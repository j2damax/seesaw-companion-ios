// AudioService.swift
// SeeSaw — Tier 2 companion app
//
// Converts story text to audio using AVSpeechSynthesizer and returns PCM Data
// ready for BLE chunked transfer. AAC encoding is a PoC placeholder.

import AVFoundation
import Foundation

actor AudioService {

    // MARK: - Public

    func generateAndEncodeAudio(from text: String) async throws -> Data {
        AppConfig.shared.log("generateAndEncodeAudio: start, textLength=\(text.count)")
        let data = try await synthesizeWithAVSpeech(text)
        AppConfig.shared.log("generateAndEncodeAudio: done, pcmBytes=\(data.count)")
        return data
    }

    // MARK: - TTS synthesis

    @MainActor
    private func synthesizeWithAVSpeech(_ text: String) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let accumulator = AudioAccumulator()
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
            utterance.pitchMultiplier = 1.1
            let synthesizer = AVSpeechSynthesizer()
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

    func append(_ data: Data) {
        lock.withLock { buffer.append(data) }
    }

    func finalize(continuation: CheckedContinuation<Data, Error>) {
        lock.lock()
        guard !completed else { lock.unlock(); return }
        completed = true
        let result = buffer
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
