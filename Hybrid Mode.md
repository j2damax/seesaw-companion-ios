Here's the plan for the redesigned hybrid mode:

---

## Hybrid Mode Redesign: Dual-Agent Story Engine

### The Problem With Current Hybrid

Current `runHybridPipeline()` is a glorified fallback chain: try cloud → fail → Gemma4 → fail → Apple FM. The cloud path is **single-shot** (one beat, no conversation loop), the cloud response is thrown away if fallback triggers, and there's zero data flow between layers. It adds nothing that `cloud` mode doesn't already do better.

### The Redesigned Flow: Local Foreground + Cloud Background

```
                    ┌──────────────────────────────────────────────┐
                    │          FOREGROUND (real-time, <3s)         │
                    │                                              │
  Camera ──► Privacy Pipeline ──► ScenePayload ──► Gemma4/Apple FM│
                    │                 │            (base beat)     │
                    │                 │                ▼           │
                    │                 │         speak(baseBeat)    │
                    │                 │         listenForAnswer()  │
                    │                 │              ▼             │
                    │                 │     SemanticTurnDetector   │
                    │                 │         (Apple FM VAD)     │
                    └─────────────────┼────────────────────────────┘
                                      │
                    ┌─────────────────▼────────────────────────────┐
                    │        BACKGROUND (concurrent, async)        │
                    │                                              │
                    │  ScenePayload + baseBeat + childAnswer       │
                    │         ▼                                    │
                    │  Cloud Agent (Gemini 2.0 Flash)              │
                    │    • Richer vocabulary, longer arcs           │
                    │    • Better ending detection                  │
                    │    • Narrative coherence across turns         │
                    │    • Safety re-evaluation                    │
                    │         ▼                                    │
                    │  EnhancedBeat (cached for next turn)         │
                    └──────────────────────────────────────────────┘
```

### Beat-by-Beat Sequence

| Step | Agent | What Happens | Latency | Child Waiting? |
|------|-------|-------------|---------|----------------|
| 1 | **Foreground** | Camera capture → privacy pipeline → `ScenePayload` | ~500ms | No (scanning UI) |
| 2 | **Foreground** | Gemma4 `startStory(context)` → base `StoryBeat` | 1–3s | Yes (streaming text) |
| 3 | **Foreground** | `speak(baseBeat.storyText)` + `speak(baseBeat.question)` | 3–7s | Listening to story |
| 4 | **Background** | While child listens: POST `{payload, baseBeat}` to cloud | 5–15s | No (async) |
| 5 | **Foreground** | `listenForAnswer()` with 3-layer turn detection | up to 8s | Talking |
| 6 | **Foreground** | Check: has `enhancedNextBeat` arrived from cloud? | <1ms | — |
| 6a | If yes | Use `enhancedNextBeat` as the next story beat | 0ms | — |
| 6b | If no | Gemma4 `continueTurn(childAnswer)` → base beat | 1–3s | Yes (streaming) |
| 7 | **Background** | POST `{childAnswer, previousBeat}` → cloud prepares next | async | — |
| 8 | Repeat from 3 | | | |

**Key insight:** The cloud is always **one beat ahead**. It receives the base beat + child's answer and prepares an enhanced version while the foreground handles the next cycle. If the cloud response arrives in time, it replaces the local generation entirely. If not, the local model fills in without delay.

### New Cloud Contract: Enhancement Endpoint

```
POST /story/enhance
Body: {
    "scene_payload": ScenePayload,          // current scene
    "base_beat": {                          // what the local model generated
        "story_text": "...",
        "question": "...",
        "is_ending": false
    },
    "child_answer": "a dragon!",            // what the child said (PII-scrubbed)
    "story_history": [StoryTurn],           // conversation so far
    "turn_number": 3,
    "max_turns": 6,
    "child_age": 5,
    "child_name": "Emma"
}

Response: {
    "story_text": "...",                    // richer, more coherent version
    "question": "...",                      // better follow-up question
    "is_ending": false,                     // smarter ending detection
    "narrative_hints": {                    // optional: guidance for fallback
        "character_names": ["Luna the dragon"],
        "current_arc": "discovery",
        "suggested_next_theme": "friendship"
    },
    "session_id": "...",
    "beat_index": 3
}
```

### Enhanced Ending Detection (Cloud Side)

The cloud agent solves the heuristic gap from the review. Instead of checking against a fixed word list, Gemini evaluates:

```python
# Cloud agent ending detection (seesaw-cloud-agent)
ENDING_PROMPT = """
Evaluate whether this story should end NOW.
Consider:
1. Natural narrative arc (setup → conflict → resolution)
2. Turn count ({turn}/{max_turns}) — if turn >= max-1, MUST end
3. Child's energy signals (short answers = fading interest)
4. Story completeness (has the conflict been resolved?)

Child said: "{child_answer}"
Story so far: {story_history_summary}
Current beat: "{base_beat_text}"

Return JSON: {"should_end": true/false, "reason": "..."}
"""
```

This replaces the fragile `["the end", "goodbye", "farewell", ...]` heuristic with LLM-powered narrative awareness — but only on the **cloud side**, never blocking the local loop.

### The `BackgroundStoryEnhancer` Actor

