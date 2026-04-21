# MSc Thesis Completion Prompt — SeeSaw

> Parse this prompt to your writing agent. It contains everything needed to complete the dissertation without fabricating any content.

---

## Your Task

Complete the in-progress MSc dissertation for the **SeeSaw** project. The thesis document is at:

**Google Docs:** https://docs.google.com/document/d/1trnVHX-scMv0lAuC5Kf0RAaTVpg2z-P2t17LIZG3Bb8/edit?usp=sharing

**Step 1 — read the entire current document first.** Identify every section that is:
- ✅ Already written — preserve exactly as-is, do not rephrase, restructure, or add to it
- ⬜ Empty / placeholder — complete using ONLY the source files listed below
- ⚠️ Partially written — extend only with facts from the source files; do not modify existing sentences

---

## The Iron Rule — No Artificial Content

**Every claim, number, latency figure, percentage, model parameter count, and qualitative statement you write must come from one of the source files listed in this prompt.**

If a source file does not contain the information needed to complete a section:
- Write: `[DATA PENDING — source: <filename>]` as a placeholder
- Do NOT invent a plausible-sounding number
- Do NOT generalise from related literature
- Do NOT round or approximate measured values — use the exact figures from the source

The dissertation will be examined. Fabricated evidence will fail it.

---

## Project Overview

**SeeSaw** is a privacy-preserving iOS app that transforms a child's real-world environment into AI-generated interactive stories. Raw pixels and audio never leave the device — only anonymous scene labels reach any LLM.

**Thesis statement:**
> *A structurally privacy-preserving edge AI architecture can generate contextually relevant, interactive children's stories with zero PII transmission, at latencies comparable to cloud-dependent alternatives, with narrative quality ratings statistically indistinguishable from cloud-generated outputs.*

**Three original research contributions:**
1. A custom YOLO11n model trained on children's indoor environments (44 classes, three-layer dataset)
2. A novel privacy-preserving bridging layer using Apple Foundation Models for child storytelling
3. A fine-tuned Gemma 3 1B on-device model (Q8_0 GGUF, 1,028 MB) for edge story generation

**Four story generation architectures evaluated:**
- Mode A — Cloud: Gemini 2.0 Flash via Cloud Run (network required)
- Mode B — On-device: Apple Foundation Models 3B (no network)
- Mode C — On-device: Gemma 3 1B Q8_0 via MediaPipe (no network)
- Mode D — Hybrid: Gemma/Apple FM first, cloud enrichment concurrent (Architecture D is the primary novel contribution)

---

## Three Repositories

All implementation details, measured results, and design decisions are documented in these repositories. Read the specified files — do not access the internet or external sources.

### Repository 1 — iOS App (primary)
**Path/URL:** `github.com/j2damax/seesaw-companion-ios`

| File | What it contains | Use for chapters |
|------|-----------------|-----------------|
| `SeeSaw-Project-Master.md` | Research motivation, RQs, contributions, architecture overview, null hypothesis, future work | Ch.1, Ch.2, Ch.3, Ch.7 |
| `submission.md` | Master reference: thesis statement, all measured data by section, statistical results, chart inventory, limitations, novel contributions checklist | ALL chapters |
| `Pipeline.md` | Full technical implementation of all 4 modes, six-stage privacy pipeline, VAD three-layer design, hybrid Architecture D, sequence diagrams, §8 Empirical Results | Ch.3, Ch.4, Ch.5, Ch.6 |
| `Observations.md` | Empirical research log — per-run latency data, story quality notes, anomalies, hybrid metrics, all OB-NNN entries | Ch.5, Ch.6 |
| `DEVELOPER_REFERENCE.md` | Architecture decisions, concurrency model, known limitations, test results | Ch.3, Ch.6 §limitations |
| `CODEBASE_BLUEPRINT.md` | Architecture diagrams, class relationships, full 44-class YOLO taxonomy | Ch.3 |
| `README.md` | Privacy invariant, test results summary (130 tests, 0 failures), architecture table | Ch.4, Ch.6 |
| `DATA_LOCATION.md` | Google Drive link and folder map for all CSV data files | Reference when citing data |
| `testflight.md` | TestFlight deployment, parent evaluation protocol | Ch.5 §evaluation design |

