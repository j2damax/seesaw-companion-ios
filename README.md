# SeeSaw — Privacy-Preserving AI Story Companion

SeeSaw is a privacy-first iOS app that transforms a child's real-world environment into AI-generated interactive stories. Raw pixels and audio never leave the device — only anonymous scene labels reach any LLM.

---

## Thesis Statement

> *A structurally privacy-preserving edge AI architecture can generate contextually relevant, interactive children's stories with zero PII transmission, at latencies comparable to cloud-dependent alternatives.*

---

## Four Story Generation Architectures

| Mode | Code | Engine | Network | Latency |
|------|------|--------|---------|---------|
| **A — Cloud baseline** | `cloud` | Gemini 2.0 Flash via Cloud Run | ScenePayload only (no pixels) | 2–8 s |
| **B — On-Device (Apple FM)** | `onDevice` | Apple Foundation Models 3B | None | ~1.5–2 s |
| **C — On-Device (Gemma)** | `gemma4OnDevice` | Gemma 3 1B Q4_K_M via MediaPipe | None | ~1.5–2 s |
| **D — Hybrid** | `hybrid` | Gemma/Apple FM + Cloud Run (concurrent) | ScenePayload only | ~1.5 s + cloud enrichment |

Architecture D is the primary research contribution: local model generates immediately, cloud enhancement races during the speak/listen window (8–15 s). **88.9% cloud hit rate** observed on device.

---

## Privacy Pipeline

The same six-stage pipeline runs in all modes. Stages 3–5 execute in parallel.

```
JPEG frame (in-memory only — never written to disk)
    │
    ▼  Stage 1 — Face Detection      VNDetectFaceRectanglesRequest      ~15 ms
    ▼  Stage 2 — Face Blur           CIGaussianBlur σ=30                 ~8 ms
    ├─ Stage 3 — Object Detection    YOLO11n CoreML, 44 classes, ≥0.25  ~40 ms
    ├─ Stage 4 — Scene Classify      VNClassifyImageRequest, top-3, ≥0.3 ~35 ms
    └─ Stage 5 — Speech → Text       SFSpeechRecognizer (on-device only)
    ▼  Stage 6 — PII Scrub           PIIScrubber regex
    ▼
 ScenePayload { objects, scene, transcript }   ← only this crosses the boundary
```

**Privacy invariant:** Verified by a 100-run automated test — `ScenePayload` contains zero raw pixel data, zero face data, zero audio.

---

## Quick Start

```bash
# 1. Install dependencies (always open .xcworkspace, not .xcodeproj)
pod install
open SeeSaw.xcworkspace

# 2. Build (simulator)
xcodebuild build \
  -workspace SeeSaw.xcworkspace \
  -scheme SeeSaw \
  -destination 'platform=iOS Simulator,arch=arm64,id=E33D4588-A415-495B-8BEB-91B0AC534511' \
  -configuration Debug

# 3. Run all tests
xcodebuild test \
  -workspace SeeSaw.xcworkspace \
  -scheme SeeSaw \
  -destination 'platform=iOS Simulator,arch=arm64,id=E33D4588-A415-495B-8BEB-91B0AC534511' \
  -testPlan SeeSaw \
  -enableCodeCoverage YES \
  -resultBundlePath test-results/run.xcresult

# 4. Export coverage report
./export_test_results.sh
```

**Requirements:** iOS 26+ · Xcode 16+ · iPhone 12+ (Neural Engine) · CocoaPods

---

## Architecture Highlights

- **Actor-based concurrency** — every service is a Swift actor; `@MainActor` only where platform APIs require it
- **`ScenePayload` privacy boundary** — the only struct that crosses the device boundary; enforced structurally, not by policy
- **`@Generable StoryBeat`** — Apple Foundation Models structured output constrained to 3 fields; schema overhead is a first-class token-budget concern at 3B parameters
- **Three-layer VAD** — heuristic (<1 ms) → Apple FM semantic (~150 ms) → hard cap (8 s); no dedicated VAD model required
- **Polling deadline** — `consumeEnhancedBeat()` uses a 50 ms poll loop rather than `withTaskGroup` (which cannot enforce deadlines on unstructured tasks)
- **Protocol-driven testability** — `StoryGenerating`, `CloudEnhancing` protocols; mocks require no networking or Apple Intelligence hardware

---

## Repository Structure

```
SeeSaw/
  App/              AppConfig, AppCoordinator, AppDependencyContainer
  Services/
    AI/             OnDeviceStoryService, Gemma4StoryService,
                    BackgroundStoryEnhancer, HybridMetricsStore,
                    ModelDownloadManager, SemanticTurnDetector
    Cloud/          CloudAgentService (CloudEnhancing protocol)
    Privacy/        PrivacyPipelineService, PIIScrubber
    Audio/          AudioService, AudioCaptureService, SpeechRecognitionService
    BLE/            BLEService (AiSee headset)
  Model/            ScenePayload, StoryBeat, HybridBeatMetric, StoryTools
  ViewModel/        CompanionViewModel
  View/             SwiftUI views
SeeSawTests/        ~130 tests, 0 failures
```

---

## Key Documents

| Document | Purpose |
|----------|---------|
| `DEVELOPER_REFERENCE.md` | Full developer reference — architecture, commands, test results, learnings, limitations, thesis/viva guide |
| `Pipeline.md` | Implementation reference — all 4 modes, VAD detail, sequence diagrams |
| `Observations.md` | Empirical research log — per-run latency data, thesis evidence |
| `TestCoverage.md` | Latest test coverage report |

---

## Cloud Agent

| | |
|-|-|
| **URL** | `https://seesaw-cloud-agent-531853173205.europe-west1.run.app` |
| **Region** | `europe-west1` (Cloud Run) |
| **Model** | Gemini 2.0 Flash |
| **Endpoints** | `POST /story/generate` · `POST /story/enhance` (404 → fallback) |
| **Auth** | `X-SeeSaw-Key` header |

---

## Test Results

| Metric | Value |
|--------|-------|
| Total tests | ~130 |
| Failures | 0 |
| PIIScrubber coverage | 100% |
| Privacy invariant (100 runs) | 0 violations |
| Hybrid cloud hit rate (device) | 88.9% (8/9 beats) |
| SeeSawTests coverage | 89.8% |
