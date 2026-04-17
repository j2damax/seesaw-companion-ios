// HybridMetricsStore.swift
// SeeSaw — Tier 2 companion app
//
// Actor that records per-beat hybrid metrics for Chapter 6 dissertation analysis.
// Follows the same pattern as StoryMetricsStore — does NOT modify StoryMetricsEvent.

import Foundation

actor HybridMetricsStore {

    private var metrics: [HybridBeatMetric] = []

    // MARK: - Write

    func record(_ metric: HybridBeatMetric) {
        metrics.append(metric)
    }

    // MARK: - Query

    func allMetrics() -> [HybridBeatMetric] { metrics }

    func eventCount() -> Int { metrics.count }

    /// Fraction of turns where the cloud-enhanced beat arrived in time and was used.
    func cloudHitRate() -> Double {
        guard !metrics.isEmpty else { return 0 }
        let hits = metrics.filter { $0.source == .cloud }.count
        return Double(hits) / Double(metrics.count)
    }

    /// Average local generation time across all beats (ms).
    func averageLocalMs() -> Double {
        guard !metrics.isEmpty else { return 0 }
        return metrics.map(\.localGenerationMs).reduce(0, +) / Double(metrics.count)
    }

    /// Average cloud response time for beats where the cloud actually responded (ms).
    func averageCloudMs() -> Double {
        let cloudMs = metrics.compactMap(\.cloudResponseMs)
        guard !cloudMs.isEmpty else { return 0 }
        return cloudMs.reduce(0, +) / Double(cloudMs.count)
    }

    // MARK: - Export

    /// CSV export for Chapter 6 analysis.
    /// Header: turn,source,local_ms,cloud_ms,cloud_arrived,ending_by,timestamp
    func exportCSV() -> String {
        let header = "turn,source,local_ms,cloud_ms,cloud_arrived,ending_by,timestamp"
        let rows = metrics.map { m -> String in
            let cloudMs = m.cloudResponseMs.map { String(format: "%.1f", $0) } ?? ""
            let ending  = m.endingDetectedBy?.rawValue ?? ""
            return "\(m.turnNumber),\(m.source.rawValue),\(String(format: "%.1f", m.localGenerationMs)),\(cloudMs),\(m.cloudArrivedInTime),\(ending),\(m.timestamp)"
        }
        return ([header] + rows).joined(separator: "\n")
    }
}
