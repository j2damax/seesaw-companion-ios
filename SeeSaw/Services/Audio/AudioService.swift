// AudioService.swift
// SeeSaw — Tier 2 companion app
//
// Converts story text to audio using AVSpeechSynthesizer.
//
// Voice quality improvements for child-directed storytelling (per Audio.md):
//   • Enhanced Samantha voice — Neural Engine backed, warmer than compact default
//   • Rate 0.40 ≈ 130 WPM — optimal for ages 3–8 (default 0.5 ≈ 170 WPM is too fast)
//   • Pitch 1.15 — +15% warmth, signals "I am talking directly to you"
//   • Sentence splitting with 250ms inter-sentence pauses
//   • 450ms pre-pause before question sentences for dramatic effect
//
// speak() path (iPhone): builds per-sentence AVSpeechUtterances, then delegates
// to SpeechOrchestrator which queues all utterances on a single persistent
// AVSpeechSynthesizer and resolves when the last one completes.
//
// generateAndEncodeAudio() path: offline PCM synthesis via synthesizer.write(),
// kept for Phase 2 BLE transfer to external wearables.

import AVFoundation
import Foundation
import UIKit

actor AudioService {

    // MARK: - Voice configuration

    /// Enhanced Samantha voice (Neural Engine backed, warm female character).
    /// Falls back to language default if not installed on the device.
    static let narratorVoiceID = "com.apple.voice.enhanced.en-US.Samantha"

    /// 0.40 ≈ 130 WPM. Children aged 3–8 process speech best at 120–140 WPM.
    /// AVSpeechUtteranceDefaultSpeechRate (0.5) produces ~170 WPM — too fast.
    static let speechRate: Float = 0.40

    /// +15% above neutral pitch. Signals warmth and direct engagement to children.
    static let pitchMultiplier: Float = 1.15

    static let speakerVolume: Float = 1.0

    /// Pause injected after each narration sentence to create a storytelling breath.
    static let interSentencePauseSeconds: TimeInterval = 0.25

    /// Pre-pause before a question sentence — signals "now it's your turn to think".
    static let preQuestionPauseSeconds: TimeInterval = 0.45

    /// Resolved narrator voice, cached at first use so the voice lookup and any
    /// WARNING log fire exactly once per app launch rather than on every speak() call.
    private static let cachedNarratorVoice: AVSpeechSynthesisVoice = resolvedNarratorVoice()

    // MARK: - Direct speech output (iPhone / speaker path)

    /// Speaks `text` aloud, splitting at sentence boundaries so pauses are injected
    /// naturally between narration and before questions.
    func speak(_ text: String) async {
        guard !text.isEmpty else { return }
        let utterances = Self.buildUtterances(for: text)
        await SpeechOrchestrator.shared.speakAll(utterances)
    }

    // MARK: - PCM encode (BLE / wearable path — Phase 2)

    func generateAndEncodeAudio(from text: String) async throws -> Data {
        AppConfig.shared.log("generateAndEncodeAudio: start, textLength=\(text.count)")
        let data = try await synthesizeWithAVSpeech(text)
        AppConfig.shared.log("generateAndEncodeAudio: done, pcmBytes=\(data.count)")
        return data
    }

    // MARK: - Utterance builder

    /// Splits `text` into sentence-level `AVSpeechUtterance` objects with voice
    /// settings and pauses calibrated for child-directed storytelling.
    ///
    /// - Each narration sentence gets a 250ms post-utterance pause.
    /// - Each question sentence gets a 450ms pre-utterance pause instead —
    ///   the pre-pause feels more dramatic and natural than a post-pause.
    static func buildUtterances(for text: String) -> [AVSpeechUtterance] {
        let voice = cachedNarratorVoice
        let sentences = splitSentences(text)

        return sentences.map { sentence in
            let utterance = AVSpeechUtterance(string: sentence)
            utterance.voice = voice
            utterance.rate = speechRate
            utterance.pitchMultiplier = pitchMultiplier
            utterance.volume = speakerVolume

            if sentence.trimmingCharacters(in: .whitespaces).hasSuffix("?") {
                utterance.preUtteranceDelay  = preQuestionPauseSeconds
            } else {
                utterance.postUtteranceDelay = interSentencePauseSeconds
            }
            return utterance
        }
    }

    /// Returns the enhanced Samantha voice, falling back to the `en-US` language
    /// default if the enhanced voice is not downloaded on this device.
    static func resolvedNarratorVoice() -> AVSpeechSynthesisVoice {
        if let enhanced = AVSpeechSynthesisVoice(identifier: narratorVoiceID) {
            return enhanced
        }
        AppConfig.shared.log(
            "AudioService: enhanced voice '\(narratorVoiceID)' not available — using language default",
            level: .warning
        )
        return AVSpeechSynthesisVoice(language: "en-US")
            ?? AVSpeechSynthesisVoice(language: "en-AU")
            ?? AVSpeechSynthesisVoice(language: "en-GB")!
    }

    /// Splits `text` at sentence boundaries (`. `, `! `, `? ` + uppercase next char).
    ///
    /// Requiring the next character to be uppercase avoids splitting on abbreviations
    /// like "Mr.", "Dr.", "U.S.", which are uncommon in child-directed story text but
    /// worth guarding against.
    static func splitSentences(_ text: String) -> [String] {
        var sentences: [String] = []
        var current = ""
        let chars = Array(text)
        var i = 0

        while i < chars.count {
            current.append(chars[i])
            // Split when: terminal punct + space + uppercase
            let isBoundary = (chars[i] == "." || chars[i] == "!" || chars[i] == "?")
                && i + 2 < chars.count
                && chars[i + 1] == " "
                && chars[i + 2].isUppercase
            if isBoundary {
                let trimmed = current.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { sentences.append(trimmed) }
                current = ""
                i += 2  // skip the space separator
            } else {
                i += 1
            }
        }
        let tail = current.trimmingCharacters(in: .whitespaces)
        if !tail.isEmpty { sentences.append(tail) }
        return sentences
    }

    // MARK: - Offline PCM synthesis (Phase 2 BLE path)

    @MainActor
    private func synthesizeWithAVSpeech(_ text: String) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let accumulator = AudioAccumulator()
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AudioService.resolvedNarratorVoice()
            utterance.rate = AudioService.speechRate
            utterance.pitchMultiplier = AudioService.pitchMultiplier
            let synthesizer = AVSpeechSynthesizer()
            accumulator.retainSynthesizer(synthesizer)
            synthesizer.write(utterance) { buffer in
                guard let pcm = buffer as? AVAudioPCMBuffer else { return }
                if pcm.frameLength == 0 {
                    accumulator.finalize(continuation: continuation)
                } else if let data = pcm.toPCMData() {
                    accumulator.append(data)
                }
            }
        }
    }
}