**Google Drive data folder** (referenced from DATA_LOCATION.md):
https://drive.google.com/drive/folders/1BlDVn-gw1g5HQp5WQwx65OxhJU9glHmd?usp=sharing

Key files in Google Drive:
- `step2/privacy_pipeline_raw.csv` — 21 rows, pipeline latency baseline
- `step12/story_metrics_cloud/ondevice/gemma4/hybrid.csv` — per-beat generation timing for all 4 modes
- `step8/hybrid_metrics.csv` — 28 hybrid beats: per-beat routing (source, local_ms, cloud_ms, cloud_arrived)
- `step15/story_ratings.csv` — 5 parent sessions: enjoyment, age-appropriate, scene-grounding (Likert 1–5)
- `step9/vad_console_logs.txt` — 58 VAD decisions
- `step3/pii-tests-output.txt` — 130 PII scrubber tests
- `step12/charts/*.png` — 9 statistical charts (Fig 12.1–12.9)
- `step16/yolo_evidence.md` — complete YOLO training evidence (dataset counts, Run A/B/C results, figures list)
- `step16/cloud_agent_evidence.md` — Gemma fine-tuning evidence (LoRA config, training metrics, GGUF export)
- `step16/model_card.md` — YOLO model card (performance, taxonomy, licences)
- `step16/api_cost_analysis.md` — cost comparison: on-device $0 vs cloud $0.00022/session
- `step16/dataset_licences.md` — dataset licence inventory with dissertation citation block
- `step16/github_evidence.md` — development timeline, commit counts, PR history

---

### Repository 2 — YOLO Model Training
**Path/URL:** `github.com/j2damax/seesaw-yolo-model`

| File | What it contains | Use for chapters |
|------|-----------------|-----------------|
| `docs/THESIS_REFERENCE.md` (if exists) | Verified facts for dissertation | Ch.4, Ch.5 |
| `notebooks/yolo_training.ipynb` | Full training pipeline with saved cell outputs — all Run A/B/C metrics are in cell outputs | Ch.4, Ch.5 |
| `docs/results_comparison.csv` | Run A mAP@50=0.0105, Run B=0.7010, Run C=0.6748 (44-class) / 0.8490 (12-class benchmark) | Ch.5 |
| `configs/seesaw_children.yaml` | 44-class taxonomy definition | Ch.4 |
| `scripts/data_merge.py` | 14-synonym normalisation mappings, 70/15/15 split implementation | Ch.4 |
| `docs/dissertation_figures/` | All 9 pre-generated figures (class_distribution.png, confusion_matrix_run_b/c.png, results_run_b/c_training_curves.png, val_predictions_run_b/c.jpg, labels_distribution_run_b/c.jpg) | Ch.4, Ch.5 figures |

**Key facts to use (verified from notebook cell outputs):**

*Dataset:*
- Layer 1: HomeObjects-3K, 2,689 images (augmented), 12 classes, 22,292 annotations
- Layer 2: seesaw-layer2 (Roboflow), 208 raw images → 354 exported (augmentation applied), 33 classes, 1,400 annotations
- Layer 3: seesaw-layer3 (Roboflow, original egocentric iPhone photos), 99 raw images → 240 exported, 5 classes, 175 annotations, avg 12.19 MP (4032×3024)
- Merged: datasets/seesaw_children/, 3,283 images total, 44 classes, ~18,700 annotations
- Split: Train 2,275 (70%) / Val 487 (15%) / Test 488 (15%), seed=42

*Training hardware:* NVIDIA H100 80GB HBM3 (Google Colab), CUDA 12.8, PyTorch 2.10.0, Ultralytics 8.4.33

*Training config (Runs B and C):* base=yolo11n.pt (COCO pretrained, 2.6M params), epochs=50, imgsz=640, batch=16, optimizer=AdamW, early_stopping_patience=20

