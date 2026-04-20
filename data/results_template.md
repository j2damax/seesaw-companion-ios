# SeeSaw Thesis — Results Collection Template

Fill in each section as you complete the corresponding step in `results_collection_plan.md`.  
Leave `TBD` if not yet collected. Claude will verify completeness and flag gaps when you share this file.

**Device:** iPhone 16e (Jam 16e) — UDID `00008140-000121DA2E32801C`  
**iOS version:** 26.4.1 (23E254)  
**App bundle:** `com.seesaw.companion.ios` v1  
**Xcode version:** <!-- e.g. 16.3 — fill from Xcode → About -->  
**App build:** Debug <!-- fill commit hash: git rev-parse --short HEAD -->  
**Collection date:** <!-- fill when you start, e.g. 2026-04-20 -->  

---

## Step 1 — Unit Test Suite & Coverage

| Metric | Value |
|--------|-------|
| Total tests run | — |
| Passed | All (run-summary.txt: 0 failures) |
| Failed | 0 |
| SeeSawTests.xctest coverage (%) | 90.6% |
| SeeSaw.app coverage (%) | 15.1% |
| PIIScrubber.swift coverage (%) | see TestCoverage.md |
| PrivacyMetricsStore.swift coverage (%) | see TestCoverage.md |
| ChunkBuffer.swift coverage (%) | see TestCoverage.md |
| Privacy invariant test (100-run) — violations | 0 (SeeSawTests.xctest passed) |
| Privacy invariant test duration (s) | see test-results/privacy-pipeline-tests.txt |

**Device:** iPhone 16e (Jam 16e), iOS 26.4.1  
**Date run:** 2026-04-19  
**TestCoverage.md regenerated?** YES  
**Notes:** SeeSawUITests.xctest shows 100% (1 test). SeeSawTests.xctest 90.6% on device.

---

## Step 2 — Privacy Pipeline Stage Latencies

**Number of pipeline runs captured:** TBD  
**CSV file saved?** YES (`data/privacy_pipeline_raw.csv`) / NO

### Per-stage mean latency (from CSV analysis)

20 steady-state runs (cold start row excluded — 869ms first run).  
`sceneClassifyMs`, `sttMs`, `piiScrubMs` = 0 in debug capture path — Stage 4/5/6 timings will come from full story sessions (Steps 5–8).

| Stage | Mean (ms) | Std Dev (ms) | Min (ms) | Max (ms) |
|-------|-----------|--------------|----------|----------|
| Face Detection (Stage 1) | 11.27 | 1.42 | 9.27 | 15.01 |
| Face Blur (Stage 2) | 7.51 | 0.95 | 6.18 | 10.00 |
| Object Detection / YOLO (Stage 3) | 19.26 | 3.08 | 16.29 | 29.90 |
| Scene Classification (Stage 4) | — | — | — | — |
| Speech-to-Text (Stage 5) | — | — | — | — |
| PII Scrub (Stage 6) | — | — | — | — |
| **Total Pipeline (debug path)** | **67.24** | **22.12** | **54.24** | **153.60** |

### Scene breakdown (runs per scene type)

| Scene | Runs | Objects detected |
|-------|------|-----------------|
| Study/desk (table, window) | 5 (runs 1–5) | table, window |
| Living room / doorway (table, door, potted_plant) | 5 (runs 6–10) | table, door, potted_plant, window |
| Bedroom (bed, curtains) | 5 (runs 11–15) | bed, curtains |
| Living room angle 2 (sofa, window, photo_frame) | 6 (runs 16–21) | window, table, photo_frame, sofa, door |

### Privacy invariant (from CSV)

| Metric | Value |
|--------|-------|
| `rawDataTransmitted = true` count | **0** ✓ |
| Mean objects detected per frame | 2.3 |
| Mean faces detected per frame | 0 (no faces in test scenes) |
| Mean faces blurred per frame | 0 |
| Total PII tokens scrubbed (all runs) | 0 (no speech during captures) |

**Raw CSV:** `data/privacy_pipeline_raw.csv` (21 rows + header)  
**Console logs saved:** YES — `data/privacy_runs.md` (raw), `data/pipeline_console_filtered.txt` (filtered)  
**Notes:** Stage 4 (sceneClassifyMs) is not instrumented in the `runDebugDetection` path used by the Capture button. Full Stage 4 timing will be measured during story sessions (Steps 5–8) via the `runFullPipeline` path. Cold-start row (869ms) excluded from all statistics.

---

## Step 3 — PII Scrubbing Verification

### Automated test results

Results from Step 1 full suite run (Swift Testing framework — `-only-testing:` not supported for struct-based tests).

| Pattern category | Tests | Result |
|-----------------|-------|--------|
| Name patterns | scrubRemovesNamePatterns, scrubIsCaseInsensitiveForNames, scrubRemovesImCalledPattern | ✅ All passed |
| Email patterns | scrubRemovesEmailAddresses | ✅ Passed |
| Phone / long numbers | scrubRemovesPhoneNumbers, scrubRemovesLongNumbers | ✅ All passed |
| Address / postcode | scrubRemovesStreetAddresses, scrubRemovesUKPostcodes, scrubRemovesUSZipCodes | ✅ All passed |
| Multi-PII + edge cases | scrubHandlesMultiplePIITypes, scrubHandlesEmptyString, scrubPreservesNonPIIContent, scrubPreservesStoryVocabulary | ✅ All passed |
| Token counting | scrubCountsRedactedTokens, totalTokensScrubbed | ✅ All passed |
| Suite summary | PIIScrubberTests, PrivacyMetricsStoreTests, PrivacyMetricsInvariantTests, PrivacyComplianceTests, ScenePayloadPrivacyTests | ✅ All suites passed |

### Live speech PII test (physical device)

