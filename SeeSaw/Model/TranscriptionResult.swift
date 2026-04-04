// TranscriptionResult.swift
// SeeSaw — Tier 2 companion app

struct TranscriptionResult: Sendable {
    let text: String
    let isFinal: Bool
    let confidence: Float
}
