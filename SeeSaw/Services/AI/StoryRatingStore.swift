// StoryRatingStore.swift
// SeeSaw — Tier 2 companion app
//
// Actor that persists parent story ratings for Chapter 6 dissertation analysis.
// Follows the same pattern as HybridMetricsStore.

import Foundation

actor StoryRatingStore {

    private var ratings: [StoryRatingEvent] = []

    // MARK: - Write

    func record(_ rating: StoryRatingEvent) {
        ratings.append(rating)
    }

    // MARK: - Query

    func eventCount() -> Int { ratings.count }

    func averageEnjoyment() -> Double {
        guard !ratings.isEmpty else { return 0 }
        return Double(ratings.map(\.enjoyment).reduce(0, +)) / Double(ratings.count)
    }

    func averageAgeAppropriateness() -> Double {
        guard !ratings.isEmpty else { return 0 }
        return Double(ratings.map(\.ageAppropriateness).reduce(0, +)) / Double(ratings.count)
    }

    func averageSceneGrounding() -> Double {
        guard !ratings.isEmpty else { return 0 }
        return Double(ratings.map(\.sceneGrounding).reduce(0, +)) / Double(ratings.count)
    }

    // MARK: - Export

    /// CSV export for Chapter 6 analysis.
    /// Header: session_id,mode,child_age,beats,duration_ms,enjoyment,age_appropriate,scene_grounding,timestamp
    func exportCSV() -> String {
        let header = "session_id,mode,child_age,beats,duration_ms,enjoyment,age_appropriate,scene_grounding,timestamp"
        let rows = ratings.map { r -> String in
            "\(r.sessionId),\(r.generationMode.rawValue),\(r.childAge),\(r.beatsPlayed),\(String(format: "%.0f", r.sessionDurationMs)),\(r.enjoyment),\(r.ageAppropriateness),\(r.sceneGrounding),\(r.timestamp)"
        }
        return ([header] + rows).joined(separator: "\n")
    }
}