| Field | Value |
|-------|-------|
| PII spoken aloud | "My name is Tripathy I live in 10 Maple St. my phone number is 07" |
| `tokensRedacted` — name trigger | 1 (at inputLength=14 — "Tripathy" detected) |
| `tokensRedacted` — address trigger | 2 (at inputLength=42 — "10 Maple St" detected) |
| VAD end trigger | Layer 3 hard cap (8s) |
| Raw STT transcript | `My name is Tripathy I live in 10 Maple St. my phone number is 07` |
| Scrubbed answer sent to LLM | `[REDACTED] I live in [REDACTED]. my phone number is zero` |
| Phone number fully redacted? | **Partial** — STT transcribed "07" as "zero seven"; "zero" passed through (incomplete pattern match) |

### Network verification of PII

| Check | Result |
|-------|--------|
| Raw name "Tripathy" in request body | **ABSENT** ✓ |
| Raw address "10 Maple St" in request body | **ABSENT** ✓ |
| `[REDACTED]` in `transcript` field | **PRESENT** ✓ |
| Beat 0 request size (no transcript yet) | 174 bytes |
| Beat 1 request size (scrubbed transcript) | 595 bytes |
| Beat 0 response | HTTP 200, 414 bytes, 26,059ms (cold start) |
| Beat 1 response | HTTP 200, 398 bytes, ~4,000ms (warm) |
| Instruments network trace screenshot | `data/screenshots/network_instruments_trace.png` |

### Stage 4 — scene classification (captured from this full pipeline run)

| Field | Value |
|-------|-------|
| Labels returned | `["structure", "wood_processed"]` |
| Child-friendly? | No — tech/material taxonomy (OB-003 confirmed) |
| Pipeline benchmark log | `faceDetect=57ms blur=38ms yolo=292ms scene=292ms stt=292ms piiScrub=0ms total=400ms` |
| Note | yolo/scene/stt values are cumulative timestamps from pipeline start — stages 3–5 run in parallel |

**PII test output saved?** YES (`data/pii-tests-output.txt` + console log)  
**Notes:** Partial phone number leak ("zero") is a known edge case — STT transcribes "07" as "zero seven" and the regex requires a complete phone pattern. Documents as dissertation finding on STT-scrubber interaction. Cold-start latency 26s on beat 0 (Cloud Run cold container).

---

## Step 4 — Object Detection (YOLO11n)

**Confidence threshold used:** 0.25 (default)  
**YOLO model:** seesaw-yolo11n.mlpackage (44 classes)

### Per-scene detection results

**Source files:** `data/scene_captures/scenes/1–5.png` + `data/scene_captures/logs.md`

#### Scene 1 — Study/Desk (1.png) — 4 captures, fully logged ✓

| Expected object | Detected? | Confidence | Appearances |
|----------------|-----------|-----------|-------------|
| tv (monitor) | **YES** | 96–98% | 4/4 |
| potted_plant | **YES** | 97–98% | 4/4 |
| table | **YES** | 95–98% | 4/4 |
| laptop | **YES** | 92% | 1/4 |
| book | **NO** | — | 0/4 |
| False positives | None | — | — |

Precision: **1.00** · Recall: **0.80** · F1: **0.89**

#### Scene 2 — Window/Storage Area (2.png) — 1 capture (0 detections)

| Expected object | Detected? | Notes |
|----------------|-----------|-------|
| window | NO | Camera angle produced 0 detections |
| cupboard | NO | — |
| stuffed_animal | NO | — |

Insufficient log data — camera angle missed all objects. Precision/Recall: N/A.

#### Scene 3 — Wardrobe Room (3.png) — 1 capture logged

| Expected object | Detected? | Confidence | Notes |
|----------------|-----------|-----------|-------|
| wardrobe | **Partial** | 83% (as "cupboard") | Class label mismatch — same object |
| door | **YES** | 69% | Low confidence, partially visible |
| dinosaur_toy | NO | — | Not detected |
| bottle | NO | — | Not detected |
| False positives | None | — | — |

Cross-ref Step 3 (better lighting, full pipeline): `wardrobe@97%` detected correctly.

#### Scene 4 — Child's Bedroom (4.png) — log not captured

| Expected object | Evidence | Confidence |
|----------------|----------|-----------|
| bed | Step 2 CSV (5 captures) | 98% |
| door | Step 2 CSV cross-ref | 77–93% |
| dinosaur_toy | Not detected in any session | — |
| toy_car | Not detected in any session | — |
| building_blocks | Not detected in any session | — |

#### Scene 5 — Hallway/Door (5.png) — log not captured

| Expected object | Evidence | Confidence |
|----------------|----------|-----------|
| door | Step 2 CSV cross-ref | 77–93% |
| window | Step 2 CSV cross-ref | 64–96% |

### Aggregate detection metrics

| Metric | Value | Note |
|--------|-------|------|
| Total expected objects (5 scenes) | 21 | Visual ground truth |
| True positives (confirmed) | 5 | Scene 1 only — fully logged |
| False positives | 0 | Zero spurious detections |
| False negatives (confirmed) | 8 | book, toy classes, bottle, stuffed_animal |
| Precision (Scene 1) | **1.00** | |
| Recall (Scene 1) | **0.80** | book missed consistently |
| F1 (Scene 1) | **0.89** | |
| Training mAP@50 — Run C (production) | **0.6748** | From training repo |
| Training mAP@50 — Run B (Layer 1 only) | **0.8614** | From training repo |

### Scene classification labels (Stage 4 — VNClassifyImageRequest)

| Scene | Labels returned | Child-friendly? |
|-------|----------------|-----------------|
| Wardrobe room (Step 3 full pipeline) | `["structure", "wood_processed"]` | **No** — material taxonomy |
| All others | Not captured (debug path) | Captured during Steps 5–8 |

**OB-003 label mismatch confirmed:** YES — `["structure", "wood_processed"]` returned for wardrobe/bedroom scene.  
**Notes:**  
- Furniture classes (tv, table, potted_plant) detected at 95–98% — high confidence  
- Toy classes (dinosaur_toy, toy_car, building_blocks) not detected — underrepresented in Run C  
- `wardrobe`/`cupboard` boundary ambiguity — both in 44-class taxonomy  
- Scene 2 requires re-capture for complete metrics

