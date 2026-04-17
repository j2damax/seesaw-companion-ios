// SemanticTurnDetector.swift
// SeeSaw — Tier 2 companion app
//
// LLM-assisted semantic turn-taking detection for child-directed conversational AI.
// Three-layer architecture:
//   Layer 1: Heuristic — trailing incomplete phrase detection (synchronous, <1ms)
//   Layer 2: Apple FM binary check (~150ms, @Generable TurnCompletionResponse)
//   Layer 3: Hard cap — enforced by the caller's timeout task
//
// This is a novel dissertation contribution: no existing children's AI companion
// uses on-device LLM semantic completion. All existing systems use acoustic VAD only.

import FoundationModels
import Foundation

// MARK: - @Generable structured output

@Generable
struct TurnCompletionResponse: Sendable {
    @Guide(description: "True if the child has completed their response, false if mid-thought or trailing off")
    var isComplete: Bool
}

// MARK: - SemanticTurnDetector actor

actor SemanticTurnDetector {

    // MARK: - Tunable constants

    static let silenceThresholdSeconds: Double = 1.0
    static let heuristicExtensionSeconds: Double = 1.0
    static let semanticExtensionSeconds: Double = 0.8
    static let hardCapSeconds: Double = 8.0

    // MARK: - Layer 1: Heuristic incomplete-phrase detection

    /// Returns `true` if the transcript ends with a phrase that strongly predicts
    /// the child has not yet finished their thought (mid-sentence, trailing off).
    /// Returns `false` for empty/whitespace — no extension on silence-only input.
    func isIncomplete(transcript: String) -> Bool {
        let trimmed = transcript.lowercased().trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }

        let trailingIncompletePhrases = [
            "and then", "but also", "and also", "what if", "i think",
            "because", "maybe", "and", "but", "like", "so", "or",
            "um", "uh",
        ]
        return trailingIncompletePhrases.contains(where: { trimmed.hasSuffix($0) })
    }

    // MARK: - Layer 2: Apple FM semantic check

    /// Returns `true` if the child has completed their response to `question`.
    /// Uses a fresh `LanguageModelSession` — no tools, minimal schema — so that
    /// this check does not pollute the story generation context.
    /// On any error (model unavailable, guardrail, etc.) returns `true` to ensure
    /// the story loop is never permanently blocked.
    func semanticCheck(transcript: String, question: String) async -> Bool {
        let trimmed = transcript.trimmingCharacters(in: .whitespaces)

        // Fast-path: empty → treat as complete (hard cap will handle silence-only)
        guard !trimmed.isEmpty else { return true }

        // Fast-path: very short answers (≤5 chars, e.g. "yes", "no", "fly") are complete
        if trimmed.count <= 5 { return true }

        AppConfig.shared.log("listenForAnswer: Layer 2 semantic check starting")

        do {
            let session = LanguageModelSession(instructions: """
                You are a turn-taking detector for a children's story app.
                Respond only with the structured output indicating whether the child has finished speaking.
                """
            )

            let prompt = """
                The story question was: "\(question)"
                The child said: "\(trimmed)"
                Has the child completed their response?
                """

            let response = try await session.respond(
                to: prompt,
                generating: TurnCompletionResponse.self
            )

            let isComplete = response.content.isComplete
            AppConfig.shared.log(
                isComplete
                    ? "listenForAnswer: Layer 2 complete → returning transcript"
                    : "listenForAnswer: Layer 2 incomplete → extending silence window"
            )
            return isComplete
        } catch {
            // Model unavailable, guardrail hit, or any other error — never block the loop
            AppConfig.shared.log(
                "listenForAnswer: Layer 2 error (\(error.localizedDescription)), treating as complete",
                level: .warning
            )
            return true
        }
    }
}
