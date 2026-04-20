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
    var storyMetricsStore: StoryMetricsStore
    var hybridMetricsStore: HybridMetricsStore
    var storyRatingStore: StoryRatingStore

    @State private var cloudURLString: String = UserDefaults.standard.cloudAgentURL?.absoluteString ?? ""
    @State private var metricsCount = 0
    @State private var avgLatency = 0.0
    @State private var sanitisationRate = 1.0
    @State private var totalFaces = 0
    @State private var totalBlurred = 0
    @State private var totalTokensScrubbed = 0
    @State private var storyCount = 0
    @State private var avgGenMs = 0.0
    @State private var avgStoryLen = 0
    @State private var totalViolations = 0
    @State private var hybridBeatCount = 0
    @State private var hybridCloudHitRate = 0.0
    @State private var hybridAvgLocalMs = 0.0
    @State private var hybridAvgCloudMs = 0.0
    @State private var ratingCount = 0
    @State private var avgEnjoyment = 0.0
    @State private var avgAgeAppropriateness = 0.0
    @State private var avgSceneGrounding = 0.0
    @State private var csvData = ""
    @State private var showingCSVShare = false
    @State private var showingExportAll = false
    @State private var exportAllItems: [Any] = []
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                AccessoryPickerView(accessoryManager: accessoryManager)
                childAgeSection
                cloudSection
                privacyMetricsSection
                storyMetricsSection
                hybridMetricsSection
                storyRatingsSection
                exportAllSection
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
            .sheet(isPresented: $showingCSVShare) {
                if let data = csvData.data(using: .utf8) {
                    ShareLink(item: data, preview: SharePreview("SeeSaw CSV Export"))
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
    }

    private var storyRatingsSection: some View {
        Section {
            LabeledContent("Sessions Rated", value: "\(ratingCount)")
            LabeledContent("Avg Enjoyment", value: ratingCount > 0 ? String(format: "%.1f / 5", avgEnjoyment) : "—")
            LabeledContent("Avg Age-Appropriate", value: ratingCount > 0 ? String(format: "%.1f / 5", avgAgeAppropriateness) : "—")
            LabeledContent("Avg Scene Match", value: ratingCount > 0 ? String(format: "%.1f / 5", avgSceneGrounding) : "—")
            Button("Export Ratings CSV") {
                Task {
                    csvData = await storyRatingStore.exportCSV()
                    showingCSVShare = true
                }
            }
            .disabled(ratingCount == 0)
        } header: {
            Text("Story Ratings")
        } footer: {
            Text("Parent-submitted star ratings after each story session.")
                .font(.caption)
        }
    }

    private var exportAllSection: some View {
        Section {
            Button("Export All Data") {
                Task {
                    let privacy  = await metricsStore.exportCSV()
                    let story    = await storyMetricsStore.exportCSV()
                    let hybrid   = await hybridMetricsStore.exportCSV()
                    let ratings  = await storyRatingStore.exportCSV()
                    exportAllItems = [
                        privacy.data(using: .utf8) as Any,
                        story.data(using: .utf8) as Any,
                        hybrid.data(using: .utf8) as Any,
                        ratings.data(using: .utf8) as Any
                    ].compactMap { $0 }
                    showingExportAll = true
                }
            }
        } footer: {
            Text("Shares privacy_metrics.csv, story_metrics.csv, hybrid_metrics.csv and story_ratings.csv in one share sheet.")
                .font(.caption)
        }
        .sheet(isPresented: $showingExportAll) {
            ActivityViewController(activityItems: exportAllItems)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("App", value: "SeeSaw Companion")
            LabeledContent("Version", value: "1.0 PoC")
            LabeledContent("Privacy", value: "On-device only")
        }
    }

    private var storyMetricsSection: some View {
        Section {
            LabeledContent("Story Generations", value: "\(storyCount)")
            LabeledContent("Avg Generation Time", value: storyCount > 0 ? "\(Int(avgGenMs)) ms" : "—")
            LabeledContent("Avg Story Length", value: storyCount > 0 ? "\(avgStoryLen) chars" : "—")
            LabeledContent("Guardrail Violations", value: "\(totalViolations)")
            Button("Export Story CSV") {
                Task {
                    csvData = await storyMetricsStore.exportCSV()
                    showingCSVShare = true
                }
            }
            .disabled(storyCount == 0)
        } header: {
            Text("Story Generation Metrics")
        } footer: {
            Text("Benchmark data for dissertation Chapter 6. Stories generated on-device via Foundation Models.")
                .font(.caption)
        }
    }

    private var hybridMetricsSection: some View {
        Section {
            LabeledContent("Beats Recorded", value: "\(hybridBeatCount)")
            LabeledContent("Cloud Hit Rate", value: hybridBeatCount > 0 ? formatPercent(hybridCloudHitRate) : "—")
            LabeledContent("Avg Local Gen", value: hybridBeatCount > 0 ? "\(Int(hybridAvgLocalMs)) ms" : "—")
            LabeledContent("Avg Cloud Response", value: hybridAvgCloudMs > 0 ? "\(Int(hybridAvgCloudMs)) ms" : "—")
            Button("Export Hybrid CSV") {
                Task {
                    csvData = await hybridMetricsStore.exportCSV()
                    showingCSVShare = true
                }
            }
            .disabled(hybridBeatCount == 0)
        } header: {
            Text("Hybrid Mode Metrics")
        } footer: {
            Text("Per-beat source routing data (local Gemma vs cloud-enhanced). Chapter 6 dissertation data.")
                .font(.caption)
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
        storyCount = await storyMetricsStore.eventCount()
        avgGenMs = await storyMetricsStore.averageGenerationMs()
        avgStoryLen = await storyMetricsStore.averageStoryLength()
        totalViolations = await storyMetricsStore.totalGuardrailViolations()
        hybridBeatCount = await hybridMetricsStore.eventCount()
        hybridCloudHitRate = await hybridMetricsStore.cloudHitRate()
        hybridAvgLocalMs = await hybridMetricsStore.averageLocalMs()
        hybridAvgCloudMs = await hybridMetricsStore.averageCloudMs()
        ratingCount = await storyRatingStore.eventCount()
        avgEnjoyment = await storyRatingStore.averageEnjoyment()
        avgAgeAppropriateness = await storyRatingStore.averageAgeAppropriateness()
        avgSceneGrounding = await storyRatingStore.averageSceneGrounding()
    }

    private func formatPercent(_ value: Double) -> String {
        "\(Int(value * 100))%"
    }

    // MARK: - Save

    private func save() {
        UserDefaults.standard.childAge = childAge
        if let url = URL(string: cloudURLString),
           (url.scheme == "http" || url.scheme == "https"),
           !(url.host?.isEmpty ?? true) {
            UserDefaults.standard.cloudAgentURL = url
        }
    }
}

#Preview {
    let container = AppDependencyContainer()
    SettingsView(
        childAge: .constant(5),
        accessoryManager: container.accessoryManager,
        metricsStore: container.privacyMetricsStore,
        storyMetricsStore: container.storyMetricsStore,
        hybridMetricsStore: container.hybridMetricsStore,
        storyRatingStore: container.storyRatingStore
    )
}

