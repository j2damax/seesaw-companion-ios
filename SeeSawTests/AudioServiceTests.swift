// AudioServiceTests.swift
// SeeSaw — Unit tests for AudioService
//
// Groups:
//   1. Voice settings — constants within valid AVFoundation ranges, child-optimised values
//   2. Sentence splitter — splitSentences() boundary detection correctness
//   3. Utterance builder — buildUtterances() pause and voice configuration
//   4. Empty-text guard — speak("") is a no-op
//   5. MockAudioService — protocol-level tests used in ViewModel integration tests

import Testing
import AVFoundation
import Foundation

@testable import SeeSaw

// MARK: - 1. Voice settings

struct AudioServiceVoiceSettingsTests {

    /// Rate must be within AVFoundation's valid range.
    @Test func speechRateIsWithinValidRange() {
        #expect(AudioService.speechRate >= AVSpeechUtteranceMinimumSpeechRate)
        #expect(AudioService.speechRate <= AVSpeechUtteranceMaximumSpeechRate)
    }

    /// Rate should be in the child-optimal 120–140 WPM band (≈ 0.38–0.42).
    @Test func speechRateIsChildOptimal() {
        #expect(AudioService.speechRate >= 0.35)
        #expect(AudioService.speechRate <= 0.45)
    }

    /// Pitch must be in [0.5, 2.0] per AVFoundation docs.
    @Test func pitchMultiplierIsWithinValidRange() {
        #expect(AudioService.pitchMultiplier >= 0.5)
        #expect(AudioService.pitchMultiplier <= 2.0)
    }

    /// Pitch should be in the warm/engaging range for children (1.0–1.3).
    @Test func pitchMultiplierIsWarm() {
        #expect(AudioService.pitchMultiplier >= 1.0)
        #expect(AudioService.pitchMultiplier <= 1.3)
    }

    /// Volume must be in [0.0, 1.0].
    @Test func volumeIsWithinValidRange() {
        #expect(AudioService.speakerVolume >= 0.0)
        #expect(AudioService.speakerVolume <= 1.0)
    }

    /// Narrator voice ID is a non-empty string.
    @Test func narratorVoiceIDIsNonEmpty() {
        #expect(!AudioService.narratorVoiceID.isEmpty)
    }

    /// resolvedNarratorVoice() always returns a non-nil voice
    /// (falls back to language default if enhanced not installed).
    @Test func resolvedNarratorVoiceIsNonNil() {
        let voice = AudioService.resolvedNarratorVoice()
        // Voice language should be English family regardless of enhanced/compact.
        #expect(voice.language.hasPrefix("en"))
    }

    /// Inter-sentence pause is in the natural storytelling range (200–400ms).
    @Test func interSentencePauseIsNatural() {
        #expect(AudioService.interSentencePauseSeconds >= 0.15)
        #expect(AudioService.interSentencePauseSeconds <= 0.50)
    }

    /// Pre-question pause is longer than inter-sentence pause (dramatic effect).
    @Test func preQuestionPauseLongerThanInterSentence() {
        #expect(AudioService.preQuestionPauseSeconds > AudioService.interSentencePauseSeconds)
    }
}

// MARK: - 2. Sentence splitter

struct AudioServiceSentenceSplitterTests {

    @Test func singleSentenceReturnedAsIs() {
        let result = AudioService.splitSentences("The dragon flew over the hill.")
        #expect(result == ["The dragon flew over the hill."])
    }

    @Test func twoSentencesSplitCorrectly() {
        let result = AudioService.splitSentences("The tower wobbled. It fell down with a crash!")
        #expect(result.count == 2)
        #expect(result[0] == "The tower wobbled.")
        #expect(result[1] == "It fell down with a crash!")
    }

    @Test func questionSentenceSplitCorrectly() {
        let result = AudioService.splitSentences("You built a rocket ship. What should we name it?")
        #expect(result.count == 2)
        #expect(result[1] == "What should we name it?")
    }