*Results:*
- Run A (COCO baseline, no fine-tuning): mAP@50=0.0105, mAP@50-95=0.0077, Precision=0.0208, Recall=0.0084
- Run B (Layer 1 only, 12 classes): mAP@50=0.7010, mAP@50-95=0.4913, Precision=0.7502, Recall=0.6088
- Run C (all 3 layers, 44 classes, 12-class benchmark): mAP@50=0.8490, mAP@50-95=0.6479, Precision=0.8241, Recall=0.7780
- Run C (full 44-class eval on seesaw_children val set): mAP@50=0.6748

*CoreML export:* seesaw-yolo11n.mlpackage, 5.2 MB, 2,590,732 parameters, NMS baked in, FP32 stored / Neural Engine FP16 at runtime, inference ~8.1 ms total (1.4 preprocess + 5.8 inference + 0.9 postprocess), iOS 16+ minimum

*CoreML patch:* After export, CoreML spec contained hardcoded nc=80 (COCO class count). Notebook Cells 22–23 patch the pipeline spec to nc=44. Document this as a reproducibility note.

---

### Repository 3 — Cloud Agent + Gemma Fine-Tuning
**Path/URL:** `github.com/j2damax/seesaw-cloud-agent`

| File | What it contains | Use for chapters |
|------|-----------------|-----------------|
| `docs/THESIS_REFERENCE.md` | Verified cite-ready facts: cloud deployment, fine-tuning run, privacy contract, comparative evaluation design | Ch.3, Ch.4, Ch.5, Ch.6 |
| `docs/FINE_TUNING.md` | Complete Gemma fine-tuning guide: dataset construction, LoRA config, training hyperparameters, GGUF export engineering challenges | Ch.4 |
| `docs/ARCHITECTURE.md` | Cloud backend architecture: FastAPI, Firestore, Cloud Run, ADK 0.2.0 | Ch.3 |
| `docs/API_REFERENCE.md` | Endpoint contracts: /story/generate, /story/enhance, /model/latest, /health | Ch.3 |
| `docs/DEPLOYMENT.md` | Cloud Run deployment record: region, revisions, configuration | Ch.3 |
| `docs/PRIVACY_CONTRACT.md` | Formal privacy spec: what crosses boundary, what never crosses, auditability | Ch.4 |
| `training/finetune.ipynb` | LoRA fine-tuning notebook with SAVED cell outputs (trainable params, train/eval loss per epoch, checkpoint upload) | Ch.4 |
| `training/export_gguf.ipynb` | GGUF export notebook with SAVED cell outputs (Q8_0 quantisation, file size 1,077,509,216 bytes, validation metadata) | Ch.4 |
| `training/data_prep.ipynb` | Dataset preparation notebook (TinyStories sampling, SeeSaw beats export, safety filter) | Ch.4 |
| `docs/seesaw_training_all.jsonl` | Sample training examples in Gemma chat template format | Ch.4 (for format illustration) |

**Key facts to use (verified from notebook cell outputs):**

*Fine-tuning:*
- Base model: google/gemma-3-1b-it (1B parameters, 32,768 token context)
- Method: LoRA, r=16, α=32, target modules: q_proj/k_proj/v_proj/o_proj, dropout=0.05
- Trainable parameters: 2,981,888 / 1,002,867,840 = 0.2973%
- Dataset: 8,000 examples (7,200 train / 800 eval) — TinyStories + SeeSaw beat exports
- Hardware: Vertex AI T4 GPU, runtime ~27 minutes, cost ~$6 USD
- Epochs: 3, batch=4, grad_accum=4 (effective=16), lr=2e-4 cosine with 5% warmup
- Training loss: epoch 1=0.5126, epoch 2=0.4769, epoch 3=0.4687
- Validation loss: epoch 1=0.5115, epoch 2=0.4960, epoch 3=0.4945 (best)

