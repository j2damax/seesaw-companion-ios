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

    let imageDataStream: AsyncStream<Data>
    let statusStream: AsyncStream<String>

    private let imageYielder: AsyncStream<Data>.Continuation
    private let statusYielder: AsyncStream<String>.Continuation

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
        var imageCont: AsyncStream<Data>.Continuation!
        var statusCont: AsyncStream<String>.Continuation!
        imageDataStream = AsyncStream { imageCont = $0 }
        statusStream    = AsyncStream { statusCont = $0 }
        imageYielder  = imageCont
        statusYielder = statusCont
        super.init()
    }

    // MARK: - WearableAccessory: Lifecycle

    func startDiscovery() async throws {
        try await requestCameraPermission()
        try await requestMicPermission()
        try setupCaptureSession()
        setupAudioPlayback()
        // startRunning() is synchronous and blocks; run on a background thread.
        let session = captureSession
        await Task.detached { session?.startRunning() }.value
        statusYielder.yield(BLEConstants.statusReady)
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
        statusYielder.yield("DISCONNECTED")
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
            try captureOneFrame()
        }
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
        // Hop to @MainActor to safely yield into the stream
        Task { @MainActor [weak self] in
            self?.imageYielder.yield(data)
        }
    }
}