```swift
actor BackgroundStoryEnhancer {

    private let cloudService: CloudAgentService
    private var pendingEnhancement: Task<StoryBeat?, Never>?
    private var cachedEnhancedBeat: StoryBeat?
    private var storyHistory: [StoryTurn] = []
    private var narrativeHints: NarrativeHints?

    // Called by foreground immediately after local generation
    func requestEnhancement(
        payload: ScenePayload,
        baseBeat: StoryBeat,
        childAnswer: String?,
        turnNumber: Int
    ) {
        pendingEnhancement = Task {
            do {
                let enhanced = try await cloudService.requestEnhancement(
                    payload: payload,
                    baseBeat: baseBeat,
                    childAnswer: childAnswer,
                    storyHistory: storyHistory,
                    turnNumber: turnNumber
                )
                cachedEnhancedBeat = enhanced.beat
                narrativeHints = enhanced.hints
                return enhanced.beat
            } catch {
                // Cloud unavailable — foreground proceeds unaffected
                return nil
            }
        }
    }

    // Called by foreground before generating next beat
    // Returns enhanced beat if cloud responded in time, nil otherwise
    func consumeEnhancedBeat() async -> StoryBeat? {
        guard let task = pendingEnhancement else { return nil }
        let result = await task.value
        pendingEnhancement = nil
        cachedEnhancedBeat = nil
        return result
    }

    // Quick non-blocking check (no await)
    func hasEnhancedBeat() -> Bool {
        cachedEnhancedBeat != nil
    }
}
```

### Modified `CompanionViewModel` Hybrid Loop

```swift
// Replaces current single-shot runHybridPipeline()
private func runHybridPipeline(jpegData: Data) async {
    // ── Stage 1: Privacy pipeline (same as all modes) ───────────
    sessionState = .processingPrivacy
    let result = try await privacyPipeline.process(jpegData, childAge, childName)
    await metricsStore.record(result.metrics)
    let payload = result.payload

    // ── Stage 2: Local foreground generates base beat ───────────
    sessionState = .generatingStory
    let context = SceneContext(from: payload)
    let profile = ChildProfile(name: childName, age: childAge)
    let baseBeat = try await localStoryService.startStory(
        context: context, profile: profile
    )

    // ── Stage 3: Fire background enhancement (non-blocking) ────
    await backgroundEnhancer.requestEnhancement(
        payload: payload,
        baseBeat: baseBeat,
        childAnswer: nil,
        turnNumber: 0
    )

    // ── Stage 4: Speak immediately (don't wait for cloud) ──────
    sessionState = .sendingAudio
    await audioService.speak(baseBeat.storyText)
    await audioService.speak(baseBeat.question)

    // ── Stage 5: Enter hybrid conversation loop ────────────────
    if !baseBeat.isEnding {
        storyLoopTask = Task { await continueHybridLoop(payload: payload) }
    }
}

private func continueHybridLoop(payload: ScenePayload) async {
    while !Task.isCancelled {
        // ── Listen for child's answer ──────────────────────────
        sessionState = .listeningForAnswer
        let answer = await listenForAnswer()  // 3-layer VAD (unchanged)

        // ── Check: did cloud deliver an enhanced beat? ─────────
        sessionState = .generatingStory
        var beat: StoryBeat

        if let enhanced = await backgroundEnhancer.consumeEnhancedBeat() {
            // Cloud arrived in time — use richer version
            beat = enhanced
            AppConfig.shared.log("hybridLoop: using cloud-enhanced beat")
            metricsStore.recordHybridSource(.cloud)
        } else {
            // Cloud too slow — local model generates immediately
            beat = try await localStoryService.continueTurn(childAnswer: answer)
            AppConfig.shared.log("hybridLoop: using local fallback beat")
            metricsStore.recordHybridSource(.local)
        }

        // ── Fire next enhancement request (non-blocking) ──────
        await backgroundEnhancer.requestEnhancement(
            payload: payload,
            baseBeat: beat,
            childAnswer: answer,
            turnNumber: localStoryService.currentTurnCount
        )

        // ── Speak the beat ─────────────────────────────────────
        sessionState = .sendingAudio
        await audioService.speak(beat.storyText)
        await audioService.speak(beat.question)
        recordBeat(beat, answer: answer)

        if beat.isEnding { break }
    }
}
```

### What This Solves

| Current Gap | How Hybrid v2 Fixes It |
|---|---|
| Single-shot cloud, no conversation loop | Full multi-turn loop with cloud running concurrently |
| Cloud response discarded on fallback | Cloud **enhances** local beat, never blocks |
| Heuristic ending detection fragile | Cloud uses LLM-powered narrative arc evaluation |
| ~15s idle compute per turn | Cloud works during speak() + listen() dead time |
| No `continueHybridLoop()` exists | New method with cloud-or-local racing pattern |
| Cloud beat not persisted | `recordBeat()` called for every beat regardless of source |
| No data seeding between layers | `narrativeHints` from cloud feed into local generation if cloud goes down mid-session |

### Metrics & Dissertation Value

New instrumentation for Chapter 6:

```swift
struct HybridBeatMetric: Codable {
    let turnNumber: Int
    let source: HybridSource          // .local or .cloud
    let localGenerationMs: Double     // always measured (even if cloud used)
    let cloudResponseMs: Double?      // nil if cloud didn't respond
    let cloudArrivedInTime: Bool      // true = enhanced beat used
    let endingDetectedBy: EndingSource // .localHeuristic, .cloudLLM, .turnCap
}
```

This gives the dissertation a **direct quality comparison** per beat: same scene, same child answer, but local-generated vs cloud-enhanced text — rated blind by evaluators.

### Privacy Boundary: Unchanged

