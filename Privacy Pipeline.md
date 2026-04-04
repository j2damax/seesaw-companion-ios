# Privacy Pipeline — Implementation Plan

> **Project:** seesaw-companion-ios (Tier 2)
> **Date:** 2026-04-04
> **Scope:** Tasks 1–8 covering privacy metrics, automated tests, face detection/blur, scene classification, PII scrubbing, JSON payload assembly, and pipeline benchmarking.

---

## Current State Assessment

| Task | Status | Notes |
|------|--------|-------|
| Task 3 — Face detection | ✅ Implemented | `PrivacyPipelineService.detectAndBlurFaces()` uses `VNDetectFaceRectanglesRequest` |
| Task 4 — Face blur | ✅ Implemented | `blurRegion()` applies `CIGaussianBlur` radius 30 via Core Image |
| Task 5 — Scene classification | ⚠️ Partial | `classifyScene()` uses `VNClassifyImageRequest` (confidence ≥ 0.3) but returns top 5 — task spec asks for top 3 |
| Task 6 — PII scrub | ⚠️ Partial | `scrubPII()` strips 7+ digit numbers and emails only — missing names, addresses, phone numbers |
| Task 7 — JSON payload | ⚠️ Partial | `ScenePayload` exists but lacks `session_id`, `query`, `timestamp` fields |
| Task 1 — Privacy metrics | ❌ Not started | No `PrivacyMetricsEvent`, no metrics collection, no CSV export |
| Task 2 — Privacy assertion test | ❌ Not started | No XCTest for privacy assertions |
| Task 8 — Benchmark | ❌ Not started | No per-stage timing or `os_signpost` instrumentation |

---

## Phase 1: Model Layer — New Types & Payload Enhancements

### 1a. Create `PrivacyMetricsEvent` (Task 1)

**File:** `SeeSaw/Model/PrivacyMetricsEvent.swift`

Define a pure struct (zero framework imports, per Model layer rules):

```swift
struct PrivacyMetricsEvent: Codable, Sendable {
    let facesDetected: Int
    let facesBlurred: Int
    let objectsDetected: Int
    let tokensScrubbedFromTranscript: Int
    let rawDataTransmitted: Bool  // must always be false
    let pipelineLatencyMs: Double

    // Per-stage breakdown (Task 8)
    let faceDetectMs: Double
    let blurMs: Double
    let yoloMs: Double
    let sceneClassifyMs: Double
    let sttMs: Double
    let piiScrubMs: Double
}
```

**Rationale:**
- `Codable` enables CSV/JSON export for dissertation evaluation.
- `Sendable` required by Swift 6 strict concurrency since it will be passed across actor boundaries.
- Per-stage fields support the benchmark requirement (Task 8).
- `rawDataTransmitted` is **always** `false` — enforced at construction time.

### 1b. Create `PipelineResult` struct

**File:** `SeeSaw/Model/PipelineResult.swift`

```swift
struct PipelineResult: Sendable {
    let payload: ScenePayload
    let metrics: PrivacyMetricsEvent
}
```

**Rationale:** The enhanced `process()` function returns both the cloud payload and metrics without modifying the privacy boundary of `ScenePayload`.

### 1c. Enhance `ScenePayload` (Task 7)

**File:** `SeeSaw/Model/ScenePayload.swift`

**Recommended approach:** Create a wrapper `StoryRequest` struct that adds `session_id`, `query`, and `timestamp` around the existing `ScenePayload` fields — preserving the clean 4-field privacy boundary.

```swift
struct StoryRequest: Codable, Sendable {
    let sessionId: String      // UUID v4
    let childAge: Int
    let objects: [String]
    let scene: [String]
    let query: String          // e.g. "tell me a story about the dog"
    let timestamp: String      // ISO 8601
}
```

**Decision point:** Whether to embed `ScenePayload` fields directly or reference the struct. Direct embedding is recommended for clean JSON serialisation matching the spec.

---

## Phase 2: PII Scrub Enhancement (Task 6)

