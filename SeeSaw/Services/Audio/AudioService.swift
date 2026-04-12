// AudioService.swift
// SeeSaw — Tier 2 companion app
//
// Converts story text to audio using AVSpeechSynthesizer.
//
// speak() path (iPhone): delegates to SpeechOrchestrator, which reuses a single
// AVSpeechSynthesizer to avoid IPC teardown between utterances (fixes the
// IPCAUClient -66748 error seen when a new synthesizer was created per call).
// Follows the AiSee BusFeedbackService pattern.
//
// generateAndEncodeAudio() path: offline PCM synthesis via synthesizer.write(),
// kept for Phase 2 BLE transfer to external wearables.

import AVFoundation
import Foundation
import UIKit

actor AudioService {

    // MARK: - Voice settings (exposed as internal constants for testability)

    /// BCP-47 language tag for the story narrator voice.
    /// en-US matches the AiSee BusFeedbackService configuration for consistent
    /// voice behaviour across SeeSaw and AiSee deployments.
    static let voiceLanguage = "en-US"

    /// Speech rate multiplier applied to AVSpeechUtteranceDefaultSpeechRate.
    /// 1.0 = default rate, matching the AiSee BusFeedbackService (no slowdown).
    static let speechRateMultiplier: Float = 1.0

    /// Pitch multiplier — 1.0 = neutral, matching the AiSee BusFeedbackService.
    /// Valid range: 0.5 (low) to 2.0 (high). Default is 1.0.
    static let pitchMultiplier: Float = 1.0

    /// Playback volume. 1.0 = full device volume.
    static let speakerVolume: Float = 1.0

    // MARK: - Direct speech output (iPhone / speaker path)

    /// Speaks `text` aloud through the device speaker and suspends the caller
    /// until speech is fully complete. Empty strings are skipped immediately.
    /// Sequential calls play in order because each `await` suspends until the
    /// synthesizer fires `didFinish` or `didCancel`.
    func speak(_ text: String) async {
        guard !text.isEmpty else { return }
        await SpeechOrchestrator.shared.speak(text)
    }

    // MARK: - PCM encode (BLE / wearable path — Phase 2)

    func generateAndEncodeAudio(from text: String) async throws -> Data {
        AppConfig.shared.log("generateAndEncodeAudio: start, textLength=\(text.count)")
        let data = try await synthesizeWithAVSpeech(text)
        AppConfig.shared.log("generateAndEncodeAudio: done, pcmBytes=\(data.count)")
        return data
    }

    // MARK: - Offline PCM synthesis

    @MainActor
    private func synthesizeWithAVSpeech(_ text: String) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let accumulator = AudioAccumulator()
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: AudioService.voiceLanguage)
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * AudioService.speechRateMultiplier
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
/// Design (from AiSee BusFeedbackService):
/// - One synthesizer instance avoids CoreAudio IPC teardown between calls,
///   eliminating the `IPCAUClient: can't connect to server (-66748)` warning.
/// - AVAudioSession is re-configured before each utterance to recover from
///   deactivations caused by the camera session or speech recognizer teardown.
/// - ObjectIdentifier tracking prevents stale delegate callbacks from resolving
///   the wrong continuation when a new utterance starts before the old one finishes.
/// - Interruption + app-background observers resolve any leaked continuation.
@MainActor
private final class SpeechOrchestrator: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {

    static let shared = SpeechOrchestrator()

    private let synthesizer = AVSpeechSynthesizer()
    private var speechCompletion: CheckedContinuation<Void, Never>?
    private var currentUtterance: AVSpeechUtterance?

    private override init() {
        super.init()
        synthesizer.delegate = self
        installObservers()
    }

    private func installObservers() {
        // Resume any pending continuation if the audio session is interrupted
        // (e.g. phone call arrives mid-story).
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let pending = self.speechCompletion else { return }
                AppConfig.shared.log("AudioService: session interrupted — resuming continuation", level: .warning)
                pending.resume()
                self.speechCompletion = nil
                self.currentUtterance = nil
            }
        }

        // Resume any pending continuation if the app enters background mid-speech.
        // AVSpeechSynthesizer stops speaking when backgrounded; without this the
        // continuation would never resume and the story loop would hang.
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let pending = self.speechCompletion else { return }
                AppConfig.shared.log("AudioService: app backgrounded mid-speech — stopping", level: .warning)
                self.synthesizer.stopSpeaking(at: .immediate)
                pending.resume()
                self.speechCompletion = nil
                self.currentUtterance = nil
            }
        }
    }

    func speak(_ text: String) async {
        // Re-configure AVAudioSession each call — recovers from deactivations
        // caused by camera session transitions or speech recognizer teardown.
        do {
            try configureSession()
        } catch {
            AppConfig.shared.log("AudioService: session configure failed: \(error.localizedDescription)", level: .warning)
        }

        // Discard any leftover continuation from a previous cancelled call
        // (shouldn't normally happen, but guards against stuck states).
        if let leftover = speechCompletion {
            AppConfig.shared.log("AudioService: clearing leftover continuation", level: .warning)
            currentUtterance = nil
            speechCompletion = nil
            leftover.resume()
            await Task.yield()
        }

        // Stop any in-progress speech before starting the new utterance.
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            await Task.yield()
        }

        AppConfig.shared.log("AudioService: speaking, chars=\(text.count)")

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: AudioService.voiceLanguage)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * AudioService.speechRateMultiplier
        utterance.pitchMultiplier = AudioService.pitchMultiplier
        utterance.volume = AudioService.speakerVolume

        currentUtterance = utterance
        await withCheckedContinuation { continuation in
            speechCompletion = continuation
            synthesizer.speak(utterance)
        }

        AppConfig.shared.log("AudioService: speech done, chars=\(text.count)")
    }

    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        // Only reconfigure if the category changed (e.g. another subsystem reset it).
        if session.category != .playAndRecord {
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.allowBluetooth, .defaultToSpeaker]
            )
        }
        // Re-activate each call to recover from interruptions or deactivations.
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                        didFinish utterance: AVSpeechUtterance) {
        let finishedID = ObjectIdentifier(utterance)
        Task { @MainActor [weak self] in
            guard let self,
                  let current = self.currentUtterance,
                  ObjectIdentifier(current) == finishedID else { return }
            self.speechCompletion?.resume()
            self.speechCompletion = nil
            self.currentUtterance = nil
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                        didCancel utterance: AVSpeechUtterance) {
        let cancelledID = ObjectIdentifier(utterance)
        Task { @MainActor [weak self] in
            guard let self,
                  let current = self.currentUtterance,
                  ObjectIdentifier(current) == cancelledID else { return }
            self.speechCompletion?.resume()
            self.speechCompletion = nil
            self.currentUtterance = nil
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
