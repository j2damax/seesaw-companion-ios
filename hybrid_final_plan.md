# Hybrid Mode v2 — Final Implementation Plan

**Evaluator:** Independent review of `Hybrid Mode.md` against actual codebase state.  
**Date:** 2026-04-16  
**Branch:** `hybrid-mode`

---

## Critical Evaluation Summary

The `Hybrid Mode.md` document is architecturally sound. The dual-agent design (local foreground + background cloud) is the right approach for child-latency requirements. However, one **critical bug** and two **compilation blockers** must be fixed before implementation. The rest is largely correct and should be followed as written.

---

## Bug Analysis

### BUG-1 (Critical): `consumeEnhancedBeat` — `withTaskGroup` does NOT enforce the 1s deadline

**The plan proposes:**
```swift
return await withTaskGroup(of: (StoryBeat, Double)?.self) { group in
    group.addTask { await task.value }
    group.addTask { try? await Task.sleep(for: deadline); return nil }
    let result = await group.next() ?? nil
    group.cancelAll()
    if result != nil { pendingTask = nil; cachedResult = nil }
    return result
}
```

**Why this is wrong:** Swift's `withTaskGroup` *implicitly awaits all child tasks before returning*, even after `group.cancelAll()` is called. Cancellation in Swift is cooperative — `await task.value` (where `task` is an unstructured `Task<_, Never>`) does NOT check for cancellation and will not interrupt. So if the cloud task takes 60s, `consumeEnhancedBeat` blocks for 60s, defeating the 1s deadline entirely.

**Verdict:** This breaks the "never blocks the child" guarantee and is the most critical correctness issue.

**Fix — polling approach (correct, simple, low overhead):**
```swift
func consumeEnhancedBeat(deadline: Duration = .seconds(1)) async -> (StoryBeat, Double)? {
    // Fast path: cloud already completed while child was answering
    if let cached = cachedResult {
        let result = cached; cachedResult = nil; pendingTask = nil; return result
    }
    guard pendingTask != nil else { return nil }

    // Poll every 50ms for up to `deadline`. The unstructured pendingTask
    // continues running — if it wins between polls, cachedResult is set.
    // Maximum extra wait: 50ms beyond deadline. Acceptable.
    let pollInterval = Duration.milliseconds(50)
    var remaining = deadline
    while remaining > .zero {
        try? await Task.sleep(for: min(pollInterval, remaining))
        remaining -= pollInterval
        if let cached = cachedResult {
            let result = cached; cachedResult = nil; pendingTask = nil; return result
        }
    }
    // Cloud didn't respond in time. Leave pendingTask running —
    // it will call setCached() when it finishes, seeding the next turn.
    return nil
}
```

**Why polling works here:** 20 iterations × 50ms = 1s max. If cloud responds in 100ms, we return in ≤150ms. The unstructured `pendingTask` continues concurrently and populates `cachedResult` for the next turn's fast path. No blocking.

---

### BUG-2 (Compilation blocker): `StoryBeat` is not explicitly `Codable`

**The plan assumes:** "`StoryBeat` is already `Codable` via `@Generable`"

**Actual codebase:** `StoryBeat.swift` is annotated `@Generable` only. `@Generable` synthesises Foundation Models structured-output conformance. Whether it also synthesises `Codable` depends on the macro implementation, which is not guaranteed to be stable across Xcode versions.

**Impact:** `EnhancementRequest: Codable` embeds `baseBeat: StoryBeat`. If `StoryBeat` is not `Codable`, this fails to compile.

**Fix — add explicit conformance in a new file (avoids touching StoryBeat.swift):**
```swift
// StoryBeatCodable.swift — manual Codable for network use
extension StoryBeat: Codable {
    enum CodingKeys: String, CodingKey {
        case storyText = "story_text"
        case question
        case isEnding  = "is_ending"
    }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        storyText = try c.decode(String.self, forKey: .storyText)
        question  = try c.decode(String.self, forKey: .question)
        isEnding  = try c.decode(Bool.self,   forKey: .isEnding)
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(storyText, forKey: .storyText)
        try c.encode(question,  forKey: .question)
        try c.encode(isEnding,  forKey: .isEnding)
    }
}
```

