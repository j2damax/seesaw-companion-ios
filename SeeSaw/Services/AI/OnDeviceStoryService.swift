// OnDeviceStoryService.swift
// SeeSaw — Tier 2 companion app
//
// Core actor managing Apple Foundation Models LLM sessions for on-device
// story generation. Handles session lifecycle, context window management,
// guardrail violation recovery, and graceful degradation.
//
// Imports FoundationModels along with StoryBeat.swift and StoryTools.swift.

import FoundationModels
import Foundation

actor OnDeviceStoryService: StoryGenerating {

    // MARK: - State

    private var session: LanguageModelSession?
    private var turnCount = 0
    private let maxTurns = 6
    private var conversationSummary: String?
    private var currentProfile: ChildProfile?

    // Single lightweight tool re-enabled after reducing to 3-field StoryBeat.
    // BookmarkMomentTool schema is ~65 tokens — within budget.
    // AdjustDifficultyTool and SwitchSceneTool remain disabled (too much schema overhead).
    private let bookmarkTool = BookmarkMomentTool()

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
        session = LanguageModelSession(tools: [bookmarkTool], instructions: systemPrompt)
        turnCount = 0
        conversationSummary = nil

        let prompt = buildInitialPrompt(context: context)
        return try await generateWithErrorRecovery(prompt: prompt)
    }

    // MARK: - Streaming story start

    /// Streams tokens for the first story beat, calling `onPartialText` as `storyText`
    /// fills in progressively. Returns the final complete `StoryBeat` for control flow.
    /// The `isEnding` flag should only be read from the returned final beat, not from
    /// partial values (Gap 3 resolution: separate streaming display from control flow).
    /// When context summarisation triggers mid-session, the recovery turn runs through
    /// the non-streaming `generateWithErrorRecovery` path and `onPartialText` is not called.
    func streamStartStory(
        context: SceneContext,
        profile: ChildProfile,
        onPartialText: @Sendable @escaping (String) async -> Void
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
        session = LanguageModelSession(tools: [bookmarkTool], instructions: systemPrompt)
        turnCount = 0
        conversationSummary = nil

        let prompt = buildInitialPrompt(context: context)
        return try await streamWithErrorRecovery(prompt: prompt, onPartialText: onPartialText)
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

    // MARK: - Streaming continuation

    /// Streaming variant of `continueTurn`. Calls `onPartialText` as `storyText`
    /// fills in, then returns the final complete beat for `isEnding` checks.
    /// When context summarisation triggers, falls back to non-streaming generation
    /// for that recovery turn only.
    func streamContinueTurn(
        childAnswer: String,
        onPartialText: @Sendable @escaping (String) async -> Void
    ) async throws -> StoryBeat {
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

        let beat = try await streamWithErrorRecovery(prompt: prompt, onPartialText: onPartialText)
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

    /// Streaming variant: iterates partial beats, calls `onPartialText` for each
    /// non-empty `storyText`, then assembles the final `StoryBeat` from the last
    /// non-empty value of each field seen during iteration.
    ///
    /// Design note: `for try await` exhausts the ResponseStream. Calling
    /// `stream.collect()` after the loop re-consumes an already-empty stream and
    /// causes a "Failed to deserialize a Generable type" error. We therefore
    /// accumulate partial field values during the loop instead of using collect().
    private func streamWithErrorRecovery(
        prompt: String,
        onPartialText: @Sendable @escaping (String) async -> Void
    ) async throws -> StoryBeat {
        guard let session else {
            throw StoryError.noActiveSession
        }

        do {
            // Accumulate the latest non-empty value for each field as tokens stream in.
            // All @Generable properties are Optional during streaming (PartiallyGenerated).
            // Each snapshot is cumulative — later snapshots supersede earlier ones.
            // NOTE: do NOT call stream.collect() after this loop — it re-consumes the
            // exhausted stream and throws "Failed to deserialize a Generable type".
            var lastText      = ""
            var lastQuestion  = ""
            var lastIsEnding  = false
            var snapshotCount = 0

            await AppConfig.shared.log("streamWithErrorRecovery: starting stream")
            let stream = session.streamResponse(to: prompt, generating: StoryBeat.self)
            for try await snapshot in stream {
                snapshotCount += 1
                if let text = snapshot.content.storyText, !text.isEmpty {
                    lastText = text
                    await onPartialText(text)
                }
                if let q = snapshot.content.question, !q.isEmpty { lastQuestion = q }
                if let e = snapshot.content.isEnding              { lastIsEnding  = e }
            }

            await AppConfig.shared.log("streamWithErrorRecovery: done, snapshots=\(snapshotCount), textLen=\(lastText.count), hasQuestion=\(!lastQuestion.isEmpty), isEnding=\(lastIsEnding)")

            guard !lastText.isEmpty else {
                throw StoryError.generationFailed("Stream completed without generating story content.")
            }

            return StoryBeat(
                storyText: lastText,
                question:  lastQuestion.isEmpty ? "What do you think happens next?" : lastQuestion,
                isEnding:  lastIsEnding
            )
        } catch let error as LanguageModelSession.GenerationError {
            return try await handleGenerationError(error, prompt: prompt)
        } catch let error as StoryError {
            throw error
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

        session = LanguageModelSession(instructions: """
            Continue an ongoing story. Story so far: \(summary)
            \(contentRules)
            """
        )
        turnCount = 0

        return try await generateWithErrorRecovery(prompt: lastPrompt)
    }

    private func updateConversationSummary(beat: StoryBeat) {
        // Use first 120 chars of storyText as a rolling summary for context restarts.
        let snippet = String(beat.storyText.prefix(120))
        if let existing = conversationSummary {
            conversationSummary = "\(existing) \(snippet)"
        } else {
            conversationSummary = snippet
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
        Generate short story segments (2-3 sentences, max 30 words).
        End every beat with one short question (max 10 words).
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

        let difficulty = UserDefaults.standard.storyDifficultyLevel
        let difficultyGuidance: String
        switch difficulty {
        case 1: difficultyGuidance = "Use very simple words and short sentences suitable for ages 3–5."
        case 3: difficultyGuidance = "Use richer vocabulary and more complex sentences suitable for ages 9–12."
        default: difficultyGuidance = "Use age-appropriate vocabulary and sentence length for ages 6–8."
        }

        let name = profile.name.isEmpty ? "your friend" : profile.name
        return """
        You are Whisper, a warm storytelling companion for \(name), \
        aged \(profile.age).
        Always address \(name) by name in questions — never say "you" or "the child".
        \(contentRules)
        Use detected objects: \(objects).
        Scene: \(scenes).
        \(difficultyGuidance)
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
        let trimmed = childAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        var prompt: String
        if trimmed.isEmpty {
            prompt = "The child was quiet. Make the next story moment more exciting to re-engage them"
        } else if trimmed.count <= 3 {
            prompt = "The child said: \"\(trimmed)\". Continue the story building on their response"
        } else {
            prompt = "The child answered: \"\(trimmed)\". Continue the story"
        }
        if isFinalTurn {
            prompt += " and bring it to a warm, satisfying conclusion"
        }
        prompt += "."
        return prompt
    }
}
