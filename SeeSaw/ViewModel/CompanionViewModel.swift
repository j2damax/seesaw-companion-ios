// CompanionViewModel.swift
// SeeSaw — Tier 2 companion app
//
// Single ViewModel for PoC. Coordinates all services and drives the UI.
// Uses AccessoryManager to resolve the active WearableAccessory at connect time,
// so changing input source in Settings takes effect immediately on next connect.

import AVFoundation
import Foundation
import UIKit

@MainActor
@Observable
final class CompanionViewModel {

    // MARK: - Observable state

    var sessionState: SessionState = .idle
    var lastError: String?
    var connectedDeviceName: String?
    var childAge: Int = UserDefaults.standard.childAge
    var timeline: [TimelineEntry] = []

    /// Full-screen debug preview after "Capture Scene".
    var isShowingScenePreview: Bool = false
    var capturedImageData: Data?
    var sceneDetections: [DetectionResult] = []

    /// Live/final transcript from speech recognition.
    var currentTranscript: String?

    /// Whether audio is currently being recorded.
    var isRecording: Bool { sessionState == .recordingAudio }

    /// Exposes the currently selected type for the UI (connect button label, etc.)
    var selectedWearableType: WearableType { accessoryManager.selectedType }

    /// Live AVCaptureSession for the Camera tab preview (non-nil only when iPhone camera is active).
    var cameraPreviewSession: AVCaptureSession? { accessoryManager.previewSession }

    // MARK: - Dependencies

    private let accessoryManager: AccessoryManager
    private let privacyPipeline: PrivacyPipelineService
    private let cloudService: CloudAgentService
    private let audioService: AudioService
    private let audioCaptureService: AudioCaptureService
    private let speechRecognitionService: SpeechRecognitionService

    // MARK: - Active stream tasks (cancelled on disconnect)

    private var imageStreamTask: Task<Void, Never>?
    private var statusStreamTask: Task<Void, Never>?
    private var transcriptionStreamTask: Task<Void, Never>?

    // MARK: - Init

    init(
        accessoryManager: AccessoryManager,
        privacyPipeline: PrivacyPipelineService,
        cloudService: CloudAgentService,
        audioService: AudioService,
        audioCaptureService: AudioCaptureService,
        speechRecognitionService: SpeechRecognitionService
    ) {
        self.accessoryManager = accessoryManager
        self.privacyPipeline  = privacyPipeline
        self.cloudService     = cloudService
        self.audioService     = audioService
        self.audioCaptureService = audioCaptureService
        self.speechRecognitionService = speechRecognitionService
    }

    // MARK: - Public actions

    func startScanning() {
        let wearable = accessoryManager.activeAccessory

        // Wire lifecycle callbacks onto the specific wearable instance being connected
        wearable.onConnected    = { [weak self] in
            self?.handleConnected(name: wearable.accessoryName)
        }
        wearable.onDisconnected = { [weak self] in
            self?.handleDisconnected()
        }

        // Start observing this wearable's streams (cancel any previous observation)
        imageStreamTask?.cancel()
        statusStreamTask?.cancel()

        imageStreamTask = Task { [weak self] in
            for await imageData in wearable.imageDataStream {
                await self?.runDetectionPreview(jpegData: imageData)
            }
        }

        statusStreamTask = Task { [weak self] in
            for await status in wearable.statusStream {
                self?.handleStatus(status)
            }
        }

        sessionState = .scanning
        Task {
            do {
                try await wearable.startDiscovery()
            } catch {
                setError(error.localizedDescription)
            }
        }
    }

    func stopScanning() {
        Task { await accessoryManager.activeAccessory.stopDiscovery() }
        cancelStreamTasks()
        sessionState = .idle
    }

    func disconnect() {
        Task { await accessoryManager.activeAccessory.disconnect() }
        cancelStreamTasks()
        sessionState = .idle
        connectedDeviceName = nil
    }

    func captureScene() {
        Task {
            do {
                try await accessoryManager.activeAccessory.sendCommand(BLEConstants.cmdCapture)
            } catch {
                setError(error.localizedDescription)
            }
        }
    }

    func dismissError() {
        lastError = nil
        sessionState = sessionState.isConnected ? .connected : .idle
    }

    func dismissScenePreview() {
        isShowingScenePreview = false
        capturedImageData = nil
        sceneDetections = []
    }

    // MARK: - Audio recording & transcription

