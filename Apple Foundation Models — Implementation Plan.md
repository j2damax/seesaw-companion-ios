# Apple Foundation Models — Implementation Plan

**Project:** seesaw-companion-ios (Tier 2)  
**Date:** 6 April 2026  
**Status:** Implementation Complete (Phases 0–8) — Pending Device Validation  
**Target:** iOS 26.0+ / iPhone 15 Pro+  
**Last Updated:** 7 April 2026

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
let availability = model.availability  // .available | .unavailable(reason)

// MARK: - Session creation
let session = LanguageModelSession(
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

### Phase 0: Model Layer (1 day) ✅ COMPLETE

**Goal:** Define all new model types needed for Foundation Models integration.

**Status:** All 4 model files implemented and compiling: `StoryBeat.swift`, `StoryGenerationMode.swift`, `StoryError.swift`, `SceneContext.swift`. Additional models added: `ChildProfile.swift`, `StoryMetricsEvent.swift`.

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

### Phase 1: OnDeviceStoryService (2–3 days) ✅ COMPLETE

**Goal:** Core actor managing LLM sessions, context windows, and error recovery.

**Status:** Full actor implemented with `StoryGenerating` protocol conformance. Availability check uses `.unavailable(.modelNotReady)` (corrected from wrong `.downloading` API). Error recovery: context window overflow → `restartWithSummary()`, guardrail violation → `retrySoftened()` with 3-level retry, static `safeFallback` as last resort. `session.respond(to:, generating:)` returns `Response<StoryBeat>` — `.content` property extracted correctly.

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

### Phase 2: ViewModel & Pipeline Integration (1–2 days) ✅ COMPLETE

**Goal:** Wire `OnDeviceStoryService` into the existing `CompanionViewModel` and add mode-based pipeline routing.

**Status:** OnDeviceStoryService registered in `AppDependencyContainer` and injected into `CompanionViewModel`. Pipeline routing via `runFullPipeline()` → `runOnDevicePipeline()` / `runCloudPipeline()` based on `storyMode`. Two new session states (`.generatingStory`, `.listeningForAnswer`) added. `storyMode` persisted in `UserDefaults+Settings`. Cloud fallback on `.modelUnavailable` / `.modelDownloading` errors implemented.

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

### Phase 3: Streaming & Audio Optimisation (1–2 days) ⏳ DEFERRED

**Goal:** Use streaming generation for sub-second time-to-first-word.

**Status:** Deferred for post-PoC. Currently uses blocking `.respond()`. Streaming via `.streamResponse()` is planned but not yet implemented. The blocking approach works correctly and meets the PoC requirements. Streaming will improve perceived latency from ~2s to <1s.

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

### Phase 4: Interactive Story Loop (1–2 days) ✅ COMPLETE

**Goal:** Implement the full interaction cycle: story → question → child answers → continue.

**Status:** `continueStoryLoop()` fully implemented in `CompanionViewModel`. Listens for child answers via `AudioCaptureService` + `SpeechRecognitionService` with 15-second timeout. PII scrubbing applied to answers via `SpeechRecognitionService.scrubPII()`. Story ends on `isEnding == true`, `maxTurns` reached, or timeout. Graceful ending via `endStoryGracefully()` using `StoryBeat.endingFallback`.

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

### Phase 5: UI Updates (1 day) ✅ COMPLETE

**Goal:** Add story mode selection and generation status indicators.

**Status:** Story mode segmented picker added to `SettingsTabView` (On-Device / Cloud / Hybrid) with mode descriptions. `CameraTabView` now shows dedicated UI for `.generatingStory` (spinner + "Turn X of 6") and `.listeningForAnswer` (mic icon + live transcript + turn count). `storyMode` persists via `UserDefaults` with `didSet` handler.

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

### Phase 6: Testing (1–2 days) ✅ COMPLETE

**Goal:** Unit tests for all new functionality using Swift Testing framework.

**Status:** 30 new tests across 4 test files, all using Swift Testing (`import Testing`, `#expect`). `MockStoryService` actor conforms to `StoryGenerating` protocol for hardware-free testing. Tests cover: StoryBeat (6), SceneContext (5), StoryGenerationMode (7), MockStoryService lifecycle (7), StoryError (3), StoryMetricsStore (5), StoryMetricsEvent Codable (1). Total repository tests: 89 unit + 3 UI = 92.

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

### Phase 7: Benchmark Instrumentation (1–2 days) ✅ COMPLETE

**Goal:** Add measurement infrastructure for the dissertation's Chapter 6 (Results).

**Status:** `StoryMetricsEvent` struct defined with 7 fields (generationMode, timeToFirstTokenMs, totalGenerationMs, turnCount, guardrailViolations, storyTextLength, timestamp). `StoryMetricsStore` actor created with record/query/CSV export methods. `CompanionViewModel` records metrics after every story generation with `CFAbsoluteTimeGetCurrent()` timing. `SettingsView` displays story generation metrics dashboard (generations, avg latency, avg story length, guardrail violations) with CSV export button.

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

### Phase 8: Documentation (0.5 day) ✅ COMPLETE

**Status:** This implementation plan updated with phase completion status. API references corrected (`.respond()` not `.generate()`, `Response<T>.content` extraction, `.unavailable(.modelNotReady)` availability check). All 8 phases documented with implementation notes.

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

### New Files (12)

| File | Purpose | Phase | Status |
|------|---------|-------|--------|
| `SeeSaw/Model/StoryBeat.swift` | `@Generable` struct for LLM output | 0 | ✅ |
| `SeeSaw/Model/StoryGenerationMode.swift` | Mode enum (onDevice/cloud/hybrid) | 0 | ✅ |
| `SeeSaw/Model/StoryError.swift` | Error types for story generation | 0 | ✅ |
| `SeeSaw/Model/SceneContext.swift` | Bridge: PipelineResult → story service | 0 | ✅ |
| `SeeSaw/Services/AI/OnDeviceStoryService.swift` | Core actor: session, generation, context window | 1 | ✅ |
| `SeeSaw/Services/AI/StoryGenerating.swift` | Protocol abstraction for testability | 1 | ✅ |
| `SeeSaw/Services/AI/StoryMetricsStore.swift` | Actor: story metrics recording + CSV export | 7 | ✅ |
| `SeeSaw/Model/StoryMetricsEvent.swift` | Benchmark metrics struct | 7 | ✅ |
| `SeeSawTests/OnDeviceStoryServiceTests.swift` | Mock-based unit tests + StoryMetrics tests | 6 | ✅ |
| `SeeSawTests/StoryBeatTests.swift` | Unit tests for StoryBeat model | 6 | ✅ |
| `SeeSawTests/SceneContextTests.swift` | Unit tests for SceneContext | 6 | ✅ |
| `SeeSawTests/StoryGenerationModeTests.swift` | Unit tests for mode enum | 6 | ✅ |

### Modified Files (7)

| File | Change | Phase | Status |
|------|--------|-------|--------|
| `SeeSaw/App/AppDependencyContainer.swift` | Register `OnDeviceStoryService` + `StoryMetricsStore`; pass to CompanionViewModel | 2, 7 | ✅ |
| `SeeSaw/ViewModel/CompanionViewModel.swift` | Add `storyMode`, `onDeviceStoryService`, `storyMetricsStore`, pipeline routing, story loop, metrics recording | 2, 4, 7 | ✅ |
| `SeeSaw/Model/SessionState.swift` | Add `.generatingStory`, `.listeningForAnswer` cases | 2 | ✅ |
| `SeeSaw/Extensions/UserDefaults+Settings.swift` | Add `storyMode` persistence key | 2 | ✅ |
| `SeeSaw/View/Home/SettingsTabView.swift` | Add story mode segmented picker | 5 | ✅ |
| `SeeSaw/View/Home/CameraTabView.swift` | Story generation + listening status with turn count | 5 | ✅ |
| `SeeSaw/View/SettingsView.swift` | Story generation metrics dashboard section | 7 | ✅ |

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
| `SystemLanguageModel.availability` | Check `.available` / `.unavailable(reason)` |
| `LanguageModelSession(instructions:)` | Create conversation session with Whisper persona |
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

---

## 15. Technical Review & Feedback

**Reviewer:** Claude (claude-sonnet-4-6)  
**Review date:** 6 April 2026  
**Verdict:** Strong plan — ready to implement with the corrections and clarifications noted below.

---

### 15.1 What the Plan Gets Right

These are genuine strengths worth preserving as-is.

**Architectural decisions are sound.**
Decision 5 (isolating `FoundationModels` import to exactly two files) is the right call. It limits framework coupling, keeps the rest of the codebase testable without hardware, and means a future API change from Apple requires changes in at most two places. This is the kind of constraint that looks obvious in hindsight but is easy to miss under time pressure.

**The corrected API errors section (§4) is the most valuable part of this document.**
Catching `.generate()` → `.respond(to:generating:)`, the force-unwrap, and the missing availability check before writing a line of code saves approximately 2–3 days of debugging. These are exactly the errors that manifest as cryptic runtime crashes, not compile errors. Whoever wrote §4 did the hard work upfront.

**`StoryGenerating` protocol abstraction (Decision 1) is essential, not optional.**
Without this, every unit test requires a physical iPhone 15 Pro with Apple Intelligence enabled. With it, `MockStoryService` can run the full `CompanionViewModel` coordinator logic in CI. This decision should be treated as a hard requirement, not an optional refactor.

**The guardrail retry strategy (§9) is realistic for children's content.**
Words like "dragon", "monster", "scary", "fight" are central to the kind of stories children want to hear. A children's storytelling app that can't handle these words without crashing is broken. The 3-level retry with a static fallback is pragmatic — it accepts that the safety classifier is imperfect and builds resilience around it rather than pretending the problem doesn't exist.

**The benchmark design (§12) is dissertation-quality.**
Three architectures, three quality dimensions, clear null hypothesis, measured with independent raters. The research question is well-posed. Architecture C's "zero bytes transmitted" result is a hard fact that can be confirmed with a network monitor, not a subjective claim — that's exactly the kind of result that makes a strong dissertation chapter.

**The privacy argument upgrade is academically significant.**
"Structurally guaranteed — no network call is made" is fundamentally stronger than "filtered before cloud" for a dissertation. The former is provable by static analysis of the call graph. The latter requires auditing every code path. The revised architecture turns a behavioural claim into a structural one — that distinction is worth foregrounding in the dissertation introduction.

---

### 15.2 Bugs and Errors to Fix Before Coding

These are issues that will cause compilation failures or incorrect runtime behaviour.

#### Bug 1 — Token budget math is internally inconsistent

**Section 8, Token Budget Breakdown:**

```
Max turns without management: 3,500 / 160 ≈ 21 turns (theoretical)
Practical max (with overhead): ~6 turns
```

This is contradictory. If 21 turns are theoretically possible, the context window is not the constraint that limits the story to 6 turns. The 6-turn cap appears to be a **user experience choice** (story length), not a technical constraint from the context window.

This matters because the plan treats context overflow as a High/High risk (Risk Register §10, Risk 1) and invests significant implementation complexity in the sliding-window summarisation strategy — yet the math shows the window isn't actually a problem for a 6-turn story without any management.

**Recommendation:** Either (a) justify the "6 turns" cap as a UX/quality decision and downgrade Risk 1 to Low/Low for a 6-turn story, or (b) correct the token estimates. The ~160 tokens/turn estimate likely understates system overhead. If the true overhead pushes the practical limit to ~8–10 turns, document that clearly. The sliding-window implementation is still worth keeping as a safety net, but the risk register should reflect the real numbers.

---

#### Bug 2 — `session.tokenCount(for:)` checks the wrong thing

**Section 8, `checkContextBudget()` implementation:**

```swift
private func checkContextBudget(nextPrompt: String) async -> Bool {
    guard let session else { return false }
    let promptTokens = session.tokenCount(for: nextPrompt)
    let contextSize = session.contextSize
    return promptTokens < (contextSize - 800)
}
```

This checks whether the *next prompt alone* fits within 800 tokens of the window size. It does not check the *accumulated conversation history*. A 40-token prompt will always pass this check regardless of how full the session's context window is.

The correct check must account for the total tokens already consumed by the session (system prompt + all prior turns). At the time of writing, Apple's API does not expose a `session.usedTokenCount` property directly. The practical approaches are:

1. Track accumulated token usage manually: sum `tokenCount(for:)` calls for each prompt and response after every turn.
2. Rely on catching `.exceededContextWindowSize` as the signal and use `restartWithSummary()` reactively rather than proactively.
3. Use a conservative turn-count heuristic (e.g., summarise after turn 4) rather than token counting.

**Recommendation:** Use the turn-count heuristic as primary strategy (simpler, no API dependency), keep `.exceededContextWindowSize` catch as the safety net. The iOS 26.4+ `tokenCount(for:)` API is better suited to measuring individual prompt costs than tracking total session usage.

---

#### Bug 3 — `session.tokenCount(for:)` requires iOS 26.4+ but minimum deployment is iOS 26.0

**Section 8 and §2:**

`session.tokenCount(for:)` and `session.contextSize` are noted as iOS 26.4+ APIs. The app's minimum deployment target is iOS 26.0 (§1: "Target: iOS 26.0+"). This creates an unavoidable API availability gap.

Any call to these APIs without an `if #available(iOS 26.4, *)` guard will cause a crash on iOS 26.0–26.3 devices. The current implementation code in §8 has no availability guard.

**Recommendation:** Wrap all `session.tokenCount` and `session.contextSize` calls in `if #available(iOS 26.4, *) { ... } else { /* use turn-count heuristic */ }`. Document this as a non-trivial compatibility branch, not a one-liner.

---

#### Bug 4 — `StoryBeat.safeFallback` static property may not compile

**Section 9:**

```swift
extension StoryBeat {
    static let safeFallback = StoryBeat(
        storyText: "The friends decided to go on a peaceful walk...",
        question: "What kind of flower do you think they found?",
        isEnding: false,
        theme: "nature",
        suggestedContinuation: "Continue with gentle nature exploration."
    )
}
```

The `@Generable` macro generates a custom conformance that may synthesise a non-public or modified initialiser. Depending on the macro's expansion, the memberwise initialiser shown here may not be directly accessible, or the field order/signature may differ from the struct definition.

**Recommendation:** Verify that `StoryBeat(storyText:question:isEnding:theme:suggestedContinuation:)` is the actual synthesised init signature after macro expansion. If it is not accessible, the fallback can be constructed by decoding from a JSON literal or by using `@Generable`-generated factory methods if Apple exposes them.

---

#### Bug 5 — `LanguageModelSession` initialiser signature needs verification

The plan uses two different initialisers in different sections:

**Section 5 (Corrected API Reference):**
```swift
let session = LanguageModelSession(
    model: model,
    instructions: "System prompt here..."
)
```

**Section 8 (`restartWithSummary`):**
```swift
session = LanguageModelSession(
    model: model,
    instructions: "..."
)
```

Apple's `LanguageModelSession` documentation (referenced in §14) shows that sessions use `SystemLanguageModel.default` implicitly — the session may not accept an explicit `model:` parameter and the correct init signature may be `LanguageModelSession(instructions:)`.

**Recommendation:** Verify the exact initialiser signature against the Xcode 26 SDK headers before writing `OnDeviceStoryService`. If `model:` is not a parameter, remove it. If it is, the code is correct as written.

---

#### Bug 6 — `response.content` accessor needs verification

**Section 5:**
```swift
let response = try await session.respond(
    to: "User prompt",
    generating: StoryBeat.self
)
let beat: StoryBeat = response.content
```

The `response.content` property assumes the return type of `respond(to:generating:)` is a wrapper type with a `.content` property. Apple's API may instead return the generated type directly (i.e., `let beat: StoryBeat = try await session.respond(to:generating:)`).

**Recommendation:** Verify the actual return type in the SDK. If it returns the type directly, remove the `.content` accessor throughout `OnDeviceStoryService`.

---

### 15.3 Design Gaps to Address

These are not bugs — the plan doesn't break — but the implementation will require decisions not documented here.

#### Gap 1 — `ChildProfile` is used but never defined

`startStory(context: SceneContext, profile: ChildProfile)` appears in the `StoryGenerating` protocol, `OnDeviceStoryService`, `CompanionViewModel`, and the system prompt builder — but `ChildProfile` is not defined anywhere in the document. It is not in the file change inventory (§11).

Currently, child age and name likely live in `UserDefaults` (via `UserDefaults+Settings.swift`). Two options:

1. **Simple:** Read age and name directly from `UserDefaults` inside `OnDeviceStoryService` (avoids a new type, keeps the call site clean).
2. **Clean:** Define a `struct ChildProfile: Sendable { let name: String; let age: Int }`, create it in `CompanionViewModel` from `UserDefaults`, and pass it through. Add `ChildProfile.swift` to the file inventory in §11.

Option 2 is more testable and is recommended. Add the file to the inventory.

---

#### Gap 2 — `conversationSummary` is never populated

The sliding-window strategy in §8 depends on `conversationSummary` to reconstruct context after a session restart. The `restartWithSummary()` method reads it:

```swift
let summary = conversationSummary ?? "An interactive story is in progress."
```

But nowhere in the plan is `conversationSummary` updated. It is never written to. As implemented, every context restart will use the generic fallback string `"An interactive story is in progress."` — losing all story continuity.

**Recommendation:** After each successful `StoryBeat` generation, append a compact summary to `conversationSummary`. One approach:

```swift
// After each successful turn
conversationSummary = "\(conversationSummary ?? "") \(beat.suggestedContinuation)"
```

The `suggestedContinuation` field exists on `StoryBeat` precisely for this purpose — use it.

---

#### Gap 3 — Streaming and `isEnding` are in tension

**Section 3:**

```swift
let stream = session.streamResponse(to: prompt, generating: StoryBeat.self)
for try await partialBeat in stream {
    if let text = partialBeat.storyText, !text.isEmpty {
        await beginIncrementalTTS(text)
    }
}
```

Partial `StoryBeat` values during streaming will have `storyText` populated incrementally but other fields (`isEnding`, `theme`, `suggestedContinuation`) will be `nil` or default until the stream completes. The story loop logic in Phase 4 uses `beat.isEnding` to decide whether to loop or terminate:

```swift
if beat.isEnding { break }
```

If this check runs against a partial beat during streaming, `isEnding` will always be `false` (its default), and the loop will never end from a streaming partial.

**Recommendation:** Separate streaming concerns from control flow:
1. Use `streamResponse()` to feed the audio pipeline for low-latency TTS.
2. After the stream completes, read the **final** `StoryBeat` for `isEnding`, `theme`, and `suggestedContinuation`.
3. Update `conversationSummary` only from the final beat.

This is a two-variable approach: a streaming `partialBeat` for audio, and a `finalBeat` captured at stream completion for control flow.

---

#### Gap 4 — Hybrid mode is under-specified

Hybrid mode is described in §3 (three operating modes) and mentioned in Phase 2.5 but the implementation of `runHybridPipeline()` is only sketched. Key questions left open:

- If the cloud response arrives while the on-device story is still playing — what happens?
- If the cloud response is richer/different — do you interrupt playback, queue it, or discard it?
- Does the on-device session stay open while waiting for cloud?
- On network timeout, does the story loop continue from on-device only, or terminate?

For a PoC, the simplest hybrid strategy is: fire cloud request in background, play on-device result immediately, log whether cloud arrived within a 10-second window (for the benchmark), and discard the cloud result if not in time. Document this explicitly in the plan so the PoC scope is clear.

---

#### Gap 5 — `StoryGenerating.swift` and `ChildProfile.swift` missing from file inventory

Section 11 lists 10 new files, but the following are referenced in the plan and need to be created:

| Missing File | Contains |
|---|---|
| `SeeSaw/Services/AI/StoryGenerating.swift` | `StoryGenerating` protocol + `MockStoryService` |
| `SeeSaw/Model/ChildProfile.swift` | `ChildProfile` struct (if Gap 1 is resolved with Option 2) |

Update §11 to include these, and revise the file count from "10 new files" to "12 new files".

---

### 15.4 Minor Issues

| # | Location | Issue |
|---|---|---|
| M1 | §8 token budget | The 300-token system prompt estimate is reasonable but may be optimistic — the example prompt in §1 is already ~120 tokens for a compact version. Verify with `session.tokenCount(for: systemPrompt)` on first run. |
| M2 | §6 Phase 3.2 | Sentence splitting on `.`, `?`, `!` will incorrectly split on abbreviations (e.g. `"Dr. Fox"`, `"3 p.m."`). Use `NLTokenizer` with `.sentence` unit instead of regex/character split. |
| M3 | §9 `retrySoftened` | The method signature shows `attempt: Int` but the call site in §9 loops without an increment — the attempt counter needs to be tracked in the outer method or the retry loop. |
| M4 | §6 Phase 4.2 | `continueStoryLoop()` uses `try?` to silently swallow errors from `audioService` and `accessoryManager`. Consider logging these even if not throwing — silent audio failures are hard to diagnose. |
| M5 | §11 modified files | `SeeSaw/Services/AI/BenchmarkService.swift` is a new file (Phase 7) but is not listed in §11. Add it. |

---

### 15.5 Dissertation-Specific Observations

**The "zero bytes transmitted" result is the dissertation's strongest empirical claim.** Make sure the benchmark captures this at the network layer (Charles Proxy or `NWConnection` monitoring), not just by code inspection. The examiner will ask how you verified it.

**Quality evaluation (§12) needs inter-rater reliability.** Three raters with a Likert scale is correct, but you should report Cohen's kappa or Fleiss' kappa for inter-rater agreement, not just the mean rating. Without it, a sceptical examiner can dismiss the quality scores as subjective. This is a one-line addition to the methods section but changes the credibility of the results significantly.

**The "structural vs behavioural privacy" framing (§13) deserves its own subsection in the dissertation literature review.** This distinction exists in the academic privacy literature (Nissenbaum's contextual integrity, Datta et al. on privacy as a structural property). Grounding the SeeSaw claim in that literature would raise the work above a purely engineering contribution.

**Latency comparisons need careful framing.** Architecture A (Cloud Raw) measures latency including raw image upload, which is dominated by network bandwidth — not inference speed. A reader might argue this is an unfair comparison. Frame it as "end-to-end user-perceived latency" rather than "inference latency" to make the comparison legitimate.

---

### 15.6 Overall Assessment

| Dimension | Rating | Notes |
|---|---|---|
| API correctness | Good | §4 errors correctly identified; initialisers and return types need final SDK verification (Bugs 5, 6) |
| Architecture design | Excellent | Protocol abstraction, import isolation, and graceful degradation are all well-reasoned |
| Context window strategy | Adequate | Sliding window approach is correct; token budget math and proactive check logic need fixes (Bugs 1, 2, 3) |
| Error handling | Good | Guardrail retry is thorough; streaming/isEnding tension needs resolution (Gap 3) |
| Testability | Excellent | `StoryGenerating` protocol makes unit testing possible without hardware |
| Implementation completeness | Good | `ChildProfile` and `conversationSummary` gaps need filling before Phase 1 work starts |
| Dissertation alignment | Excellent | Benchmark design, null hypothesis, and privacy framing are publication-quality |

**Priority order for fixes before writing code:**

1. **Gap 1** — Define `ChildProfile` (needed by every method signature)
2. **Bug 5** — Verify `LanguageModelSession` init signature against SDK headers
3. **Bug 6** — Verify `response.content` vs direct return type
4. **Gap 3** — Separate streaming audio path from `isEnding` control flow
5. **Bug 2** — Fix `checkContextBudget()` to track accumulated context, not just next prompt
6. **Gap 2** — Implement `conversationSummary` update after each turn using `suggestedContinuation`
7. **Bug 3** — Add `#available(iOS 26.4, *)` guards around `tokenCount` / `contextSize` calls
8. **Bug 1** — Reconcile token budget math and correct the risk register accordingly
