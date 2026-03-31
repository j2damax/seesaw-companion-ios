// AuthViewModel.swift
// SeeSaw — Tier 2 companion app

import AuthenticationServices
import Foundation

@MainActor
@Observable
final class AuthViewModel {

    // MARK: - State

    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let authService: AuthenticationService
    private let coordinator: AppCoordinator

    // MARK: - Init

    init(authService: AuthenticationService, coordinator: AppCoordinator) {
        self.authService = authService
        self.coordinator = coordinator
    }

    // MARK: - Apple Sign-In

    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential
            else { return }
            isLoading = true
            Task {
                await authService.signInWithApple(credential: credential)
                isLoading = false
                coordinator.signInCompleted()
            }

        case .failure(let error):
            if let nsError = error as? NSError,
               nsError.code != ASAuthorizationError.canceled.rawValue {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Google Sign-In (stub — requires Google SDK in production)

    func handleGoogleSignIn() {
        errorMessage = "Google Sign-In requires the Google Identity SDK. Coming soon."
    }

    func clearError() {
        errorMessage = nil
    }
}
