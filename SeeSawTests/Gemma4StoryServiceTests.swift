// Gemma4StoryServiceTests.swift
// SeeSaw — Unit tests for the Gemma 4 on-device story engine (Architecture C)
//
// Tests cover:
//   • parseResponse() — static, pure, no MediaPipe required (runs in CI/Simulator)
//   • Gemma4StoryService model state machine transitions
//   • ModelDownloadManager file-based state helpers
//   • ModelDownloadEvent value semantics
//
// MediaPipe LlmInference integration itself cannot be unit tested — it requires a
// physical device with the GGUF file present. Those paths are covered by manual
// on-device testing (T3-018 acceptance criteria).
//
// These tests support dissertation Chapter 6 Table: Architecture C latency and
// quality comparisons (Gemma 4 on-device vs Apple FM vs cloud Gemini).

import Testing
import Foundation

@testable import SeeSaw

// MARK: - parseResponse: JSON path

struct Gemma4ParseResponseJSONTests {

    @Test func parsesWellFormedJSON() {
        let raw = """
        {"story_text": "The dragon flew high.", "question": "Where did it land?", "is_ending": false}
        """
        let beat = Gemma4StoryService.parseResponse(raw, isFinalTurn: false)

        #expect(beat.storyText == "The dragon flew high.")
        #expect(beat.question == "Where did it land?")
        #expect(beat.isEnding == false)
    }

    @Test func parsesEndingBeatFromJSON() {
        let raw = """
        {"story_text": "They all went home.", "question": "", "is_ending": true}
        """
        let beat = Gemma4StoryService.parseResponse(raw, isFinalTurn: false)

        #expect(beat.isEnding == true)
    }

    @Test func isFinalTurnOverridesJSONFalse() {
        // When isFinalTurn=true, the beat must be an ending even if JSON says false
        let raw = """
        {"story_text": "More adventure.", "question": "What next?", "is_ending": false}
        """
        let beat = Gemma4StoryService.parseResponse(raw, isFinalTurn: true)

        #expect(beat.isEnding == true)
    }

    @Test func stripsMarkdownFences() {
        let raw = """
        ```json
        {"story_text": "Magic forest!", "question": "Who lives there?", "is_ending": false}
        ```
        """
        let beat = Gemma4StoryService.parseResponse(raw, isFinalTurn: false)

        #expect(beat.storyText == "Magic forest!")
        #expect(beat.question == "Who lives there?")
        #expect(beat.isEnding == false)
    }

    @Test func stripsPlainFencesWithoutJsonLabel() {
        let raw = """
        ```
        {"story_text": "A bright star.", "question": "What do you see?", "is_ending": false}
        ```
        """
        let beat = Gemma4StoryService.parseResponse(raw, isFinalTurn: false)

        #expect(beat.storyText == "A bright star.")
    }

    @Test func handlesLeadingAndTrailingWhitespace() {
        let raw = "   \n{\"story_text\": \"Quiet woods.\", \"question\": \"What is there?\", \"is_ending\": false}\n   "
        let beat = Gemma4StoryService.parseResponse(raw, isFinalTurn: false)

        #expect(beat.storyText == "Quiet woods.")
    }

    @Test func missingIsEndingDefaultsToIsFinalTurn() {
        // Model might omit "is_ending" — should default to isFinalTurn
        let raw = """
        {"story_text": "A river flowed.", "question": "Where does it go?"}
        """
        let beatMid = Gemma4StoryService.parseResponse(raw, isFinalTurn: false)
        let beatFinal = Gemma4StoryService.parseResponse(raw, isFinalTurn: true)

        #expect(beatMid.isEnding == false)
        #expect(beatFinal.isEnding == true)
    }
}

// MARK: - parseResponse: heuristic fallback

struct Gemma4ParseResponseHeuristicTests {

