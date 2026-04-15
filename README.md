# SeeSaw — Privacy-Preserving Edge AI Story Companion

**MSc Computer Science Research Prototype · University of East London · 2026**

SeeSaw is a privacy-first iOS app that transforms a child's real-world environment into AI-generated interactive stories — entirely on-device, with zero raw PII transmitted to any server.

---

## Research Thesis

> *A structurally privacy-preserving edge AI architecture can generate contextually relevant, interactive children's stories with zero PII transmission, at latencies comparable to cloud-dependent alternatives, with narrative quality ratings statistically indistinguishable from cloud-generated outputs.*

### Research Questions

| RQ | Question | Evidence |
|----|----------|---------|
| Primary | Can privacy-preserving edge AI enable quality interactive storytelling for children? | Architecture A works end-to-end with zero transmission |
| RQ1 | How much PII is prevented from cloud transmission vs. baseline? | `totalPiiTokensRedacted` per session; privacy invariant tests |
| RQ2 | What are the latency trade-offs between on-device and cloud architectures? | StoryMetricsStore CSV export, benchmark sessions |
| RQ3 | Is on-device story quality equivalent to cloud-generated quality? | Guardrail violations = 0 across all modes |
| RQ4 | What is the minimum hardware requirement? | iPhone 12+ (Neural Engine) |

---

## Three Story Generation Architectures

| Mode | Engine | Network | First-Beat Latency |
|------|--------|---------|-------------------|
| **Architecture A — Apple FM** | Apple Foundation Models (3B, Neural Engine) | None | ~400–500 ms TTFT |
| **Architecture B — Cloud** | Gemini 2.0 Flash via Cloud Run FastAPI | Labels only (no pixels/audio) | ~1.5–3 s (warm) |
| **Architecture C — Gemma** | Gemma 3 1B Q4_K_M GGUF via MediaPipe | None | ~600–800 ms |

All three modes share the same **six-stage privacy pipeline**. Only anonymous `ScenePayload` (object labels + scrubbed transcript) crosses the generation boundary — raw pixels and audio never leave the device in any mode.

---

## Privacy Pipeline

```
Stage 1  Face detection      VNDetectFaceRectanglesRequest
Stage 2  Face blur           CIGaussianBlur (σ ≥ 30)          ← before any ML
Stage 3  Object detection    YOLO11n CoreML (44 classes, conf ≥ 0.25)
Stage 4  Scene classify      VNClassifyImageRequest (conf ≥ 0.3)
Stage 5  Speech → text       SFSpeechRecognizer (on-device only)
Stage 6  PII scrub           PIIScrubber regex (names, numbers, locations)
         ↓
      ScenePayload { objects:[String], scene:[String], transcript:String? }
```

**Privacy invariant:** `rawDataTransmitted = false` is stored in every session record and verified by the automated test suite (100-run invariant, 0 failures).

---

## Novel Research Contributions

1. **YOLO11n-SeeSaw** — Custom object detector trained across 3 dataset layers (3,283 images, 44 child-environment classes). Training pipeline in sibling ML repo.

2. **Privacy-Preserving Bridging Layer** — First published Apple Foundation Models integration for child-facing interactive storytelling. `@Generable StoryBeat` with structured output, semantic VAD (LLM-assisted turn detection replacing hard timeouts).

3. **SeeSaw-Gemma-1B** — Fine-tuned open-weight edge LLM for child co-creative storytelling (eval_loss = 0.4945, Q4_K_M GGUF, 777 MB). First demonstrably safe, auditable, child-specific on-device story LLM.

---

## System Requirements

- iOS 26.0+ (Architecture A requires Apple Foundation Models)
- iPhone 12+ recommended (Neural Engine)
- Architecture C: ~800 MB storage for model download

## Repository Structure

```
SeeSaw/                      iOS app source
  App/                       AppConfig, coordinator, DI container
  Services/
    AI/                      OnDeviceStoryService, Gemma4StoryService, ModelDownloadManager
    Cloud/                   CloudAgentService
    Pipeline/                PrivacyPipelineService
    Audio/                   AudioService, SpeechRecognitionService
    BLE/                     BLEService (AiSee headset)
  Model/                     ScenePayload, StoryBeat, StoryMetricsEvent, PrivacyMetrics
  ViewModel/                 CompanionViewModel (central orchestrator)
  View/                      SwiftUI views
SeeSawTests/                 Unit test suite (~130 tests, 0 failures)
Pipeline.md                  Full architecture reference with Mermaid diagrams
Observations.md              Empirical research log (Runs 4–6, benchmark data)
CLAUDE.md                    Developer guide for Claude Code sessions
```

## Key Documentation

| Document | Purpose |
|----------|---------|
| `CLAUDE.md` | Developer reference: commands, architecture, concurrency model |
| `Pipeline.md` | Full implementation reference: all 4 modes, VAD, sequence diagrams |
| `Observations.md` | Empirical research log: run data, latency benchmarks, thesis evidence |
| `SeeSaw-Project-Master.md` | Research context, thesis statement, RQs, contributions |
| `CODEBASE_BLUEPRINT.md` | Architecture diagrams, class relationships, YOLO class taxonomy |
| `TestCoverage.md` | Test suite results and coverage report |
| `Research Marking Scheme.md` | MSc marking criteria |
