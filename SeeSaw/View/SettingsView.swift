// SettingsView.swift
// SeeSaw — Tier 2 companion app
//
// Parent-facing settings:
//   • Input Source  — selects which wearable / accessory to use
//   • Child age     — used in ScenePayload
//   • Cloud agent URL — endpoint for story generation
//   • Privacy Metrics — transparency dashboard

import SwiftUI

struct SettingsView: View {

    @Binding var childAge: Int
    var accessoryManager: AccessoryManager
    var metricsStore: PrivacyMetricsStore

    @State private var cloudURLString: String = UserDefaults.standard.cloudAgentURL.absoluteString
    @State private var metricsCount = 0
    @State private var avgLatency = 0.0
    @State private var sanitisationRate = 1.0
    @State private var totalFaces = 0
    @State private var totalBlurred = 0
    @State private var totalTokensScrubbed = 0
    @State private var csvData = ""
    @State private var showingCSVShare = false
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                AccessoryPickerView(accessoryManager: accessoryManager)
                childAgeSection
                cloudSection
                privacyMetricsSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { save(); dismiss() }
                }
            }
            .task { await loadMetrics() }
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

    private var privacyMetricsSection: some View {
        Section {
            LabeledContent("Pipeline Runs", value: "\(metricsCount)")
            LabeledContent("Avg Latency", value: metricsCount > 0 ? "\(Int(avgLatency)) ms" : "—")
            LabeledContent("Sanitisation Rate", value: formatPercent(sanitisationRate))
            LabeledContent("Faces Detected", value: "\(totalFaces)")
            LabeledContent("Faces Blurred", value: "\(totalBlurred)")
            LabeledContent("PII Tokens Scrubbed", value: "\(totalTokensScrubbed)")
            Button("Export CSV") {
                Task {
                    csvData = await metricsStore.exportCSV()
                    showingCSVShare = true
                }
            }
            .disabled(metricsCount == 0)
        } header: {
            Text("Privacy Metrics")
        } footer: {
            Text("All processing runs on-device. Raw images and audio never leave the device.")
                .font(.caption)
        }
        .sheet(isPresented: $showingCSVShare) {
            if let data = csvData.data(using: .utf8) {
                ShareLink(item: data, preview: SharePreview("Privacy Metrics CSV"))
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("App", value: "SeeSaw Companion")
            LabeledContent("Version", value: "1.0 PoC")
            LabeledContent("Privacy", value: "On-device only")
        }
    }

    // MARK: - Helpers

    private func loadMetrics() async {
        metricsCount = await metricsStore.eventCount()
        avgLatency = await metricsStore.averageLatency()
        sanitisationRate = await metricsStore.privacySanitisationRate()
        totalFaces = await metricsStore.totalFacesDetected()
        totalBlurred = await metricsStore.totalFacesBlurred()
        totalTokensScrubbed = await metricsStore.totalTokensScrubbed()
    }

    private func formatPercent(_ value: Double) -> String {
        "\(Int(value * 100))%"
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
    let container = AppDependencyContainer()
    SettingsView(childAge: .constant(5), accessoryManager: container.accessoryManager, metricsStore: container.privacyMetricsStore)
}

