// ContentView.swift
// SeeSaw — Tier 2 companion app
//
// Root view for the main companion screen (post sign-in).
// Displays session status and connection controls for the parent.

import SwiftUI

struct ContentView: View {

    @State private var vm: CompanionViewModel
    private let coordinator: AppCoordinator

    init(viewModel: CompanionViewModel, coordinator: AppCoordinator) {
        _vm = State(initialValue: viewModel)
        self.coordinator = coordinator
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                StatusView(
                    state: vm.sessionState,
                    deviceName: vm.connectedDeviceName,
                    wearableType: vm.selectedWearableType
                )

                controlButtons

                if let error = vm.lastError {
                    errorBanner(error)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("SeeSaw")
            .toolbar { toolbarContent }
        }
    }

    // MARK: - Control buttons

    @ViewBuilder
    private var controlButtons: some View {
        switch vm.sessionState {
        case .idle:
            Button(vm.selectedWearableType.connectActionLabel) { vm.startScanning() }
                .buttonStyle(.borderedProminent)

        case .scanning:
            Button("Cancel") { vm.stopScanning() }
                .buttonStyle(.bordered)
                .tint(.secondary)

        case .connected:
            VStack(spacing: 12) {
                Button("Capture Scene") { vm.captureScene() }
                    .buttonStyle(.borderedProminent)
                Button("Disconnect") { vm.disconnect() }
                    .buttonStyle(.bordered)
                    .tint(.secondary)
            }

        case .error:
            Button("Dismiss") { vm.dismissError() }
                .buttonStyle(.bordered)
                .tint(.red)

        default:
            EmptyView()
        }
    }

    // MARK: - Error banner

    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            NavigationLink {
                SettingsView(
                    childAge: $vm.childAge,
                    accessoryManager: coordinator.container.accessoryManager,
                    metricsStore: coordinator.container.privacyMetricsStore,
                    storyMetricsStore: coordinator.container.storyMetricsStore,
                    hybridMetricsStore: coordinator.container.hybridMetricsStore,
                    storyRatingStore: coordinator.container.storyRatingStore
                )
            } label: {
                Image(systemName: "gear")
            }
        }
        ToolbarItem(placement: .topBarLeading) {
            Button("Sign Out") { coordinator.signOut() }
                .font(.caption)
        }
    }
}

#Preview {
    let container = AppDependencyContainer()
    let coordinator = AppCoordinator(container: container)
    ContentView(
        viewModel: container.makeCompanionViewModel(),
        coordinator: coordinator
    )
}


