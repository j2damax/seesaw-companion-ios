// LaunchScreenView.swift
// SeeSaw — Tier 2 companion app
//
// Screen 1 — Splash/launch screen shown on first run.
// Displays the app logo and a "Get Started" button.

import SwiftUI

struct LaunchScreenView: View {

    private let coordinator: AppCoordinator

    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            logo
            Spacer()
            getStartedButton
                .padding(.bottom, 52)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(brandGradient)
    }

    // MARK: - Logo

    private var logo: some View {
        VStack(spacing: 20) {
            Image(systemName: "eye.circle.fill")
                .font(.system(size: 96))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)

            Text("SeeSaw")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("AI Storytelling for Children")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.85))
        }
    }

    // MARK: - CTA button

    private var getStartedButton: some View {
        Button {
            coordinator.getStarted()
        } label: {
            Text("Get Started")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(.white)
                .foregroundStyle(.tint)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Background

    private var brandGradient: some View {
        LinearGradient(
            colors: [Color.teal, Color.blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    let container = AppDependencyContainer()
    LaunchScreenView(coordinator: AppCoordinator(container: container))
}
