// AudioCaptureService.swift
// SeeSaw — Tier 2 companion app
//
// Captures audio from the iPhone microphone via AVAudioEngine.
// Streams PCM buffers in real time for speech recognition and accumulates
// the complete recording in memory for downstream consumers.
//
// PRIVACY CONTRACT: captured audio Data is never persisted to disk.

import AVFoundation
import Foundation

actor AudioCaptureService {

    // MARK: - Configuration

    private static let sampleRate: Double = 16000
    private static let channels: AVAudioChannelCount = 1

    // MARK: - State

    private(set) var isCapturing = false
    private var audioEngine: AVAudioEngine?
    private var accumulatedData = Data()
    private var bufferContinuation: AsyncStream<AVAudioPCMBuffer>.Continuation?

    // MARK: - Public stream

    private var _audioBufferStream: AsyncStream<AVAudioPCMBuffer>?

    var audioBufferStream: AsyncStream<AVAudioPCMBuffer> {
        _audioBufferStream ?? AsyncStream { _ in }
    }

    // MARK: - Public API

    func startCapture() async throws {
        guard !isCapturing else { return }

        try await configureAudioSession()

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode

        let recordingFormat = Self.recordingFormat(for: inputNode)
        accumulatedData = Data()

        var continuation: AsyncStream<AVAudioPCMBuffer>.Continuation!
        let stream = AsyncStream<AVAudioPCMBuffer> { continuation = $0 }
        bufferContinuation = continuation
        _audioBufferStream = stream

        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: recordingFormat
        ) { [weak self] buffer, _ in
            continuation.yield(buffer)
            if let pcmData = buffer.toPCMData() {
                Task { [weak self] in await self?.appendData(pcmData) }
            }
        }

        engine.prepare()
        try engine.start()
        audioEngine = engine
        isCapturing = true

        AppConfig.shared.log("startCapture: recording started, sampleRate=\(recordingFormat.sampleRate), channels=\(recordingFormat.channelCount)")
    }

    func stopCapture() async -> Data {
        guard isCapturing else { return Data() }

        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil

        bufferContinuation?.finish()
        bufferContinuation = nil
        _audioBufferStream = nil

        isCapturing = false

        let result = accumulatedData
        accumulatedData = Data()

        await deactivateAudioSession()

        AppConfig.shared.log("stopCapture: recording stopped, accumulatedBytes=\(result.count)")
        return result
    }

    // MARK: - Permission

    func requestMicPermission() async throws {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            guard granted else { throw AudioCaptureError.permissionDenied }
        } else if status != .authorized {
            throw AudioCaptureError.permissionDenied
        }
    }

    // MARK: - Private helpers

    private func appendData(_ data: Data) {
        guard isCapturing else { return }
        accumulatedData.append(data)
    }

    private func configureAudioSession() async throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)
    }

    private func deactivateAudioSession() async {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private static func recordingFormat(for inputNode: AVAudioInputNode) -> AVAudioFormat {
        if let desired = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: channels,
            interleaved: false
        ) {
            return desired
        }
        return inputNode.outputFormat(forBus: 0)
    }
}

// MARK: - AVAudioPCMBuffer → Data

extension AVAudioPCMBuffer {
    func toPCMData() -> Data? {
        guard let channelData = floatChannelData else { return nil }
        let frameCount = Int(frameLength)
        let channelCount = Int(format.channelCount)
        guard frameCount > 0 else { return nil }
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

enum AudioCaptureError: LocalizedError, Sendable {
    case permissionDenied
    case engineStartFailed
    case notCapturing

    var errorDescription: String? {
        switch self {
        case .permissionDenied: return "Microphone access was denied. Please allow it in Settings."
        case .engineStartFailed: return "Failed to start audio capture engine."
        case .notCapturing: return "Audio capture is not active."
        }
    }
}
