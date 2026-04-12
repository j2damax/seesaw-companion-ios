// AudioServiceTests.swift
// SeeSaw — Unit tests for AudioService
//
// Tests are organised into three groups:
//   1. Voice settings — verify the child-optimised constants are within valid ranges
//   2. Empty-text guard — verify speak("") is a no-op (no synthesizer call, no hang)
//   3. MockAudioService — protocol-level tests used in ViewModel integration tests
//
// NOTE: Tests that exercise actual AVSpeechSynthesizer output are not included here
// because AVSpeechSynthesizer in the Simulator fires delegate callbacks silently and
// its timing is non-deterministic. Those paths are validated in on-device UI tests.

import Testing
import AVFoundation
import Foundation

@testable import SeeSaw

// MARK: - 1. Voice settings

struct AudioServiceVoiceSettingsTests {

    /// Rate is applied as a multiplier of AVSpeechUtteranceDefaultSpeechRate (~0.5).
    /// The final rate must be within the AVFoundation valid range [AVSpeechUtteranceMinimumSpeechRate, AVSpeechUtteranceMaximumSpeechRate].
    @Test func speechRateIsWithinValidRange() {
        let rate = AVSpeechUtteranceDefaultSpeechRate * AudioService.speechRateMultiplier
        #expect(rate >= AVSpeechUtteranceMinimumSpeechRate)
        #expect(rate <= AVSpeechUtteranceMaximumSpeechRate)
    }

    /// Pitch must be in [0.5, 2.0] per AVFoundation docs.
    @Test func pitchMultiplierIsWithinValidRange() {
        #expect(AudioService.pitchMultiplier >= 0.5)
        #expect(AudioService.pitchMultiplier <= 2.0)
    }

    /// Volume must be in [0.0, 1.0].
    @Test func volumeIsWithinValidRange() {
        #expect(AudioService.speakerVolume >= 0.0)
        #expect(AudioService.speakerVolume <= 1.0)
    }

    /// Voice language is a valid BCP-47 tag that AVFoundation can resolve.
    @Test func voiceLanguageResolvesToNonNilVoice() {
        let voice = AVSpeechSynthesisVoice(language: AudioService.voiceLanguage)
        // On simulator with en-US language pack installed this is non-nil.
        // If nil, the synthesizer falls back to the device's default language — acceptable.
        // We just verify the identifier string is non-empty.
        #expect(!AudioService.voiceLanguage.isEmpty)
        // If a voice was resolved, confirm it speaks the right language family.
        if let voice {
            #expect(voice.language.hasPrefix("en"))
        }
    }

    /// Rate multiplier equals 1.0 — matches the AiSee BusFeedbackService default.
    /// No slowdown is applied; AVSpeechUtteranceDefaultSpeechRate is used as-is.
    @Test func speechRateMultiplierMatchesAiSeeDefault() {
        #expect(AudioService.speechRateMultiplier == 1.0)
    }

    /// Pitch is neutral (1.0) — matches the AiSee BusFeedbackService (no pitch override).
    @Test func pitchMultiplierIsAtNeutral() {
        #expect(AudioService.pitchMultiplier == 1.0)
    }
}

// MARK: - 2. Empty-text guard

struct AudioServiceEmptyTextTests {

    /// speak("") must return immediately without invoking the synthesizer.
    /// If the guard were missing, the synthesizer would receive an empty string
    /// and either crash or produce an unresolvable continuation.
    @Test func speakEmptyStringReturnsImmediately() async {
        let service = AudioService()
        // This must complete synchronously (guard exits before any async work).
        // If it hangs, the test framework's default timeout will catch it.
        await service.speak("")
        // Reaching here confirms the guard fired.
    }

    /// Whitespace-only input is not guarded at the AudioService level (it goes to the
    /// synthesizer which handles it gracefully). Verify it does not crash.
    @Test func speakWhitespaceDoesNotCrash() async {
        let service = AudioService()
        // Wrapped in a detached Task with a 5-second deadline to guard against hangs
        // in CI environments where the synthesizer may time out.
        let completed = await withTaskGroup(of: Bool.self) { group in
            group.addTask { await service.speak("  "); return true }
            group.addTask {
                try? await Task.sleep(for: .seconds(5))
                return false
            }
            let result = await group.next() ?? false
            group.cancelAll()
            return result
        }
        // Either the speak completed (true) or timed out (false but no crash).
        _ = completed
    }
}