**Note:** If Xcode confirms `@Generable` already synthesises `Codable` (no compile error without this file), skip it. Add it only if needed.

---

### BUG-3 (Compilation blocker): 404 fallback — `StoryResponse` ≠ `StoryBeat`

**The plan says:** "stub via `/story/generate` with `childAnswer` appended to `storyHistory`"

**Actual codebase:** `CloudAgentService.requestStory()` returns `StoryResponse`, not `StoryBeat`. `StoryResponse` has `storyText`, `question`, `isEnding`, `sessionId`, `beatIndex`. The `requestEnhancement()` method must return `StoryBeat`.

**Fix — explicit conversion in the fallback path inside `requestEnhancement()`:**
```swift
// Inside the 404 fallback branch:
let payloadWithHistory = ScenePayload(
    objects: payload.objects,
    scene: payload.scene,
    transcript: payload.transcript,
    childAge: payload.childAge,
    childName: payload.childName,
    sessionId: payload.sessionId,
    storyHistory: storyHistory  // pass accumulated history
)
let response = try await requestStory(payload: payloadWithHistory)
return StoryBeat(
    storyText: response.storyText,
    question:  response.question,
    isEnding:  response.isEnding
)
```

**Why `transcript` is not overloaded with childAnswer:** Correct per the plan — `transcript` means PII-scrubbed ambient speech. The child's answer goes into `storyHistory`, which `ScenePayload` already has as a field.

---

## Decisions Confirmed Correct

### ✓ Dual-Agent Architecture

Foreground local Gemma4 generates the base beat in <3s. Background cloud runs concurrently during speak+listen dead time (8–15s). If cloud wins, child gets a richer beat; if cloud loses, local fills in instantly. This is the right design. No alternatives needed.

### ✓ `withTaskGroup` → polling for `consumeEnhancedBeat` (above) but the rest of BackgroundStoryEnhancer is correct

- `cachedResult` for late-arriving cloud beats: correct, seeds the next turn's fast path.
- `storyHistory` tracked inside the actor, not passed from ViewModel: correct — keeps ViewModel clean.
- History appended before firing the Task: correct ordering (model beat, then child answer).
- Cloud errors logged at `.warning` then discarded: correct.
- `reset()` cancels task and clears history: correct — called at session end.

### ✓ `resolveHybridLocalService()` once per session

Checking `Gemma4StoryService.currentModelState()` once avoids repeated async state checks per turn. Returning `skipSemantic: true` for Gemma4 matches the existing `continueGemma4Loop` pattern (Apple FM unavailable in that context — calling it causes ~8s hang). This is correct.

### ✓ Non-lazy stored properties

`lazy var` on `@MainActor` classes has thread-safety implications in Swift concurrency. `hybridMetricsStore` and `backgroundEnhancer` must be non-lazy stored properties initialized in `init()`. Correct.

### ✓ `beginStorySession` call

The current `runHybridPipeline` (lines 815–845) does **not** call `beginStorySession`. The plan adds it. This is correct — without it, `recordBeat` silently no-ops (it guards on `currentSession`). Confirmed by reading `recordBeat()` at line 1031.

### ✓ `localService.endSession()` call

The plan calls `await localService.endSession()` before `finalizeCurrentSession()`. This is correct — matches `continueGemma4Loop` and `continueStoryLoop` patterns which both call their respective service's `endSession()`.

### ✓ `StoryBeat.safeFallback` for `continueTurn` failure

`beat = (try? await localService.continueTurn(childAnswer: answer)) ?? .safeFallback` — correct. Never throws to the user.

### ✓ HybridSource enum — 3 cases only

`.cloud`, `.localGemma4`, `.localOnDevice`. The source of truth check `localService is Gemma4StoryService` is the correct runtime type test. No `.localGemma4orOnDevice` combo case. Correct.

### ✓ `EnhancementRequest` separate from `ScenePayload`

