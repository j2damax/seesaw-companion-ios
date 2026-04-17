// AppConfig.swift
// SeeSaw — Tier 2 companion app
//
// Single source of truth for app-wide configuration.
// #if DEBUG appears here and nowhere else — all feature flags
// that differ between Debug and Release builds are set in this file.
//
// ── Endpoint & model config ──────────────────────────────────────────────────
// Edit the constants in the "Endpoints" section below to point at your
// Cloud Run service and GGUF model.  These values are written into
// UserDefaults once at first launch (or when blank), so the Settings UI
// can still override them at runtime without an app rebuild.

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

    // MARK: - Endpoints  ← edit these for your deployment

    /// Base URL of the Cloud Run story-agent service.
    /// Used for cloud and hybrid story modes, and to fetch a signed GGUF download URL.
    /// Leave empty to disable cloud features entirely.
    static let cloudAgentBaseURL = "https://seesaw-cloud-agent-531853173205.europe-west1.run.app"

    /// Optional API key sent as `X-SeeSaw-Key` header on every cloud request.
    /// Leave empty if your Cloud Run service is unauthenticated.
    static let cloudAgentAPIKey  = "289bbf7d03f9118862730b8fd46c14e9cdaf4b966d22207a4d9cddc08f23de1a"

    /// Gemma 2 2B IT GPU int8 in MediaPipe .task format (Kaggle LiteRT variation).
    /// MediaPipe TasksGenAI 0.10.33 on iOS requires .task (TFLite FlatBuffer) — GGUF not supported on iOS.
    /// Source: kaggle.com/models/google/gemma-2/tfLite → gemma2-2b-it-gpu-int8 → Version 1
    static let gemma4DirectDownloadURL = "https://storage.googleapis.com/seesaw-models/gemma2-2b-it-gpu-int8.bin"

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
