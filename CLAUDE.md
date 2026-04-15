# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SeeSaw Companion is a privacy-first iOS app for AI-powered interactive children's storytelling (ages 3–8). Its central architectural guarantee: raw media (pixels, audio) never leaves the device — only anonymous labels and PII-scrubbed transcript reach the LLM.

This is an MSc research prototype. The codebase prioritises instrumentation for dissertation benchmarking, clean actor-based concurrency, and graceful degradation over production polish.

**Requirements:** iOS 26+ minimum, iPhone 12+ recommended (Neural Engine), Apple Foundation Models requires iOS 26+.

## Common Commands

**Important:** This project uses CocoaPods (MediaPipeTasksGenAI). Always open and build from `SeeSaw.xcworkspace`, never `SeeSaw.xcodeproj`. After any `pod install`, reopen the workspace.

```bash
# Install / update pods (run after cloning or changing Podfile)
pod install

# Build (Debug) — iOS 26.2 simulator (iPhone 17)
xcodebuild build \
  -workspace SeeSaw.xcworkspace \
  -scheme SeeSaw \
  -destination 'platform=iOS Simulator,arch=arm64,id=E33D4588-A415-495B-8BEB-91B0AC534511' \
  -configuration Debug

# Run all tests with coverage
xcodebuild test \
  -workspace SeeSaw.xcworkspace \
  -scheme SeeSaw \
  -destination 'platform=iOS Simulator,arch=arm64,id=E33D4588-A415-495B-8BEB-91B0AC534511' \
  -testPlan SeeSaw \
  -enableCodeCoverage YES \
  -resultBundlePath test-results/run.xcresult

# Run a single test class
xcodebuild test \
  -workspace SeeSaw.xcworkspace \
  -scheme SeeSaw \
  -destination 'platform=iOS Simulator,arch=arm64,id=E33D4588-A415-495B-8BEB-91B0AC534511' \
  -only-testing:SeeSawTests/PrivacyPipelineTests

# List available simulators (if destination ID needs updating after Xcode upgrade)
xcrun simctl list devices available | grep -E "iPhone|iPad"

# Export coverage report from last xcresult
./export_test_results.sh
# Or with explicit path:
XCRESULT_PATH=test-results/run.xcresult ./export_test_results.sh
```

## Architecture

### Privacy Boundary

The fundamental design constraint is that `ScenePayload` is the **only** struct that crosses the privacy boundary. It contains:
- `objects: [String]` — YOLO label strings (no pixels)
- `scene: [String]` — scene classification labels (no pixels)
- `transcript: String?` — PII-scrubbed speech (no audio)

Raw JPEG frames and audio buffers are allocated, processed in-memory, and discarded. Nothing raw is written to disk or sent over the network.

### Six-Stage Privacy Pipeline (`PrivacyPipelineService.swift`)

```
Stage 1: Face detection    → VNDetectFaceRectanglesRequest
Stage 2: Face blur         → CIGaussianBlur (σ≥30)
Stage 3: Object detection  → YOLO11n CoreML (44 classes, conf≥0.25)
Stage 4: Scene classify    → VNClassifyImageRequest (conf≥0.3)
Stage 5: Speech → text     → SFSpeechRecognizer (on-device only)
Stage 6: PII scrub         → PIIScrubber regex patterns
         ↓
      ScenePayload (crosses boundary to OnDeviceStoryService)
```

### Story Generation (`OnDeviceStoryService.swift`)

Uses Apple Foundation Models (`LanguageModelSession`). Key design decisions:
- Output type `StoryBeat` is `@Generable` — Foundation Models populates it in a type-safe, constrained way (3 fields: `storyText`, `question`, `isEnding`)
- Max 6 turns per session; context window exhaustion triggers summarise-and-restart
- Guardrail violations retry with softened prompts (max 2 attempts), then fall back to `StoryBeat.safeFallback`
- `BookmarkMomentTool` registered in initial session (tools deregistered in restart session to minimise context overhead)
- `AdjustDifficultyTool` and `SwitchSceneTool` defined but disabled (schema overhead causes context overflow in long sessions)

### Story Generation Modes

```swift
enum StoryGenerationMode { case onDevice, gemma4OnDevice, cloud, hybrid }
```

- **onDevice**: Apple Foundation Models only (zero network, zero privacy risk)
- **gemma4OnDevice**: MediaPipe LlmInference with Gemma 3 1B Q4_K_M GGUF (zero network, zero privacy risk)
- **cloud**: POST `ScenePayload` to Cloud Run endpoint (`cloudAgentURL` in UserDefaults)
- **hybrid**: on-device first, cloud enhancement if network available

