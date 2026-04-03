// AppConfig.swift
// SeeSaw — Tier 2 companion app
//
// Single source of truth for app-wide configuration.
// #if DEBUG appears here and nowhere else — all feature flags
// that differ between Debug and Release builds are set in this file.

import Foundation

struct AppConfig: Sendable {

    // MARK: - Shared instance

    static let shared = AppConfig()

    // MARK: - Feature flags

    /// When true, all pipeline log calls emit output.
    /// Set to true automatically in Debug builds; always false in Release.
    let enableLogging: Bool

    /// When true, use the asset image named "test1" for the preview/detection pipeline instead of camera capture (test mode).
    let useTestImageForPreview: Bool

    // MARK: - Init

    private init() {
        #if DEBUG
        enableLogging = true
        useTestImageForPreview = false // Change to false to use real camera
        #else
        enableLogging = false
        useTestImageForPreview = false
        #endif
    }
}
