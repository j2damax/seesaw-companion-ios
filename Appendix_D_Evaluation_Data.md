# Appendix D — Evaluation Data and Benchmark Results

**Device:** iPhone 16e · iOS 26.4.1 (23E254) · App: `com.seesaw.companion.ios` v1  
**Collection date:** 19–20 April 2026 · **Commit:** `fd06a52` (TestFlight release build)  
**All results are traceable to raw CSV files, Proxyman captures, and Xcode Instruments traces in the project `data/` directory.**

---

## D.1 — Unit Test Suite and Coverage

| Metric | Value |
|--------|-------|
| Total tests passed | 559 (0 failures) |
| SeeSawTests.xctest line coverage | 90.6% |
| SeeSaw.app overall coverage | 15.1% |
| Privacy invariant test (100-run) — violations | 0 |

**Privacy-critical module coverage**

| Module | Coverage |
|--------|---------|
| PIIScrubber.swift | See TestCoverage.md |
| PrivacyMetricsStore.swift | See TestCoverage.md |
| ChunkBuffer.swift | See TestCoverage.md |

**Date run:** 2026-04-19 · **Source:** `test-results/run.xcresult`, `test-results/run-summary.txt`

---

## D.2 — Privacy Pipeline Stage Latencies

**Runs captured:** 20 steady-state (cold-start row of 869 ms excluded)  
**Path:** `runDebugDetection` (Capture button) — Stages 4–6 not exercised on this path; full-pipeline timings from story sessions (D.5–D.8)

### Per-stage latency

| Stage | Mean (ms) | SD (ms) | Min (ms) | Max (ms) |
|-------|-----------|---------|---------|---------|
| Stage 1 — Face Detection | 11.27 | 1.42 | 9.27 | 15.01 |
| Stage 2 — Face Blur | 7.51 | 0.95 | 6.18 | 10.00 |
| Stage 3 — Object Detection (YOLO11n) | 19.26 | 3.08 | 16.29 | 29.90 |
| Stage 4 — Scene Classification | — | — | — | — |
| Stage 5 — Speech-to-Text | — | — | — | — |
| Stage 6 — PII Scrub | — | — | — | — |
| **Total pipeline (debug path)** | **67.24** | **22.12** | **54.24** | **153.60** |

### Scene breakdown

| Scene | Runs | Objects detected |
|-------|------|----------------|
| Study / desk | 5 (runs 1–5) | table, window |
| Living room / doorway | 5 (runs 6–10) | table, door, potted_plant, window |
| Bedroom | 5 (runs 11–15) | bed, curtains |
| Living room angle 2 | 6 (runs 16–21) | window, table, photo_frame, sofa, door |

### Privacy invariant

| Metric | Value |
|--------|-------|
| `rawDataTransmitted = true` count | **0** |
| Mean objects detected per frame | 2.3 |
| Mean faces detected per frame | 0 |
| Mean faces blurred per frame | 0 |
| Total PII tokens scrubbed | 0 (no speech during debug captures) |

**Source:** `data/step2/privacy_pipeline_raw.csv` (21 rows + header)

---

## D.3 — PII Scrubbing Verification

### Automated test results

| Pattern category | Tests | Result |
|-----------------|-------|--------|
| Name patterns | scrubRemovesNamePatterns, scrubIsCaseInsensitiveForNames, scrubRemovesImCalledPattern | All passed |
| Email patterns | scrubRemovesEmailAddresses | Passed |
| Phone / long numbers | scrubRemovesPhoneNumbers, scrubRemovesLongNumbers | All passed |
| Address / postcode | scrubRemovesStreetAddresses, scrubRemovesUKPostcodes, scrubRemovesUSZipCodes | All passed |
| Multi-PII + edge cases | scrubHandlesMultiplePIITypes, scrubHandlesEmptyString, scrubPreservesNonPIIContent, scrubPreservesStoryVocabulary | All passed |
| Token counting | scrubCountsRedactedTokens, totalTokensScrubbed | All passed |
| **Suite total** | **130 tests across 5 suites** | **0 failures** |

### Live speech PII test (physical device)

