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
    var storyMode: StoryGenerationMode = UserDefaults.standard.storyMode {
        didSet { UserDefaults.standard.storyMode = storyMode }
    }
    var storyTurnCount: Int = 0

    /// Partial story text streamed token-by-token during on-device generation.
    /// Reset to empty when generation completes or before each new turn.
    var streamingStoryText: String = ""

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
    let metricsStore: PrivacyMetricsStore
    let storyMetricsStore: StoryMetricsStore
    private let onDeviceStoryService: OnDeviceStoryService

    // MARK: - Active stream tasks (cancelled on disconnect)

    private var imageStreamTask: Task<Void, Never>?
    private var statusStreamTask: Task<Void, Never>?
    private var transcriptionStreamTask: Task<Void, Never>?
    private var storyLoopTask: Task<Void, Never>?

    // MARK: - Init

    init(
        accessoryManager: AccessoryManager,
        privacyPipeline: PrivacyPipelineService,
        cloudService: CloudAgentService,
        audioService: AudioService,
        audioCaptureService: AudioCaptureService,
        speechRecognitionService: SpeechRecognitionService,
        metricsStore: PrivacyMetricsStore,
        storyMetricsStore: StoryMetricsStore,
        onDeviceStoryService: OnDeviceStoryService
    ) {
        self.accessoryManager = accessoryManager
        self.privacyPipeline  = privacyPipeline
        self.cloudService     = cloudService
        self.audioService     = audioService
        self.audioCaptureService = audioCaptureService
        self.speechRecognitionService = speechRecognitionService
        self.metricsStore = metricsStore
        self.storyMetricsStore = storyMetricsStore
        self.onDeviceStoryService = onDeviceStoryService
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

        // Cancel any previous stream observations
        imageStreamTask?.cancel()
        statusStreamTask?.cancel()

        sessionState = .scanning
        Task {
            do {
                // startDiscovery() resets the accessory's AsyncStreams, so we must
                // subscribe *after* this call to get the fresh stream instances.
                try await wearable.startDiscovery()

                // Now observe the newly-created streams for this connection session.
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
        Task {
            await onDeviceStoryService.endSession()
            await accessoryManager.activeAccessory.disconnect()
        }
        cancelStreamTasks()
        storyTurnCount = 0
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

    func generateStory() {
        guard let jpegData = capturedImageData else {
            setError("No captured image available for story generation.")
            return
        }
        isShowingScenePreview = false
        Task {
            await runFullPipeline(jpegData: jpegData)
        }
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
                        let scrubbed = SpeechRecognitionService.scrubPII(result.text)
                        self?.currentTranscript = scrubbed
                        if result.isFinal {
                            AppConfig.shared.log("startRecording: final transcript received, confidence=\(result.confidence)")
                        }
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
            let (blurredData, detections, metrics) = try await privacyPipeline.runDebugDetection(jpegData: dataToUse)
            await metricsStore.record(metrics)
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

    // MARK: - Full pipeline (mode-based routing)

    private func runFullPipeline(jpegData: Data) async {
        AppConfig.shared.log("runFullPipeline: start, mode=\(storyMode.rawValue), jpegBytes=\(jpegData.count), childAge=\(childAge)")
        switch storyMode {
        case .onDevice:
            await runOnDevicePipeline(jpegData: jpegData)
        case .cloud:
            await runCloudPipeline(jpegData: jpegData)
        case .hybrid:
            await runOnDevicePipeline(jpegData: jpegData)
        }
    }

    // MARK: - On-device story pipeline

    private func runOnDevicePipeline(jpegData: Data) async {
        AppConfig.shared.log("runOnDevicePipeline: start")

        // Ensure speech recognition is authorized before entering the story loop.
        // This prompts the user on first run; subsequent calls return immediately.
        let speechAuthorized = await speechRecognitionService.requestAuthorization()
        if !speechAuthorized {
            AppConfig.shared.log("runOnDevicePipeline: speech recognition not authorized, story loop will skip listening", level: .warning)
        }

        do {
            sessionState = .processingPrivacy
            let result = try await privacyPipeline.process(
                jpegData: jpegData,
                childAge: childAge
            )
            await metricsStore.record(result.metrics)
            AppConfig.shared.log("runOnDevicePipeline: privacy done, objects=\(result.payload.objects)")

            let context = SceneContext(from: result.payload)
            let profile = ChildProfile(
                name: UserDefaults.standard.childName,
                age: childAge,
                preferences: UserDefaults.standard.childPreferences
            )

            sessionState = .generatingStory
            let startTime = CFAbsoluteTimeGetCurrent()
            streamingStoryText = ""
            let beat = try await onDeviceStoryService.streamStartStory(
                context: context,
                profile: profile,
                onPartialText: { text in
                    await MainActor.run { self.streamingStoryText = text }
                }
            )
            streamingStoryText = ""
            let generationMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            AppConfig.shared.log("runOnDevicePipeline: story generated in \(Int(generationMs))ms")
            storyTurnCount = await onDeviceStoryService.currentTurnCount

            await storyMetricsStore.record(StoryMetricsEvent(
                generationMode: storyMode.rawValue,
                timeToFirstTokenMs: generationMs,
                totalGenerationMs: generationMs,
                turnCount: storyTurnCount,
                guardrailViolations: 0,
                storyTextLength: beat.storyText.count,
                timestamp: Date().timeIntervalSince1970
            ))

            sessionState = .encodingAudio
            let storyAudio = try await audioService.generateAndEncodeAudio(
                from: beat.storyText
            )
            sessionState = .sendingAudio
            try await accessoryManager.activeAccessory.sendAudio(storyAudio)

            let questionAudio = try await audioService.generateAndEncodeAudio(
                from: beat.question
            )
            try await accessoryManager.activeAccessory.sendAudio(questionAudio)

            timeline.insert(TimelineEntry(
                sceneObjects: result.payload.objects,
                storySnippet: String(beat.storyText.prefix(120))
            ), at: 0)

            if !beat.isEnding {
                storyLoopTask = Task { [weak self] in
                    await self?.continueStoryLoop()
                }
            } else {
                await onDeviceStoryService.endSession()
                storyTurnCount = 0
                sessionState = .connected
            }
        } catch let error as StoryError {
            streamingStoryText = ""
            AppConfig.shared.log("runOnDevicePipeline: StoryError=\(error.localizedDescription)", level: .error)
            await handleStoryError(error, jpegData: jpegData)
        } catch {
            streamingStoryText = ""
            AppConfig.shared.log("runOnDevicePipeline: error=\(error.localizedDescription)", level: .error)
            setError(error.localizedDescription)
        }
    }

    private func continueStoryLoop() async {
        while !Task.isCancelled {
            sessionState = .listeningForAnswer
            guard let answer = await listenForAnswer(timeoutSeconds: 15) else {
                AppConfig.shared.log("continueStoryLoop: answer timeout, ending story")
                await endStoryGracefully()
                break
            }

            sessionState = .generatingStory
            do {
                let turnStart = CFAbsoluteTimeGetCurrent()
                streamingStoryText = ""
                let beat = try await onDeviceStoryService.streamContinueTurn(
                    childAnswer: answer,
                    onPartialText: { text in
                        await MainActor.run { self.streamingStoryText = text }
                    }
                )
                streamingStoryText = ""
                let turnMs = (CFAbsoluteTimeGetCurrent() - turnStart) * 1000
                storyTurnCount = await onDeviceStoryService.currentTurnCount

                await storyMetricsStore.record(StoryMetricsEvent(
                    generationMode: storyMode.rawValue,
                    timeToFirstTokenMs: turnMs,
                    totalGenerationMs: turnMs,
                    turnCount: storyTurnCount,
                    guardrailViolations: 0,
                    storyTextLength: beat.storyText.count,
                    timestamp: Date().timeIntervalSince1970
                ))

                sessionState = .encodingAudio
                let storyAudio = try await audioService.generateAndEncodeAudio(
                    from: beat.storyText
                )
                sessionState = .sendingAudio
                try await accessoryManager.activeAccessory.sendAudio(storyAudio)

                let questionAudio = try await audioService.generateAndEncodeAudio(
                    from: beat.question
                )
                try await accessoryManager.activeAccessory.sendAudio(questionAudio)

                timeline.insert(TimelineEntry(
                    sceneObjects: [],
                    storySnippet: String(beat.storyText.prefix(120))
                ), at: 0)

                if beat.isEnding { break }
            } catch {
                streamingStoryText = ""
                AppConfig.shared.log("continueStoryLoop: error=\(error.localizedDescription)", level: .error)
                setError(error.localizedDescription)
                break
            }
        }
        await onDeviceStoryService.endSession()
        storyTurnCount = 0
        guard case .error = sessionState else {
            sessionState = .connected
            return
        }
    }

    private func listenForAnswer(timeoutSeconds: Int) async -> String? {
        do {
            try await audioCaptureService.startCapture()
            let bufferStream = await audioCaptureService.audioBufferStream
            let transcriptionStream = try await speechRecognitionService.startLiveTranscription(
                audioStream: bufferStream
            )

            let result: String? = await withTaskGroup(of: String?.self) { group in
                group.addTask { [weak self] in
                    for await result in transcriptionStream {
                        if Task.isCancelled { return nil }
                        let scrubbed = SpeechRecognitionService.scrubPII(result.text)
                        await MainActor.run { self?.currentTranscript = scrubbed }
                        if result.isFinal { return scrubbed }
                    }
                    return nil
                }
                group.addTask {
                    try? await Task.sleep(for: .seconds(timeoutSeconds))
                    return nil
                }
                let first = await group.next() ?? nil
                group.cancelAll()
                return first
            }

            _ = await audioCaptureService.stopCapture()
            _ = await speechRecognitionService.stopTranscription()
            return result
        } catch {
            AppConfig.shared.log("listenForAnswer: error=\(error.localizedDescription)", level: .error)
            return nil
        }
    }

    private func endStoryGracefully() async {
        do {
            let endBeat = StoryBeat.endingFallback
            sessionState = .encodingAudio
            let audio = try await audioService.generateAndEncodeAudio(
                from: endBeat.storyText
            )
            sessionState = .sendingAudio
            try await accessoryManager.activeAccessory.sendAudio(audio)
        } catch {
            AppConfig.shared.log("endStoryGracefully: error=\(error.localizedDescription)", level: .error)
        }
        await onDeviceStoryService.endSession()
        storyTurnCount = 0
        sessionState = .connected
    }

    private func handleStoryError(
        _ error: StoryError,
        jpegData: Data
    ) async {
        switch error {
        case .modelUnavailable, .modelDownloading:
            AppConfig.shared.log("handleStoryError: falling back to cloud pipeline")
            await runCloudPipeline(jpegData: jpegData)
        default:
            setError(error.localizedDescription)
        }
    }

    // MARK: - Cloud story pipeline

    private func runCloudPipeline(jpegData: Data) async {
        AppConfig.shared.log("runCloudPipeline: start, jpegBytes=\(jpegData.count), childAge=\(childAge)")
        do {
            sessionState = .processingPrivacy
            let result = try await privacyPipeline.process(jpegData: jpegData, childAge: childAge)
            await metricsStore.record(result.metrics)
            AppConfig.shared.log("runCloudPipeline: privacy done, objects=\(result.payload.objects), scene=\(result.payload.scene), latency=\(Int(result.metrics.pipelineLatencyMs))ms")

            sessionState = .requestingStory
            let story = try await cloudService.requestStory(payload: result.payload)
            AppConfig.shared.log("runCloudPipeline: story received, textLength=\(story.storyText.count)")

            sessionState = .encodingAudio
            let audioData = try await audioService.generateAndEncodeAudio(from: story.storyText)
            AppConfig.shared.log("runCloudPipeline: audio encoded, pcmBytes=\(audioData.count)")

            sessionState = .sendingAudio
            try await accessoryManager.activeAccessory.sendAudio(audioData)
            AppConfig.shared.log("runCloudPipeline: audio sent to accessory")

            timeline.insert(TimelineEntry(
                sceneObjects: result.payload.objects,
                storySnippet: String(story.storyText.prefix(120))
            ), at: 0)

            sessionState = .connected
            AppConfig.shared.log("runCloudPipeline: complete, timelineEntries=\(timeline.count)")
        } catch {
            AppConfig.shared.log("runCloudPipeline: error=\(error.localizedDescription)", level: .error)
            setError(error.localizedDescription)
        }
    }

    // MARK: - Helpers

    private func cancelStreamTasks() {
        imageStreamTask?.cancel()
        statusStreamTask?.cancel()
        transcriptionStreamTask?.cancel()
        storyLoopTask?.cancel()
        imageStreamTask  = nil
        statusStreamTask = nil
        transcriptionStreamTask = nil
        storyLoopTask = nil
    }

    private func setError(_ message: String) {
        AppConfig.shared.log("setError: \(message)", level: .error)
        lastError = message
        sessionState = .error(message)
    }
}