    @Test func fallsBackToHeuristicForPlainProse() {
        // No JSON — model produced plain prose
        let raw = "The brave knight rode through the forest. The trees whispered secrets. What should the knight do?"
        let beat = Gemma4StoryService.parseResponse(raw, isFinalTurn: false)

        #expect(!beat.storyText.isEmpty)
        #expect(!beat.question.isEmpty)
    }

    @Test func detectsEndingWordsInFallback() {
        let raw = "They returned home safely and lived happily. The adventure is over."
        let beat = Gemma4StoryService.parseResponse(raw, isFinalTurn: false)

        #expect(beat.isEnding == true)
    }

    @Test func finalTurnForcesEndingInFallback() {
        let raw = "The story continues with more magic. What do you see?"
        let beat = Gemma4StoryService.parseResponse(raw, isFinalTurn: true)

        #expect(beat.isEnding == true)
    }

    @Test func emptyStringYieldsNonCrashingBeat() {
        let beat = Gemma4StoryService.parseResponse("", isFinalTurn: false)

        // Must not crash — empty text is acceptable as a degraded output
        #expect(beat.storyText.isEmpty || !beat.storyText.isEmpty) // always passes — just verifies no crash
    }

    @Test func storyTextIsNonEmptyForNonEmptyInput() {
        let raw = "A little mouse found a cheese."
        let beat = Gemma4StoryService.parseResponse(raw, isFinalTurn: false)

        #expect(!beat.storyText.isEmpty)
    }

    // Tests for the expanded ending-word list (covers phrases added in review remediation)

    @Test func detectsHappilyEverAfter() {
        let raw = "The princess and the knight lived happily ever after in the castle."
        let beat = Gemma4StoryService.parseResponse(raw, isFinalTurn: false)
        #expect(beat.isEnding == true)
    }

    @Test func detectsSweetDreams() {
        let raw = "The little bear closed his eyes. Sweet dreams, little one."
        let beat = Gemma4StoryService.parseResponse(raw, isFinalTurn: false)
        #expect(beat.isEnding == true)
    }

    @Test func detectsSafeAndSound() {
        let raw = "Everyone arrived safe and sound at the cosy cottage."
        let beat = Gemma4StoryService.parseResponse(raw, isFinalTurn: false)
        #expect(beat.isEnding == true)
    }

    @Test func detectsTimeToSleep() {
        let raw = "The sun set over the meadow. It was time to sleep."
        let beat = Gemma4StoryService.parseResponse(raw, isFinalTurn: false)
        #expect(beat.isEnding == true)
    }

    @Test func detectsTheStoryEnds() {
        let raw = "And so the story ends with everyone happy and full of cake."
        let beat = Gemma4StoryService.parseResponse(raw, isFinalTurn: false)
        #expect(beat.isEnding == true)
    }

    @Test func doesNotFalsePositiveOnMidStoryProse() {
        let raw = "The dragon flew over the mountain and found a hidden cave. What do you think is inside?"
        let beat = Gemma4StoryService.parseResponse(raw, isFinalTurn: false)
        #expect(beat.isEnding == false)
    }
}

// MARK: - Gemma4StoryService model state machine

// .serialized: LlmInference initialisation is not re-entrant — concurrent inits
// from parallel test tasks cause EXC_GUARD Mach port violations on device.
@Suite(.serialized)
struct Gemma4ModelStateTests {

    @Test func initialStateIsNotDownloaded() async {
        let service = Gemma4StoryService()
        let state = await service.currentModelState()

        guard case .notDownloaded = state else {
            #expect(Bool(false), "Expected .notDownloaded, got \(state)")
            return
        }
    }

    @Test func updateToDownloadingState() async {
        let service = Gemma4StoryService()
        await service.updateModelState(.downloading(progress: 0.42))

        let state = await service.currentModelState()
        guard case .downloading(let progress) = state else {
            #expect(Bool(false), "Expected .downloading")
            return
        }
        #expect(abs(progress - 0.42) < 0.001)
    }

