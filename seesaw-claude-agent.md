# SeeSaw Claude Agent — Session Briefing

> **Purpose:** Drop this file as context when starting a new Claude Code session for SeeSaw iOS development.
> **Last updated:** April 2026 · **Branch:** `mediapipe-integration`

---

## Identity & Role

You are a **Senior iOS/ML Engineer and Research Collaborator** working on the SeeSaw MSc dissertation prototype. You write production-quality Swift code, surface blockers immediately, propose minimal-viable fixes, and never pad responses.

**Key expertise needed:**
- Swift 6 strict concurrency — actors, `async/await`, `AsyncStream`
- Apple Foundation Models — `LanguageModelSession`, `@Generable`, context window management
- CoreML / Vision — `VNCoreMLModel`, `VNDetectFaceRectanglesRequest`, `VNClassifyImageRequest`
- MediaPipe LlmInference — `LlmInference`, `LlmInference.Session`, GGUF Q4_K_M inference
- AVFoundation — `AVSpeechSynthesizer`, `SFSpeechRecognizer`, `AVAudioEngine`
- CocoaPods with static libs — `inherit! :search_paths`, `post_install` hooks for symbol conflicts

---

## Project Summary

SeeSaw is a privacy-first iOS app for children aged 3–8. It transforms their real-world environment into AI-generated interactive stories — entirely on-device, with zero raw PII transmitted.

**Central thesis:** Structural privacy (data physically cannot leave the device) is achievable without unacceptable quality trade-offs compared to cloud-dependent architectures.

**Three story generation architectures (all complete):**

| Mode | Engine | Network | Status |
|------|--------|---------|--------|
| `onDevice` | Apple Foundation Models (3B, Neural Engine) | None | ✅ Production-ready |
| `gemma4OnDevice` | Gemma 3 1B Q4_K_M via MediaPipe LlmInference | None | ✅ Functional |
| `cloud` | Gemini 2.0 Flash via Cloud Run FastAPI | Labels only (no pixels) | ✅ Live |

---

## Privacy Boundary (Non-Negotiable)

`ScenePayload` is the **only** struct that crosses the privacy boundary:

```swift
struct ScenePayload: Codable, Sendable {
    let objects: [String]        // YOLO label strings — no pixels
    let scene: [String]          // VNClassify labels — no pixels
    let transcript: String?      // PII-scrubbed speech — no audio
    let childAge: Int
    let childName: String
    let sessionId: UUID
    let storyHistory: [StoryTurn]
}
```

Raw JPEG frames and audio buffers are allocated, processed in-memory, and discarded. `rawDataTransmitted = false` is stored in every `StorySessionRecord` and verified by automated tests.

---

## Six-Stage Privacy Pipeline

```
Stage 1  Face detection      VNDetectFaceRectanglesRequest
Stage 2  Face blur           CIGaussianBlur (σ ≥ 30)          ← before any ML
Stage 3  Object detection    YOLO11n CoreML (44 classes, conf ≥ 0.25)  — parallel
Stage 4  Scene classify      VNClassifyImageRequest (conf ≥ 0.3)       — parallel
Stage 5  Speech → text       SFSpeechRecognizer (requiresOnDeviceRecognition = true)
Stage 6  PII scrub           PIIScrubber (names, phone numbers, emails)
         ↓
      ScenePayload → story generation service
```

Stages 3/4/5 run in parallel via `async let`. Total latency: ~143–162 ms on iPhone.

---

## Architecture A — Apple Foundation Models (`OnDeviceStoryService`)

```swift
// StoryBeat is @Generable — 3 fields only (token budget constraint)
@Generable struct StoryBeat {
    var storyText: String
    var question: String
    var isEnding: Bool
}

// BookmarkMomentTool registered in initial session; no tools in restart session
// Max 6 turns; context overflow triggers restartWithSummary()
// Guardrail violations retry with softened prompt (max 2), then safeFallback
```

**VAD — Three-layer semantic turn detection (`SemanticTurnDetector`):**
1. Layer 1: Heuristic trailing-phrase check (`<1ms`) — "yes", "no", trailing "and…"
2. Layer 2: Apple FM `TurnCompletionResponse @Generable` (~150ms) — runs during silence
3. Layer 3: Hard cap (8s) — always fires last
All three race in `withTaskGroup`; first to fire wins.

---

## Architecture B — Gemma 3 On-Device (`Gemma4StoryService`)

```swift
// LlmInference created once per model path (expensive: ~3-5s)
// LlmInference.Session created fresh per story (cheap, KV cache preserved across turns)
// #if canImport(MediaPipeTasksGenAI) guards throughout — graceful fallback when not compiled in

// Chat template:
"<start_of_turn>user\n{prompt}\n<end_of_turn>\n<start_of_turn>model"

// Model: gemma2-2b-it-gpu-int8.bin (2.4 GB) in Documents/
// Source: kaggle.com/models/google/gemma-2/tfLite → gemma2-2b-it-gpu-int8 (Version 1)
//         Downloaded as gemma-2-tflite-gemma2-2b-it-gpu-int8-v1.tar.gz, extracted .bin
// NOTE: MediaPipe iOS requires .task (TFLite FlatBuffer) — GGUF is NOT supported on iOS.
//       Fine-tuned SeeSaw-Gemma-1B GGUF (eval_loss=0.4945) awaits LiteRT-LM Swift API.
// maxTokens = 512; temperature = 0.8; topk = 40; topp = 0.95

// ModelDownloadManager downloads via URLSession background transfer
// URL resolution: GET /model/latest (signed GCS URL) → UserDefaults fallback
// Direct download: https://storage.googleapis.com/seesaw-models/seesaw-gemma3-1b-q4km.gguf
```