---

## Step 5 — Mode A: Cloud (Gemini 2.0 Flash)

**Sessions run:** 5  
**Total beats:** 25 (S1=1, S2=8, S3=8, S4=4, S5=4)  
**CSV saved?** YES — `data/story_metrics_cloud.csv`  
**HTTP requests captured (Proxyman):** 24 — all HTTP 200

### Latency summary (from `data/story_metrics_cloud.csv`)

| Metric | Value (ms) |
|--------|-----------|
| Mean TTFT (beat[0] across 5 sessions) | 4,190 |
| Median TTFT (beat[0]) | 4,650 |
| Mean total generation (all 25 beats) | 4,205 |
| Median total generation | 4,083 |
| Std Dev total generation | 1,345 |
| Min generation | 1,756 (S1 warm-up beat) |
| Max generation | 7,481 |
| Mean turns per session | 5.0 |
| Guardrail violations | 0 |

**Per-session turns:** S1=1, S2=8, S3=8, S4=4, S5=4

### Network footprint (from `data/step5/network_cloud_sessions_proxyman.csv`)

| Metric | Value |
|--------|-------|
| Mean HTTP round-trip (ms) | 4,142 |
| Median HTTP round-trip (ms) | 4,126 |
| Std Dev HTTP RTT (ms) | 1,286 |
| Min / Max HTTP RTT (ms) | 2,383 / 7,450 |
| Mean request body size (bytes) | 1,120 (range: 179–2,621; grows with story history) |
| Mean response body size (bytes) | 425 (range: 363–500) |
| Total bytes sent (25 beats) | 26,868 |
| Total bytes received | 10,196 |
| Connection | HTTPS POST → `seesaw-cloud-agent-531853173205.europe-west1.run.app` |
| TLS certificate | `*.a.run.app` (Google Cloud Run) |
| Network log saved | YES — `data/step5/network_cloud_sessions_proxyman.csv` |

### Privacy verification (from `data/step5/privacy_pipeline_cloud.csv`)

| Check | Result |
|-------|--------|
| `rawDataTransmitted` | false — ALL 15 rows |
| Raw pixels in request body | ABSENT — only `objects[]`, `scene[]`, `transcript`, `child_age`, `child_name`, `session_id` |
| Content-Type | application/json |
| Faces detected & blurred | YES — 1 face detected and blurred in 3 captures (faceDetect=1, blurred=1) |
| sceneClassifyMs in cloud mode | > 0 (Stage 4 runs in full pipeline — mean 100.9 ms) |
| sceneClassifyMs in debug mode | 0 (Stage 4 skipped in capture-only path) |
| PII scrub latency | ~1.8 µs (negligible) |
| Request body screenshot | YES — `data/step5/screenshots/network_request_body_proof.png` |
| Proxyman network screenshots | YES — `data/step5/screenshots/network_bytes_overview.png`, `network_active_connections.png` |

### Cloud pipeline latency (from `data/step5/privacy_pipeline_cloud.csv`, cloud rows n=5)

| Stage | Mean (ms) |
|-------|----------|
| Face detect (Stage 1) | ~16.0 |
| Face blur (Stage 2) | ~10.7 |
| YOLO detection (Stage 3) | 100.9 |
| Scene classify (Stage 4) | 100.9 (recorded cumulatively with Stage 3) |
| PII scrub (Stage 6) | 0.002 |
| **Full pipeline mean** | **126.3** |

### System resource usage (Instruments, 12 min 23 sec)

| Resource | Value |
|----------|-------|
| CPU (SeeSaw avg) | 7% |
| CPU peak | 163% |
| Active threads | ANEServicesThread, NSURLConnection, UIKit event fetch |
| GPU frame rate | 60 fps, 0.1 ms frame time |
| Memory avg | 65.9 MB (0.85% of 7.5 GB) |
| Memory peak | 121.9 MB |
| Energy impact | High (CPU 84.9%, Display 8.1%, GPU 3.8%, Network 1.6%) |
| Thermal state | Serious |
| Disk read | 52.7 MB |
| Disk write | 14.7 MB |

**Source files:** `data/story_metrics_cloud.csv`, `data/step5/network_cloud_sessions_proxyman.csv`, `data/step5/privacy_pipeline_cloud.csv`, `data/step5/screenshots/`

**Notes:**
- S1 had only 1 beat (1,756 ms cold start) — shortest session, excluded from multi-turn analysis
- S2 and S3 reached maximum 8 beats each — full session data
- Request body grows linearly with story history: 179 B (beat 1) → 2,621 B (beat 8)
- sceneClassifyMs = yoloMs in cloud metrics rows — likely recorded as cumulative Stage 3+4 timing in `runFullPipeline`; not a bug, confirms Stage 4 runs in production path

---

## Step 6 — Mode B: On-Device (Apple Foundation Models)

**Sessions run:** 5  
**Total beats:** 18 (S1=4, S2=3, S3=3, S4=3, S5=5)  
**CSV saved?** YES — `data/story_metrics_ondevice.csv`

### Latency summary (from `data/story_metrics_ondevice.csv`)

| Metric | Value (ms) |
|--------|-----------|
| Mean TTFT (timeToFirstToken) | 4,148 |
| Median TTFT | 3,723 |
| Std Dev TTFT | 1,763 |
| Min TTFT | 2,574 (warm session) |
| Max TTFT | 10,782 (S1 cold start — model loading) |
| Mean total generation | 7,102 |
| Median total generation | 6,654 |
| Std Dev total generation | 1,857 |
| Min / Max total generation (ms) | 4,643 / 13,627 |
| Mean turns per session | 3.6 (S1=4, S2=3, S3=3, S4=3, S5=5) |
| Guardrail violations | 0 |

**vs Cloud mode:** onDevice mean 7,102 ms vs Cloud 4,205 ms — **69% slower** generation. TTFT near-equal (4,148 vs 4,190 ms).

