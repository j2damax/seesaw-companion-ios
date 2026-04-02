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
        return try await synthesizeWithAVSpeech(text)
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

// MARK: - AVAudioPCMBuffer → Data

private extension AVAudioPCMBuffer {
    func toPCMData() -> Data? {
        guard let channelData = floatChannelData else { return nil }
        let frameCount   = Int(frameLength)
        let channelCount = Int(format.channelCount)
        var result = Data(capacity: frameCount * channelCount * MemoryLayout<Float>.size)
        for frame in 0..<frameCount {
            for channel in 0..<channelCount {
                var sample = channelData[channel][frame]
                withUnsafeBytes(of: &sample) { result.append(contentsOf: $0) }
            }
        }
        return result
    }
}

// MARK: - Errors

enum AudioError: LocalizedError, Sendable {
    case synthesisFailed

    var errorDescription: String? {
        "Audio synthesis failed."
    }
}