**File:** `SeeSaw/Services/AI/PrivacyPipelineService.swift` — modify `scrubPII()`

### Current Implementation (lines 300–307)
Only strips:
- 7+ digit numbers (`\b\d{7,}\b`)
- Email addresses (`\S+@\S+\.\S+`)

### Enhanced Patterns to Add

| Pattern | Regex | Example Matches |
|---------|-------|-----------------|
| Phone numbers (US/UK) | `\b(\+?\d{1,3}[\s-]?)?\(?\d{2,4}\)?[\s.-]?\d{3,4}[\s.-]?\d{3,4}\b` | `+44 123 456 7890`, `(555) 123-4567` |
| Postcodes/ZIP codes | `\b[A-Z]{1,2}\d[A-Z\d]?\s*\d[A-Z]{2}\b` (UK), `\b\d{5}(-\d{4})?\b` (US) | `SW1A 1AA`, `90210` |
| "My name is X" patterns | `\b(my name is\|i'm called\|i am)\s+\w+\b` (case-insensitive) | `my name is Alice` |
| Street addresses | `\b\d+\s+[A-Z][a-z]+\s+(Street\|St\|Avenue\|Ave\|Road\|Rd\|Drive\|Dr\|Lane\|Ln\|Court\|Ct)\b` | `42 Oak Street` |

### Return Type Change

```swift
// Before:
private func scrubPII(_ text: String) -> String

// After:
private func scrubPII(_ text: String) -> (scrubbed: String, tokensRedacted: Int)
```

Count tokens redacted by incrementing a counter each time a pattern match is replaced with `[REDACTED]`. This feeds into `PrivacyMetricsEvent.tokensScrubbedFromTranscript`.

**Approach:** Conservative scrubbing recommended — only scrub explicit PII patterns to avoid over-redacting valid story content (e.g., "the Castle was big" should NOT redact "Castle").

---

## Phase 3: Pipeline Instrumentation (Tasks 1 & 8)

### 3a. Add Per-Stage Timing

**File:** `SeeSaw/Services/AI/PrivacyPipelineService.swift` — modify `process()`

Wrap each stage with `CFAbsoluteTimeGetCurrent()`:

```swift
func process(jpegData: Data, childAge: Int) async throws -> PipelineResult {
    let pipelineStart = CFAbsoluteTimeGetCurrent()

    // Stage 1+2: Face detect + blur
    let faceStart = CFAbsoluteTimeGetCurrent()
    let (blurredImage, faceCount) = try detectAndBlurFaces(in: ciImage)
    let faceEnd = CFAbsoluteTimeGetCurrent()

    // Stage 3: YOLO object detection
    let yoloStart = CFAbsoluteTimeGetCurrent()
    let objects = try await detectObjects(in: blurredImage)
    let yoloEnd = CFAbsoluteTimeGetCurrent()

    // ... etc for each stage

    let metrics = PrivacyMetricsEvent(
        facesDetected: faceCount,
        facesBlurred: faceCount,  // all detected faces are always blurred
        objectsDetected: objects.count,
        tokensScrubbedFromTranscript: scrubResult.tokensRedacted,
        rawDataTransmitted: false,
        pipelineLatencyMs: (pipelineEnd - pipelineStart) * 1000,
        faceDetectMs: ...,
        // ...
    )

    return PipelineResult(payload: payload, metrics: metrics)
}
```

**Key invariant:** `facesBlurred` always equals `facesDetected` — every detected face is blurred before any other analysis runs.

### 3b. Modify `detectAndBlurFaces` Return Type

```swift
// Before:
private func detectAndBlurFaces(in image: CIImage) throws -> CIImage

// After:
private func detectAndBlurFaces(in image: CIImage) throws -> (image: CIImage, faceCount: Int)
```

Return the face count alongside the blurred image so metrics can capture it without a separate Vision call.

### 3c. Add `os_signpost` Instrumentation (Task 8)