All data crossing the network is still `ScenePayload` (labels + scrubbed transcript). The new `/story/enhance` endpoint receives `baseBeat` (generated text, not raw media) and `childAnswer` (PII-scrubbed). No new privacy surface.

### Implementation Priority

| Task | Effort | Dependency |
|------|--------|------------|
| 1. `BackgroundStoryEnhancer` actor | Small | None |
| 2. `CloudAgentService.requestEnhancement()` | Small | New endpoint contract |
| 3. `continueHybridLoop()` in CompanionViewModel | Medium | Tasks 1–2 |
| 4. Cloud `/story/enhance` endpoint | Medium | seesaw-cloud-agent repo |
| 5. `HybridBeatMetric` instrumentation | Small | Task 3 |
| 6. `NarrativeHints` struct + local prompt seeding | Small | Task 4 |
| 7. Tests: enhancement racing, timeout, fallback | Medium | Tasks 1–3 |

### Scope Decision

For the dissertation, **tasks 1–3 + 5** are sufficient — they prove the dual-agent architecture pattern. Task 4 (cloud endpoint) can be stubbed with a delayed mock that returns the same beat with minor enrichment, still demonstrating the architecture. Tasks 6–7 are polish.

### REVIEW 1: 
# Hybrid Mode v2: Dual-Agent Story Engine

## Context

The current `runHybridPipeline()` is a single-shot fallback chain (cloud → Gemma4 → Apple FM). It generates one beat and stops — there is no conversation loop. It also discards the cloud response if a fallback triggers, and the cloud runs in serial with the foreground so the child waits for network latency on every turn.

The redesign makes hybrid a genuine dual-agent architecture: a **local model** (Gemma4 preferred, Apple FM fallback) runs in the foreground for zero-wait story generation, while a **cloud agent** (Gemini) runs concurrently in the background during speak + listen dead time, ready to replace the next local beat with a richer, narrative-coherent version. If the cloud beat arrives before the child finishes answering, it replaces the local beat entirely. If not, the local model fills in without delay. The child never waits.

This is the primary dissertation Chapter 6 comparison: same scene, same child answer, local-generated vs cloud-enhanced text — rated blind by evaluators.

---

## Files to Create

| File | Purpose |
|---|---|
| `SeeSaw/Services/AI/BackgroundStoryEnhancer.swift` | New actor that manages concurrent cloud enhancement tasks |
| `SeeSaw/Model/HybridBeatMetric.swift` | Metric struct tracking source + timing per beat for dissertation |
| `SeeSaw/Services/AI/HybridMetricsStore.swift` | Actor that accumulates HybridBeatMetric events and exports CSV |

## Files to Modify

| File | Change |
|---|---|
| `SeeSaw/Services/Cloud/CloudAgentService.swift` | Add `requestEnhancement()` method (new `/story/enhance` endpoint, stub fallback to `/story/generate`) |
| `SeeSaw/ViewModel/CompanionViewModel.swift` | Add `backgroundEnhancer` property; rewrite `runHybridPipeline()`; add `continueHybridLoop()` |

---

## Step 1 — `HybridBeatMetric` + `HybridMetricsStore`

**New file:** `SeeSaw/Model/HybridBeatMetric.swift`

```swift
enum HybridSource: String, Codable, Sendable {
    case cloud          // Cloud Gemini beat arrived in time and was used
    case localGemma4    // Gemma4 generated because cloud was too slow or failed
    case localOnDevice  // Apple FM generated (Gemma4 unavailable)
}

struct HybridBeatMetric: Codable, Sendable {
    let turnNumber: Int
    let source: HybridSource
    let localGenerationMs: Double    // Time for local model (always measured)
    let cloudResponseMs: Double?     // nil if cloud didn't respond before listen completed
    let cloudArrivedInTime: Bool     // true = enhanced beat used
    let timestamp: Double
}
```

**New file:** `SeeSaw/Services/AI/HybridMetricsStore.swift`

Actor with `record(_ metric: HybridBeatMetric)`, `allMetrics() -> [HybridBeatMetric]`, `cloudHitRate() -> Double`, `averageLocalMs() -> Double`, `averageCloudMs() -> Double`, `exportCSV() -> String`.

CSV columns for dissertation: `turn,source,local_ms,cloud_ms,cloud_arrived,timestamp`.

---

## Step 2 — `CloudAgentService.requestEnhancement()`

**Modify:** `SeeSaw/Services/Cloud/CloudAgentService.swift`

Add a new Codable request struct:

```swift
struct EnhancementRequest: Codable {
    let scenePayload: ScenePayload
    let baseBeat: EnhancementBeat     // {story_text, question, is_ending}
    let childAnswer: String?
    let storyHistory: [StoryTurn]
    let turnNumber: Int
    let maxTurns: Int
    let childAge: Int
    let childName: String
}

struct EnhancementBeat: Codable {
    let storyText: String
    let question: String
    let isEnding: Bool
}
```

New method:

```swift
func requestEnhancement(
    payload: ScenePayload,
    baseBeat: StoryBeat,
    childAnswer: String?,
    storyHistory: [StoryTurn],
    turnNumber: Int
) async throws -> StoryBeat
```

Implementation: POST `EnhancementRequest` to `baseURL/story/enhance`. If 404 (endpoint not yet deployed), fall back to POST the existing `ScenePayload` (with `transcript = childAnswer`, `storyHistory`) to `baseURL/story/generate` and return a `StoryBeat` from `StoryResponse`. This stub fallback keeps the architecture demonstrable before the cloud endpoint is built.

Parse response as `StoryResponse` → convert to `StoryBeat`.

