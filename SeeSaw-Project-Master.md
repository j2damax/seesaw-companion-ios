# SeeSaw — Project Master Document
### MSc Research Project · End-to-End Vision, Architecture & Research Strategy
**Last Updated:** April 10, 2026  
**Status:** Active Development · Final Submission Sprint (2 weeks remaining)

---

## Table of Contents

1. [Project Overview & Vision](#1-project-overview--vision)
2. [Research Context & Motivation](#2-research-context--motivation)
3. [Research Objectives & Questions](#3-research-objectives--questions)
4. [Original Research Contributions](#4-original-research-contributions)
5. [System Architecture Overview](#5-system-architecture-overview)
6. [Three-Tier Technical Architecture](#6-three-tier-technical-architecture)
7. [Privacy Pipeline — The Core Contribution](#7-privacy-pipeline--the-core-contribution)
8. [Gemma 4 Integration Strategy](#8-gemma-4-integration-strategy)
9. [Benchmark Design — The Distinction-Level Evidence](#9-benchmark-design--the-distinction-level-evidence)
10. [Implementation Status & Sprint Plan](#10-implementation-status--sprint-plan)
11. [Dissertation Structure Alignment](#11-dissertation-structure-alignment)
12. [Technology Stack Reference](#12-technology-stack-reference)
13. [Key Decisions & Rationale Log](#13-key-decisions--rationale-log)
14. [Future Work Roadmap](#14-future-work-roadmap)

---

## 1. Project Overview & Vision

### What is SeeSaw?

**SeeSaw** is a privacy-preserving, AI-powered interactive storytelling companion for children aged 3–8, built as an iOS application. Using the device's camera and microphone, SeeSaw observes the child's real-world environment and co-creates contextually grounded, personalised stories in real time — entirely on-device, with zero transmission of personally identifiable information (PII).

The name "SeeSaw" reflects the balance the system achieves: between AI capability and child safety, between cloud intelligence and on-device privacy, between technology and imaginative play.

### The Core Problem

Existing AI companions for children (e.g., OpenAI's Sora, various GPT-powered apps) offer powerful narrative generation but transmit raw audio, video, and personal context data to cloud servers. For child users, this creates a structural privacy risk that no terms-of-service can fully mitigate. Parents cannot meaningfully consent to real-time biometric data streaming for their children when the child is the active user.

SeeSaw proposes that **structural privacy** — architectures where sensitive data physically cannot leave the device — is the only credible solution, and demonstrates that it is achievable without unacceptable quality trade-offs.

### Project Thesis Statement

> *A structurally privacy-preserving edge AI architecture can generate contextually relevant, interactive children's stories with zero PII transmission, at latencies comparable to cloud-dependent alternatives, with narrative quality ratings statistically indistinguishable from cloud-generated outputs.*

This is the falsifiable central claim the dissertation proves or disproves through quantitative benchmark evidence.

---

## 2. Research Context & Motivation

### The Technology Convergence Opportunity

Three technology developments in 2024–2026 created the conditions for SeeSaw:

1. **On-device LLMs became viable:** Apple Foundation Models (~3B parameters, Neural Engine optimised), running at ~400ms latency on iPhone 15+, crossed the threshold for real-time interactive generation.

2. **Edge vision models became practical:** YOLO11n (2.6M parameters, ~4.7MB CoreML model) achieves real-time object detection at 30fps on iPhone with minimal battery impact.

3. **Privacy regulation tightened:** GDPR, COPPA, UK GDPR, and the emerging EU AI Act created legal and ethical pressure to move child-AI interaction off cloud pipelines.

### Gap in the Literature

Existing research on AI storytelling for children focuses on:
- Cloud-based LLM narrative generation (Zhao et al., 2023)
- Children's engagement with AI companions (Druga et al., 2022)
- Privacy frameworks for child digital services (Livingstone et al., 2023)

No published work combines **multimodal real-world scene understanding**, **on-device LLM generation**, and **structural privacy guarantees** in a deployed child-facing application. SeeSaw occupies this gap.

---

## 3. Research Objectives & Questions

### Primary Research Question

> *How can a privacy-preserving, on-device AI architecture enable contextually grounded, interactive storytelling for children while maintaining narrative quality comparable to cloud-dependent systems?*

### Secondary Research Questions

1. What is the measurable PII reduction achieved by structural privacy architecture compared to behavioural filtering and cloud-raw baselines?
2. What latency trade-offs are introduced by fully on-device multimodal processing?
3. Does on-device generation produce story beats rated equivalent in quality to cloud-generated alternatives?
4. What are the minimum hardware requirements for acceptable real-time performance?

### Research Objectives

| # | Objective | Chapter |
|---|-----------|---------|
| RO1 | Design and implement a five-stage on-device privacy pipeline for child AI interactions | Ch. 4 |
| RO2 | Create a domain-specific YOLO11n model trained on children's play environments | Ch. 4 |
| RO3 | Evaluate the pipeline against three benchmark architectures across four metrics | Ch. 6 |
| RO4 | Demonstrate interactive story co-creation quality equivalent to cloud systems | Ch. 6 |
| RO5 | Establish a replicable privacy evaluation methodology for edge AI systems | Ch. 5 |

### Null Hypothesis (H₀)

> A structurally privacy-preserving on-device architecture (Architecture C — SeeSaw) produces story beats that are rated statistically equivalent in quality to cloud-dependent architectures (A and B), while transmitting zero personally identifiable information.

---

## 4. Original Research Contributions

SeeSaw makes **three distinct original research contributions**:

### Contribution 1: YOLO11n-SeeSaw — Domain-Specific Children's Environment Vision Model

A custom-trained YOLO11n CoreML model fine-tuned on a curated dataset of children's play environments: toys, books, domestic objects, outdoor play items, and age-appropriate props. Standard COCO-trained models perform poorly on children's environments; this custom model addresses that gap with a domain-specific training set.

- **Architecture:** YOLOv11n backbone (2.6M params, 4.7MB)
- **Training:** Custom dataset + COCO transfer learning
- **Output:** Object labels + bounding boxes + confidence scores
- **Deployment:** CoreML `.mlpackage` on iOS

### Contribution 2: Privacy-Preserving Bridging Layer — Apple Foundation Models for Child Storytelling

A novel integration pattern that bridges on-device vision outputs (YOLO11n labels) with Apple Foundation Models via a structured `SceneContext` protocol, generating child-appropriate story beats without raw media ever entering the language model. This bridging narration layer is the first published implementation of Apple Foundation Models for child-facing interactive storytelling.

- **Input:** Structured `SceneContext` JSON (labels, spatial relationships, child speech transcript)
- **Model:** Apple Foundation Models (on-device, ~3B params)
- **Output:** Age-appropriate `StoryBeat` narrative (50–120 words, second-person, present tense)
- **Privacy:** No raw image, audio, or biometric data enters the model

### Contribution 3 (Future): SeeSaw-Gemma-1B — Fine-Tuned Open-Weight Edge LLM

A Gemma 4 1B model fine-tuned on children's story beat training data via Google Vertex AI, producing a portable, open-weight, child-safe story generation model that can be deployed on any mobile device. This contribution is planned post-submission and noted as future work in Chapter 7.

---

## 5. System Architecture Overview

### High-Level Component Map

```
┌─────────────────────────────────────────────────────────────────┐
│                    SeeSaw iOS App                                │
│  seesaw-companion-ios                                            │
│                                                                  │
│  ┌─────────────┐   ┌──────────────┐   ┌─────────────────────┐   │
│  │ Camera Feed │──▶│ YOLO11n      │──▶│ SceneContext Builder │   │
│  │ (AVFoundation)│  │ (CoreML)     │   │                     │   │
│  └─────────────┘   └──────────────┘   └──────────┬──────────┘   │
│                                                   │              │
│  ┌─────────────┐                                  │              │
│  │ Microphone  │──▶ SFSpeechRecognizer ───────────┤              │
│  │ (AVAudio)   │   (on-device)                    │              │
│  └─────────────┘                                  ▼              │
│                                         ┌──────────────────┐     │
│                                         │ Apple Foundation │     │
│                                         │ Models (on-device│     │
│                                         │ ~3B, Neural Eng) │     │
│                                         └────────┬─────────┘     │
│                                                  │               │
│                                         ┌────────▼─────────┐     │
│                                         │  AVSpeechSynth   │     │
│                                         │  (TTS, on-device)│     │
│                                         └──────────────────┘     │
└─────────────────────────────────────────────────────────────────┘
                              │
                    (Optional, when online)
                              │
              ┌───────────────▼────────────────┐
              │     seesaw-cloud-agent          │
              │     (Google Cloud Run)          │
              │                                 │
              │  FastAPI + Google ADK           │
              │  Gemini 2.0 Flash               │
              │  Firestore (session memory)     │
              │  Cloud TTS (premium voices)     │
              └─────────────────────────────────┘
```

### The Five-Stage On-Device Privacy Pipeline

```
Stage 1: CAPTURE
Raw Camera Frame (UIImage) + Raw Audio (AVAudioPCMBuffer)
         │
         ▼ [YOLO11n CoreML inference + VNDetectFaceRectanglesRequest]
         │  [SFSpeechRecognizer on-device transcription]
         │  ⚠️  Raw frame and audio DISCARDED after this stage
         │
Stage 2: DETECT & ANONYMISE
Object labels + confidence scores (no raw pixels)
Face bounding boxes — presence detected, NOT identity
Speech transcript (local text, no audio stream)
         │
         ▼ [SceneContext Assembly]
Stage 3: CONTEXTUALISE
SceneContext {
  detectedObjects: ["teddy bear", "red cup", "book"],
  sceneType: "bedroom_play",
  facePresence: true,  // boolean only — no biometric data
  speechFragment: "make the bear go on adventure",
  timestamp: ISO8601
}
         │
         ▼ [Apple Foundation Models — on-device]
Stage 4: GENERATE
StoryBeat {
  narrative: "Your teddy bear finds a mysterious map...",
  tone: "adventurous",
  suggestedNextPrompt: "Where does the map lead?",
  ageGroup: "5-7"
}
         │
         ▼ [AVSpeechSynthesizer — on-device]
Stage 5: NARRATE
Spoken story narration
Visual beat display on screen
```

**Privacy Guarantee:** At no point after Stage 1 does any raw image, audio recording, voice biometric, or face image exist in memory or leave the device.

---

## 6. Three-Tier Technical Architecture

### Tier 1 — On-Device Vision (seesaw-vision)

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Camera Capture | `AVCaptureSession` | Real-time frame acquisition |
| Object Detection | YOLO11n-SeeSaw CoreML | Domain-specific object recognition |
| Face Anonymisation | `VNDetectFaceRectanglesRequest` | Presence detection without identity |
| Speech Recognition | `SFSpeechRecognizer` | On-device STT transcription |
| Context Assembly | `SceneContext` Swift struct | Structured anonymised scene representation |

**Runtime target:** iPhone 12+, iOS 26+  
**Latency target:** <150ms for YOLO inference, <200ms for speech recognition

### Tier 2 — On-Device Intelligence (seesaw-companion-ios)

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Story Generation | Apple Foundation Models | On-device LLM narrative generation |
| Story Safety | Apple FM safety config | Age-appropriate output filtering |
| Turn Management | `StorySessionManager` Swift actor | Multi-turn conversation state |
| TTS | `AVSpeechSynthesizer` | On-device voice narration |
| Fallback Engine | Template-based generator | Offline/model-unavailable fallback |

**Model:** Apple Foundation Models (~3B params, Neural Engine)  
**Latency target:** <400ms end-to-end (Stage 3 → Stage 5)

### Tier 3 — Cloud Enhancement (seesaw-cloud-agent)

| Component | Technology | Purpose |
|-----------|-----------|---------|
| API Layer | FastAPI (Python) | REST endpoints for cloud features |
| Agent Framework | Google ADK (Agent Development Kit) | Multi-agent orchestration |
| Story Model | Gemini 2.0 Flash | Premium cloud story generation |
| Session Memory | Firestore | Cross-session story continuity |
| Safety | ShieldGemma 4 | Cloud-side content moderation |
| TTS | Google Cloud TTS | Premium voice quality |
| Auth | Firebase Auth | Parent account management |

**Deployment:** Google Cloud Run (auto-scaling)  
**Privacy contract:** iOS app sends only `SceneContext` JSON to cloud — never raw media  
**Activation:** Only when network available AND user has premium subscription

### Tier 3 Dual Role (Post-Submission)

The cloud agent also serves as a **model training and distribution hub**:
- Vertex AI fine-tuning pipeline for Gemma 4 1B
- Produces `SeeSaw-Gemma-1B.gguf` (INT4 quantised, ~800MB)
- Distributed to iOS app via CDN on first launch

---

## 7. Privacy Pipeline — The Core Contribution

### Three Architecture Comparison (Benchmark)

| | Architecture A (Baseline) | Architecture B (Filtered) | Architecture C (SeeSaw) |
|--|--------------------------|--------------------------|------------------------|
| **Design** | Raw data → Cloud | Labels → Cloud | All processing on-device |
| **Raw video transmitted** | ✅ Yes | ❌ No | ❌ No |
| **Raw audio transmitted** | ✅ Yes | ❌ No | ❌ No |
| **PII items/session (expected)** | HIGH | MEDIUM | **ZERO** |
| **Privacy type** | None | Behavioural | **Structural** |
| **Network dependency** | Always required | Required | **None** |

### Privacy Types Defined

**Behavioural Privacy:** System claims not to store/use sensitive data, but data still physically traverses the network and server infrastructure. Trust-dependent.

**Structural Privacy:** Sensitive data is anonymised and discarded on-device before any network communication. The architecture physically prevents PII transmission regardless of server-side behaviour. Trust-independent.

SeeSaw implements **structural privacy** — the only type that can be independently verified without trusting the operator.

### Face Anonymisation Detail

```swift
// VNDetectFaceRectanglesRequest — presence only, no recognition
let faceRequest = VNDetectFaceRectanglesRequest { request, error in
    let faceCount = (request.results as? [VNFaceObservation])?.count ?? 0
    context.facePresenceDetected = faceCount > 0
    // Raw frame is explicitly nil'd here — never passed to LLM
    rawFrame = nil
}
```

This is intentional and must be documented in Chapter 4 as a design decision. The system knows *a child is present* but not *who the child is*.

---

## 8. Gemma 4 Integration Strategy

### Gemma 4 Model Family (Released April 2026)

| Model | Params | Context | Modalities | On-Device? |
|-------|--------|---------|------------|------------|
| Gemma 4 1B | 1B | 32K | Text only | ✅ iPhone-viable (~800MB INT4) |
| Gemma 4 4B | 4B | 128K | Text + Vision | ⚠️ Too heavy for real-time |
| Gemma 4 12B | 12B | 128K | Text + Vision | ❌ Server only |
| Gemma 4 27B | 27B | 128K | Text + Vision | ❌ Server only |

### Three-Mode Story Generation Architecture

```swift
enum StoryGenerationMode {
    case appleFoundationModels     // Built-in, always available, fastest (~400ms)
    case gemma4OnDevice            // Downloaded once, fine-tuned, best offline quality (~700ms)
    case geminiCloudEnhanced       // When network available, highest quality (~2-4s)
}

func selectMode(networkAvailable: Bool, gemmaLoaded: Bool) -> StoryGenerationMode {
    if networkAvailable { return .geminiCloudEnhanced }
    if gemmaLoaded      { return .gemma4OnDevice }
    return .appleFoundationModels
}
```

### Gemma 4 Implementation Path (Post-Submission / Future Work)

1. Fine-tune Gemma 4 1B on children's story beat data via Google Vertex AI (LoRA, ~8h training)
2. Export to GGUF INT4 format (~800MB)
3. Deploy via MediaPipe LLM Inference on iOS
4. Distribute model file via CDN with `/model/latest` signed URL endpoint
5. iOS app downloads once on first launch, shows progress to parent

**Status:** Planned as Contribution 3. Not in scope for MSc submission — listed in Chapter 7 (Future Work).

---

## 9. Benchmark Design — The Distinction-Level Evidence

### Why This Benchmark Matters

The benchmark is the single highest-value activity in the remaining 2 weeks. It transforms the dissertation from a project report into a research document. Every examiner of a "privacy-preserving AI" dissertation will ask: *how do you know it actually preserves privacy, and by how much?* This benchmark answers that question with real numbers.

### Benchmark Setup

**Test Inputs (fixed set, used across all 3 architectures):**
- 10 test photos: children's bedroom objects, play scenes, faces visible
- 10 audio clips: children's speech fragments, story prompts

**Measurement Tools:**
- Charles Proxy / Wireshark: intercept and count bytes + PII items transmitted
- Xcode Instruments (Time Profiler): measure per-stage latency
- iOS Battery API: measure energy consumption over 30-minute session
- Human rating form (Google Form): 5-point Likert scale, 3 raters

### Results Table (Chapter 6 Template)

| Metric | Architecture A (Cloud Raw) | Architecture B (Cloud Filtered) | Architecture C (SeeSaw) |
|--------|---------------------------|----------------------------------|-------------------------|
| PII items transmitted / session | *measured* | *measured* | **0** |
| Raw bytes transmitted / session (KB) | *measured* | *measured* | **0** |
| End-to-end latency — mean (ms) | *measured* | *measured* | *measured* |
| End-to-end latency — P95 (ms) | *measured* | *measured* | *measured* |
| Battery drain / 30 min (%) | *measured* | *measured* | *measured* |
| Story quality — relevance (μ/5) | *rated* | *rated* | *rated* |
| Story quality — creativity (μ/5) | *rated* | *rated* | *rated* |
| Story quality — age-appropriateness (μ/5) | *rated* | *rated* | *rated* |
| Inter-rater agreement (Cohen's κ) | — | — | *calculated* |

### Story Quality Evaluation Protocol

1. Generate 10 story beats using each architecture from the same 10 inputs
2. Present beats to 3 adult raters (blind to architecture) via Google Form
3. Rate each beat on relevance (0–5), creativity (0–5), age-appropriateness (0–5)
4. Calculate mean + standard deviation per architecture per dimension
5. Calculate Cohen's Kappa for inter-rater agreement
6. Report whether Architecture C is statistically equivalent to A/B (H₀ test)

### BenchmarkLogger Implementation

```swift
actor BenchmarkLogger {
    struct StageTimestamp {
        let stage: PipelineStage
        let startTime: Date
        let endTime: Date
        var durationMs: Double { endTime.timeIntervalSince(startTime) * 1000 }
    }
    
    enum PipelineStage: String, CaseIterable {
        case capture, detect, contextualise, generate, narrate
    }
    
    private var log: [StageTimestamp] = []
    
    func record(stage: PipelineStage, start: Date, end: Date) {
        log.append(StageTimestamp(stage: stage, startTime: start, endTime: end))
    }
    
    func exportCSV() -> String {
        let header = "stage,start,end,duration_ms"
        let rows = log.map { "\($0.stage.rawValue),\($0.startTime),\($0.endTime),\($0.durationMs)" }
        return ([header] + rows).joined(separator: "\n")
    }
}
```

### Architecture A Baseline (CloudBaselineService)

```swift
// Required for benchmark counterfactual — 30 min to implement
class CloudBaselineService {
    func sendRawToCloud(frame: UIImage, audio: AVAudioPCMBuffer) async {
        let imageData = frame.jpegData(compressionQuality: 0.8)!
        let audioData = audio.toData()
        
        // Send to controlled endpoint (localhost or test server)
        // Charles Proxy intercepts here and counts:
        // - Total bytes transmitted
        // - Faces visible (manual count from photos)
        // - Audio containing child speech
        var request = URLRequest(url: URL(string: "http://localhost:8080/baseline")!)
        request.httpMethod = "POST"
        request.httpBody = imageData + audioData
        _ = try? await URLSession.shared.data(for: request)
    }
}
```

---

## 10. Implementation Status & Sprint Plan

### Current Status (April 10, 2026)

| Component | Status |
|-----------|--------|
| YOLO11n-SeeSaw CoreML model | ✅ Complete |
| iOS camera capture pipeline | ✅ Complete |
| YOLO integration in iOS | ✅ Complete |
| Apple Foundation Models integration | ✅ Basic groundwork complete |
| AVSpeechSynthesizer TTS | ✅ Complete |
| SceneContext assembly | ✅ Complete |
| seesaw-cloud-agent FastAPI skeleton | ✅ Basic groundwork complete |
| BenchmarkLogger | ❌ Not started |
| Architecture A baseline | ❌ Not started |
| Architecture B filtered baseline | ❌ Not started |
| Story quality evaluation | ❌ Not started |
| Dissertation Chapters 4–6 | 🔄 In progress |

### 2-Week Final Sprint Plan

#### Week 1: Build the Benchmark (Days 1–7)

| Day | Task | Output |
|-----|------|--------|
| Day 1 | Complete `BenchmarkLogger` + instrument all 5 pipeline stages | Latency data collection working |
| Day 2 | Build `CloudBaselineService` (Arch A) + set up Charles Proxy intercept | Counterfactual baseline working |
| Day 3 | Run full benchmark — all 3 architectures, 20 test inputs | Raw CSV data collected |
| Day 4 | Build story quality rating form (Google Form) + generate 30 story beats (10×3 arch) | Story beats ready for rating |
| Day 5 | Complete quality rating (3 raters) + calculate Cohen's Kappa | Quality data complete |
| Day 6 | Write Chapter 6 (Results) using real measured data | Chapter 6 draft complete |
| Day 7 | Review Chapter 6, create results figures (charts, tables) | Chapter 6 final |

#### Week 2: Write, Polish, Submit (Days 8–14)

| Day | Task | Output |
|-----|------|--------|
| Day 8 | Write Chapter 5 (Discussion — interpret benchmark, connect to RQs) | Chapter 5 draft |
| Day 9 | Complete Chapter 4 (Implementation — YOLO section + Apple FM section + privacy pipeline) | Chapter 4 final |
| Day 10 | Complete Chapter 3 (Methodology — benchmark design, ethics, participants) | Chapter 3 final |
| Day 11 | Write Abstract, fix Introduction, Chapter 2 citation corrections | Chapters 1–2 final |
| Day 12 | Insert all figures: Xcode screenshots, Wireshark outputs, training curves, architecture diagrams | All figures inserted |
| Day 13 | Full dissertation review — word count, formatting, reference list (IEEE/APA format) | Pre-submission review complete |
| Day 14 | Final proofread → **SUBMIT** | 🎓 Submitted |

### What to Drop (Do Not Implement)

The following are **not in scope for MSc submission** and must be listed in Chapter 7 (Future Work):

- ❌ Gemma 4 1B on-device integration
- ❌ Vertex AI fine-tuning pipeline
- ❌ Parent dashboard full UI
- ❌ Community story wall
- ❌ seesaw-cloud-agent Firestore + full ADK multi-agent pipeline
- ❌ Long-term cross-session story memory

---

## 11. Dissertation Structure Alignment

### Chapter Map

| Chapter | Title | Key Content | SeeSaw Component |
|---------|-------|-------------|-----------------|
| Ch. 1 | Introduction | Problem, RQs, contributions, structure | Full system overview |
| Ch. 2 | Literature Review | Edge AI, children's privacy, on-device LLMs, AI storytelling | Research context |
| Ch. 3 | Methodology | Benchmark design, ethics, data collection, evaluation protocol | Benchmark design |
| Ch. 4 | System Design & Implementation | Architecture, YOLO11n, Apple FM, privacy pipeline | All tiers |
| Ch. 5 | Discussion | Benchmark interpretation, limitations, implications | Results analysis |
| Ch. 6 | Results | Benchmark data, quality ratings, statistical analysis | Benchmark output |
| Ch. 7 | Conclusion & Future Work | Contributions, limitations, Gemma 4 roadmap | Future contributions |

### Chapter 6 Narrative Arc

The results chapter must tell this story:

1. **Privacy result:** Architecture C transmitted 0 bytes of PII vs. X KB (Architecture A) and Y KB (Architecture B). This is a structural guarantee, not a policy claim.

2. **Latency result:** Architecture C achieved Z ms end-to-end, compared to W ms (Architecture A, excluding network RTT) and V ms (Architecture B). The on-device system is [faster/slower] than cloud alternatives when network latency is included.

3. **Quality result:** Architecture C story beats were rated [equivalent/higher/lower] to Architectures A and B on relevance (μ=X), creativity (μ=Y), and age-appropriateness (μ=Z). H₀ [rejected/not rejected] at p<0.05.

4. **Conclusion:** The system achieves absolute privacy with [acceptable/superior] quality and [competitive/superior] latency. The trade-off is favourable for a child-facing application where privacy must be non-negotiable.

---

## 12. Technology Stack Reference

### iOS Application (seesaw-companion-ios)

| Layer | Technology | Version |
|-------|-----------|---------|
| Language | Swift | 5.10 |
| UI | SwiftUI | iOS 26+ |
| Vision | Vision framework + CoreML | iOS 26+ |
| Object Detection | YOLO11n-SeeSaw.mlpackage | Custom trained |
| Face Detection | VNDetectFaceRectanglesRequest | iOS 26+ |
| Speech Recognition | SFSpeechRecognizer | iOS 26+ |
| LLM | Apple Foundation Models | iOS 26.1+ |
| TTS | AVSpeechSynthesizer | iOS 26+ |
| Camera | AVCaptureSession | iOS 26+ |
| Networking | URLSession + async/await | iOS 26+ |
| Concurrency | Swift actors + async/await | Swift 5.5+ |

### Cloud Agent (seesaw-cloud-agent)

| Layer | Technology | Version |
|-------|-----------|---------|
| Language | Python | 3.11+ |
| API Framework | FastAPI | 0.111+ |
| Agent Framework | Google ADK (Agent Dev Kit) | Latest |
| LLM | Gemini 2.0 Flash | GA |
| Session Store | Cloud Firestore | Latest |
| Auth | Firebase Authentication | Latest |
| TTS | Google Cloud Text-to-Speech | Latest |
| Safety | ShieldGemma 4 | April 2026 |
| Deployment | Google Cloud Run | Latest |
| Container | Docker | 24+ |

### YOLO11n Training

| Component | Technology |
|-----------|-----------|
| Base Model | YOLOv11n (Ultralytics) |
| Training Framework | Ultralytics Python SDK |
| Dataset | Custom children's environment dataset + COCO |
| Export Format | CoreML .mlpackage (iOS) + ONNX (cross-platform) |
| Parameters | 2.6M |
| Model Size | ~4.7MB |
| Inference Speed | <150ms on iPhone 12+ |

---

## 13. Key Decisions & Rationale Log

### Decision 1: Apple Foundation Models over Gemini Nano / Gemma 4 for Tier 2

**Decision:** Use Apple Foundation Models as the primary on-device LLM, not Gemini Nano or Gemma 4 1B.

**Rationale:**
- Apple Foundation Models runs via the Neural Engine with system-level optimisation — no model download required
- Zero setup friction for end users
- Deepest OS integration (privacy attestation built in)
- Gemma 4 1B is a better fine-tunable option but requires an 800MB download, adding complexity outside the MSc timeline

**Trade-off accepted:** Apple FM is not fine-tunable by the application; Gemma 4 would be. This is noted as a future enhancement.

### Decision 2: Structural Privacy over Behavioural Privacy

**Decision:** Discard raw media on-device immediately after extraction, never passing it to any model or API.

**Rationale:** Behavioural privacy (filtering + policy) requires trusting the operator. Structural privacy is independently verifiable. For a child-facing application, only structural privacy is defensible under COPPA/GDPR-K.

**Trade-off accepted:** Loss of some context richness (face expression, scene texture) that cloud vision APIs could leverage.

### Decision 3: Three-Tier Architecture over Simple On-Device

**Decision:** Build a three-tier system (edge vision + on-device LLM + optional cloud enhancement) rather than a pure on-device system.

**Rationale:** Supports multiple deployment contexts: no-connectivity (school, rural), home with Wi-Fi (cloud-enhanced), future premium subscription tier. The privacy guarantee is maintained regardless of tier — the cloud agent never receives raw media.

### Decision 4: YOLO11n over YOLO11s/m/l

**Decision:** Use YOLO11n (nano) variant, not a larger YOLO11 model.

**Rationale:** Real-time inference at 30fps on iPhone 12+ is achievable only with the nano variant. Larger variants exceed the battery and latency budget. Accuracy trade-off is acceptable given the domain (children's toy-scale objects, not complex scenes).

### Decision 5: Two-Week Benchmark Sprint over Feature Completion

**Decision:** Prioritise running the privacy pipeline benchmark over completing Gemma 4 integration, parent dashboard, or cloud agent full feature set.

**Rationale:** The benchmark is the primary evidence for the dissertation's central claim. Incomplete features can be listed as future work. Missing benchmark data cannot be compensated by additional features.

---

## 14. Future Work Roadmap

The following are out of scope for the MSc submission but represent the natural product development roadmap:

### Phase 2 (Q3 2026): Gemma 4 Integration

- Fine-tune Gemma 4 1B on 10,000+ children's story beat training examples
- Deploy as `SeeSaw-Gemma-1B.gguf` (~800MB, INT4 quantised)
- Integrate via MediaPipe LLM Inference on iOS
- Conduct A/B quality comparison: Apple FM vs. SeeSaw-Gemma-1B
- Publish as open-weight model on HuggingFace

### Phase 3 (Q4 2026): Full Cloud Agent

- Complete Google ADK multi-agent pipeline
- Firestore-backed cross-session story continuity ("chapter memory")
- Parent dashboard: story review, vocabulary tracking, session history
- Community story wall: anonymised story beat sharing
- Premium subscription tier

### Phase 4 (2027): Platform Expansion

- Android port using Gemma 4 1B + MediaPipe (no Apple FM dependency)
- Web companion for browser-based access
- Educator mode: classroom story creation with teacher controls
- Accessibility features: sign language detection (YOLO hand pose), simplified TTS

### Research Extensions

- Longitudinal study: vocabulary development in children using SeeSaw vs. control
- Parent trust study: comparing parental comfort with SeeSaw vs. cloud alternatives
- Comparative privacy study: formal privacy proofs using differential privacy frameworks
- Multi-language expansion: non-English story generation with cultural context adaptation

---

## Appendix A: Research Question ↔ Architecture Mapping

| Research Question | Architecture Component | Benchmark Metric |
|-------------------|----------------------|-----------------|
| RQ1: PII reduction | Privacy pipeline (all 3 architectures) | PII items transmitted / session |
| RQ2: Latency trade-offs | BenchmarkLogger (per stage) | Latency mean + P95 (ms) |
| RQ3: Story quality equivalence | Quality rating evaluation | Likert scores, Cohen's κ |
| RQ4: Hardware requirements | Xcode Instruments | iPhone model × latency matrix |

---

## Appendix B: Privacy Pipeline Stage Timing Targets

| Stage | Component | Target | Acceptable Max |
|-------|-----------|--------|---------------|
| Stage 1: Capture | AVCaptureSession | 33ms (30fps) | 50ms |
| Stage 2: Detect | YOLO11n CoreML | 100ms | 150ms |
| Stage 2b: Speech | SFSpeechRecognizer | 150ms | 250ms |
| Stage 3: Contextualise | SceneContext assembly | 10ms | 20ms |
| Stage 4: Generate | Apple Foundation Models | 350ms | 600ms |
| Stage 5: Narrate | AVSpeechSynthesizer | 50ms | 100ms |
| **Total** | **End-to-end** | **~700ms** | **1,200ms** |

Note: Stages 2 and 2b run in parallel. Total is Stage1 + max(Stage2, Stage2b) + Stage3 + Stage4 + Stage5.

---

## Appendix C: Gemma 4 vs. Apple FM Comparison

| Dimension | Apple Foundation Models | Gemma 4 1B |
|-----------|------------------------|------------|
| Parameters | ~3B (estimated) | 1B |
| On-device size | Built-in (0MB download) | ~800MB download |
| Fine-tunable | ❌ No | ✅ Yes |
| Open weights | ❌ No | ✅ Yes |
| iOS integration | Native Neural Engine | MediaPipe or llama.cpp |
| Context window | Not published | 32K tokens |
| Multimodal | Text only (via bridging) | Text only (1B variant) |
| Setup friction | Zero | One-time 800MB download |
| Research value | Deployment novelty | Academic publishability |
| MSc scope | ✅ In scope | ❌ Future work |

---

*Document compiled from SeeSaw MSc research conversation, April 2026.*  
*For the latest version, refer to the project repository README.*
