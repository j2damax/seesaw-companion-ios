// StoryMetricsEvent.swift
// SeeSaw — Tier 2 companion app
//
// Benchmark metrics for story generation, used in dissertation Chapter 6.

struct StoryMetricsEvent: Codable, Sendable {
    let generationMode: String
    let timeToFirstTokenMs: Double
    let totalGenerationMs: Double
    let turnCount: Int
    let guardrailViolations: Int
    let storyTextLength: Int
    let timestamp: Double
}