// MARK: - Speech orchestrator

/// Manages a persistent AVSpeechSynthesizer for the app lifetime.
///
/// Design:
/// - One synthesizer instance avoids CoreAudio IPC teardown between calls,
///   eliminating the `IPCAUClient: can't connect to server (-66748)` warning.
/// - `speakAll(_:)` accepts a pre-built utterance array and resolves a single
///   continuation when ALL utterances complete, enabling sentence-level pauses
///   to be baked into individual utterances without multiple async hops.
/// - `pendingCount` tracks how many utterances remain; both `didFinish` and
///   `didCancel` decrement it, so cancellation mid-sequence resolves cleanly.
/// - Two `Task.yield()` calls in `speakAll` ensure that stale delegate callbacks
///   from any previously-interrupted speech fire and discard before the new
///   batch's state is committed.
/// - Interruption + background observers resolve leaked continuations.
@MainActor
private final class SpeechOrchestrator: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {

    static let shared = SpeechOrchestrator()

    private let synthesizer = AVSpeechSynthesizer()
    private var speechCompletion: CheckedContinuation<Void, Never>?
    private var pendingCount = 0

    private override init() {
        super.init()
        synthesizer.delegate = self
        installObservers()
    }

    private func installObservers() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let pending = self.speechCompletion else { return }
                AppConfig.shared.log("AudioService: session interrupted — resolving continuation", level: .warning)
                self.pendingCount = 0
                self.speechCompletion = nil
                pending.resume()
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let pending = self.speechCompletion else { return }
                AppConfig.shared.log("AudioService: app backgrounded mid-speech — stopping", level: .warning)
                self.synthesizer.stopSpeaking(at: .immediate)
                self.pendingCount = 0
                self.speechCompletion = nil
                pending.resume()
            }
        }
    }

    // MARK: - Public

    func speakAll(_ utterances: [AVSpeechUtterance]) async {
        guard !utterances.isEmpty else { return }

        do {
            try configureSession()
        } catch {
            AppConfig.shared.log(
                "AudioService: session configure failed: \(error.localizedDescription)",
                level: .warning
            )
        }

        // Clear any leftover continuation from a prior interrupted call.
        // Two yield()s ensure stale delegate callbacks from the previous speech
        // have a chance to fire (and safely no-op) before the new state is set.
        if let leftover = speechCompletion {
            AppConfig.shared.log("AudioService: clearing leftover continuation", level: .warning)
            pendingCount = 0
            speechCompletion = nil
            leftover.resume()
            await Task.yield()
        }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            await Task.yield()  // let didCancel callbacks fire and discard
        }

        let totalChars = utterances.reduce(0) { $0 + $1.speechString.count }
        AppConfig.shared.log(
            "AudioService: speaking \(utterances.count) sentence(s), chars=\(totalChars)"
        )

        pendingCount = utterances.count
        await withCheckedContinuation { continuation in
            speechCompletion = continuation
            for utterance in utterances {
                synthesizer.speak(utterance)
            }
        }

        AppConfig.shared.log(
            "AudioService: speech done, sentences=\(utterances.count), chars=\(totalChars)"
        )
    }

    // MARK: - AVAudioSession

    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        if session.category != .playAndRecord {
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.allowBluetooth, .defaultToSpeaker]
            )
        }
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.pendingCount -= 1
            guard self.pendingCount <= 0, let completion = self.speechCompletion else { return }
            self.pendingCount = 0
            self.speechCompletion = nil
            completion.resume()
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.pendingCount -= 1
            guard self.pendingCount <= 0, let completion = self.speechCompletion else { return }
            self.pendingCount = 0
            self.speechCompletion = nil
            completion.resume()
        }
    }
}

// MARK: - Thread-safe PCM accumulator (Phase 2 BLE path)

private final class AudioAccumulator: @unchecked Sendable {
    private var buffer = Data()
    private var completed = false
    private let lock = NSLock()
    private var synthesizer: AVSpeechSynthesizer?

    func retainSynthesizer(_ synth: AVSpeechSynthesizer) {
        lock.withLock { synthesizer = synth }
    }

    func append(_ data: Data) {
        lock.withLock { buffer.append(data) }
    }

    func finalize(continuation: CheckedContinuation<Data, Error>) {
        lock.lock()
        guard !completed else { lock.unlock(); return }
        completed = true
        let result = buffer
        synthesizer = nil
        lock.unlock()
        continuation.resume(returning: result)
    }
}

// MARK: - Errors

enum AudioError: LocalizedError, Sendable {
    case synthesisFailed

    var errorDescription: String? {
        "Audio synthesis failed."
    }
}