---

## Step 3 — `BackgroundStoryEnhancer` actor

**New file:** `SeeSaw/Services/AI/BackgroundStoryEnhancer.swift`

```swift
actor BackgroundStoryEnhancer {

    private let cloudService: CloudAgentService
    private var pendingTask: Task<StoryBeat?, Never>?
    private var cachedBeat: StoryBeat?
    private var storyHistory: [StoryTurn] = []

    init(cloudService: CloudAgentService) { ... }

    // Call immediately after local model generates a beat (non-blocking)
    func requestEnhancement(
        payload: ScenePayload,
        baseBeat: StoryBeat,
        childAnswer: String?,
        turnNumber: Int
    ) {
        pendingTask = Task {
            // any error → return nil, foreground proceeds unaffected
        }
    }

    // Call before generating next beat. Awaits if task in-flight (no timeout needed —
    // we call this only after listenForAnswer() completes, giving the cloud 8–15s)
    func consumeEnhancedBeat() async -> StoryBeat? {
        guard let task = pendingTask else { return nil }
        let beat = await task.value
        pendingTask = nil; cachedBeat = nil
        return beat
    }

    // Quick non-async check
    func hasEnhancedBeat() -> Bool { cachedBeat != nil }

    // Call at session end
    func reset() { pendingTask?.cancel(); pendingTask = nil; cachedBeat = nil; storyHistory = [] }

    // Internal: append to storyHistory on successful cloud response
}
```

---

## Step 4 — `CompanionViewModel` changes

**Modify:** `SeeSaw/ViewModel/CompanionViewModel.swift`

### 4a — New stored property

```swift
// Lazy — only created when hybrid mode is active
private lazy var backgroundEnhancer = BackgroundStoryEnhancer(cloudService: cloudService)
```

### 4b — Helper: which local service to use in hybrid

```swift
private func hybridLocalService() -> any StoryGenerating {
    if case .ready = await gemma4StoryService.currentModelState() {
        return gemma4StoryService
    }
    return onDeviceStoryService
}
```

### 4c — Rewrite `runHybridPipeline()` (lines 814–844)

```swift
private func runHybridPipeline(jpegData: Data) async {
    // 1. Privacy pipeline (same as all modes)
    sessionState = .processingPrivacy
    let result = try await privacyPipeline.process(...)
    await metricsStore.record(result.metrics)
    let payload = result.payload

    beginStorySession(jpegData: jpegData, payload: payload, ...)

    // 2. Local foreground generates base beat immediately
    sessionState = .generatingStory
    let localStart = CFAbsoluteTimeGetCurrent()
    let local = hybridLocalService()
    let context = SceneContext(from: payload)
    let profile = ChildProfile(name: childName, age: childAge, preferences: ...)
    let baseBeat = try await local.startStory(context: context, profile: profile)
    let localMs = (CFAbsoluteTimeGetCurrent() - localStart) * 1000

    // 3. Fire background enhancement (non-blocking, no await)
    await backgroundEnhancer.requestEnhancement(
        payload: payload, baseBeat: baseBeat, childAnswer: nil, turnNumber: 0
    )

    // 4. Speak immediately (don't wait for cloud)
    sessionState = .sendingAudio
    await audioService.speak(baseBeat.storyText)
    await audioService.speak(baseBeat.question)

    recordBeat(baseBeat, generationMs: localMs, ttftMs: 0, localIndex: 0)
    await hybridMetricsStore.record(HybridBeatMetric(
        turnNumber: 0, source: .localGemma4orOnDevice,
        localGenerationMs: localMs, cloudResponseMs: nil,
        cloudArrivedInTime: false, timestamp: ...
    ))
    timeline.insert(TimelineEntry(...), at: 0)

    // 5. Enter hybrid conversation loop
    if !baseBeat.isEnding {
        storyLoopTask = Task { [weak self] in
            await self?.continueHybridLoop(payload: payload, localService: local)
        }
    } else {
        finalizeCurrentSession()
        storyTurnCount = 0
        sessionState = .connected
    }
}
```

### 4d — New `continueHybridLoop()` method

```swift
private func continueHybridLoop(payload: ScenePayload, localService: any StoryGenerating) async {
    while !Task.isCancelled {
        // Listen (cloud works concurrently during this 3–8s window)
        sessionState = .listeningForAnswer
        guard let answer = await listenForAnswer(question: currentQuestion) else {
            await endStoryGracefully(); break
        }
        recordAnswer(answer, piiCount: latestAnswerPiiCount)

        // Did cloud deliver an enhanced beat?
        sessionState = .generatingStory
        let beat: StoryBeat
        let source: HybridSource
        let cloudMs: Double?

        if let enhanced = await backgroundEnhancer.consumeEnhancedBeat() {
            beat = enhanced
            source = .cloud
            cloudMs = ... // tracked inside BackgroundStoryEnhancer
            AppConfig.shared.log("hybridLoop: using cloud-enhanced beat")
        } else {
            let t = CFAbsoluteTimeGetCurrent()
            beat = (try? await localService.continueTurn(childAnswer: answer))
                   ?? .safeFallback
            source = localService is Gemma4StoryService ? .localGemma4 : .localOnDevice
            cloudMs = nil
            AppConfig.shared.log("hybridLoop: cloud too slow, using local beat")
        }

        // Fire next enhancement request immediately (non-blocking)
        await backgroundEnhancer.requestEnhancement(
            payload: payload, baseBeat: beat, childAnswer: answer,
            turnNumber: storyTurnCount
        )

        // Speak
        sessionState = .sendingAudio
        await audioService.speak(beat.storyText)
        await audioService.speak(beat.question)

        recordBeat(beat, generationMs: localMs, ttftMs: 0, localIndex: storyTurnCount)
        await hybridMetricsStore.record(HybridBeatMetric(
            turnNumber: storyTurnCount, source: source,
            localGenerationMs: localMs, cloudResponseMs: cloudMs,
            cloudArrivedInTime: source == .cloud, timestamp: ...
        ))
        timeline.insert(TimelineEntry(...), at: 0)

        if beat.isEnding { break }
    }
    await backgroundEnhancer.reset()
    finalizeCurrentSession()
    storyTurnCount = 0
    guard case .error = sessionState else { sessionState = .connected; return }
}
```

