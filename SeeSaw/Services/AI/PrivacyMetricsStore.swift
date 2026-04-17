// PrivacyMetricsStore.swift
// SeeSaw — Tier 2 companion app
//
// In-memory store for privacy pipeline metrics.
// Provides CSV export for dissertation evidence and summary statistics
// for the parent-facing Privacy Dashboard.

import Foundation

actor PrivacyMetricsStore {

    // MARK: - Storage

    private var events: [PrivacyMetricsEvent] = []

    // MARK: - Recording

    func record(_ event: PrivacyMetricsEvent) {
        events.append(event)
    }

    // MARK: - Queries

    func allEvents() -> [PrivacyMetricsEvent] {
        events
    }

    func eventCount() -> Int {
        events.count
    }

    func averageLatency() -> Double {
        guard !events.isEmpty else { return 0 }
        return events.map(\.pipelineLatencyMs).reduce(0, +) / Double(events.count)
    }

    func privacySanitisationRate() -> Double {
        guard !events.isEmpty else { return 1.0 }
        let clean = events.filter { !$0.rawDataTransmitted }.count
        return Double(clean) / Double(events.count)
    }

    func totalFacesDetected() -> Int {
        events.map(\.facesDetected).reduce(0, +)
    }

    func totalFacesBlurred() -> Int {
        events.map(\.facesBlurred).reduce(0, +)
    }

    func totalTokensScrubbed() -> Int {
        events.map(\.tokensScrubbedFromTranscript).reduce(0, +)
    }

    // MARK: - CSV Export

    func exportCSV() -> String {
        var csv = "generationMode,facesDetected,facesBlurred,objectsDetected,tokensScrubbedFromTranscript,rawDataTransmitted,pipelineLatencyMs,faceDetectMs,blurMs,yoloMs,sceneClassifyMs,sttMs,piiScrubMs,timestamp\n"
        for e in events {
            csv += "\(e.generationMode),\(e.facesDetected),\(e.facesBlurred),\(e.objectsDetected),\(e.tokensScrubbedFromTranscript),\(e.rawDataTransmitted),\(e.pipelineLatencyMs),\(e.faceDetectMs),\(e.blurMs),\(e.yoloMs),\(e.sceneClassifyMs),\(e.sttMs),\(e.piiScrubMs),\(e.timestamp)\n"
        }
        return csv
    }

    // MARK: - Reset

    func reset() {
        events.removeAll()
    }
}