`ScenePayload` is the privacy-boundary struct. `EnhancementRequest` adds cloud-only fields (`baseBeat`, `childAnswer`, `maxTurns`) that are irrelevant to the privacy pipeline. Keeping them separate is architecturally correct.

### ✓ `childAge`/`childName` sourced from `ScenePayload`

`ScenePayload` already carries `childAge` and `childName`. In `requestEnhancement()` inside `CloudAgentService`, populate the `EnhancementRequest` from `payload.childAge` and `payload.childName`. Avoids redundant parameter threading.

### ✓ `maxTurns` constant

Gemma4StoryService has `private let maxTurns = 6`. Mirror this as a constant `let maxTurns = 6` inside `requestEnhancement()`. Do not expose it through a protocol change.

### ✓ `HybridMetricsStore` pattern

Follow `StoryMetricsStore.swift` exactly: actor, `private var metrics: [HybridBeatMetric] = []`, same query-method pattern. Does not modify `StoryMetricsEvent` — no existing test breakage.

### ✓ `AppDependencyContainer` change

Add `let hybridMetricsStore = HybridMetricsStore()` and pass to `CompanionViewModel.init()` as a new parameter. The plan correctly identifies this as a non-lazy dependency. The `makeCompanionViewModel()` factory method is the only call site.

---

## Deferred Items — Confirmed Out of Scope

| Item | Why deferred |
|------|-------------|
| Real `/story/enhance` endpoint | 404 fallback is sufficient to prove the architecture for Chapter 6 |
| Streaming in hybrid | `any StoryGenerating` protocol loses `streamStartStory`; TTFT regression on beat 0 accepted |
| `NarrativeHints` + local prompt seeding | Requires real `/story/enhance` first |
| Emotion-adaptive features | `VNDetectFaceExpressionsRequest` does not exist on iOS; would need `VNDetectFaceLandmarksRequest` |
| `ScenePayload` re-capture per turn | Known limitation; noted in dissertation |

---

## Files to Create

| File | Notes |
|------|-------|
| `SeeSaw/Model/HybridBeatMetric.swift` | `HybridSource`, `EndingSource`, `HybridBeatMetric` — as specified |
| `SeeSaw/Services/AI/HybridMetricsStore.swift` | Actor, follows `StoryMetricsStore` pattern |
| `SeeSaw/Services/AI/BackgroundStoryEnhancer.swift` | Actor — use polling fix for `consumeEnhancedBeat` |
| `SeeSaw/Model/StoryBeatCodable.swift` | Only if `@Generable` doesn't synthesise `Codable` (verify first) |
| `SeeSawTests/HybridModeTests.swift` | 13 tests as specified |

## Files to Modify

| File | Change |
|------|--------|
| `SeeSaw/Services/Cloud/CloudAgentService.swift` | Add `EnhancementRequest` + `requestEnhancement()` with 404 fallback and StoryResponse→StoryBeat conversion |
| `SeeSaw/ViewModel/CompanionViewModel.swift` | Add 2 stored properties; rewrite `runHybridPipeline()`; add `resolveHybridLocalService()` and `continueHybridLoop()` |
| `SeeSaw/App/AppDependencyContainer.swift` | Construct `HybridMetricsStore`; add to `makeCompanionViewModel()` |

---

## Complete Implementation Specifications

### Step 1 — `HybridBeatMetric.swift` (unchanged from plan)

```swift
import Foundation

enum HybridSource: String, Codable, Sendable {
    case cloud
    case localGemma4
    case localOnDevice
}

enum EndingSource: String, Codable, Sendable {
    case localHeuristic
    case cloudLLM
    case turnCap
}

struct HybridBeatMetric: Codable, Sendable {
    let turnNumber: Int
    let source: HybridSource
    let localGenerationMs: Double
    let cloudResponseMs: Double?
    let cloudArrivedInTime: Bool
    let endingDetectedBy: EndingSource?
    let timestamp: Double
}
```

---

### Step 2 — `HybridMetricsStore.swift` (unchanged from plan)

