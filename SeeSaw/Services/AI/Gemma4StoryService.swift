// Gemma4StoryService.swift
// SeeSaw — Tier 2 companion app
//
// On-device story generation using Gemma 3 1B (GGUF Q4_K_M) via MediaPipe Tasks GenAI.
// Implements StoryGenerating so it can be used identically to OnDeviceStoryService.
//
// Integration:
//   pod 'MediaPipeTasksGenAI' in Podfile, then open SeeSaw.xcworkspace.
//   The GGUF model is placed in Documents/ by ModelDownloadManager.
//
// When MediaPipeTasksGenAI is NOT compiled in (pre-Pods install), all generate()
// calls throw StoryError.modelUnavailable so the routing layer falls back to
// OnDeviceStoryService silently — no code path breaks.

import Foundation
#if canImport(MediaPipeTasksGenAI)
// MediaPipe 0.10.33: LlmInference is deprecated (successor: LiteRT LM).
// The API is fully functional; migration is planned post-dissertation.
import MediaPipeTasksGenAI
import MediaPipeTasksGenAIC
#endif

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
    private var currentProfile: ChildProfile?

    private let maxTurns = 6
    /// Must match the filename written by ModelDownloadManager and the GCS object name.
    private let modelFileName = "gemma2-2b-it-gpu-int8.bin"

    // MARK: - MediaPipe inference objects
    // LlmInference is expensive to create (~3–5s) — created once per model path and reused.
    // LlmInference.Session is cheap — created fresh for each story (preserves KV cache
    // across turns within one session, discarded when story ends or session resets).
    //
    // Both are actor-isolated so only ever accessed serially from this actor.
#if canImport(MediaPipeTasksGenAI)
    private var llmInference: LlmInference?
    private var llmSession:   LlmInference.Session?
