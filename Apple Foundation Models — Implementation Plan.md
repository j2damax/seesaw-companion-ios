# Apple Foundation Models — Implementation Plan

**Project:** seesaw-companion-ios (Tier 2)  
**Date:** 6 April 2026  
**Status:** Planning → Ready for Implementation  
**Target:** iOS 26.0+ / iPhone 15 Pro+  

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [What Apple Foundation Models Provides](#2-what-apple-foundation-models-provides)
3. [Architectural Impact on SeeSaw](#3-architectural-impact-on-seesaw)
4. [Critical Analysis of Previous Plan](#4-critical-analysis-of-previous-plan)
5. [Corrected API Reference](#5-corrected-api-reference)
6. [Implementation Phases](#6-implementation-phases)
   - [Phase 0: Model Layer](#phase-0-model-layer-1-day)
   - [Phase 1: OnDeviceStoryService](#phase-1-ondevicestoryservice-2-3-days)
   - [Phase 2: ViewModel & Pipeline Integration](#phase-2-viewmodel--pipeline-integration-1-2-days)
   - [Phase 3: Streaming & Audio Optimisation](#phase-3-streaming--audio-optimisation-1-2-days)
   - [Phase 4: Interactive Story Loop](#phase-4-interactive-story-loop-1-2-days)
   - [Phase 5: UI Updates](#phase-5-ui-updates-1-day)
   - [Phase 6: Testing](#phase-6-testing-1-2-days)
   - [Phase 7: Benchmark Instrumentation](#phase-7-benchmark-instrumentation-1-2-days)
   - [Phase 8: Documentation](#phase-8-documentation-05-day)
7. [Key Architectural Decisions](#7-key-architectural-decisions)
8. [Context Window Management Strategy](#8-context-window-management-strategy)
9. [Error Handling & Graceful Degradation](#9-error-handling--graceful-degradation)
10. [Risk Register](#10-risk-register)
11. [File Change Inventory](#11-file-change-inventory)
12. [Benchmark Strategy](#12-benchmark-strategy)
13. [Dissertation Contribution](#13-dissertation-contribution)
14. [Appendix: API Quick Reference](#14-appendix-api-quick-reference)

---

## 1. Executive Summary

Apple's Foundation Models framework (iOS 26+, WWDC 2025) provides a ~3B parameter on-device LLM running on the Neural Engine. This enables SeeSaw to generate interactive children's stories **entirely on-device**, eliminating the cloud dependency for core functionality and providing **structural privacy guarantees** — no raw data ever leaves the device.

### What Changes

| Before (Cloud-Dependent) | After (On-Device First) |
|---|---|
| Privacy pipeline → POST `ScenePayload` to cloud → receive `StoryResponse` | Privacy pipeline → on-device LLM generates `StoryBeat` → TTS → BLE |
| Cloud agent required for story generation | Cloud agent becomes optional enhancement |
| Latency: ~3–5s (network round-trip) | Latency: < 1s to first word (streaming) |
| Privacy: "filtered before cloud" | Privacy: "structurally guaranteed — no network" |

### Scope

- **8 new files**, **6 modified files**, ~600–800 new lines of Swift
- **Zero new dependencies** — `FoundationModels` is a first-party Apple framework
- **Backward compatible** — existing cloud pipeline remains as fallback
- Estimated total effort: **8–12 days**

---

## 2. What Apple Foundation Models Provides

### On-Device LLM Capabilities

| Capability | API | SeeSaw Usage |
|---|---|---|
| Text generation | `LanguageModelSession.respond(to:)` | Story beat generation |
| Streaming generation | `LanguageModelSession.streamResponse(to:)` | Real-time TTS as text generates |
| Structured output | `@Generable` macro on Swift structs | Type-safe `StoryBeat` response |
| Field constraints | `@Guide` macro with descriptions/ranges | Enforce story length, question format |
| Conversation history | `LanguageModelSession` transcript | Multi-turn story continuation |
| System instructions | `LanguageModelSession(instructions:)` | Whisper persona, age-appropriate rules |
| Tool calling | `Tool` protocol | Future: scene context injection |
| Content safety | Built-in guardrail classifiers | Automatic child-safe content filtering |
| Context window | 4,096 tokens (input + output + history) | Requires sliding window management |
| Availability check | `SystemLanguageModel.default.availability` | Graceful fallback to cloud |
| Token counting | `session.tokenCount(for:)` (iOS 26.4+) | Budget monitoring |

### Hardware Requirements

- **Minimum device:** iPhone 15 Pro / Pro Max (A17 Pro Neural Engine)
- **Minimum OS:** iOS 26.0
- **Prerequisite:** Apple Intelligence must be enabled in Settings
- **Model state:** On-device model must be downloaded (`.available` status)

### What's Already Built (No Changes Needed)

| Component | Status |
|---|---|
| Face detection + blur (VNDetectFaceRectanglesRequest + CIGaussianBlur σ=30) | ✅ Complete |
| Object detection (YOLO11n, 43 classes, conf ≥ 0.25) | ✅ Complete |
| Scene classification (VNClassifyImageRequest, conf ≥ 0.3) | ✅ Complete |
| On-device STT (SFSpeechRecognizer, `requiresOnDeviceRecognition = true`) | ✅ Complete |
| PII scrubbing (PIIScrubber, 8 pattern types) | ✅ Complete |
| TTS synthesis (AVSpeechSynthesizer, en-GB, rate 0.85x, pitch 1.1x) | ✅ Complete |
| BLE audio chunking + 20ms pacing | ✅ Complete |
| Privacy metrics + CSV export | ✅ Complete |
| Cloud story service (CloudAgentService, POST /story) | ✅ Complete (becomes fallback) |

---

## 3. Architectural Impact on SeeSaw

### Three Operating Modes

```
┌─────────────────────────────────────────────────────────────────┐
│ Mode A: Fully On-Device (No Internet Required)                  │
│                                                                  │
│ Tier 1 (AiSee) ──BLE──▶ Tier 2 (iPhone)                       │
│                          ├─ Privacy Pipeline (6 stages)         │
│                          ├─ FoundationModels LLM → StoryBeat   │
│                          ├─ AVSpeechSynthesizer → PCM audio     │
│                          └──BLE──▶ Tier 1 (AiSee speaker)      │
│                                                                  │
│ Privacy: Absolute — nothing leaves device                       │
│ Latency: < 1s to first word (streaming)                         │
│ Quality: Good (3B parameter model)                              │
├─────────────────────────────────────────────────────────────────┤
│ Mode B: Hybrid (Internet Available)                             │
│                                                                  │
│ Same as Mode A, plus:                                           │
│ └─ Parallel cloud dispatch → richer story (Tier 3)             │
│ └─ Parent dashboard sync, analytics                            │
│                                                                  │
│ Strategy: Play on-device story immediately; optionally          │
│           upgrade to cloud story if it arrives in time          │
├─────────────────────────────────────────────────────────────────┤
│ Mode C: Offline Story Mode (No BLE, No Internet)               │
│                                                                  │
│ Child interacts directly with iPhone (mic + speaker)            │
│ Same FoundationModels pipeline, no AiSee required               │
│ Useful for standalone mode or testing                           │
└─────────────────────────────────────────────────────────────────┘
```

### Updated Data Flow

```
AiSee Headset / iPhone Camera (Tier 1)
    │ JPEG + Audio via BLE / local capture
    ▼
┌─── PRIVACY PIPELINE (unchanged, 210ms) ────────────────────────┐
│ Stage 1: VNDetectFaceRectanglesRequest → face bounding boxes   │
│ Stage 2: CIGaussianBlur (σ=30) → anonymised frame             │
│ Stage 3: VNCoreMLRequest (YOLO11n) → object labels             │
│ Stage 4: VNClassifyImageRequest → scene categories             │
│ Stage 5: SFSpeechRecognizer (on-device) → child transcript     │
│ Stage 6: PIIScrubber → sanitised transcript                    │
│ Output: PipelineResult { ScenePayload + PrivacyMetricsEvent }  │
└────────────────────────────────────────────────────────────────┘
    │ ScenePayload → SceneContext
    ▼
┌─── ON-DEVICE STORY GENERATION (NEW) ──────────────────────────┐
│ OnDeviceStoryService (actor)                                   │
│ ├─ Build system prompt with Whisper persona                    │
│ ├─ Create LanguageModelSession(instructions:)                  │
│ ├─ session.respond(to:, generating: StoryBeat.self)            │
│ ├─ Or: session.streamResponse(to:, generating: StoryBeat.self) │
│ ├─ Context window monitoring (4,096 token limit)               │
│ ├─ Sliding window summarisation on overflow                    │
│ └─ Error recovery: guardrail retry, cloud fallback             │
│ Output: StoryBeat { storyText, question, isEnding, theme }     │
└────────────────────────────────────────────────────────────────┘
    │ StoryBeat.storyText + StoryBeat.question
    ▼
┌─── AUDIO + INTERACTION LOOP ──────────────────────────────────┐
│ 1. AudioService → TTS for storyText → PCM audio               │
│ 2. WearableAccessory.sendAudio() → BLE/speaker                │
│ 3. AudioService → TTS for question → PCM audio                │
│ 4. WearableAccessory.sendAudio() → BLE/speaker                │
│ 5. SpeechRecognitionService → child's answer                   │
│ 6. PIIScrubber → sanitise answer                               │
│ 7. OnDeviceStoryService.continueTurn() → next StoryBeat       │
│ 8. Loop until isEnding == true or maxTurns reached             │
└────────────────────────────────────────────────────────────────┘
```

---

## 4. Critical Analysis of Previous Plan

The original `Apple Foundation Models.md` and its code examples contain several errors that must be corrected before implementation. These are documented here for traceability.

### 🔴 Critical Errors (Must Fix Before Coding)

| # | Issue | Current (Wrong) | Correct | Impact |
|---|-------|-----------------|---------|--------|
| 1 | **Wrong API method** | `session.generate(StoryBeat.self, prompt:)` | `session.respond(to:, generating: StoryBeat.self)` | Compilation failure |
| 2 | **iOS version** | "iOS 18+" | "iOS 26+" | Misleading documentation |
| 3 | **Context window not addressed** | No mitigation strategy | Sliding window summarisation required | Session crashes at turn 4–5 |
| 4 | **Force unwrap** | `session!.generate(...)` | `guard let session else { throw }` | Violates project standards |
| 5 | **No availability check** | Model assumed present | Must check `SystemLanguageModel.default.availability` | Crash on unsupported devices |

### 🟡 Significant Issues (Should Fix)

| # | Issue | Detail |
|---|-------|--------|
| 6 | Streaming not used | Code uses blocking `.respond()` despite claiming "< 1s to first word" |
| 7 | `@Guide` annotations missing | `StoryBeat` fields have no schema-level guidance for the LLM |
| 8 | Pipeline signature mismatch | Doc uses `process(jpeg:, audio:)` but actual API is `process(jpegData:, childAge:)` returning `PipelineResult` |
| 9 | `bleService.sendAudioToDevice(text:)` doesn't exist | Must use `audioService.generateAndEncodeAudio(from:)` then `accessory.sendAudio()` |
| 10 | No guardrail error handling | Words like "monster", "scary" could trigger `.guardrailViolation` in children's context |

### 🟢 What the Plan Gets Right

1. **Core thesis is correct** — on-device story generation eliminates cloud dependency
2. **Privacy argument is academically stronger** — "structurally guaranteed" vs "filtered before cloud"
3. **Three-mode strategy (A/B/C) is well-designed** — graceful degradation
4. **`@Generable StoryBeat` concept is correct** — type-safe structured output
5. **Actor-based `OnDeviceStoryService` follows project conventions**
6. **Turn-management via `LanguageModelSession` is the right approach**

---

## 5. Corrected API Reference

### Verified API Methods (from Apple Developer Documentation)

```swift
import FoundationModels

// MARK: - Model access
let model = SystemLanguageModel.default
let availability = model.availability  // .available | .downloading | .unavailable

// MARK: - Session creation
let session = LanguageModelSession(
    model: model,
    instructions: "System prompt here..."
)

// MARK: - Full response (blocking)
let response = try await session.respond(
    to: "User prompt",
    generating: StoryBeat.self
)
let beat: StoryBeat = response.content

// MARK: - Streaming response
let stream = session.streamResponse(
    to: "User prompt",
    generating: StoryBeat.self
)
for try await partial in stream {
    // partial.storyText available incrementally
}

// MARK: - Context window management (iOS 26.4+)
let contextSize = session.contextSize           // Max tokens (4096)
let tokenCount = session.tokenCount(for: prompt) // Tokens in string

// MARK: - Error handling
catch let error as LanguageModelSession.GenerationError {
    switch error {
    case .exceededContextWindowSize:  // Session must be restarted
    case .guardrailViolation:        // Content blocked by safety filter
    default: break
    }
}
```

### @Generable and @Guide Macros

```swift
@Generable
struct StoryBeat: Sendable {
    @Guide(description: "3-5 sentences, age-appropriate story segment to speak aloud")
    var storyText: String

    @Guide(description: "One open-ended imaginative question for the child")
    var question: String

    @Guide(description: "True only when the story should conclude")
    var isEnding: Bool

    @Guide(description: "Current story theme: adventure, friendship, discovery, etc.")
    var theme: String

    @Guide(description: "Brief context hint for next turn, not spoken aloud")
    var suggestedContinuation: String
}
```

### Tool Protocol (Future — Not Used in Initial Implementation)

```swift
struct SceneContextTool: Tool {
    let name = "getSceneContext"
    let description = "Get the current scene objects and categories detected by the camera"

    @Generable struct Arguments {
        @Guide(description: "Whether to include scene categories") let includeScene: Bool
    }

    func call(arguments: Arguments) async throws -> String {
        // Return scene labels from cached PipelineResult
    }
}
```

> **Decision:** Tool calling is deferred to a future phase. Tool schemas consume context window tokens (counted toward the 4,096 limit). For the PoC, scene context is passed directly in the prompt.

---

## 6. Implementation Phases

### Phase 0: Model Layer (1 day)

**Goal:** Define all new model types needed for Foundation Models integration.

#### 0.1 — `StoryBeat.swift`

**File:** `SeeSaw/Model/StoryBeat.swift`

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

**Notes:**
- `@Generable` requires `var` (not `let`) for all properties
- `@Guide` provides schema-level descriptions that the LLM uses to constrain output
- `Sendable` conformance required for actor isolation
- This is the **only model file** that imports `FoundationModels`

#### 0.2 — `StoryGenerationMode.swift`

**File:** `SeeSaw/Model/StoryGenerationMode.swift`

```swift
enum StoryGenerationMode: String, CaseIterable, Sendable {
    case onDevice = "onDevice"
    case cloud    = "cloud"
    case hybrid   = "hybrid"

    var displayName: String {
        switch self {
        case .onDevice: return "On-Device"
        case .cloud:    return "Cloud"
        case .hybrid:   return "Hybrid"
        }
    }

    var description: String {
        switch self {
        case .onDevice: return "Stories generated entirely on iPhone. Maximum privacy."
        case .cloud:    return "Stories generated by cloud AI. Requires internet."
        case .hybrid:   return "On-device first, cloud enhancement when available."
        }
    }
}
```

#### 0.3 — `StoryError.swift`

**File:** `SeeSaw/Model/StoryError.swift`

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
        case .noActiveSession:
            return "No active story session."
        case .modelUnavailable:
            return "On-device model is not available. Apple Intelligence must be enabled on iPhone 15 Pro or later."
        case .modelDownloading:
            return "On-device model is still downloading. Please wait."
        case .contextWindowExceeded:
            return "Story session exceeded context limit. Starting fresh."
        case .guardrailViolation:
            return "Content was adjusted by safety filters."
        case .generationFailed(let detail):
            return "Story generation failed: \(detail)"
        }
    }
}
```

#### 0.4 — `SceneContext.swift`

**File:** `SeeSaw/Model/SceneContext.swift`

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

**Purpose:** Bridges `ScenePayload` (privacy pipeline output) → `OnDeviceStoryService` input. Decouples the story service from the privacy pipeline's internal types.

---

### Phase 1: OnDeviceStoryService (2–3 days)

**Goal:** Core actor managing LLM sessions, context windows, and error recovery.

**File:** `SeeSaw/Services/AI/OnDeviceStoryService.swift`

#### Key Implementation Requirements

1. **Availability check** before every session start
2. **Session lifecycle:** `startStory()` → `continueTurn()` → `endSession()`
3. **Context window monitoring** via `session.tokenCount(for:)` (iOS 26.4+)
4. **Sliding window summarisation** when approaching 3,500 tokens
5. **Guardrail violation recovery** with softened prompt retry
6. **Cloud fallback** when model is unavailable
7. **Max 6 turns** (conservative due to 4,096 token limit)

#### Actor Structure

```swift
import FoundationModels

actor OnDeviceStoryService {

    // MARK: - State

    private var session: LanguageModelSession?
    private var turnCount = 0
    private let maxTurns = 6
    private var conversationSummary: String?

    // MARK: - Public API

    var isSessionActive: Bool { session != nil }
    var currentTurnCount: Int { turnCount }

    func checkAvailability() -> ModelAvailabilityStatus {
        // Returns .available, .downloading, or .unavailable
    }

    func startStory(context: SceneContext, profile: ChildProfile) async throws -> StoryBeat {
        // 1. Check availability
        // 2. Create session with system prompt
        // 3. Build initial prompt from scene context
        // 4. Generate first StoryBeat
    }

    func continueTurn(childAnswer: String) async throws -> StoryBeat {
        // 1. Validate session exists
        // 2. Increment turn count
        // 3. Build prompt from child's answer
        // 4. Generate next StoryBeat with error recovery
    }

    func endSession() {
        // Clear session, reset turn count and summary
    }

    // MARK: - Private

    private func generateWithErrorRecovery(prompt: String) async throws -> StoryBeat {
        // Try generation; catch .exceededContextWindowSize and .guardrailViolation
        // On context overflow → restartWithSummary()
        // On guardrail → retrySoftened()
    }

    private func restartWithSummary(lastPrompt: String) async throws -> StoryBeat {
        // Summarise story so far, create new session, continue
    }

    private func retrySoftened(originalPrompt: String) async throws -> StoryBeat {
        // Retry with gentler, safer prompt
    }

    private func buildSystemPrompt(context: SceneContext, profile: ChildProfile) -> String {
        // Compact system prompt (~200-300 tokens) with:
        // - Whisper persona
        // - Child's name and age
        // - Detected objects
        // - Vocabulary matching rules
        // - Content safety rules
    }
}
```

#### System Prompt Strategy

The system prompt must be **compact** (~200–300 tokens) to preserve context budget:

```swift
private func buildSystemPrompt(context: SceneContext, profile: ChildProfile) -> String {
    """
    You are Whisper, a warm storytelling companion for \(profile.name), \
    aged \(profile.age).
    Generate short story segments (3-5 sentences).
    End every beat with one imaginative question.
    Use detected objects: \(context.labels.joined(separator: ", ")).
    Scene: \(context.sceneCategories.joined(separator: ", ")).
    Match vocabulary to age \(profile.age).
    Never mention technology, devices, or AI.
    Never include violence or inappropriate content.
    """
}
```

**Why compact?** At 4,096 total tokens, every token in the system prompt reduces space for conversation history. A 300-token system prompt leaves ~3,796 tokens for prompts + responses across all turns.

---

### Phase 2: ViewModel & Pipeline Integration (1–2 days)

**Goal:** Wire `OnDeviceStoryService` into the existing `CompanionViewModel` and add mode-based pipeline routing.

#### 2.1 — Register in `AppDependencyContainer`

**File:** `SeeSaw/App/AppDependencyContainer.swift`

Add:
```swift
let onDeviceStoryService = OnDeviceStoryService()
```

Pass to `CompanionViewModel` via its initializer.

#### 2.2 — Update `SessionState` enum

**File:** `SeeSaw/Model/SessionState.swift`

Add two new cases:
```swift
case generatingStory      // On-device LLM is generating a StoryBeat
case listeningForAnswer   // Waiting for child's spoken response to question
```

Update `displayTitle`, `isActive`, and `isConnected` computed properties to include these new cases.

#### 2.3 — Add `StoryGenerationMode` to `CompanionViewModel`

**File:** `SeeSaw/ViewModel/CompanionViewModel.swift`

Add:
- `var storyMode: StoryGenerationMode` property (backed by UserDefaults)
- `private let onDeviceStoryService: OnDeviceStoryService` dependency

#### 2.4 — Add `storyMode` to `UserDefaults+Settings`

**File:** `SeeSaw/Extensions/UserDefaults+Settings.swift`

Add:
```swift
var storyMode: StoryGenerationMode {
    get {
        let raw = string(forKey: "storyMode") ?? StoryGenerationMode.onDevice.rawValue
        return StoryGenerationMode(rawValue: raw) ?? .onDevice
    }
    set { set(newValue.rawValue, forKey: "storyMode") }
}
```

#### 2.5 — Pipeline routing in `CompanionViewModel`

Add a new `runOnDevicePipeline(jpegData:)` method and update `runFullPipeline()` to route based on `storyMode`:

```swift
private func runFullPipeline(jpegData: Data) async {
    switch storyMode {
    case .onDevice:
        await runOnDevicePipeline(jpegData: jpegData)
    case .cloud:
        await runCloudPipeline(jpegData: jpegData)   // existing implementation
    case .hybrid:
        await runHybridPipeline(jpegData: jpegData)  // on-device + parallel cloud
    }
}
```

**On-device pipeline flow:**

1. Run privacy pipeline: `privacyPipeline.process(jpegData:, childAge:)` → `PipelineResult`
2. Build `SceneContext` from `result.payload`
3. Build `ChildProfile` from UserDefaults
4. Call `onDeviceStoryService.startStory(context:, profile:)` → `StoryBeat`
5. Synthesise `beat.storyText` via `audioService.generateAndEncodeAudio(from:)`
6. Send audio via `accessoryManager.activeAccessory.sendAudio()`
7. Synthesise and send `beat.question`
8. If `!beat.isEnding` → enter interactive story loop (Phase 4)

---

### Phase 3: Streaming & Audio Optimisation (1–2 days)

**Goal:** Use streaming generation for sub-second time-to-first-word.

#### 3.1 — Streaming Story Generation

Replace blocking `.respond()` with `.streamResponse()` for the primary generation path:

```swift
let stream = session.streamResponse(to: prompt, generating: StoryBeat.self)
for try await partialBeat in stream {
    if let text = partialBeat.storyText, !text.isEmpty {
        await beginIncrementalTTS(text)
    }
}
```

**Benefit:** The child hears the first sentence of the story while the model is still generating the rest.

#### 3.2 — Sentence-Level Audio Streaming

- Split streamed `storyText` by sentence boundaries (`.`, `!`, `?`)
- Synthesise each sentence via `AudioService` as soon as it's complete
- Send each sentence's PCM audio to the wearable immediately
- Queue sentences to avoid gaps between playback

#### 3.3 — Latency Budget

| Stage | Target | Notes |
|---|---|---|
| Privacy pipeline | 210ms (achieved) | No change needed |
| LLM first token | < 500ms | Neural Engine inference |
| LLM full response | < 2,000ms | ~100 tokens × ~20ms/token |
| TTS first sentence | < 200ms | AVSpeechSynthesizer |
| BLE audio send | ~20ms/chunk | 20ms pacing |
| **Total to first word** | **< 1,000ms** | With streaming |

---

### Phase 4: Interactive Story Loop (1–2 days)

**Goal:** Implement the full interaction cycle: story → question → child answers → continue.

#### 4.1 — Story Loop Flow

```
┌──────────────────────────────────────────────┐
│                                              │
│  ┌─ Generate StoryBeat ──────────────────┐  │
│  │  .storyText → TTS → send audio        │  │
│  │  .question  → TTS → send audio        │  │
│  └────────────────────────────────────────┘  │
│                    │                         │
│                    ▼                         │
│  ┌─ Listen for Answer ───────────────────┐  │
│  │  AudioCaptureService.startCapture()    │  │
│  │  SpeechRecognitionService.startLive()  │  │
│  │  Wait for isFinal or timeout (15s)     │  │
│  │  PIIScrubber.scrub() on transcript     │  │
│  └────────────────────────────────────────┘  │
│                    │                         │
│                    ▼                         │
│  ┌─ Check End Conditions ────────────────┐  │
│  │  isEnding == true? → exit loop         │  │
│  │  turnCount >= maxTurns? → force end    │  │
│  │  Otherwise → continueTurn(answer)      │  │
│  └────────────────────────────────────────┘  │
│                    │                         │
│                    ▼                         │
│              Loop back ──────────────────────┘
```

#### 4.2 — `continueStoryLoop()` Method

Add to `CompanionViewModel`:

```swift
private func continueStoryLoop() async {
    while true {
        // 1. Listen for child's answer
        sessionState = .listeningForAnswer
        guard let answer = try? await listenForAnswer(timeout: 15) else {
            // Timeout: end story gracefully
            try? await endStoryGracefully()
            break
        }

        // 2. Generate next beat
        sessionState = .generatingStory
        guard let beat = try? await onDeviceStoryService.continueTurn(
            childAnswer: answer
        ) else {
            break
        }

        // 3. Speak story and question
        sessionState = .encodingAudio
        let storyAudio = try? await audioService.generateAndEncodeAudio(from: beat.storyText)
        if let audio = storyAudio {
            sessionState = .sendingAudio
            try? await accessoryManager.activeAccessory.sendAudio(audio)
        }
        let questionAudio = try? await audioService.generateAndEncodeAudio(from: beat.question)
        if let audio = questionAudio {
            try? await accessoryManager.activeAccessory.sendAudio(audio)
        }

        // 4. Update timeline
        timeline.insert(TimelineEntry(
            sceneObjects: [],
            storySnippet: String(beat.storyText.prefix(120))
        ), at: 0)

        // 5. Check end condition
        if beat.isEnding { break }
    }
    onDeviceStoryService.endSession()
    sessionState = .connected
}
```

#### 4.3 — Answer Timeout Handling

If the child doesn't respond within 15 seconds:
1. End the current story with a warm conclusion
2. Or repeat the question once
3. After second timeout, end gracefully

---

### Phase 5: UI Updates (1 day)

**Goal:** Add story mode selection and generation status indicators.

#### 5.1 — Story Mode Picker in SettingsTabView

**File:** `SeeSaw/View/Home/SettingsTabView.swift`

- Add segmented control: "On-Device" / "Cloud" / "Hybrid"
- Show model availability status indicator (green dot / orange downloading / red unavailable)
- Grey out "On-Device" option if `SystemLanguageModel.default.availability != .available`
- Bind to `CompanionViewModel.storyMode`

#### 5.2 — Generation Status in CameraTabView

**File:** `SeeSaw/View/Home/CameraTabView.swift`

- Show current session state when `.generatingStory` or `.listeningForAnswer`
- Display turn count: "Turn 3 of 6"
- Show "Generating story…" activity indicator
- Show "Listening for answer…" with microphone icon

#### 5.3 — Model Status in StatusView

**File:** `SeeSaw/View/StatusView.swift`

- Show model download progress when `availability == .downloading`
- Show "Apple Intelligence required" notice when unavailable
- Show device compatibility warning on unsupported hardware

---

### Phase 6: Testing (1–2 days)

**Goal:** Unit tests for all new functionality using Swift Testing framework.

#### 6.1 — `OnDeviceStoryServiceTests.swift`

**File:** `SeeSawTests/OnDeviceStoryServiceTests.swift`

Tests:
- Session lifecycle: start → continue → end
- Turn counting and maxTurns enforcement
- Context window overflow handling (mock token counting)
- Guardrail violation recovery
- Model unavailability handling
- `endSession()` clears all state

#### 6.2 — `StoryBeatTests.swift`

**File:** `SeeSawTests/StoryBeatTests.swift`

Tests:
- `@Generable` conformance (struct conforms to `Generable` protocol)
- All fields are present and of correct type
- `Sendable` conformance

#### 6.3 — `SceneContextTests.swift`

**File:** `SeeSawTests/SceneContextTests.swift`

Tests:
- Construction from `ScenePayload` maps all fields correctly
- Handles empty arrays and nil transcript
- `Sendable` conformance

#### 6.4 — `StoryGenerationModeTests.swift`

**File:** `SeeSawTests/StoryGenerationModeTests.swift`

Tests:
- Raw value round-trip
- `CaseIterable` conformance
- Display names

#### 6.5 — Integration Tests

- Full pipeline flow with mocked `LanguageModelSession`
- Pipeline routing based on `storyMode`
- Fallback from on-device to cloud when model unavailable

**Note:** Testing `LanguageModelSession` directly requires either:
- A protocol abstraction (`StoryGenerating`) for mocking, OR
- Running on a physical device with Apple Intelligence enabled

For unit tests, use the protocol abstraction approach. Integration tests require physical device.

---

### Phase 7: Benchmark Instrumentation (1–2 days)

**Goal:** Add measurement infrastructure for the dissertation's Chapter 6 (Results).

#### 7.1 — Story Generation Metrics

Extend `PrivacyMetricsEvent` or create a new `StoryMetricsEvent`:

```swift
struct StoryMetricsEvent: Codable, Sendable {
    let generationMode: String           // "onDevice" | "cloud" | "hybrid"
    let timeToFirstTokenMs: Double       // LLM latency to first token
    let totalGenerationMs: Double        // Full generation time
    let turnCount: Int                   // Turns in this session
    let contextWindowUsage: Int          // Tokens used at end of session
    let guardrailViolations: Int         // Number of retries due to guardrails
    let storyTextLength: Int             // Characters in storyText
    let timestamp: Double
}
```

#### 7.2 — Benchmark Comparison Framework

Create a `BenchmarkService` that can run all three architectures on identical inputs:
- **Architecture A (Cloud Raw):** Raw JPEG + audio → cloud endpoint (measures bytes transmitted)
- **Architecture B (Cloud Filtered):** ScenePayload → cloud endpoint (existing `CloudAgentService`)
- **Architecture C (SeeSaw On-Device):** Full privacy pipeline + Foundation Models (zero transmission)

#### 7.3 — CSV Export Extension

Extend the existing CSV export in `PrivacyMetricsStore` to include story generation metrics.

---

### Phase 8: Documentation (0.5 day)

#### 8.1 — Update `Apple Foundation Models.md`

- Fix API method names (`.generate()` → `.respond()`)
- Fix iOS version (18 → 26)
- Add context window management section
- Add error handling section
- Add availability checking section

#### 8.2 — Update `PROJECT_STATUS.md`

- Add Foundation Models integration tickets
- Update architecture diagram
- Update completion counts

#### 8.3 — Update `README.md`

- Add Foundation Models as a key framework
- Document the three operating modes (A/B/C)
- Document hardware requirements (iPhone 15 Pro+)

---

## 7. Key Architectural Decisions

### Decision 1: Protocol Abstraction for Story Generation

Create a `StoryGenerating` protocol for testability and clean mode switching:

```swift
protocol StoryGenerating: Sendable {
    func startStory(context: SceneContext, profile: ChildProfile) async throws -> StoryBeat
    func continueTurn(childAnswer: String) async throws -> StoryBeat
    func endSession()
    var isSessionActive: Bool { get }
}
```

Both `OnDeviceStoryService` and a future `CloudStoryService` wrapper can conform.

### Decision 2: Context Window — Sliding Summary

After every turn, estimate remaining token budget. When budget drops below ~800 tokens:
1. Summarise all turns except the latest into a 1–2 sentence recap
2. Create a new `LanguageModelSession` with the recap as part of instructions
3. Continue the story seamlessly — invisible to the child

See [Section 8](#8-context-window-management-strategy) for full strategy.

### Decision 3: Graceful Degradation Chain

```
On-Device (preferred)
    └─ Model unavailable? → Cloud (fallback)
        └─ Network unavailable? → Error message (last resort)
```

Automatic fallback — no user intervention required. The `storyMode` setting controls the **preferred** mode; the actual mode may differ based on availability.

### Decision 4: No Tool Calling Initially

Tool schemas consume context window tokens. For the PoC, pass scene context directly in the prompt. Tool calling can be explored post-PoC when:
- Apple increases the context window
- The session can dynamically load/unload tools

### Decision 5: Isolated `FoundationModels` Import

Only two files import `FoundationModels`:
- `StoryBeat.swift` (model struct with `@Generable`)
- `OnDeviceStoryService.swift` (session management)

All other files interact through plain Swift types (`StoryBeat`, `SceneContext`, `StoryGenerationMode`). This minimises framework coupling and enables testing without the framework.

### Decision 6: Keep `CloudAgentService` Unchanged

The existing cloud service remains as-is. It continues to work with `ScenePayload` → `StoryResponse`. No changes needed. In hybrid mode, it runs in parallel with on-device generation.

---

## 8. Context Window Management Strategy

### The Problem

Apple's on-device model has a **4,096 token context window** that includes:
- System instructions (~200–300 tokens for Whisper prompt)
- All prior conversation history (prompts + responses)
- The current prompt
- The model's response

With ~100–150 tokens per StoryBeat response and ~30–50 tokens per child answer, the budget exhausts around **turn 4–5** without management.

### Token Budget Breakdown

```
Total budget:                4,096 tokens
System prompt:              -  300 tokens
Safety margin:              -  296 tokens
─────────────────────────────────────────
Available for conversation:  3,500 tokens

Per turn (approximate):
  User prompt:               ~40 tokens
  StoryBeat response:       ~120 tokens
  ────────────────────────────────────
  Total per turn:            ~160 tokens

Max turns without management: 3,500 / 160 ≈ 21 turns (theoretical)
Practical max (with overhead): ~6 turns
```

### Strategy: Sliding Window with Proactive Summarisation

```
Turn 1: System prompt + initial prompt → StoryBeat₁
Turn 2: Child answer + prompt → StoryBeat₂
Turn 3: Child answer + prompt → StoryBeat₃
         ↓ Check: tokenCount > 3,500?
Turn 4: Child answer + prompt → StoryBeat₄
         ↓ Check: tokenCount > 3,500?
         ↓ YES → Summarise turns 1-3 into recap
         ↓ → Create new session with recap as context
Turn 5: Continue seamlessly in new session
Turn 6: Final turn → isEnding = true
```

### Implementation

```swift
private func checkContextBudget(nextPrompt: String) async -> Bool {
    guard let session else { return false }
    let promptTokens = session.tokenCount(for: nextPrompt)
    let contextSize = session.contextSize
    // Reserve 800 tokens for response + safety margin
    return promptTokens < (contextSize - 800)
}

private func restartWithSummary(lastPrompt: String) async throws -> StoryBeat {
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
```

### Fallback: `.exceededContextWindowSize` Error

If proactive checking fails and the error is thrown:
1. Catch `LanguageModelSession.GenerationError.exceededContextWindowSize`
2. Call `restartWithSummary()` with the original prompt
3. Continue the story in the new session

### References

- [Apple TN3193: Managing the on-device foundation model's context window](https://developer.apple.com/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window)
- [InfoQ: Apple Improves Context Window Management (March 2026)](https://www.infoq.com/news/2026/03/apple-foundation-models-context/)

---

## 9. Error Handling & Graceful Degradation

### Error Categories

| Error | Cause | Recovery |
|---|---|---|
| `.modelUnavailable` | Wrong device, Apple Intelligence disabled | Fall back to cloud pipeline |
| `.modelDownloading` | Model not yet downloaded | Show progress UI, fall back to cloud |
| `.exceededContextWindowSize` | Too many turns without summary | Restart session with summary |
| `.guardrailViolation` | Content flagged by safety classifier | Retry with softened prompt |
| `.generationFailed` | Unknown LLM error | Show error, offer retry |
| `CloudError.invalidResponse` | Cloud service failure | Show error message |
| `WearableError.notConnected` | BLE disconnected mid-story | Stop story loop, show reconnect |

### Guardrail Violation Strategy

Children's storytelling may trigger guardrails on words like "monster", "scary", "fight":

1. **First attempt:** Original prompt → `.guardrailViolation`
2. **Retry 1:** Softened prompt: "Continue the story in a gentle, positive direction."
3. **Retry 2:** Generic fallback: "Tell a short, happy story about friendship."
4. **Retry 3:** Static fallback beat (pre-written safe story segment)

```swift
private func retrySoftened(originalPrompt: String, attempt: Int) async throws -> StoryBeat {
    guard let session else { throw StoryError.noActiveSession }

    let fallbackPrompts = [
        "Continue the story in a gentle, positive direction. Keep the tone warm.",
        "Tell a short, happy story about friendship and adventure.",
    ]

    let prompt = attempt < fallbackPrompts.count
        ? fallbackPrompts[attempt]
        : fallbackPrompts.last ?? "Tell a happy story."

    do {
        let response = try await session.respond(to: prompt, generating: StoryBeat.self)
        return response.content
    } catch {
        // All retries failed — return static fallback
        return StoryBeat.safeFallback
    }
}
```

### Static Fallback Beat

```swift
extension StoryBeat {
    static let safeFallback = StoryBeat(
        storyText: "The friends decided to go on a peaceful walk through the meadow, picking wildflowers and watching butterflies dance in the sunlight.",
        question: "What kind of flower do you think they found?",
        isEnding: false,
        theme: "nature",
        suggestedContinuation: "Continue with gentle nature exploration."
    )
}
```

---

## 10. Risk Register

| # | Risk | Impact | Likelihood | Mitigation |
|---|------|--------|------------|------------|
| 1 | 4,096 token limit causes mid-story session failure | High | High | Sliding window summarisation, max 6 turns, proactive token checking |
| 2 | Guardrail blocks children's story content | Medium | Medium | 3-level retry (softened prompt → generic → static fallback) |
| 3 | Model unavailable on test devices (iPhone 15 Pro+ required) | High | Medium | Cloud fallback, protocol abstraction for mocking in tests |
| 4 | 3B model produces low-quality stories for ages 3–4 | Medium | Medium | `@Guide` constraints, careful system prompt, quality evaluation |
| 5 | Apple changes Foundation Models API in future iOS | Low | Low | Protocol abstraction isolates app from API changes |
| 6 | Latency exceeds targets when Neural Engine is under load | Medium | Low | Streaming mitigates perceived latency |
| 7 | `@Generable` fails to parse model output | Medium | Low | Fallback to plain text, retry logic |
| 8 | Combined privacy pipeline + LLM latency exceeds 8s target | Low | Low | Pipeline is 210ms; LLM < 2s; well within budget |
| 9 | Streaming partial output has insufficient text for TTS | Low | Medium | Buffer until sentence boundary before starting TTS |
| 10 | Battery drain from continuous LLM inference | Medium | Medium | Limit to 6 turns; measure in benchmark (Phase 7) |

---

## 11. File Change Inventory

### New Files (10)

| File | Purpose | Phase |
|------|---------|-------|
| `SeeSaw/Model/StoryBeat.swift` | `@Generable` struct for LLM output | 0 |
| `SeeSaw/Model/StoryGenerationMode.swift` | Mode enum (onDevice/cloud/hybrid) | 0 |
| `SeeSaw/Model/StoryError.swift` | Error types for story generation | 0 |
| `SeeSaw/Model/SceneContext.swift` | Bridge: PipelineResult → story service | 0 |
| `SeeSaw/Services/AI/OnDeviceStoryService.swift` | Core actor: session, generation, context window | 1 |
| `SeeSawTests/OnDeviceStoryServiceTests.swift` | Unit tests for story service | 6 |
| `SeeSawTests/StoryBeatTests.swift` | Unit tests for StoryBeat model | 6 |
| `SeeSawTests/SceneContextTests.swift` | Unit tests for SceneContext | 6 |
| `SeeSawTests/StoryGenerationModeTests.swift` | Unit tests for mode enum | 6 |
| `SeeSaw/Model/StoryMetricsEvent.swift` | Benchmark metrics struct | 7 |

### Modified Files (6)

| File | Change | Phase |
|------|--------|-------|
| `SeeSaw/App/AppDependencyContainer.swift` | Register `OnDeviceStoryService`; pass to CompanionViewModel | 2 |
| `SeeSaw/ViewModel/CompanionViewModel.swift` | Add `storyMode`, `onDeviceStoryService`, pipeline routing, story loop | 2, 4 |
| `SeeSaw/Model/SessionState.swift` | Add `.generatingStory`, `.listeningForAnswer` cases | 2 |
| `SeeSaw/Extensions/UserDefaults+Settings.swift` | Add `storyMode` persistence key | 2 |
| `SeeSaw/View/Home/SettingsTabView.swift` | Add story mode picker + model status | 5 |
| `SeeSaw/View/Home/CameraTabView.swift` | Story generation status indicator | 5 |

### Optionally Modified (2)

| File | Change | Phase |
|------|--------|-------|
| `SeeSaw/View/StatusView.swift` | Model availability indicator | 5 |
| `SeeSaw/Services/AI/PrivacyMetricsStore.swift` | Extended CSV export with story metrics | 7 |

**Total: 10 new files, 6–8 modified files, ~600–800 new lines of Swift**

---

## 12. Benchmark Strategy

### Research Question

> *Can a structurally privacy-preserving on-device architecture generate contextually relevant, interactive children's stories without transmitting raw personal data, while maintaining narrative quality comparable to cloud-dependent alternatives?*

### Three Architectures to Compare

| Architecture | Description | PII Transmitted | Network Required |
|---|---|---|---|
| **A: Cloud Raw (Baseline)** | Raw JPEG + audio → cloud endpoint | All raw data | Yes |
| **B: Cloud Filtered** | ScenePayload (labels only) → cloud endpoint | Zero raw data, labels only | Yes |
| **C: SeeSaw On-Device** | Full pipeline + Foundation Models, zero network | **Zero** | **No** |

### Measurement Dimensions

| Metric | Method | Tool |
|---|---|---|
| PII items transmitted per session | Network intercept | Charles Proxy / Wireshark |
| Raw bytes transmitted per session | Network intercept | Charles Proxy |
| End-to-end latency (mean + P95) | Per-stage timestamps | Xcode Instruments / OSSignpost |
| Time to first word (streaming) | First audio packet timestamp | Custom instrumentation |
| Story quality — relevance (1–5) | Human evaluation | 3 raters, 10 stories, Likert scale |
| Story quality — creativity (1–5) | Human evaluation | Same protocol |
| Story quality — age-appropriateness (1–5) | Human evaluation | Same protocol |
| Battery drain (30-min session) | iOS battery API | Physical device test |

### Chapter 6 Results Table Template

| Metric | Arch A (Cloud Raw) | Arch B (Cloud Filtered) | Arch C (SeeSaw On-Device) |
|---|---|---|---|
| PII items transmitted / session | *measured* | *measured* | **0** |
| Raw bytes transmitted / session | *measured* | *measured* | **0** |
| End-to-end latency mean (ms) | *measured* | *measured* | *measured* |
| Time to first word (ms) | *measured* | *measured* | *measured* |
| Battery drain / 30 min (%) | *measured* | *measured* | *measured* |
| Story quality — relevance (mean/5) | *rated* | *rated* | *rated* |
| Story quality — creativity (mean/5) | *rated* | *rated* | *rated* |
| Story quality — age-appropriate (mean/5) | *rated* | *rated* | *rated* |

### Null Hypothesis

> **H₀:** A structurally privacy-preserving on-device architecture (Architecture C) produces story beats rated statistically equivalent in quality to cloud-dependent architectures (A and B), while transmitting zero personally identifiable information.

---

## 13. Dissertation Contribution

### Core Claim

> *"SeeSaw demonstrates that a structurally privacy-preserving edge AI architecture can generate contextually relevant, interactive children's stories with zero PII transmission, at latencies comparable to cloud-dependent alternatives, with narrative quality ratings statistically indistinguishable from cloud LLM outputs."*

### Why This Is Stronger Than the Original Architecture

| Aspect | Original (Cloud-Dependent) | Revised (On-Device First) |
|---|---|---|
| Privacy model | Behavioural ("filters applied before cloud") | Structural ("no network = no data leak") |
| Dependency | Cloud required for core functionality | Cloud optional, enhancement only |
| Offline capability | None | Full story interaction offline |
| Verifiability | Must audit filter correctness | Provable by architecture (no network calls) |
| Academic novelty | Incremental | Novel — edge AI + privacy-by-design |

### Key Evidence Points for Dissertation

1. **Zero PII transmission** — measurable via network intercept (Charles Proxy shows 0 bytes for Arch C)
2. **Sub-second latency** — measurable via Instruments (streaming first token < 500ms)
3. **Quality parity** — measurable via Likert evaluation (3 raters × 10 stories × 3 architectures)
4. **Battery efficiency** — measurable via iOS battery API (30-min session)
5. **210ms privacy pipeline** — already measured and documented

---

## 14. Appendix: API Quick Reference

### Foundation Models Framework — APIs Used

| API | Usage in SeeSaw |
|-----|-----------------|
| `SystemLanguageModel.default` | Access the on-device language model |
| `SystemLanguageModel.availability` | Check `.available` / `.downloading` / `.unavailable` |
| `LanguageModelSession(model:instructions:)` | Create conversation session with Whisper persona |
| `session.respond(to:generating:)` | Generate structured `StoryBeat` (full response) |
| `session.streamResponse(to:generating:)` | Generate `StoryBeat` with streaming partial results |
| `session.contextSize` | Query max context window (iOS 26.4+) |
| `session.tokenCount(for:)` | Count tokens in a string (iOS 26.4+) |
| `@Generable` macro | Mark `StoryBeat` struct for guided generation |
| `@Guide` macro | Constrain/describe each field for LLM accuracy |
| `LanguageModelSession.GenerationError` | Error types: `.exceededContextWindowSize`, `.guardrailViolation` |

### Existing APIs (No Changes)

| API | Usage |
|-----|-------|
| `VNDetectFaceRectanglesRequest` | Privacy pipeline Stage 1 |
| `CIGaussianBlur` (σ=30) | Privacy pipeline Stage 2 |
| `VNCoreMLRequest` (YOLO11n) | Privacy pipeline Stage 3 |
| `VNClassifyImageRequest` | Privacy pipeline Stage 4 |
| `SFSpeechRecognizer` (on-device) | Privacy pipeline Stage 5 + answer capture |
| `PIIScrubber` | Privacy pipeline Stage 6 + answer scrubbing |
| `AVSpeechSynthesizer` | TTS for story text + questions |
| `CloudAgentService` | Cloud fallback / hybrid mode |

### References

- [Apple Developer: Foundation Models](https://developer.apple.com/documentation/foundationmodels)
- [Apple Developer: LanguageModelSession](https://developer.apple.com/documentation/foundationmodels/languagemodelsession)
- [Apple Developer: @Generable](https://developer.apple.com/documentation/foundationmodels/generable())
- [Apple Developer: @Guide](https://developer.apple.com/documentation/foundationmodels/guide)
- [Apple TN3193: Managing Context Window](https://developer.apple.com/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window)
- [WWDC25-286: Meet the Foundation Models Framework](https://developer.apple.com/videos/play/wwdc2025/286/)
- [Apple: Expanding Generation with Tool Calling](https://developer.apple.com/documentation/foundationmodels/expanding-generation-with-tool-calling)
- [Apple Intelligence Foundation Language Models Tech Report (arXiv 2507.13575)](https://arxiv.org/abs/2507.13575)