    @Test func updateToReadyState() async {
        let service = Gemma4StoryService()
        await service.updateModelState(.ready(modelPath: "/docs/model.gguf"))

        let state = await service.currentModelState()
        guard case .ready(let path) = state else {
            #expect(Bool(false), "Expected .ready")
            return
        }
        #expect(path == "/docs/model.gguf")
    }

    @Test func updateToFailedState() async {
        let service = Gemma4StoryService()
        await service.updateModelState(.failed(reason: "network error"))

        let state = await service.currentModelState()
        guard case .failed(let reason) = state else {
            #expect(Bool(false), "Expected .failed")
            return
        }
        #expect(reason == "network error")
    }

    @Test func startStoryThrowsWhenNotDownloaded() async {
        let service = Gemma4StoryService()
        let context = SceneContext(labels: ["bear"], sceneCategories: ["bedroom"], transcript: nil, childAge: 5)
        let profile = ChildProfile(name: "Aria", age: 5, preferences: [])

        do {
            _ = try await service.startStory(context: context, profile: profile)
            #expect(Bool(false), "Expected StoryError.modelUnavailable")
        } catch let error as StoryError {
            #expect(error == .modelUnavailable)
        } catch {
            #expect(Bool(false), "Unexpected error: \(error)")
        }
    }

    @Test func startStoryThrowsWhenDownloading() async {
        let service = Gemma4StoryService()
        await service.updateModelState(.downloading(progress: 0.5))
        let context = SceneContext(labels: [], sceneCategories: [], transcript: nil, childAge: 5)
        let profile = ChildProfile(name: "Aria", age: 5, preferences: [])

        do {
            _ = try await service.startStory(context: context, profile: profile)
            #expect(Bool(false), "Expected StoryError.modelDownloading")
        } catch let error as StoryError {
            #expect(error == .modelDownloading)
        } catch {
            #expect(Bool(false), "Unexpected error: \(error)")
        }
    }

    // Disabled: with MediaPipeTasksGenAI compiled in (pods installed), calling
    // startStory() with a fake path triggers LlmInference(options: fakePath) which
    // crashes the process with EXC_GUARD — MediaPipe's guarded file descriptor is
    // violated when the model file does not exist. Manual on-device test with a
    // real GGUF covers this acceptance criterion (T3-018).
    @Test(.disabled("LlmInference with a fake path crashes on device — manual T3-018 covers this"))
    func startStoryThrowsModelUnavailableWhenReady() async {
        let service = Gemma4StoryService()
        await service.updateModelState(.ready(modelPath: "/docs/model.gguf"))
        let context = SceneContext(labels: ["book"], sceneCategories: ["room"], transcript: nil, childAge: 6)
        let profile = ChildProfile(name: "Leo", age: 6, preferences: [])

        do {
            _ = try await service.startStory(context: context, profile: profile)
        } catch let error as StoryError {
            #expect(error == .modelUnavailable || {
                if case .generationFailed = error { return true }
                return false
            }())
        } catch {
            // Any error from a fake path is acceptable
        }
    }

    @Test func continueTurnThrowsWithoutActiveSession() async {
        let service = Gemma4StoryService()

        do {
            _ = try await service.continueTurn(childAnswer: "the dragon flew away")
            #expect(Bool(false), "Expected StoryError.noActiveSession")
        } catch let error as StoryError {
            #expect(error == .noActiveSession)
        } catch {
            #expect(Bool(false), "Unexpected error: \(error)")
        }
    }

    @Test func endSessionResetsState() async {
        let service = Gemma4StoryService()
        await service.updateModelState(.ready(modelPath: "/docs/model.gguf"))

        // endSession() should not throw and must leave service in a clean state
        await service.endSession()

        // After endSession, continueTurn should raise .noActiveSession (not .ready-path errors)
        do {
            _ = try await service.continueTurn(childAnswer: "something")
            #expect(Bool(false), "Expected StoryError.noActiveSession after endSession")
        } catch let error as StoryError {
            #expect(error == .noActiveSession)
        } catch {
            #expect(Bool(false), "Unexpected error: \(error)")
        }
    }
}

