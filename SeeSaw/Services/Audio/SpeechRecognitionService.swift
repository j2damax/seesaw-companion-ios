// SpeechRecognitionService.swift
// SeeSaw — Tier 2 companion app
//
// On-device speech-to-text using SFSpeechRecognizer.
// Enforces requiresOnDeviceRecognition — no audio ever leaves the device.
//
// Supports two modes:
//   1. Live transcription from an AsyncStream<AVAudioPCMBuffer>
//   2. One-shot transcription from accumulated PCM Data
//
// PRIVACY CONTRACT: all recognition runs on-device. No cloud fallback.

import AVFoundation
import Foundation
import Speech

actor SpeechRecognitionService {

    // MARK: - State

    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    // nonisolated(unsafe): written synchronously from the SFSpeechRecognizer callback
    // (which runs on an unmanaged system thread) and read in stopTranscription after
    // task cancellation. No concurrent access — the recognition task is always cancelled
    // before stopTranscription reads this value.
    nonisolated(unsafe) private var lastTranscript: String?
    private var streamTask: Task<Void, Never>?

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    // MARK: - Live transcription

    func startLiveTranscription(
        audioStream: AsyncStream<AVAudioPCMBuffer>
    ) async throws -> AsyncStream<TranscriptionResult> {
        try validateRecognizer()
        stopCurrentTask()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        recognitionRequest = request

        var resultContinuation: AsyncStream<TranscriptionResult>.Continuation!
        let resultStream = AsyncStream<TranscriptionResult> { resultContinuation = $0 }

        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) else {
            throw SpeechRecognitionError.recognizerUnavailable
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            if let result {
                let text = result.bestTranscription.formattedString
                let isFinal = result.isFinal
                let confidence = result.bestTranscription.segments.last?.confidence ?? 0
                let transcription = TranscriptionResult(
                    text: text,
                    isFinal: isFinal,
                    confidence: confidence
                )
                resultContinuation.yield(transcription)
                self?.lastTranscript = text   // synchronous write via nonisolated(unsafe)
                if isFinal {
                    resultContinuation.finish()
                }
            }
            if let error {
                AppConfig.shared.log("recognitionTask error: \(error.localizedDescription)", level: .error)
                resultContinuation.finish()
            }
        }

        let capturedRequest = request
        streamTask = Task { [weak self] in
            for await buffer in audioStream {
                capturedRequest.append(buffer)
            }
            await self?.endRequest()
        }

        AppConfig.shared.log("startLiveTranscription: started")
        return resultStream
    }

    func stopTranscription() async -> String? {
        stopCurrentTask()
        let transcript = lastTranscript
        lastTranscript = nil
        AppConfig.shared.log("stopTranscription: transcript=\(transcript ?? "nil")")
        return transcript
    }

    // MARK: - One-shot transcription

    func transcribeAudioData(
        _ data: Data,
        sampleRate: Double = 16000,
        channels: AVAudioChannelCount = 1
    ) async throws -> String? {
        try validateRecognizer()
        guard !data.isEmpty else { return nil }

        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: channels,
            interleaved: false
        ) else {
            throw SpeechRecognitionError.invalidAudioFormat
        }

        let frameCount = data.count / (MemoryLayout<Float32>.size * Int(channels))
        guard frameCount > 0 else { return nil }

        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(frameCount)
        ) else {
            throw SpeechRecognitionError.invalidAudioFormat
        }

        buffer.frameLength = AVAudioFrameCount(frameCount)
        data.withUnsafeBytes { raw in
            guard let src = raw.bindMemory(to: Float32.self).baseAddress,
                  let dst = buffer.floatChannelData?[0] else { return }
            dst.update(from: src, count: frameCount)
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = false
        request.requiresOnDeviceRecognition = true
        request.append(buffer)
        request.endAudio()

        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")),
              recognizer.supportsOnDeviceRecognition else {
            throw SpeechRecognitionError.onDeviceNotSupported
        }

        let result: String? = try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error, result == nil {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result, result.isFinal else { return }
                let text = result.bestTranscription.formattedString
                continuation.resume(returning: text.isEmpty ? nil : text)
            }
        }

        AppConfig.shared.log("transcribeAudioData: result=\(result ?? "nil")")
        return result
    }

    // MARK: - Private helpers

    private func validateRecognizer() throws {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            throw SpeechRecognitionError.notAuthorized
        }
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")),
              recognizer.supportsOnDeviceRecognition else {
            throw SpeechRecognitionError.onDeviceNotSupported
        }
    }

    private func stopCurrentTask() {
        streamTask?.cancel()
        streamTask = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
    }

    private func endRequest() {
        recognitionRequest?.endAudio()
    }

    // updateLastTranscript removed — lastTranscript is now written synchronously
    // from the SFSpeechRecognizer callback via nonisolated(unsafe).
}

// MARK: - PII scrubbing

extension SpeechRecognitionService {

    static func scrubPII(_ text: String) -> String {
        PIIScrubber.scrub(text).scrubbed
    }
}

// MARK: - Errors

enum SpeechRecognitionError: LocalizedError, Sendable {
    case notAuthorized
    case recognizerUnavailable
    case onDeviceNotSupported
    case invalidAudioFormat

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition is not authorized. Please allow it in Settings."
        case .recognizerUnavailable:
            return "Speech recognizer is not available for the selected locale."
        case .onDeviceNotSupported:
            return "On-device speech recognition is not supported on this device."
        case .invalidAudioFormat:
            return "The audio format is not compatible with speech recognition."
        }
    }
}
