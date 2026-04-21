# SeeSaw Companion — Thesis Results Collection Plan

> **Data folder:** All CSV files, screenshots and exports are on [Google Drive](https://drive.google.com/drive/folders/1BlDVn-gw1g5HQp5WQwx65OxhJU9glHmd?usp=sharing) — see `DATA_LOCATION.md`.

**Purpose:** Systematic data collection for MSc dissertation Chapter 5 (implementation), Chapter 6 (evaluation), and Chapter 7 (discussion).  
**Covers:** Privacy pipeline, object detection, all four story generation modes, hybrid architecture, VAD, and final cross-mode comparison.  
**Date authored:** 2026-04-19  
**All steps run on:** Physical iPhone 12+ with iOS 26+, connected via USB to Mac running Xcode.

---

## Overview of Data to Collect

| Category | Source | Format | Destination |
|----------|--------|--------|-------------|
| Unit test results + coverage | xcodebuild on device + xcresult | Markdown table | TestCoverage.md |
| Privacy pipeline stage latencies | PrivacyMetricsStore CSV | CSV → tables/charts | Chapter 6 §6.1 |
| YOLO object detection performance | PrivacyMetricsStore CSV + Console logs | CSV | Chapter 6 §6.2 |
| Story generation latency (all 4 modes) | StoryMetricsStore CSV | CSV → box plots | Chapter 6 §6.3 |
| Time-to-first-token (TTFT) per mode | StoryMetricsStore CSV | CSV | Chapter 6 §6.3 |
| Hybrid cloud hit rate + source breakdown | HybridMetricsStore CSV | CSV → pie/bar charts | Chapter 6 §6.4 |
| VAD layer decision distribution | Console logs (manual parse) | Tally table | Chapter 6 §6.5 |
| Privacy invariant proof (100-run) | Automated test output | Pass/fail count | Chapter 5 §5.3 |
| Network traffic verification | Xcode Network Inspector | Screenshots | Chapter 5 §5.3 |
| PII scrubbing effectiveness | PrivacyMetricsStore CSV | CSV | Chapter 6 §6.1 |
| Context restart frequency | StoryMetricsStore + Console logs | Tally | Chapter 6 §6.3 |
| End-to-end round-trip latency | Manual timing + Console logs | Table | Chapter 6 §6.6 |
| Cross-mode comparison | All CSVs combined | Summary table | Chapter 6 §6.7 |

---

## Prerequisites — Physical Device Setup

Complete all of these before starting any step.

### P1 — Device details (confirmed)

| Field | Value |
|-------|-------|
| Device name | Jam 16e |
| Model | iPhone 16e |
| iOS version | 26.4.1 (23E254) |
| UDID | `00008140-000121DA2E32801C` |
| Capacity | 128 GB |
| Bundle ID | `com.seesaw.companion.ios` |
| SeeSaw installed | Yes (version 1) |

Set destination variable for all `xcodebuild` commands in this session:

```bash
export DEVICE_UDID="00008140-000121DA2E32801C"
export DEVICE_DEST="platform=iOS,id=$DEVICE_UDID"
```

### P2 — Build and install on device

```bash
cd /Users/jayampathyicloud.com/SeeSaw/code/seesaw-companion-ios

xcodebuild build \
  -workspace SeeSaw.xcworkspace \
  -scheme SeeSaw \
  -destination "$DEVICE_DEST" \
  -configuration Debug \
  2>&1 | tail -10
```

Confirm last line reads `** BUILD SUCCEEDED **`.

### P3 — Device configuration checklist

Device confirmed connected and app installed. Verify these before starting Step 1:

| Setting | Where | Required value | Status |
|---------|-------|----------------|--------|
| Apple Intelligence | iOS Settings → Apple Intelligence & Siri | **On** | Verify |
| Screen auto-lock | iOS Settings → Display & Brightness → Auto-Lock | **Never** | Set now |
| Developer mode | iOS Settings → Privacy & Security → Developer Mode | **On** | Verify |
| Network Link Conditioner | iOS Settings → Developer | Available | Verify (used in Step 8) |
| Gemma 3 1B model | SeeSaw App → Settings | "Ready" (800 MB) | Verify / Download |
| Cloud Agent URL | SeeSaw App → Settings | `https://seesaw-cloud-agent-531853173205.europe-west1.run.app` | Set if blank |
| Child name | SeeSaw App → Settings | "Test Child" | Set |
| Child age | SeeSaw App → Settings | 6 | Set |
| Wearable type | SeeSaw App → Settings | iPhone Camera | Set |

### P4 — Attach Xcode Console before every step

In Xcode:
1. **Debug → Attach to Process → SeeSaw** (while app is running on device)
2. In the Console filter bar enter: `com.seesaw.companion`
3. Before each step, click **Clear** (⌘K) so logs are isolated per step

---

## Step 1 — Unit Test Suite & Code Coverage

**Goal:** Capture current test pass rate and per-file coverage, including privacy invariant proof.  
**Duration:** ~10 minutes.  
**Runs on:** Physical iPhone (connected via USB — Neural Engine coverage needed for accurate CoreML test paths).

### 1.1 Run full test suite on device

```bash
cd /Users/jayampathyicloud.com/SeeSaw/code/seesaw-companion-ios

xcodebuild test \
  -workspace SeeSaw.xcworkspace \
  -scheme SeeSaw \
  -destination "$DEVICE_DEST" \
  -testPlan SeeSaw \
  -enableCodeCoverage YES \
  -resultBundlePath test-results/run.xcresult \
  2>&1 | grep -E "(Test Suite|passed|failed|error:)" | tee test-results/run-summary.txt
```

### 1.2 Count pass/fail totals

```bash
grep -c "passed" test-results/run-summary.txt
grep -c "failed" test-results/run-summary.txt
```

### 1.3 Export coverage to Markdown

```bash
bash scripts/export-coverage.sh test-results/run.xcresult TestCoverage.md
# Rewrites TestCoverage.md
```

### 1.4 Run privacy invariant test in isolation and save output

```bash
xcodebuild test \
  -workspace SeeSaw.xcworkspace \
  -scheme SeeSaw \
  -destination "$DEVICE_DEST" \
  -only-testing:SeeSawTests/PrivacyPipelineTests \
  2>&1 | tee test-results/privacy-pipeline-tests.txt
```

Look for `testPrivacyInvariantAcross100Runs`. Record:
- Iterations: 100
- Violations: 0
- Wall-clock duration (seconds)

### 1.5 Expected results

| Metric | Expected |
|--------|----------|
| Total tests | ~130 |
| Failures | 0 |
| SeeSawTests.xctest coverage | ≥ 96% |
| PIIScrubber.swift coverage | 100% |
| PrivacyMetricsStore.swift coverage | 100% |
| Privacy invariant violations | 0 |

Record findings in `[Google Drive]/results_template.md` → Step 1 section.

---

## Step 2 — Privacy Pipeline Stage Latency Benchmarks

**Goal:** Per-stage latency data (face detect, blur, YOLO, scene, STT, PII scrub) with Neural Engine active.  
**Duration:** ~25 minutes.  
**Runs on:** Physical iPhone (Neural Engine required — simulator YOLO timing is not representative).

### 2.1 App configuration

- App → Settings → Story Mode: **On-Device (Apple FM)** *(pipeline is mode-independent; this avoids cloud calls)*
- Xcode Console: attached and cleared

### 2.2 Run pipeline 20+ times across 4 scene types

Point the camera at each scene and tap **Capture**. Wait for the pipeline to complete (status returns to idle) before the next capture.

| Scene | Target runs | Objects to have visible |
|-------|------------|------------------------|
| Desk | 5 | laptop, cup, book |
| Living room | 5 | sofa, cushion, plant |
| Toy area | 5 | teddy bear, building blocks |
| Bedroom | 5 | bed, wardrobe, window |

### 2.3 Export Privacy Pipeline CSV

1. App → Settings → **Export Pipeline CSV**
2. AirDrop or email to Mac
3. Save as: `data/privacy_pipeline_raw.csv`

Expected columns:
```
generationMode, facesDetected, facesBlurred, objectsDetected,
tokensScrubbedFromTranscript, rawDataTransmitted, pipelineLatencyMs,
faceDetectMs, blurMs, yoloMs, sceneClassifyMs, sttMs, piiScrubMs, timestamp
```

### 2.4 Save Xcode Console log for this step

In Xcode Console after all 20+ runs:
1. Select all → Copy
2. Paste into: `data/pipeline_console_logs.txt`

Filter lines of interest:
```bash
grep -E "faceDetect|yolo|sceneClassify|piiScrub|pipelineLatency|conf=" \
  data/pipeline_console_logs.txt > data/pipeline_console_filtered.txt
```

### 2.5 Verify YOLO confidence scores

From `data/pipeline_console_filtered.txt`, note the confidence score format (`conf=0.XX`) for detected classes. This feeds into Step 4 per-class analysis.

Record all findings in `[Google Drive]/results_template.md` → Step 2 section.

---

## Step 3 — PII Scrubbing Verification

**Goal:** Prove PII patterns are caught by the automated suite and confirmed live on device.  
**Duration:** ~20 minutes.  
**Runs on:** Physical iPhone for both automated tests (Neural Engine parity) and live speech test.

### 3.1 Run PII tests in isolation on device

```bash
# Note: PrivacyPipelineTests uses Swift Testing (struct, not XCTestCase).
# -only-testing: does not filter Swift Testing suites — run full suite and grep.
# PII results are already in test-results/run-summary.txt from Step 1.
grep -E "PIIScrubber|PrivacyMetrics|PrivacyCompliance|ScenePayloadPrivacy|scrub" \
  test-results/run-summary.txt > data/pii-tests-output.txt
```

Check the output for each pattern category (names, emails, phone numbers, addresses) — all should pass.

### 3.2 Live speech PII test

1. App → Settings → Story Mode: **Cloud** *(so you can inspect the outbound network request)*
2. Start a story session (Capture → wait for first beat + question)
3. When prompted to answer, speak clearly:  
   **"My name is [your name] and I live at 10 Maple Street"**
4. In Xcode Console look for:
   ```
   PIIScrubber: tokensRedacted=N
   ```
5. Note the value of N and what tokens were redacted

### 3.3 Network verification of PII scrubbing

During the cloud session started in 3.2:

1. Xcode → Debug Navigator → **Network** tab (or use Proxyman on Mac)
2. Find the POST to `/story/generate`
3. Inspect the `transcript` field in the request body JSON
4. Confirm `[REDACTED]` appears where your name/address was spoken

Take a screenshot → save as `data/screenshots/pii_network_request.png`

Record all findings in `[Google Drive]/results_template.md` → Step 3 section.

---

## Step 4 — Object Detection Accuracy (YOLO11n)

**Goal:** Document in-app detection precision/recall per scene for the 44-class model.  
**Duration:** ~30 minutes.  
**Runs on:** Physical iPhone (Neural Engine — YOLO runs CoreML with Neural Engine acceleration).

### 4.1 Preparation

- App → Settings → Story Mode: **On-Device (Apple FM)** *(avoid cloud calls during detection testing)*
- Xcode Console: attached and cleared before each scene
- Set up each scene physically with the objects listed below

### 4.2 Controlled scene captures (5 scenes × 4 captures each = 20 total)

For each scene, tap **Capture** 4 times from slightly different angles. After each capture, note from the Console:
- Object classes detected
- Confidence score per detection (`conf=0.XX`)
- Any false positives (classes not physically present)

| Scene | Objects to place | Expected classes |
|-------|-----------------|------------------|
| A — Study | Teddy bear, book, cup on a table | teddy_bear, book, cup, table |
| B — Toys | Building blocks, toy car, puzzle pieces | building_blocks, toy_car, puzzle_piece |
| C — Bag area | Backpack, chair, water bottle | backpack, chair, bottle |
| D — Living room | Sofa, lamp, potted plant | sofa, lamp, potted_plant |
| E — Bedroom | Bed, wardrobe, photo frame on wall | bed, wardrobe, photo_frame |

### 4.3 Record scene classification labels (Stage 4)

For each scene, from Console log record the `VNClassifyImageRequest` top-3 labels:

```bash
grep "sceneClassify" data/pipeline_console_logs.txt
```

Note whether labels are child-friendly (bedroom, living_room) or tech-centric (consumer_electronics) — relates to OB-003.

### 4.4 Compute detection metrics per scene

```
Precision = TP / (TP + FP)
Recall    = TP / (TP + FN)
F1        = 2 × (P × R) / (P + R)
```

Reference mAP@50 from training repo (not computed here):
- Run B (Layer 1 only): **mAP@50 = 0.8614**
- Run C (production, all layers): **mAP@50 = 0.6748**

Record all findings in `[Google Drive]/results_template.md` → Step 4 section.

---

## Step 5 — Story Generation: Mode A — Cloud (Gemini 2.0 Flash)

**Goal:** Baseline network-dependent generation latency, payload size, cold start penalty.  
**Duration:** ~35 minutes.  
**Runs on:** Physical iPhone with active WiFi internet connection.

### 5.1 Configure

- App → Settings → Story Mode: **Cloud**
- Cloud Agent URL: `https://seesaw-cloud-agent-531853173205.europe-west1.run.app`
- Xcode Console: attached and cleared
- Xcode Debug Navigator → **Network** tab: open and ready to capture

### 5.2 Cold start capture (first session only)

Leave the Cloud Run service idle for ≥ 15 minutes before this step (or first run of the day). The first `/story/generate` request will hit a cold container. Record the HTTP round-trip time separately as "cold start latency".

### 5.3 Run 5 complete story sessions

For each session:
1. Point camera at an indoor scene → tap **Capture**
2. Wait for the first story beat to appear and be spoken
3. Answer each question aloud (2–4 words)
4. Continue until `isEnding=true` fires or 6 turns reached
5. Between sessions: wait 60 seconds (let the app return to idle)

During sessions, in the **Network** tab record per request:
- HTTP round-trip latency (ms)
- Request body size (bytes)
- Response body size (bytes)

### 5.4 Export Story Metrics CSV

App → Settings → **Export Story CSV**  
Save as: `data/story_metrics_cloud.csv`

Expected columns:
```
generationMode, timeToFirstTokenMs, totalGenerationMs, turnCount,
guardrailViolations, storyTextLength, timestamp
```

### 5.5 Save network logs

In Xcode Network Inspector: File → Export → HAR  
Save as: `data/network_cloud_sessions.har`

### 5.6 Verify privacy invariant in request body

From the Network tab, click any `/story/generate` request → **Body**:
- `objects`: string array ✓
- `scene`: string array ✓
- `transcript`: string or null ✓
- No `image`, `jpeg`, `base64`, `pixels` field ✓
- Content-Type: `application/json` ✓

Screenshot → `data/screenshots/network_cloud_request.png`

Record all findings in `[Google Drive]/results_template.md` → Step 5 section.

---

## Step 6 — Story Generation: Mode B — On-Device (Apple Foundation Models)

**Goal:** On-device generation latency, streaming TTFT, context window restart behaviour.  
**Duration:** ~50 minutes.  
**Runs on:** Physical iPhone (Apple Foundation Models requires Neural Engine + Apple Intelligence enabled).

### 6.1 Configure

- App → Settings → Story Mode: **On-Device (Apple FM)**
- iOS Settings → Apple Intelligence & Siri → **On** (verify)
- iOS Settings → Display & Brightness → Auto-Lock → **Never**
- Xcode Console: attached and cleared
- Xcode Debug Navigator → **Network** tab: open (to verify zero requests)

### 6.2 Run 5 complete story sessions

Same procedure as Step 5.3. Additionally watch Console for:
```
restartWithSummary        → context restart fired
Context restart at turn N → which turn triggered it
totalGenerationMs=        → end-to-end generation time
onPartialText: first      → TTFT anchor
```

For each session note:
- Did `restartWithSummary` fire? Which turn?
- Generation time pre-restart vs. post-restart
- Did the child's name survive the restart?

### 6.3 Export Story Metrics CSV

App → Settings → **Export Story CSV**  
Save as: `data/story_metrics_ondevice.csv`

### 6.4 Save Console log for this step

After all 5 sessions, copy Console output → `data/ondevice_console_logs.txt`

Filter:
```bash
grep -E "totalGenerationMs|ttft|restartWithSummary|Context restart|onPartialText" \
  data/ondevice_console_logs.txt > data/ondevice_console_filtered.txt
```

### 6.5 Verify zero network requests

In Xcode Network Inspector: confirm no HTTP requests appear during story generation turns.  
Screenshot the empty network tab → `data/screenshots/network_ondevice_zero_requests.png`

Record all findings in `[Google Drive]/results_template.md` → Step 6 section.

---

## Step 7 — Story Generation: Mode C — On-Device Gemma 3 1B (MediaPipe)

**Goal:** Second on-device baseline; JSON parse success rate; compare latency with Apple FM.  
**Duration:** ~50 minutes.  
**Runs on:** Physical iPhone (MediaPipe GGUF inference, ~800 MB model on device).

### 7.1 Configure

- Verify model is ready: App → Settings → Gemma model status shows **"Ready"**
- If not downloaded: tap **Download Model** → wait ~5 minutes
- App → Settings → Story Mode: **Gemma 3 1B (On-Device)**
- Xcode Console: attached and cleared
- Xcode Debug Navigator → **Network** tab: open (verify zero requests)

### 7.2 Important: VAD Layer 2 is disabled in this mode

`skipSemanticLayer=true` is set when calling `listenForAnswer` in Gemma mode. This prevents a MediaPipe/Apple FM concurrency hang. The story interaction uses only:
- Layer 1 (heuristic trailing-phrase, <1 ms)
- Layer 3 (8s hard cap)

Document this explicitly in your dissertation as a known architectural constraint.

### 7.3 Run 5 complete story sessions

Same procedure as Step 5.3. During sessions, watch Console for:
```
parseResponse: JSON path      → structured JSON extraction succeeded
parseResponse: heuristic      → fallback text parsing used
Gemma JSON parse success      → clean beat
Gemma heuristic fallback      → degraded path
LlmInference token:           → token throughput
```

Count JSON vs. heuristic beats manually from Console or by grepping the log after sessions.

### 7.4 Export Story Metrics CSV

App → Settings → **Export Story CSV**  
Save as: `data/story_metrics_gemma4.csv`

### 7.5 Save Console log for this step

Copy Console output → `data/gemma4_console_logs.txt`

Filter:
```bash
grep -E "parseResponse|Gemma|LlmInference|totalGenerationMs" \
  data/gemma4_console_logs.txt > data/gemma4_console_filtered.txt
```

Compute:
```bash
JSON_COUNT=$(grep -c "JSON path\|JSON parse success" data/gemma4_console_filtered.txt)
HEURISTIC_COUNT=$(grep -c "heuristic" data/gemma4_console_filtered.txt)
echo "JSON: $JSON_COUNT  Heuristic: $HEURISTIC_COUNT"
```

### 7.6 Verify zero network requests

Network tab: confirm no HTTP requests during story turns.

Record all findings in `[Google Drive]/results_template.md` → Step 7 section.

---

## Step 8 — Story Generation: Mode D — Hybrid

**Goal:** Cloud hit rate, source distribution per beat, behaviour under network degradation.  
**Duration:** ~55 minutes (3 network conditions).  
**Runs on:** Physical iPhone with varying network conditions.

### 8.1 Configure

- App → Settings → Story Mode: **Hybrid**
- Cloud Agent URL: set (same as Step 5.1)
- Both Gemma model ready AND Apple Intelligence on
- Xcode Console: attached and cleared
- Xcode Debug Navigator → **Network** tab: open

### 8.2 Session group 1 — Strong WiFi (2 sessions, ≥ 10 beats)

Normal home/office WiFi. Expect high cloud hit rate (cloud response arrives within the ~8s speak+listen window).

For each beat, Console will log:
```
BackgroundStoryEnhancer: cloud arrived=true/false
HybridBeatMetric: source=cloud/localGemma4/localOnDevice
```

### 8.3 Session group 2 — Throttled (2 sessions, ≥ 10 beats)

1. iOS Settings → Developer → **Network Link Conditioner** → Enable → Profile: **"3G"**
2. Run 2 sessions. Cloud responses will be slower; expect more local fallback beats.
3. After sessions: disable Network Link Conditioner.

### 8.4 Session group 3 — Airplane mode mid-session (1 session)

1. Start session normally (WiFi on) — complete 2 turns
2. Enable Airplane mode
3. Continue 2 more turns — local engine only
4. Re-enable WiFi
5. Continue to story end — cloud returns

Observe source switching in Console and Network tab.

### 8.5 Export both Hybrid CSVs

App → Settings → **Export Hybrid CSV**  
Save as: `data/hybrid_metrics.csv`

App → Settings → **Export Story CSV**  
Save as: `data/story_metrics_hybrid.csv`

Hybrid CSV expected columns:
```
turn, source, local_ms, cloud_ms, cloud_arrived, ending_by, timestamp
```

### 8.6 Compute hit rates per network condition

```bash
# Total cloud hit rate
awk -F',' 'NR>1 && $5=="true" {hits++} NR>1 {total++} END {print hits/total*100"%"}' \
  data/hybrid_metrics.csv
```

Or in Python (Step 12 analysis).

Record all findings in `[Google Drive]/results_template.md` → Step 8 section.

---

## Step 9 — VAD Layer Distribution Measurement

**Goal:** Quantify which VAD layer ends each turn and the latency cost of Layer 2.  
**Duration:** Logs collected passively during Steps 5–8; ~15 minutes to analyse.  
**Runs on:** Analysis on Mac from saved log files.

### 9.1 Extract VAD log lines from all mode logs

```bash
# Combine all Console logs into one VAD-specific file
grep -E "VAD layer|listenForAnswer|semanticTurnDetector" \
  data/ondevice_console_logs.txt \
  data/gemma4_console_logs.txt \
  > data/vad_console_logs.txt

# If you captured a combined log during cloud/hybrid sessions, include those too
```

### 9.2 Tally layer decisions

```bash
L1=$(grep -c "VAD layer1\|trailing phrase" data/vad_console_logs.txt)
L2=$(grep -c "VAD layer2\|semantic complete" data/vad_console_logs.txt)
L3=$(grep -c "VAD layer3\|hard cap" data/vad_console_logs.txt)
echo "Layer 1 (heuristic): $L1"
echo "Layer 2 (Apple FM semantic): $L2"
echo "Layer 3 (8s hard cap): $L3"
```

### 9.3 Extract Layer 2 latency

```bash
grep "semanticTurnDetector: result in" data/vad_console_logs.txt
# Expected format: "semanticTurnDetector: result in 147ms"
```

Compute mean from the extracted values. Document in the dissertation as the overhead cost of the semantic layer (~150 ms, per prior observations).

### 9.4 Mode breakdown table

| Mode | Layer 2 enabled | Expected dominant layer |
|------|----------------|------------------------|
| onDevice (Apple FM) | Yes | Layer 1 or Layer 2 |
| gemma4OnDevice | **No** (`skipSemanticLayer=true`) | Layer 1 or Layer 3 |
| cloud | Yes | Layer 1 or Layer 2 |
| hybrid | Yes | Layer 1 or Layer 2 |

Record tally in `[Google Drive]/results_template.md` → Step 9 section.

---

## Step 10 — Network Privacy Verification (Screenshot Evidence)

**Goal:** Visual proof that raw pixels and audio never leave the device.  
**Duration:** ~20 minutes (screenshots taken during Steps 5–8 sessions).  
**Runs on:** Physical iPhone + Xcode Network Inspector.

Screenshots should already be partially captured during Steps 5–8. Complete any missing ones here.

### 10.1 Cloud mode — ScenePayload content verification

1. App → Settings → Story Mode: **Cloud** → run one story beat
2. Xcode → Debug Navigator → **Network** → select POST to `/story/generate`
3. Click **Body** → verify JSON:

| Field | Expected content | Verify |
|-------|-----------------|--------|
| `objects` | `["teddy_bear", "book"]` (string array) | No binary data |
| `scene` | `["bedroom", "living_room"]` (string array) | No binary data |
| `transcript` | `"..."` or `null` (scrubbed string) | No audio bytes |
| No `image` / `jpeg` / `pixels` field | — | Absent |
| Content-Type header | `application/json` | Not multipart |
| Request body size | < 2 KB | No embedded media |

Screenshot → `data/screenshots/network_cloud_request.png`

### 10.2 On-device mode — zero network requests

1. App → Settings → Story Mode: **On-Device (Apple FM)** → run a full 5-turn session
2. Xcode → Debug Navigator → **Network** tab throughout the session
3. Verify: no outbound HTTP requests appear

Screenshot of empty network tab → `data/screenshots/network_ondevice_zero_requests.png`

### 10.3 Hybrid mode — enhance endpoint

1. App → Settings → Story Mode: **Hybrid** → run one story beat
2. Network tab: find POST to `/story/enhance` (or `/story/generate` if enhance returns 404)
3. Verify same privacy guarantees as 10.1

Screenshot → `data/screenshots/network_hybrid_enhance_request.png`

Record verification results in `[Google Drive]/results_template.md` → Step 10 section.

---

## Step 11 — End-to-End Round-Trip Latency

**Goal:** Total user-facing latency per turn in each mode.  
**Duration:** Derived from data already collected in Steps 2, 5–8. ~20 minutes analysis.  
**Runs on:** Mac (analysis of saved logs and CSVs).

### 11.1 Components of round-trip per turn

```
Total round-trip =
  Pipeline latency       (from Step 2 CSV, pipelineLatencyMs)
+ Generation latency     (from Steps 5–8 CSVs, totalGenerationMs)
+ TTS playback duration  (estimated from Console logs)
+ VAD listening window   (1.0 s min — 8.0 s max)
```

### 11.2 TTS duration from Console logs

```bash
grep "AudioService: willSpeak\|AudioService: didFinish" \
  data/ondevice_console_logs.txt | head -40
```

Calculate: `chars_in_beat / 14.8 chars_per_sec` (observed rate from OB-008).  
Or measure directly from timestamps between `willSpeak` and `didFinish` log lines.

### 11.3 Round-trip summary table

Compute mean values from CSVs, then fill:

| Component | Mode A Cloud | Mode B Apple FM | Mode C Gemma 3 1B | Mode D Hybrid |
|-----------|-------------|-----------------|-------------------|---------------|
| Pipeline (ms) | from Step 2 | from Step 2 | from Step 2 | from Step 2 |
| Generation (ms) | from CSV | from CSV | from CSV | from CSV |
| TTS (s) | calculated | calculated | calculated | calculated |
| VAD window (s) | 1.0–8.0 | 1.0–8.0 | 1.0–8.0 (no L2) | 1.0–8.0 |
| **Estimated total (s)** | sum | sum | sum | sum |

Record in `[Google Drive]/results_template.md` → Step 11 section.

---

## Step 12 — Statistical Analysis & Comparison Charts

**Goal:** Dissertation-quality statistics and visualisations from all collected CSVs.  
**Duration:** ~2 hours.  
**Runs on:** Mac (Python with pandas, scipy, matplotlib).

### 12.1 Setup

```bash
pip install pandas scipy matplotlib tabulate
```

### 12.2 Combine story metrics

```python
import pandas as pd

cloud  = pd.read_csv('data/story_metrics_cloud.csv')
device = pd.read_csv('data/story_metrics_ondevice.csv')
gemma  = pd.read_csv('data/story_metrics_gemma4.csv')
hybrid = pd.read_csv('data/story_metrics_hybrid.csv')

all_data = pd.concat([cloud, device, gemma, hybrid], ignore_index=True)
all_data['generationMode'] = all_data['generationMode'].astype('category')
```

### 12.3 Latency summary table (Table 6.X)

```python
summary = all_data.groupby('generationMode').agg(
    n              = ('totalGenerationMs', 'count'),
    mean_total     = ('totalGenerationMs', 'mean'),
    median_total   = ('totalGenerationMs', 'median'),
    std_total      = ('totalGenerationMs', 'std'),
    mean_ttft      = ('timeToFirstTokenMs', 'mean'),
    median_ttft    = ('timeToFirstTokenMs', 'median'),
    std_ttft       = ('timeToFirstTokenMs', 'std'),
    mean_turns     = ('turnCount', 'mean'),
).round(1)
print(summary.to_markdown())
```

### 12.4 Hybrid source breakdown (Table 6.Y)

```python
hybrid_raw = pd.read_csv('data/hybrid_metrics.csv')

print("Source distribution (%):")
print(hybrid_raw['source'].value_counts(normalize=True).mul(100).round(1))

print("\nCloud hit rate:",
      round((hybrid_raw['cloud_arrived'] == True).mean() * 100, 1), "%")
print("Mean local_ms:", round(hybrid_raw['local_ms'].mean(), 1))

arrived = hybrid_raw[hybrid_raw['cloud_arrived'] == True]
print("Mean cloud_ms (when arrived):", round(arrived['cloud_ms'].mean(), 1))

print("\nEnding source distribution (%):")
print(hybrid_raw['ending_by'].value_counts(normalize=True).mul(100).round(1))
```

### 12.5 Privacy pipeline summary (Table 6.Z)

```python
pipeline = pd.read_csv('data/privacy_pipeline_raw.csv')

stages = ['faceDetectMs','blurMs','yoloMs','sceneClassifyMs','sttMs','piiScrubMs','pipelineLatencyMs']
print(pipeline[stages].describe().loc[['mean','std','min','max']].round(1).to_markdown())

print("\nPrivacy violations (rawDataTransmitted=True):",
      int((pipeline['rawDataTransmitted'] == True).sum()))
print("Mean objects/frame:", round(pipeline['objectsDetected'].mean(), 1))
print("Total PII tokens scrubbed:", int(pipeline['tokensScrubbedFromTranscript'].sum()))
```

### 12.6 Statistical significance (Welch's t-test)

```python
from scipy import stats

pairs = [
    ('cloud', 'onDevice'),
    ('cloud', 'gemma4OnDevice'),
    ('onDevice', 'gemma4OnDevice'),
    ('hybrid', 'cloud'),
]

for a, b in pairs:
    ga = all_data[all_data['generationMode'] == a]['totalGenerationMs']
    gb = all_data[all_data['generationMode'] == b]['totalGenerationMs']
    t, p = stats.ttest_ind(ga, gb, equal_var=False)
    sig = "p<0.05 *" if p < 0.05 else "n.s."
    print(f"{a} vs {b}: t={t:.2f}, p={p:.4f}  {sig}")
```

Report format for dissertation: *"Welch's t-test, t(N) = X.XX, p < 0.05"*

### 12.7 Box plots (Figure 6.X)

```python
import matplotlib.pyplot as plt

mode_order = ['cloud', 'onDevice', 'gemma4OnDevice', 'hybrid']
labels = ['Cloud\n(Gemini)', 'Apple FM\n(On-Device)', 'Gemma 3 1B\n(On-Device)', 'Hybrid']

fig, axes = plt.subplots(1, 2, figsize=(12, 5))

for ax, col, title, ylabel in [
    (axes[0], 'totalGenerationMs', 'Total Generation Latency by Mode', 'Latency (ms)'),
    (axes[1], 'timeToFirstTokenMs', 'Time to First Token by Mode', 'TTFT (ms)'),
]:
    data_by_mode = [all_data[all_data['generationMode'] == m][col].dropna() for m in mode_order]
    ax.boxplot(data_by_mode, labels=labels)
    ax.set_title(title)
    ax.set_ylabel(ylabel)
    ax.grid(axis='y', linestyle='--', alpha=0.5)

plt.tight_layout()
plt.savefig('data/charts/latency_comparison.png', dpi=300)
print("Saved data/charts/latency_comparison.png")
```

### 12.8 Hybrid source pie chart (Figure 6.Y)

```python
source_counts = hybrid_raw['source'].value_counts()
plt.figure(figsize=(6, 6))
plt.pie(source_counts, labels=source_counts.index, autopct='%1.1f%%', startangle=90)
plt.title('Hybrid Mode — Beat Source Distribution')
plt.savefig('data/charts/hybrid_source_distribution.png', dpi=300)
```

---

## Step 13 — Story Quality Assessment (Qualitative)

**Goal:** Human-rated story quality across all four modes.  
**Duration:** ~60 minutes reviewing story transcripts.  
**Runs on:** App Story Timeline on device + manual scoring on paper/spreadsheet.

### 13.1 Access sessions from Timeline

App → Home → **Story Timeline** → select each session → view beat-by-beat conversation cards.

For each of the 5 sessions per mode (20 sessions total), read through and score on the rubric below.

### 13.2 Scoring rubric (Likert 1–5)

| Dimension | 1 — Poor | 3 — Adequate | 5 — Excellent |
|-----------|----------|-------------|---------------|
| Scene relevance | No scene elements in story | 1–2 mentions | Scene is central to the story |
| Child answer integration | Answer ignored | Answer acknowledged | Answer shapes the plot |
| Language age-appropriateness | Adult / technical vocabulary | Mixed | Child-friendly throughout |
| Story coherence | Disjointed beats | Mostly coherent | Satisfying narrative arc |
| Ending quality | Abrupt or missing | Reasonable conclusion | Natural, satisfying ending |

### 13.3 Record scores

Fill the scoring tables in `[Google Drive]/results_template.md` → Step 13 section.

Compare mean quality score per mode. Note whether:
- Cloud (Gemini) scores higher on coherence due to larger context window
- Gemma shows JSON parse fallback artefacts in story text
- Apple FM post-restart beats show continuity loss
- Hybrid beats sourced from cloud score differently than local-sourced beats

---

## Step 14 — Data File Checklist

Verify all files exist before beginning dissertation write-up:

```
data/
├── privacy_pipeline_raw.csv           # Step 2.3
├── pipeline_console_logs.txt          # Step 2.4
├── pipeline_console_filtered.txt      # Step 2.4
├── pii-tests-output.txt               # Step 3.1
├── story_metrics_cloud.csv            # Step 5.4
├── network_cloud_sessions.har         # Step 5.5
├── story_metrics_ondevice.csv         # Step 6.3
├── ondevice_console_logs.txt          # Step 6.4
├── ondevice_console_filtered.txt      # Step 6.4
├── story_metrics_gemma4.csv           # Step 7.4
├── gemma4_console_logs.txt            # Step 7.5
├── gemma4_console_filtered.txt        # Step 7.5
├── hybrid_metrics.csv                 # Step 8.5
├── story_metrics_hybrid.csv           # Step 8.5
├── vad_console_logs.txt               # Step 9.1
├── screenshots/
│   ├── network_cloud_request.png      # Step 10.1
│   ├── pii_network_request.png        # Step 3.3
│   ├── network_ondevice_zero_requests.png  # Step 10.2
│   └── network_hybrid_enhance_request.png  # Step 10.3
└── charts/
    ├── latency_comparison.png          # Step 12.7
    └── hybrid_source_distribution.png # Step 12.8

test-results/
├── run.xcresult                        # Step 1.1
├── run-summary.txt                     # Step 1.1
└── privacy-pipeline-tests.txt         # Step 1.4
```

---

## Step 15 — Update Documentation

After all data is collected:

### 15.1 Observations.md — add OB-014 onward

One entry per mode (OB-014 through OB-017), each containing:
- Device model, iOS version, app build, date
- Mean TTFT, mean generation time
- Notable events (restart, fallback, anomaly)

### 15.2 Regenerate TestCoverage.md

```bash
XCRESULT_PATH=test-results/run.xcresult ./export_test_results.sh
```

### 15.3 Pipeline.md — add §7 Empirical Results

New section with:
- Final per-stage latency figures from Step 2
- Cross-mode generation timing summary
- Privacy invariant proof statement (0 violations, 100 runs)

### 15.4 README.md — update Test Results table

Replace current values with final measured numbers from Step 1 and Steps 5–8.

---

## Cross-Mode Comparison Reference Table

Fill after Steps 5–13. Replace all TBD before dissertation submission.

| Metric | Mode A Cloud | Mode B Apple FM | Mode C Gemma 3 1B | Mode D Hybrid |
|--------|-------------|-----------------|-------------------|---------------|
| Network required | Yes | No | No | Conditional |
| Payload sent | ScenePayload JSON | None | None | ScenePayload JSON |
| Raw data transmitted | Never | Never | Never | Never |
| Mean TTFT (ms) | **TBD** | **TBD** | N/A | **TBD** |
| Mean total generation (ms) | **TBD** | **TBD** | **TBD** | **TBD** |
| Mean round-trip per turn (s) | **TBD** | **TBD** | **TBD** | **TBD** |
| VAD Layer 2 enabled | Yes | Yes | **No** | Yes |
| Context restart needed | No | Yes (~turn 5) | No | No |
| Model size on device | 0 MB | ~3 GB (Apple FM) | ~800 MB (GGUF) | ~3.8 GB total |
| Cold start penalty | ~30 s first call | No | No (post-download) | Mitigated by local |
| Story quality mean (/5) | **TBD** | **TBD** | **TBD** | **TBD** |
| Cloud hit rate | 100% | 0% | 0% | **TBD**% |
| JSON parse success rate | N/A | N/A | **TBD**% | N/A |
| Privacy risk | Low (labels only) | Zero | Zero | Low (labels only) |

---

## Appendix — Console Log Filter Quick Reference

Use in Xcode Console search bar or Console.app (Action → Search → Subsystem = `com.seesaw.companion`).

| What to find | Search string |
|-------------|---------------|
| All app logs | `com.seesaw.companion` |
| Pipeline total latency | `pipelineLatency` |
| Per-stage timings | `faceDetect` / `yoloMs` / `sceneClassify` / `piiScrub` |
| YOLO class detections + confidence | `conf=` |
| Story generation timing | `totalGenerationMs` |
| TTFT streaming anchor | `onPartialText` |
| Context restart event | `restartWithSummary` |
| VAD layer decisions | `VAD layer` |
| Layer 2 latency | `semanticTurnDetector` |
| Hybrid beat source | `HybridBeatMetric` / `BackgroundEnhancer` |
| PII scrubbing events | `PIIScrubber` / `tokensRedacted` |
| TTS start / end | `AudioService: willSpeak` / `didFinish` |
| Gemma parse path | `parseResponse` / `Gemma JSON` / `heuristic` |

---

## Estimated Time Budget

| Step | Activity | Time |
|------|----------|------|
| Prerequisites | Device setup + build | 15 min |
| 1 | Tests + coverage | 10 min |
| 2 | Pipeline benchmark (20 captures) | 25 min |
| 3 | PII tests + live speech | 20 min |
| 4 | YOLO detection scenes | 30 min |
| 5 | Cloud sessions (5×) | 35 min |
| 6 | Apple FM sessions (5×) | 50 min |
| 7 | Gemma sessions (5×) | 50 min |
| 8 | Hybrid sessions (5×, 3 conditions) | 55 min |
| 9 | VAD analysis from logs | 15 min |
| 10 | Network screenshots | 20 min |
| 11 | Round-trip analysis | 20 min |
| 12 | Python stats + charts | 2 hrs |
| 13 | Story quality scoring | 60 min |
| 14–15 | Doc updates | 30 min |
| **Total** | | **~8 hrs across multiple sessions** |

*Recommended sessions: Steps 1–4 in one sitting (~1.5 hrs). Steps 5–8 in one sitting (~3.5 hrs with device attached to Mac). Steps 9–15 on Mac after device testing is complete.*
