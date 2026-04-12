// HomeView.swift
// SeeSaw — Tier 2 companion app
//
// Screen 5 — Main home screen (post-onboarding).
// Three-tab layout:
//   📷 Camera   — live device status + camera preview + controls
//   🕐 Timeline — usage history list
//   ⚙️ Settings — accessory setup, child prefs, sign out

import SwiftUI

struct HomeView: View {

    @State private var vm: CompanionViewModel
    private let coordinator: AppCoordinator

    init(coordinator: AppCoordinator) {
        _vm = State(initialValue: coordinator.container.makeCompanionViewModel())
        self.coordinator = coordinator
    }

    // MARK: - Body

    var body: some View {
        TabView {
            CameraTabView(vm: vm, coordinator: coordinator)
                .tabItem {
                    Label("Camera", systemImage: "camera.fill")
                }

            TimelineTabView(store: coordinator.container.storyTimelineStore)
                .tabItem {
                    Label("Timeline", systemImage: "clock.fill")
                }

            SettingsTabView(
                vm: vm,
                accessoryManager: coordinator.container.accessoryManager,
                coordinator: coordinator
            )
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .tint(.teal)
    }
}

#Preview {
    let container = AppDependencyContainer()
    HomeView(coordinator: AppCoordinator(container: container))
}
