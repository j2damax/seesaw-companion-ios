# Appendix E — iOS Companion App: Screen Reference

**Device:** iPhone (iOS 26, TestFlight build 1.0 PoC)  
**Screenshots captured:** 24 April 2026  
**Source files:** `data/screensshots/`

This appendix provides an annotated screen-by-screen walkthrough of the SeeSaw Companion iOS app in the order a parent and child would encounter them during a story session. All screenshots are taken from a live device running the TestFlight beta build. No personal data is visible; the child's name ("Vihas") is the research participant identifier used throughout the evaluation.

---

## E.1 Authentication

### Figure E.1 — Launch and Sign-In Screen

`[INSERT: IMG_0355 2.PNG]`

The launch screen presents the SeeSaw logo (blue eye icon) and the tagline "AI Storytelling for Children." Parents authenticate using Sign in with Apple or Sign in with Google. A prominent note at the foot of the screen reads *"Parent sign-in only. Children do not interact with this screen,"* reinforcing the child-safety design intent. Authentication is required only once; subsequent launches bypass this screen and proceed directly to the Camera tab.

---

## E.2 Camera and Scene Capture

### Figure E.2 — Camera Tab: Connected State

`[INSERT: IMG_0353 2.PNG]`

The Camera tab is the app's primary interaction surface. A live viewfinder fills the upper portion of the screen. When the selected input source (here, iPhone Camera + Mic) is active, a green "Connected" badge overlays the viewfinder. Two actions are available: **Capture Scene** begins the privacy pipeline, and **Disconnect** releases the camera session. The gear icon (top-right) provides a shortcut to Settings. The three-tab navigation bar (Camera · Timeline · Settings) is visible throughout the app.

---

### Figure E.3 — Object Detection: Toy Scene

`[INSERT: IMG_0310 2.PNG]`

After the parent taps **Capture Scene**, the privacy pipeline runs in under 170 ms and returns the YOLO detection overlay. Green bounding boxes are drawn over detected objects, each labelled with the YOLO class name and confidence score. In this example the model detects three toy cars (90 %, 62 %, 98 %) and a toy airplane on a desk. Detection chip labels appear as a scrollable row below the viewfinder. The **Generate Story** button (teal, bottom) is enabled once at least one object has been detected. No raw pixel data leaves this stage; only the label strings are forwarded to story generation.

---

### Figure E.4 — Object Detection: Indoor Scene

`[INSERT: IMG_0354 2.PNG]`

A second example of the detection overlay in a different environment — a staircase and window area of a home. The model identifies two windows (93 %, 92 %) and a potted plant with bounding boxes. This screenshot demonstrates the app's scene-grounding capability across everyday child environments, not only toy-specific contexts. The same **Generate Story** call-to-action is shown at the bottom.

---

## E.3 Settings

### Figure E.5 — Settings: Story Engine Selection

`[INSERT: IMG_0346 2.PNG]`

The Settings tab is divided into three sections. The **Story Engine** section exposes the generation mode picker. In this screenshot, *On-Device (Apple FM)* is selected — the annotation confirms "Apple Foundation Models. Maximum privacy, no download needed." The **Input Source** section lists four hardware backends: iPhone Camera + Mic (active, shown with a tick), AiSee (BLE), Meta Glass, and MFi Camera Accessory. A **Save** button (top-right) commits changes.

---

### Figure E.6 — Settings: Story Engine Dropdown

`[INSERT: IMG_0347 2.PNG]`

Tapping the Engine picker reveals all four story generation modes as a native iOS selection menu:

| Mode | Description |
|------|-------------|
| On-Device (Apple FM) ✓ | Apple Foundation Models — zero network, currently selected |
| On-Device (Gemma 4) | MediaPipe Gemma 3 1B Q8_0 — requires one-time model download |
| Cloud | POST to Google Cloud Run — requires network |
| Hybrid | On-device first, cloud enhancement if network available |

The mode hierarchy maps directly to the privacy guarantee spectrum described in Chapter 7.

---

### Figure E.7 — Settings: Child Preferences

`[INSERT: IMG_0348 2.PNG]`

Scrolling below the Input Source section reveals **Child Preferences**. The parent enters the child's first name and age (used to calibrate story vocabulary and complexity) and selects up to six favourite topics from a predefined grid: Dinosaurs, Space, Fairy Tales, Animals, Superheroes, Ocean, Robots, Nature. Selected topics (highlighted in teal, here "Nature") bias the story prompt toward interests the child finds engaging. This data is stored on-device only in `UserDefaults` and is never transmitted.

