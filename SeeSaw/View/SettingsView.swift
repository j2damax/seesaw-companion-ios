// SettingsView.swift
// SeeSaw — Tier 2 companion app
//
// Parent-facing settings. Two settings for PoC:
//   • Child age (used in ScenePayload)
//   • Cloud agent URL (posted to for story generation)

import SwiftUI

struct SettingsView: View {

    @Binding var childAge: Int

    @State private var cloudURLString: String = UserDefaults.standard.cloudAgentURL.absoluteString
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                childAgeSection
                cloudSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { save(); dismiss() }
                }
            }
        }
    }

    // MARK: - Sections

    private var childAgeSection: some View {
        Section("Child Profile") {
            Stepper("Age: \(childAge)", value: $childAge, in: 2...12)
        }
    }

    private var cloudSection: some View {
        Section {
            TextField("https://your-cloud-run-url", text: $cloudURLString)
                .keyboardType(.URL)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        } header: {
            Text("Cloud Agent URL")
        } footer: {
            Text("ScenePayload is POST-ed to this URL at /story. Never includes raw image or audio.")
                .font(.caption)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("App", value: "SeeSaw Companion")
            LabeledContent("Version", value: "1.0 PoC")
            LabeledContent("Privacy", value: "On-device only")
        }
    }

    // MARK: - Save

    private func save() {
        UserDefaults.standard.childAge = childAge
        if let url = URL(string: cloudURLString), url.scheme?.hasPrefix("http") == true {
            UserDefaults.standard.cloudAgentURL = url
        }
    }
}

#Preview {
    SettingsView(childAge: .constant(5))
}