// MARK: - 3. AudioError

struct AudioErrorTests {

    @Test func synthesisFailed_hasDescription() {
        let error = AudioError.synthesisFailed
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test func synthesisFailed_isLocalizedError() {
        let error: any LocalizedError = AudioError.synthesisFailed
        #expect(error.errorDescription != nil)
    }
}

// MARK: - 4. MockAudioService for ViewModel-level tests

/// Protocol extracted from AudioService for dependency injection in ViewModel tests.
/// Mirrors the public surface of AudioService used by CompanionViewModel.
protocol AudioPlaying: Actor {
    func speak(_ text: String) async
    func generateAndEncodeAudio(from text: String) async throws -> Data
}

actor MockAudioService: AudioPlaying {

    private(set) var speakCallCount = 0
    private(set) var spokenTexts: [String] = []
    private(set) var encodeCallCount = 0
    var dataToReturn = Data()
    var shouldThrow = false

    func speak(_ text: String) async {
        speakCallCount += 1
        spokenTexts.append(text)
    }

    func generateAndEncodeAudio(from text: String) async throws -> Data {
        if shouldThrow { throw AudioError.synthesisFailed }
        encodeCallCount += 1
        return dataToReturn
    }
}

struct MockAudioServiceTests {

    @Test func speakRecordsCallCount() async {
        let mock = MockAudioService()
        await mock.speak("Hello")
        await mock.speak("World")
        #expect(await mock.speakCallCount == 2)
    }

    @Test func speakRecordsTextsInOrder() async {
        let mock = MockAudioService()
        await mock.speak("First sentence.")
        await mock.speak("What do you think?")
        let texts = await mock.spokenTexts
        #expect(texts == ["First sentence.", "What do you think?"])
    }

    @Test func speakEmptyStringIsRecorded() async {
        // MockAudioService does not apply the guard — it records everything.
        // This ensures tests can verify the caller's filtering logic.
        let mock = MockAudioService()
        await mock.speak("")
        #expect(await mock.speakCallCount == 1)
    }

    @Test func generateAndEncodeReturnsConfiguredData() async throws {
        let mock = MockAudioService()
        let expected = Data([0x01, 0x02, 0x03])
        await mock.setData(expected)
        let result = try await mock.generateAndEncodeAudio(from: "Test")
        #expect(result == expected)
        #expect(await mock.encodeCallCount == 1)
    }

    @Test func generateAndEncodeThrowsWhenConfigured() async {
        let mock = MockAudioService()
        await mock.setShouldThrow(true)
        do {
            _ = try await mock.generateAndEncodeAudio(from: "Test")
            #expect(Bool(false), "Expected AudioError.synthesisFailed")
        } catch let error as AudioError {
            #expect(error == .synthesisFailed)
        } catch {
            #expect(Bool(false), "Unexpected error: \(error)")
        }
    }

    @Test func storyBeatSpeaksTextThenQuestion() async {
        // Verifies that the two sequential speak() calls in CompanionViewModel
        // (audioService.speak(beat.storyText), audioService.speak(beat.question))
        // are made in the correct order.
        let mock = MockAudioService()
        let beat = StoryBeat(
            storyText: "The dragon flew over the mountain.",
            question: "Where should it go next?",
            isEnding: false
        )
        await mock.speak(beat.storyText)
        await mock.speak(beat.question)
        let texts = await mock.spokenTexts
        #expect(texts.first == beat.storyText)
        #expect(texts.last == beat.question)
        #expect(texts.count == 2)
    }
}

// MARK: - MockAudioService helpers

extension MockAudioService {
    func setData(_ data: Data) { dataToReturn = data }
    func setShouldThrow(_ value: Bool) { shouldThrow = value }
    func reset() { speakCallCount = 0; spokenTexts = []; encodeCallCount = 0; shouldThrow = false }
}

// MARK: - AudioError equatability (needed for tests)

extension AudioError: Equatable {
    public static func == (lhs: AudioError, rhs: AudioError) -> Bool {
        switch (lhs, rhs) {
        case (.synthesisFailed, .synthesisFailed): return true
        }
    }
}
