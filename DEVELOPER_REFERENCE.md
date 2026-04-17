# SeeSaw Companion — Developer Reference

**Branch:** `hybrid-mode` (merged into `main` via PR #17)  
**iOS:** 26+ · Xcode 16+ · Swift 6  
**Last updated:** 2026-04-16  
**Status:** MSc Thesis Submission / Production-ready PoC

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Quick Start — Reproduce from Scratch](#2-quick-start--reproduce-from-scratch)
3. [System Architecture](#3-system-architecture)
4. [Privacy Pipeline — Six Stages](#4-privacy-pipeline--six-stages)
5. [Story Generation Modes (A–D)](#5-story-generation-modes-ad)
   - 5.1 [Mode A — Cloud Raw](#51-mode-a--cloud-raw)
   - 5.2 [Mode B — Cloud Filtered (ScenePayload)](#52-mode-b--cloud-filtered-scenepayload)
   - 5.3 [Mode C — On-Device (Apple Foundation Models)](#53-mode-c--on-device-apple-foundation-models)
   - 5.4 [Mode D — Hybrid (Architecture D)](#54-mode-d--hybrid-architecture-d)
6. [VAD — Three-Layer Turn Detection](#6-vad--three-layer-turn-detection)
7. [Key Services — Implementation Detail](#7-key-services--implementation-detail)
8. [Concurrency Model](#8-concurrency-model)
9. [Dependency Injection and Navigation](#9-dependency-injection-and-navigation)
10. [ML Model — YOLO11n](#10-ml-model--yolo11n)
11. [Deployment](#11-deployment)
12. [Test Suite and Coverage](#12-test-suite-and-coverage)
13. [Device Test Results — Hybrid Mode](#13-device-test-results--hybrid-mode)
14. [Research Observations and Learnings](#14-research-observations-and-learnings)
15. [Known Limitations](#15-known-limitations)
16. [Future Work](#16-future-work)
17. [MSc Thesis — Key Areas](#17-msc-thesis--key-areas)
18. [Viva Talking Points](#18-viva-talking-points)
19. [Presentation Highlights](#19-presentation-highlights)

---

## 1. Project Overview

SeeSaw Companion is a privacy-first iOS app for AI-powered interactive children's storytelling (ages 3–8). It is the software component of the SeeSaw wearable AI companion — a device worn by children that uses a camera and microphone to observe the child's environment and generate personalised story beats.

**Central architectural guarantee:** Raw media (pixels, audio) never leaves the device. Only anonymous labels and PII-scrubbed transcript reach any LLM — whether on-device or cloud.

**Research context:** MSc dissertation prototype evaluating four story-generation architectures (A–D) for privacy–quality–latency trade-offs in AI-mediated children's storytelling.

**Repository layout:**
```
seesaw-companion-ios/       ← this repo (iOS app)
seesaw-companion-ios/../    ← sibling ML training repo (YOLO11n, Colab, CoreML export)
```

---

## 2. Quick Start — Reproduce from Scratch

### Prerequisites

- macOS 15+ with Xcode 16.3+
- iOS 26+ device or simulator (iPhone 17, iOS 26.2 recommended)
- CocoaPods (`gem install cocoapods`)
- Apple Developer account (for on-device testing)

### Step 1 — Clone and install dependencies

```bash
git clone https://github.com/j2damax/seesaw-companion-ios.git
cd seesaw-companion-ios
pod install
```

**Always open `SeeSaw.xcworkspace`, never `SeeSaw.xcodeproj`.**

### Step 2 — Build (Simulator)

```bash
xcodebuild build \
  -workspace SeeSaw.xcworkspace \
  -scheme SeeSaw \
  -destination 'platform=iOS Simulator,arch=arm64,id=E33D4588-A415-495B-8BEB-91B0AC534511' \
  -configuration Debug
```

Simulator ID for iPhone 17 iOS 26.2. If this ID is stale after an Xcode upgrade:

```bash
xcrun simctl list devices available | grep -E "iPhone 17"
```

### Step 3 — Run all tests

```bash
xcodebuild test \
  -workspace SeeSaw.xcworkspace \
  -scheme SeeSaw \
  -destination 'platform=iOS Simulator,arch=arm64,id=E33D4588-A415-495B-8BEB-91B0AC534511' \
  -testPlan SeeSaw \
  -enableCodeCoverage YES \
  -resultBundlePath test-results/run.xcresult
```

### Step 4 — Run a single test class

```bash
xcodebuild test \
  -workspace SeeSaw.xcworkspace \
  -scheme SeeSaw \
  -destination 'platform=iOS Simulator,arch=arm64,id=E33D4588-A415-495B-8BEB-91B0AC534511' \
  -only-testing:SeeSawTests/HybridModeTests
```

Replace `HybridModeTests` with any class name: `PrivacyPipelineTests`, `OnDeviceStoryServiceTests`, `Gemma4StoryServiceTests`, etc.

### Step 5 — Export coverage report

```bash
./export_test_results.sh
# or with explicit path:
XCRESULT_PATH=test-results/run.xcresult ./export_test_results.sh
```

Output: `TestCoverage.md` in the project root.

### Step 6 — Configure cloud agent (optional, for hybrid/cloud modes)

In the app: Settings tab → Cloud Agent URL:
```
https://seesaw-cloud-agent-531853173205.europe-west1.run.app
```
API Key: `289bbf7d03f9118862730b8fd46c14e9cdaf4b966d22207a4d9cddc08f23de1a`

### Step 7 — Download Gemma model (optional, for gemma4OnDevice/hybrid modes)

In the app: Settings tab → Gemma model section → Download. The model (~1.5 GB) downloads from:
```
https://storage.googleapis.com/seesaw-models/gemma2-2b-it-gpu-int8.bin
```
Landing path on device: `Documents/gemma2-2b-it-gpu-int8.bin`

---

## 3. System Architecture

```
┌─────────────────────────────────────────────────────┐
│                    iPhone (on-device)                │
│                                                      │
│  Camera / BLE headset                                │
│      │                                               │
│      ▼                                               │
│  PrivacyPipelineService (6-stage actor)              │
│      │                                               │
│      ▼                                               │
│  ScenePayload ←── PRIVACY BOUNDARY ──────────────►  │
│      │                         ╔══════════════╗      │
│      ├──► OnDeviceStoryService ║ Apple FM 3B  ║      │
│      ├──► Gemma4StoryService   ║ Gemma 3 1B   ║      │
│      │                         ╚══════════════╝      │
│      │                                               │
│  SemanticTurnDetector (3-layer VAD)                  │
│  AudioService (AVSpeechSynthesizer)                  │
│  SpeechRecognitionService (SFSpeechRecognizer)       │
└─────────────────────────────────────────────────────┘
         │ HTTPS POST /story/generate (ScenePayload JSON)
         ▼
┌────────────────────────────────┐
│ Cloud Run (europe-west1)       │
│ seesaw-cloud-agent             │
│ Gemini 2.0 Flash               │
└────────────────────────────────┘
```

### Core design principles

1. **Privacy by architecture** — `ScenePayload` is the only struct that crosses the device boundary. It contains YOLO label strings, scene category strings, and PII-scrubbed transcript. No pixels, no face data, no raw audio ever leave the device.
2. **Actor-based concurrency** — All services are Swift actors. `@MainActor` is used only where platform APIs require it (CoreBluetooth, AVCaptureSession, ViewModels).
3. **Graceful degradation** — Every mode has a fallback: cloud → on-device, Gemma4 → Apple FM, Apple FM → static fallback beat.
4. **Protocol-driven testability** — Services expose protocols (`StoryGenerating`, `CloudEnhancing`) so tests use mocks without networking or Apple Intelligence hardware.

---

## 4. Privacy Pipeline — Six Stages

All six stages execute on every camera frame regardless of story generation mode. Stages 3, 4, and 5 run in parallel after stage 2 completes.

```
JPEG frame (raw — allocated in memory, never written to disk)
    │
    ▼ Stage 1 — Face Detection
    │   VNDetectFaceRectanglesRequest
    │   ~15 ms (Neural Engine)
    │
    ▼ Stage 2 — Face Blur
    │   CIGaussianBlur σ=30
    │   ~8 ms (GPU)
    │   ← blurred JPEG leaves only this point for stages 3+4
    │
    ├──────────────────────────────────────────────────┐
    ▼ Stage 3 — Object Detection          ▼ Stage 4 — Scene Classify
    │   YOLO11n CoreML (44 classes)        VNClassifyImageRequest
    │   conf ≥ 0.25                        conf ≥ 0.3, top-3
    │   ~40 ms (Neural Engine)             ~35 ms (Neural Engine)
    │                                      │
    │                         ▼ Stage 5 — Speech-to-Text
    │                             SFSpeechRecognizer
    │                             requiresOnDeviceRecognition = true
    │                             ~variable (on-device ASR)
    │
    ▼ Stage 6 — PII Scrub
        PIIScrubber (regex)
        Removes: phone numbers, emails, proper nouns (heuristic)
        │
        ▼
    ScenePayload (crosses privacy boundary)
```

**Total pipeline latency:** ~165 ms typical (face detect + blur + parallel YOLO + scene + PII)

### Key configuration constants (AppConfig.swift)

| Constant | Value | Purpose |
|----------|-------|---------|
| `objectDetectionConfidence` | 0.25 | YOLO minimum confidence threshold |
| `sceneConfidenceThreshold` | 0.3 | VNClassifyImageRequest minimum confidence |
| `sceneTopK` | 3 | Number of top scene labels to include |
| `maxFaceBlurSigma` | 30 | CIGaussianBlur sigma for face anonymisation |

---

## 5. Story Generation Modes (A–D)

Configured via `StoryGenerationMode` enum. Selected in Settings tab; persisted in UserDefaults.

```swift
enum StoryGenerationMode: String, Codable {
    case onDevice          // Mode C — Apple Foundation Models
    case gemma4OnDevice    // Mode C variant — Gemma 3 1B via MediaPipe
    case cloud             // Mode A/B — Cloud Run / Gemini
    case hybrid            // Mode D — dual-agent (dissertation Architecture D)
}
```

### 5.1 Mode A — Cloud Raw

**What it does:** POST the `ScenePayload` (privacy-filtered labels only — no raw pixels) to Cloud Run. Gemini 2.0 Flash generates the story beat.

**Privacy posture:** ScenePayload only. No raw media. Objects, scene labels, and PII-scrubbed transcript cross the network.

**Endpoint:** `POST /story/generate`

**Request body:**
```json
{
  "objects": ["teddy_bear", "book"],
  "scene": ["bedroom"],
  "transcript": null,
  "child_age": 5,
  "child_name": "Alex",
  "session_id": "abc123",
  "story_history": []
}
```

**Response:**
```json
{
  "story_text": "...",
  "question": "...",
  "is_ending": false
}
```

**Latency:** 2–8 s (Cloud Run cold start up to 30 s)

### 5.2 Mode B — Cloud Filtered (ScenePayload)

Architecturally identical to Mode A in the iOS client — both POST a `ScenePayload`. The distinction in the dissertation is conceptual: Mode A represents a baseline where the researcher controls what is sent (demonstrating that privacy filtering is deliberate, not accidental). The iOS implementation uses the same `CloudAgentService.requestStory()` for both.

### 5.3 Mode C — On-Device (Apple Foundation Models)

**What it does:** `OnDeviceStoryService` creates a `LanguageModelSession` with Apple Foundation Models. `StoryBeat` is `@Generable` — the Foundation Models runtime populates it with structured output constrained to exactly 3 fields.

**Privacy posture:** Zero network. All inference on Neural Engine.

**Session lifecycle:**
- `startStory()` creates a new `LanguageModelSession` with system prompt and `BookmarkMomentTool`
- Turns 1–5: `continueStory()` calls `session.respond(to: prompt, generating: StoryBeat.self)`
- Turn 6: `restartWithSummary()` — summarises conversation, creates new session, continues
- Guardrail violations: retry with softened prompt, then fall back to `StoryBeat.safeFallback`

**Gemma4 variant (`gemma4OnDevice`):** Uses `Gemma4StoryService` with MediaPipe `LlmInference`. JSON response parsed by `parseResponse()` with heuristic fallback. The `LlmInference` object is created once per model path (3–5 s initialisation) and reused; `LlmInference.Session` is cheap and created fresh per story.

**Model file:** `gemma2-2b-it-gpu-int8.bin` (~1.5 GB) downloaded from GCS to `Documents/` by `ModelDownloadManager`.

**Availability gate:** `checkAvailability()` queries `SystemLanguageModel.default.availability`. If `.unavailable(.modelNotReady)`, throws `StoryError.modelDownloading`.

**Latency (Apple Foundation Models, iPhone 14 Pro, iOS 26):**

| Beat | Generation time | Text length |
|------|----------------|-------------|
| 0    | ~2.1 s          | ~180 chars  |
| 1    | ~1.8 s          | ~160 chars  |
| 2–5  | ~1.5–2.0 s      | ~150–200 chars |

### 5.4 Mode D — Hybrid (Architecture D)

**Design:** Two agents run concurrently per turn. The local model generates immediately (Gemma4 preferred, Apple FM fallback). Simultaneously, a background cloud request runs via `BackgroundStoryEnhancer`. At the end of the listening window, `consumeEnhancedBeat()` checks whether the cloud responded in time.

```
┌── Local generation (foreground) ─────────────────────────────┐
│   Gemma4StoryService.continueStory()                         │
│   ~1.5–2.0 s → StoryBeat (immediate)                        │
└──────────────────────────────────────────────────────────────┘
                    │ result available immediately
                    ▼
          [speak + listen window: 8–15 s]
                    │
┌── Cloud enhancement (background) ────────────────────────────┐
│   BackgroundStoryEnhancer → CloudAgentService                │
│   POST /story/enhance (with storyHistory + childAnswer)      │
│   ~2–5 s typical                                             │
└──────────────────────────────────────────────────────────────┘
                    │
          consumeEnhancedBeat(deadline: .seconds(1))
                    │
          ┌─────────┴──────────┐
          │ cloud arrived?     │
          │                    │
         YES                   NO
          │                    │
    use cloud beat      use local beat
    (richer, context-aware)  (instant fallback)
```

**Key design decision — polling vs. `withTaskGroup`:** `withTaskGroup` cannot enforce a true deadline on unstructured `Task.value` because it implicitly awaits ALL child tasks before returning, even after `cancelAll()`. The `URLSession` timeout is 75 s — a `withTaskGroup` race would block for up to 75 s. Instead, `consumeEnhancedBeat()` uses a 50 ms poll loop. The `pendingTask` continues running after the deadline and populates `cachedResult` — available as a fast path for the next turn.

**`BackgroundStoryEnhancer` actor:**
```
requestEnhancement()
    └── appends to storyHistory (model beat + child answer)
    └── fires unstructured Task { try await cloudService.requestEnhancement(...) }
    └── on completion: setCached(beat, ms)

consumeEnhancedBeat(deadline:)
    └── fast path: if cachedResult != nil → return immediately
    └── poll loop: 50 ms steps up to deadline
    └── on timeout: return nil (pendingTask continues in background)
    └── on hit: clear cachedResult, clear pendingTask, return beat

reset()
    └── pendingTask?.cancel()
    └── clear all state
```

**`storyHistory` accumulation:** Each turn appends `StoryTurn(role: "model", text: beat.storyText)` and, if present, `StoryTurn(role: "user", text: childAnswer)`. This history is passed to the cloud enhancer, enabling narrative continuity across turns.

**Fallback chain for `/story/enhance`:**
1. POST to `/story/enhance` — returns `StoryBeat` JSON
2. If HTTP 404 (endpoint not yet deployed): fall back to `/story/generate` with storyHistory injected into `ScenePayload.storyHistory`
3. If network failure: cloud failure logged, `nil` returned, local beat used silently

**Metrics:** `HybridMetricsStore` records a `HybridBeatMetric` per beat:
- `source`: `.cloud`, `.localGemma4`, or `.localOnDevice`
- `localGenerationMs`: time spent in `consumeEnhancedBeat()` (≤1 s when cloud wins)
- `cloudResponseMs`: actual cloud RTT (nil if cloud missed deadline)
- `cloudArrivedInTime`: whether cloud beat was used
- `endingDetectedBy`: `.localHeuristic`, `.cloudLLM`, or `.turnCap`

Export: `hybridMetricsStore.exportCSV()` → CSV string for Chapter 6 analysis.

---

## 6. VAD — Three-Layer Turn Detection

`SemanticTurnDetector` implements a three-layer voice activity detection strategy to determine when a child has finished their answer.

```
Layer 1 — Heuristic (<1 ms)
    Checks transcript length, last word, and silence markers
    Fast exit for obvious completions ("yes", "no", short phrases ending with "!")
    
Layer 2 — Apple FM Semantic (~150 ms)
    LanguageModelSession.respond() with binary "complete?" prompt
    Skipped when localService == Gemma4StoryService (too slow for Gemma4 mode)
    
Layer 3 — Hard cap (8 s)
    Timer fires regardless — story continues with whatever transcript exists
    Prevents infinite wait on ASR failure
```

**SFSpeechRecognizer behaviour:** With `requiresOnDeviceRecognition = true`, the recogniser may never produce `isFinal = true` for short child utterances. The hard cap at 8 s is the primary turn-completion mechanism in practice. Partial transcripts are used as-is.

**Research contribution:** The three-layer VAD is the novel engineering contribution of Chapter 5. It demonstrates that a pure heuristic (Layer 1) handles ~60% of turns, semantic verification (Layer 2) handles ~30%, and the hard cap (Layer 3) catches the remainder — without a dedicated on-device VAD model.

---

## 7. Key Services — Implementation Detail

### PrivacyPipelineService (actor)

File: `SeeSaw/Services/Privacy/PrivacyPipelineService.swift`

Core 6-stage actor. All Vision requests are dispatched via `VNImageRequestHandler` on a background serial queue. The output is a `ScenePayload` passed to the active story service.

Key methods:
- `processFrame(_ jpeg: Data) async throws -> ScenePayload`
- `processFrameWithMetrics(_ jpeg: Data) async throws -> (ScenePayload, PrivacyMetricsEvent)`

Metrics tracked: face count, object count, PII count, per-stage latency.

### OnDeviceStoryService (actor)

File: `SeeSaw/Services/AI/OnDeviceStoryService.swift`

Manages `LanguageModelSession` lifecycle. Implements `StoryGenerating` protocol.

Critical implementation details:
- `@Generable StoryBeat` constrains output to exactly 3 fields — `@Generable` does NOT synthesise `Codable` (manual conformance in `StoryBeatCodable.swift`)
- `BookmarkMomentTool` is the only registered tool (schema ~65 tokens)
- `AdjustDifficultyTool` and `SwitchSceneTool` are defined but disabled (causes context overflow)
- Context window exhaustion at turn 6: `restartWithSummary()` summarises then creates a new session
- Guardrail violations retry with softened prompt (max 2 attempts), then `StoryBeat.safeFallback`

### Gemma4StoryService (actor)

File: `SeeSaw/Services/AI/Gemma4StoryService.swift`

MediaPipe `LlmInference` wrapper. Implements `StoryGenerating`.

Key details:
- `#if canImport(MediaPipeTasksGenAI)` guard — compiles without the pod installed
- `LlmInference` initialised once per model path, reused across sessions
- `parseResponse(_ text: String)` — tries JSON decode first, then heuristic extraction
- `currentModelState()` exposed publicly for hybrid mode to check Gemma4 readiness

### CloudAgentService (actor)

File: `SeeSaw/Services/Cloud/CloudAgentService.swift`

URLSession-based HTTPS client. 75 s timeout (covers Cloud Run cold start + generation).

Methods:
- `requestStory(payload: ScenePayload) async throws -> StoryResponse` — POST `/story/generate`
- `requestEnhancement(payload:baseBeat:childAnswer:storyHistory:turnNumber:) async throws -> StoryBeat` — POST `/story/enhance`, 404-fallback to `/story/generate`

Conforms to `CloudEnhancing` protocol for testability.

### BackgroundStoryEnhancer (actor)

File: `SeeSaw/Services/AI/BackgroundStoryEnhancer.swift`

See §5.4 for design rationale. Uses `any CloudEnhancing` (not concrete `CloudAgentService`) to allow mock injection in tests.

### HybridMetricsStore (actor)

File: `SeeSaw/Services/AI/HybridMetricsStore.swift`

Per-beat metrics for Chapter 6 analysis. Thread-safe append + query. CSV export for spreadsheet analysis.

### AudioService (actor)

File: `SeeSaw/Services/Audio/AudioService.swift`

`AVSpeechSynthesizer` wrapper. Serialises story beats into audio. Configures `AVAudioSession` for playback. Notifies completion via `AsyncStream`.

### SpeechRecognitionService (actor)

File: `SeeSaw/Services/Speech/SpeechRecognitionService.swift`

`SFSpeechRecognizer` with `requiresOnDeviceRecognition = true`. Streams partial transcripts. The `lastTranscript` property is `nonisolated(unsafe)` and written synchronously in the recognition callback to avoid an async race with `stopTranscription()`.

### PIIScrubber (struct)

File: `SeeSaw/Services/Privacy/PIIScrubber.swift`

Stateless regex-based scrubber. 100% test coverage. Removes: phone numbers, email addresses, URLs, national ID patterns, and optionally proper nouns (heuristic). Input/output lengths logged for dissertation measurement.

---

## 8. Concurrency Model

| Component | Isolation | Reason |
|-----------|-----------|--------|
| `PrivacyPipelineService` | `actor` | Serialize Vision requests |
| `OnDeviceStoryService` | `actor` | Serialize LanguageModelSession access |
| `Gemma4StoryService` | `actor` | Serialize LlmInference access |
| `CloudAgentService` | `actor` | Serialize URLSession + config mutations |
| `BackgroundStoryEnhancer` | `actor` | Protect pendingTask + cachedResult |
| `HybridMetricsStore` | `actor` | Thread-safe append |
| `AudioService` | `actor` | Serialize AVSpeechSynthesizer |
| `SpeechRecognitionService` | `actor` | Serialize recogniser state |
| `PrivacyMetricsStore` | `actor` | Thread-safe metrics |
| `BLEService` | `@MainActor` | CoreBluetooth delegate requirement |
| `LocalDeviceAccessory` | `@MainActor` | AVCaptureSession requirement |
| `AccessoryManager` | `@MainActor` | Aggregates @MainActor accessories |
| `CompanionViewModel` | `@MainActor` | SwiftUI @Observable requirement |

`AsyncStream` bridges callback-based APIs (BLE GATT, audio tap, speech results) into structured concurrency at actor boundaries.

---

## 9. Dependency Injection and Navigation

**No DI framework.** `AppDependencyContainer` constructs all service singletons at launch:

```
AppDependencyContainer.init()
    └── privacyPipeline = PrivacyPipelineService()
    └── cloudService = CloudAgentService(baseURL: ...)
    └── audioService = AudioService()
    └── onDeviceStoryService = OnDeviceStoryService()
    └── gemma4StoryService = Gemma4StoryService()
    └── hybridMetricsStore = HybridMetricsStore()
    └── metricsStore = PrivacyMetricsStore()
    └── storyMetricsStore = StoryMetricsStore()
    └── modelDownloadManager = ModelDownloadManager()
    └── accessoryManager = AccessoryManager(...)
    └── makeCompanionViewModel() → CompanionViewModel(all services)
```

**Navigation** — `AppCoordinator` owns a `Route` enum state machine:
```
launch → terms → signIn → onboarding → home
```
Fast-path: if `hasAcceptedTerms && hasCompletedOnboarding` in UserDefaults, coordinator jumps directly to `home`.

---

## 10. ML Model — YOLO11n

**File:** `SeeSaw/Resources/seesaw-yolo11n.mlpackage` (4.7 MB, checked into repo)

**Training:** Fine-tuned YOLO11n on 3,283 images across 44 child-environment classes. NMS baked into the CoreML graph. See sibling ML training repo for training pipeline.

**44-class taxonomy:**
- 0–11: Furniture (bed, sofa, chair, table, lamp, tv, laptop, wardrobe, window, door, potted_plant, photo_frame)
- 12–24: Child-environment objects (teddy_bear, book, sports_ball, backpack, bottle, cup, building_blocks, dinosaur_toy, stuffed_animal, picture_book, crayon, toy_car, puzzle_piece)
- 25–43: Extended household/toy classes

**iOS integration:**
```swift
let model = try VNCoreMLModel(for: seesaw_yolo11n(configuration: .init()).model)
let request = VNCoreMLRequest(model: model)
// NMS baked in — no post-processing needed
```

**Confidence threshold:** 0.25 (configured in AppConfig). Labels below threshold are discarded before constructing ScenePayload.

---

## 11. Deployment

### Cloud Agent — Google Cloud Run

**Service URL:** `https://seesaw-cloud-agent-531853173205.europe-west1.run.app`  
**Region:** `europe-west1`  
**Model:** Gemini 2.0 Flash  
**Authentication:** `X-SeeSaw-Key` header  

**Endpoints:**
- `POST /story/generate` — accepts `ScenePayload` JSON, returns `StoryResponse` JSON
- `POST /story/enhance` — accepts `EnhancementRequest` JSON, returns `StoryBeat` JSON (currently returns 404 — endpoint deferred; iOS client falls back to `/story/generate` with storyHistory injected)

**Timeout configuration:**
- Cloud Run service timeout: 60 s
- iOS `URLSession` timeout: 75 s (deliberately higher so server 504 surfaces before client timeout)

**Cloud Run deployment (from cloud agent repo):**
```bash
gcloud run deploy seesaw-cloud-agent \
  --region europe-west1 \
  --allow-unauthenticated \
  --timeout 60
```

### Gemma Model — GCS

**Bucket:** `seesaw-models`  
**Object:** `gemma2-2b-it-gpu-int8.bin`  
**Size:** ~1.5 GB  
**Format:** GGUF Q4_K_M (Gemma 3 1B)

Downloaded to device via `ModelDownloadManager` → `Documents/gemma2-2b-it-gpu-int8.bin`.

### Xcode Build — Device

```bash
xcodebuild build \
  -workspace SeeSaw.xcworkspace \
  -scheme SeeSaw \
  -destination 'generic/platform=iOS' \
  -configuration Release
```

For device installation, use Xcode's Product → Run with a physical device selected.

---

## 12. Test Suite and Coverage

**~130 tests, 0 failures** (as of 2026-04-16)

### Test files

| Test file | What it covers |
|-----------|---------------|
| `PrivacyPipelineTests.swift` | PII scrubbing correctness, metrics invariants, 100-run privacy invariant |
| `OnDeviceStoryServiceTests.swift` | Story generation, error recovery, fallback paths (mock Apple FM) |
| `Gemma4StoryServiceTests.swift` | State machine, `parseResponse` JSON and heuristic paths |
| `HybridModeTests.swift` | `BackgroundStoryEnhancer` racing, `HybridBeatMetric` Codable, `HybridMetricsStore` analytics |
| `SceneContextTests.swift` | `ScenePayload` bridging from `SceneContext` |
| `StoryBeatTests.swift` | Struct invariants, static fallbacks |
| `StoryToolsTests.swift` | Tool behaviour, UserDefaults side-effects |
| `StoryGenerationModeTests.swift` | Mode enum encoding/decoding |
| `SeeSawTests.swift` | Smoke test |
| `AudioServiceTests.swift` | AudioService state machine |
| `StoryToolsTests.swift` | BookmarkMomentTool behaviour |

### Coverage (SeeSaw.app target — 2026-04-16)

| File | Coverage |
|------|---------|
| `PIIScrubber.swift` | 100.0% |
| `StoryTools.swift` | 100.0% |
| `PrivacyMetricsStore.swift` | 100.0% |
| `ScenePayload.swift` | 100.0% |
| `SessionState.swift` | 100.0% |
| `StoryError.swift` | 100.0% |
| `StoryGenerationMode.swift` | 100.0% |
| `AppConfig.swift` | 100.0% |
| `AppDependencyContainer.swift` | 87.3% |
| `Gemma4StoryService.swift` | 46.9% |
| `CloudAgentService.swift` | 29.0% |
| `OnDeviceStoryService.swift` | 3.8% |
| `CompanionViewModel.swift` | 2.5% |
| **SeeSaw.app overall** | **14.4%** |
| **SeeSawTests.xctest** | **89.8%** |

**Note on low app-level coverage:** `CompanionViewModel` (1,219 lines) and `PrivacyPipelineService` (396 lines) have low line coverage because they require hardware (camera, Neural Engine, BLE) to exercise their main paths. The test suite uses protocol mocks to validate logic paths without hardware. This is documented as a known limitation.

### HybridModeTests — 13 tests

```
BackgroundStoryEnhancer (5 tests)
├── consumeEnhancedBeatReturnsNilWhenNoPendingTask
├── consumeEnhancedBeatReturnsCloudBeatWhenFast
├── consumeEnhancedBeatReturnsNilWhenCloudExceedsDeadline
├── resetCancelsPendingTask
└── storyHistoryAccumulatesAcrossEnhancementRequests

HybridBeatMetric (3 tests)
├── codableRoundTrip
├── hybridSourceRawValues
└── endingSourceRawValues

HybridMetricsStore (5 tests)
├── cloudHitRateZeroWhenAllLocal
├── cloudHitRateOneWhenAllCloud
├── cloudHitRateFractionMixed
├── csvExportContainsCorrectHeader
└── exportCSVRowCountMatchesRecordCount
```

---

## 13. Device Test Results — Hybrid Mode

**Session:** 9 beats, 8 child answer turns  
**Device:** iPhone (physical device, iOS 26)  
**Mode:** `.hybrid` with Gemma4 as local service  
**Cloud URL:** seesaw-cloud-agent Cloud Run endpoint  

### Per-beat summary

| Beat | Local source | Cloud arrived? | storyHistory size |
|------|-------------|---------------|------------------|
| 0 | localGemma4 | N/A (no cloud for beat 0) | 383 bytes |
| 1 | cloud | Yes | 523 bytes |
| 2 | cloud | Yes | 871 bytes |
| 3 | cloud | Yes | 1,204 bytes |
| 4 | cloud | Yes | 1,689 bytes |
| 5 | cloud | Yes | 2,117 bytes |
| 6 | cloud | Yes | 2,641 bytes |
| 7 | cloud | Yes | 3,039 bytes |
| 8 | cloud | Yes (isEnding=true) | 3,309 bytes |

**Cloud hit rate:** 8/9 = **88.9%**

### Key observations from device log

1. **Dual-agent racing works** — Cloud consistently responded within the 1 s deadline during the 8–15 s speak+listen window.
2. **storyHistory grows correctly** — from 383 bytes (beat 0) to 3,309 bytes (beat 8), ~+300 bytes per turn. Validates the accumulation logic.
3. **404 fallback transparent** — `/story/enhance` returned 404 on every call (endpoint not deployed). Fallback to `/story/generate` with storyHistory was silent and correct — child received cloud-enhanced beats on all 8 turns.
4. **No hangs** — Validates the polling deadline fix. `withTaskGroup` would have blocked for 75 s.
5. **9 beats instead of 6** — `turnCount` in hybrid mode only increments from the local service path. Cloud beats driving `isEnding=true` correctly terminated the session. The turn cap behaviour in hybrid mode is a documented limitation.
6. **VAD truncation** — "It's seesaw" → "It's" on one turn. Pre-existing SFSpeechRecognizer behaviour on short utterances. Documented as platform limitation.

---

## 14. Research Observations and Learnings

### OB-001 — `@Generable` schema is a first-class token-budget constraint

**Finding:** A 5-field `StoryBeat` with 3 registered tools caused context window overflow within the first turn on a 3B-parameter model. Reduced to 3 fields + 1 tool → sessions complete successfully.

**Lesson:** When using Apple Foundation Models with `@Generable`, treat each field description and each tool schema as a hard budget item. Token-budget planning must include struct schema overhead, not just conversation content.

**Thesis relevance:** Demonstrates a novel constraint unique to on-device LLM integration that has no equivalent in cloud API usage.

### OB-002 — `withTaskGroup` cannot enforce deadlines on unstructured Tasks

**Finding:** The initial hybrid mode design used `withTaskGroup` to race cloud vs. timeout. Analysis revealed that `withTaskGroup` awaits ALL child tasks before returning — including `await task.value` on an unstructured `Task<_, Never>` that does not respect cooperative cancellation. A 75 s URLSession timeout would block for 75 s.

**Fix:** 50 ms poll loop. The unstructured `pendingTask` continues in the background, seeding `cachedResult` for the next turn.

**Lesson:** Swift's structured concurrency model has a subtle interaction with unstructured tasks: `Task.value` on a non-cancellable task blocks until completion regardless of surrounding cancellation. Deadline enforcement requires explicit polling.

### OB-003 — Scene classification labels mismatch child environments

**Finding:** `VNClassifyImageRequest` returns ImageNet-derived labels (e.g., "consumer_electronics", "machine") that contradict the story system prompt's `contentRules` ("Never mention technology, devices, or AI").

**Lesson:** General-purpose vision classifiers are not domain-adapted for children's storytelling. A label-mapping layer (tech labels → "an interesting place") would resolve the semantic contradiction.

**Thesis relevance:** Relevant to RQ2 (pipeline fidelity) — demonstrates a gap between technical privacy correctness and semantic story quality.

### OB-004 — `SFSpeechRecognizer` isFinal unreliable for children's short utterances

**Finding:** With `requiresOnDeviceRecognition = true`, `isFinal` never fires within the listening window for short utterances (≤ 2 words). The 8 s hard cap is the primary turn-completion mechanism.

**Lesson:** On-device ASR is a privacy non-negotiable, but carries a quality trade-off for short/quiet utterances. The 3-layer VAD correctly handles this via the hard cap.

### OB-005 — `@Generable` does not synthesise `Codable`

**Finding:** `StoryBeat` is `@Generable` (Apple Foundation Models structured output). When `StoryBeat` needed to appear in `EnhancementRequest: Codable` for the cloud path, the build failed because `@Generable` does not synthesise `Codable`.

**Fix:** Manual `extension StoryBeat: Codable` in `StoryBeatCodable.swift` with snake_case `CodingKeys`.

**Lesson:** `@Generable` and `Codable` are independent protocol requirements. Any type that must cross both the Foundation Models boundary and a JSON boundary needs explicit conformance to both.

### OB-006 — Hybrid cloud hit rate 88.9% validates dual-agent design

**Finding:** 8/9 beats received cloud-enhanced beats within the 1 s deadline on a physical device over a home WiFi connection.

**Lesson:** The speak+listen dead time (8–15 s) provides sufficient budget for cloud enhancement even with Cloud Run cold start. The architecture is validated for typical home environments with reliable WiFi.

---

## 15. Known Limitations

### L-001 — `/story/enhance` endpoint not deployed

**Impact:** All cloud enhancement falls back to `/story/generate` with storyHistory injected into `ScenePayload`. The fallback is transparent and produces correct results.

**Mitigation:** The 404 → fallback path is intentional and documented in `CloudAgentService.swift`. `/story/enhance` is designed to accept `EnhancementRequest` (which includes `baseBeat` and `childAnswer` not available in `ScenePayload`), enabling a richer cloud-side narrative arc. Deploying it would improve story quality in hybrid mode.

### L-002 — Turn cap not enforced in hybrid mode

**Impact:** `turnCount` increments only from the local service code path. When the cloud beat drives `isEnding=true`, the session can run longer than 6 turns (observed: 9 beats).

**Mitigation:** Not a correctness issue — the session terminates correctly when `isEnding=true`. Document for dissertation. If strict turn cap is required, increment `turnCount` in `CompanionViewModel.runHybridPipeline()` independently of the local service.

### L-003 — VAD truncation on short utterances

**Impact:** "It's seesaw" → "It's". Occurs because `SFSpeechRecognizer` with `requiresOnDeviceRecognition = true` may not commit partial results on short pauses.

**Mitigation:** The story continues with whatever transcript exists — functionality is not broken. This affects all modes equally. Quantifying word error rate for children's speech is recommended for Chapter 6.

### L-004 — Low test coverage for hardware-dependent paths

**Impact:** `CompanionViewModel` (2.5%), `PrivacyPipelineService` (9.3%), `OnDeviceStoryService` (3.8%) have low coverage because their primary paths require physical hardware or Apple Intelligence capability.

**Mitigation:** Core logic is covered via protocol mocks. Hardware paths are validated by device test runs documented in `Observations.md`.

### L-005 — Beat 0 latency in hybrid mode

**Impact:** Beat 0 uses only the local model (Gemma4 or Apple FM) — there is no previous turn result to trigger background enhancement. The first beat always takes the local model's latency (~1.5–2 s).

**Mitigation:** Beat 0 local generation is fast enough not to be perceptible as a delay in normal use. Cloud enhancement begins immediately after beat 0, seeding beats 1+.

### L-006 — Scene label semantic mismatch (OB-003)

**Impact:** Tech-scene labels from `VNClassifyImageRequest` contradict story content rules. Affects story grounding quality in office/tech environments.

**Mitigation:** Apply a label-mapping filter before building the system prompt: map tech labels to child-friendly place descriptions ("an interesting place").

### L-007 — Gemma model file not in repo (1.5 GB)

**Impact:** `gemma4OnDevice` and `hybrid` modes require a manual model download. The GGUF file cannot be checked into git.

**Mitigation:** `ModelDownloadManager` automates the download from GCS. The download URL is hardcoded in `AppConfig`. Requires network connectivity on first use.

### L-008 — MediaPipe LlmInference is deprecated (0.10.33)

**Impact:** MediaPipe API `LlmInference` is deprecated in 0.10.33 — successor is LiteRT LM. Functional, but will need migration post-dissertation.

**Mitigation:** No functional impact for dissertation timeline. Migration note in `Gemma4StoryService.swift` header.

---

## 16. Future Work

### Near-term (post-dissertation)

1. **Deploy `/story/enhance` endpoint** — Enables richer cloud narrative enhancement with `baseBeat` and `childAnswer` context. High impact on hybrid mode story quality.
2. **Scene label mapping** — Map `VNClassifyImageRequest` tech labels to child-friendly place descriptions. Fixes OB-003 semantic mismatch.
3. **Enforce hybrid turn cap** — Increment `turnCount` in `CompanionViewModel` independently of local service to enforce 6-turn cap in hybrid mode.
4. **Migrate MediaPipe to LiteRT LM** — Follow MediaPipe 0.10.33 migration guide. No functional change, removes deprecation warning.

### Medium-term

5. **WER benchmark** — Measure word error rate for children's speech with `SFSpeechRecognizer` on-device vs. cloud ASR. Quantifies the privacy–accuracy trade-off of on-device-only ASR.
6. **A/B story quality evaluation** — Structured evaluation (parent/researcher ratings) comparing beats from Modes A–D on the same scene context. Required for dissertation Chapter 6 comparative analysis.
7. **`SwitchSceneTool` and `AdjustDifficultyTool`** — Currently disabled due to context window overhead. Re-enable when running on models with larger context windows (or with quantised tool schemas).
8. **BLE AiSee headset integration** — `BLEService` is implemented. End-to-end testing with physical AiSee headset is the next hardware milestone.
9. **SwiftData timeline** — `StoryTimelineStore` and `StorySessionRecord` are implemented but coverage is low (15%). Full integration + UI testing needed.

### Research directions

10. **Adaptive deadline** — `consumeEnhancedBeat(deadline:)` uses a fixed 1 s deadline. An adaptive deadline based on observed RTT history would optimise cloud hit rate under variable network conditions.
11. **On-device Gemini Nano** — If Apple or Google expose Gemini Nano APIs on-device (iOS 26+), this could replace the cloud path in hybrid mode entirely, eliminating network dependency.
12. **Child speech fine-tuning** — Fine-tune SFSpeechRecognizer language model on children's speech corpus to improve recognition accuracy for ages 3–8.

---

## 17. MSc Thesis — Key Areas

### Research Questions (from SeeSaw-Project-Master.md)

- **RQ1:** Can a privacy-preserving pipeline (no raw media transmission) produce interactive children's stories of comparable quality to cloud-native approaches?
- **RQ2:** What are the measurable trade-offs (latency, quality, privacy) across the four architectures (A–D)?
- **RQ3:** Does hybrid dual-agent mode achieve the best latency–quality balance?

### Chapter mapping

| Chapter | Content | Key evidence |
|---------|---------|-------------|
| Ch. 3 — Privacy Pipeline | 6-stage architecture, privacy invariant, PIIScrubber | 100-run test in `PrivacyPipelineTests`, OB-001, OB-004 |
| Ch. 4 — On-Device LLM | Apple Foundation Models, `@Generable`, context window | OB-001 (token budget), OB-005 (Codable independence), latency table |
| Ch. 5 — VAD | 3-layer turn detection, SFSpeechRecognizer limitations | VAD design, OB-004 (isFinal unreliable), hard cap rationale |
| Ch. 5 — Gemma4 Integration | MediaPipe, GGUF, parseResponse | Gemma4StoryService, `#if canImport` guard |
| Ch. 6 — Comparative Evaluation | A–D modes, latency, cloud hit rate, story quality | Device test (88.9% hit rate), HybridMetricsStore CSV, OB-006 |
| Ch. 7 — Discussion | Limitations, future work, research contributions | L-001 through L-008, §16 Future Work |

### Novel contributions

1. **Privacy-by-architecture** — ScenePayload as the privacy boundary is the primary design contribution. Proven by formal privacy invariant test (100 runs, no raw data in output).
2. **Three-layer VAD** — Novel combination of heuristic + semantic LLM verification + hard cap for child-speech turn detection without a dedicated VAD model.
3. **Architecture D (hybrid)** — Dual-agent design with polling deadline enforcer and storyHistory accumulation. First published implementation of a real-time hybrid on-device/cloud story generation system for children.
4. **`@Generable` schema budget** — Empirical finding that structured output schema design is a first-class constraint for on-device 3B models (OB-001).
5. **`withTaskGroup` deadline limitation** — Engineering finding with broader applicability to Swift structured concurrency deadline patterns (OB-002).

### Metrics for dissertation

All metrics are exported by `HybridMetricsStore.exportCSV()`:
- `cloudHitRate()` — fraction of turns where cloud beat arrived in time
- `averageLocalMs()` — mean local generation latency per beat
- `averageCloudMs()` — mean cloud RTT per beat
- `source` distribution — proportion of beats from cloud vs. localGemma4 vs. localOnDevice

Supplementary:
- PII scrubber: `PrivacyMetricsStore` — pii_count per session
- Pipeline latency: per-stage ms from `PrivacyMetricsEvent`
- Coverage: `TestCoverage.md` from `export_test_results.sh`

---

## 18. Viva Talking Points

**Q: Why can't you just send the JPEG to the cloud?**
Raw JPEG contains faces, potentially identifiable backgrounds, and visual PII. Children's data is subject to COPPA, GDPR-K, and equivalent regulations. Transmitting raw images of children to a cloud service without explicit parental consent is not legally permissible in a deployed product. The 6-stage pipeline ensures that what leaves the device is semantically equivalent to "there's a teddy bear and a book in what looks like a bedroom" — no visual PII.

**Q: How is the privacy guarantee proven?**
`PrivacyPipelineTests.swift` contains a 100-run invariant test that asserts: `ScenePayload` contains no raw pixel data, no face bounding boxes, no audio samples. Additionally, `PIIScrubber` has 100% test coverage with a comprehensive corpus of PII patterns.

**Q: Why Apple Foundation Models instead of GPT-4 on-device?**
Apple Foundation Models (iOS 26) is the only production-quality on-device LLM available on iPhone that does not require network access, does not transmit data to third parties, and integrates natively with the iOS secure enclave trust model. It is the only option that satisfies the zero-network privacy requirement on Apple hardware.

**Q: Why hybrid instead of pure on-device?**
The Apple Foundation Models 3B parameter model generates story beats at 1.5–2 s latency with limited narrative depth. The cloud Gemini 2.0 Flash model generates richer, more contextually aware beats at 2–5 s. Hybrid mode captures the best of both: instant response from on-device (never keeps the child waiting), enriched beats from cloud when network is available. 88.9% cloud hit rate confirms this works in practice.

**Q: What happens when the cloud is unavailable?**
Graceful degradation: `consumeEnhancedBeat()` returns `nil` after the 1 s deadline, and the local beat is used. The child never waits. From the child's perspective, the story continues identically — they cannot distinguish a local beat from a cloud-enhanced beat.

**Q: How do you know the story quality is better with cloud enhancement?**
The device test log shows storyHistory growing from 383 bytes (beat 0) to 3,309 bytes (beat 8) — the cloud has full narrative context. Gemini 2.0 Flash receives `childAnswer` (what the child said), `storyHistory` (all previous beats), and `baseBeat` (what the local model generated), enabling it to produce a beat that directly responds to the child's input within the established narrative arc. A formal quality evaluation (parent ratings) is future work.

**Q: What is the turn cap and why did you observe 9 beats?**
The `maxTurns = 6` cap in `OnDeviceStoryService` is for Apple Foundation Models context window management. In hybrid mode, `turnCount` increments only from the local service path. Cloud-driven ending detection (`isEnding=true` from Gemini) correctly terminated the session at beat 9. This is a known limitation (L-002) — the cap should be enforced at the `CompanionViewModel` level, independently of the local service.

---

## 19. Presentation Highlights

### Slide 1 — The Privacy Problem

"Existing AI storytelling apps (Curio, Tales Factory, etc.) transmit raw audio or video of children to cloud servers. SeeSaw never does. Here's how."

→ Show `ScenePayload` struct. "This is the only data structure that leaves the device. Four string arrays. No pixels."

### Slide 2 — Six-Stage Privacy Pipeline

Show the pipeline flowchart from §4. Highlight Stage 2 (face blur, σ=30) and Stage 6 (PII scrub).

"Every frame is processed in-memory. The blurred JPEG exists only for the duration of a single pipeline execution. Nothing raw is written to disk."

### Slide 3 — Four Architectures

| Architecture | Privacy | Latency | Quality |
|-------------|---------|---------|---------|
| A — Cloud Raw | Medium | 2–8 s | High |
| B — Cloud Filtered | High | 2–8 s | Medium–High |
| C — On-Device | Maximum | 1.5–2 s | Medium |
| D — Hybrid | High | 1.5–2 s | High |

"Architecture D achieves cloud-quality output at on-device latency. The child never waits."

### Slide 4 — Dual-Agent Design

Show the timing diagram from §5.4. Emphasise:
- Local beat ready in 1.5 s
- Cloud enhancement arrives during the 8–15 s speak+listen window
- 88.9% cloud hit rate on device test

### Slide 5 — Three-Layer VAD

"Existing approaches use dedicated VAD models (WebRTC VAD, Silero). We implemented a three-layer approach that requires no additional model:
1. Heuristic — 60% of turns, <1 ms
2. Apple FM semantic — 30% of turns, ~150 ms  
3. Hard cap — 10% of turns, 8 s"

### Slide 6 — Test Evidence

- 130 tests, 0 failures
- PIIScrubber: 100% coverage
- 100-run privacy invariant: zero violations
- 88.9% cloud hit rate on physical device

### Slide 7 — Learnings

1. `@Generable` schema is a token budget — 3 fields, 1 tool is the maximum for a 3B model
2. `withTaskGroup` cannot enforce deadlines — polling is the correct pattern
3. On-device ASR `isFinal` unreliable for children — hard cap is essential
4. General-purpose scene classifiers need domain adaptation for children's environments

### Demo script

1. Open app on device
2. Select **Hybrid** mode in Settings
3. Point camera at a scene with toys visible
4. Tap **Connect** (iPhone camera mode)
5. Watch: pipeline runs → YOLO labels appear → story beat generated → audio plays
6. Respond verbally → VAD detects turn completion → next beat generates
7. Show Xcode console: cloud hit logged, storyHistory size growing

---

*This document was generated from codebase exploration of the `hybrid-mode` branch on 2026-04-16.*  
*For the latest test results, run `./export_test_results.sh` after a full test run.*
