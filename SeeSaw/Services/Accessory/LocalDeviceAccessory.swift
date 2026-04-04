// LocalDeviceAccessory.swift
// SeeSaw — Tier 2 companion app
//
// WearableAccessory implementation that uses the iPhone's own hardware:
//   • Input:  Back camera (AVCaptureSession + AVCapturePhotoOutput)
//   • Input:  Built-in microphone (via PrivacyPipelineService STT path)
//   • Output: Built-in speaker (AVAudioEngine + AVAudioPlayerNode)
//
// No BLE, no Wi-Fi. The iPhone itself is the "wearable".
//
// Usage flow (matches BLEService exactly from the ViewModel's perspective):
//   1. startDiscovery()  → requests camera + mic permissions, starts AVCaptureSession
//   2. sendCommand("CAPTURE") → captures one photo → yields JPEG via imageDataStream
//   3. sendAudio(data)   → plays PCM audio through the iPhone speaker
//   4. disconnect()      → stops capture session and audio engine

import AVFoundation
import Foundation

@MainActor
final class LocalDeviceAccessory: NSObject, WearableAccessory {

    // MARK: - WearableAccessory identity

    let accessoryName  = "iPhone Camera + Mic"
    let wearableType: WearableType = .iPhoneCamera

    var isConnected: Bool { captureSession?.isRunning ?? false }

    // MARK: - WearableAccessory callbacks

    var onConnected: (() -> Void)?
    var onDisconnected: (() -> Void)?

    // MARK: - Streams
    //
    // AsyncStream is single-consumer: once a `for await` loop finishes or is
    // cancelled, a new iterator on the same stream instance will not receive
    // subsequent values.  To support disconnect → reconnect cycles we recreate
    // the stream/continuation pair each time `startDiscovery()` is called.

    private(set) var imageDataStream: AsyncStream<Data>
    private(set) var statusStream: AsyncStream<String>

    private var imageYielder: AsyncStream<Data>.Continuation?
    private var statusYielder: AsyncStream<String>.Continuation?

    // MARK: - Audio capture

    private(set) var audioDataStream: AsyncStream<Data>
    private var audioDataYielder: AsyncStream<Data>.Continuation?
    private var audioCaptureService: AudioCaptureService?
    private var audioCaptureStreamTask: Task<Void, Never>?

    // MARK: - AVFoundation

    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?

    // MARK: - Camera preview (read-only, used by CameraPreviewView)

    /// Returns the live AVCaptureSession when connected, nil otherwise.
    var previewSession: AVCaptureSession? { captureSession }

    // MARK: - Init

    override init() {
        imageDataStream = AsyncStream { $0.finish() }
        statusStream    = AsyncStream { $0.finish() }
        audioDataStream = AsyncStream { $0.finish() }
        super.init()
    }

    /// Creates fresh AsyncStream/continuation pairs so a new `for await` consumer
    /// receives all values yielded during this connection session.
    private func resetStreams() {
        var imageCont: AsyncStream<Data>.Continuation!
        var statusCont: AsyncStream<String>.Continuation!
        imageDataStream = AsyncStream { imageCont = $0 }
        statusStream    = AsyncStream { statusCont = $0 }
        imageYielder  = imageCont
        statusYielder = statusCont
    }

    // MARK: - WearableAccessory: Lifecycle

    func startDiscovery() async throws {
        resetStreams()
        try await requestCameraPermission()
        try await requestMicPermission()
        try setupCaptureSession()
        setupAudioPlayback()
        // startRunning() is synchronous and blocks; run on a detached background task
        // so the main actor is free while the session starts up.
        let session = captureSession
        Task.detached { session?.startRunning() }
        statusYielder?.yield(BLEConstants.statusReady)
        onConnected?()
    }

    func stopDiscovery() async {
        captureSession?.stopRunning()
    }

    func disconnect() async {
        captureSession?.stopRunning()
        captureSession = nil
        photoOutput    = nil
        audioEngine?.stop()
        audioEngine = nil
        playerNode  = nil
        audioCaptureStreamTask?.cancel()
        audioCaptureStreamTask = nil
        if let service = audioCaptureService {
            _ = await service.stopCapture()
            audioCaptureService = nil
        }
        audioDataYielder?.finish()
        audioDataYielder = nil
        statusYielder?.yield("DISCONNECTED")
        imageYielder?.finish()
        imageYielder = nil
        statusYielder?.finish()
        statusYielder = nil
        onDisconnected?()
    }

