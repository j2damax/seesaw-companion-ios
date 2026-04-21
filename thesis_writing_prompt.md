# MSc Thesis Completion Prompt — SeeSaw

> Parse this prompt to your writing agent to complete the dissertation.

---

## Context: What Has Been Read

The thesis document at https://docs.google.com/document/d/1trnVHX-scMv0lAuC5Kf0RAaTVpg2z-P2t17LIZG3Bb8/edit?usp=sharing has been reviewed. Current state:

| Chapter | Status |
|---------|--------|
| Ch.1 Introduction | ✅ Fully written — do not touch |
| Ch.2 Literature Review | ✅ Fully written — do not touch |
| Ch.3 Methodology | ✅ Fully written — do not touch |
| Ch.4 System Design & Architecture | ✅ Fully written — do not touch |
| Ch.5 Implementation | ✅ Fully written — **but see correction below** |
| **Ch.6 Evaluation and Results** | ❌ **EMPTY — single `[TO INCLUDE]` placeholder — write this entirely** |
| **Ch.7 Conclusion and Future Work** | ⚠️ Partially written — extend only, do not rephrase existing content |
| Appendix A (Branding) | ✅ Fully written — do not touch |
| Appendix B (Parent Survey) | ✅ Fully written — do not touch |

---

## The Iron Rule — No Artificial Content

**Every number, latency figure, percentage, model parameter count, and result you write must come verbatim from one of the source files listed in this prompt.**

If a source file does not contain sufficient detail:
- Write: `[DATA PENDING — source: <filename>]`
- Do NOT invent a plausible number
- Do NOT round or approximate measured values — use exact figures from source
- Do NOT add literature citations that are not already in the document

The dissertation will be examined. Fabricated evidence will fail it.

---

## Step 0 — Fix One Factual Error in Chapter 5 Before Writing Chapter 6

Chapter 5.1.4 in the current document contains incorrect mAP values. **Before writing Ch.6, correct these numbers in Ch.5.1.4 to match the verified values below.** Do not change any other content in Ch.5.

| Run | Current (wrong) | Correct value | Source |
|-----|----------------|--------------|--------|
| Run A — COCO baseline mAP@50 | 0.0147 | **0.0105** | `seesaw-yolo-model/docs/results_comparison.csv` |
| Run B — Layer 1 only mAP@50 | 0.8223 | **0.7010** | `seesaw-yolo-model/docs/results_comparison.csv` |
| Run C — All layers mAP@50 | 0.4972 | **0.6748** (44-class full eval) | `seesaw-yolo-model/docs/results_comparison.csv` |

Also correct in Ch.5.1.3 if present:
- Ultralytics version: correct to `8.4.33` (not 8.4.30)
- Training GPU: correct to `NVIDIA H100 80GB HBM3` (not T4 — T4 was used for Gemma fine-tuning, H100 for YOLO)

---

## Your Primary Task: Write Chapter 6 — Evaluation and Results

Chapter 6 is completely empty. Write it in full using ONLY the sources listed below. Match the writing style of the existing chapters — formal academic English, third person, same heading depth and paragraph length as Ch.5.

The chapter must cover these sections in order:

---

### 6.1 Evaluation Overview

Write a brief (1–2 paragraph) introduction to the chapter covering:
- What is being evaluated: privacy pipeline, story generation latency across 4 modes, YOLO object detection accuracy, hybrid routing behaviour, parent-rated narrative quality
- Evaluation was conducted on iPhone 15 Pro (A17 Pro Neural Engine, iOS 26 beta)
- Source: `submission.md` §2 (research questions answered by this chapter) and `Pipeline.md` §8

---

### 6.2 Privacy Pipeline Evaluation

**Sources to read:** `README.md` (test results table), `Pipeline.md` §8.1, `submission.md` §4

Write content covering:

**Privacy Invariant:**
- 100-run automated test: `rawDataTransmitted = false` in 100% of 100 runs — zero violations
- 130 unit tests, 0 failures (`SeeSawTests/` test suite)
- `PIIScrubber` coverage: 100%; `PrivacyMetricsStore` coverage: 100%; `ChunkBuffer` coverage: 100%
- 1 live PII event detected and redacted across 86 live sessions (from `Observations.md` entry OB-009)
- The privacy invariant is **structural** — enforced by the type system, not policy. `ScenePayload` is the only struct that crosses the device boundary; it contains label strings only, never pixels or audio.

**Pipeline Latency:**
- Source data: `[Google Drive]/step2/privacy_pipeline_raw.csv` (21 rows)
- Read the CSV and compute/report the actual measured values: mean, median, p95 for total pipeline latency and per-stage breakdown (faceDetectMs, blurMs, yoloMs, sceneClassifyMs, sttMs, piiScrubMs)
- All 21 rows had `rawDataTransmitted = false`
- Reference figure: `[Google Drive]/step12/charts/fig12_4_pipeline_stages.png`

---

### 6.3 Story Generation Latency — Four-Mode Comparison