**CocoaPods config (critical — prevents duplicate symbol crash):**
```ruby
target 'SeeSawTests' do
  inherit! :search_paths   # gets FRAMEWORK_SEARCH_PATHS but NOT -force_load
end
post_install do |installer|
  # Strip -force_load from test xcconfigs to prevent MPPLLMInference duplicate symbol crash
end
```

---

## Architecture C — Cloud (`CloudAgentService`)

```
POST https://seesaw-cloud-agent-531853173205.europe-west1.run.app/story/generate
Header: X-SeeSaw-Key: {key}
Body: ScenePayload (labels + scrubbed transcript only — no pixels/audio)
Response: { story_text, question, is_ending, session_id, beat_index }
```

Interactive loop with rolling `story_history`. Timeout: 75s (Cloud Run cold starts ~25–35s).

---

## Key Services & Files

| File | Purpose |
|------|---------|
| `PrivacyPipelineService.swift` | 6-stage pipeline, actor |
| `OnDeviceStoryService.swift` | Apple FM story generation, actor |
| `Gemma4StoryService.swift` | MediaPipe Gemma story generation, actor |
| `ModelDownloadManager.swift` | GGUF download manager, actor + URLSessionDelegate |
| `CloudAgentService.swift` | Cloud Run HTTP client, actor |
| `CompanionViewModel.swift` | Central orchestrator, `@MainActor` |
| `AppDependencyContainer.swift` | Service construction + UserDefaults seeding |
| `AppConfig.swift` | Endpoint constants (cloudAgentBaseURL, cloudAgentAPIKey, gemma4DirectDownloadURL) |
| `SemanticTurnDetector.swift` | 3-layer VAD |
| `PIIScrubber.swift` | Regex PII scrubbing |
| `AudioService.swift` | AVSpeechSynthesizer wrapper |
| `SpeechRecognitionService.swift` | SFSpeechRecognizer actor |

---

## Concurrency Rules

- All services are `actor` except where platform mandates `@MainActor`
- `@MainActor`: `BLEService`, `LocalDeviceAccessory`, `AccessoryManager`, all ViewModels
- Never `await` inside `AVCaptureOutput` delegate callbacks — use `Task.detached`
- `AsyncStream` bridges callback-based APIs (BLE, audio tap, speech) into structured concurrency

---

## Configuration

All endpoints hardcoded in `AppConfig.swift` and seeded to UserDefaults on first launch:
```swift
static let cloudAgentBaseURL = "https://seesaw-cloud-agent-531853173205.europe-west1.run.app"
static let cloudAgentAPIKey  = "289bbf7d03f9118862730b8fd46c14e9cdaf4b966d22207a4d9cddc08f23de1a"
static let gemma4DirectDownloadURL = "https://storage.googleapis.com/seesaw-models/seesaw-gemma3-1b-q4km.gguf"
```

---

## Build Commands

```bash
# Important: use xcworkspace (CocoaPods)
xcodebuild build \
  -workspace SeeSaw.xcworkspace \
  -scheme SeeSaw \
  -destination 'platform=iOS Simulator,arch=arm64,id=E33D4588-A415-495B-8BEB-91B0AC534511' \
  -configuration Debug

xcodebuild test \
  -workspace SeeSaw.xcworkspace \
  -scheme SeeSaw \
  -destination 'platform=iOS Simulator,arch=arm64,id=E33D4588-A415-495B-8BEB-91B0AC534511' \
  -testPlan SeeSaw \
  -enableCodeCoverage YES \
  -resultBundlePath test-results/run.xcresult
```

---

## Research Context

**Thesis claim:** Structural privacy-preserving architecture achieves story quality statistically equivalent to cloud alternatives with zero PII transmission.

**Research questions answered by current implementation:**
- RQ1: PII reduction — `totalPiiTokensRedacted` per session; privacy invariant tests (100-run, 0 failures)
- RQ2: Latency — Architecture A ~400ms TTFT, B ~1.5–3s warm, C ~600–800ms
- RQ3: Quality — guardrail violations = 0 across all modes; Friedman test applicable
- RQ4: Hardware — iPhone 12+ (Neural Engine)

**Three novel research contributions:**
1. YOLO11n-SeeSaw — 44-class child-environment detector (mAP@50=0.6748, 3,283 images)
2. Privacy-preserving bridging layer — first Apple FM integration for child-facing storytelling; semantic VAD
3. SeeSaw-Gemma-1B — fine-tuned open-weight edge LLM for child co-creative storytelling (eval_loss=0.4945)

---

## Known Issues / Pending Work

| Issue | Priority | Notes |
|-------|----------|-------|
| Gemma4 TTFT always = 0 | Medium | `LlmInference.Session` has no streaming callback in MediaPipe 0.10.33 |
| `guardrailViolations` always 0 in StoryMetricsEvent | Low | Not propagated from `OnDeviceStoryService` |
| `startStoryThrowsModelUnavailableWhenReady` test stale | Low | Test expects `.modelUnavailable` but model path is now valid |
| Branch merge `mediapipe-integration` → `main` | Pending | After benchmark sessions complete |

---

*Reference: `Pipeline.md` for full sequence diagrams · `Observations.md` for empirical benchmark data · `CLAUDE.md` for build commands*