---

## Step 5 — Tests

**New test file:** `SeeSawTests/HybridModeTests.swift`

Test groups:
- `BackgroundStoryEnhancerTests` — `consumeEnhancedBeat()` returns nil when no task; returns beat when task completes; `reset()` cancels in-flight task
- `HybridBeatMetricTests` — value semantics, Codable round-trip, `HybridSource` raw values
- `HybridMetricsStoreTests` — `cloudHitRate()` calculation, CSV export header

Use a `MockCloudAgentService` for BackgroundStoryEnhancer tests (no network).

---

## Scope Notes

- Cloud `/story/enhance` endpoint is **not** built in this pass. `CloudAgentService.requestEnhancement()` stubs by falling back to `/story/generate` when it receives 404. This is sufficient to demonstrate the dual-agent architecture: the cloud path does run, it just uses the existing endpoint as a proxy enhancer.
- `NarrativeHints` and local prompt seeding (task 6 in design doc) are **out of scope** for this pass.
- `StoryMetricsEvent` is **not modified** — hybrid beats are tracked separately in `HybridMetricsStore` to avoid breaking existing tests.

---

## Verification

```bash
# Build
xcodebuild build \
  -workspace SeeSaw.xcworkspace -scheme SeeSaw \
  -destination 'platform=iOS Simulator,arch=arm64,id=E33D4588-A415-495B-8BEB-91B0AC534511'

# Tests (all 247 existing + new hybrid tests)
xcodebuild test \
  -workspace SeeSaw.xcworkspace -scheme SeeSaw \
  -destination 'platform=iOS Simulator,arch=arm64,id=E33D4588-A415-495B-8BEB-91B0AC534511' \
  -testPlan SeeSaw -enableCodeCoverage YES

# Manual: set mode to "hybrid" in Settings tab, point at scene, verify:
# 1. First beat speaks within ~3s (local model)
# 2. "hybridLoop: using cloud-enhanced beat" appears in Xcode console from beat 2 onward
#    (or "using local fallback beat" if cloud not configured)
# 3. Full multi-turn conversation loop completes without crash
# 4. HybridMetricsStore.exportCSV() includes cloud_arrived column for dissertation
```

####

---

### REVIEW 2: Independent Architectural Review

**Reviewer:** GitHub Copilot (Claude Opus 4.6)
**Date:** 16 April 2026
**Scope:** Reviewed design doc, REVIEW 1 spec, and the live codebase (`CompanionViewModel.swift`, `CloudAgentService.swift`, `StoryGenerating` protocol, `Gemma4StoryService`, `OnDeviceStoryService`, `SessionState`, `AppDependencyContainer`, all model types, and `SemanticTurnDetector`).

---

#### Verdict: Architecturally Sound — Ship Tasks 1-3 + 5

The dual-agent design is well-motivated and the core insight — exploit the 8-15s speak+listen dead time for concurrent cloud work — is solid. The child never waits for the network. The dissertation value (same scene, same answer, local vs cloud text — blind-rated) is compelling. The privacy boundary is preserved: only `ScenePayload` + generated text crosses the wire, no new attack surface.

Below are issues ranked by severity.

---

#### Critical Issues (must fix before implementation)

**C1. `consumeEnhancedBeat()` blocks indefinitely if cloud hangs**

The spec says *"no timeout needed — we call this only after listenForAnswer() completes, giving the cloud 8-15s"*. This is wrong. `consumeEnhancedBeat()` does `await task.value`, which blocks until the cloud task finishes. If the cloud takes 60s (the server timeout) or the network is alive but slow, the foreground is frozen for up to 60s after the child answers. `listenForAnswer()` completing does not cancel the cloud task.

**Fix:** Race the pending task against a short deadline (e.g. 500ms–1s). If the cloud hasn't responded by then, return `nil` and let the local model generate. The enhancement task can continue running and seed the *next* turn's cache.

```swift
func consumeEnhancedBeat(deadline: Duration = .seconds(1)) async -> StoryBeat? {
    guard let task = pendingTask else { return nil }
    let result = await Task {
        try? await Task.sleep(for: deadline)
        return nil as StoryBeat?
    }.value
    // Race: whichever finishes first
}
```

Or use `Task.select` / `withTaskGroup` with a timeout child task.

**C2. `skipSemanticLayer` decision is missing**

`continueGemma4Loop` passes `skipSemanticLayer: true` because Apple FM's `LanguageModelSession` cancellation causes ~8s hangs when Gemma4 is also loaded. The hybrid loop spec calls `listenForAnswer(question: currentQuestion)` without addressing this. Since hybrid's local service *is* Gemma4 (preferred) or Apple FM, the same conflict applies.

