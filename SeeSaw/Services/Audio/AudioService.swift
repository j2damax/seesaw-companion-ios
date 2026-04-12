// AudioService.swift
// SeeSaw — Tier 2 companion app
//
// Converts story text to audio using AVSpeechSynthesizer and returns PCM Data
// ready for BLE chunked transfer. AAC encoding is a PoC placeholder.

import AVFoundation
import Foundation

actor AudioService {

    // MARK: - Direct speech output (iPhone / speaker path)

    /// Speaks `text` aloud through the device speaker and suspends the caller
    /// until speech is fully complete. Each call creates an isolated synthesizer
    /// instance so sequential calls (story text then question) play in order.
    func speak(_ text: String) async {
        guard !text.isEmpty else { return }
        await speakOnMain(text)
    }

    @MainActor
    private func speakOnMain(_ text: String) async {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        utterance.rate  = AVSpeechUtteranceDefaultSpeechRate * 0.85
        utterance.pitchMultiplier = 1.1

        // `synthesizer` and `bridge` are local vars on the async frame, so neither
        // is ARC-released before the delegate fires (the frame stays live while suspended).
        let synthesizer = AVSpeechSynthesizer()
        let bridge = SpeechFinishBridge()
        synthesizer.delegate = bridge

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            bridge.setCompletion { continuation.resume() }
            synthesizer.speak(utterance)
        }
        // Extend lifetime explicitly — compiler must not release before continuation resumes.
        withExtendedLifetime((synthesizer, bridge)) {}
    }

    // MARK: - PCM encode (BLE / wearable path — kept for Phase 2)

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
            utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
            utterance.pitchMultiplier = 1.1
            let synthesizer = AVSpeechSynthesizer()
            // Retain the synthesizer in the accumulator so it stays alive
            // until synthesis completes (otherwise ARC deallocates it mid-callback).
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

// MARK: - Thread-safe accumulator

private final class AudioAccumulator: @unchecked Sendable {
    private var buffer = Data()
    private var completed = false
    private let lock  = NSLock()
    // Strong reference keeps the synthesizer alive until the final callback fires.
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

// MARK: - Speech completion bridge

/// Bridges AVSpeechSynthesizerDelegate callbacks to a CheckedContinuation.
/// Marked @unchecked Sendable because delegate callbacks fire on the main thread
/// (same actor as speakOnMain), and the only mutable state is set once before
/// synthesis starts and cleared on first callback invocation.
private final class SpeechFinishBridge: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    private var completion: (() -> Void)?

    func setCompletion(_ block: @escaping () -> Void) {
        completion = block
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                            didFinish utterance: AVSpeechUtterance) {
        completion?()
        completion = nil
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                            didCancel utterance: AVSpeechUtterance) {
        completion?()
        completion = nil
    }
}

// MARK: - Errors

enum AudioError: LocalizedError, Sendable {
    case synthesisFailed

    var errorDescription: String? {
        "Audio synthesis failed."
    }
}
