// PrivacyMetricsEvent.swift
// SeeSaw — Tier 2 companion app
//
// Auditable record produced by every privacy pipeline run.
// Proves no raw data was transmitted and captures per-stage latencies.

struct PrivacyMetricsEvent: Codable, Sendable {
    let generationMode: String
    let facesDetected: Int
    let facesBlurred: Int
    let objectsDetected: Int
    let tokensScrubbedFromTranscript: Int
    let rawDataTransmitted: Bool
    let pipelineLatencyMs: Double

    let faceDetectMs: Double
    let blurMs: Double
    let yoloMs: Double
    let sceneClassifyMs: Double
    let sttMs: Double
    let piiScrubMs: Double

    let timestamp: Double
}
