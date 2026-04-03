// AuthenticationService.swift
// SeeSaw — Tier 2 companion app
//
// Handles Sign In with Apple and Google Sign-In via Firebase Authentication.

import AuthenticationServices
import FirebaseAuth
import Foundation
import GoogleSignIn

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

    // MARK: - Google Sign-In

    /// Presents the Google Sign-In flow, exchanges the Google credential for a
    /// Firebase Auth credential, and creates a local session on success.
    func signInWithGoogle() async throws {
        guard let windowScene = await MainActor.run(body: {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first
        }) else {
            throw AuthError.missingPresentingWindow
        }

        let rootVC: UIViewController = try await MainActor.run {
            guard let vc = windowScene.windows.first(where: \.isKeyWindow)?.rootViewController else {
                throw AuthError.missingPresentingWindow
            }
            return vc
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
        let user = result.user

        guard let idToken = user.idToken?.tokenString else {
            throw AuthError.missingGoogleIDToken
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: user.accessToken.tokenString
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        let firebaseUser = authResult.user

        let session = UserSession(
            userID: firebaseUser.uid,
            fullName: firebaseUser.displayName,
            email: firebaseUser.email,
            provider: .google
        )
        currentSession = session
        persistSession(session)
    }

    // MARK: - Sign-out

    func signOut() {
        // Sign out from Firebase
        try? Auth.auth().signOut()
        // Disconnect Google Sign-In
        GIDSignIn.sharedInstance.signOut()

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

// MARK: - Errors
enum AuthError: LocalizedError {
    case missingPresentingWindow
    case missingGoogleIDToken

    var errorDescription: String? {
        switch self {
        case .missingPresentingWindow:
            "Unable to find a window to present Google Sign-In."
        case .missingGoogleIDToken:
            "Google Sign-In did not return an ID token."
        }
    }
}


