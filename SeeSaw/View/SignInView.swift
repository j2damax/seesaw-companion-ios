// SignInView.swift
// SeeSaw — Tier 2 companion app
//
// Parent authentication screen. Uses Sign In with Apple (AuthenticationServices).
// Google Sign-In is stubbed — requires Google Identity SDK in production.

import AuthenticationServices
import SwiftUI

struct SignInView: View {

    @State private var vm: AuthViewModel

    init(coordinator: AppCoordinator) {
        _vm = State(initialValue: coordinator.container.makeAuthViewModel(coordinator: coordinator))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            branding
            Spacer()
            signInButtons
            footerNote
        }
        .padding(32)
        .alert("Sign-In Error", isPresented: .init(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.clearError() } }
        )) {
            Button("OK") { vm.clearError() }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    // MARK: - Branding

    private var branding: some View {
        VStack(spacing: 16) {
            Image(systemName: "eye.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.tint)
            Text("SeeSaw")
                .font(.largeTitle.bold())
            Text("AI Storytelling for Children")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Sign-in buttons

    private var signInButtons: some View {
        VStack(spacing: 16) {
            appleSignInButton
            googleSignInButton
        }
    }

    private var appleSignInButton: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            vm.handleAppleSignIn(result)
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var googleSignInButton: some View {
        Button {
            vm.handleGoogleSignIn()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "globe")
                    .font(.body.bold())
                Text("Sign in with Google")
                    .font(.body.bold())
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color(.systemBackground))
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.separator))
            )
        }
    }

    private var footerNote: some View {
        Text("Parent sign-in only. Children do not interact with this screen.")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
    }
}

#Preview {
    let container = AppDependencyContainer()
    let coordinator = AppCoordinator(container: container)
    SignInView(coordinator: coordinator)
}