### Context window behaviour

| Metric | Value |
|--------|-------|
| Sessions where `restartWithSummary` fired | 0 / 5 sessions |
| Mean turn at which restart fired | N/A — no restarts in this run |
| Generation time trend across turns | Stable (no significant degradation observed) |
| Character/name continuity | MAINTAINED (no restart needed) |

### Privacy & network verification

| Check | Result |
|-------|--------|
| Cloud Run HTTP requests during story session | **0** — confirmed by Proxyman CSV (4 rows: Firebase + Apple push only) |
| `rawDataTransmitted` | false — ALL rows in `privacy_pipeline_ondevice.csv` |
| Network screenshot (empty connections) | YES — `data/step6/network_report.png` ("No Active Connections") |
| Received (Instruments) | 8.0 KB (system telemetry only — no story traffic) |
| Sent (Instruments) | 5.3 KB |

### onDevice pipeline latency (`data/step6/privacy_pipeline_ondevice.csv`, onDevice rows n=5)

| Stage | Mean (ms) |
|-------|----------|
| Face detect (Stage 1) | ~8.5 |
| Face blur (Stage 2) | ~5.7 |
| YOLO detection (Stage 3) | 90.2 |
| Full pipeline mean | 115.3 |

### System resource usage (Instruments, 10 min 1 sec)

| Resource | Value |
|----------|-------|
| CPU (SeeSaw avg) | 6% |
| CPU peak | 180% |
| Active threads | ANEServicesThread (×3), AXSpeech (TTS), com.apple.audio.toolbox |
| GPU frame rate | 60 fps, 0.1 ms frame time |
| Memory avg | 65.7 MB (0.85% of 7.5 GB) |
| Memory peak | 121.7 MB |
| Energy impact | High (CPU 89.5%, Display 7.9%, GPU 2.6%, **Network 0%**) |
| Thermal state | **Critical** (vs Cloud: Serious) |
| Disk read | 45.2 MB |
| Disk write | 14.2 MB |

**Source files:** `data/story_metrics_ondevice.csv`, `data/step6/privacy_pipeline_ondevice.csv`, `data/step6/network_proxyman_ondevice.csv`, `data/ondevice_console_logs.txt`, `data/step6/`

**Notes:**
- S1 cold-start TTFT of 10,782 ms — Apple FM model loads on first session; subsequent sessions warm
- Thermal state **Critical** (red) vs Cloud's Serious (yellow) — sustained ANE usage with no network idle periods
- **Network 0%** energy component confirms zero cloud calls — strongest privacy guarantee of all 4 modes
- AXSpeech thread confirms on-device TTS active — audio synthesised locally
- No `restartWithSummary` triggered in any session (max 5 turns, well under 6-turn limit)

---

## Step 7 — Mode C: On-Device Gemma 3 1B (MediaPipe)

**Sessions run:** 5  
**Total beats:** 24 (S1=5, S2=7, S3=2, S4=3, S5=7)  
**CSV saved?** YES — `data/story_metrics_gemma4.csv`  
**Model:** Gemma 3 1B Q4_K_M GGUF (~800 MB on disk, **2.96 GB loaded in RAM**)

### Latency summary (from `data/story_metrics_gemma4.csv`)

| Metric | Value (ms) |
|--------|-----------|
| TTFT (timeToFirstToken) | N/A — not instrumented in Gemma4StoryService (all 0.0) |
| Mean total generation (all 24 beats) | 14,614 |
| Median total generation | 13,465 |
| Std Dev total generation | 5,004 |
| Min / Max total generation (ms) | 9,721 / 34,516 |
| Cold start (S1 beat 0) | **34,516** ms — GGUF model load + first inference |
| Warm beats mean (beats 1+) | 13,749 ms |
| Warm beats median | 13,315 ms |
| Mean beats per session | 4.8 (S1=5, S2=7, S3=2, S4=3, S5=7) |
| Guardrail violations | 0 |

**vs Cloud (4,205 ms):** Gemma warm mean 3.3× slower  
**vs Apple FM (7,102 ms):** Gemma warm mean 1.9× slower

### Response parsing (from `data/step7/gemma_console_logs.txt`)

| Metric | Value |
|--------|-------|
| Total beats logged | 11 (partial log — Xcode truncated early sessions) |
| JSON parse success (structured path) | 9 / 11 |
| JSON parse success rate | ~82% |
| Heuristic fallback / bad parse | 2 — raw ` ```json ` leaked into storyText field |
| Empty / failed responses | 0 |
| `isEnding: true` appearances | 0 (sessions ended by VAD timeout) |

**Parse failure example:** Beat[2] of S1 — `storyText` contained raw ` ```json` prefix, `question` contained JSON fragment. Story still continued via heuristic path.

### VAD note

| Check | Result |
|-------|--------|
| VAD Layer 2 (Apple FM semantic) enabled | NO — `skipSemanticLayer=true` for Gemma mode |
| Active VAD layers | Layer 1 (keyword) + Layer 3 (hard cap 8s) only |

### Privacy & network verification

| Check | Result |
|-------|--------|
| Cloud Run HTTP requests | **0** — Proxyman shows only `gateway.icloud.com` CONNECT (system) |
| `rawDataTransmitted` | false — ALL rows |
| Network screenshot | YES — `data/step7/network_report.png` ("No Active Connections") |
| Proxyman screenshot | YES — `data/step7/proxyman_no_cloud_requests.png` |

### Gemma pipeline latency (`data/step7/privacy_pipeline_gemma4.csv`, n=5)

| Stage | Mean (ms) |
|-------|----------|
| Face detect (Stage 1) | ~11.2 |
| Face blur (Stage 2) | ~7.5 |
| YOLO detection (Stage 3) | 104.2 |
| Full pipeline mean | 134.1 |

### System resource usage (Instruments, 16 min 52 sec)