```swift
actor HybridMetricsStore {
    private var metrics: [HybridBeatMetric] = []

    func record(_ metric: HybridBeatMetric) {
        metrics.append(metric)
    }

    func allMetrics() -> [HybridBeatMetric] { metrics }

    func cloudHitRate() -> Double {
        guard !metrics.isEmpty else { return 0 }
        let hits = metrics.filter { $0.source == .cloud }.count
        return Double(hits) / Double(metrics.count)
    }

    func averageLocalMs() -> Double {
        guard !metrics.isEmpty else { return 0 }
        return metrics.map(\.localGenerationMs).reduce(0, +) / Double(metrics.count)
    }

    func averageCloudMs() -> Double {
        let cloudMetrics = metrics.compactMap(\.cloudResponseMs)
        guard !cloudMetrics.isEmpty else { return 0 }
        return cloudMetrics.reduce(0, +) / Double(cloudMetrics.count)
    }

    func exportCSV() -> String {
        let header = "turn,source,local_ms,cloud_ms,cloud_arrived,ending_by,timestamp"
        let rows = metrics.map { m in
            "\(m.turnNumber),\(m.source.rawValue),\(m.localGenerationMs),\(m.cloudResponseMs.map { String($0) } ?? ""),\(m.cloudArrivedInTime),\(m.endingDetectedBy?.rawValue ?? ""),\(m.timestamp)"
        }
        return ([header] + rows).joined(separator: "\n")
    }
}
```

---

### Step 3 — `CloudAgentService.swift` additions

```swift
struct EnhancementRequest: Codable {
    let scenePayload: ScenePayload
    let baseBeat: StoryBeat        // Requires StoryBeat: Codable (verify or add StoryBeatCodable.swift)
    let childAnswer: String?
    let storyHistory: [StoryTurn]
    let turnNumber: Int
    let maxTurns: Int
    let childAge: Int
    let childName: String

    enum CodingKeys: String, CodingKey {
        case scenePayload = "scene_payload"
        case baseBeat     = "base_beat"
        case childAnswer  = "child_answer"
        case storyHistory = "story_history"
        case turnNumber   = "turn_number"
        case maxTurns     = "max_turns"
        case childAge     = "child_age"
        case childName    = "child_name"
    }
}

// POST to /story/enhance; on 404 fall back to /story/generate with storyHistory
// Returns StoryBeat directly (not StoryResponse)
func requestEnhancement(
    payload: ScenePayload,
    baseBeat: StoryBeat,
    childAnswer: String?,
    storyHistory: [StoryTurn],
    turnNumber: Int
) async throws -> StoryBeat {
    guard let base = baseURL else {
        AppConfig.shared.log("requestEnhancement: no cloud agent URL", level: .error)
        throw CloudError.notConfigured
    }
    let maxTurns = 6
    let req = EnhancementRequest(
        scenePayload: payload, baseBeat: baseBeat, childAnswer: childAnswer,
        storyHistory: storyHistory, turnNumber: turnNumber, maxTurns: maxTurns,
        childAge: payload.childAge, childName: payload.childName
    )
    let endpoint = base.appendingPathComponent("story/enhance")
    var urlRequest = URLRequest(url: endpoint)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    if let apiKey = UserDefaults.standard.cloudAgentAPIKey, !apiKey.isEmpty {
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-SeeSaw-Key")
    }
    urlRequest.httpBody = try JSONEncoder().encode(req)
    AppConfig.shared.log("requestEnhancement: POST \(endpoint), turn=\(turnNumber)")

    let (data, response) = try await session.data(for: urlRequest)
    guard let http = response as? HTTPURLResponse else { throw CloudError.invalidResponse }

    if http.statusCode == 200 {
        return try JSONDecoder().decode(StoryBeat.self, from: data)
    }

    // 404 or other: fall back to /story/generate with storyHistory context
    AppConfig.shared.log("requestEnhancement: HTTP \(http.statusCode), falling back to /story/generate", level: .warning)
    let payloadWithHistory = ScenePayload(
        objects: payload.objects,
        scene: payload.scene,
        transcript: payload.transcript,
        childAge: payload.childAge,
        childName: payload.childName,
        sessionId: payload.sessionId,
        storyHistory: storyHistory      // inject conversation history
    )
    let storyResponse = try await requestStory(payload: payloadWithHistory)
    // Convert StoryResponse → StoryBeat (StoryResponse has exactly the same 3 semantic fields)
    return StoryBeat(
        storyText: storyResponse.storyText,
        question:  storyResponse.question,
        isEnding:  storyResponse.isEnding
    )
}
```

