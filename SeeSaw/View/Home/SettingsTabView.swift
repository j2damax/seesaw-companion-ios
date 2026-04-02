// SettingsTabView.swift
// SeeSaw — Tier 2 companion app
//
// "Settings" tab on the home screen.
// Contains three sections:
//   1. Accessory Setup  — reuses AccessoryPickerView
//   2. Child Preferences — name, age, favourite topics
//   3. Account          — Sign Out

import SwiftUI

struct SettingsTabView: View {

    var accessoryManager: AccessoryManager
    let coordinator: AppCoordinator

    @State private var childName: String = UserDefaults.standard.childName
    @State private var childAge: Int = UserDefaults.standard.childAge
    @State private var selectedPreferences: Set<String> = Set(UserDefaults.standard.childPreferences)
    @State private var showSignOutConfirmation = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
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
        }
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
    }
}

#Preview {
    let container = AppDependencyContainer()
    SettingsTabView(
        accessoryManager: container.accessoryManager,
        coordinator: AppCoordinator(container: container)
    )
}