    func startRecording() {
        guard sessionState.isConnected else {
            setError("Cannot record: no device connected.")
            return
        }
        sessionState = .recordingAudio
        currentTranscript = nil
        Task {
            do {
                try await audioCaptureService.startCapture()
                let bufferStream = await audioCaptureService.audioBufferStream
                let transcriptionStream = try await speechRecognitionService.startLiveTranscription(
                    audioStream: bufferStream
                )
                transcriptionStreamTask = Task { [weak self] in
                    for await result in transcriptionStream {
                        self?.currentTranscript = SpeechRecognitionService.scrubPII(result.text)
                    }
                }
                AppConfig.shared.log("startRecording: capture and live transcription started")
            } catch {
                setError(error.localizedDescription)
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        Task {
            transcriptionStreamTask?.cancel()
            transcriptionStreamTask = nil
            let audioData = await audioCaptureService.stopCapture()
            let finalTranscript = await speechRecognitionService.stopTranscription()
            if let transcript = finalTranscript {
                currentTranscript = SpeechRecognitionService.scrubPII(transcript)
            }
            sessionState = .connected
            AppConfig.shared.log("stopRecording: audioBytes=\(audioData.count), transcript=\(currentTranscript ?? "nil")")
        }
    }

    // MARK: - Private state handlers

    private func handleConnected(name: String) {
        sessionState = .connected
        connectedDeviceName = name
    }

    private func handleDisconnected() {
        cancelStreamTasks()
        sessionState = .idle
        connectedDeviceName = nil
    }

    private func handleStatus(_ status: String) {
        switch status {
        case BLEConstants.statusTimeout:
            setError("Wearable timed out waiting for audio response.")
        case BLEConstants.statusError:
            setError("Wearable reported an error.")
        case "DISCONNECTED":
            handleDisconnected()
        default:
            break
        }
    }

    // MARK: - Detection preview pipeline (debug)

    private func runDetectionPreview(jpegData: Data) async {
        do {
            AppConfig.shared.log("runDetectionPreview: start, jpegBytes=\(jpegData.count)")

            let dataToUse: Data
            if AppConfig.shared.useTestImageForPreview {
                if let testImage = UIImage(named: "test1") {
                    if let data = testImage.pngData() {
                        AppConfig.shared.log("runDetectionPreview: using test image 'test1' for preview")
                        dataToUse = data
                    } else if let data = testImage.jpegData(compressionQuality: 1.0) {
                        AppConfig.shared.log("runDetectionPreview: using test image 'test1' (jpeg) for preview")
                        dataToUse = data
                    } else {
                        AppConfig.shared.log("runDetectionPreview: warning - test image 'test1' found but failed to extract image data, using original jpegData", level: .warning)
                        dataToUse = jpegData
                    }
                } else {
                    AppConfig.shared.log("runDetectionPreview: warning - test image asset 'test1' not found, using original jpegData", level: .warning)
                    dataToUse = jpegData
                }
            } else {
                dataToUse = jpegData
            }

            sessionState = .processingPrivacy
            let (blurredData, detections) = try await privacyPipeline.runDebugDetection(jpegData: dataToUse)
            capturedImageData  = blurredData
            sceneDetections    = detections
            isShowingScenePreview = true
            AppConfig.shared.log("runDetectionPreview: done, detectionCount=\(detections.count), blurredBytes=\(blurredData.count)")
            sessionState = .connected
        } catch {
            AppConfig.shared.log("runDetectionPreview: error=\(error.localizedDescription)", level: .error)
            setError(error.localizedDescription)
        }
    }

    // MARK: - Full pipeline (cloud + audio)

    private func runFullPipeline(jpegData: Data) async {
        do {
            sessionState = .processingPrivacy
            let payload = try await privacyPipeline.process(jpegData: jpegData, childAge: childAge)

            sessionState = .requestingStory
            let story = try await cloudService.requestStory(payload: payload)

            sessionState = .encodingAudio
            let audioData = try await audioService.generateAndEncodeAudio(from: story.storyText)

            sessionState = .sendingAudio
            try await accessoryManager.activeAccessory.sendAudio(audioData)

            // Record this interaction in the timeline (newest first)
            let entry = TimelineEntry(
                sceneObjects: payload.objects,
                storySnippet: String(story.storyText.prefix(120))
            )
            timeline.insert(entry, at: 0)

            sessionState = .connected
        } catch {
            setError(error.localizedDescription)
        }
    }

    // MARK: - Helpers

    private func cancelStreamTasks() {
        imageStreamTask?.cancel()
        statusStreamTask?.cancel()
        transcriptionStreamTask?.cancel()
        imageStreamTask  = nil
        statusStreamTask = nil
        transcriptionStreamTask = nil
    }

    private func setError(_ message: String) {
        lastError = message
        sessionState = .error(message)
    }
}