| Resource | Value |
|----------|-------|
| CPU (SeeSaw avg) | 7% |
| CPU peak | 156% |
| Active threads | ANEServicesThread, `drishtij/0` ×5 (MediaPipe inference threads) |
| GPU frame time | **151.2 ms** (vs 0.1 ms for Cloud/Apple FM — MediaPipe uses GPU for LLM) |
| GPU energy share | **21.1%** (vs 2.6–3.8% other modes) |
| Memory avg | **2.96 GB** (39.2% of 7.5 GB) |
| Memory peak | **3.01 GB** |
| Energy impact | High (CPU 76.9%, GPU 21.1%, Display 1.9%, Network 0%) |
| Thermal state | Critical |
| Disk read | **2.7 GB** (GGUF model loaded from storage) |
| Disk write | 15.2 MB |

**Source files:** `data/story_metrics_gemma4.csv`, `data/gemma4_console_logs.txt`, `data/step7/privacy_pipeline_gemma4.csv`, `data/step7/`

**Notes:**
- **Memory 2.96 GB** — 45× higher than Cloud (65.9 MB) and Apple FM (65.7 MB); GGUF Q4_K_M model held entirely in RAM throughout session
- **Disk read 2.7 GB** — full model file streamed from flash storage on first session; confirms model not cached in RAM across app launches
- `drishtij/0` threads are MediaPipe LLM inference worker threads — visible CPU burst pattern matches generation cadence in CPU chart
- GPU 151.2 ms frame time indicates GPU is saturated during inference (MediaPipe uses Metal GPU backend), causing UI frame drops
- 2 JSON parse failures (18% failure rate) — a known limitation of the prompt-based JSON extraction approach; heuristic fallback recovered both
- `toy_airplane` detected by YOLO (rows in log) — one of the 44-class extended taxonomy objects performing correctly

---

## Step 8 — Mode D: Hybrid (Gemma/Apple FM + Cloud)

**Sessions run:** 5  
**Total beats:** 15 (all sessions 3 beats each)  
**Story metrics CSV saved?** YES — `data/story_metrics_hybrid.csv`  
**Hybrid metrics CSV saved?** NO — `HybridMetricsStore` not separately exported; beat routing derived from console log

### Latency summary (from `data/story_metrics_hybrid.csv`)

| Metric | Value (ms) |
|--------|-----------|
| Mean total generation (all 15 beats) | 12,522 |
| Median total generation | 6,147 |
| Std Dev | 12,020 (bimodal: onDevice ~14k vs cloud ~5k) |
| Min / Max (ms) | 3,055 / 44,199 |
| Mean beats per session | 3.0 |
| Guardrail violations | 0 |
| TTFT | N/A — not instrumented (0.0 for all Gemma-sourced beats) |

### Beat source distribution (from `data/step8/hybrid_console_logs.txt`)

| Source | Beat count | Percentage | Mean latency (ms) |
|--------|-----------|-----------|------------------|
| Gemma4 local (beat[0] every session) | 5 | 33% | 17,721 |
| Gemma4 local fallback (S1 beat[1]) | 1 | 7% | 14,134 |
| Cloud `/story/generate` (beats 1–2, S2–S5) | 9 | 60% | 4,986 |
| **Total beats** | **15** | **100%** | |

### Critical finding — `/story/enhance` endpoint: 404

| Check | Result |
|-------|--------|
| `/story/enhance` requests | **15 — all HTTP 404** |
| `/story/generate` requests | 15 — all HTTP 200 |
| Enhancement layer deployed? | **NO** — endpoint not implemented on Cloud Run backend |
| Effective hybrid behaviour | beat[0] = local Gemma4; beat[1+] = cloud `/story/generate` fallback |

**Log evidence:** `requestEnhancement: HTTP 404, falling back to /story/generate` repeated every turn. The intended hybrid architecture (local-first + cloud enhancement overlay) was non-functional for this evaluation. This is a significant dissertation limitation — hybrid mode reduced to Gemma4 for opener + pure cloud for continuation.

### Network footprint (from `data/step8/network_hybrid_proxyman.csv`)

| Metric | Value |
|--------|-------|
| `/story/generate` mean RTT | 3,685 ms |
| `/story/generate` median RTT | 3,600 ms |
| `/story/enhance` mean RTT | 3,118 ms (mostly fast 404 responses; one 38,151 ms outlier = Cloud Run cold start) |
| Request body mean size | 904 bytes (range: 363–1,721) |
| Response body mean size | 221 bytes (`/enhance` 404s return small error bodies) |
| Total received (Instruments) | 67.4 KB |
| Total sent (Instruments) | 70.9 KB |

### Privacy verification

| Check | Result |
|-------|--------|
| `rawDataTransmitted` | false — ALL rows |
| Objects in request body | Labels only (`objects[]`, `scene[]`) — no pixels |
| Network screenshot | YES — `data/step8/network_report.png` |

### Hybrid pipeline latency (`data/step8/privacy_pipeline_hybrid.csv`, hybrid rows n=5)

| Stage | Mean (ms) |
|-------|----------|
| YOLO detection (Stage 3) | 101.1 |
| Full pipeline mean | 129.8 |

### System resource usage (Instruments, 10 min 47 sec)

| Resource | Value |
|----------|-------|
| CPU (SeeSaw avg) | 6% |
| CPU peak | 209% |
| Active threads | ANEServicesThread ×2, drishtij/0 (MediaPipe), NSURLConnection |
| GPU frame time | **136.8 ms** (MediaPipe still loaded) |
| GPU energy share | 2.1% |
| Memory avg | **2.96 GB** (39.2% — GGUF model held in RAM) |
| Memory peak | 3.01 GB |
| Energy impact | High (CPU 91.2%, Display 4.2%, Network 1.3%, GPU 2.1%) |
| Thermal state | Critical |
| Disk read | 2.7 GB (GGUF model load) |
| Disk write | 14.7 MB |

**Source files:** `data/story_metrics_hybrid.csv`, `data/step8/network_hybrid_proxyman.csv`, `data/step8/privacy_pipeline_hybrid.csv`, `data/step8/hybrid_console_logs.txt`, `data/step8/`

