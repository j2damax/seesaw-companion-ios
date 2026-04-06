# Apple Foundation Models — Detailed Implementation Plan

**Project:** seesaw-companion-ios  
**Date:** 6 April 2026  
**Status:** Planning  

---

## Table of Contents

1. [Critical Analysis of Current Document](#part-1-critical-analysis)
2. [What the Document Gets Right](#part-2-what-the-document-gets-right)
3. [Detailed Implementation Plan](#part-3-detailed-implementation-plan)
4. [Key Architectural Decisions](#part-4-key-architectural-decisions)
5. [Risk Register](#part-5-risk-register)
6. [Estimated File Changes](#part-6-estimated-file-changes)

---

## Part 1: Critical Analysis

### Issues Found in `Apple Foundation Models.md`

Based on deep research into Apple's actual Foundation Models framework documentation, WWDC 2025 sessions, Apple Developer technotes, and the full SeeSaw codebase, the following issues were identified.

---

### 🔴 Critical Errors (Must Fix)

#### 1. Wrong API Method Names

The document uses `session.generate(StoryBeat.self, prompt:)` which **does not exist** in Apple's Foundation Models framework. The correct APIs are:

```swift
// ✅ Correct — full output
session.respond(to: prompt, generating: StoryBeat.self)

// ✅ Correct — streaming
session.streamResponse(to: prompt, generating: StoryBeat.self)
```

All code examples in the document must be corrected from `.generate()` to `.respond()` / `.streamResponse()`.

**Sources:**
- [Apple Developer Documentation: LanguageModelSession](https://developer.apple.com/documentation/foundationmodels/languagemodelsession)
- [Axiom Foundation Models Reference](https://charleswiltgen.github.io/Axiom/reference/foundation-models-ref)

---

#### 2. iOS Version Contradiction

The document states "iOS 18+" in the hardware requirements section, but Foundation Models requires **iOS 26+** (the actual release version). The project's `IPHONEOS_DEPLOYMENT_TARGET` is already 26.2, which is correct, but the document text is misleading.

**Fix:** Replace "iOS 18+" with "iOS 26+" throughout the document.

---

#### 3. 4,096 Token Context Window — Not Addressed At All

This is the document's **biggest blind spot**. Apple's on-device model has a strict **4,096 token context window** that includes:

- System instructions (~200–400 tokens for the proposed Whisper prompt)
- Tool schemas (if used)
- All prior conversation history (both prompts and responses)
- The model's own responses
- The current prompt

With the proposed `maxTurns = 8`, a typical story session would easily exceed this. At ~3–4 sentences per `StoryBeat` response (~100 tokens), plus child answers (~20–50 tokens each), plus the system prompt, you'd hit the limit around **turn 4–5**. The document proposes no mitigation strategy.

**Required mitigation strategies:**

1. Use `session.contextSize` and `tokenCount(for:)` APIs (available iOS 26.4+) to monitor usage
2. Implement a **sliding window**: summarise older turns before they overflow
3. Reduce `maxTurns` from 8 to **5–6** as a safety margin
4. Handle `.exceededContextWindowSize` errors gracefully with session restart + context summary

**Sources:**
- [Apple TN3193: Managing the on-device foundation model's context window](https://developer.apple.com/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window)
- [InfoQ: Apple Improves Context Window Management](https://www.infoq.com/news/2026/03/apple-foundation-models-context/)

---

#### 4. Force Unwrap in Code Example

The `startStory()` method contains `session!.generate(...)` — a **force unwrap** that directly violates the project's established coding standard ("No Force Unwrap" rule). Must use `guard let session` pattern.

```swift
// ❌ In the document
return try await session!.generate(StoryBeat.self, prompt: prompt)

// ✅ Corrected
guard let session else { throw StoryError.noActiveSession }
return try await session.respond(to: prompt, generating: StoryBeat.self)
```

---

#### 5. No Availability Check

The code never checks `SystemLanguageModel.default.availability` before creating a session. On unsupported devices or when the model is still downloading, this will crash or fail silently. The document proposes no fallback mechanism.

```swift
// ✅ Required availability check
let model = SystemLanguageModel.default
guard model.availability == .available else {
    // Handle .downloading or .unavailable
    throw StoryError.modelUnavailable
}
let session = LanguageModelSession(model: model)
```

---

### 🟡 Significant Issues (Should Fix)

#### 6. Streaming Not Actually Used

The document mentions "streaming text generation" as a key capability and claims "< 1 second to first word (streaming)" but the code example uses `session.generate()` (blocking), not `streamResponse()`. This means the user waits for the **entire** response before any audio plays, negating the streaming advantage.

For a children's storytelling app, streaming is critical: the child hears the first sentence while the model is still generating the rest.

```swift
// ✅ Streaming implementation
let stream = session.streamResponse(to: prompt, generating: StoryBeat.self)
for try await partialBeat in stream {
    // Start TTS on storyText as soon as partially available
    if let text = partialBeat.storyText, !text.isEmpty {
        await ttsService.speakIncremental(text)
    }
}
```

---

#### 7. `@Guide` Annotations Missing from `StoryBeat`

The `@Generable StoryBeat` struct lacks `@Guide` macros that would constrain the model's output:

```swift
// ❌ Current (no guidance)
@Generable
struct StoryBeat {
    let storyText: String
    let question: String
    // ...
}

// ✅ With proper guidance
@Generable
struct StoryBeat {
    @Guide(description: "A short story segment of 3-5 sentences to speak aloud")
    let storyText: String

    @Guide(description: "One open-ended imaginative question for the child")
    let question: String

    @Guide(description: "True only when the story should conclude")
    let isEnding: Bool

    @Guide(description: "Current story theme: adventure, friendship, discovery, etc.")
    let theme: String

    @Guide(description: "Brief context hint for next turn, not spoken aloud")
    let suggestedContinuation: String
}
```

Without `@Guide`, the model has no schema-level guidance on output format, leading to unpredictable lengths and content.

**Source:** [Apple Developer: Guided Generation](https://developer.apple.com/documentation/foundationmodels)

---

#### 8. Pipeline Signature Mismatch

The document shows:

```swift
let context = try await privacyPipeline.process(jpeg: receivedJPEG, audio: receivedAudio)
```

But the **actual** current API is:

```swift
let result = try await privacyPipeline.process(jpegData: Data, childAge: Int) -> PipelineResult
// PipelineResult contains: .payload (ScenePayload) + .metrics (PrivacyMetricsEvent)
```

The document introduces a breaking interface change without acknowledging it.

---

#### 9. `bleService.sendAudioToDevice(text:)` Doesn't Exist

The document's pipeline shows:

```swift
await bleService.sendAudioToDevice(text: beat.storyText)
```

This method doesn't exist. The current API requires **two steps**:

```swift
// Step 1: TTS → PCM audio data
let audioData = try await audioService.generateAndEncodeAudio(from: beat.storyText)

// Step 2: Send via BLE (or speaker for local device)
try await accessoryManager.activeAccessory.sendAudio(audioData)
```

---

#### 10. No Error Handling for Guardrail Violations

Apple's model enforces built-in, non-configurable guardrails. A `.guardrailViolation` error can occur if the model interprets any prompt as potentially unsafe. For a children's app, this is especially relevant — words like "scary", "monster", or "fight" in a child's answer could trigger it. The document has zero error recovery strategy.

**Required handling:**

```swift
do {
    let beat = try await session.respond(to: prompt, generating: StoryBeat.self)
} catch let error as LanguageModelError {
    switch error {
    case .guardrailViolation:
        // Retry with softened prompt, or use fallback story segment
        return try await generateSafeFallback()
    case .exceededContextWindowSize:
        // Summarise context and start new session
        return try await restartWithSummary()
    default:
        throw error
    }
}
```

---

### 🟢 Minor Issues

#### 11. `SceneContext` Type Introduced Without Definition

The document references `SceneContext` in the new pipeline but never defines it. Is it the same as `ScenePayload`? A new struct? How does it differ? Needs a clear definition and a factory method from `ScenePayload`.

#### 12. `ChildProfile` Usage

The document references `ChildProfile` with `preferences.themes` but the existing `ChildProfile` model only has `name: String, age: Int, preferences: [String]`. There's no `.themes` sub-property.

#### 13. No Testing Strategy

The document proposes significant new functionality but includes zero testing plan. The project currently has 62 tests (34 privacy-specific). The on-device story service needs unit tests, especially for context window management and error recovery.

#### 14. Firebase Dependencies

The project already has Firebase (Auth, Analytics, Crashlytics, AI) dependencies. The document's claim of "Zero third-party libraries" is already partially violated. The plan should clarify that Firebase stays for auth/analytics while Foundation Models handles story generation.

---

## Part 2: What the Document Gets Right

Despite the issues above, the core thesis and strategy are sound:

1. **Core thesis is correct** — Apple Foundation Models does enable a fully on-device story generation loop, eliminating the cloud dependency for core functionality.

2. **Privacy argument is academically stronger** — "Structurally guaranteed" privacy (no network = no data leak) is a bolder claim than "filtered before cloud".

3. **Three-mode strategy (A/B/C) is well-designed** — Graceful degradation from fully on-device → hybrid → offline-only is architecturally clean.

4. **`@Generable StoryBeat` concept is correct** — Structured output eliminates JSON parsing and gives type-safe story responses. This is the right way to use the framework.

5. **Actor-based `OnDeviceStoryService` follows project conventions** — Correctly uses `actor` keyword for thread-safe service isolation.

6. **Turn-management concept is sound** — Stateful `LanguageModelSession` with conversation history is the right approach for interactive storytelling.

7. **Cloud agent as enhancement layer** — Correctly positions Tier 3 as optional for richer stories, analytics, and the parent dashboard.

---

## Part 3: Detailed Implementation Plan

### Phase 0: Pre-requisites & Model Layer (1–2 days)

#### 0.1 — Define `StoryBeat` model

- **File**: `SeeSaw/Model/StoryBeat.swift`
- Import `FoundationModels`
- Define `@Generable struct StoryBeat` with `@Guide` annotations on every field:
  - `storyText: String` — @Guide("3–5 sentences, age-appropriate story segment")
  - `question: String` — @Guide("One open-ended imaginative question")
  - `isEnding: Bool` — @Guide("True when the story should conclude")
  - `theme: String` — @Guide("Current story theme")
  - `suggestedContinuation: String` — @Guide("Brief context hint for next turn, not spoken")

```swift
import FoundationModels

@Generable
struct StoryBeat: Sendable {
    @Guide(description: "A short story segment of 3-5 sentences, age-appropriate, to be spoken aloud")
    var storyText: String

    @Guide(description: "One open-ended imaginative question for the child to answer")
    var question: String

    @Guide(description: "True only when the story should reach its conclusion")
    var isEnding: Bool

    @Guide(description: "Current story theme such as adventure, friendship, or discovery")
    var theme: String

    @Guide(description: "Brief internal context hint for the next turn, never spoken aloud")
    var suggestedContinuation: String
}
```

#### 0.2 — Define `StoryGenerationMode` enum

- **File**: `SeeSaw/Model/StoryGenerationMode.swift`
- Cases: `.onDevice`, `.cloud`, `.hybrid`
- Persisted in `UserDefaults` with a default of `.onDevice`

```swift
enum StoryGenerationMode: String, CaseIterable, Sendable {
    case onDevice = "onDevice"
    case cloud    = "cloud"
    case hybrid   = "hybrid"
}
```

#### 0.3 — Define `StoryError` enum

- **File**: `SeeSaw/Model/StoryError.swift`
- Provide comprehensive error cases for all failure modes

```swift
enum StoryError: LocalizedError, Sendable {
    case noActiveSession
    case modelUnavailable
    case modelDownloading
    case contextWindowExceeded
    case guardrailViolation
    case generationFailed(String)

    var errorDescription: String? {
        switch self {
        case .noActiveSession:        return "No active story session."
        case .modelUnavailable:       return "On-device model is not available on this device."
        case .modelDownloading:       return "On-device model is still downloading."
        case .contextWindowExceeded:  return "Story session exceeded context limit."
        case .guardrailViolation:     return "Content was blocked by safety filters."
        case .generationFailed(let m): return "Story generation failed: \(m)"
        }
    }
}
```

#### 0.4 — Define `SceneContext` struct

- **File**: `SeeSaw/Model/SceneContext.swift`
- Bridge between `PipelineResult` and the story service

```swift
struct SceneContext: Sendable {
    let labels: [String]
    let sceneCategories: [String]
    let transcript: String?
    let childAge: Int

    init(from payload: ScenePayload) {
        self.labels          = payload.objects
        self.sceneCategories = payload.scene
        self.transcript      = payload.transcript
        self.childAge        = payload.childAge
    }
}
```

---

### Phase 1: Core On-Device Story Service (2–3 days)

#### 1.1 — Create `OnDeviceStoryService`

- **File**: `SeeSaw/Services/AI/OnDeviceStoryService.swift`
- Declare as `actor OnDeviceStoryService`

**Key implementation requirements:**

1. **Availability check**: Check `SystemLanguageModel.default.availability` before every session start. Handle `.available`, `.downloading`, `.unavailable` states.
2. **Session management**: Hold `private var session: LanguageModelSession?`
3. **Context window monitoring**: Track approximate token usage via `session.tokenCount(for:)` API (iOS 26.4+).
4. **Sliding window**: When approaching ~3,500 tokens (safety margin under 4,096), summarise the oldest 2 turns into a single sentence and start a new session with the summary as context.
5. **Correct API usage**: Use `session.respond(to:, generating:)` for initial implementation; upgrade to `session.streamResponse(to:, generating:)` in Phase 3.

```swift
import FoundationModels

actor OnDeviceStoryService {

    // MARK: - State

    private var session: LanguageModelSession?
    private var turnCount = 0
    private let maxTurns = 6  // Conservative due to 4096 token limit
    private var conversationSummary: String?

    // MARK: - Public API

    var isSessionActive: Bool { session != nil }
    var currentTurnCount: Int { turnCount }

    func checkAvailability() async -> Bool {
        let model = SystemLanguageModel.default
        return model.availability == .available
    }

    func startStory(context: SceneContext, profile: ChildProfile) async throws -> StoryBeat {
        let model = SystemLanguageModel.default
        guard model.availability == .available else {
            throw StoryError.modelUnavailable
        }

        session = LanguageModelSession(
            model: model,
            instructions: buildSystemPrompt(context: context, profile: profile)
        )
        turnCount = 0
        conversationSummary = nil

        let prompt = """
        The child is looking at: \(context.labels.joined(separator: ", ")).
        \(context.transcript.map { "They said: '\($0)'" } ?? "")
        Start the story now. Make it exciting from the very first sentence.
        """

        return try await generateWithErrorRecovery(prompt: prompt)
    }

    func continueTurn(childAnswer: String) async throws -> StoryBeat {
        guard let session else { throw StoryError.noActiveSession }
        turnCount += 1

        let isNearEnd = turnCount >= maxTurns - 1
        let prompt = """
        The child answered: "\(childAnswer)"
        Continue the story, incorporating their answer naturally.
        \(isNearEnd ? "This is near the end — start wrapping up warmly." : "")
        """

        return try await generateWithErrorRecovery(prompt: prompt)
    }

    func endSession() {
        session = nil
        turnCount = 0
        conversationSummary = nil
    }

    // MARK: - Private

    private func generateWithErrorRecovery(prompt: String) async throws -> StoryBeat {
        guard let session else { throw StoryError.noActiveSession }

        do {
            let response = try await session.respond(
                to: prompt,
                generating: StoryBeat.self
            )
            return response.content
        } catch let error as LanguageModelSession.GenerationError {
            switch error {
            case .exceededContextWindowSize:
                return try await restartWithSummary(lastPrompt: prompt)
            case .guardrailViolation:
                return try await retrySoftened(originalPrompt: prompt)
            default:
                throw StoryError.generationFailed(error.localizedDescription)
            }
        }
    }

    private func restartWithSummary(lastPrompt: String) async throws -> StoryBeat {
        // Summarise the story so far and start a new session
        let summary = conversationSummary ?? "An interactive story is in progress."
        endSession()

        let model = SystemLanguageModel.default
        session = LanguageModelSession(
            model: model,
            instructions: """
            Continue an ongoing story. Story so far: \(summary)
            Keep the same warm, imaginative tone.
            """
        )
        turnCount = 0

        guard let session else { throw StoryError.noActiveSession }
        let response = try await session.respond(
            to: lastPrompt,
            generating: StoryBeat.self
        )
        return response.content
    }

    private func retrySoftened(originalPrompt: String) async throws -> StoryBeat {
        guard let session else { throw StoryError.noActiveSession }
        let softenedPrompt = """
        Continue the story in a gentle, positive direction.
        Keep the tone warm and friendly.
        """
        let response = try await session.respond(
            to: softenedPrompt,
            generating: StoryBeat.self
        )
        return response.content
    }

    private func buildSystemPrompt(context: SceneContext, profile: ChildProfile) -> String {
        // Keep under ~300 tokens to preserve context budget
        """
        You are Whisper, a warm storytelling companion for \(profile.name), \
        aged \(profile.age).
        Generate short story segments (3-5 sentences).
        End every beat with one imaginative question.
        Use detected objects: \(context.labels.joined(separator: ", ")).
        Match vocabulary to age \(profile.age).
        Never mention technology, devices, or AI.
        Never include violence or inappropriate content.
        """
    }
}
```

---

### Phase 2: ViewModel & Pipeline Integration (1–2 days)

#### 2.1 — Register `OnDeviceStoryService` in `AppDependencyContainer`

- Add `let onDeviceStoryService = OnDeviceStoryService()` to the container
- Pass to `CompanionViewModel` via init

#### 2.2 — Add `StoryGenerationMode` to `CompanionViewModel`

- New property: `var storyMode: StoryGenerationMode` (backed by UserDefaults)
- Expose in SettingsView for user control

#### 2.3 — Update `SessionState` enum

Add new cases to represent the on-device story loop:

```swift
enum SessionState: Equatable, Sendable {
    // ... existing cases ...
    case generatingStory     // On-device LLM is generating
    case listeningForAnswer  // Waiting for child's spoken response
}
```

#### 2.4 — New pipeline method: `runOnDevicePipeline(jpegData:)`

Flow:

1. Run privacy pipeline (unchanged): `privacyPipeline.process(jpegData:, childAge:) → PipelineResult`
2. Build `SceneContext` from `result.payload`
3. Call `onDeviceStoryService.startStory(context:, profile:)` → `StoryBeat`
4. Synthesise `beat.storyText` via `audioService.generateAndEncodeAudio(from:)` → PCM Data
5. Send audio via `accessoryManager.activeAccessory.sendAudio(data)`
6. Synthesise and send `beat.question`
7. Listen for child's answer via `speechRecognitionService`
8. Call `onDeviceStoryService.continueTurn(childAnswer:)` → next `StoryBeat`
9. Loop until `beat.isEnding == true` or `maxTurns` reached

```swift
private func runOnDevicePipeline(jpegData: Data) async {
    do {
        // Stage 1-5: Privacy pipeline (unchanged)
        sessionState = .processingPrivacy
        let result = try await privacyPipeline.process(jpegData: jpegData, childAge: childAge)
        await metricsStore.record(result.metrics)

        // Build context for story service
        let context = SceneContext(from: result.payload)
        let profile = ChildProfile(
            name: UserDefaults.standard.childName,
            age: childAge,
            preferences: UserDefaults.standard.childPreferences
        )

        // Stage 6: Generate story beat on-device
        sessionState = .generatingStory
        let beat = try await onDeviceStoryService.startStory(
            context: context,
            profile: profile
        )

        // Stage 7: Speak story text
        sessionState = .encodingAudio
        let storyAudio = try await audioService.generateAndEncodeAudio(from: beat.storyText)
        sessionState = .sendingAudio
        try await accessoryManager.activeAccessory.sendAudio(storyAudio)

        // Stage 8: Speak question
        let questionAudio = try await audioService.generateAndEncodeAudio(from: beat.question)
        try await accessoryManager.activeAccessory.sendAudio(questionAudio)

        // Record timeline entry
        let entry = TimelineEntry(
            sceneObjects: result.payload.objects,
            storySnippet: String(beat.storyText.prefix(120))
        )
        timeline.insert(entry, at: 0)

        // Stage 9: Listen for answer and continue loop
        if !beat.isEnding {
            await continueStoryLoop()
        }

        sessionState = .connected
    } catch {
        setError(error.localizedDescription)
    }
}

private func continueStoryLoop() async {
    sessionState = .listeningForAnswer
    // Start recording and wait for child's answer
    // ... (uses speechRecognitionService)
    // Then call onDeviceStoryService.continueTurn(childAnswer:)
    // Loop until isEnding or maxTurns
}
```

#### 2.5 — Update `runFullPipeline()` routing

Check `storyMode` to determine which pipeline to use:

```swift
private func runFullPipeline(jpegData: Data) async {
    switch storyMode {
    case .onDevice:
        await runOnDevicePipeline(jpegData: jpegData)
    case .cloud:
        await runCloudPipeline(jpegData: jpegData) // existing implementation
    case .hybrid:
        await runHybridPipeline(jpegData: jpegData) // on-device first, cloud in parallel
    }
}
```

---

### Phase 3: Streaming & Audio Optimisation (1–2 days)

#### 3.1 — Implement streaming story generation

Use `session.streamResponse(to:, generating: StoryBeat.self)`:

```swift
let stream = session.streamResponse(to: prompt, generating: StoryBeat.self)
for try await partialBeat in stream {
    // As soon as storyText is partially populated, begin TTS
    if let text = partialBeat.storyText, !text.isEmpty {
        await beginIncrementalTTS(text)
    }
}
```

This achieves the "< 1 second to first word" latency target.

#### 3.2 — Sentence-level audio streaming

- Split streamed `storyText` by sentence boundaries
- Synthesise and send each sentence to BLE as soon as it's complete
- Queue sentences to avoid gaps between audio playback

---

### Phase 4: UI Updates (1 day)

#### 4.1 — Add story mode picker to SettingsView/SettingsTabView

- Segmented control: "On-Device" / "Cloud" / "Hybrid"
- Show model availability status indicator
- Grey out "On-Device" if model unavailable

#### 4.2 — Add story generation status to CameraTabView

- Show current turn number and session state
- Show "Generating story..." indicator during on-device generation
- Display guardrail violation warnings if they occur

#### 4.3 — Update StatusView

- Display model download progress if `availability == .downloading`
- Show "Apple Intelligence required" notice if model unavailable

---

### Phase 5: Testing (1–2 days)

#### 5.1 — Unit tests for `OnDeviceStoryService`

- Test session lifecycle: start → continue → end
- Test context window overflow handling
- Test error recovery paths (guardrail, unavailable model)
- Test turn counting and max turns enforcement
- Test `SceneContext` construction from `ScenePayload`

#### 5.2 — Unit tests for `StoryBeat` model

- Test `@Generable` conformance
- Test field presence and types

#### 5.3 — Integration tests

- Mock `LanguageModelSession` (or use protocol abstraction)
- Test full pipeline flow: image → privacy → story → TTS → audio send

---

### Phase 6: Documentation & Cleanup (0.5 day)

#### 6.1 — Update `Apple Foundation Models.md`

- Fix all API method names (`.generate()` → `.respond()`)
- Add context window management section
- Fix iOS version references (18 → 26)
- Add error handling section
- Add availability checking section

#### 6.2 — Update `PROJECT_STATUS.md`

- Add new tickets for Foundation Models integration
- Update architecture diagram

---

## Part 4: Key Architectural Decisions

### Decision 1: Protocol abstraction for story generation

Create a `StoryGenerating` protocol that both `OnDeviceStoryService` and `CloudAgentService` can conform to. This enables clean mode switching and testability:

```swift
protocol StoryGenerating: Sendable {
    func generateStory(context: SceneContext, profile: ChildProfile) async throws -> StoryBeat
    func continueTurn(childAnswer: String) async throws -> StoryBeat
    func endSession()
}
```

### Decision 2: Context window management strategy

Use a **"sliding summary"** approach:

1. After every turn, check remaining token budget
2. When budget drops below ~800 tokens, summarise all turns except the latest into a 1–2 sentence recap
3. Create a new session with the recap as system prompt context
4. This is invisible to the child — the story continues seamlessly

### Decision 3: Graceful degradation chain

```
On-Device (preferred) → Cloud (fallback) → Error (last resort)
```

If Foundation Models is unavailable (wrong device, model downloading, Apple Intelligence disabled), automatically fall back to the existing cloud pipeline. If cloud is also unavailable, show a clear error message.

### Decision 4: No `@Tool` usage initially

While Apple supports tool calling, using it would consume precious context window tokens (tool schemas count toward the 4,096 limit). For the PoC, pass scene context directly in the prompt. Tool calling can be added later if the context budget allows.

### Decision 5: Keep `FoundationModels` import isolated

Only `OnDeviceStoryService.swift` and `StoryBeat.swift` should import `FoundationModels`. All other files interact through the `StoryGenerating` protocol and plain Swift types. This keeps the framework dependency minimal and testable.

---

## Part 5: Risk Register

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| 4,096 token limit causes sessions to terminate mid-story | High | High | Sliding window summarisation, reduce max turns to 5–6 |
| Guardrail blocks children's story content ("monster", "scary") | Medium | Medium | Retry with softened prompt, fallback to cloud |
| Model unavailable on test devices (requires iPhone 15 Pro+) | High | Medium | Cloud fallback, test on simulator with mocks |
| 3B model produces low-quality stories for younger children (ages 3–4) | Medium | Medium | Extensive prompt engineering, `@Guide` constraints |
| Apple changes Foundation Models API in future iOS updates | Low | Low | Protocol abstraction insulates app from API changes |
| Latency exceeds targets when Neural Engine is under load | Medium | Low | Streaming mitigates perceived latency |
| `@Generable` struct fails to parse model output | Medium | Low | Fallback to plain text response, retry logic |
| Privacy pipeline + LLM combined latency exceeds 8s target | Medium | Low | Privacy pipeline is 210ms; LLM generation should be <2s; well within budget |

---

## Part 6: Estimated File Changes

### New Files (8)

| File | Purpose |
|------|---------|
| `SeeSaw/Model/StoryBeat.swift` | `@Generable` struct for on-device LLM output |
| `SeeSaw/Model/StoryGenerationMode.swift` | Mode enum (onDevice / cloud / hybrid) |
| `SeeSaw/Model/StoryError.swift` | Error types for story generation |
| `SeeSaw/Model/SceneContext.swift` | Bridge struct: PipelineResult → story service |
| `SeeSaw/Services/AI/OnDeviceStoryService.swift` | Core actor — session management, generation, context window |
| `SeeSawTests/OnDeviceStoryServiceTests.swift` | Unit tests for story service |
| `SeeSawTests/StoryBeatTests.swift` | Unit tests for StoryBeat model |
| `SeeSawTests/SceneContextTests.swift` | Unit tests for SceneContext bridge |

### Modified Files (5)

| File | Change |
|------|--------|
| `SeeSaw/App/AppDependencyContainer.swift` | Register `OnDeviceStoryService` |
| `SeeSaw/ViewModel/CompanionViewModel.swift` | Add `storyMode`, on-device pipeline routing, turn loop |
| `SeeSaw/Model/SessionState.swift` | Add `.generatingStory`, `.listeningForAnswer` cases |
| `SeeSaw/View/Home/SettingsTabView.swift` | Add story mode picker UI |
| `SeeSaw/Extensions/UserDefaults+Settings.swift` | Add `storyMode` persistence key |

### Optionally Modified (2)

| File | Change |
|------|--------|
| `SeeSaw/View/Home/CameraTabView.swift` | Story generation status indicator |
| `SeeSaw/View/StatusView.swift` | Model availability indicator |

**Total: 8 new files, 5–7 modified files**

---

## Appendix: Correct API Reference

### Foundation Models Framework — Key APIs Used

| API | Usage |
|-----|-------|
| `SystemLanguageModel.default` | Access the on-device language model |
| `SystemLanguageModel.availability` | Check if model is `.available`, `.downloading`, or `.unavailable` |
| `LanguageModelSession(model:instructions:)` | Create a conversation session with system prompt |
| `session.respond(to:generating:)` | Generate structured output (full response) |
| `session.streamResponse(to:generating:)` | Generate structured output (streaming partial results) |
| `session.contextSize` | Get maximum context window size (iOS 26.4+) |
| `session.tokenCount(for:)` | Count tokens in a string (iOS 26.4+) |
| `@Generable` macro | Mark structs for guided structured generation |
| `@Guide` macro | Add constraints/descriptions to `@Generable` fields |
| `LanguageModelSession.GenerationError` | Error types: `.exceededContextWindowSize`, `.guardrailViolation` |

### References

- [Apple Developer: Foundation Models](https://developer.apple.com/documentation/foundationmodels)
- [Apple Developer: LanguageModelSession](https://developer.apple.com/documentation/foundationmodels/languagemodelsession)
- [Apple TN3193: Managing Context Window](https://developer.apple.com/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window)
- [WWDC25-286: Meet the Foundation Models Framework](https://wwdcnotes.com/documentation/wwdcnotes/wwdc25-286-meet-the-foundation-models-framework/)
- [Apple: Expanding Generation with Tool Calling](https://developer.apple.com/documentation/foundationmodels/expanding-generation-with-tool-calling)
- [Apple Intelligence Foundation Language Models Tech Report 2025](https://arxiv.org/abs/2507.13575)


Here is the critical evaluation — direct, honest, and structured for immediate action.

***
## Critical Analysis: Apple Foundation Models — Implementation Plan
### What the Plan Does Well
**Structural completeness is strong.** The plan covers all five pipeline stages (camera capture → YOLO detection → context assembly → Apple FM → story narration) in the correct sequence. The stage-by-stage breakdown with estimated hours, Swift actor isolation, and the `SceneContext` struct design are all sound architectural decisions that map well onto the dissertation's implementation chapter.

**The privacy-first design is correctly foregrounded.** Using `VNDetectFaceRectanglesRequest` to generate bounding boxes and then explicitly not passing raw frames downstream is the correct structural privacy pattern. The plan names this clearly, which is essential for Chapter 4.

**The fallback chain is well-considered.** The three-mode fallback (Apple FM → structured template → minimal response) demonstrates defensive programming maturity that an examiner will notice positively.

***
### Critical Gaps — What the Plan Is Missing
#### Gap 1: The Benchmark Is Not in the Plan (Highest Priority)

This is the most serious omission. The implementation plan describes *building* the pipeline but contains **zero specification for measuring it**. The Single Most Valuable Recommendation explicitly states the benchmark (PII transmission count, latency per stage, battery, story quality rating) is the distinction-level contribution — yet the implementation plan has no instrumentation code, no Charles Proxy/Instruments logging hooks, no test input set, and no results collection mechanism.

**What needs to be added immediately:**
- A `BenchmarkLogger` service that records timestamps at each pipeline stage boundary
- A `NetworkInterceptor` flag that routes Architecture A (cloud-baseline) traffic through a Charles Proxy session
- A defined set of 20 fixed test inputs (10 photos + 10 audio clips) stored in the test bundle
- A `BenchmarkSession` struct that serialises results to CSV for Chapter 6

Without this, the plan builds a working system that cannot prove its core research claim.

#### Gap 2: No Baseline Architecture A Implementation

The benchmark requires three architectures to compare. The plan implements **only Architecture C** (on-device SeeSaw). Architecture A (raw data sent to cloud) and Architecture B (filtered labels sent to cloud) are never mentioned. Without the baseline, there is nothing to benchmark *against* — the privacy claim has no counterfactual.

Architecture A needs only 30 minutes to implement: a dummy `CloudBaselineService` that takes the raw `UIImage` + `AVAudioPCMBuffer`, serialises them, and sends to a controlled endpoint (even localhost). Charles Proxy intercepts this and counts bytes/PII items. This is the entire counterfactual.

#### Gap 3: Story Quality Evaluation Protocol Is Absent

The recommendation specifies a 5-point Likert scale, 3 raters, 10 stories per architecture. The plan has no mention of:
- How story beats are exported for human rating
- What the rating criteria are (relevance, creativity, age-appropriateness)
- Who the three raters are
- How inter-rater agreement is calculated (Cohen's Kappa minimum)

This evaluation is what makes Chapter 6 academically credible. Without it, the results chapter has only latency numbers and byte counts — technically interesting but insufficient to claim story *quality* is preserved.

#### Gap 4: The YOLO11n Integration Is Assumed, Not Specified

The plan repeatedly references YOLO11n-SeeSaw CoreML output as the input to Apple FM, but never specifies:
- The exact `CoreML` model call and output format
- How confidence thresholds are applied (what is the cutoff? 0.5? 0.7?)
- How multiple detections are ranked/filtered before passing to `SceneContext`
- Whether the model handles the "no objects detected" edge case gracefully

This matters because the dissertation's Chapter 4 must describe the YOLO integration as an original contribution (the custom-trained dataset). If the plan glosses over this, the implementation chapter will be thin precisely where the examiners will look hardest.

#### Gap 5: Latency Targets Are Aspirational, Not Validated

The plan states "target: 400ms total end-to-end latency" but provides no methodology for measuring this or what happens if the target is missed. Instruments profiling is not mentioned anywhere. This is a problem: if the submitted dissertation claims 400ms but you have never actually measured it, an examiner can trivially disprove it during the viva.

**Fix:** Add a mandatory Instruments profiling session as a named task (Day 3 of the sprint). Record actual mean and P95 latency for each stage separately. Report the real number, not the target — if it is 750ms, that is still fast enough to argue the system is usable, and honesty is always stronger than unverified claims.

#### Gap 6: Swift Concurrency Architecture Has a Threading Risk

The plan uses `actor` isolation for `OnDeviceStoryOrchestrator`, which is correct. However, the camera capture pipeline (`AVCaptureSession`) runs on a dedicated serial queue, and calling `await orchestrator.processFrame()` from inside a `CMSampleBuffer` delegate callback creates a risk of dropping frames if the inference queue backs up. The plan does not specify:
- Whether frame dropping is intentional (it should be — process only 1 frame per story beat, not every camera frame)
- How the `AVCaptureSession` callback is bridged to the Swift concurrency domain safely
- Whether `@MainActor` is correctly isolated from the inference pipeline

This is a legitimate implementation bug risk that could cause the demo to freeze during the live demo or video recording.

**Fix:** Add a `frameDropPolicy: .dropWhenBusy` flag and a `Task.detached` dispatch from the capture callback, explicitly not awaiting the result inside the delegate.

***
### What the Recommendation Doc Is Missing (Addenda)
The Single Most Valuable Recommendation document is strategically correct but has two gaps relative to what is needed for submission:

**Missing: A Chapter 6 Results Table Template**

The dissertation examiner needs to see a clear comparison table. The recommendation describes the metrics but does not give you the exact table structure. Here it is — build your Chapter 6 around this:

| Metric | Architecture A (Cloud Raw) | Architecture B (Cloud Filtered) | Architecture C (SeeSaw On-Device) |
|--------|---------------------------|----------------------------------|-----------------------------------|
| PII items transmitted / session | *measured* | *measured* | **0** |
| Raw bytes transmitted / session | *measured* | *measured* | **0** |
| End-to-end latency (mean ms) | *measured* | *measured* | *measured* |
| Battery drain / 30 min (%) | *measured* | *measured* | *measured* |
| Story quality — relevance (mean/5) | *rated* | *rated* | *rated* |
| Story quality — creativity (mean/5) | *rated* | *rated* | *rated* |
| Story quality — age-appropriate (mean/5) | *rated* | *rated* | *rated* |

Every cell marked *measured* or *rated* is one day of work. Every cell you fill with a real number is a paragraph in Chapter 6 that writes itself.

**Missing: The Falsifiable Null Hypothesis**

The dissertation needs a clearly stated null hypothesis to elevate it to research-standard framing:

> **H₀:** A structurally privacy-preserving on-device architecture (Architecture C) produces story beats that are rated statistically equivalent in quality to cloud-dependent architectures (A and B), while transmitting zero personally identifiable information.

Stating and then either accepting or rejecting this hypothesis transforms Chapter 6 from "here are some numbers" into "here is a research finding." This single sentence is what separates a project report from a research dissertation.

***
### Priority Action List (in order)
1. **Add `BenchmarkLogger` to the iOS implementation plan** — instrument all five pipeline stages with timestamps
2. **Build Architecture A baseline** (`CloudBaselineService`, 30 min, intercept with Charles Proxy)
3. **Define the 20 fixed test inputs** — commit them to the test bundle today so all three architectures run on identical inputs
4. **Add the story quality rating protocol** — export beats to a simple Google Form, rate with 3 people, record results
5. **Run Instruments profiling** — get real latency numbers, replace "400ms target" with "X ms measured"
6. **State the null hypothesis** in the dissertation Introduction and return to it in Chapter 6

The implementation plan is a solid engineering document. With these additions, it becomes a research instrument — and that distinction is exactly what your examiner will reward.