`gemma4OnDevice` requires the GGUF model file to be downloaded via `ModelDownloadManager` before use. The model lands at `Documents/seesaw-gemma3-1b-q4km.gguf`.

### Concurrency Model

All services are Swift actors except where platform APIs mandate `@MainActor`:
- **Actors**: `PrivacyPipelineService`, `OnDeviceStoryService`, `AudioService`, `AudioCaptureService`, `SpeechRecognitionService`, `CloudAgentService`, `AuthenticationService`, `PrivacyMetricsStore`, `StoryMetricsStore`
- **@MainActor**: `BLEService` (CoreBluetooth), `LocalDeviceAccessory` (AVCaptureSession), `AccessoryManager`, all ViewModels

`AsyncStream` bridges callback-based APIs (BLE GATT notifications, audio tap, speech results) into structured concurrency.

### Dependency Injection

No DI framework. `AppDependencyContainer` constructs all service singletons at launch and passes them to `AppCoordinator`, which injects into ViewModels via factory methods (`makeCompanionViewModel()`, etc.). Views never construct services directly.

### Navigation

`AppCoordinator` owns a `Route` enum state machine:
`launch → terms → signIn → onboarding → home`

Fast-paths: if `hasAcceptedTerms` and `hasCompletedOnboarding` are set in UserDefaults, coordinator skips directly to `home`.

### Hardware Abstraction

`WearableAccessory` protocol abstracts three backends:
- `LocalDeviceAccessory` — iPhone camera (AVCaptureSession) + mic + speaker
- `BLEService` — CoreBluetooth GATT central for AiSee headset; reassembles chunked JPEG/audio via `ChunkBuffer`
- `ExternalSDKAccessory` — stub for Meta Glass / MFi cameras (not yet implemented)

`AccessoryManager` holds one instance of each and exposes `activeAccessory` based on `selectedType`.

### Key State

`CompanionViewModel` drives all post-login UI state. Central state enum in `SessionState.swift`:
`idle → scanning → connected → receivingImage → processingPrivacy → requestingStory → generatingStory → encodingAudio → sendingAudio → recordingAudio → listeningForAnswer → error(_)`

### Persistent Storage

All storage is `UserDefaults` (PoC scope). Typed accessors in `UserDefaults+Settings.swift`. Keys include: `auth.*`, `childName/Age/Preferences`, `storyDifficultyLevel`, `storyMode`, `selectedWearableType`, `hasAcceptedTerms`, `hasCompletedOnboarding`, `cloudAgentURL`.

## ML Model

`seesaw-yolo11n.mlpackage` (4.7 MB, checked into repo) — custom YOLO11n trained on 3,283 images across 44 child-environment classes. NMS is baked into the CoreML graph. Confidence threshold: 0.25. See the sibling ML training repo (`seesaw-companion-ios/../`) for training pipeline.

## Testing

Unit test files in `SeeSawTests/` (~130 tests, 0 failures):
- `PrivacyPipelineTests` — PII scrubbing correctness, metrics invariants, privacy compliance (100-run invariant)
- `OnDeviceStoryServiceTests` — story generation, error recovery, fallback paths
- `Gemma4StoryServiceTests` — `Gemma4StoryService` state machine, `parseResponse` JSON and heuristic paths
- `SceneContextTests` — payload bridging
- `StoryBeatTests` — struct invariants and static fallbacks
- `StoryToolsTests` — tool behaviour and UserDefaults side-effects
- `StoryGenerationModeTests`, `SeeSawTests` — smoke

`SeeSaw.xctestplan` has code coverage enabled and parallel execution enabled.

Tests run without Apple Intelligence hardware or MediaPipe via protocol-driven mocks (`MockStoryService`, `MockAudioService`) and `#if canImport` guards.

## Key Reference Documents

- `Pipeline.md` — Full implementation reference: all 4 modes, VAD 3-layer detail, sequence diagrams, configuration constants
- `SeeSaw-Project-Master.md` — Research context, thesis statement, research questions, novel contributions, dissertation structure
- `CODEBASE_BLUEPRINT.md` — Architecture diagrams (Mermaid), class relationships, full YOLO 44-class taxonomy
- `Observations.md` — Empirical research log: per-run latency data, story quality notes, thesis evidence
- `TestCoverage.md` — Latest test coverage report
- `README.md` — Project overview and architecture summary