#endif

    // MARK: - StoryGenerating

    var isSessionActive: Bool  { isActive   }
    var currentTurnCount: Int  { turnCount  }

    func startStory(context: SceneContext, profile: ChildProfile) async throws -> StoryBeat {
        let modelPath = try resolvedModelPath()
        try loadInferenceIfNeeded(modelPath: modelPath)
        resetSession(profile: profile)
        try startNewLLMSession()
        isActive = true

        let systemPrompt = buildSystemPrompt(context: context, profile: profile)
        let userPrompt   = buildInitialPrompt(context: context)
        // First turn: system prompt + user prompt are sent together as one chunk.
        return try await generate(prompt: systemPrompt + "\n\n" + userPrompt, isFinalTurn: false)
    }

    func continueTurn(childAnswer: String) async throws -> StoryBeat {
        guard isActive else { throw StoryError.noActiveSession }
        let _ = try resolvedModelPath()   // verify model still accessible
        turnCount += 1
        let isFinalTurn = turnCount >= maxTurns
        let prompt = buildContinuationPrompt(childAnswer: childAnswer, isFinalTurn: isFinalTurn)
        return try await generate(prompt: prompt, isFinalTurn: isFinalTurn)
    }

    func endSession() {
        clearLLMSession()
        resetSession(profile: nil)
    }

    // MARK: - Model state management (called from ModelDownloadManager)

    func updateModelState(_ state: ModelState) {
        modelState = state
        // When model is removed or fails, discard the loaded inference object so
        // it won't be used with a stale or deleted file path.
        switch state {
        case .notDownloaded, .failed:
#if canImport(MediaPipeTasksGenAI)
            llmInference = nil
            llmSession   = nil
#endif
            isActive = false
        default:
            break
        }
    }

    func currentModelState() -> ModelState { modelState }

    // MARK: - Private: model resolution

    private func resolvedModelPath() throws -> String {
        switch modelState {
        case .ready(let path):   return path
        case .notDownloaded:     throw StoryError.modelUnavailable
        case .downloading:       throw StoryError.modelDownloading
        case .failed(let r):     throw StoryError.generationFailed("Gemma model unavailable: \(r)")
        }
    }

    // MARK: - Private: session management

    private func resetSession(profile: ChildProfile?) {
        isActive       = false
        turnCount      = 0
        currentProfile = profile
        clearLLMSession()
    }

    private func clearLLMSession() {
#if canImport(MediaPipeTasksGenAI)
        llmSession = nil
#endif
    }

    // MARK: - Private: MediaPipe integration

    /// Creates `LlmInference` the first time a model path is used, or when the path changes.
    /// This is the expensive operation (~3–5s on first call). Subsequent calls are no-ops.
    private func loadInferenceIfNeeded(modelPath: String) throws {
#if canImport(MediaPipeTasksGenAI)
        // If we already have an inference object for this path, reuse it.
        if llmInference != nil { return }

        AppConfig.shared.log("Gemma4StoryService: loading LlmInference from \(modelPath)")
        let loadStart = CFAbsoluteTimeGetCurrent()
        let options = LlmInference.Options(modelPath: modelPath)
        // 2048 covers a full 6-turn session comfortably:
        //   ~300 tokens (system prompt) + 6 × ~90 tokens (beat + child reply) ≈ 840 tokens peak.
        // 512 caused context overflow at turn 3 (current_step=492 + input=22 > 512).
        // Gemma 2 2B supports up to 8192 context; 2048 is a safe cap for mobile memory.
        options.maxTokens = 2048
        llmInference = try LlmInference(options: options)
        let loadMs = Int((CFAbsoluteTimeGetCurrent() - loadStart) * 1000)
        AppConfig.shared.log("Gemma4StoryService: LlmInference ready, modelLoadTime=\(loadMs)ms")
#else
        throw StoryError.modelUnavailable
#endif
    }

    /// Creates a fresh `LlmInference.Session` for a new story.
    /// The session preserves KV cache across turns, making subsequent beats fast.
    private func startNewLLMSession() throws {
#if canImport(MediaPipeTasksGenAI)
        guard let inference = llmInference else { throw StoryError.modelUnavailable }
        let opts = LlmInference.Session.Options()
        opts.temperature = 0.8
        opts.topk        = 40
        opts.topp        = 0.95
        llmSession = try LlmInference.Session(llmInference: inference, options: opts)
        AppConfig.shared.log("Gemma4StoryService: new LlmInference.Session created")
#else
        throw StoryError.modelUnavailable
#endif
    }

    /// Adds `prompt` as the next query chunk to the active session and collects
    /// the full response from the async stream before parsing it into a `StoryBeat`.
    ///
    /// Using `LlmInference.Session` means:
    /// • KV cache is preserved across turns — each continuation is fast
    /// • The session internally manages the conversation history
    /// • We only send the NEW turn's text each time (not the full history)
    private func generate(prompt: String, isFinalTurn: Bool) async throws -> StoryBeat {
#if canImport(MediaPipeTasksGenAI)
        guard let session = llmSession else { throw StoryError.noActiveSession }

        AppConfig.shared.log("Gemma4StoryService: generate() turn=\(turnCount), isFinal=\(isFinalTurn), promptLen=\(prompt.count)")
        let start = CFAbsoluteTimeGetCurrent()

        try session.addQueryChunk(inputText: prompt)
        let responseStream = session.generateResponseAsync()

        var fullResponse = ""
        var firstTokenMs: Int? = nil
        var chunkCount = 0
        for try await partial in responseStream {
            chunkCount += 1
            if firstTokenMs == nil {
                firstTokenMs = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
                AppConfig.shared.log("Gemma4StoryService: first token at \(firstTokenMs!)ms (chunk #\(chunkCount))")
            }
            fullResponse += partial
        }

        let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
        let wordCount = fullResponse.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.count
        let wordsPerSec = ms > 0 ? String(format: "%.1f", Double(wordCount) / (Double(ms) / 1000.0)) : "n/a"
        AppConfig.shared.log("Gemma4StoryService: generated \(fullResponse.count) chars, ~\(wordCount) words in \(ms)ms (\(wordsPerSec) words/s), ttft=\(firstTokenMs ?? -1)ms, chunks=\(chunkCount)")
        AppConfig.shared.log("Gemma4StoryService: raw response: \(fullResponse)")

        let beat = Self.parseResponse(fullResponse, isFinalTurn: isFinalTurn)
        AppConfig.shared.log("Gemma4StoryService: parsed storyText: \(beat.storyText)")
        AppConfig.shared.log("Gemma4StoryService: parsed question: \(beat.question)")
        AppConfig.shared.log("Gemma4StoryService: parsed isEnding: \(beat.isEnding)")
        return beat
#else
        // MediaPipe not compiled in — fall back gracefully so the routing layer
        // redirects to OnDeviceStoryService (Architecture A).
        _ = prompt
        throw StoryError.modelUnavailable
#endif
    }

    // MARK: - parseResponse

    /// Parses a Gemma response into a `StoryBeat`.
    ///
    /// The fine-tuned seesaw-gemma3-1b model is trained to output JSON:
    ///   `{"story_text": "...", "question": "...", "is_ending": false}`
    /// JSON parse is attempted first; heuristic text extraction is the fallback
    /// for cases where the model produces plain prose instead.
    static func parseResponse(_ raw: String, isFinalTurn: Bool) -> StoryBeat {
        let clean = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // ── JSON path (preferred — matches fine-tuned model output) ─────────────
        if let data = clean.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let storyText = json["story_text"] as? String,
           let question  = json["question"]   as? String {
            // isFinalTurn always wins: reaching the turn cap closes the story
            // regardless of what the model emits for "is_ending".
            let isEnding = isFinalTurn || ((json["is_ending"] as? Bool) ?? false)
            return StoryBeat(storyText: storyText, question: question, isEnding: isEnding)
        }

        // ── Heuristic fallback (plain prose) ────────────────────────────────────
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

        let storyText   = storyParts.joined(separator: ". ")
        let endingWords = [
            "the end", "goodbye", "farewell", "home safely",
            "happily ever after", "lived happily", "sweet dreams",
            "safe and sound", "the story ends", "back home",
            "time to sleep", "story is over", "and they all"
        ]
        let isEnding    = isFinalTurn || endingWords.contains { raw.lowercased().contains($0) }

        return StoryBeat(
            storyText: storyText.isEmpty ? raw : storyText,
            question:  question,
            isEnding:  isEnding
        )
    }

    // MARK: - Prompt builders

    private let contentRules = """
        Generate short story segments (2-3 sentences, max 30 words).
        Output JSON only: {"story_text": "...", "question": "...", "is_ending": false}
        End every beat with one open question directed at the child using "you" (max 10 words). Example: "What do you think happens next?"
        Address the child as "you" in story sentences — never use their name as subject of an action.
        Use their name only for praise or greetings: "Great idea, [name]!" or "Well done, [name]!"
        Speak as a warm companion ("I wonder...", "Let's see!"), not as a narrator telling a story about someone.
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
        let name = profile.name.isEmpty ? "the child" : profile.name

        let difficultyLevel = UserDefaults.standard.storyDifficultyLevel
        let difficultyGuidance: String
        switch difficultyLevel {
        case 1:  difficultyGuidance = "Use very simple words for ages 3–5."
        case 3:  difficultyGuidance = "Use richer vocabulary for ages 9–12."
        default: difficultyGuidance = "Use age-appropriate language for ages 6–8."
        }

        return """
            <start_of_turn>system
            You are Whisper, a warm storytelling companion speaking directly with \(name), aged \(profile.age).
            You are talking *with* \(name), not telling a story *about* them.
            \(contentRules)
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
            // Explicit override — the model must close the story here.
            // "bring it to a conclusion" was too weak; the model kept asking questions.
            content = "The child answered: \"\(trimmed)\". THIS IS THE FINAL BEAT. Write a warm, satisfying 2-sentence ending that closes the story. Set is_ending to true. Do NOT ask a question — output an empty string for the question field."
        }
        return "<start_of_turn>user\n\(content).\n<end_of_turn>\n<start_of_turn>model"
    }
}