*GGUF export:*
- Quantisation: Q8_0 (NOT Q4_K_M — K-quants are unsupported in MediaPipe Tasks GenAI 0.10.33; Q4_K_M was rejected at load time)
- File: seesaw-gemma3-1b-q8_0.gguf
- Size: 1,077,509,216 bytes (1,028 MB)
- Architecture (GGUF metadata): gemma3, context=32,768, all metadata checks passed
- GCS location: gs://seesaw-models/seesaw-gemma3-1b-q8_0.gguf
- Tool: llama.cpp b8797, two Gemma 3 patches applied (vocab assertion, BPE pre-tokeniser hash)

*Cloud deployment:*
- Service URL: https://seesaw-cloud-agent-531853173205.europe-west1.run.app
- Region: europe-west1 (EU data residency, GDPR compliant)
- Framework: FastAPI 0.115 + Google ADK 0.2.0 + Gemini 2.0 Flash
- Container: Python 3.12-slim, 1 Gi RAM, min-instances=0, max-instances=3
- Persistence: Firestore (Native mode, europe-west2), 30-day TTL
- Cold start: ~25–35s; warm: ~1.5–3s
- Total dissertation spend: $0.21 (Gemini API only; Cloud Run + Storage = $0.00 free tier)

---

## Chapter-by-Chapter Source Map

Use this to know exactly which files to read before writing each chapter section.

### Chapter 1 — Introduction
*Sources:* `SeeSaw-Project-Master.md` §1–3, `submission.md` §1–2, `README.md`
- Motivation: the child AI privacy problem, raw data streaming in competitor apps
- Technology convergence: on-device LLMs (2024–2026), edge vision, regulatory pressure (COPPA, GDPR, EU AI Act)
- Gap in literature: no prior work combines multimodal scene understanding + on-device LLM + structural privacy in a child-facing deployed app
- Research questions (4 RQs from `submission.md` §2)
- Thesis structure overview
- **Do not modify anything already written**

### Chapter 2 — Literature Review
*Sources:* `SeeSaw-Project-Master.md` §2, `submission.md` §8 (literature references)
- Review only what is cited in these files; do not add external citations not already listed
- If a subsection is empty and no source covers it, write `[DATA PENDING]`

### Chapter 3 — System Design and Architecture
*Sources:* `Pipeline.md` §1–7, `CODEBASE_BLUEPRINT.md`, `DEVELOPER_REFERENCE.md`, `seesaw-cloud-agent/docs/ARCHITECTURE.md`, `seesaw-cloud-agent/docs/API_REFERENCE.md`
- Six-stage privacy pipeline (face detection → blur → YOLO → scene classify → STT → PII scrub → ScenePayload)
- Four architectures A–D with architecture table from README.md
- ScenePayload as the privacy boundary (what it contains, what never crosses)
- Actor-based concurrency model
- Architecture D (hybrid) dual-agent design — local generates immediately, cloud enriches concurrently
- Cloud backend stack from cloud-agent/docs/ARCHITECTURE.md
- **Cite exact class/file names** (e.g., `PrivacyPipelineService.swift`, `OnDeviceStoryService.swift`, `Gemma4StoryService.swift`) as implementation evidence

### Chapter 4 — Dataset Construction and Model Fine-Tuning
*Sources:* `seesaw-yolo-model` notebooks + `docs/`, `seesaw-cloud-agent/docs/FINE_TUNING.md`, `seesaw-cloud-agent/training/*.ipynb` outputs, `step16/yolo_evidence.md` (Google Drive), `step16/cloud_agent_evidence.md` (Google Drive), `step16/dataset_licences.md` (Google Drive)

