// Gemma4StoryService.swift
// SeeSaw — Tier 2 companion app
//
// On-device story generation using Gemma 4 1B (GGUF Q4_K_M) via MediaPipe Tasks GenAI.
// Implements StoryGenerating so it can be used identically to OnDeviceStoryService.
//
// Prerequisites:
//   1. MediaPipeTasksGenAI Swift package added to the Xcode project.
//   2. The GGUF model file placed in the app's Documents directory by ModelDownloadManager.
//
// Until MediaPipe is wired up, this service throws StoryError.modelUnavailable so
// the routing layer falls back to OnDeviceStoryService silently.

import Foundation

// MARK: - Gemma4StoryService

actor Gemma4StoryService: StoryGenerating {

    // MARK: - Types

    enum ModelState: Sendable {
        case notDownloaded
        case downloading(progress: Double)
        case ready(modelPath: String)
        case failed(reason: String)
    }

    // MARK: - State

    private var modelState: ModelState = .notDownloaded
    private var turnCount    = 0
    private var isActive     = false
    private var sessionContext: [String] = []    // rolling prompt context
    private var currentProfile: ChildProfile?

    private let maxTurns  = 6
    private let modelFileName = "gemma4-1b-it-q4_k_m.gguf"

    // MARK: - StoryGenerating

    var isSessionActive: Bool { isActive }
    var currentTurnCount: Int { turnCount }

    func startStory(context: SceneContext, profile: ChildProfile) async throws -> StoryBeat {
        let modelPath = try resolvedModelPath()
        resetSession(profile: profile)
        let systemPrompt = buildSystemPrompt(context: context, profile: profile)
        sessionContext = [systemPrompt]
        let userPrompt = buildInitialPrompt(context: context)
        return try await generate(userPrompt: userPrompt, modelPath: modelPath)
    }

    func continueTurn(childAnswer: String) async throws -> StoryBeat {
        guard isActive else { throw StoryError.noActiveSession }
        let modelPath = try resolvedModelPath()
        turnCount += 1
        let isFinalTurn = turnCount >= maxTurns
        let userPrompt  = buildContinuationPrompt(childAnswer: childAnswer, isFinalTurn: isFinalTurn)
        return try await generate(userPrompt: userPrompt, modelPath: modelPath)
    }

    func endSession() {
        resetSession(profile: nil)
    }

    // MARK: - Model state management (called from ModelDownloadManager)

    func updateModelState(_ state: ModelState) {
        modelState = state
    }

    func currentModelState() -> ModelState { modelState }

    // MARK: - Private

    private func resolvedModelPath() throws -> String {
        switch modelState {
        case .ready(let path):
            return path
        case .notDownloaded:
            throw StoryError.modelUnavailable
        case .downloading:
            throw StoryError.modelDownloading
        case .failed(let reason):
            throw StoryError.generationFailed("Gemma 4 model unavailable: \(reason)")
        }
    }

    private func resetSession(profile: ChildProfile?) {
        isActive       = false
        turnCount      = 0
        sessionContext = []
        currentProfile = profile
    }

    // MARK: - Generation

    /// Performs one inference turn with the assembled prompt.
    ///
    /// MediaPipe integration point: replace the placeholder below with
    /// `LlmInference.generateResponse(inputText:)` once the Swift package is added.
    /// The prompt format is already compatible with Gemma instruction-tuned chat templates.
    private func generate(userPrompt: String, modelPath: String) async throws -> StoryBeat {
        sessionContext.append(userPrompt)
        let fullPrompt = sessionContext.joined(separator: "\n\n")

        // ── MediaPipe integration ──────────────────────────────────────────────
        // TODO: Uncomment and replace placeholder once MediaPipeTasksGenAI package
        //       is added to the project (Sprint 3, step 4.4):
        //
        // let options = LlmInference.Options(modelPath: modelPath)
        // options.maxTokens = 200
        // options.temperature = 0.7
        // let inference = try LlmInference(options: options)
        // let rawOutput  = try inference.generateResponse(inputText: fullPrompt)
        // ──────────────────────────────────────────────────────────────────────

        // Until MediaPipe is integrated, raise modelUnavailable so the routing
        // layer in CompanionViewModel falls back to OnDeviceStoryService.
        _ = fullPrompt   // suppress unused-variable warning
        _ = modelPath
        throw StoryError.modelUnavailable
    }

    /// Parses a plain-text Gemma response into a `StoryBeat`.
    ///
    /// Gemma 4 outputs plain prose, so we use heuristics:
    ///   - The last sentence ending with "?" is the question.
    ///   - Everything before it is the story text.
    ///   - `isEnding` is set when the response contains ending keywords.
    static func parseResponse(_ raw: String, isFinalTurn: Bool) -> StoryBeat {
        let sentences = raw
            .components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var question  = "What do you think happens next?"
        var storyParts: [String] = []

        for sentence in sentences {
            if sentence.hasSuffix("?") || raw.contains(sentence + "?") {
                question = sentence + "?"
            } else {
                storyParts.append(sentence)
            }
        }

        let storyText  = storyParts.joined(separator: ". ")
        let endingWords = ["end", "goodbye", "farewell", "journey", "home safely", "the end"]
        let isEnding   = isFinalTurn || endingWords.contains { raw.lowercased().contains($0) }

        return StoryBeat(
            storyText: storyText.isEmpty ? raw : storyText,
            question:  question,
            isEnding:  isEnding
        )
    }

    // MARK: - Prompt builders

    private let contentRules = """
        Generate short story segments (2-3 sentences, max 30 words).
        End every beat with one short question (max 10 words) starting on a new line.
        Never mention technology, devices, or AI.
        Never include violence or inappropriate content.
        """

    private func buildSystemPrompt(context: SceneContext, profile: ChildProfile) -> String {
        let objects = context.labels.isEmpty
            ? "various items"
            : context.labels.joined(separator: ", ")
        let scenes = context.sceneCategories.isEmpty
            ? "an interesting place"
            : context.sceneCategories.joined(separator: ", ")
        let name = profile.name.isEmpty ? "your friend" : profile.name

        let difficultyLevel = UserDefaults.standard.storyDifficultyLevel
        let difficultyGuidance: String
        switch difficultyLevel {
        case 1:  difficultyGuidance = "Use very simple words for ages 3–5."
        case 3:  difficultyGuidance = "Use richer vocabulary for ages 9–12."
        default: difficultyGuidance = "Use age-appropriate language for ages 6–8."
        }

        return """
            <start_of_turn>system
            You are Whisper, a warm storytelling companion for \(name), aged \(profile.age).
            Always address \(name) by name. \(contentRules)
            Objects visible: \(objects). Scene: \(scenes). \(difficultyGuidance)
            <end_of_turn>
            """
    }

    private func buildInitialPrompt(context: SceneContext) -> String {
        var prompt = "<start_of_turn>user\nStart a new interactive story"
        if !context.labels.isEmpty {
            prompt += " featuring \(context.labels.prefix(3).joined(separator: " and "))"
        }
        if let transcript = context.transcript, !transcript.isEmpty {
            prompt += ". The child said: \"\(transcript)\""
        }
        prompt += ".\n<end_of_turn>\n<start_of_turn>model"
        return prompt
    }

    private func buildContinuationPrompt(childAnswer: String, isFinalTurn: Bool) -> String {
        let trimmed = childAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        var content: String
        if trimmed.isEmpty {
            content = "The child was quiet. Continue the story to re-engage them"
        } else {
            content = "The child answered: \"\(trimmed)\". Continue the story"
        }
        if isFinalTurn {
            content += " and bring it to a warm, satisfying conclusion"
        }
        return "<start_of_turn>user\n\(content).\n<end_of_turn>\n<start_of_turn>model"
    }
}
