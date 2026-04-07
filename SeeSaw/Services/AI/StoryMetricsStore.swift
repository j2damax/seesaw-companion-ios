// StoryMetricsStore.swift
// SeeSaw — Tier 2 companion app
//
// Actor-based store for story generation metrics.
// Supports recording, querying, and CSV export for dissertation benchmarking.

import Foundation

actor StoryMetricsStore {

    // MARK: - Storage

    private var events: [StoryMetricsEvent] = []

    // MARK: - Recording

    func record(_ event: StoryMetricsEvent) {
        events.append(event)
    }

    // MARK: - Queries

    func eventCount() -> Int {
        events.count
    }

    func averageGenerationMs() -> Double {
        guard !events.isEmpty else { return 0 }
        return events.map(\.totalGenerationMs).reduce(0, +) / Double(events.count)
    }

    func averageTimeToFirstTokenMs() -> Double {
        guard !events.isEmpty else { return 0 }
        return events.map(\.timeToFirstTokenMs).reduce(0, +) / Double(events.count)
    }

    func totalTurns() -> Int {
        events.map(\.turnCount).max() ?? 0
    }

    func totalGuardrailViolations() -> Int {
        events.map(\.guardrailViolations).reduce(0, +)
    }

    func averageStoryLength() -> Int {
        guard !events.isEmpty else { return 0 }
        return events.map(\.storyTextLength).reduce(0, +) / events.count
    }

    func allEvents() -> [StoryMetricsEvent] {
        events
    }

    // MARK: - CSV Export

    func exportCSV() -> String {
        var csv = "generationMode,timeToFirstTokenMs,totalGenerationMs,"
        csv += "turnCount,guardrailViolations,storyTextLength,timestamp\n"
        for e in events {
            csv += "\(e.generationMode),"
            csv += "\(e.timeToFirstTokenMs),"
            csv += "\(e.totalGenerationMs),"
            csv += "\(e.turnCount),"
            csv += "\(e.guardrailViolations),"
            csv += "\(e.storyTextLength),"
            csv += "\(e.timestamp)\n"
        }
        return csv
    }
}
