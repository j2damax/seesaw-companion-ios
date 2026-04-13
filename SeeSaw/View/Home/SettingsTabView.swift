// SettingsTabView.swift
// SeeSaw — Tier 2 companion app
//
// "Settings" tab on the home screen.
// Contains five sections:
//   1. Story Engine     — mode picker + Gemma 4 model download
//   2. Accessory Setup  — reuses AccessoryPickerView
//   3. Child Preferences — name, age, favourite topics
//   4. Account          — Sign Out

import SwiftUI

struct SettingsTabView: View {

    @Bindable var vm: CompanionViewModel
    var accessoryManager: AccessoryManager
    let coordinator: AppCoordinator

    @State private var childName: String = UserDefaults.standard.childName
    @State private var childAge: Int = UserDefaults.standard.childAge
    @State private var selectedPreferences: Set<String> = Set(UserDefaults.standard.childPreferences)
    @State private var showSignOutConfirmation = false

    // Cloud configuration
    @State private var cloudURLString: String = UserDefaults.standard.cloudAgentURL.absoluteString
    @State private var cloudAgentKey: String = UserDefaults.standard.cloudAgentKey

    // Gemma 4 download state — polled once on appear and after action
    @State private var gemmaModelState: Gemma4StoryService.ModelState = .notDownloaded
    @State private var downloadProgress: Double = 0

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                storyEngineSection
                AccessoryPickerView(accessoryManager: accessoryManager)
                childPreferencesSection
                accountSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { savePreferences() }
                }
            }
            .confirmationDialog(
                "Are you sure you want to sign out?",
                isPresented: $showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) { coordinator.signOut() }
                Button("Cancel", role: .cancel) {}
            }
            .task { await refreshGemmaState() }
        }
    }

    // MARK: - Story Engine section

    private var storyEngineSection: some View {
        Section {
            Picker("Engine", selection: $vm.storyMode) {
                ForEach(StoryGenerationMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }

            Text(vm.storyMode.description)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Gemma 4 model download row — only visible when mode requires it
            if vm.storyMode == .gemma4OnDevice || vm.storyMode == .hybrid {
                gemmaModelRow
            }

            // Cloud configuration — only visible when cloud or hybrid mode is selected
            if vm.storyMode == .cloud || vm.storyMode == .hybrid {
                TextField("Cloud Agent URL", text: $cloudURLString)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(.caption)
                    .onSubmit { saveCloudConfig() }

                SecureField("API Key (X-SeeSaw-Key)", text: $cloudAgentKey)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(.caption)
                    .onSubmit { saveCloudConfig() }
            }
        } header: {
            Text("Story Engine")
        }
    }

    @ViewBuilder
    private var gemmaModelRow: some View {
        switch gemmaModelState {
        case .notDownloaded:
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gemma 4 1B model")
                        .font(.subheadline)
                    Text("~800 MB required for on-device mode")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Download") {
                    Task { await startDownload() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

        case .downloading(let progress):
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Downloading Gemma 4…")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: progress)
                    .tint(.teal)
            }

        case .ready:
            HStack {
                Label("Gemma 4 model ready", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline)
                Spacer()
                Button("Remove", role: .destructive) {
                    Task { await deleteModel() }
                }
                .font(.caption)
                .foregroundStyle(.red)
            }

        case .failed(let reason):
            VStack(alignment: .leading, spacing: 4) {
                Label("Download failed", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .font(.subheadline)
                Text(reason)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Button("Retry") {
                    Task { await startDownload() }
                }
                .font(.caption)
            }
        }
    }

    // MARK: - Gemma download actions

    private func refreshGemmaState() async {
        gemmaModelState = await vm.gemma4StoryService.currentModelState()
    }

    private func startDownload() async {
        for await event in await vm.modelDownloadManager.downloadModel() {
            switch event {
            case .progress(let p):
                gemmaModelState = .downloading(progress: p)
                downloadProgress = p
            case .completed(let path):
                gemmaModelState = .ready(modelPath: path)
            case .failed(let error):
                gemmaModelState = .failed(reason: error.localizedDescription)
            }
        }
    }

    private func deleteModel() async {
        try? await vm.modelDownloadManager.deleteModel()
        gemmaModelState = .notDownloaded
    }

    // MARK: - Child Preferences section

    private var childPreferencesSection: some View {
        Section {
            TextField("Child's name", text: $childName)
                .textContentType(.givenName)
                .autocorrectionDisabled()

            Stepper("Age: \(childAge)", value: $childAge, in: 2...12)

            VStack(alignment: .leading, spacing: 10) {
                Text("Favourite Topics")
                    .font(.subheadline.bold())
                    .padding(.top, 4)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(ChildProfile.presetTopics, id: \.self) { topic in
                        preferenceChip(topic)
                    }
                }
            }
        } header: {
            Text("Child Preferences")
        }
    }

    @ViewBuilder
    private func preferenceChip(_ topic: String) -> some View {
        let selected = selectedPreferences.contains(topic)
        Button {
            if selected { selectedPreferences.remove(topic) }
            else        { selectedPreferences.insert(topic) }
        } label: {
            Text(topic)
                .font(.caption.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selected ? Color.teal : Color(.tertiarySystemBackground))
                .foregroundStyle(selected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Account section

    private var accountSection: some View {
        Section("Account") {
            Button(role: .destructive) {
                showSignOutConfirmation = true
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    // MARK: - Save

    private func savePreferences() {
        UserDefaults.standard.childName        = childName
        UserDefaults.standard.childAge         = childAge
        UserDefaults.standard.childPreferences = Array(selectedPreferences)
        saveCloudConfig()
    }

    private func saveCloudConfig() {
        if let url = URL(string: cloudURLString.trimmingCharacters(in: .whitespacesAndNewlines)),
           url.scheme?.hasPrefix("http") == true {
            UserDefaults.standard.cloudAgentURL = url
        }
        UserDefaults.standard.cloudAgentKey = cloudAgentKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    let container = AppDependencyContainer()
    SettingsTabView(
        vm: container.makeCompanionViewModel(),
        accessoryManager: container.accessoryManager,
        coordinator: AppCoordinator(container: container)
    )
}