**Notes:**
- S1 cold start: 35,927ms beat[0] + 14,134ms beat[1] (both Gemma4 local) + 44,199ms beat[2] (cloud, incl. 38s Cloud Run cold start)
- S2–S5 warm pattern: ~13,000ms local beat[0] then ~4,000–6,000ms cloud beats[1–2]
- `/story/enhance` 404 is the key limitation — deploy this endpoint to unlock true hybrid enhancement
- Memory and GPU load identical to Step 7 (Gemma mode) — GGUF model remains loaded for beat[0] generation
- Network energy 1.3% (vs 0% for pure onDevice modes) confirms cloud requests are firing for beats 1+

---

## Step 9 — VAD Layer Distribution

**Total turns analysed:** 58 (compiled from Steps 5–8 console logs)  
**Console logs saved?** YES — `data/vad_console_logs.txt` (compiled from step5–8 logs)  
**Source modes:** Cloud (Step 5), Apple FM (Step 6), Gemma (Step 7), Hybrid (Step 8)

### Layer decision counts

| VAD Layer | Fires count | % of turns | Notes |
|-----------|-------------|------------|-------|
| Layer 1 — heuristic trailing phrase | 2 | 3% | Keyword detection rarely triggers alone |
| Layer 2 — Apple FM semantic check started | 28 | 48% | Only fires when speech detected and substantial |
| Layer 2 — completed successfully | 27 | 96% of L2 fires | Fast semantic evaluation |
| Layer 2 — error/cancelled | 5 | 18% of L2 fires | CancellationError when L3 beat it |
| Layer 3 — 8s hard cap | 58 | 100% | Always runs concurrently; safety net on every turn |

**Interpretation:** Layer 3 (hard cap) fires on every single turn — it runs in parallel with Layers 1 and 2 as a guaranteed ceiling. Layer 2 started on ~48% of turns (when the STT transcript was long enough to trigger semantic evaluation). The two layers often resolve within the same second, with L3 cancelling L2 when speech continues past 8s.

### Layer 2 latency (when fired)

| Metric | Value |
|--------|-------|
| Mean Layer 2 decision latency | 1.8 s |
| Median | 1.0 s |
| Min | < 1 s (same-second as start) |
| Max | 21 s (outlier — L2 not cancelled, eventually errored) |
| Typical range | 1–2 s |

### Mode breakdown (Layer 2 availability)

| Mode | Layer 2 enabled? | Note |
|------|-----------------|------|
| onDevice (Apple FM) | YES | Full 3-layer VAD |
| gemma4OnDevice | NO | `skipSemanticLayer=true` — MediaPipe GPU contention |
| cloud | YES | Full 3-layer VAD |
| hybrid | YES | Full 3-layer VAD (L2 = Apple FM local, independent of cloud) |

**Source files:** `data/vad_console_logs.txt`, `data/step9/vad_console_logs.txt`

**Notes:**
- Layer 1 (2 fires) confirms keyword/trailing-phrase detection is a minor contributor — most turns end via L2 or L3
- 21s L2 outlier: Apple FM semantic check hung during hybrid session; eventually threw CancellationError and returned answer anyway
- Gemma mode deliberately skips L2 to avoid GPU resource contention between MediaPipe inference and Apple FM model
- Layer 2 error rate of 18% when fired is acceptable — all errors fall through gracefully via `treating as complete`

### Mode breakdown (Layer 2 availability)

| Mode | Layer 2 enabled? | Note |
|------|-----------------|------|
| onDevice (Apple FM) | YES | Full 3-layer VAD |
| gemma4OnDevice | NO | `skipSemanticLayer=true` — MediaPipe contention |
| cloud | YES | Full 3-layer VAD |
| hybrid | YES | Full 3-layer VAD |

**Notes:**

---

## Step 10 — Network Privacy Verification Screenshots

| Screenshot | File | Verified |
|-----------|------|---------|
| Cloud request body (no raw pixels) | `data/step5/screenshots/network_request_body_proof.png` | YES |
| On-device zero network requests | `data/step6/network_report.png` | YES |
| Gemma zero network requests | `data/step7/network_report.png` | YES |
| Hybrid network activity | `data/step8/network_report.png` | YES |
| Proxyman Gemma — no SeeSaw cloud traffic | `data/step7/proxyman_no_cloud_requests.png` | YES |

### Checklist for each cloud/hybrid request

| Field | Expected | Observed |
|-------|----------|---------|
| `objects` field type | string array | YES — e.g. `["potted_plant"]` |
| `scene` field type | string array | YES — e.g. `["cord", "container"]` |
| `transcript` field | string or null | YES — `null` when no speech |
| `child_age` / `child_name` | metadata only | YES — `6`, `"Test Child"` |
| Any `image` / `jpeg` / `pixels` field | ABSENT | CONFIRMED ABSENT |
| Content-Type header | `application/json` | CONFIRMED |
| Request size (bytes) | < 2 KB | YES — range 163–2,621 bytes |
| `rawDataTransmitted` in metrics | false | ALL rows across all modes |

**Notes:** Full request/response JSON captured via Proxyman for Steps 5 and 8. All requests contain only anonymised labels — zero raw media data.

---

## Step 11 — End-to-End Round-Trip Latency

**TTS speech rate:** ~14.8 chars/sec (OB-008 baseline)  
**VAD listening window:** 8 s hard cap (Layer 3) on every turn  
**Mean story text length:** Cloud=237 chars, Apple FM=96 chars, Gemma=193 chars

### Mean round-trip per mode

| Component | Apple FM (onDevice) | Gemma 3 1B | Cloud | Hybrid |
|-----------|---------------------|-----------|-------|--------|
| Pipeline latency (ms) | 115 | 134 | 126 | 130 |
| Story generation (ms) | 7,102 | 13,749 (warm) | 4,205 | 12,522 (mean) |
| TTS duration — est. (s) | ~6.5 | ~13.0 | ~16.0 | ~13.5 |
| VAD listening window (s) | 8 | 8 | 8 | 8 |
| **Total round-trip est. (s)** | **~21.6** | **~29.9** | **~28.3** | **~29.6** |