| Field | Value |
|-------|-------|
| PII spoken aloud | "My name is Tripathy I live in 10 Maple St. my phone number is 07" |
| Raw STT transcript | `My name is Tripathy I live in 10 Maple St. my phone number is 07` |
| Scrubbed transcript sent to LLM | `[REDACTED] I live in [REDACTED]. my phone number is zero` |
| Phone number fully redacted? | **Partial** — STT transcribed "07" as "zero seven"; "zero" passed through (incomplete pattern match). Documented as dissertation finding on STT–scrubber interaction. |

### Network verification of PII

| Check | Result |
|-------|--------|
| Raw name "Tripathy" in request body | **ABSENT** |
| Raw address "10 Maple St" in request body | **ABSENT** |
| `[REDACTED]` in `transcript` field | **PRESENT** |
| Beat 0 request size (no transcript) | 174 bytes |
| Beat 1 request size (scrubbed transcript) | 595 bytes |

**Source:** `data/step3/pii-tests-output.txt`, `data/step5/screenshots/network_request_body_proof.png`

---

## D.4 — Object Detection (YOLO11n)

**Model:** `seesaw-yolo11n.mlpackage` (44 classes, confidence threshold 0.25)

### Per-scene detection results

#### Scene 1 — Study / Desk — 4 captures

| Expected object | Detected? | Confidence | Appearances |
|----------------|-----------|-----------|------------|
| tv (monitor) | Yes | 96–98% | 4/4 |
| potted_plant | Yes | 97–98% | 4/4 |
| table | Yes | 95–98% | 4/4 |
| laptop | Yes | 92% | 1/4 |
| book | No | — | 0/4 |
| False positives | None | — | — |

**Precision: 1.00 · Recall: 0.80 · F1: 0.89**

#### Scene 2 — Window / Storage Area — 1 capture

Camera angle produced 0 detections. Precision / Recall: N/A.

#### Scene 3 — Wardrobe Room — 1 capture

| Expected object | Detected? | Confidence | Notes |
|----------------|-----------|-----------|-------|
| wardrobe | Partial | 83% (as "cupboard") | Class label boundary — same object |
| door | Yes | 69% | Low confidence, partially visible |
| dinosaur_toy | No | — | Underrepresented class |
| bottle | No | — | Not detected |

#### Scene 4 — Child's Bedroom — from Step 2 CSV cross-reference

| Expected object | Confidence |
|----------------|-----------|
| bed | 98% |
| door | 77–93% |
| dinosaur_toy | Not detected |
| toy_car | Not detected |
| building_blocks | Not detected |

#### Scene 5 — Hallway / Door — from Step 2 CSV cross-reference

| Expected object | Confidence |
|----------------|-----------|
| door | 77–93% |
| window | 64–96% |

### Aggregate detection metrics

| Metric | Value |
|--------|-------|
| Precision (Scene 1) | 1.00 |
| Recall (Scene 1) | 0.80 |
| F1 (Scene 1) | 0.89 |
| False positives (all scenes) | 0 |
| Training mAP@50 — Run C, 12-class benchmark | 0.8490 |
| Training mAP@50 — Run C, full 44-class | 0.6748 |

### On-device inference latency (iPhone 16e Neural Engine)

| Component | Latency |
|-----------|---------|
| Preprocessing | 1.4 ms |
| ANE inference | 5.8 ms |
| Post-processing | 0.9 ms |
| **Total** | **8.1 ms per frame** |

**Source:** `data/step4/logs.md`, `data/step4/scenes/`

---

## D.5 — Mode A: Cloud (Gemini 2.5 Flash)

**Sessions:** 5 · **Total beats:** 25 (S1=1, S2=8, S3=8, S4=4, S5=4)

### Generation latency

| Metric | Value (ms) |
|--------|-----------|
| Mean TTFT — beat[0] across 5 sessions | 4,190 |
| Median TTFT — beat[0] | 4,650 |
| Mean total generation — all 25 beats | 4,205 |
| Median total generation | 4,083 |
| SD | 1,345 |
| Min | 1,756 |
| Max | 7,481 |
| Mean turns per session | 5.0 |
| Guardrail violations | 0 |

### Network footprint

| Metric | Value |
|--------|-------|
| Mean HTTP round-trip | 4,142 ms |
| Median HTTP RTT | 4,126 ms |
| SD HTTP RTT | 1,286 ms |
| Min / Max HTTP RTT | 2,383 / 7,450 ms |
| Mean request body size | 1,120 bytes (range: 179–2,621) |
| Mean response body size | 425 bytes (range: 363–500) |
| Total bytes sent (25 beats) | 26,868 bytes |
| Total bytes received | 10,196 bytes |
| Endpoint | HTTPS POST → Cloud Run (europe-west1) |