---

### Step 4 — `BackgroundStoryEnhancer.swift` (critical fix applied)

```swift
actor BackgroundStoryEnhancer {

    private let cloudService: CloudAgentService
    private var pendingTask: Task<(StoryBeat, Double)?, Never>?
    private var cachedResult: (StoryBeat, Double)?
    private var storyHistory: [StoryTurn] = []

    init(cloudService: CloudAgentService) { self.cloudService = cloudService }

    func requestEnhancement(
        payload: ScenePayload,
        baseBeat: StoryBeat,
        childAnswer: String?,
        turnNumber: Int
    ) {
        storyHistory.append(StoryTurn(role: "model", text: baseBeat.storyText))
        if let answer = childAnswer {
            storyHistory.append(StoryTurn(role: "user", text: answer))
        }
        let history = storyHistory

        pendingTask = Task {
            let start = CFAbsoluteTimeGetCurrent()
            do {
                let beat = try await cloudService.requestEnhancement(
                    payload: payload, baseBeat: baseBeat, childAnswer: childAnswer,
                    storyHistory: history, turnNumber: turnNumber
                )
                let ms = (CFAbsoluteTimeGetCurrent() - start) * 1000
                await self.setCached((beat, ms))
                return (beat, ms)
            } catch {
                AppConfig.shared.log("BackgroundStoryEnhancer: cloud failed: \(error)", level: .warning)
                return nil
            }
        }
    }

    /// Race cloud task vs deadline. Returns immediately if already cached.
    /// If cloud wins within deadline: clears task, returns result.
    /// If timeout wins: leaves pendingTask running — it will populate
    /// cachedResult for the next turn's fast path.
    func consumeEnhancedBeat(deadline: Duration = .seconds(1)) async -> (StoryBeat, Double)? {
        // Fast path: cloud completed while child was answering
        if let cached = cachedResult {
            let result = cached; cachedResult = nil; pendingTask = nil; return result
        }
        guard pendingTask != nil else { return nil }

        // Poll every 50ms for up to deadline.
        // pendingTask runs concurrently — if it finishes between polls it sets cachedResult.
        // Max excess wait: 50ms. Acceptable for 1s deadline.
        let pollInterval = Duration.milliseconds(50)
        var remaining = deadline
        while remaining > .zero {
            try? await Task.sleep(for: min(pollInterval, remaining))
            remaining -= pollInterval
            if let cached = cachedResult {
                let result = cached; cachedResult = nil; pendingTask = nil; return result
            }
        }
        return nil  // cloud too slow; pendingTask continues in background
    }

    func reset() {
        pendingTask?.cancel(); pendingTask = nil
        cachedResult = nil; storyHistory = []
    }

    private func setCached(_ value: (StoryBeat, Double)) {
        cachedResult = value
    }
}
```

---

### Step 5 — `AppDependencyContainer.swift`

```swift
// Add alongside storyMetricsStore:
let hybridMetricsStore = HybridMetricsStore()

// Update makeCompanionViewModel():
func makeCompanionViewModel() -> CompanionViewModel {
    CompanionViewModel(
        // ... existing parameters ...
        hybridMetricsStore: hybridMetricsStore
    )
}
```

---

### Step 6 — `CompanionViewModel.swift`

**New stored properties** (add near `storyMetricsStore` declaration):
```swift
private let hybridMetricsStore: HybridMetricsStore
private let backgroundEnhancer: BackgroundStoryEnhancer
```