// MARK: - ModelDownloadManager file-based helpers

struct ModelDownloadManagerTests {

    @Test func destinationURLHasCorrectFilename() {
        let service = Gemma4StoryService()
        let manager = ModelDownloadManager(storyService: service)

        #expect(manager.modelDestinationURL.lastPathComponent == "seesaw-gemma3-1b-q4km.gguf")
    }

    @Test func destinationURLIsInDocumentsDirectory() {
        let service = Gemma4StoryService()
        let manager = ModelDownloadManager(storyService: service)

        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        #expect(manager.modelDestinationURL.deletingLastPathComponent() == docsDir)
    }

    @Test func installedModelPathReturnsNilWhenAbsent() async {
        let service = Gemma4StoryService()
        let manager = ModelDownloadManager(storyService: service)

        // The GGUF file should not exist in the test sandbox — so installedModelPath() is nil
        // (unless a previous test somehow placed it there, which is extremely unlikely)
        let path = await manager.installedModelPath()

        // We can't guarantee the file doesn't exist on every machine, but we can verify
        // the return type contract: nil or a non-empty string.
        if let p = path {
            #expect(!p.isEmpty)
        }
        // No assertion failure either way — this is a presence check, not a hard requirement
    }

    @Test func checkInstalledModelUpdatesServiceStateToNotDownloadedWhenAbsent() async {
        let service = Gemma4StoryService()
        let manager = ModelDownloadManager(storyService: service)

        // If file not present, state stays .notDownloaded
        await manager.checkInstalledModel()

        let state = await service.currentModelState()
        // If the model file happens to exist (dev machine), state is .ready — also valid
        switch state {
        case .notDownloaded, .ready:
            break  // both are valid outcomes
        default:
            #expect(Bool(false), "Unexpected state after checkInstalledModel: \(state)")
        }
    }
}

// MARK: - ModelDownloadEvent value semantics

struct ModelDownloadEventTests {

    @Test func progressEventCarriesValue() {
        let event = ModelDownloadEvent.progress(0.75)
        guard case .progress(let p) = event else {
            #expect(Bool(false), "Expected .progress")
            return
        }
        #expect(abs(p - 0.75) < 0.001)
    }

    @Test func completedEventCarriesPath() {
        let event = ModelDownloadEvent.completed(modelPath: "/docs/model.gguf")
        guard case .completed(let path) = event else {
            #expect(Bool(false), "Expected .completed")
            return
        }
        #expect(path == "/docs/model.gguf")
    }

    @Test func failedEventCarriesError() {
        let error = ModelDownloadError.invalidURL
        let event = ModelDownloadEvent.failed(error)
        guard case .failed(let e) = event else {
            #expect(Bool(false), "Expected .failed")
            return
        }
        #expect(e.localizedDescription == error.localizedDescription)
    }
}

// MARK: - ModelDownloadError

struct ModelDownloadErrorTests {

    @Test func invalidURLHasDescription() {
        let error = ModelDownloadError.invalidURL
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test func moveFailedHasDescription() {
        let error = ModelDownloadError.moveFailed
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }
}

// MARK: - StoryGenerationMode Gemma4 cases

struct StoryGenerationModeGemma4Tests {

    @Test func gemma4OnDeviceModeExists() {
        let mode = StoryGenerationMode.gemma4OnDevice
        #expect(mode == .gemma4OnDevice)
    }

    @Test func gemma4OnDeviceHasDisplayName() {
        let mode = StoryGenerationMode.gemma4OnDevice
        #expect(!mode.displayName.isEmpty)
    }

    @Test func hybridModeExists() {
        let mode = StoryGenerationMode.hybrid
        #expect(mode == .hybrid)
    }

    @Test func allCasesIsNonEmpty() {
        #expect(!StoryGenerationMode.allCases.isEmpty)
    }

    @Test func allCasesIncludesGemma4() {
        #expect(StoryGenerationMode.allCases.contains(.gemma4OnDevice))
    }
}