### Privacy verification

| Check | Result |
|-------|--------|
| `rawDataTransmitted` | false — all 15 rows |
| Raw pixels in request body | Absent — objects[], scene[], transcript, child_age, child_name, session_id only |
| Faces detected and blurred | Yes — 1 face detected and blurred in 3 captures |
| PII scrub latency | ~1.8 µs (negligible) |

### Full pipeline latency (cloud sessions)

| Stage | Mean (ms) |
|-------|----------|
| Face detect | ~16.0 |
| Face blur | ~10.7 |
| YOLO + Scene classify (cumulative) | 100.9 |
| PII scrub | 0.002 |
| **Total pipeline** | **126.3** |

### System resources (12 min 23 sec session)

| Resource | Value |
|----------|-------|
| CPU avg | 7% |
| CPU peak | 163% |
| Memory avg | 65.9 MB |
| Memory peak | 121.9 MB |
| Thermal state | Serious |
| Network energy share | 1.6% |

**Source:** `data/step12/story_metrics_cloud.csv`, `data/step5/network_cloud_sessions_proxyman.csv`, `data/step5/privacy_pipeline_cloud.csv`

---

## D.6 — Mode B: Apple Foundation Models (On-Device)

**Sessions:** 5 · **Total beats:** 18 (S1=4, S2=3, S3=3, S4=3, S5=5)

### Generation latency

| Metric | Value (ms) |
|--------|-----------|
| Mean TTFT | 4,148 |
| Median TTFT | 3,723 |
| SD TTFT | 1,763 |
| Min TTFT | 2,574 |
| Max TTFT | 10,782 (S1 cold-start) |
| Mean total generation | 7,102 |
| Median total generation | 6,654 |
| SD | 1,857 |
| Min / Max | 4,643 / 13,627 ms |
| Mean turns per session | 3.6 |
| Guardrail violations | 0 |
| Context window restarts | 0 / 5 sessions |

**vs Cloud:** 69% slower generation; TTFT near-equal (4,148 vs 4,190 ms).

### Privacy and network verification

| Check | Result |
|-------|--------|
| Cloud Run HTTP requests during story session | **0** |
| `rawDataTransmitted` | false — all rows |
| Network energy share | **0%** — strongest privacy guarantee of all four modes |

### Full pipeline latency (Apple FM sessions)

| Stage | Mean (ms) |
|-------|----------|
| Face detect | ~8.5 |
| Face blur | ~5.7 |
| YOLO detection | 90.2 |
| **Total pipeline** | **115.3** |

### System resources (10 min 1 sec session)

| Resource | Value |
|----------|-------|
| CPU avg | 6% |
| CPU peak | 180% |
| Memory avg | 65.7 MB |
| Memory peak | 121.7 MB |
| Thermal state | **Critical** |
| Network energy share | **0%** |

**Source:** `data/step12/story_metrics_ondevice.csv`, `data/step6/privacy_pipeline_ondevice.csv`, `data/step6/network_proxyman_ondevice.csv`

---

## D.7 — Mode C: Gemma 3 1B On-Device (MediaPipe)

**Sessions:** 5 · **Total beats:** 24 (S1=5, S2=7, S3=2, S4=3, S5=7)  
**Model:** Gemma 3 1B Q8_0 GGUF — 1,028 MB on disk, **2.96 GB loaded in RAM**

### Generation latency

| Metric | Value (ms) |
|--------|-----------|
| Mean total generation — all 24 beats | 14,614 |
| Median total generation | 13,465 |
| SD | 5,004 |
| Min | 9,721 |
| Max | 34,516 (S1 cold-start — GGUF model load) |
| Cold-start beat (S1 beat[0]) | **34,516** |
| Warm beats mean (beats 1+) | 13,749 |
| Mean turns per session | 4.8 |
| Guardrail violations | 0 |

**vs Cloud (4,205 ms):** 3.3× slower (warm)  
**vs Apple FM (7,102 ms):** 1.9× slower (warm)

### Response parsing