**§4.1 YOLO Dataset Construction:**
- Three-layer strategy: use exact image/annotation counts from "Key facts" above
- Distinguish raw counts (208/99 — from Roboflow analytics) from augmented exported counts (354/240 — used in training)
- Train/val/test split: 2,275/487/488 (70/15/15, seed=42)
- Synonym normalisation: 14 mappings, handled by `scripts/data_merge.py`
- Layer 3 significance: only egocentric (child's eye-level) photographs in dataset, avg 12.19 MP vs 0.33 MP for Layer 2
- Dataset licences from `step16/dataset_licences.md`

**§4.2 YOLO Training:**
- Hardware and configuration from "Key facts" above
- Three-run comparative design (Run A baseline, Run B Layer 1, Run C all layers)
- CoreML export process including nc=80→nc=44 patch

**§4.3 Gemma 3 Fine-Tuning:**
- Dataset construction: TinyStories + SeeSaw beat exports, safety filter (BANNED_TERMS list from FINE_TUNING.md)
- Training format: Gemma chat template, JSON-in-text output format
- LoRA configuration and all hyperparameters from "Key facts" above
- Training results (loss table) from notebook cell outputs
- GGUF export: emphasise Q8_0 (not Q4_K_M), explain why (MediaPipe 0.10.33 K-quant incompatibility)
- Engineering challenges: two llama.cpp patches (vocab assertion, BPE hash) from FINE_TUNING.md §Key implementation notes

### Chapter 5 — Privacy Pipeline Evaluation
*Sources:* `Pipeline.md` §8 Empirical Results, `submission.md` §4–5, `Observations.md`, `README.md` (test results table), `step2/privacy_pipeline_raw.csv`, `step3/pii-tests-output.txt`

**§5.1 Privacy Invariant Verification:**
- 100-run automated test: rawDataTransmitted=false in 100% of runs
- 130 unit tests, 0 failures
- PII scrubber: 100% branch coverage
- Live PII event: 1 name detected and redacted in 86 live sessions (OB-009 from Observations.md)

**§5.2 Pipeline Latency:**
- Use exact figures from `step2/privacy_pipeline_raw.csv` and `Pipeline.md` §8.1
- Median total pipeline: 61 ms, p95: 154 ms (if in source — else note source file)
- Per-stage breakdown: face detection, blur, YOLO, scene classify, STT, PII scrub
- All 21 rows: rawDataTransmitted=false (privacy invariant held)

**§5.3 Statistical Analysis of Pipeline:**
- Use results from `submission.md` §5 exactly as documented

### Chapter 6 — Story Generation Evaluation and Results
*Sources:* `submission.md` §4–6, `Pipeline.md` §8, `Observations.md` OB-001 through OB-016, `step12/story_metrics_*.csv`, `step8/hybrid_metrics.csv`, `step15/story_ratings.csv`, `step12/charts/*.png`

**§6.1 Evaluation Design:**
- Four modes A–D, session counts per mode from submission.md
- Metrics: timeToFirstTokenMs, totalGenerationMs, guardrailViolations, storyTextLength, rawDataTransmitted

**§6.2 Generation Latency by Mode:**
- Use exact mean/median values from `step12/story_metrics_*.csv`
- Cloud (Mode A): mean ~4,205 ms; Apple FM (Mode B): mean ~7,102 ms; Gemma (Mode C): mean ~14,614 ms; Hybrid (Mode D): from submission.md
- Statistical test: Kruskal-Wallis H=52.75, p<0.001 (from submission.md §1)
- Post-hoc Mann-Whitney U with Bonferroni correction (from submission.md §1)

**§6.3 Hybrid Architecture D — Beat Routing:**
- 28 beats from `step8/hybrid_metrics.csv`
- cloud_arrived=true rate (cloud hit rate), local_ms vs cloud_ms comparison
- Architecture D observation: 88.9% cloud hit rate observed on device (from README.md)
- Explain the 50ms polling deadline design (from Pipeline.md)

**§6.4 YOLO Object Detection Results:**
- Three-run comparison table (Run A/B/C) — all values from "Key facts" above
- Key finding: positive transfer — Run C outperforms Run B on shared 12-class benchmark (+21% mAP@50, +28% recall)
- Run A significance: near-zero mAP confirms COCO pretrained model unsuitable for children's environments
- Reference figures: confusion_matrix_run_c.png, results_run_c_training_curves.png, val_predictions_run_c.jpg

**§6.5 Parent Ratings:**
- Source: `step15/story_ratings.csv`
- 5 sessions rated; enjoyment 4.0/5, age-appropriate 3.6/5, scene-grounding 4.0/5 (verify exact values from CSV)
- Note the limitation: n=5 is insufficient for statistical significance — acknowledge in limitations section

**§6.6 VAD Layer Analysis:**
- Source: `step9/vad_console_logs.txt`, 58 VAD decisions
- Three-layer VAD: heuristic (<1 ms) → Apple FM semantic (~150 ms) → hard cap (8 s)
- L2 (semantic VAD) fired rate from log analysis

**§6.7 Memory Footprint:**
- Gemma model: ~8.2 GB peak RAM during story generation (from submission.md / Observations.md)
- Cloud mode: ~180 MB (no local model)
- Apple FM: Neural Engine allocation (from source files)

### Chapter 7 — Discussion and Conclusion
*Sources:* `SeeSaw-Project-Master.md` §4 (contributions), §14 (future work), `submission.md` §9 (limitations), §10 (novel contributions checklist)

**§7.1 Research Questions Answered:**
- Go through each RQ from submission.md §2 and state the finding, citing the evidence chapter

**§7.2 Novel Contributions:**
- Use exactly the three contributions listed in submission.md §10 / SeeSaw-Project-Master.md §4
- Do not add or reframe contributions

**§7.3 Limitations:**
- Use exactly the limitations listed in submission.md §9
- Include: n=5 parent ratings insufficient for H₀, Gemma RAM constraint (3 GB), external rater scoring pending, iOS 26 minimum requirement

**§7.4 Future Work:**
- Use exactly the items from `SeeSaw-Project-Master.md` §14
- Do not invent additional future directions

---

## Style Instructions

1. **Maintain the existing voice** — read the written chapters first and match the tone, sentence length, and formality level exactly
2. **Cite source files as evidence** — when writing "the pipeline achieved X ms latency", add a footnote or inline reference like "(measured, `step2/privacy_pipeline_raw.csv`)"
3. **Use first-person-plural sparingly** — the existing text likely uses "the system", "the architecture", "this study"
4. **Technical terminology** — use exact class names (`PrivacyPipelineService`, `ScenePayload`, `StoryBeat`, `@Generable`) as they appear in the source files
5. **Tables and figures** — insert figure references using the filenames from `step12/charts/` and `seesaw-yolo-model/docs/dissertation_figures/`; do not describe figures you have not seen
6. **Word count** — do not pad to hit a word count; write only what the source material supports

---

## What to Do If a Section Cannot Be Completed

If a source file is missing, unreadable, or does not contain sufficient detail for a section:
1. Write the section heading
2. Write: `[INCOMPLETE — requires: <list what is missing> — source: <filename>]`
3. Move on — do not fill the gap with assumptions

Known pending items at time of writing:
- **Step 13 external rater scores** — `step13/story_scoring_sheet.md` contains extracted story beats but awaits external rater. Write the evaluation methodology; leave the results table as `[DATA PENDING — external rater]`
- **TestFlight / App Store Connect screenshots** — pending Beta App Review approval
- **Cloud Run service overview screenshot** — one screenshot outstanding

---

## Repository Access Summary

```
Repo 1 (iOS):      github.com/j2damax/seesaw-companion-ios     branch: testflight-release
Repo 2 (YOLO):     github.com/j2damax/seesaw-yolo-model        branch: main
Repo 3 (Cloud):    github.com/j2damax/seesaw-cloud-agent       branch: main
Data (Google Drive): https://drive.google.com/drive/folders/1BlDVn-gw1g5HQp5WQwx65OxhJU9glHmd?usp=sharing
Thesis document:   https://docs.google.com/document/d/1trnVHX-scMv0lAuC5Kf0RAaTVpg2z-P2t17LIZG3Bb8/edit?usp=sharing
```

Start by reading the thesis document. Then read `submission.md` from Repo 1 — it is the master reference and cross-links to every other source. Do not write a single word until you have read both.
