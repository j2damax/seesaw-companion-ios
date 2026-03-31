// CompanionViewModel.swift
// SeeSaw — Tier 2 companion app
//
// Single ViewModel for PoC. Coordinates all services and drives the UI.
// Uses AccessoryManager to resolve the active WearableAccessory at connect time,
// so changing input source in Settings takes effect immediately on next connect.

import Foundation

@MainActor
@Observable
final class CompanionViewModel {

    // MARK: - Observable state

    var sessionState: SessionState = .idle
    var lastError: String?
    var connectedDeviceName: String?
    var childAge: Int = UserDefaults.standard.childAge

    /// Exposes the currently selected type for the UI (connect button label, etc.)
    var selectedWearableType: WearableType { accessoryManager.selectedType }

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
                await self?.runFullPipeline(jpegData: imageData)
            }
        }

        statusStreamTask = Task { [weak self] in
            for await status in wearable.statusStream {
                await self?.handleStatus(status)
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

    // MARK: - Full pipeline

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

