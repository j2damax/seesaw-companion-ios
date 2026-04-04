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

    // MARK: - Init

    init() {
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
            speechRecognitionService: speechRecognitionService
        )
    }

    func makeAuthViewModel(coordinator: AppCoordinator) -> AuthViewModel {
        AuthViewModel(authService: authService, coordinator: coordinator)
    }
}

