// CompanionViewModel.swift
// SeeSaw — Tier 2 companion app
//
// Single ViewModel for PoC. Coordinates all services and drives the UI.
// Uses AccessoryManager to resolve the active WearableAccessory at connect time,
// so changing input source in Settings takes effect immediately on next connect.

import AVFoundation
import Foundation

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

    /// Exposes the currently selected type for the UI (connect button label, etc.)
    var selectedWearableType: WearableType { accessoryManager.selectedType }

    /// Live AVCaptureSession for the Camera tab preview (non-nil only when iPhone camera is active).
    var cameraPreviewSession: AVCaptureSession? { accessoryManager.previewSession }

    // MARK: - Dependencies

    private let accessoryManager: AccessoryManager
    private let privacyPipeline: PrivacyPipelineService
    private let cloudService: CloudAgentService
    private let audioService: AudioService

    // MARK: - Active stream tasks (cancelled on disconnect)

    private var imageStreamTask: Task<Void, Never>?
    private var statusStreamTask: Task<Void, Never>?

    // MARK: - Init

    init(
        accessoryManager: AccessoryManager,
        privacyPipeline: PrivacyPipelineService,
        cloudService: CloudAgentService,
        audioService: AudioService
    ) {
        self.accessoryManager = accessoryManager
        self.privacyPipeline  = privacyPipeline
        self.cloudService     = cloudService
        self.audioService     = audioService
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
            sessionState = .processingPrivacy
            let (blurredData, detections) = try await privacyPipeline.runDebugDetection(jpegData: jpegData)
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
        imageStreamTask  = nil
        statusStreamTask = nil
    }

    private func setError(_ message: String) {
        lastError = message
        sessionState = .error(message)
    }
}

