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
    var capturedImageData: Data?          // privacy-filtered (blurred) JPEG
    var originalCapturedImageData: Data?  // original unblurred JPEG
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
    let gemma4StoryService: Gemma4StoryService
    let modelDownloadManager: ModelDownloadManager
    private let storyTimelineStore: StoryTimelineStore
    private let hybridMetricsStore: HybridMetricsStore
    private let backgroundEnhancer: BackgroundStoryEnhancer
    private let turnDetector = SemanticTurnDetector()

    // MARK: - Active stream tasks (cancelled on disconnect)

    private var imageStreamTask: Task<Void, Never>?
    private var statusStreamTask: Task<Void, Never>?
    private var transcriptionStreamTask: Task<Void, Never>?
    private var storyLoopTask: Task<Void, Never>?

    // TTFT (time-to-first-token) tracking per generation beat — dissertation benchmark.
    // Reset before each streamStartStory / streamContinueTurn call.
    private var generationStartTime: CFAbsoluteTime = 0
    private var ttftMs: Double = 0

    // MARK: - Timeline session tracking (in-progress session state)

    /// The SwiftData record for the currently active story session.
    private var currentSession: StorySessionRecord?
    /// The last beat record awaiting the child's answer.
    private var pendingBeat: StoryBeatRecord?
    /// Global beat counter within the session (never resets, used for sequenceNumber).
    private var currentBeatSequence = 0
    /// The local beat index from the previous beat; used to detect context restarts.
    private var prevLocalBeatIndex = -1
    /// Accumulated PII count for the answer currently being captured.
    private var latestAnswerPiiCount = 0
    /// Whether restartWithSummary has been triggered in this session.
    private var sessionHadRestart = false

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
        onDeviceStoryService: OnDeviceStoryService,
        gemma4StoryService: Gemma4StoryService,
        modelDownloadManager: ModelDownloadManager,
        storyTimelineStore: StoryTimelineStore,
        hybridMetricsStore: HybridMetricsStore
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
        self.gemma4StoryService = gemma4StoryService
        self.modelDownloadManager = modelDownloadManager
        self.storyTimelineStore = storyTimelineStore
        self.hybridMetricsStore = hybridMetricsStore
        self.backgroundEnhancer = BackgroundStoryEnhancer(cloudService: cloudService)
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
        finalizeCurrentSession()
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
        isShowingScenePreview     = false
        capturedImageData         = nil
        originalCapturedImageData = nil
        sceneDetections           = []
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
            originalCapturedImageData = dataToUse
            capturedImageData         = blurredData
            sceneDetections           = detections
            isShowingScenePreview     = true
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
        case .gemma4OnDevice:
            await runGemma4Pipeline(jpegData: jpegData)
        case .cloud:
            await runCloudPipeline(jpegData: jpegData)
        case .hybrid:
            // Fallback chain: cloud → gemma4OnDevice → onDevice
            await runHybridPipeline(jpegData: jpegData)
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
                childAge: childAge,
                childName: UserDefaults.standard.childName,
                generationMode: storyMode.rawValue
            )
            await metricsStore.record(result.metrics)
            AppConfig.shared.log("runOnDevicePipeline: privacy done, objects=\(result.payload.objects)")

            let context = SceneContext(from: result.payload)
            let profile = ChildProfile(
                name: UserDefaults.standard.childName,
                age: childAge,
                preferences: UserDefaults.standard.childPreferences
            )

            // Begin timeline session with captured (blurred) image + pipeline metrics
            beginStorySession(
                jpegData: jpegData,
                payload: result.payload,
                privacyMetrics: result.metrics,
                childName: profile.name,
                childAge: profile.age
            )

            sessionState = .generatingStory
            generationStartTime = CFAbsoluteTimeGetCurrent()
            ttftMs = 0
            streamingStoryText = ""
            let beat = try await onDeviceStoryService.streamStartStory(
                context: context,
                profile: profile,
                onPartialText: { text in
                    await MainActor.run { [weak self] in
                        guard let self else { return }
                        if self.ttftMs == 0 {
                            self.ttftMs = (CFAbsoluteTimeGetCurrent() - self.generationStartTime) * 1000
                        }
                        self.streamingStoryText = text
                    }
                }
            )
            streamingStoryText = ""
            let generationMs = (CFAbsoluteTimeGetCurrent() - generationStartTime) * 1000
            AppConfig.shared.log("runOnDevicePipeline: story generated in \(Int(generationMs))ms, ttft=\(Int(ttftMs))ms")
            AppConfig.shared.log("beat[0] storyText: \(beat.storyText)")
            AppConfig.shared.log("beat[0] question: \(beat.question)")
            storyTurnCount = await onDeviceStoryService.currentTurnCount
            recordBeat(beat, generationMs: generationMs, ttftMs: ttftMs, localIndex: 0)

            await storyMetricsStore.record(StoryMetricsEvent(
                generationMode: storyMode.rawValue,
                timeToFirstTokenMs: ttftMs,
                totalGenerationMs: generationMs,
                turnCount: storyTurnCount,
                guardrailViolations: 0,
                storyTextLength: beat.storyText.count,
                timestamp: Date().timeIntervalSince1970
            ))

            // Speak story then question; each call suspends until the synthesizer
            // finishes, so the story loop cannot start listening until both are done.
            sessionState = .sendingAudio
            await audioService.speak(beat.storyText)
            await audioService.speak(beat.question)

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
                finalizeCurrentSession()
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
            latestAnswerPiiCount = 0
            guard let answer = await listenForAnswer(question: pendingBeat?.question ?? "") else {
                AppConfig.shared.log("continueStoryLoop: answer timeout, ending story")
                await endStoryGracefully()
                break
            }

            // Record the child's answer on the beat that asked the question
            recordAnswer(answer, piiCount: latestAnswerPiiCount)

            sessionState = .generatingStory
            do {
                generationStartTime = CFAbsoluteTimeGetCurrent()
                ttftMs = 0
                streamingStoryText = ""
                let beat = try await onDeviceStoryService.streamContinueTurn(
                    childAnswer: answer,
                    onPartialText: { text in
                        await MainActor.run { [weak self] in
                            guard let self else { return }
                            if self.ttftMs == 0 {
                                self.ttftMs = (CFAbsoluteTimeGetCurrent() - self.generationStartTime) * 1000
                            }
                            self.streamingStoryText = text
                        }
                    }
                )
                streamingStoryText = ""
                let turnMs = (CFAbsoluteTimeGetCurrent() - generationStartTime) * 1000
                AppConfig.shared.log("beat[\(storyTurnCount)] storyText: \(beat.storyText)")
                AppConfig.shared.log("beat[\(storyTurnCount)] question: \(beat.question)")
                storyTurnCount = await onDeviceStoryService.currentTurnCount
                recordBeat(beat, generationMs: turnMs, ttftMs: ttftMs, localIndex: storyTurnCount)

                await storyMetricsStore.record(StoryMetricsEvent(
                    generationMode: storyMode.rawValue,
                    timeToFirstTokenMs: ttftMs,
                    totalGenerationMs: turnMs,
                    turnCount: storyTurnCount,
                    guardrailViolations: 0,
                    storyTextLength: beat.storyText.count,
                    timestamp: Date().timeIntervalSince1970
                ))

                sessionState = .sendingAudio
                await audioService.speak(beat.storyText)
                await audioService.speak(beat.question)

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
        finalizeCurrentSession()
        storyTurnCount = 0
        guard case .error = sessionState else {
            sessionState = .connected
            return
        }
    }

    /// - Parameters:
    ///   - skipSemanticLayer: When `true`, Layer 2 (Apple FM semantic check) is skipped entirely.
    ///     Pass `true` from Gemma pipelines — Apple FM is unavailable in that context and calling it
    ///     causes an ~8-second post-hard-cap hang while the Foundation Models cancellation surfaces.
    private func listenForAnswer(timeoutSeconds: Int = 8, question: String, skipSemanticLayer: Bool = false) async -> String? {
        // Clear stale transcript from the previous turn so the hard-cap fallback
        // doesn't return an old answer when the child is silent this turn.
        currentTranscript = nil
        do {
            try await audioCaptureService.startCapture()
            let bufferStream = await audioCaptureService.audioBufferStream
            let transcriptionStream = try await speechRecognitionService.startLiveTranscription(
                audioStream: bufferStream
            )

            let result: String? = await withTaskGroup(of: String?.self) { group in
                // Task 1: isFinal path (preserved from original — fires when STT is confident)
                group.addTask { [weak self] in
                    for await result in transcriptionStream {
                        if Task.isCancelled { return nil }
                        let (scrubbed, piiCount) = PIIScrubber.scrub(result.text)
                        await MainActor.run { [weak self] in
                            self?.currentTranscript = scrubbed
                            self?.latestAnswerPiiCount = piiCount
                        }
                        if result.isFinal { return scrubbed }
                    }
                    return nil
                }
                // Task 2: hard cap (Layer 3)
                group.addTask { [weak self] in
                    try? await Task.sleep(for: .seconds(timeoutSeconds))
                    AppConfig.shared.log("listenForAnswer: hard cap reached (\(timeoutSeconds)s)")
                    // On timeout return whatever partial transcript was accumulated,
                    // so a short or interrupted utterance still drives the story forward.
                    return await MainActor.run { self?.currentTranscript }
                }
                // Task 3: semantic watchdog (Layers 1 & 2)
                group.addTask { [weak self] in
                    guard let self else { return nil }
                    var lastSeen = ""
                    var lastChangeTime = CFAbsoluteTimeGetCurrent()
                    var heuristicFired = false

                    while !Task.isCancelled {
                        try? await Task.sleep(for: .milliseconds(200))
                        let current = await MainActor.run { self.currentTranscript ?? "" }

                        if current != lastSeen {
                            lastSeen = current
                            lastChangeTime = CFAbsoluteTimeGetCurrent()
                            heuristicFired = false
                            continue
                        }
                        guard !lastSeen.isEmpty else { continue }

                        let silence = CFAbsoluteTimeGetCurrent() - lastChangeTime
                        guard silence >= SemanticTurnDetector.silenceThresholdSeconds else { continue }

                        // Layer 1: heuristic trailing-phrase check
                        let incomplete = await self.turnDetector.isIncomplete(transcript: lastSeen)
                        if !heuristicFired && incomplete {
                            AppConfig.shared.log("listenForAnswer: Layer 1 heuristic extend, trailing phrase detected")
                            heuristicFired = true
                            lastChangeTime = CFAbsoluteTimeGetCurrent()
                            continue
                        }

                        // Layer 2: Apple FM semantic completion check
                        // Skipped in Gemma mode — Apple FM is not available there and the async
                        // cancellation takes ~8s to surface, causing a post-hard-cap freeze.
                        if skipSemanticLayer {
                            AppConfig.shared.log("listenForAnswer: Layer 2 skipped (Gemma mode) — returning transcript after silence")
                            return lastSeen
                        }
                        AppConfig.shared.log("listenForAnswer: Layer 2 semantic check starting")
                        let done = await self.turnDetector.semanticCheck(transcript: lastSeen, question: question)
                        if done {
                            AppConfig.shared.log("listenForAnswer: Layer 2 complete → returning transcript")
                            return lastSeen
                        }
                        // Extend silence window by semanticExtensionSeconds (implicit — reset clock)
                        lastChangeTime = CFAbsoluteTimeGetCurrent()
                    }
                    return nil
                }
                let first = await group.next() ?? nil
                group.cancelAll()
                return first
            }

            _ = await audioCaptureService.stopCapture()
            _ = await speechRecognitionService.stopTranscription()
            let answerLen = result?.count ?? 0
            AppConfig.shared.log("listenForAnswer: answer='\(result ?? "nil")', length=\(answerLen)")
            // Convert empty-string result to nil so callers correctly invoke endStoryGracefully()
            return result?.isEmpty == true ? nil : result
        } catch {
            AppConfig.shared.log("listenForAnswer: error=\(error.localizedDescription)", level: .error)
            return nil
        }
    }

    private func endStoryGracefully() async {
        sessionState = .sendingAudio
        await audioService.speak(StoryBeat.endingFallback.storyText)
        await onDeviceStoryService.endSession()
        finalizeCurrentSession()
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

    // MARK: - Gemma 4 on-device story pipeline

    /// Identical flow to `runOnDevicePipeline` but uses `Gemma4StoryService`.
    /// Falls back to `runOnDevicePipeline` silently when the model is not yet
    /// downloaded or MediaPipe integration is pending.
    private func runGemma4Pipeline(jpegData: Data) async {
        AppConfig.shared.log("runGemma4Pipeline: start")
        let speechAuthorized = await speechRecognitionService.requestAuthorization()
        if !speechAuthorized {
            AppConfig.shared.log("runGemma4Pipeline: speech not authorized", level: .warning)
        }

        do {
            sessionState = .processingPrivacy
            let result = try await privacyPipeline.process(jpegData: jpegData, childAge: childAge, childName: UserDefaults.standard.childName, generationMode: storyMode.rawValue)
            await metricsStore.record(result.metrics)

            let context = SceneContext(from: result.payload)
            let profile = ChildProfile(
                name: UserDefaults.standard.childName,
                age: childAge,
                preferences: UserDefaults.standard.childPreferences
            )

            beginStorySession(
                jpegData: jpegData,
                payload: result.payload,
                privacyMetrics: result.metrics,
                childName: profile.name,
                childAge: profile.age
            )

            sessionState = .generatingStory
            generationStartTime = CFAbsoluteTimeGetCurrent()
            ttftMs = 0
            streamingStoryText = ""

            AppConfig.shared.log("runGemma4Pipeline: privacy done, objects=\(result.payload.objects), scene=\(result.payload.scene)")
            let beat = try await gemma4StoryService.startStory(context: context, profile: profile)
            streamingStoryText = ""
            let generationMs = (CFAbsoluteTimeGetCurrent() - generationStartTime) * 1000
            AppConfig.shared.log("runGemma4Pipeline: beat[0] generated in \(Int(generationMs))ms, ttft=\(Int(ttftMs))ms")
            AppConfig.shared.log("beat[0] storyText: \(beat.storyText)")
            AppConfig.shared.log("beat[0] question: \(beat.question)")
            AppConfig.shared.log("beat[0] isEnding: \(beat.isEnding)")
            storyTurnCount = await gemma4StoryService.currentTurnCount
            recordBeat(beat, generationMs: generationMs, ttftMs: ttftMs, localIndex: 0)

            await storyMetricsStore.record(StoryMetricsEvent(
                generationMode: storyMode.rawValue,
                timeToFirstTokenMs: ttftMs,
                totalGenerationMs: generationMs,
                turnCount: storyTurnCount,
                guardrailViolations: 0,
                storyTextLength: beat.storyText.count,
                timestamp: Date().timeIntervalSince1970
            ))

            sessionState = .sendingAudio
            await audioService.speak(beat.storyText)
            await audioService.speak(beat.question)

            timeline.insert(TimelineEntry(
                sceneObjects: result.payload.objects,
                storySnippet: String(beat.storyText.prefix(120))
            ), at: 0)

            if !beat.isEnding {
                storyLoopTask = Task { [weak self] in
                    await self?.continueGemma4Loop()
                }
            } else {
                await gemma4StoryService.endSession()
                finalizeCurrentSession()
                storyTurnCount = 0
                sessionState = .connected
            }
        } catch let error as StoryError where
            error == .modelUnavailable || error == .modelDownloading {
            AppConfig.shared.log("runGemma4Pipeline: model not ready, falling back to Apple FM", level: .warning)
            streamingStoryText = ""
            await runOnDevicePipeline(jpegData: jpegData)
        } catch {
            streamingStoryText = ""
            AppConfig.shared.log("runGemma4Pipeline: error=\(error.localizedDescription)", level: .error)
            setError(error.localizedDescription)
        }
    }

    private func continueGemma4Loop() async {
        let sessionStart = CFAbsoluteTimeGetCurrent()
        var loopIteration = 0
        while !Task.isCancelled {
            loopIteration += 1
            let sessionElapsed = Int((CFAbsoluteTimeGetCurrent() - sessionStart) * 1000)
            AppConfig.shared.log("continueGemma4Loop: iteration=\(loopIteration), sessionElapsed=\(sessionElapsed)ms")

            sessionState = .listeningForAnswer
            latestAnswerPiiCount = 0
            AppConfig.shared.log("continueGemma4Loop: listening (skipSemanticLayer=true)")
            let listenStart = CFAbsoluteTimeGetCurrent()
            // skipSemanticLayer=true: Layer 2 Apple FM check is skipped to avoid ~8s hang
            // caused by FoundationModels cancellation delay after the hard cap fires.
            guard let answer = await listenForAnswer(question: pendingBeat?.question ?? "", skipSemanticLayer: true) else {
                let listenMs = Int((CFAbsoluteTimeGetCurrent() - listenStart) * 1000)
                AppConfig.shared.log("continueGemma4Loop: no answer after \(listenMs)ms, ending story")
                await endStoryGracefully()
                break
            }
            let listenMs = Int((CFAbsoluteTimeGetCurrent() - listenStart) * 1000)
            recordAnswer(answer, piiCount: latestAnswerPiiCount)
            AppConfig.shared.log("continueGemma4Loop: answer='\(answer)', listenTime=\(listenMs)ms, piiCount=\(latestAnswerPiiCount)")

            sessionState = .generatingStory
            do {
                generationStartTime = CFAbsoluteTimeGetCurrent()
                ttftMs = 0
                streamingStoryText = ""
                let beat = try await gemma4StoryService.continueTurn(childAnswer: answer)
                streamingStoryText = ""
                let turnMs = (CFAbsoluteTimeGetCurrent() - generationStartTime) * 1000
                let sessionElapsedNow = Int((CFAbsoluteTimeGetCurrent() - sessionStart) * 1000)
                storyTurnCount = await gemma4StoryService.currentTurnCount
                recordBeat(beat, generationMs: turnMs, ttftMs: ttftMs, localIndex: storyTurnCount)
                AppConfig.shared.log("continueGemma4Loop: beat[\(storyTurnCount)] generated in \(Int(turnMs))ms, sessionElapsed=\(sessionElapsedNow)ms")
                AppConfig.shared.log("beat[\(storyTurnCount)] storyText: \(beat.storyText)")
                AppConfig.shared.log("beat[\(storyTurnCount)] question: \(beat.question)")
                AppConfig.shared.log("beat[\(storyTurnCount)] isEnding: \(beat.isEnding)")

                await storyMetricsStore.record(StoryMetricsEvent(
                    generationMode: storyMode.rawValue,
                    timeToFirstTokenMs: ttftMs,
                    totalGenerationMs: turnMs,
                    turnCount: storyTurnCount,
                    guardrailViolations: 0,
                    storyTextLength: beat.storyText.count,
                    timestamp: Date().timeIntervalSince1970
                ))

                sessionState = .sendingAudio
                await audioService.speak(beat.storyText)
                await audioService.speak(beat.question)

                timeline.insert(TimelineEntry(sceneObjects: [], storySnippet: String(beat.storyText.prefix(120))), at: 0)
                if beat.isEnding { break }
            } catch {
                streamingStoryText = ""
                AppConfig.shared.log("continueGemma4Loop: error=\(error.localizedDescription)", level: .error)
                setError(error.localizedDescription)
                break
            }
        }
        await gemma4StoryService.endSession()
        finalizeCurrentSession()
        storyTurnCount = 0
        guard case .error = sessionState else {
            sessionState = .connected
            return
        }
    }

    // MARK: - Hybrid pipeline (local foreground + cloud background)

    private func runHybridPipeline(jpegData: Data) async {
        let speechAuthorized = await speechRecognitionService.requestAuthorization()
        if !speechAuthorized {
            AppConfig.shared.log("runHybridPipeline: speech not authorised", level: .warning)
        }

        do {
            sessionState = .processingPrivacy
            let result = try await privacyPipeline.process(
                jpegData: jpegData,
                childAge: childAge,
                childName: UserDefaults.standard.childName,
                generationMode: storyMode.rawValue
            )
            await metricsStore.record(result.metrics)
            let payload = result.payload
            AppConfig.shared.log("runHybridPipeline: privacy done, objects=\(payload.objects), scene=\(payload.scene)")

            let profile = ChildProfile(
                name: UserDefaults.standard.childName,
                age: childAge,
                preferences: UserDefaults.standard.childPreferences
            )
            beginStorySession(
                jpegData: jpegData,
                payload: payload,
                privacyMetrics: result.metrics,
                childName: profile.name,
                childAge: profile.age
            )

            let (localService, skipSemantic) = await resolveHybridLocalService()

            sessionState = .generatingStory
            generationStartTime = CFAbsoluteTimeGetCurrent()
            let context = SceneContext(from: payload)
            let baseBeat = try await localService.startStory(context: context, profile: profile)
            let localMs = (CFAbsoluteTimeGetCurrent() - generationStartTime) * 1000
            AppConfig.shared.log("runHybridPipeline: beat[0] generated in \(Int(localMs))ms via \(localService is Gemma4StoryService ? "Gemma4" : "AppleFM")")

            // Fire background cloud enhancement during speak + listen dead time
            await backgroundEnhancer.requestEnhancement(
                payload: payload, baseBeat: baseBeat, childAnswer: nil, turnNumber: 0
            )

            sessionState = .sendingAudio
            await audioService.speak(baseBeat.storyText)
            await audioService.speak(baseBeat.question)

            storyTurnCount = 1
            recordBeat(baseBeat, generationMs: localMs, ttftMs: 0, localIndex: 0)
            await storyMetricsStore.record(StoryMetricsEvent(
                generationMode: storyMode.rawValue,
                timeToFirstTokenMs: 0,
                totalGenerationMs: localMs,
                turnCount: storyTurnCount,
                guardrailViolations: 0,
                storyTextLength: baseBeat.storyText.count,
                timestamp: Date().timeIntervalSince1970
            ))
            await hybridMetricsStore.record(HybridBeatMetric(
                turnNumber: 0,
                source: localService is Gemma4StoryService ? .localGemma4 : .localOnDevice,
                localGenerationMs: localMs,
                cloudResponseMs: nil,
                cloudArrivedInTime: false,
                endingDetectedBy: nil,
                timestamp: Date().timeIntervalSince1970
            ))
            timeline.insert(TimelineEntry(
                sceneObjects: payload.objects,
                storySnippet: String(baseBeat.storyText.prefix(120))
            ), at: 0)

            if !baseBeat.isEnding {
                storyLoopTask = Task { [weak self] in
                    await self?.continueHybridLoop(
                        payload: payload,
                        localService: localService,
                        skipSemantic: skipSemantic
                    )
                }
            } else {
                finalizeCurrentSession()
                storyTurnCount = 0
                sessionState = .connected
            }
        } catch {
            AppConfig.shared.log("runHybridPipeline: error=\(error.localizedDescription)", level: .error)
            setError(error.localizedDescription)
        }
    }

    /// Resolve which local service to use for this hybrid session.
    /// Checked once per session — not per turn — to avoid repeated async state reads.
    /// Returns skipSemantic=true for Gemma4: Apple FM is unavailable in that context
    /// and calling it causes an ~8s hang while Foundation Models cancellation surfaces.
    private func resolveHybridLocalService() async -> (service: any StoryGenerating, skipSemantic: Bool) {
        if case .ready = await gemma4StoryService.currentModelState() {
            return (gemma4StoryService, true)
        }
        return (onDeviceStoryService, false)
    }

    private func continueHybridLoop(
        payload: ScenePayload,
        localService: any StoryGenerating,
        skipSemantic: Bool
    ) async {
        var currentBeat: StoryBeat? = nil

        while !Task.isCancelled {
            sessionState = .listeningForAnswer
            latestAnswerPiiCount = 0
            let question = currentBeat?.question ?? ""
            guard let answer = await listenForAnswer(question: question, skipSemanticLayer: skipSemantic) else {
                AppConfig.shared.log("continueHybridLoop: no answer, ending story")
                await endStoryGracefully()
                break
            }
            recordAnswer(answer, piiCount: latestAnswerPiiCount)

            sessionState = .generatingStory
            let beat: StoryBeat
            let source: HybridSource
            var cloudResponseMs: Double? = nil
            let localStart = CFAbsoluteTimeGetCurrent()

            if let (enhanced, cloudMs) = await backgroundEnhancer.consumeEnhancedBeat() {
                beat = enhanced
                source = .cloud
                cloudResponseMs = cloudMs
                AppConfig.shared.log("hybridLoop: turn \(storyTurnCount) cloud-enhanced (\(Int(cloudMs))ms)")
            } else {
                beat = (try? await localService.continueTurn(childAnswer: answer)) ?? .safeFallback
                source = localService is Gemma4StoryService ? .localGemma4 : .localOnDevice
                AppConfig.shared.log("hybridLoop: turn \(storyTurnCount) local fallback (\(source.rawValue))")
            }
            let localMs = (CFAbsoluteTimeGetCurrent() - localStart) * 1000
            currentBeat = beat

            // Fire next cloud enhancement during speak + listen dead time
            await backgroundEnhancer.requestEnhancement(
                payload: payload, baseBeat: beat, childAnswer: answer, turnNumber: storyTurnCount
            )

            sessionState = .sendingAudio
            await audioService.speak(beat.storyText)
            await audioService.speak(beat.question)

            storyTurnCount += 1
            recordBeat(
                beat,
                generationMs: source == .cloud ? 0 : localMs,
                ttftMs: 0,
                localIndex: storyTurnCount - 1
            )
            await storyMetricsStore.record(StoryMetricsEvent(
                generationMode: storyMode.rawValue,
                timeToFirstTokenMs: 0,
                totalGenerationMs: source == .cloud ? (cloudResponseMs ?? 0) : localMs,
                turnCount: storyTurnCount,
                guardrailViolations: 0,
                storyTextLength: beat.storyText.count,
                timestamp: Date().timeIntervalSince1970
            ))
            await hybridMetricsStore.record(HybridBeatMetric(
                turnNumber: storyTurnCount - 1,
                source: source,
                localGenerationMs: localMs,
                cloudResponseMs: cloudResponseMs,
                cloudArrivedInTime: source == .cloud,
                endingDetectedBy: beat.isEnding
                    ? (source == .cloud ? .cloudLLM : .localHeuristic) : nil,
                timestamp: Date().timeIntervalSince1970
            ))
            timeline.insert(TimelineEntry(
                sceneObjects: [],
                storySnippet: String(beat.storyText.prefix(120))
            ), at: 0)

            if beat.isEnding { break }
        }

        await localService.endSession()
        await backgroundEnhancer.reset()
        finalizeCurrentSession()
        storyTurnCount = 0
        guard case .error = sessionState else { sessionState = .connected; return }
    }

    // MARK: - Cloud story pipeline

    private func runCloudPipeline(jpegData: Data) async {
        AppConfig.shared.log("runCloudPipeline: start, jpegBytes=\(jpegData.count), childAge=\(childAge)")
        let speechAuthorized = await speechRecognitionService.requestAuthorization()
        if !speechAuthorized {
            AppConfig.shared.log("runCloudPipeline: speech not authorized", level: .warning)
        }

        do {
            sessionState = .processingPrivacy
            let result = try await privacyPipeline.process(jpegData: jpegData, childAge: childAge, childName: UserDefaults.standard.childName, generationMode: storyMode.rawValue)
            await metricsStore.record(result.metrics)
            AppConfig.shared.log("runCloudPipeline: privacy done, objects=\(result.payload.objects), scene=\(result.payload.scene), latency=\(Int(result.metrics.pipelineLatencyMs))ms")

            let profile = ChildProfile(
                name: UserDefaults.standard.childName,
                age: childAge,
                preferences: UserDefaults.standard.childPreferences
            )
            beginStorySession(
                jpegData: jpegData,
                payload: result.payload,
                privacyMetrics: result.metrics,
                childName: profile.name,
                childAge: profile.age
            )

            sessionState = .generatingStory
            generationStartTime = CFAbsoluteTimeGetCurrent()
            let beat = try await cloudService.requestStory(payload: result.payload)
            let generationMs = (CFAbsoluteTimeGetCurrent() - generationStartTime) * 1000
            AppConfig.shared.log("runCloudPipeline: beat[0] received in \(Int(generationMs))ms, beatIndex=\(beat.beatIndex)")
            AppConfig.shared.log("beat[0] storyText: \(beat.storyText)")
            AppConfig.shared.log("beat[0] question: \(beat.question)")
            AppConfig.shared.log("beat[0] isEnding: \(beat.isEnding)")

            storyTurnCount = beat.beatIndex + 1
            recordBeat(
                StoryBeat(storyText: beat.storyText, question: beat.question, isEnding: beat.isEnding),
                generationMs: generationMs, ttftMs: 0, localIndex: beat.beatIndex
            )

            await storyMetricsStore.record(StoryMetricsEvent(
                generationMode: storyMode.rawValue,
                timeToFirstTokenMs: 0,
                totalGenerationMs: generationMs,
                turnCount: storyTurnCount,
                guardrailViolations: 0,
                storyTextLength: beat.storyText.count,
                timestamp: Date().timeIntervalSince1970
            ))

            sessionState = .sendingAudio
            await audioService.speak(beat.storyText)
            await audioService.speak(beat.question)

            timeline.insert(TimelineEntry(
                sceneObjects: result.payload.objects,
                storySnippet: String(beat.storyText.prefix(120))
            ), at: 0)

            if !beat.isEnding {
                storyLoopTask = Task { [weak self] in
                    await self?.continueCloudLoop(basePayload: result.payload, lastBeat: beat)
                }
            } else {
                finalizeCurrentSession()
                storyTurnCount = 0
                sessionState = .connected
            }
        } catch {
            AppConfig.shared.log("runCloudPipeline: error=\(error.localizedDescription)", level: .error)
            setError(error.localizedDescription)
        }
    }

    private func continueCloudLoop(basePayload: ScenePayload, lastBeat: StoryResponse) async {
        var sessionId   = lastBeat.sessionId
        var history     = [StoryTurn(role: "model", text: lastBeat.storyText)]
        var currentBeat = lastBeat

        while !Task.isCancelled {
            sessionState = .listeningForAnswer
            latestAnswerPiiCount = 0
            guard let answer = await listenForAnswer(question: currentBeat.question) else {
                AppConfig.shared.log("continueCloudLoop: answer timeout, ending story")
                await endStoryGracefully()
                break
            }
            recordAnswer(answer, piiCount: latestAnswerPiiCount)
            history.append(StoryTurn(role: "user", text: answer))

            sessionState = .generatingStory
            do {
                let continuationPayload = ScenePayload(
                    objects:      basePayload.objects,
                    scene:        basePayload.scene,
                    transcript:   answer,
                    childAge:     basePayload.childAge,
                    childName:    basePayload.childName,
                    sessionId:    sessionId,
                    storyHistory: history
                )

                generationStartTime = CFAbsoluteTimeGetCurrent()
                let beat = try await cloudService.requestStory(payload: continuationPayload)
                let turnMs = (CFAbsoluteTimeGetCurrent() - generationStartTime) * 1000

                history.append(StoryTurn(role: "model", text: beat.storyText))
                sessionId   = beat.sessionId
                currentBeat = beat
                storyTurnCount = beat.beatIndex + 1

                AppConfig.shared.log("continueCloudLoop: answer='\(answer)'")
                AppConfig.shared.log("beat[\(beat.beatIndex)] storyText: \(beat.storyText)")
                AppConfig.shared.log("beat[\(beat.beatIndex)] question: \(beat.question)")
                AppConfig.shared.log("beat[\(beat.beatIndex)] isEnding: \(beat.isEnding)")

                recordBeat(
                    StoryBeat(storyText: beat.storyText, question: beat.question, isEnding: beat.isEnding),
                    generationMs: turnMs, ttftMs: 0, localIndex: beat.beatIndex
                )

                await storyMetricsStore.record(StoryMetricsEvent(
                    generationMode: storyMode.rawValue,
                    timeToFirstTokenMs: 0,
                    totalGenerationMs: turnMs,
                    turnCount: storyTurnCount,
                    guardrailViolations: 0,
                    storyTextLength: beat.storyText.count,
                    timestamp: Date().timeIntervalSince1970
                ))

                sessionState = .sendingAudio
                await audioService.speak(beat.storyText)
                await audioService.speak(beat.question)

                timeline.insert(TimelineEntry(sceneObjects: [], storySnippet: String(beat.storyText.prefix(120))), at: 0)

                if beat.isEnding { break }
            } catch {
                AppConfig.shared.log("continueCloudLoop: error=\(error.localizedDescription)", level: .error)
                setError(error.localizedDescription)
                break
            }
        }
        finalizeCurrentSession()
        storyTurnCount = 0
        guard case .error = sessionState else {
            sessionState = .connected
            return
        }
    }

    // MARK: - Timeline helpers

    /// Creates and inserts a new `StorySessionRecord` at the start of a pipeline run.
    private func beginStorySession(
        jpegData: Data,
        payload: ScenePayload,
        privacyMetrics: PrivacyMetricsEvent,
        childName: String,
        childAge: Int
    ) {
        let metrics = PrivacyMetricsData(payload: payload, event: privacyMetrics)
        let session = StorySessionRecord(
            childName: childName,
            childAge: childAge,
            storyMode: storyMode.rawValue,
            originalImageData: originalCapturedImageData,
            capturedImageData: jpegData,
            metrics: metrics
        )
        storyTimelineStore.insert(session)
        currentSession        = session
        currentBeatSequence   = 0
        prevLocalBeatIndex    = -1
        sessionHadRestart     = false
        latestAnswerPiiCount  = 0
    }

    /// Appends a `StoryBeatRecord` for the beat that was just generated.
    private func recordBeat(
        _ beat: StoryBeat,
        generationMs: Double,
        ttftMs: Double,
        localIndex: Int
    ) {
        guard let session = currentSession else { return }
        // A context restart is detected when the local beat index drops below the
        // previous value (restartWithSummary resets the service's turn counter to 0).
        let isRestart = prevLocalBeatIndex >= 0 && localIndex < prevLocalBeatIndex
        if isRestart { sessionHadRestart = true }
        prevLocalBeatIndex = localIndex

        let record = StoryBeatRecord(
            sequenceNumber:   currentBeatSequence,
            localBeatIndex:   localIndex,
            isInitialBeat:    currentBeatSequence == 0,
            isContextRestart: isRestart,
            storyText:        beat.storyText,
            question:         beat.question,
            isEnding:         beat.isEnding,
            generationMs:     generationMs,
            ttftMs:           currentBeatSequence == 0 ? ttftMs : 0
        )
        storyTimelineStore.addBeat(record, to: session)
        pendingBeat           = record
        currentBeatSequence  += 1
    }

    /// Saves the child's spoken answer on the most recently generated beat.
    private func recordAnswer(_ answer: String, piiCount: Int) {
        guard let session = currentSession, let beat = pendingBeat else { return }
        storyTimelineStore.setAnswer(answer, piiCount: piiCount, on: beat, session: session)
    }

    /// Marks the current session as complete and clears tracking state.
    /// Safe to call multiple times — no-ops if there is no active session.
    private func finalizeCurrentSession() {
        guard let session = currentSession else { return }
        storyTimelineStore.finalizeSession(session, hadContextRestart: sessionHadRestart)
        currentSession       = nil
        pendingBeat          = nil
        currentBeatSequence  = 0
        prevLocalBeatIndex   = -1
        sessionHadRestart    = false
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

