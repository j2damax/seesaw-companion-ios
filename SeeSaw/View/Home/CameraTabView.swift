// CameraTabView.swift
// SeeSaw — Tier 2 companion app
//
// "Camera" tab on the home screen.
// Shows live camera preview (iPhone camera only), connection status,
// and accessory controls. Powered by CompanionViewModel.

import SwiftUI

struct CameraTabView: View {

    @Bindable var vm: CompanionViewModel
    let coordinator: AppCoordinator

    // MARK: - Body

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    previewArea(height: geo.size.height * 0.52)
                    controlsArea
                        .padding(20)
                    if let error = vm.lastError {
                        errorBanner(error)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                    }
                }
            }
            .navigationTitle("Camera")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { settingsToolbar }
            .fullScreenCover(isPresented: $vm.isShowingScenePreview) {
                if let imageData = vm.capturedImageData {
                    ScenePreviewView(
                        imageData: imageData,
                        detections: vm.sceneDetections,
                        onDismiss: { vm.dismissScenePreview() }
                    )
                }
            }
        }
    }

    // MARK: - Camera preview

    private func previewArea(height: CGFloat) -> some View {
        ZStack {
            if let session = vm.cameraPreviewSession {
                CameraPreviewView(session: session)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            } else {
                cameraPlaceholder
            }

            // Overlaid status badge
            VStack {
                Spacer()
                StatusView(
                    state: vm.sessionState,
                    deviceName: vm.connectedDeviceName,
                    wearableType: vm.selectedWearableType
                )
                .padding(12)
            }
        }
        .frame(height: height)
    }

    private var cameraPlaceholder: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(.secondarySystemBackground))
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: vm.selectedWearableType.systemImage)
                        .font(.system(size: 48))
                        .foregroundStyle(.quaternary)
                    Text("No preview available")
                        .font(.caption)
                        .foregroundStyle(.quaternary)
                }
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
    }

    // MARK: - Connection controls

    @ViewBuilder
    private var controlsArea: some View {
        switch vm.sessionState {
        case .idle:
            Button(vm.selectedWearableType.connectActionLabel) { vm.startScanning() }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .frame(maxWidth: .infinity)

        case .scanning:
            Button("Cancel") { vm.stopScanning() }
                .buttonStyle(.bordered)
                .tint(.secondary)

        case .connected:
            HStack(spacing: 12) {
                Button("Capture Scene") { vm.captureScene() }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                Button("Disconnect") { vm.disconnect() }
                    .buttonStyle(.bordered)
                    .tint(.secondary)
            }

        case .error:
            Button("Dismiss") { vm.dismissError() }
                .buttonStyle(.bordered)
                .tint(.red)

        default:
            HStack(spacing: 8) {
                ProgressView()
                Text(vm.sessionState.displayTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Error banner

    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var settingsToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            NavigationLink {
                SettingsView(
                    childAge: $vm.childAge,
                    accessoryManager: coordinator.container.accessoryManager,
                    metricsStore: coordinator.container.privacyMetricsStore
                )
            } label: {
                Image(systemName: "gear")
            }
        }
    }
}

#Preview {
    let container = AppDependencyContainer()
    let coordinator = AppCoordinator(container: container)
    CameraTabView(
        vm: container.makeCompanionViewModel(),
        coordinator: coordinator
    )
}