**`init()` additions:**
```swift
self.hybridMetricsStore = hybridMetricsStore
self.backgroundEnhancer = BackgroundStoryEnhancer(cloudService: cloudService)
```

**New helper method:**
```swift
private func resolveHybridLocalService() async -> (service: any StoryGenerating, skipSemantic: Bool) {
    if case .ready = await gemma4StoryService.currentModelState() {
        return (gemma4StoryService, true)
    }
    return (onDeviceStoryService, false)
}
```

**Rewritten `runHybridPipeline()` (replaces lines 813–845):**
```swift
// MARK: - Hybrid pipeline (local foreground + cloud background)

private func runHybridPipeline(jpegData: Data) async {
    let speechAuthorized = await speechRecognitionService.requestAuthorization()
    if !speechAuthorized {
        AppConfig.shared.log("runHybridPipeline: speech not authorised", level: .warning)
    }

    do {
        sessionState = .processingPrivacy
        let result = try await privacyPipeline.process(
            jpegData: jpegData,
            childAge: childAge,
            childName: UserDefaults.standard.childName,
            generationMode: storyMode.rawValue
        )
        await metricsStore.record(result.metrics)
        let payload = result.payload

        let profile = ChildProfile(
            name: UserDefaults.standard.childName,
            age: childAge,
            preferences: UserDefaults.standard.childPreferences
        )
        beginStorySession(
            jpegData: jpegData, payload: payload,
            privacyMetrics: result.metrics,
            childName: profile.name, childAge: profile.age
        )

        let (localService, skipSemantic) = await resolveHybridLocalService()

        sessionState = .generatingStory
        generationStartTime = CFAbsoluteTimeGetCurrent()
        let context = SceneContext(from: payload)
        let baseBeat = try await localService.startStory(context: context, profile: profile)
        let localMs = (CFAbsoluteTimeGetCurrent() - generationStartTime) * 1000

        // Fire background cloud enhancement while child listens to beat 0
        await backgroundEnhancer.requestEnhancement(
            payload: payload, baseBeat: baseBeat, childAnswer: nil, turnNumber: 0
        )

        sessionState = .sendingAudio
        await audioService.speak(baseBeat.storyText)
        await audioService.speak(baseBeat.question)

        storyTurnCount = 1
        recordBeat(baseBeat, generationMs: localMs, ttftMs: 0, localIndex: 0)
        await storyMetricsStore.record(StoryMetricsEvent(
            generationMode: storyMode.rawValue,
            timeToFirstTokenMs: 0, totalGenerationMs: localMs,
            turnCount: storyTurnCount, guardrailViolations: 0,
            storyTextLength: baseBeat.storyText.count,
            timestamp: Date().timeIntervalSince1970
        ))
        await hybridMetricsStore.record(HybridBeatMetric(
            turnNumber: 0,
            source: localService is Gemma4StoryService ? .localGemma4 : .localOnDevice,
            localGenerationMs: localMs, cloudResponseMs: nil,
            cloudArrivedInTime: false, endingDetectedBy: nil,
            timestamp: Date().timeIntervalSince1970
        ))
        timeline.insert(TimelineEntry(
            sceneObjects: payload.objects,
            storySnippet: String(baseBeat.storyText.prefix(120))
        ), at: 0)

        if !baseBeat.isEnding {
            storyLoopTask = Task { [weak self] in
                await self?.continueHybridLoop(
                    payload: payload, localService: localService, skipSemantic: skipSemantic
                )
            }
        } else {
            finalizeCurrentSession(); storyTurnCount = 0; sessionState = .connected
        }
    } catch {
        AppConfig.shared.log("runHybridPipeline: error=\(error.localizedDescription)", level: .error)
        setError(error.localizedDescription)
    }
}
```

