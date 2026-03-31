// AppCoordinator.swift
// SeeSaw — Tier 2 companion app
//
// Root coordinator. Manages top-level navigation between the sign-in flow
// and the main companion screen. ViewModels receive this coordinator via
// injection to trigger route changes without importing SwiftUI.

import Foundation

@MainActor
@Observable
final class AppCoordinator {

    // MARK: - Routes

    enum Route {
        case signIn
        case companion
    }

    // MARK: - State

    var currentRoute: Route

    // MARK: - Dependencies

    let container: AppDependencyContainer

    // MARK: - Init

    init(container: AppDependencyContainer) {
        self.container = container
        currentRoute = .signIn
    }

    // MARK: - Navigation actions

    func signInCompleted() {
        currentRoute = .companion
    }

    func signOut() {
        Task {
            await container.authService.signOut()
            await container.bleService.disconnect()
        }
        currentRoute = .signIn
    }
}
