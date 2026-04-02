// AuthenticationService.swift
// SeeSaw — Tier 2 companion app
//
// Handles Sign In with Apple using the native AuthenticationServices framework.
// The parent authenticates once; the session is persisted in the Keychain via
// ASAuthorizationAppleIDProvider credential state checks.

import AuthenticationServices
import Foundation

actor AuthenticationService {

    // MARK: - State

    private(set) var currentSession: UserSession?

    var isSignedIn: Bool { currentSession != nil }

    // MARK: - Init

    init() {
        currentSession = Self.loadPersistedSession()
    }

    // MARK: - Apple Sign-In

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) {
        let userID   = credential.user
        let fullName = formatName(credential.fullName)
        let email    = credential.email

        let session = UserSession(
            userID: userID,
            fullName: fullName,
            email: email,
            provider: .apple
        )
        currentSession = session
        persistSession(session)
    }

    // MARK: - Sign-out

    func signOut() {
        currentSession = nil
        clearPersistedSession()
    }

    // MARK: - Credential state check

    func validateAppleCredential(userID: String) async -> Bool {
        await withCheckedContinuation { continuation in
            let provider = ASAuthorizationAppleIDProvider()
            provider.getCredentialState(forUserID: userID) { state, _ in
                continuation.resume(returning: state == .authorized)
            }
        }
    }

    // MARK: - Persistence (simple UserDefaults for PoC)

    private nonisolated static func loadPersistedSession() -> UserSession? {
        guard let userID = UserDefaults.standard.string(forKey: "auth.userID"),
              let providerRaw = UserDefaults.standard.string(forKey: "auth.provider"),
              let provider = AuthProvider(rawValue: providerRaw) else {
            return nil
        }
        let fullName = UserDefaults.standard.string(forKey: "auth.fullName")
        let email    = UserDefaults.standard.string(forKey: "auth.email")
        return UserSession(userID: userID, fullName: fullName, email: email, provider: provider)
    }

    private func persistSession(_ session: UserSession) {
        UserDefaults.standard.set(session.userID,           forKey: "auth.userID")
        UserDefaults.standard.set(session.provider.rawValue, forKey: "auth.provider")
        UserDefaults.standard.set(session.fullName,         forKey: "auth.fullName")
        UserDefaults.standard.set(session.email,            forKey: "auth.email")
    }

    private func clearPersistedSession() {
        ["auth.userID", "auth.provider", "auth.fullName", "auth.email"]
            .forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    // MARK: - Helpers

    private func formatName(_ components: PersonNameComponents?) -> String? {
        guard let components else { return nil }
        let joined = [components.givenName, components.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        return joined.isEmpty ? nil : joined
    }
}