**New `continueHybridLoop()`:**
```swift
private func continueHybridLoop(
    payload: ScenePayload,
    localService: any StoryGenerating,
    skipSemantic: Bool
) async {
    var currentBeat: StoryBeat? = nil

    while !Task.isCancelled {
        sessionState = .listeningForAnswer
        latestAnswerPiiCount = 0
        let question = currentBeat?.question ?? ""
        guard let answer = await listenForAnswer(question: question, skipSemanticLayer: skipSemantic) else {
            await endStoryGracefully(); break
        }
        recordAnswer(answer, piiCount: latestAnswerPiiCount)

        sessionState = .generatingStory
        let beat: StoryBeat
        let source: HybridSource
        var cloudResponseMs: Double? = nil
        let localStart = CFAbsoluteTimeGetCurrent()

        if let (enhanced, cloudMs) = await backgroundEnhancer.consumeEnhancedBeat() {
            beat = enhanced; source = .cloud; cloudResponseMs = cloudMs
            AppConfig.shared.log("hybridLoop: turn \(storyTurnCount) cloud-enhanced (\(Int(cloudMs))ms)")
        } else {
            beat = (try? await localService.continueTurn(childAnswer: answer)) ?? .safeFallback
            source = localService is Gemma4StoryService ? .localGemma4 : .localOnDevice
            AppConfig.shared.log("hybridLoop: turn \(storyTurnCount) local fallback")
        }
        let localMs = (CFAbsoluteTimeGetCurrent() - localStart) * 1000
        currentBeat = beat

        // Fire next background enhancement during speak+listen dead time
        await backgroundEnhancer.requestEnhancement(
            payload: payload, baseBeat: beat, childAnswer: answer, turnNumber: storyTurnCount
        )

        sessionState = .sendingAudio
        await audioService.speak(beat.storyText)
        await audioService.speak(beat.question)

        storyTurnCount += 1
        recordBeat(beat, generationMs: source == .cloud ? 0 : localMs,
                   ttftMs: 0, localIndex: storyTurnCount - 1)
        await storyMetricsStore.record(StoryMetricsEvent(
            generationMode: storyMode.rawValue,
            timeToFirstTokenMs: 0,
            totalGenerationMs: source == .cloud ? (cloudResponseMs ?? 0) : localMs,
            turnCount: storyTurnCount, guardrailViolations: 0,
            storyTextLength: beat.storyText.count,
            timestamp: Date().timeIntervalSince1970
        ))
        await hybridMetricsStore.record(HybridBeatMetric(
            turnNumber: storyTurnCount - 1, source: source,
            localGenerationMs: localMs, cloudResponseMs: cloudResponseMs,
            cloudArrivedInTime: source == .cloud,
            endingDetectedBy: beat.isEnding
                ? (source == .cloud ? .cloudLLM : .localHeuristic) : nil,
            timestamp: Date().timeIntervalSince1970
        ))
        timeline.insert(TimelineEntry(
            sceneObjects: [], storySnippet: String(beat.storyText.prefix(120))
        ), at: 0)

        if beat.isEnding { break }
    }

    await localService.endSession()
    await backgroundEnhancer.reset()
    finalizeCurrentSession()
    storyTurnCount = 0
    guard case .error = sessionState else { sessionState = .connected; return }
}
```

---

### Step 7 — `HybridModeTests.swift` (unchanged from plan)