```swift
import os

private static let signpostLog = OSLog(subsystem: "com.seesaw.companion", category: "PrivacyPipeline")

// In process():
let signpostID = OSSignpostID(log: Self.signpostLog)
os_signpost(.begin, log: Self.signpostLog, name: "FaceDetection", signpostID: signpostID)
// ... stage work ...
os_signpost(.end, log: Self.signpostLog, name: "FaceDetection", signpostID: signpostID)
```

This enables visibility in Xcode Instruments (Time Profiler + Core ML Instrument) per the Task 8 specification.

### 3d. Log Per-Stage Breakdown

After each pipeline run:
```
Pipeline benchmark: faceDetect=45ms, blur=12ms, yolo=320ms, scene=85ms, stt=150ms, piiScrub=2ms, total=614ms
```

---

## Phase 4: In-Memory Metrics Store (Task 1)

### Create `PrivacyMetricsStore`

**File:** `SeeSaw/Services/AI/PrivacyMetricsStore.swift`

```swift
actor PrivacyMetricsStore {

    private var events: [PrivacyMetricsEvent] = []

    func record(_ event: PrivacyMetricsEvent) {
        events.append(event)
    }

    func allEvents() -> [PrivacyMetricsEvent] {
        events
    }

    func exportCSV() -> String {
        var csv = "facesDetected,facesBlurred,objectsDetected,tokensScrubbedFromTranscript,rawDataTransmitted,pipelineLatencyMs,faceDetectMs,blurMs,yoloMs,sceneClassifyMs,sttMs,piiScrubMs\n"
        for e in events {
            csv += "\(e.facesDetected),\(e.facesBlurred),\(e.objectsDetected),\(e.tokensScrubbedFromTranscript),\(e.rawDataTransmitted),\(e.pipelineLatencyMs),\(e.faceDetectMs),\(e.blurMs),\(e.yoloMs),\(e.sceneClassifyMs),\(e.sttMs),\(e.piiScrubMs)\n"
        }
        return csv
    }

    func averageLatency() -> Double {
        guard !events.isEmpty else { return 0 }
        return events.map(\.pipelineLatencyMs).reduce(0, +) / Double(events.count)
    }
}
```

**Registration:** Add to `AppDependencyContainer.init()` and inject into `CompanionViewModel`.

---

## Phase 5: Scene Classification Adjustment (Task 5)

**File:** `SeeSaw/Services/AI/PrivacyPipelineService.swift` — modify `classifyScene()`

Change `.prefix(5)` to `.prefix(3)` to match the task spec:

```swift
// Before:
.prefix(5)

// After:
.prefix(3)
```

This limits output to the top 3 scene category labels with confidence > 0.3.

---

## Phase 6: Automated Privacy Assertion Test (Tasks 2 & 7)

### 6a. Create XCTest File

**File:** `SeeSawTests/PrivacyPipelineTests.swift`

Uses XCTest (as explicitly required by the task for dissertation evidence). XCTest and Swift Testing coexist in the same test target.

### 6b. Test Cases

#### `testPrivacyPipelineNeverTransmitsRawData`
```swift
func testPrivacyPipelineNeverTransmitsRawData() async throws {
    let pipeline = PrivacyPipelineService()
    let testImage = loadTestFaceImage()  // JPEG with known face

    let result = try await pipeline.process(jpegData: testImage, childAge: 5)

    // 1. rawDataTransmitted must be false
    XCTAssertFalse(result.metrics.rawDataTransmitted)

    // 2. JSON output contains zero raw pixel data
    let json = try JSONEncoder().encode(result.payload)
    let jsonString = String(data: json, encoding: .utf8)!
    XCTAssertFalse(jsonString.contains("base64"))
    XCTAssertFalse(jsonString.contains("data:image"))

    // 3. JSON output contains zero face bounding box data
    XCTAssertFalse(jsonString.contains("boundingBox"))
    XCTAssertFalse(jsonString.contains("faceRect"))

    // 4. All detected faces were blurred before object detection
    XCTAssertEqual(result.metrics.facesDetected, result.metrics.facesBlurred)
}
```

