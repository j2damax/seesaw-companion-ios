// HybridBeatMetric.swift
// SeeSaw — Tier 2 companion app
//
// Per-beat metric for hybrid mode (Architecture D, Chapter 6 dissertation).
// Records which agent produced each beat and whether the cloud responded in time.

import Foundation

enum HybridSource: String, Codable, Sendable {
    case cloud          // Cloud beat arrived within 1s deadline; used
    case localGemma4    // Gemma4 generated the beat (cloud too slow or failed)
    case localOnDevice  // Apple FM generated the beat (Gemma4 unavailable)
}

enum EndingSource: String, Codable, Sendable {
    case localHeuristic // Keyword match in Gemma4StoryService / OnDeviceStoryService
    case cloudLLM       // Gemini narrative-arc evaluation
    case turnCap        // maxTurns reached
}

struct HybridBeatMetric: Codable, Sendable {
    let turnNumber: Int
    let source: HybridSource
    /// Always measured, even when the cloud beat was used. Represents the time
    /// spent waiting on consumeEnhancedBeat() (≤1s when cloud wins, actual
    /// local generation time when cloud falls back).
    let localGenerationMs: Double
    /// nil when cloud did not respond before the 1s deadline.
    let cloudResponseMs: Double?
    let cloudArrivedInTime: Bool
    /// nil when this is not an ending beat.
    let endingDetectedBy: EndingSource?
    let timestamp: Double
}