```swift
import Testing
@testable import SeeSaw

// MARK: - MockCloudAgentService

actor MockCloudAgentService: /* CloudServiceProtocol if extracted; else inline */ {
    var delay: Duration = .zero
    var beatToReturn: StoryBeat = .safeFallback
    var shouldFail = false
    var requestCount = 0

    func requestEnhancement(...) async throws -> StoryBeat {
        requestCount += 1
        if delay > .zero { try? await Task.sleep(for: delay) }
        if shouldFail { throw CloudError.notConfigured }
        return beatToReturn
    }
}

@Suite("Hybrid Mode", .serialized)
struct HybridModeTests {

    @Suite("BackgroundStoryEnhancer")
    struct BackgroundStoryEnhancerTests {
        @Test func consumeEnhancedBeatReturnsNilWhenNoPendingTask() async { ... }
        @Test func consumeEnhancedBeatReturnsCloudBeatWhenFast() async { ... }
        @Test func consumeEnhancedBeatReturnsNilWhenCloudExceedsDeadline() async {
            // mock delay = 2s, deadline = 0.1s → expect nil returned in ~0.15s
        }
        @Test func resetCancelsPendingTask() async { ... }
        @Test func storyHistoryAccumulatesAcrossEnhancementRequests() async { ... }
    }

    @Suite("HybridBeatMetric")
    struct HybridBeatMetricTests {
        @Test func codableRoundTrip() throws { ... }
        @Test func hybridSourceRawValues() { ... }
        @Test func endingSourceRawValues() { ... }
    }

    @Suite("HybridMetricsStore")
    struct HybridMetricsStoreTests {
        @Test func cloudHitRateZeroWhenAllLocal() async { ... }
        @Test func cloudHitRateOneWhenAllCloud() async { ... }
        @Test func cloudHitRateFractionMixed() async { ... }
        @Test func csvExportContainsCorrectHeader() async { ... }
        @Test func exportCSVRowCountMatchesRecordCount() async { ... }
    }
}
```

**Note on MockCloudAgentService:** `CloudAgentService` is a concrete actor with no protocol. Two options:
1. Extract a `CloudAgentServiceProtocol` (extra change, not needed for hybrid tests alone)
2. Create the mock by subclassing — not possible with actors
3. **Recommended:** Wrap `CloudAgentService` interaction inside `BackgroundStoryEnhancer` with a closure or make the cloud call injectable. For now, test `BackgroundStoryEnhancer` with a real `CloudAgentService` configured with no baseURL (throws `notConfigured` instantly), and a separate fast-mock path using a local HTTP stub or test-doubles. The plan should document this trade-off; the 5 BackgroundStoryEnhancer tests may need `CloudAgentService` to gain a protocol or a testable seam.

---

## Verification

```bash
# 1. Build
xcodebuild build \
  -workspace SeeSaw.xcworkspace -scheme SeeSaw \
  -destination 'platform=iOS Simulator,arch=arm64,id=E33D4588-A415-495B-8BEB-91B0AC534511'

# 2. Tests (existing 130+ + 13 new hybrid tests)
xcodebuild test \
  -workspace SeeSaw.xcworkspace -scheme SeeSaw \
  -destination 'platform=iOS Simulator,arch=arm64,id=E33D4588-A415-495B-8BEB-91B0AC534511' \
  -testPlan SeeSaw -enableCodeCoverage YES

# 3. Manual on device — Settings → hybrid → capture scene:
# • Beat 0: local model speaks within ~3s
# • Beat 1+: Console shows "cloud-enhanced (Xms)" or "local fallback" — never hangs
# • Full 6-turn conversation completes without pause
# • HybridMetricsStore.exportCSV() columns match Ch.6 requirements
```

---

## Change Inventory (exact lines affected)

| File | Action | Details |
|------|--------|---------|
| `SeeSaw/Model/HybridBeatMetric.swift` | **Create** | New file, ~20 lines |
| `SeeSaw/Model/StoryBeatCodable.swift` | **Create if needed** | Extension: `StoryBeat: Codable` |
| `SeeSaw/Services/AI/HybridMetricsStore.swift` | **Create** | Actor, ~45 lines |
| `SeeSaw/Services/AI/BackgroundStoryEnhancer.swift` | **Create** | Actor, ~65 lines (with polling fix) |
| `SeeSaw/Services/Cloud/CloudAgentService.swift` | **Modify** | Add `EnhancementRequest` struct + `requestEnhancement()` (~65 lines) |
| `SeeSaw/ViewModel/CompanionViewModel.swift` | **Modify** | +2 properties in declarations; extend `init()`; replace lines 813–845; add 2 new methods (~120 lines net) |
| `SeeSaw/App/AppDependencyContainer.swift` | **Modify** | +1 let; update `makeCompanionViewModel()` (~5 lines) |
| `SeeSawTests/HybridModeTests.swift` | **Create** | 13 tests, mock infrastructure |