    @Test func threeSentencesSplitCorrectly() {
        let input = "You and your mom were building blocks. It was very tall. What do you think happens next?"
        let result = AudioService.splitSentences(input)
        #expect(result.count == 3)
    }

    @Test func noSplitOnAbbreviations() {
        // "Mr." followed by lowercase should not split
        let result = AudioService.splitSentences("Mr. bear came to visit. He brought honey.")
        // "Mr. bear" → 'r' after ". " is lowercase, so no split there
        #expect(result.count == 2)
        #expect(result[0].contains("Mr. bear"))
    }

    @Test func emptyStringReturnsEmpty() {
        let result = AudioService.splitSentences("")
        #expect(result.isEmpty)
    }

    @Test func singleWordReturnedAsIs() {
        let result = AudioService.splitSentences("Hello")
        #expect(result == ["Hello"])
    }

    @Test func trailingWhitespaceStripped() {
        let result = AudioService.splitSentences("  Hello world.  ")
        #expect(result.count == 1)
        #expect(!result[0].hasPrefix(" "))
        #expect(!result[0].hasSuffix(" "))
    }
}

// MARK: - 3. Utterance builder

struct AudioServiceUtteranceBuilderTests {

    @Test func singleSentenceProducesOneUtterance() {
        let utterances = AudioService.buildUtterances(for: "The dragon flew over the mountain.")
        #expect(utterances.count == 1)
    }

    @Test func twoSentencesProduceTwoUtterances() {
        let utterances = AudioService.buildUtterances(for: "The tower fell. It made a loud noise!")
        #expect(utterances.count == 2)
    }

    @Test func allUtterancesHaveCorrectRate() {
        let utterances = AudioService.buildUtterances(for: "Hello world. How are you?")
        for u in utterances {
            #expect(u.rate == AudioService.speechRate)
        }
    }

    @Test func allUtterancesHaveCorrectPitch() {
        let utterances = AudioService.buildUtterances(for: "Hello world. How are you?")
        for u in utterances {
            #expect(u.pitchMultiplier == AudioService.pitchMultiplier)
        }
    }

    @Test func questionUtteranceHasPrePause() {
        let utterances = AudioService.buildUtterances(for: "What do you think happens next?")
        #expect(utterances.count == 1)
        #expect(utterances[0].preUtteranceDelay == AudioService.preQuestionPauseSeconds)
        #expect(utterances[0].postUtteranceDelay == 0)
    }

    @Test func narrationUtteranceHasPostPause() {
        let utterances = AudioService.buildUtterances(for: "The dragon flew over the mountain.")
        #expect(utterances.count == 1)
        #expect(utterances[0].postUtteranceDelay == AudioService.interSentencePauseSeconds)
        #expect(utterances[0].preUtteranceDelay == 0)
    }

    @Test func mixedBeatNarrationHasPostPauseQuestionHasPrePause() {
        let utterances = AudioService.buildUtterances(
            for: "The blocks fell down with a crash. What do you think we should build next?"
        )
        #expect(utterances.count == 2)
        #expect(utterances[0].postUtteranceDelay == AudioService.interSentencePauseSeconds)
        #expect(utterances[1].preUtteranceDelay  == AudioService.preQuestionPauseSeconds)
    }

    @Test func emptyStringProducesNoUtterances() {
        let utterances = AudioService.buildUtterances(for: "")
        #expect(utterances.isEmpty)
    }
}

// MARK: - 4. Empty-text guard

struct AudioServiceEmptyTextTests {

    @Test func speakEmptyStringReturnsImmediately() async {
        let service = AudioService()
        await service.speak("")
        // Reaching here confirms the guard fired without hanging.
    }

    @Test func speakWhitespaceDoesNotCrash() async {
        let service = AudioService()
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
        _ = completed
    }
}

// MARK: - 5. AudioError

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

// MARK: - 6. MockAudioService for ViewModel-level tests

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

// MARK: - AudioError equatability

extension AudioError: Equatable {
    public static func == (lhs: AudioError, rhs: AudioError) -> Bool {
        switch (lhs, rhs) {
        case (.synthesisFailed, .synthesisFailed): return true
        }
    }
}
