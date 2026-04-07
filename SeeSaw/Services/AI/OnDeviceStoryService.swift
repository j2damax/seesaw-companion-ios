// OnDeviceStoryService.swift
// SeeSaw — Tier 2 companion app
//
// Core actor managing Apple Foundation Models LLM sessions for on-device
// story generation. Handles session lifecycle, context window management,
// guardrail violation recovery, and graceful degradation.
//
// One of only two files that imports FoundationModels (the other is StoryBeat).

import FoundationModels
import Foundation

actor OnDeviceStoryService: StoryGenerating {

    // MARK: - State

    private var session: LanguageModelSession?
    private var turnCount = 0
    private let maxTurns = 6
    private var conversationSummary: String?
    private var currentProfile: ChildProfile?

    // MARK: - Public computed properties

    var isSessionActive: Bool { session != nil }
    var currentTurnCount: Int { turnCount }

    // MARK: - Availability

    enum ModelAvailabilityStatus: Sendable {
        case available
        case downloading
        case unavailable
    }

    func checkAvailability() -> ModelAvailabilityStatus {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            return .available
        case .unavailable(.modelNotReady):
            return .downloading
        case .unavailable:
            return .unavailable
        }
    }

    // MARK: - Session lifecycle

    func startStory(
        context: SceneContext,
        profile: ChildProfile
    ) async throws -> StoryBeat {
        let availability = checkAvailability()
        switch availability {
        case .unavailable:
            throw StoryError.modelUnavailable
        case .downloading:
            throw StoryError.modelDownloading
        case .available:
            break
        }

        endSessionInternal()
        currentProfile = profile

        let systemPrompt = buildSystemPrompt(context: context, profile: profile)
        session = LanguageModelSession(instructions: systemPrompt)
        turnCount = 0
        conversationSummary = nil

        let prompt = buildInitialPrompt(context: context)
        return try await generateWithErrorRecovery(prompt: prompt)
    }

    func continueTurn(childAnswer: String) async throws -> StoryBeat {
        guard session != nil else {
            throw StoryError.noActiveSession
        }

        turnCount += 1

        let isFinalTurn = turnCount >= maxTurns
        let prompt = buildContinuationPrompt(
            childAnswer: childAnswer,
            isFinalTurn: isFinalTurn
        )

        if shouldSummariseContext() {
            return try await restartWithSummary(lastPrompt: prompt)
        }

        let beat = try await generateWithErrorRecovery(prompt: prompt)
        updateConversationSummary(beat: beat)
        return beat
    }

    func endSession() {
        endSessionInternal()
    }

    // MARK: - Private session management

    private func endSessionInternal() {
        session = nil
        turnCount = 0
        conversationSummary = nil
        currentProfile = nil
    }

    // MARK: - Generation with error recovery

    private func generateWithErrorRecovery(
        prompt: String
    ) async throws -> StoryBeat {
        guard let session else {
            throw StoryError.noActiveSession
        }

        do {
            let response = try await session.respond(
                to: prompt,
                generating: StoryBeat.self
            )
            return response.content
        } catch let error as LanguageModelSession.GenerationError {
            return try await handleGenerationError(error, prompt: prompt)
        } catch {
            throw StoryError.generationFailed(error.localizedDescription)
        }
    }

    private func handleGenerationError(
        _ error: LanguageModelSession.GenerationError,
        prompt: String
    ) async throws -> StoryBeat {
        switch error {
        case .exceededContextWindowSize:
            await AppConfig.shared.log(
                "OnDeviceStoryService: context window exceeded, restarting with summary",
                level: .warning
            )
            return try await restartWithSummary(lastPrompt: prompt)

        case .guardrailViolation:
            await AppConfig.shared.log(
                "OnDeviceStoryService: guardrail violation, retrying with softened prompt",
                level: .warning
            )
            return try await retrySoftened(attempt: 0)

        default:
            throw StoryError.generationFailed(error.localizedDescription)
        }
    }

    // MARK: - Context window management

    private func shouldSummariseContext() -> Bool {
        // Turn-count heuristic: summarise after turn 4 as a safety measure.
        // This is simpler and more reliable than token counting, per plan §15.2 Bug 2.
        return turnCount > 4
    }

    private func restartWithSummary(
        lastPrompt: String
    ) async throws -> StoryBeat {
        let summary = conversationSummary ?? "An interactive story is in progress."
        let profile = currentProfile

        endSessionInternal()
        currentProfile = profile

        session = LanguageModelSession(
            instructions: """
            Continue an ongoing story. Story so far: \(summary)
            \(contentRules)
            """
        )
        turnCount = 0

        return try await generateWithErrorRecovery(prompt: lastPrompt)
    }

    private func updateConversationSummary(beat: StoryBeat) {
        let continuation = beat.suggestedContinuation
        if let existing = conversationSummary {
            conversationSummary = "\(existing) \(continuation)"
        } else {
            conversationSummary = continuation
        }
    }

    // MARK: - Guardrail recovery

    private func retrySoftened(attempt: Int) async throws -> StoryBeat {
        guard let session else {
            throw StoryError.noActiveSession
        }

        let fallbackPrompts = [
            "Continue the story in a gentle, positive direction. Keep the tone warm and friendly.",
            "Tell a short, happy story about friendship and adventure.",
        ]

        let prompt = fallbackPrompts[min(attempt, fallbackPrompts.count - 1)]

        do {
            let response = try await session.respond(
                to: prompt,
                generating: StoryBeat.self
            )
            return response.content
        } catch {
            if attempt < fallbackPrompts.count - 1 {
                return try await retrySoftened(attempt: attempt + 1)
            }
            await AppConfig.shared.log(
                "OnDeviceStoryService: all retries failed, returning static fallback",
                level: .warning
            )
            return StoryBeat.safeFallback
        }
    }

    // MARK: - Prompt builders

    private let contentRules = """
        Generate short story segments (3-5 sentences).
        End every beat with one imaginative question.
        Never mention technology, devices, or AI.
        Never include violence or inappropriate content.
        """

    private func buildSystemPrompt(
        context: SceneContext,
        profile: ChildProfile
    ) -> String {
        let objects = context.labels.isEmpty
            ? "various items"
            : context.labels.joined(separator: ", ")
        let scenes = context.sceneCategories.isEmpty
            ? "an interesting place"
            : context.sceneCategories.joined(separator: ", ")

        return """
        You are Whisper, a warm storytelling companion for \(profile.name), \
        aged \(profile.age).
        \(contentRules)
        Use detected objects: \(objects).
        Scene: \(scenes).
        Match vocabulary to age \(profile.age).
        """
    }

    private func buildInitialPrompt(context: SceneContext) -> String {
        var prompt = "Start a new interactive story"
        if !context.labels.isEmpty {
            prompt += " featuring \(context.labels.prefix(3).joined(separator: " and "))"
        }
        if let transcript = context.transcript, !transcript.isEmpty {
            prompt += ". The child said: \"\(transcript)\""
        }
        prompt += "."
        return prompt
    }

    private func buildContinuationPrompt(
        childAnswer: String,
        isFinalTurn: Bool
    ) -> String {
        var prompt = "The child answered: \"\(childAnswer)\". Continue the story"
        if isFinalTurn {
            prompt += " and bring it to a warm, satisfying conclusion"
        }
        prompt += "."
        return prompt
    }
}