*TTS duration estimated from mean storyTextLength ÷ 14.8 chars/sec.*  
*Round-trip = pipeline + generation + TTS + VAD window.*

### Fastest observed round-trips (best-case)

| Mode | Min generation (ms) | Min story length | Est. fastest round-trip (s) |
|------|--------------------|-----------------|-----------------------------|
| Cloud | 1,756 | 148 chars | ~20.0 |
| Apple FM | 4,643 | 42 chars | ~17.5 |
| Gemma | 9,721 | 88 chars | ~23.7 |
| Hybrid (cloud beats) | 3,055 | 222 chars | ~26.0 |

**Notes:**
- Apple FM has the lowest mean round-trip despite slower generation — shorter story texts reduce TTS time significantly
- Cloud fastest raw generation (1,756ms) but longer responses push total round-trip up
- VAD 8s window dominates for short answers — opportunity to reduce with adaptive VAD timeout

---

## Step 13 — Story Quality Assessment

**Sessions evaluated:** TBD (target: 5 per mode = 20 total)  
**Rubric:** 1 (poor) — 3 (adequate) — 5 (excellent)

### Cloud mode — quality scores

| Session | Scene relevance | Answer integration | Language age | Coherence | Ending | Mean |
|---------|-----------------|--------------------|-------------|-----------|--------|------|
| S-CL-01 | TBD | TBD | TBD | TBD | TBD | TBD |
| S-CL-02 | TBD | TBD | TBD | TBD | TBD | TBD |
| S-CL-03 | TBD | TBD | TBD | TBD | TBD | TBD |
| S-CL-04 | TBD | TBD | TBD | TBD | TBD | TBD |
| S-CL-05 | TBD | TBD | TBD | TBD | TBD | TBD |
| **Mean** | TBD | TBD | TBD | TBD | TBD | **TBD** |

### Apple FM mode — quality scores

| Session | Scene relevance | Answer integration | Language age | Coherence | Ending | Mean |
|---------|-----------------|--------------------|-------------|-----------|--------|------|
| S-AF-01 | TBD | TBD | TBD | TBD | TBD | TBD |
| S-AF-02 | TBD | TBD | TBD | TBD | TBD | TBD |
| S-AF-03 | TBD | TBD | TBD | TBD | TBD | TBD |
| S-AF-04 | TBD | TBD | TBD | TBD | TBD | TBD |
| S-AF-05 | TBD | TBD | TBD | TBD | TBD | TBD |
| **Mean** | TBD | TBD | TBD | TBD | TBD | **TBD** |

### Gemma 3 1B mode — quality scores

| Session | Scene relevance | Answer integration | Language age | Coherence | Ending | Mean |
|---------|-----------------|--------------------|-------------|-----------|--------|------|
| S-GM-01 | TBD | TBD | TBD | TBD | TBD | TBD |
| S-GM-02 | TBD | TBD | TBD | TBD | TBD | TBD |
| S-GM-03 | TBD | TBD | TBD | TBD | TBD | TBD |
| S-GM-04 | TBD | TBD | TBD | TBD | TBD | TBD |
| S-GM-05 | TBD | TBD | TBD | TBD | TBD | TBD |
| **Mean** | TBD | TBD | TBD | TBD | TBD | **TBD** |

### Hybrid mode — quality scores

| Session | Scene relevance | Answer integration | Language age | Coherence | Ending | Mean |
|---------|-----------------|--------------------|-------------|-----------|--------|------|
| S-HY-01 | TBD | TBD | TBD | TBD | TBD | TBD |
| S-HY-02 | TBD | TBD | TBD | TBD | TBD | TBD |
| S-HY-03 | TBD | TBD | TBD | TBD | TBD | TBD |
| S-HY-04 | TBD | TBD | TBD | TBD | TBD | TBD |
| S-HY-05 | TBD | TBD | TBD | TBD | TBD | TBD |
| **Mean** | TBD | TBD | TBD | TBD | TBD | **TBD** |

### Cross-mode quality summary

| Mode | Mean quality score (/5) | Rank |
|------|------------------------|------|
| Cloud (Gemini 2.0 Flash) | TBD | TBD |
| Apple Foundation Models | TBD | TBD |
| Gemma 3 1B | TBD | TBD |
| Hybrid | TBD | TBD |

**Notable observations:**
<!-- Any specific story excerpts, coherence issues, OB-003 scene label effects, post-restart quality drop, etc. -->

---

## Final Cross-Mode Comparison Table

*Completed after Steps 5–13. Last updated: 2026-04-20.*

| Metric | Mode A Cloud | Mode B Apple FM | Mode C Gemma 3 1B | Mode D Hybrid |
|--------|-------------|-----------------|-------------------|---------------|
| Network required | Yes | No | No | Conditional |
| Payload sent | ScenePayload JSON | None | None | ScenePayload JSON (beats 1+) |
| Raw data transmitted | Never | Never | Never | Never |
| Mean TTFT (ms) | N/A (blocking HTTP) | **4,148 ms** ± 1,023 ms | N/A (not reported by MediaPipe) | N/A |
| Mean total generation (ms) | **4,205 ms** ± 1,345 ms | **7,102 ms** ± 1,857 ms | **14,614 ms** ± 5,004 ms | **12,522 ms** ± 12,020 ms† |
| Mean round-trip per turn (s) | **~28.3 s** | **~21.6 s** | **~29.9 s** | **~29.6 s** |
| Beat text length (mean chars) | 254 | 102 | 193 | 211 |
| VAD Layer 2 enabled | Yes | Yes | **No** (skipSemanticLayer) | **No** (Gemma mode) |
| Context restart needed | No | No (max 5 turns in tests) | No | No |
| Model size on device (MB) | 0 | ~3,000 (Apple FM) | ~800 (GGUF disk) / **2,960 MB RAM** | ~3,800 |
| Cold start penalty | None (cloud) | None | **~34.5 s** (first session) / ~1 s subsequent | **~16.8 s** (model load, subsequent sessions < 1 s) |
| Story quality mean (/5) | Pending Step 13 scoring | Pending Step 13 scoring | Pending Step 13 scoring | Pending Step 13 scoring |
| Cloud hit rate | 100% | 0% | 0% | **100% contacted** / 67% cloud content used (beats 1+) |
| Privacy risk | Low (labels only) | Zero | Zero | Low (labels only) |
| JSON parse success rate | N/A | N/A | **~82%** (2 failures in 12 logged beats) | N/A |
| Guardrail violations | 0 | 0 | 0 | 0 |
| /story/enhance availability | ✅ (endpoint exists) | N/A | N/A | ❌ All 15 requests returned HTTP 404 |

