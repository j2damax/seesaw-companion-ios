// CompanionViewModel.swift
// SeeSaw — Tier 2 companion app
//
// Single ViewModel for PoC. Coordinates all services and drives the UI.
// Observes the BLE wearable's AsyncStreams via background Tasks.

import Foundation

@MainActor
@Observable
final class CompanionViewModel {

    // MARK: - Observable state

    var sessionState: SessionState = .idle
    var lastError: String?
    var connectedDeviceName: String?
    var childAge: Int = UserDefaults.standard.childAge

    // MARK: - Services

    private let wearable: BLEService
    private let privacyPipeline: PrivacyPipelineService
    private let cloudService: CloudAgentService
    private let audioService: AudioService

    // MARK: - Stream observation tasks

    private var imageStreamTask: Task<Void, Never>?
    private var statusStreamTask: Task<Void, Never>?

    // MARK: - Init

    init(
        wearable: BLEService,
        privacyPipeline: PrivacyPipelineService,
        cloudService: CloudAgentService,
        audioService: AudioService
    ) {
        self.wearable         = wearable
        self.privacyPipeline  = privacyPipeline
        self.cloudService     = cloudService
        self.audioService     = audioService
        wireWearableCallbacks()
        startStreamObservers()
    }

    // MARK: - Public actions

    func startScanning() {
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
        Task { await wearable.stopDiscovery() }
        sessionState = .idle
    }

    func disconnect() {
        Task { await wearable.disconnect() }
        sessionState = .idle
        connectedDeviceName = nil
        imageStreamTask?.cancel()
        statusStreamTask?.cancel()
    }

    func sendCaptureCommand() {
        Task {
            do {
                try await wearable.sendCommand(BLEConstants.cmdCapture)
            } catch {
                setError(error.localizedDescription)
            }
        }
    }

    func dismissError() {
        lastError = nil
        if sessionState.isConnected {
            sessionState = .connected
        } else {
            sessionState = .idle
        }
    }

    // MARK: - Private wiring

    private func wireWearableCallbacks() {
        wearable.onConnected = { [weak self] in
            self?.handleConnected()
        }
        wearable.onDisconnected = { [weak self] in
            self?.handleDisconnected()
        }
    }

    private func startStreamObservers() {
        imageStreamTask = Task { [weak self] in
            guard let self else { return }
            for await imageData in wearable.imageDataStream {
                await self.runFullPipeline(jpegData: imageData)
            }
        }

        statusStreamTask = Task { [weak self] in
            guard let self else { return }
            for await status in wearable.statusStream {
                await self.handleStatus(status)
            }
        }
    }

    // MARK: - State handlers

    private func handleConnected() {
        sessionState = .connected
        connectedDeviceName = "AiSee"
    }

    private func handleDisconnected() {
        sessionState = .idle
        connectedDeviceName = nil
    }

    private func handleStatus(_ status: String) {
        switch status {
        case BLEConstants.statusTimeout:
            setError("AiSee timed out waiting for audio response.")
        case BLEConstants.statusError:
            setError("AiSee reported an error.")
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
            try await wearable.sendAudio(audioData)

            sessionState = .connected
        } catch {
            setError(error.localizedDescription)
        }
    }

    private func setError(_ message: String) {
        lastError = message
        sessionState = .error(message)
    }
}
