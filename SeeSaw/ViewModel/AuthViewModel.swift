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
            let nsError = error as NSError
            // Ignore user-canceled errors from Apple Sign-In
            if nsError.domain == ASAuthorizationError.errorDomain && nsError.code == ASAuthorizationError.canceled.rawValue {
                return
            }
            errorMessage = nsError.localizedDescription
        }
    }

    // MARK: - Google Sign-In

    func handleGoogleSignIn() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await authService.signInWithGoogle()
                isLoading = false
                coordinator.signInCompleted()
            } catch {
                isLoading = false
                // Ignore user-canceled errors from Google Sign-In
                let nsError = error as NSError
                if nsError.domain == "com.google.GIDSignIn" && nsError.code == -5 {
                    return
                }
                errorMessage = error.localizedDescription
            }
        }
    }

    func clearError() {
        errorMessage = nil
    }
}