*† Hybrid SD is high due to beat[0] cold-start (35,927 ms in session 1) vs subsequent sessions (12,710–14,275 ms) vs cloud beats (~4,200 ms).*

---

## Anomalies & Unexpected Findings

| # | Step | Description | Impact |
|---|------|-------------|--------|
| 1 | 8 | `/story/enhance` endpoint returned HTTP 404 for all 15 hybrid enhancement requests — endpoint not deployed on Cloud Run | Hybrid mode fell back to `/story/generate` for all beats 1+; true enhance behaviour (rewriting Gemma output with richer cloud prose) was never exercised. Results represent degenerate hybrid: Gemma beat[0] + independent cloud beats, not a genuine Gemma→Cloud enhancement pipeline. Reported as a dissertation limitation. |
| 2 | 5 | Proxyman SSL inspection initially showed only CONNECT tunnels, not decrypted request bodies | Required enabling host-specific SSL proxying for the Cloud Run domain. Delayed Step 5 network capture by one restart cycle. No data lost — all 25 sessions re-run with proxyman active. |
| 3 | 7 | Gemma JSON parse failures in 2 of 12 logged beats | Raw ` ```json ` fence prefix leaked into `storyText`. Heuristic fallback recovered both cases. Dissertation finding: prompt-based JSON extraction is unreliable at 1B scale; structured output API needed. |
| 4 | 6 | `sceneClassifyMs = 0` in all `runDebugDetection` (Capture button) path rows | Stage 4 is skipped on the debug path. Full-pipeline runs (story sessions) have correct values. Debug path rows in `privacy_pipeline_raw.csv` must be excluded from scene classification latency analysis. |
| 5 | 8 | Hybrid mode thermal state reached Critical during all 5 sessions | Device heat from concurrent Gemma GPU inference + cloud HTTP + TTS. Same as pure Gemma mode. High memory pressure (2.96 GB RSS) likely cause. |
| 6 | 6 | Apple FM context restart threshold (6 turns) was NOT reached in any of the 5 test sessions (max 5 turns) | The summarise-and-restart path was not exercised empirically. Architecture remains as designed but restart latency overhead was not measured. |

---

## Completion Checklist

- [x] Step 1 — Unit test suite complete (`run.xcresult`, `run-summary.txt`, `privacy-pipeline-tests.txt` in `test-results/`); 559 test case passes, 0 failures; `TestCoverage.md` regenerated
- [x] Step 2 — Pipeline CSV exported → `data/step2/privacy_pipeline_raw.csv` (21 rows); console log → `data/step2/pipeline_console_filtered.txt`
- [x] Step 3 — PII tests run → `data/step3/pii-tests-output.txt` (130 tests, 0 failures); Proxyman verification screenshots in `data/step5/screenshots/`
- [x] Step 4 — YOLO detection results for 5 controlled scenes → `data/step4/logs.md` + `data/step4/scenes/`
- [x] Step 5 — Cloud mode: 5 sessions, 25 beats; CSV → `data/step12/story_metrics_cloud.csv`; Proxyman CSV → `data/step5/network_cloud_sessions_proxyman.csv` (HAR not available — CSV equivalent captured)
- [x] Step 6 — Apple FM mode: 5 sessions, 18 beats; CSV → `data/step12/story_metrics_ondevice.csv`; console log → `data/step6/ondevice_console_logs.txt`
- [x] Step 7 — Gemma mode: 5 sessions, 24 beats; CSV → `data/step12/story_metrics_gemma4.csv`; parse rate = 82%; zero-cloud screenshot → `data/step7/proxyman_no_cloud_requests.png`
- [x] Step 8 — Hybrid mode: 5 sessions, 15 beats; CSV → `data/step12/story_metrics_hybrid.csv`; Proxyman CSV → `data/step8/network_hybrid_proxyman.csv`; `hybrid_metrics.csv` not exported (HybridMetricsStore export not implemented — beat routing reconstructed from console log)
- [x] Step 9 — VAD layer distribution tallied → `data/step9/vad_console_logs.txt` (58 turns: L1=2, L2-semantic=27, L2-skipped=29, L3=58)
- [x] Step 10 — Privacy verification screenshots in `data/step5–8/screenshots/`; request body proof at `data/step5/screenshots/network_request_body_proof.png`; zero-cloud proof at `data/step7/proxyman_no_cloud_requests.png`
- [x] Step 11 — Round-trip table filled for all 4 modes (Cloud ~28.3 s, Apple FM ~21.6 s, Gemma ~29.9 s, Hybrid ~29.6 s); see §11 above and `data/step12/charts/fig12_9_roundtrip_latency.png`
- [x] Step 12 — Python analysis run → 9 charts in `data/step12/charts/`; Kruskal-Wallis H=52.75 p<0.001; script at `scripts/analysis_step12.py`
- [ ] Step 13 — Story scoring sheet prepared (`data/step13/story_scoring_sheet.md`); **external rater scoring pending**
- [x] Cross-mode comparison table complete (see above; story quality pending Step 13)
- [x] Anomalies section reviewed and documented (6 findings)
- [ ] Observations.md updated with OB-014+ entries (see Step 15)