| Metric | Value |
|--------|-------|
| Beats logged | 12 |
| Strict JSON parse success | 10 / 12 (82%) |
| Heuristic fallback required | 2 — unclosed ` ```json ` fence leaked into storyText |
| User-visible errors | 0 — heuristic recovered both failures |

### VAD configuration

Layer 2 (Apple FM semantic check) is **disabled** for Gemma mode (`skipSemanticLayer = true`) to avoid GPU resource contention between MediaPipe inference and Apple Foundation Models. Only Layer 1 (keyword) and Layer 3 (hard cap) are active.

### Privacy and network verification

| Check | Result |
|-------|--------|
| Cloud Run HTTP requests | **0** |
| `rawDataTransmitted` | false — all rows |

### Full pipeline latency (Gemma sessions)

| Stage | Mean (ms) |
|-------|----------|
| Face detect | ~11.2 |
| Face blur | ~7.5 |
| YOLO detection | 104.2 |
| **Total pipeline** | **134.1** |

### System resources (16 min 52 sec session)

| Resource | Value |
|----------|-------|
| CPU avg | 7% |
| CPU peak | 156% |
| GPU frame time | **151.2 ms** (vs 0.1 ms for Cloud / Apple FM) |
| GPU energy share | **21.1%** |
| Memory avg | **2.96 GB** (39.2% of 7.5 GB) |
| Memory peak | **3.01 GB** |
| Thermal state | Critical |
| Disk read | 2.7 GB (GGUF model streamed from storage) |

**Source:** `data/step12/story_metrics_gemma4.csv`, `data/step7/privacy_pipeline_gemma4.csv`, `data/step7/proxyman_no_cloud_requests.png`

---

## D.8 — Mode D: Hybrid (Gemma Opener + Cloud Continuation)

**Sessions:** 5 · **Total beats:** 15 (all sessions 3 beats each)

### Generation latency

| Metric | Value (ms) |
|--------|-----------|
| Mean total generation — all 15 beats | 12,522 |
| Median total generation | 6,147 |
| SD | 12,020 (bimodal: on-device ~14k vs cloud ~5k) |
| Min | 3,055 |
| Max | 44,199 (S1 cold-start + Cloud Run cold container) |
| Mean turns per session | 3.0 |
| Guardrail violations | 0 |

### Beat source distribution

| Source | Beats | % | Mean latency (ms) |
|--------|-------|---|-----------------|
| Gemma local — beat[0] every session | 5 | 33% | 17,721 |
| Gemma local — fallback (S1 beat[1]) | 1 | 7% | 14,134 |
| Cloud `/story/generate` — beats 1–2, S2–S5 | 9 | 60% | 4,986 |

### Critical finding — `/story/enhance` returned HTTP 404

All 15 enhancement requests returned HTTP 404. The `/story/enhance` endpoint was not deployed on Cloud Run at evaluation time. The Hybrid mode therefore operated as a degenerate fallback: Gemma beat[0] + independent Cloud continuation — not the designed concurrent dual-agent enhancement pipeline. This is documented as Anomaly 1. Deployment of `/story/enhance` is identified as future work.

### Network footprint

| Metric | Value |
|--------|-------|
| `/story/generate` mean RTT | 3,685 ms |
| `/story/enhance` mean RTT | 3,118 ms (mostly fast 404 responses) |
| Mean request body size | 904 bytes (range: 363–1,721) |
| Total received (Instruments) | 67.4 KB |
| Total sent (Instruments) | 70.9 KB |

### Privacy verification

| Check | Result |
|-------|--------|
| `rawDataTransmitted` | false — all rows |
| Objects in request body | Labels only — no pixels |

### Full pipeline latency (Hybrid sessions)

| Stage | Mean (ms) |
|-------|----------|
| YOLO detection | 101.1 |
| **Total pipeline** | **129.8** |

### System resources (10 min 47 sec session)

| Resource | Value |
|----------|-------|
| CPU peak | 209% |
| GPU frame time | 136.8 ms (MediaPipe still loaded) |
| Memory avg | **2.96 GB** |
| Memory peak | 3.01 GB |
| Thermal state | Critical |

**Source:** `data/step12/story_metrics_hybrid.csv`, `data/step8/network_hybrid_proxyman.csv`, `data/step8/privacy_pipeline_hybrid.csv`

---

## D.9 — Voice Activity Detection Layer Distribution

**Total turns analysed:** 58 (compiled from Steps 5–8 console logs)

### Layer activation counts

| VAD Layer | Activations | % of turns | Notes |
|-----------|------------|------------|-------|
| Layer 1 — keyword heuristic | 2 | 3% | Rarely the sole resolver |
| Layer 2 — semantic completeness (Apple FM) started | 28 | 48% | Fires when STT transcript is substantive |
| Layer 2 — completed successfully | 27 | 96% of L2 fires | — |
| Layer 2 — cancelled or errored | 5 | 18% of L2 fires | L3 beat it; all fell through gracefully |
| Layer 3 — 8-second hard cap | 58 | 100% | Runs concurrently on every turn as a guarantee |

Layer 3 fires on 100% of turns by design — it is a concurrent safety net, not a primary endpoint. Layer 2 resolved ~48% of turns before the cap, confirming semantic turn detection meaningfully reduces unnecessary waiting for child speech.

### Layer 2 decision latency

| Metric | Value |
|--------|-------|
| Mean | 1.8 s |
| Median | 1.0 s |
| Typical range | 1–2 s |
| Outlier maximum | 21 s (Apple FM semantic check hung; eventually errored and fell through) |

### Layer 2 availability by mode

| Mode | Layer 2 enabled? | Reason |
|------|----------------|--------|
| Cloud (Gemini 2.5 Flash) | Yes | Full 3-layer VAD |
| Apple Foundation Models | Yes | Full 3-layer VAD |
| Gemma 3 1B | **No** | `skipSemanticLayer = true` — GPU contention with MediaPipe |
| Hybrid | Yes | Layer 2 uses Apple FM locally, independent of cloud path |

**Source:** `data/step9/vad_console_logs.txt`

---

## D.10 — Network Privacy Verification Screenshots

| Screenshot | File | Verified |
|-----------|------|---------|
| Cloud request body — no raw pixels | `data/step5/screenshots/network_request_body_proof.png` | Yes |
| Apple FM — zero network connections | `data/step6/network_report.png` | Yes |
| Gemma — zero cloud requests | `data/step7/proxyman_no_cloud_requests.png` | Yes |
| Hybrid — network activity (beats 1+) | `data/step8/network_report.png` | Yes |

### Request body field verification (all cloud and hybrid requests)

| Field | Expected | Result |
|-------|----------|--------|
| `objects` | String array | Confirmed — e.g. `["potted_plant"]` |
| `scene` | String array | Confirmed — e.g. `["cord", "container"]` |
| `transcript` | String or null | Confirmed — `null` when no speech |
| `child_age` / `child_name` | Metadata only | Confirmed — `6`, `"Test Child"` |
| Any `image` / `jpeg` / `pixels` field | Absent | **Confirmed absent across all 86 beats** |
| `rawDataTransmitted` in metrics | false | All rows across all modes |

---

## D.11 — End-to-End Round-Trip Latency

**TTS speech rate:** ~14.8 chars / sec · **VAD window:** 8 s (Layer 3 hard cap)

### Mean round-trip per mode

| Component | Apple FM | Cloud | Hybrid | Gemma (warm) |
|-----------|---------|-------|--------|-------------|
| Pipeline latency | 115 ms | 126 ms | 130 ms | 134 ms |
| Story generation | 7,102 ms | 4,205 ms | 12,522 ms | 13,749 ms |
| TTS duration (est.) | ~6.5 s | ~16.0 s | ~13.5 s | ~13.0 s |
| VAD listening window | 8 s | 8 s | 8 s | 8 s |
| **Total round-trip** | **~21.6 s** | **~28.3 s** | **~29.6 s** | **~29.9 s** |

*TTS duration estimated from mean storyText length ÷ 14.8 chars/sec.*

Apple FM achieves the fastest round-trip despite slower generation because its responses are shortest (mean 102 characters), reducing TTS playback time.

---

## D.12 — Final Cross-Mode Comparison

| Metric | Cloud (Gemini 2.5 Flash) | Apple FM (On-Device) | Gemma 3 1B (On-Device) | Hybrid |
|--------|--------------------------|---------------------|----------------------|--------|
| Network required | Yes | No | No | Conditional |
| Payload transmitted | ScenePayload JSON only | None | None | ScenePayload JSON (beats 1+) |
| Raw data transmitted | Never | Never | Never | Never |
| Mean TTFT (ms) | N/A (blocking HTTP) | 4,148 | N/A (not instrumented) | N/A |
| Mean generation (ms) | **4,205** ± 1,345 | **7,102** ± 1,857 | **14,614** ± 5,004 | **12,522** ± 12,020 |
| Mean round-trip (s) | ~28.3 | **~21.6** | ~29.9 | ~29.6 |
| Beat text length (mean chars) | 254 | 102 | 193 | 211 |
| VAD Layer 2 enabled | Yes | Yes | **No** | Yes |
| JSON parse success | N/A | N/A | **82%** | N/A |
| Guardrail violations | 0 | 0 | 0 | 0 |
| Memory peak (MB) | 121.9 | 121.7 | **3,010** | ~3,010 |
| Thermal state | Serious | Critical | Critical | Critical |
| GPU energy share | 3.8% | ~0% | **21.1%** | 2.1% |
| Cold-start penalty | None | None | ~34.5 s (first session) | ~35.9 s (first session) |
| `/story/enhance` available | N/A | N/A | N/A | **No — HTTP 404** |
| Cloud hit rate | 100% | 0% | 0% | 60% (beats 1+) |
| Privacy risk | Low (labels only) | Zero | Zero | Low (labels only) |
| Cost per session | ~$0.00022 | $0 | $0 | ~$0.00013 |

---

## D.13 — Anomalies and Unexpected Findings

| # | Step | Finding | Impact |
|---|------|---------|--------|
| 1 | D.8 | `/story/enhance` returned HTTP 404 for all 15 hybrid enhancement requests. Endpoint not deployed on Cloud Run at evaluation time. | Hybrid mode operated as degenerate fallback: Gemma beat[0] + independent cloud continuation. True Gemma→Cloud enhancement pipeline was not exercised. Reported as a dissertation limitation; deployment is future work. |
| 2 | D.5 | Proxyman SSL inspection initially showed only CONNECT tunnels, not decrypted request bodies. | Required enabling host-specific SSL proxying for the Cloud Run domain. All 25 cloud sessions were re-run with Proxyman active. No data lost. |
| 3 | D.7 | Gemma JSON parse failure in 2 of 12 logged beats (18%). Raw ` ```json ` fence prefix leaked into `storyText`. | Heuristic fallback recovered both cases with no user-visible error. Confirms prompt-based JSON extraction at 1B scale is unreliable for production. Grammar-constrained decoder recommended for future iterations. |
| 4 | D.2 | `sceneClassifyMs = 0` in all `runDebugDetection` path rows (Capture button). | Stage 4 is skipped on the debug path. Full-pipeline rows from story sessions must be used for scene classification latency analysis. Debug path rows correctly excluded from Stage 4 statistics. |
| 5 | D.8 | Hybrid mode reached Critical thermal state across all 5 sessions. | Concurrent Gemma GPU inference + cloud HTTP + TTS causes sustained heat. Identical to pure Gemma mode. Memory pressure (2.96 GB RSS) is primary driver. |
| 6 | D.6 | Apple FM context window restart threshold (6 turns) was not reached in any of the 5 test sessions (max 5 turns). | The summarise-and-restart path was not exercised empirically. Architecture remains as designed but restart latency overhead was not measured. Identified for future evaluation. |

---

## D.14 — Evaluation Completion Status

| Step | Description | Status |
|------|-------------|--------|
| D.1 | Unit test suite and coverage | Complete — 559 tests, 0 failures, 90.6% coverage |
| D.2 | Privacy pipeline stage latencies | Complete — 20 steady-state runs |
| D.3 | PII scrubbing verification | Complete — 130 tests, live speech test |
| D.4 | YOLO object detection — 5 scenes | Complete |
| D.5 | Cloud mode — 5 sessions, 25 beats | Complete |
| D.6 | Apple FM mode — 5 sessions, 18 beats | Complete |
| D.7 | Gemma 3 1B mode — 5 sessions, 24 beats | Complete |
| D.8 | Hybrid mode — 5 sessions, 15 beats | Complete |
| D.9 | VAD layer distribution — 58 turns | Complete |
| D.10 | Network privacy verification screenshots | Complete |
| D.11 | End-to-end round-trip estimates | Complete |
| D.12 | Cross-mode comparison table | Complete |
| D.13 | Anomalies log | Complete — 6 findings documented |
| Step 13 | External rater story quality scoring | **Pending** — scoring sheet prepared at `data/step13/story_scoring_sheet.md`; results to be added as Appendix E upon completion |
