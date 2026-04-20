// AppDependencyContainer.swift
// SeeSaw — Tier 2 companion app
//
// Lightweight DI container. Constructs and owns all service singletons.
// ViewModels receive injected dependencies rather than constructing them.

import Foundation

@MainActor
final class AppDependencyContainer {

    // MARK: - Wearable accessories

    let bleService: BLEService
    let localDeviceAccessory: LocalDeviceAccessory
    let metaGlassAccessory: ExternalSDKAccessory
    let mfiCameraAccessory: ExternalSDKAccessory

    // MARK: - Accessory orchestration

    let accessoryManager: AccessoryManager

    // MARK: - Pipeline services

    let privacyPipelineService: PrivacyPipelineService
    let cloudAgentService: CloudAgentService
    let audioService: AudioService
    let audioCaptureService: AudioCaptureService
    let speechRecognitionService: SpeechRecognitionService
    let authService: AuthenticationService

    // MARK: - Privacy metrics

    let privacyMetricsStore: PrivacyMetricsStore

    // MARK: - Story generation

    let onDeviceStoryService: OnDeviceStoryService
    let gemma4StoryService: Gemma4StoryService
    let modelDownloadManager: ModelDownloadManager
    let storyMetricsStore: StoryMetricsStore

    // MARK: - Story timeline (SwiftData persistence)

    let storyTimelineStore: StoryTimelineStore

    // MARK: - Hybrid mode metrics

    let hybridMetricsStore: HybridMetricsStore

    // MARK: - Story ratings

    let storyRatingStore: StoryRatingStore

    // MARK: - Init

    init() {
        // Seed UserDefaults from AppConfig constants on first launch.
        // Only writes when the stored value is nil/empty so runtime overrides
        // made via the Settings UI are preserved across relaunches.
        AppDependencyContainer.seedDefaultsFromConfig()

        bleService           = BLEService()
        localDeviceAccessory = LocalDeviceAccessory()
        metaGlassAccessory   = ExternalSDKAccessory(wearableType: .metaGlass)
        mfiCameraAccessory   = ExternalSDKAccessory(wearableType: .mfiCamera)

        accessoryManager = AccessoryManager(
            bleAccessory: bleService,
            localDevice:  localDeviceAccessory,
            metaGlass:    metaGlassAccessory,
            mfiCamera:    mfiCameraAccessory
        )

        audioCaptureService      = AudioCaptureService()
        speechRecognitionService = SpeechRecognitionService()
        privacyPipelineService   = PrivacyPipelineService(speechService: speechRecognitionService)
        cloudAgentService        = CloudAgentService(baseURL: UserDefaults.standard.cloudAgentURL)
        audioService             = AudioService()
        authService              = AuthenticationService()
        privacyMetricsStore      = PrivacyMetricsStore()
        onDeviceStoryService     = OnDeviceStoryService()
        gemma4StoryService       = Gemma4StoryService()
        modelDownloadManager     = ModelDownloadManager(storyService: gemma4StoryService)
        storyMetricsStore        = StoryMetricsStore()
        storyTimelineStore       = StoryTimelineStore()
        hybridMetricsStore       = HybridMetricsStore()
        storyRatingStore         = StoryRatingStore()

        // Restore Gemma model state from the filesystem on every launch.
        // Documents/ is preserved across Xcode debug installs on physical devices,
        // but Gemma4StoryService.modelState is in-memory only. Without this call
        // the service stays .notDownloaded until the user taps "Download" in Settings.
        let _manager = modelDownloadManager
        Task { await _manager.checkInstalledModel() }
    }

    // MARK: - Config seeding

    private static func seedDefaultsFromConfig() {
        let defaults = UserDefaults.standard
        if defaults.cloudAgentURL == nil,
           !AppConfig.cloudAgentBaseURL.isEmpty,
           AppConfig.cloudAgentBaseURL != "https://your-cloud-run-url",
           let url = URL(string: AppConfig.cloudAgentBaseURL) {
            defaults.cloudAgentURL = url
        }
        if defaults.cloudAgentKey.isEmpty, !AppConfig.cloudAgentAPIKey.isEmpty {
            defaults.cloudAgentKey = AppConfig.cloudAgentAPIKey
        }
        // Always overwrite so that changing AppConfig.gemma4DirectDownloadURL
        // (e.g. switching from q4km → q8_0) takes effect on the next launch
        // without needing to delete the app.
        if !AppConfig.gemma4DirectDownloadURL.isEmpty {
            defaults.gemma4ModelURL = AppConfig.gemma4DirectDownloadURL
        }
    }

    // MARK: - Factory methods

    func makeOnboardingViewModel(coordinator: AppCoordinator) -> OnboardingViewModel {
        OnboardingViewModel(accessoryManager: accessoryManager, coordinator: coordinator)
    }

    func makeCompanionViewModel() -> CompanionViewModel {
        CompanionViewModel(
            accessoryManager: accessoryManager,
            privacyPipeline:  privacyPipelineService,
            cloudService:     cloudAgentService,
            audioService:     audioService,
            audioCaptureService: audioCaptureService,
            speechRecognitionService: speechRecognitionService,
            metricsStore: privacyMetricsStore,
            storyMetricsStore: storyMetricsStore,
            onDeviceStoryService: onDeviceStoryService,
            gemma4StoryService: gemma4StoryService,
            modelDownloadManager: modelDownloadManager,
            storyTimelineStore: storyTimelineStore,
            hybridMetricsStore: hybridMetricsStore,
            storyRatingStore: storyRatingStore
        )
    }

    func makeAuthViewModel(coordinator: AppCoordinator) -> AuthViewModel {
        AuthViewModel(authService: authService, coordinator: coordinator)
    }
}