    // MARK: - WearableAccessory: I/O

    func sendAudio(_ data: Data) async throws {
        guard isConnected else { throw WearableError.notConnected }
        guard let engine = audioEngine, let player = playerNode else {
            throw WearableError.notConnected
        }
        try playPCMData(data, engine: engine, player: player)
    }

    func sendCommand(_ command: String) async throws {
        guard isConnected else { throw WearableError.notConnected }
        if command == BLEConstants.cmdCapture {
            AppConfig.shared.log("sendCommand: command=\(command)")
            try captureOneFrame()
        }
    }

    // MARK: - Audio capture

    func startAudioCapture() async throws {
        guard isConnected else { throw WearableError.notConnected }

        let service = AudioCaptureService()
        try await service.requestMicPermission()
        try await service.startCapture()
        audioCaptureService = service

        AppConfig.shared.log("startAudioCapture: microphone capture started")
    }

    func stopAudioCapture() async throws {
        audioCaptureStreamTask?.cancel()
        audioCaptureStreamTask = nil
        guard let service = audioCaptureService else {
            throw AudioCaptureError.notCapturing
        }
        _ = await service.stopCapture()
        audioCaptureService = nil
        audioDataYielder?.finish()
        audioDataYielder = nil
        AppConfig.shared.log("stopAudioCapture: microphone capture stopped")
    }

    // MARK: - Permission helpers

    private func requestCameraPermission() async throws {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else { throw WearableError.permissionDenied("Camera") }
        } else if status != .authorized {
            throw WearableError.permissionDenied("Camera")
        }
    }

    private func requestMicPermission() async throws {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            guard granted else { throw WearableError.permissionDenied("Microphone") }
        } else if status != .authorized {
            throw WearableError.permissionDenied("Microphone")
        }
    }

    // MARK: - Capture session setup

    private func setupCaptureSession() throws {
        let session = AVCaptureSession()
        session.sessionPreset = .medium

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back) else {
            throw WearableError.deviceUnavailable("Back camera")
        }
        let input = try AVCaptureDeviceInput(device: device)
        let output = AVCapturePhotoOutput()

        guard session.canAddInput(input), session.canAddOutput(output) else {
            throw WearableError.deviceUnavailable("Capture session configuration")
        }
        session.addInput(input)
        session.addOutput(output)

        captureSession = session
        photoOutput    = output
    }

    private func captureOneFrame() throws {
        guard let output = photoOutput else {
            throw WearableError.notConnected
        }
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - Audio playback setup

    private func setupAudioPlayback() {
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        // PCM audio as produced by AudioService: float32, ~22050 Hz, mono
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 22050,
            channels: 1,
            interleaved: false
        )
        engine.connect(player, to: engine.mainMixerNode, format: format)
        audioEngine = engine
        playerNode  = player
        try? engine.start()
    }

    private func playPCMData(_ data: Data,
                              engine: AVAudioEngine,
                              player: AVAudioPlayerNode) throws {
        let frameCount = data.count / MemoryLayout<Float32>.size
        guard frameCount > 0 else { return }
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: 22050,
                                         channels: 1,
                                         interleaved: false),
              let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                            frameCapacity: AVAudioFrameCount(frameCount)) else {
            throw WearableError.transferFailed("Could not build audio buffer")
        }
        buffer.frameLength = AVAudioFrameCount(frameCount)
        data.withUnsafeBytes { raw in
            guard let src = raw.bindMemory(to: Float32.self).baseAddress,
                  let dst = buffer.floatChannelData?[0] else { return }
            dst.update(from: src, count: frameCount)
        }
        if !engine.isRunning { try? engine.start() }
        player.stop()
        player.scheduleBuffer(buffer, completionHandler: nil)
        player.play()
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension LocalDeviceAccessory: AVCapturePhotoCaptureDelegate {

    nonisolated func photoOutput(_ output: AVCapturePhotoOutput,
                                 didFinishProcessingPhoto photo: AVCapturePhoto,
                                 error: Error?) {
        guard let data = photo.fileDataRepresentation() else { return }
        let orientation = photo.metadata[kCGImagePropertyOrientation as String] ?? "unknown"
        AppConfig.shared.log("photoOutput: capturedBytes=\(data.count), exifOrientation=\(orientation)")
        // Hop to @MainActor to safely yield into the stream
        Task { @MainActor [weak self] in
            self?.imageYielder?.yield(data)
        }
    }
}