#### `testPIIScrubRemovesKnownPatterns`
```swift
func testPIIScrubRemovesKnownPatterns() async throws {
    // Test with known PII content
    let input = "My name is Alice and my number is 07700900123"
    // Pass through pipeline with mocked transcript
    // Assert [REDACTED] replacements and tokensScrubbedFromTranscript > 0
}
```

#### `testScenePayloadContainsOnlyLabels`
```swift
func testScenePayloadContainsOnlyLabels() async throws {
    let payload = ScenePayload(objects: ["ball", "dog"], scene: ["outdoor"], transcript: "hello", childAge: 5)
    let data = try JSONEncoder().encode(payload)
    let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

    // Assert only expected keys exist
    let allowedKeys: Set<String> = ["objects", "scene", "transcript", "childAge"]
    XCTAssertEqual(Set(dict.keys), allowedKeys)

    // Assert no Data-type values
    for value in dict.values {
        XCTAssertFalse(value is Data)
    }
}
```

#### `testPrivacySanitisationRate`
```swift
func testPrivacySanitisationRate() async throws {
    // Run pipeline N times (e.g., 100) with face-containing images
    // Assert rawDataTransmitted == false for ALL runs (100% pass rate)
    // This satisfies the dissertation's >99% privacy sanitisation rate target
}
```

### 6c. Test Image Strategy

**Options (in order of preference):**
1. **Existing `test1` asset** — verify if it contains a face; if so, use it directly
2. **Synthetic JPEG with face** — generate programmatically using Core Graphics (circle + features approximating a face — however `VNDetectFaceRectanglesRequest` needs realistic features)
3. **Creative Commons face image** — add a small CC0-licensed face JPEG to the test bundle
4. **Mock the face detection layer** — create a protocol for the Vision stage and inject a mock that returns known face bounding boxes in tests

**Recommended:** Option 4 (mock) for CI reliability + Option 1/3 for integration tests on device.

### 6d. Test Limitations & Mitigations

| Concern | Mitigation |
|---------|------------|
| `VNDetectFaceRectanglesRequest` needs realistic face | Use mock for CI; real image for device integration test |
| `SFSpeechRecognizer` requires device auth | Skip STT stage in unit tests; test PII scrub independently |
| YOLO model pipeline is known broken | Tests handle graceful fallback (empty object list) |
| CI simulator lacks ML capabilities | Mark hardware-dependent tests with `@available` or skip conditions |

---

## Phase 7: Integration — Wire Everything Together

### 7a. Update `AppDependencyContainer`

```swift
// Add property:
let privacyMetricsStore: PrivacyMetricsStore

// In init():
privacyMetricsStore = PrivacyMetricsStore()

// Pass to CompanionViewModel:
func makeCompanionViewModel() -> CompanionViewModel {
    CompanionViewModel(
        accessoryManager: accessoryManager,
        privacyPipeline: privacyPipelineService,
        cloudService: cloudAgentService,
        audioService: audioService,
        metricsStore: privacyMetricsStore
    )
}
```

### 7b. Update `CompanionViewModel.runFullPipeline()`

```swift
private func runFullPipeline(jpegData: Data) async {
    do {
        sessionState = .processingPrivacy
        let result = try await privacyPipeline.process(jpegData: jpegData, childAge: childAge)

        // Record privacy metrics
        await metricsStore.record(result.metrics)

        sessionState = .requestingStory
        let story = try await cloudService.requestStory(payload: result.payload)
        // ... rest unchanged
    } catch {
        setError(error.localizedDescription)
    }
}
```

### 7c. Optional: CSV Export UI

In `SettingsView`, add a minimal "Export Privacy Metrics" button:
- Calls `metricsStore.exportCSV()`
- Presents via `ShareLink` or copies to clipboard
- PoC scope — no visual polish

---

## Files Summary

### Files to Create