**Sources to read:** `submission.md` §4, `Pipeline.md` §8.2, `Observations.md` OB-001 through OB-016, `[Google Drive]/step12/story_metrics_cloud.csv`, `step12/story_metrics_ondevice.csv`, `step12/story_metrics_gemma4.csv`, `step12/story_metrics_hybrid.csv`

Write content covering:

- Read each CSV and report exact mean/median `totalGenerationMs` per mode
- Mode A (Cloud — Gemini 2.0 Flash): ~4,205 ms mean — verify from CSV
- Mode B (On-device — Apple Foundation Models): ~7,102 ms mean — verify from CSV
- Mode C (On-device — Gemma 3 1B Q8_0): ~14,614 ms mean — verify from CSV
- Mode D (Hybrid): report from `step12/story_metrics_hybrid.csv`
- **Statistical test:** Kruskal-Wallis H = 52.75, p < 0.001 (non-parametric, distributions non-normal) — from `submission.md` §1
- Post-hoc Mann-Whitney U with Bonferroni correction: Apple FM vs Hybrid p = 0.59 (not significant); Gemma vs Hybrid p = 0.10 (not significant) — from `submission.md` §1
- Reference figure: `[Google Drive]/step12/charts/fig12_1_latency_boxplot.png`, `fig12_2_latency_bar.png`
- Note the trade-off: Mode A is fastest but requires network; Modes B and C transmit zero bytes

---

### 6.4 Architecture D — Hybrid Routing Analysis

**Sources to read:** `Pipeline.md` §5 (Architecture D design), `README.md` (88.9% cloud hit rate), `[Google Drive]/step8/hybrid_metrics.csv`, `submission.md` §4

Write content covering:

- Read `hybrid_metrics.csv` — 28 beats, columns: turn, source, local_ms, cloud_ms, cloud_arrived, ending_by
- Report: how many beats had `cloud_arrived = true` vs false (this is the cloud hit rate)
- Per-beat: local_ms (Gemma local generation time) vs cloud_ms (Cloud Run generation time)
- Key design detail: local model generates immediately; cloud enhancement races concurrently during the speak/listen window (8–15 s). A 50 ms polling deadline in `consumeEnhancedBeat()` decides whether cloud result is used.
- Sessions 1–2: `source = localGemma4` (cold start, cloud not yet ready); subsequent beats: `source = cloud`
- Reference figure: `[Google Drive]/step12/charts/fig12_9_roundtrip_latency.png`
- Note: Architecture D is the primary novel contribution — it achieves cloud-quality output at on-device response speed for all beats after the first

---

### 6.5 YOLO11n Object Detection Results

**Sources to read:** `seesaw-yolo-model/docs/results_comparison.csv`, `seesaw-yolo-model/notebooks/yolo_training.ipynb` (cell outputs), `[Google Drive]/step16/yolo_evidence.md`, `[Google Drive]/step16/model_card.md`

Write content covering the three-run comparative evaluation:

**Results table (use exact values):**

| Run | Description | mAP@50 | mAP@50-95 | Precision | Recall |
|-----|------------|--------|-----------|-----------|--------|
| Run A | COCO pretrained, no fine-tuning | 0.0105 | 0.0077 | 0.0208 | 0.0084 |
| Run B | Fine-tuned Layer 1 only (12 classes) | 0.7010 | 0.4913 | 0.7502 | 0.6088 |
| Run C | Fine-tuned all 3 layers (44 classes, 12-class benchmark) | 0.8490 | 0.6479 | 0.8241 | 0.7780 |
| Run C | Fine-tuned all 3 layers (full 44-class eval) | 0.6748 | — | — | — |

**Key findings to discuss:**
1. Run A near-zero mAP (0.0105) confirms COCO-pretrained YOLO is completely unsuitable for children's home environments — establishes the research gap
2. **Positive transfer finding (novel):** Run C outperforms Run B on the shared 12-class benchmark (+21% mAP@50: 0.849 vs 0.701; +28% recall: 0.778 vs 0.609) despite being trained on 44 classes. Layer 3 egocentric photographs improved generalisation on original classes.
3. Run C 44-class mAP (0.6748) is lower than 12-class benchmark because rare classes (chimney: 8 annotations, carpet: 31) drag the average
4. Class imbalance: potted_plant (5,247 annotations, most frequent) vs chimney (8, rarest)

**Figures to reference:**
- `seesaw-yolo-model/docs/dissertation_figures/confusion_matrix_run_b.png` (12×12)
- `seesaw-yolo-model/docs/dissertation_figures/confusion_matrix_run_c.png` (44×44)
- `seesaw-yolo-model/docs/dissertation_figures/results_run_c_training_curves.png`
- `seesaw-yolo-model/docs/dissertation_figures/val_predictions_run_c.jpg`
- `seesaw-yolo-model/docs/dissertation_figures/class_distribution.png`

**CoreML deployment:**
- 5.2 MB `.mlpackage`, ~8.1 ms total inference (1.4 ms preprocess + 5.8 ms inference + 0.9 ms postprocess)
- NMS baked into CoreML graph — no post-processing needed on device
- Critical engineering note: after export the CoreML spec contained hardcoded `nc=80` (COCO class count); notebook Cells 22–23 patched this to `nc=44` — document as a reproducibility note

