// StoryError.swift
// SeeSaw — Tier 2 companion app
//
// Error types for on-device story generation via Foundation Models.

import Foundation

enum StoryError: LocalizedError, Sendable, Equatable {
    case noActiveSession
    case modelUnavailable
    case modelDownloading
    case contextWindowExceeded
    case guardrailViolation
    case generationFailed(String)

    var errorDescription: String? {
        switch self {
        case .noActiveSession:
            return "No active story session."
        case .modelUnavailable:
            return "On-device model is not available. Apple Intelligence must be enabled on iPhone 15 Pro or later."
        case .modelDownloading:
            return "On-device model is still downloading. Please wait."
        case .contextWindowExceeded:
            return "Story session exceeded context limit. Starting fresh."
        case .guardrailViolation:
            return "Content was adjusted by safety filters."
        case .generationFailed(let detail):
            return "Story generation failed: \(detail)"
        }
    }
}