| File | Purpose |
|------|---------|
| `SeeSaw/Model/PrivacyMetricsEvent.swift` | Metrics event struct (Task 1) |
| `SeeSaw/Model/PipelineResult.swift` | Combined payload + metrics return type |
| `SeeSaw/Model/StoryRequest.swift` | Enhanced JSON payload with session_id/query/timestamp (Task 7) |
| `SeeSaw/Services/AI/PrivacyMetricsStore.swift` | In-memory metrics array + CSV export (Task 1) |
| `SeeSawTests/PrivacyPipelineTests.swift` | XCTest privacy assertion suite (Task 2) |

### Files to Modify

| File | Change |
|------|--------|
| `SeeSaw/Services/AI/PrivacyPipelineService.swift` | Add timing instrumentation, enhance PII scrub, return `PipelineResult`, change scene prefix to 3, add `os_signpost` |
| `SeeSaw/App/AppDependencyContainer.swift` | Add `PrivacyMetricsStore` singleton |
| `SeeSaw/ViewModel/CompanionViewModel.swift` | Accept `metricsStore`, record metrics after pipeline runs |
| `SeeSaw/View/SettingsView.swift` | Optional: CSV export button |

**Note:** Due to `PBXFileSystemSynchronizedRootGroup`, new Swift files added to `SeeSaw/` subdirectories are auto-included in the Xcode build — no `project.pbxproj` changes required.

---

## Dependency Order

```
Phase 1 (Model types) ─┬─► Phase 2 (PII scrub)
                        ├─► Phase 3 (Instrumentation)
                        └─► Phase 5 (Scene classification)
                                    │
                                    ▼
                            Phase 4 (Metrics store)
                                    │
                                    ▼
                            Phase 6 (Tests)
                                    │
                                    ▼
                            Phase 7 (Integration)
```

Phases 1–3 and 5 can be developed in parallel. Phase 6 depends on Phases 1–5. Phase 7 integrates everything.

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| YOLO model NMS pipeline broken (80 vs 44 classes) | Object detection returns empty | Graceful fallback already in place; tests assert `objectsDetected >= 0` not `> 0` |
| `VNDetectFaceRectanglesRequest` needs real face in tests | Test may not trigger face detection | Mock Vision layer for CI; use real image on device |
| `SFSpeechRecognizer` needs device auth | STT stage returns nil in tests | Test PII scrub independently; STT stub returns nil |
| Simulator lacks Core ML acceleration | Benchmark numbers not representative | Run benchmarks on device only; CI tests verify correctness not performance |
| Over-aggressive PII scrubbing | Valid story words redacted | Use conservative regex patterns; test with diverse inputs |

---

## Performance Targets

| Metric | Target | Measurement Method |
|--------|--------|--------------------|
| Full pipeline latency | < 700 ms (iPhone 12) | `CFAbsoluteTimeGetCurrent()` + `os_signpost` |
| Face detection | < 50 ms | Per-stage timing |
| Face blur | < 20 ms | Per-stage timing |
| YOLO object detection | < 350 ms | Per-stage timing |
| Scene classification | < 100 ms | Per-stage timing |
| STT | < 150 ms | Per-stage timing |
| PII scrub | < 5 ms | Per-stage timing |
| Privacy sanitisation rate | > 99% (100% target) | `rawDataTransmitted == false` for all events |

---

## Open Questions

1. **Test image:** Does the existing `test1` asset contain a human face? If not, what face image should be used for the privacy assertion test?

2. **ScenePayload extension:** Should `session_id`, `query`, `timestamp` be added to `ScenePayload` directly (breaking the 4-field privacy boundary) or kept in a separate `StoryRequest` wrapper?

3. **PII scrub aggressiveness:** Conservative (only explicit "My name is X" patterns) or aggressive (any capitalised non-common-noun)?

4. **XCTest vs Swift Testing:** Task 2 specifies XCTest; existing tests use Swift Testing. Confirm XCTest is preferred for the privacy tests (both frameworks coexist).

5. **CSV export UI:** Should a button be added to SettingsView, or is programmatic-only access (via tests/debugger) sufficient?

6. **Signpost hooks:** Add `os_signpost` for Instruments visibility in addition to the programmatic `CFAbsoluteTimeGetCurrent()` timing?
