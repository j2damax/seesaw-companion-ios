// SeeSawApp.swift
// SeeSaw — Tier 2 companion app
//
// @main entry point. Bootstraps the DI container and root coordinator,
// then renders the appropriate root view based on auth state.

import SwiftUI

@main
struct SeeSawApp: App {

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}

// MARK: - Root View

/// Hosts the coordinator as @State so it is created on the @MainActor
/// thread guaranteed by SwiftUI's view rendering.
@MainActor
struct AppRootView: View {

    @State private var coordinator: AppCoordinator = {
        let container = AppDependencyContainer()
        return AppCoordinator(container: container)
    }()

    var body: some View {
        coordinatedView
    }

    @ViewBuilder
    private var coordinatedView: some View {
        switch coordinator.currentRoute {
        case .signIn:
            SignInView(coordinator: coordinator)
        case .companion:
            ContentView(
                viewModel: coordinator.container.makeCompanionViewModel(),
                coordinator: coordinator
            )
        }
    }
}

