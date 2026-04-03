// AppCoordinator.swift
// SeeSaw — Tier 2 companion app
//
// Root coordinator. Manages top-level navigation across all app screens:
//   launch → terms → signIn → onboarding → home
// On subsequent launches, navigation fast-paths based on persisted state.

import Foundation

@MainActor
@Observable
final class AppCoordinator {

    // MARK: - Routes

    enum Route: Equatable {
        case launch
        case terms
        case signIn
        case onboarding
        case home
    }

    // MARK: - State

    var currentRoute: Route

    // MARK: - Dependencies

    let container: AppDependencyContainer

    // MARK: - Init

    init(container: AppDependencyContainer) {
        self.container = container
        let isSignedIn = UserDefaults.standard.string(forKey: "auth.userID") != nil
        let onboarded  = UserDefaults.standard.hasCompletedOnboarding
        let termsOK    = UserDefaults.standard.hasAcceptedTerms

        if isSignedIn && onboarded {
            currentRoute = .home
        } else if isSignedIn {
            currentRoute = .onboarding
        } else if termsOK {
            currentRoute = .signIn
        } else {
            currentRoute = .launch
        }
    }

    // MARK: - Navigation actions

    func getStarted() {
        currentRoute = .terms
    }

    func termsAccepted() {
        currentRoute = .signIn
    }

    func signInCompleted() {
        if UserDefaults.standard.hasCompletedOnboarding {
            currentRoute = .home
        } else {
            currentRoute = .onboarding
        }
    }

    func onboardingCompleted() {
        currentRoute = .home
    }

    func signOut() {
        Task {
            await container.authService.signOut()
            await container.accessoryManager.disconnectAll()
        }
        currentRoute = .signIn
    }
}