---

### Figure E.8 — Settings: Export and About

`[INSERT: IMG_0356 2.PNG]`

The lower portion of Settings provides research instrumentation controls. The **Export All Data** button triggers a share sheet delivering four CSV files (privacy_metrics.csv, story_metrics.csv, hybrid_metrics.csv, story_ratings.csv) directly from the device, with no intermediary server. An aggregated ratings summary (Sessions Rated, Avg Enjoyment, Avg Age-Appropriate, Avg Scene Match) is shown above the export button, and the **About** section confirms Version 1.0 PoC and Privacy: On-device only.

---

## E.4 Story Timeline

### Figure E.9 — Timeline: Session History

`[INSERT: IMG_0349 2.PNG]`

The Timeline tab presents a chronological log of all story sessions. Each entry shows the child's name and age, timestamp, the opening line of the story (providing a memory cue for the child), beat count, and the generation mode used. In this example: *"You wander through the woods, enjoying the cool breeze and the sounds of nature."* — 1 beat, onDevice. Tapping any entry opens the full Session Detail view (Figures E.10–E.12). A **Delete All** button allows the parent to clear the local history at any time.

---

## E.5 Story Session Detail

### Figure E.10 — Session Detail: Overview and Scene Comparison

`[INSERT: IMG_0350 2.PNG]`

The Session Detail view is the app's research transparency screen. At the top, two stacked image frames are shown side by side: **Original scene** (raw camera frame before processing) and **Privacy-filtered scene** (the same frame after face blurring, shown for visual confirmation that no faces are visible). Below, an **Overview** card summarises the session metadata: child name, date, story mode, beat count, and completion status.

---

### Figure E.11 — Session Detail: Privacy Pipeline Metrics

`[INSERT: IMG_0351 2.PNG]`

The **Privacy Pipeline** card provides a complete audit of every stage in the six-stage pipeline for this session:

| Field | Value |
|-------|-------|
| Objects detected | None (scene-only labels used) |
| Scene labels | structure, wood_processed, furniture |
| Faces detected | 0 |
| Faces blurred | 0 |
| **Raw data transmitted** | **No ✓** |
| Face detect | 10 ms |
| Face blur | 6 ms |
| YOLO detect | 149 ms |
| Scene classify | 149 ms |
| PII scrub | 0 ms |
| **Total pipeline** | **169 ms** |
| PII tokens redacted | 0 — no PII detected |

The green "No ✓" next to Raw data transmitted is the per-session privacy compliance indicator. Below the pipeline card, the **Story Conversation** card renders the full exchange: Opening generation latency (4,192 ms, TTFT 3,538 ms), narration text, and the follow-up question posed to the child.

---

### Figure E.12 — Session Detail: Research Metrics

`[INSERT: IMG_0352 2.PNG]`

The **Research Metrics** card (visible by scrolling) aggregates performance indicators across the session for dissertation benchmarking:

| Metric | Value |
|--------|-------|
| Avg generation time | 4,192 ms |
| TTFT (initial beat) | 3,538 ms |
| Total beats | 1 |
| Context restarts | 0 |
| PII events | 0 token(s) redacted |

These values are the source data for the latency analysis reported in Chapter 9. The complete dataset across 86 sessions is provided in Appendix D.

---

## E.6 Summary of App Screens

| Figure | Screenshot file | Screen / Feature |
|--------|----------------|-----------------|
| E.1 | IMG_0355 2.PNG | Launch & Sign-In |
| E.2 | IMG_0353 2.PNG | Camera Tab — Connected state |
| E.3 | IMG_0310 2.PNG | YOLO detection — toy scene |
| E.4 | IMG_0354 2.PNG | YOLO detection — indoor scene |
| E.5 | IMG_0346 2.PNG | Settings — Story Engine (Apple FM selected) |
| E.6 | IMG_0347 2.PNG | Settings — Engine mode dropdown (all 4 modes) |
| E.7 | IMG_0348 2.PNG | Settings — Child Preferences |
| E.8 | IMG_0356 2.PNG | Settings — Export All Data / About |
| E.9 | IMG_0349 2.PNG | Timeline — Session history |
| E.10 | IMG_0350 2.PNG | Session Detail — Overview + scene comparison |
| E.11 | IMG_0351 2.PNG | Session Detail — Privacy Pipeline metrics |
| E.12 | IMG_0352 2.PNG | Session Detail — Research Metrics |

All screenshots were captured on a physical device running iOS 26 with TestFlight build 1.0 PoC (commit `ff5781d`). No simulator images are used in this appendix.
