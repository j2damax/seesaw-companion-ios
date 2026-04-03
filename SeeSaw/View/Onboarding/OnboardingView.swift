// OnboardingView.swift
// SeeSaw — Tier 2 companion app
//
// Screen 4 — Post-sign-in onboarding wizard (3 steps).
//   Step 0: Accessory Setup
//   Step 1: Child Preferences
//   Step 2: Success / Welcome

import SwiftUI

struct OnboardingView: View {

    @State private var vm: OnboardingViewModel

    init(coordinator: AppCoordinator) {
        _vm = State(initialValue: coordinator.container.makeOnboardingViewModel(coordinator: coordinator))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                stepIndicator
                    .padding(.top, 8)
                    .padding(.bottom, 24)

                Group {
                    switch vm.currentStep {
                    case .accessorySetup:
                        AccessorySetupStepView(vm: vm)
                    case .childPreferences:
                        ChildPreferencesStepView(vm: vm)
                    case .success:
                        OnboardingSuccessStepView(vm: vm)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal:   .move(edge: .leading)
                ))
                .animation(.easeInOut(duration: 0.3), value: vm.currentStep)

                navigationButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
            .navigationTitle(vm.currentStep.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Step indicator (3 dots)

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingViewModel.Step.allCases, id: \.self) { step in
                Capsule()
                    .fill(step.rawValue <= vm.currentStep.rawValue ? Color.teal : Color.gray.opacity(0.3))
                    .frame(width: step == vm.currentStep ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: vm.currentStep)
            }
        }
    }

    // MARK: - Navigation buttons

    @ViewBuilder
    private var navigationButtons: some View {
        switch vm.currentStep {
        case .accessorySetup:
            VStack(spacing: 12) {
                Button("Next Step →") { vm.next() }
                    .buttonStyle(PrimaryButtonStyle())

                if vm.currentStep == .accessorySetup {
                    Text("You can change this later in Settings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

        case .childPreferences:
            HStack(spacing: 12) {
                Button("← Back") { vm.back() }
                    .buttonStyle(SecondaryButtonStyle())
                Button("Next Step →") {
                    guard !vm.childName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    vm.next()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(vm.childName.trimmingCharacters(in: .whitespaces).isEmpty)
            }

        case .success:
            Button("Start Exploring →") { vm.completeOnboarding() }
                .buttonStyle(PrimaryButtonStyle())
        }
    }
}

// MARK: - Step 0: Accessory Setup

private struct AccessorySetupStepView: View {

    @Bindable var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("How will SeeSaw see the world?")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    ForEach(vm.onboardingAccessoryTypes, id: \.self) { type in
                        accessoryCard(for: type)
                    }
                }
                .padding(.horizontal)

                connectionStatusView
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    @ViewBuilder
    private func accessoryCard(for type: WearableType) -> some View {
        let isSelected = vm.accessoryManager.selectedType == type
        Button {
            vm.selectAccessoryType(type)
        } label: {
            HStack(spacing: 16) {
                Image(systemName: type.systemImage)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .teal)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color.teal : Color.teal.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(type.rawValue)
                        .font(.headline)
                        .foregroundStyle(isSelected ? .white : .primary)
                    Text(type.inputSourceDescription)
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding(16)
            .background(isSelected ? Color.teal : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.teal : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var connectionStatusView: some View {
        switch vm.connectionStatus {
        case .idle:
            Button("Connect Now") { vm.connectAccessory() }
                .buttonStyle(SecondaryButtonStyle())

        case .connecting:
            HStack(spacing: 10) {
                ProgressView()
                Text("Connecting…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

        case .connected:
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Connected!")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

        case .failed(let reason):
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("Connection failed")
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                }
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Retry") { vm.connectAccessory() }
                    .font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Step 1: Child Preferences

private struct ChildPreferencesStepView: View {

    @Bindable var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                nameSection
                ageSection
                preferencesSection
            }
            .padding(24)
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Child's Name")
                .font(.headline)
            TextField("e.g. Alex", text: $vm.childName)
                .textFieldStyle(.roundedBorder)
                .textContentType(.givenName)
                .autocorrectionDisabled()
        }
    }

    private var ageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Age")
                .font(.headline)
            Stepper("Age: \(vm.childAge)", value: $vm.childAge, in: 2...12)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Favourite Topics")
                .font(.headline)
            Text("Select all that apply — used to personalise stories.")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(ChildProfile.presetTopics, id: \.self) { topic in
                    preferenceChip(topic)
                }
            }
        }
    }

    @ViewBuilder
    private func preferenceChip(_ topic: String) -> some View {
        let selected = vm.selectedPreferences.contains(topic)
        Button { vm.toggle(preference: topic) } label: {
            Text(topic)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selected ? Color.teal : Color(.secondarySystemBackground))
                .foregroundStyle(selected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(selected ? Color.teal : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 2: Success

private struct OnboardingSuccessStepView: View {

    let vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundStyle(.teal)

            VStack(spacing: 12) {
                Text("You're all set!")
                    .font(.title.bold())

                let name = vm.childName.trimmingCharacters(in: .whitespaces)
                Text(name.isEmpty
                     ? "Welcome to SeeSaw. Let the stories begin!"
                     : "Welcome! \(name) is ready for AI-powered storytelling.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Spacer()
        }
    }
}

// MARK: - Step title helper

private extension OnboardingViewModel.Step {
    var title: String {
        switch self {
        case .accessorySetup:   return "Accessory Setup"
        case .childPreferences: return "Child Profile"
        case .success:          return "All Done!"
        }
    }
}

// MARK: - Shared button styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.teal.opacity(configuration.isPressed ? 0.8 : 1))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color(.secondarySystemBackground).opacity(configuration.isPressed ? 0.6 : 1))
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    let container = AppDependencyContainer()
    OnboardingView(coordinator: AppCoordinator(container: container))
}