---

### 6.6 Gemma 3 Fine-Tuning Results

**Sources to read:** `seesaw-cloud-agent/docs/THESIS_REFERENCE.md`, `seesaw-cloud-agent/training/finetune.ipynb` (saved cell outputs), `[Google Drive]/step16/cloud_agent_evidence.md`

Write content covering:

**Training results (from notebook cell outputs — exact values):**

| Epoch | Training Loss | Validation Loss |
|-------|--------------|-----------------|
| 1 | 0.5126 | 0.5115 |
| 2 | 0.4769 | 0.4960 |
| 3 | 0.4687 | **0.4945** (best) |

- Trainable parameters: 2,981,888 / 1,002,867,840 = **0.2973%**
- Dataset: 8,000 examples (7,200 train / 800 eval)
- Runtime: ~27 minutes on Vertex AI T4, cost ~$6 USD
- Best eval_loss 0.4945 — well below threshold of 1.5; train/val losses track closely (no overfitting)
- GGUF export: Q8_0, 1,077,509,216 bytes (1,028 MB) — Q4_K_M was attempted but rejected by MediaPipe 0.10.33 (K-quants unsupported); this is a notable engineering constraint worth documenting

---

### 6.7 Parent-Rated Narrative Quality

**Sources to read:** `[Google Drive]/step15/story_ratings.csv`, `submission.md` §4, `[Google Drive]/step16/api_cost_analysis.md`

Write content covering:

- Read `story_ratings.csv` — 5 sessions rated on Likert 1–5 scales
- Report exact mean scores for: enjoyment, age-appropriate, scene-grounding
- Note the limitation prominently: n=5 is below the 20-participant target planned in the evaluation framework (Ch.3.4); this is insufficient for statistical significance testing — results are indicative only, not confirmatory
- External rater story quality scoring (Step 13) is pending — note this explicitly: `[DATA PENDING — external rater story quality scores]`
- Cost comparison from `api_cost_analysis.md`: Mode A (cloud) ~$0.00022/session vs Modes B/C (on-device) $0.00/session

---

### 6.8 Chapter Summary

Write a 1-paragraph summary table and paragraph answering the four research questions with the evidence from this chapter. Use the RQ structure from `submission.md` §2:
- RQ1 (PII reduction): answered by privacy invariant results
- RQ2 (latency trade-offs): answered by four-mode comparison
- RQ3 (story quality equivalence): partial — parent ratings indicative, external rater pending
- RQ4 (minimum hardware): iPhone 12+ Neural Engine, iOS 26+, 3 GB free RAM for Gemma

---

## Chapter 7 — Conclusion and Future Work (extend only)

**Read the existing Ch.7 content first.** It currently contains some content about BLE/WiFi protocol comparison. Preserve all existing text.

**Then add the following sections if they are missing:**

**7.1 Summary of Contributions** — use exactly the three contributions from `SeeSaw-Project-Master.md` §4 and `submission.md` §10:
1. Custom YOLO11n-SeeSaw: 44-class domain-specific children's environment object detector
2. Privacy-preserving Apple Foundation Models bridging layer for child storytelling (first published implementation)
3. SeeSaw-Gemma-1B: fine-tuned open-weight edge LLM (Q8_0 GGUF, Vertex AI LoRA, on-device via MediaPipe)
4. Architecture D (Hybrid): dual-agent concurrent generation achieving cloud quality at on-device response time

**7.2 Limitations** — use exactly the list from `submission.md` §9. Do not add or invent new limitations.

**7.3 Future Work** — use exactly the items from `SeeSaw-Project-Master.md` §14. Do not invent new directions.

**7.4 Closing Statement** — one paragraph. Reference the thesis statement from Ch.1 and state which aspects were demonstrated and which remain pending (external rater).

---

## Repository Access

```
Repo 1 — iOS App:    github.com/j2damax/seesaw-companion-ios    branch: testflight-release
Repo 2 — YOLO:       github.com/j2damax/seesaw-yolo-model       branch: main
Repo 3 — Cloud:      github.com/j2damax/seesaw-cloud-agent      branch: main

Data (Google Drive):
https://drive.google.com/drive/folders/1BlDVn-gw1g5HQp5WQwx65OxhJU9glHmd?usp=sharing

Thesis document:
https://docs.google.com/document/d/1trnVHX-scMv0lAuC5Kf0RAaTVpg2z-P2t17LIZG3Bb8/edit?usp=sharing
```

## Reading Order

1. Read the full thesis document — understand the writing style, heading depth, and tone exactly
2. Read `seesaw-companion-ios/submission.md` — this is the master reference cross-linking all sources
3. Read `seesaw-companion-ios/Pipeline.md` §8 — pre-written empirical results section
4. Read `seesaw-companion-ios/Observations.md` — empirical log with all OB-NNN entries
5. Read `seesaw-yolo-model/docs/results_comparison.csv` — correct the Ch.5.1.4 numbers first
6. Read Google Drive CSVs as needed per section above
7. Write Ch.6 section by section; extend Ch.7 last

**Do not begin writing until you have completed steps 1–4.**
