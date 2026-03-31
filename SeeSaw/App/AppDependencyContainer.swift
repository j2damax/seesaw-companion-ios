// AppDependencyContainer.swift
// SeeSaw — Tier 2 companion app
//
// Lightweight DI container. Constructs and owns all service singletons.
// ViewModels receive injected dependencies rather than constructing them.

import Foundation

@MainActor
final class AppDependencyContainer {

    // MARK: - Services

    let bleService: BLEService
    let privacyPipelineService: PrivacyPipelineService
    let cloudAgentService: CloudAgentService
    let audioService: AudioService
    let authService: AuthenticationService

    // MARK: - Init

    init() {
        bleService             = BLEService()
        privacyPipelineService = PrivacyPipelineService()
        cloudAgentService      = CloudAgentService(baseURL: UserDefaults.standard.cloudAgentURL)
        audioService           = AudioService()
        authService            = AuthenticationService()
    }

    // MARK: - Factory methods

    func makeCompanionViewModel() -> CompanionViewModel {
        CompanionViewModel(
            wearable: bleService,
            privacyPipeline: privacyPipelineService,
            cloudService: cloudAgentService,
            audioService: audioService
        )
    }

    func makeAuthViewModel(coordinator: AppCoordinator) -> AuthViewModel {
        AuthViewModel(authService: authService, coordinator: coordinator)
    }
}
