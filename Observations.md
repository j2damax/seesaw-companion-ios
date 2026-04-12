# SeeSaw Companion — Research Observations

Running log of empirical findings from test runs. Intended for MSc Thesis Chapter 6 (evaluation) and Chapter 7 (discussion).

---

## Run Metadata

| Run | Date       | Build status | Outcome |
|-----|------------|--------------|---------|
| 1   | 2026-04-12 | OK           | Failed — deserialization error (double stream.collect()) |
| 2   | 2026-04-12 | OK           | Failed — audio server conflict (AVAudioEngine eager start) |
| 3   | 2026-04-12 | OK           | Failed — context window overflow (5-field StoryBeat + 3 tools) |
| 4   | 2026-04-12 | OK           | **Success — 3 full turns, isEnding=true** |

---

## OB-001 · Apple Foundation Models — Context Window Sensitivity

**Observation:** On-device `LanguageModelSession` (3B-parameter model, iOS 26) is extremely sensitive to `@Generable` schema overhead. A 5-field `StoryBeat` struct with 3 registered tools caused context window overflow within the first story beat (approximately 3 minutes into a 6-turn session).

**Root cause:**
- `suggestedContinuation` field (described as "internal context hint") caused the model to generate a full story continuation (~1,000+ tokens) as its value, consuming the majority of the context window in a single turn.
- 3 registered tools (`AdjustDifficultyTool`, `BookmarkMomentTool`, `SwitchSceneTool`) added ~300 tokens of JSON schema to every session prompt.
- Combined overhead pushed total token count over the context window limit by the second turn.

**Fix applied:** Reduced `StoryBeat` to 3 fields (`storyText`, `question`, `isEnding`); removed all tools. Subsequent run (Run 4) completed 3 turns without overflow.

**Thesis relevance:** Demonstrates that structured output schema design is a first-class constraint when using on-device 3B models. Token-budget planning must include `@Generable` field descriptions and tool schemas, not just conversational content.

---

## OB-002 · Apple Foundation Models — Streaming ResponseStream Double-Consume Bug

**Observation:** Calling `stream.collect()` after exhausting a `ResponseStream` with `for try await` threw "Failed to deserialize a Generable type from model output".

**Root cause:** `ResponseStream` is a single-pass sequence. `for try await` exhausts it; `collect()` re-consumes an empty stream, causing the framework to attempt deserialization of zero data.

**Fix applied:** Removed `stream.collect()`. Field values are accumulated during the `for try await` loop and a `StoryBeat` is constructed from the last non-empty value of each field.

**Thesis relevance:** Undocumented framework constraint in Apple Foundation Models beta. Worth noting as a pitfall for other researchers using streaming structured generation.

---

## OB-003 · Scene Classification — VNClassifyImageRequest Label Mismatch

**Observation:** `VNClassifyImageRequest` (Stage 4, Privacy Pipeline) consistently returns `["consumer_electronics", "machine", "computer"]` across all test runs, regardless of the scene content.

**Analysis:**
- Labels are **not hardcoded**. The classifier is running correctly and genuinely reflecting the test environment (home office desk with a laptop/monitor in frame).
- `VNClassifyImageRequest` uses Apple's ImageNet-derived scene taxonomy — categories designed for machine vision, not children's storytelling.
- The categories are accurate from a computer-vision standpoint, but semantically wrong for the use case: the system prompt tells the model "Scene: consumer_electronics, machine, computer" while `contentRules` explicitly state "Never mention technology, devices, or AI."
- This creates a **prompt-level contradiction**: the model receives tech-scene context that it is simultaneously instructed to ignore.

