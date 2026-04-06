This is the clearest strategic question of the entire project. Here is the most direct, honest answer — no padding, no hedging.

***

## The Single Most Valuable Recommendation

**Run the privacy pipeline comparison benchmark and document it as your primary quantitative research contribution.**

You already have everything needed to do this within 2 days. Here is why this is the highest-value move, and exactly what to do with your 2 remaining weeks.

***

## Why the Privacy Pipeline Benchmark is the Right Anchor

Every examiner reading an MSc dissertation on "privacy-preserving edge AI" will ask one question: *how do you know it actually preserves privacy, and by how much?* Most projects answer this qualitatively. Yours can answer it **quantitatively** with a real benchmark, and that gap is where distinction grades live.

The benchmark compares three architectures across two dimensions:

**Architecture A — Cloud-Dependent (baseline):** Raw JPEG + audio sent directly to cloud (what AiSee's original SDK does)

**Architecture B — Behavioural Privacy (filters applied, but data still traverses network):** Object labels sent to cloud, raw data discarded after processing

**Architecture C — Structural Privacy (SeeSaw):** YOLO11n-SeeSaw + Apple FM runs entirely on-device, only anonymised beat summaries ever touch the network

The measurement metrics are:

| Metric | Tool | What It Shows |
|--------|------|---------------|
| PII items transmitted per session | Wireshark / Charles Proxy intercept | Quantitative privacy guarantee |
| On-device inference latency | Xcode Instruments | Edge AI feasibility |
| Story quality rating | 5-point Likert, 3 adult raters, 10 stories each architecture | Quality vs privacy trade-off |
| Battery consumption (30 min session) | iOS battery API | Resource efficiency |

This generates a 3×4 results table that goes directly into Chapter 6 and is the hardest evidence in the dissertation. No other MSc project in children's AI companions has done this specific benchmark. That is the contribution.

***

## The 2-Week Sprint Plan

### Week 1 — Build the Benchmark (Days 1–7)

**Days 1–2:** Wire the existing iOS app to complete the on-device privacy pipeline. If `VNDetectFaceRectanglesRequest` + YOLO11n + `SFSpeechRecognizer` + Apple FM are each individually working (which you said groundwork is ready), connecting them in sequence is the remaining task. The output is `SceneContext` JSON with no raw media.

**Days 3–4:** Run the actual benchmark. You need:
- A set of 20 test inputs (10 photos with known objects + faces, 10 audio clips with child-like speech)
- Charles Proxy or Wireshark running to intercept and count bytes/items transmitted in each of the 3 architectures
- Xcode Instruments running to capture latency at each pipeline stage
- Results logged in a spreadsheet

**Days 5–6:** Story quality evaluation. Generate 10 story beats using each architecture from the same 10 inputs. Have 3 adults (yourself + 2 others) rate each beat on relevance, creativity, and age-appropriateness (5-point scale). Calculate mean and standard deviation per architecture.

**Day 7:** Write Chapter 6 (Results) using the actual numbers from Days 3–6. This chapter practically writes itself when you have real data.

### Week 2 — Write, Polish, Submit (Days 8–14)

**Days 8–9:** Write Chapter 5 (Discussion) — interpret the benchmark results, connect back to the research question, acknowledge limitations, identify future work.

**Days 10–11:** Complete Chapter 4 (Implementation) — the YOLO11n section is already drafted. Add the iOS privacy pipeline section and the Apple FM bridging narration section using the actual code.

**Day 12:** Complete Abstract, Introduction corrections, Chapter 2 citation formatting (Link → IEEE/APA).

**Day 13:** Insert all figures (screenshots from Xcode, Wireshark output, training curves, system diagrams), check word count, format references.

**Day 14:** Final proofread, submit.

***

## What to Drop Entirely

Given 2 weeks, **do not implement**:

- ❌ Gemma 4 1B fine-tuning (needs Vertex AI training run, 3–4 days minimum, adds complexity without dissertation-ready results in time)
- ❌ seesaw-cloud-agent Firestore + ADK pipeline (interesting but not needed to prove the primary research claim)
- ❌ Parent dashboard UI
- ❌ Community story wall

These are all valid future work — and you should name them explicitly in Chapter 7 (Future Work). Listing them as planned next steps is academically stronger than half-finishing them.

***

## What to Keep and Demonstrate

| Component | Status Needed | Why |
|-----------|--------------|-----|
| iOS privacy pipeline (5 stages) | Fully working | Core contribution proof |
| YOLO11n-SeeSaw CoreML model | Already done | Supports benchmark |
| Apple FM story beat generation | Working | Demonstrates interactive co-creation |
| End-to-end demo (button → story) | Working once | Video recording for appendix |
| Privacy benchmark data | Collected in Week 1 | Chapter 6 quantitative results |
| User survey data (parents) | Already collected | Chapter 3 methodology |

***

## The Distinction-Level Framing

The dissertation title-level claim should be:

*"SeeSaw demonstrates that a structurally privacy-preserving edge AI architecture can generate contextually relevant, interactive children's stories with zero PII transmission, at latencies comparable to cloud-dependent alternatives, with narrative quality ratings statistically indistinguishable from Gemini 2.0 Flash outputs."*

This is a falsifiable, testable claim supported by your benchmark. It is the kind of claim that earns distinction marks — not because the system is perfect, but because the claim is clear, the evidence is real, and the contribution is original.

***

## The One Thing That Would Prevent Distinction

The only thing that prevents a distinction grade at this stage is **submitting without the benchmark data**. A well-written, well-structured dissertation about a privacy-preserving system that never actually measures privacy quantitatively will plateau at merit. Two days of benchmark work is the difference between a merit and a distinction — that is the clearest cost-benefit calculation in the project.