**Fix:** When `hybridLocalService()` returns `gemma4StoryService`, pass `skipSemanticLayer: true` in the hybrid loop, matching `continueGemma4Loop` behaviour. When it returns `onDeviceStoryService`, pass `false`.

**C3. `EnhancementBeat` duplicates `StoryBeat` needlessly**

`EnhancementBeat` has identical fields to `StoryBeat` (`storyText`, `question`, `isEnding`). Since `StoryBeat` is already `Codable` (it's `@Generable` which synthesises `Codable`), just use `StoryBeat` directly in `EnhancementRequest`. Creating a separate type adds a mapping layer with no benefit and risks field drift.

**Fix:** Drop `EnhancementBeat`. Use `StoryBeat` in `EnhancementRequest`.

---

#### Significant Issues (should fix)

**S1. `hybridLocalService()` returns `any StoryGenerating` — loses streaming**

The spec's helper `hybridLocalService()` returns `any StoryGenerating`. But `StoryGenerating` only has `startStory()` / `continueTurn()` — it does not expose `streamStartStory(onPartialText:)` or `streamContinueTurn(onPartialText:)`. The on-device and Gemma4 pipelines use streaming for the first beat's TTFT tracking and `streamingStoryText` updates. Hybrid beat 0 in the spec calls `local.startStory(context:profile:)`, which means no token-by-token streaming in the UI — a UX regression from both `runOnDevicePipeline` and `runGemma4Pipeline`.

**Fix:** For the first beat, call the concrete streaming method directly (check the type and call `onDeviceStoryService.streamStartStory` or `gemma4StoryService.startStory` as appropriate). Alternatively, add `streamStartStory` and `streamContinueTurn` to the `StoryGenerating` protocol (with default no-op implementations for Gemma4 which doesn't support streaming).

**S2. `storyHistory` is tracked in `BackgroundStoryEnhancer` but never populated**

The actor declares `private var storyHistory: [StoryTurn] = []` and the spec says *"Internal: append to storyHistory on successful cloud response"*. But `requestEnhancement()` receives `baseBeat` and `childAnswer` without ever appending to `storyHistory`, and `storyHistory` is never passed to `cloudService.requestEnhancement()`. The cloud endpoint spec *requires* `storyHistory` for narrative coherence.

**Fix:** Append `StoryTurn(role: "model", text: baseBeat.storyText)` and `StoryTurn(role: "user", text: childAnswer)` inside `requestEnhancement()` before making the API call. Pass `storyHistory` to the cloud service.

**S3. `beginStorySession()` is missing from `runHybridPipeline()`**

The onDevice, Gemma4, and cloud pipelines all call `beginStorySession(jpegData:payload:privacyMetrics:childName:childAge:)` to create a `StorySessionRecord` before the first beat. The REVIEW 1 spec includes `beginStorySession(...)` but the original design doc's `runHybridPipeline()` pseudo-code omits it. Without this call, `recordBeat()` silently no-ops (it guards on `currentSession != nil`), so no timeline data is persisted.

The REVIEW 1 spec caught this — just confirming it must not be missed during implementation.

**S4. No `endSession()` called on the local story service**

All other loops call `onDeviceStoryService.endSession()` or `gemma4StoryService.endSession()` when the loop exits. The hybrid loop spec calls `backgroundEnhancer.reset()` and `finalizeCurrentSession()` but never calls `localService.endSession()`. This leaves the local model's session state dirty — `isSessionActive` stays `true`, turn counters are not reset, and LanguageModelSession / LlmInference.Session resources are not released.

**Fix:** Add `await localService.endSession()` before `finalizeCurrentSession()` in the loop exit path.

**S5. `HybridSource` naming inconsistency**

The spec defines `HybridSource` as `.cloud`, `.localGemma4`, `.localOnDevice` but the pseudo-code references `.localGemma4orOnDevice` (a combined case that doesn't exist in the enum). Pick one and be consistent. The three-case enum is better for dissertation analysis.

**S6. Cloud `requestEnhancement` 404-fallback creates silent data corruption**

The spec says: on 404, fall back to `requestStory(payload:)`. But `requestStory` expects a `ScenePayload` with `storyHistory` — the enhancement endpoint has a different contract (`EnhancementRequest`). The fallback constructs a `ScenePayload` with `transcript = childAnswer`, which hijacks the transcript field's semantic meaning (it normally holds PII-scrubbed ambient speech, not the child's story answer). This could confuse the cloud agent's prompt engineering.

**Fix:** Document that the fallback is a temporary shim and log a clear warning. Do not overload `transcript`. Instead, append the child's answer to `storyHistory` and pass it in the `ScenePayload`'s existing `storyHistory` field — the cloud agent already reads that for context.

---

#### Minor Issues / Suggestions

**M1. `requestEnhancement` on `CloudAgentService` is `async throws` but `BackgroundStoryEnhancer.requestEnhancement` swallows the error**

This is intentional (cloud failure = silent fallback), but the spec should explicitly log the error before discarding it, matching the project's instrumentation-first philosophy. A `AppConfig.shared.log("enhancement failed: \(error)", level: .warning)` is needed inside the `catch`.

**M2. `lazy var backgroundEnhancer` on `@MainActor` class is a footgun**

`CompanionViewModel` is `@MainActor`. `lazy var backgroundEnhancer = BackgroundStoryEnhancer(cloudService: cloudService)` will be initialised on first access on the main actor. Since `BackgroundStoryEnhancer` is an actor, calls into it will hop off main — that's fine. But `lazy` + `@MainActor` has historically caused thread-safety issues in Swift < 6.0. Consider making it a non-lazy stored property initialised in `init()`, consistent with all other services in `CompanionViewModel`.

**M3. `currentQuestion` referenced but not defined**

`continueHybridLoop` calls `listenForAnswer(question: currentQuestion)` but there is no `currentQuestion` property in `CompanionViewModel`. The existing loops use `pendingBeat?.question ?? ""`. Use the same pattern.

**M4. Metrics: `localMs` is referenced but not computed in `continueHybridLoop` cloud path**

When the cloud beat is used (`source == .cloud`), `localMs` is referenced in `recordBeat(beat, generationMs: localMs, ...)` but `localMs` is only computed in the `else` branch. For the cloud path, pass `0` or the cloud response time.

**M5. `HybridMetricsStore` should share `exportCSV()` pattern with `StoryMetricsStore`**

Both stores export CSV. Consider a shared `CSVExportable` protocol or at minimum matching header conventions for consistency in dissertation data processing.

**M6. Speech authorisation check is missing**

All other pipelines (`runOnDevicePipeline`, `runGemma4Pipeline`, `runCloudPipeline`) call `speechRecognitionService.requestAuthorization()` before the loop. The hybrid pipeline spec omits it. Without this, `listenForAnswer()` may silently fail on first launch.

**M7. Consider `ScenePayload` staleness in multi-turn**

The hybrid loop captures `payload` once (from the initial camera frame) and reuses it for every cloud enhancement request across all turns. By turn 5, the scene may have changed (child moved, new objects visible). The other local loops don't re-capture because they don't send payloads to the cloud. For cloud enhancement quality, consider re-running the privacy pipeline on each turn (or at least noting this as a known limitation for the dissertation).

---

#### What the Design Gets Right

1. **Privacy invariant preserved.** No new data type crosses the boundary. `baseBeat` is generated text, `childAnswer` is PII-scrubbed. The enhancement request is strictly labels + generated text.

2. **Graceful degradation.** Cloud failure = local model fills in. Child never waits. This is the correct default for a children's app where latency ruins engagement.

3. **Dissertation instrumentation built-in.** `HybridBeatMetric` with `source`, `cloudArrivedInTime`, and paired `localGenerationMs` / `cloudResponseMs` gives direct per-beat comparison data for Chapter 6. CSV export is ready for R/Python analysis.

4. **Minimal blast radius.** Separate `HybridMetricsStore` avoids breaking 130+ existing tests. Existing `StoryMetricsEvent` is untouched. New code paths are additive.

5. **Correct Task lifecycle.** Using `storyLoopTask` for the hybrid loop, `Task.isCancelled` checks in the loop, and `backgroundEnhancer.reset()` on exit matches the existing patterns.

6. **Scope discipline.** Tasks 1-3 + 5 is the right cut for a dissertation prototype. The 404-fallback shim for the cloud endpoint is pragmatic — proves the architecture without requiring the backend.

---

#### Implementation Order (Revised)

Based on this review, the recommended implementation order is:

1. `HybridBeatMetric.swift` + `HybridMetricsStore.swift` (no dependencies, can test immediately)
2. `CloudAgentService.requestEnhancement()` (fix C3: use `StoryBeat` not `EnhancementBeat`; fix S6: use `storyHistory` not `transcript` for fallback)
3. `BackgroundStoryEnhancer.swift` (fix C1: add timeout to `consumeEnhancedBeat`; fix S2: track `storyHistory` internally; fix M1: log errors)
4. `CompanionViewModel` changes (fix C2: `skipSemanticLayer` based on local service type; fix S4: call `localService.endSession()`; fix M2: non-lazy init; fix M3: use `pendingBeat?.question`; fix M6: speech auth check)
5. `HybridModeTests.swift` — test the timeout racing, fallback, metric recording, and CSV export


### Review 3

Here is the critical review of the `Hybrid-Mode.md` document based on thorough reading against the full project context. 

***

## Overall Verdict: **Architecturally Strong, Operationally Incomplete**

The document represents a significant conceptual leap from the old fallback-chain hybrid. The four-role specialisation model — Perception → Scene Understanding → Narrative Generation → Safety + Delivery — is genuinely novel and directly addresses the core problem you identified. The thinking is sound. However, the document has several critical gaps that would prevent a developer (or a Claude agent) from implementing it without ambiguity.

***

## What the Document Gets Right

### The Core Concept Is Correct and Publishable
The fundamental insight — that Apple FM should handle *perception and delivery*, not generation — is the most important architectural decision in the document, and it is right. 

Using Apple FM as a lightweight emotion classifier and safety filter rather than as the primary story generator is a better use of its strengths. Apple FM is optimised for fast, on-device structured inference, not long-form creative generation. Assigning it perception (face emotion, speech tone) and safety (output checking, TTS adaptation) plays to its Neural Engine strengths while leaving the creative heavy lifting to Gemma 4 or Gemini.

### The Role Separation Is Clean
The four roles are well-defined and non-overlapping.  Each model has one job. This is exactly what makes the architecture defensible in a viva — an examiner can ask "why did you use Apple FM here?" and the answer ("because it is the fastest on-device classifier for real-time perception") is technically justified, not arbitrary.

### The EmotionContext Struct Is the Right Abstraction
The `EmotionContext` struct with `childMood`, `energyLevel`, `speechTone`, and `attentionSignal` is the correct data contract between the perception layer and the generation layer.  It is minimal enough to be real-time, rich enough to meaningfully influence the downstream prompt. This is the right design.

***

## Critical Gaps That Need Addressing

### Gap 1 — `VNDetectFaceExpressionsRequest` Does Not Exist on iOS

This is the most important technical error in the document. The code references `VNDetectFaceExpressionsRequest` for face emotion detection, but **this request type does not exist in Apple's Vision framework** as a public API on iOS. 

What actually exists:
- `VNDetectFaceLandmarksRequest` — returns face geometry (eye positions, mouth shape, jaw)
- `VNDetectFaceRectanglesRequest` — detects face presence and bounding box
- Face expression classification via `Create ML` + `Vision` requires a **custom trained CoreML model** — it is not a built-in Vision request

**The fix:** Either (a) use `VNDetectFaceLandmarksRequest` and derive a crude emotion proxy from landmark geometry (open mouth = excited, closed eyes = tired), or (b) use the front camera feed with a lightweight emotion CoreML model (Apple provides one via Create ML's Image Classifier template). Option (a) is implementable in 2 hours. Option (b) needs a trained model (~4 hours including training).

If this error reaches implementation unchanged, the code will not compile.

### Gap 2 — Latency Budget Is Not Calculated

The document describes a 4-stage sequential pipeline but never calculates the total latency.  This is a critical omission because the hybrid pipeline adds two Apple FM passes (perception + safety) on top of the existing YOLO + generation pipeline. If the total round-trip exceeds 2 seconds, children will experience it as broken.

Estimated latency per stage:
- `VNDetectFaceLandmarksRequest`: ~50ms
- Apple FM speech tone classification: ~200ms
- YOLO11n-SeeSaw: ~80ms
- Gemma 4 1B story generation: ~600–800ms
- Apple FM safety check: ~150ms
- Adaptive TTS first word: ~100ms
- **Total: ~1.2–1.4 seconds**

That is acceptable. But the document should state this explicitly so there is a measurable target for the benchmark.

### Gap 3 — The Attention Signal Implementation Is Undefined

The `attentionSignal: Bool` field in `EmotionContext` appears in the struct and the adaptation table but is never implemented in the code.  "Is child looking toward camera?" requires a face presence check combined with head pose estimation, neither of which is shown.

The fix is simple: use `VNDetectFaceRectanglesRequest` — if it returns zero faces, `attentionSignal = false`. If it returns one or more faces, `attentionSignal = true`. This is a one-liner. But it needs to be stated.

### Gap 4 — The Safety Filter Implementation Is Described But Not Specified

"Apple FM safety filter pass on generated beats" appears in the architecture but the actual implementation — what prompt Apple FM receives, what constitutes a pass vs. fail, what happens on fail — is not specified. 

This matters for the dissertation because the safety layer is a research contribution (on-device safety checking, no cloud model has final authority over child content). It needs a concrete specification:
- Input: `String` (generated story beat)
- Prompt: "Is the following story beat appropriate for a child aged 4–8? Answer YES or NO only."
- Pass: response starts with "YES"
- Fail: replace with a pre-authored safe fallback beat from a local array

### Gap 5 — Benchmark Extension Is Missing

The document adds a new pipeline mode but does not extend the existing benchmark plan to cover it.  The dissertation's Chapter 6 benchmark currently measures three architectures. The hybrid mode should be a fourth row:

| Metric | Arch A (Cloud Raw) | Arch B (Cloud Filtered) | Arch C (SeeSaw) | **Arch D (Hybrid Emotion-Adaptive)** |
|--------|-------------------|------------------------|-----------------|-------------------------------------|
| PII transmitted | measured | measured | 0 | **0** |
| Latency (ms) | measured | measured | measured | **measured** |
| Story quality | rated | rated | rated | **rated — also rate on emotion adaptation quality** |
| **Emotion adaptation accuracy** | N/A | N/A | N/A | **rated: did voice/content match child state?** |

The hybrid mode's unique measurable output is whether the emotional adaptation was perceived as appropriate — this is a new rating dimension that no other architecture has.

***

## Minor Issues

- **The `buildEmotionAdaptivePrompt` function** mixes XML-style tags (`<child_state>`) with plain text in a way that Gemma 4 1B (trained on instruction-tuning format) may not handle reliably. The prompt should use the Gemma 4 chat template format (`<start_of_turn>user`) consistently throughout.

- **The emotion-to-TTS mapping table** shows `rate: 0.45` for excited state, which is higher than the 0.40 baseline established in the voice quality research. That is directionally correct (faster when excited) but the absolute value should be validated against the `ChildNarratorTTSService` rate range agreed earlier.

- **"Dual-Brain Story Engine"** is an excellent product name but should not appear in dissertation section headings — use "Emotion-Adaptive Multi-Model Pipeline" for the academic framing.

***

## Priority Fix List

1. **Replace `VNDetectFaceExpressionsRequest` with `VNDetectFaceLandmarksRequest`** — compile blocker, fix immediately
2. **Add attention signal implementation** — one-liner using `VNDetectFaceRectanglesRequest`
3. **Specify the Apple FM safety filter prompt** — needed for Chapter 4 implementation description
4. **Add Arch D to the benchmark table** — needed for Chapter 6 results
5. **Add total latency budget calculation** — needed for dissertation credibility
6. **Fix Gemma 4 prompt format** — use `<start_of_turn>` template not XML tags

The architecture is the strongest part of the entire SeeSaw project. With these fixes addressed before implementation begins, it will produce both a working feature and a compelling dissertation contribution.