**Potential improvements:**
1. Map Apple scene taxonomy identifiers to child-friendly place descriptions (e.g. `living_room`, `bedroom`, `garden`) and discard tech-centric labels before building the system prompt.
2. Apply a denylist filter: if all scene labels are from a tech category (electronics, computer, machine), fall back to `"an interesting place"` to avoid the contradiction.
3. Investigate whether `VNClassifyImageRequest` in the actual wearable deployment (AiSee headset, outdoor/indoor children's environment) returns more useful categories.

**Thesis relevance:** Highlights a semantic gap between general-purpose vision classifiers and child-specific deployment contexts. Relevant to RQ2 (privacy pipeline fidelity) and the discussion of scene-context quality for story grounding.

---

## OB-004 · Speech Recognition — isFinal Never Fires Within Timeout

**Observation:** `SFSpeechRecognizer` with `requiresOnDeviceRecognition = true` never produced `result.isFinal = true` within the 15-second listening window during any test run. Partial transcripts of 4–11 characters were observed via PIIScrubber logging.

**Evidence (Run 4):**
```
PIIScrubber: inputLength=4
PIIScrubber: inputLength=5
PIIScrubber: inputLength=11
PIIScrubber: inputLength=11
stopCapture: accumulatedBytes=2956800   ← 16s of audio at 48kHz mono float32
stopTranscription: transcript=          ← SpeechRecognitionService lastTranscript empty (async race)
listenForAnswer: answer=..., length=... ← ViewModel currentTranscript captured correctly
```

**Root cause of empty `stopTranscription` log:** `lastTranscript` in `SpeechRecognitionService` was written via `Task { await self.updateLastTranscript(text) }` — an async dispatch that races with `stopTranscription`. The result of `stopTranscription` is discarded (`_ = await ...`) so this does not affect story continuity; it produced a misleading log entry.

**Fix applied:** Changed `lastTranscript` to `nonisolated(unsafe)` and writes it synchronously in the recognition callback, eliminating the async race.

**On-device recognition limitation:** Short utterances (≤ 2 words) from children in a quiet room may not trigger `isFinal` because the on-device model requires a long silence or explicit `endAudio()` call to commit. The 15-second timeout correctly falls back to `currentTranscript` (last partial result), so the story continues with whatever partial answer was captured.

**Thesis relevance:** On-device `requiresOnDeviceRecognition = true` is a hard privacy constraint; the trade-off is reduced accuracy for short/child utterances compared to cloud STT. Quantifying this gap (WER, latency) is a recommended benchmark for Chapter 6.

---

## OB-005 · Story Generation Latency — Run 4 Baseline

**Observation:** With 3-field `StoryBeat` and no tools, on-device generation times (Apple Foundation Models, iPhone 14 Pro, iOS 26 beta):

| Beat | Generation time | Snapshots | Text length | isEnding |
|------|----------------|-----------|-------------|----------|
| 1    | 10 909 ms      | 11        | 332 chars   | false    |
| 2    | ~8 000 ms      | 8         | 272 chars   | false    |
| 3    | ~8 500 ms      | 8         | 276 chars   | true     |

**TTFT not yet separated in Run 4** — `timeToFirstTokenMs` was set equal to `totalGenerationMs`. Corrected from Run 5 onwards via dedicated `ttftMs` property and first-`onPartialText`-callback capture.

**TTS duration:** ~28 seconds per beat (storyText + question via `AVSpeechSynthesizer`). At 332-char storyText + ~80-char question, this is approximately 40 words at 0.85× default rate.

**Effective round-trip per turn:** generation (~9s) + TTS (~28s) + listening (15s) ≈ **52 seconds/turn**. For ages 3–8, this is at the outer limit of engagement; the 30-word cap introduced post-Run 4 should reduce TTS to ~12–15s.

**Thesis relevance:** Run 4 establishes the baseline. Next run will capture true TTFT and shorter beat durations for comparison.

---

## OB-006 · AVAudioEngine / AVSpeechSynthesizer Audio Server Contention

**Observation:** `IPCAUClient: can't connect to server (-66748)` and `AVAudioBuffer.mm:281 mBuffers[0].mDataByteSize (0) should be non-zero` appear consistently in the log after `AVSpeechSynthesizer.speak()` completes.

**Root cause:** `AVSpeechSynthesizer` and `AVAudioEngine` share the CoreAudio IPC connection to the audio server. When the synthesizer tears down its audio session after playback, it briefly invalidates the shared IPC channel, triggering the error message in any co-resident `AVAudioEngine` instance. Because `LocalDeviceAccessory` no longer starts the engine eagerly (fix applied in Run 2), it does not hold the connection open — but the synthesizer teardown still fires the warning.

**Impact:** None on functionality. TTS completes correctly and audio capture starts normally afterwards.

**Thesis relevance:** Known iOS 26 beta behaviour. Noted as a benign artefact; should be re-checked on iOS 26 GM.

---

## OB-007 · BookmarkMomentTool Token Budget

**Observation:** With `StoryBeat` reduced to 3 fields, the per-session `@Generable` schema budget allows re-enabling one lightweight tool without triggering context overflow.

**Token budget estimate (per session turn at turn 4):**
- 3-field `StoryBeat` schema: ~120 tokens
- `BookmarkMomentTool` schema (1 string argument): ~65 tokens
- System prompt + `contentRules`: ~80 tokens
- Per-turn conversation history (3 short turns): ~300–450 tokens
- **Estimated total: ~565–715 tokens** — within the on-device model's context window

`AdjustDifficultyTool` and `SwitchSceneTool` remain disabled. Their combined schema (~400 additional tokens) would push long sessions over the limit.

**Note:** `BookmarkMomentTool` is added only to the initial `LanguageModelSession` (story start). The `restartWithSummary` session remains tool-free to keep the context-recovery path as lean as possible.

**Thesis relevance:** Tool use in Apple Foundation Models adds schema overhead that directly competes with conversational context. For on-device 3B models, a practical limit of 1–2 lightweight tools applies. This is not documented in Apple's WWDC 2025 Foundation Models session.

---

*Updated: 2026-04-12. Add new entries after each test run with run number, date, and observations.*
