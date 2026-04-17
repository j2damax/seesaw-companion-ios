// StoryGenerationMode.swift
// SeeSaw — Tier 2 companion app
//
// Controls how stories are generated: on-device LLM, cloud API, or hybrid.

enum StoryGenerationMode: String, CaseIterable, Sendable {
    case onDevice       = "onDevice"        // Apple Foundation Models (default)
    case gemma4OnDevice = "gemma4OnDevice"  // Gemma 4 1B GGUF via MediaPipe
    case cloud          = "cloud"           // seesaw-cloud-agent FastAPI + Gemini
    case hybrid         = "hybrid"          // cloud → gemma4OnDevice → onDevice fallback

    var displayName: String {
        switch self {
        case .onDevice:       return "On-Device (Apple FM)"
        case .gemma4OnDevice: return "On-Device (Gemma 4)"
        case .cloud:          return "Cloud"
        case .hybrid:         return "Hybrid"
        }
    }

    var description: String {
        switch self {
        case .onDevice:       return "Apple Foundation Models. Maximum privacy, no download needed."
        case .gemma4OnDevice: return "Gemma 4 1B on-device. Richer stories. Requires ~800 MB download."
        case .cloud:          return "Cloud AI via Gemini 2.0 Flash. Best quality, requires internet."
        case .hybrid:         return "Cloud first, falls back to on-device automatically."
        }
    }

    /// Whether this mode requires a network connection.
    var requiresNetwork: Bool {
        switch self {
        case .onDevice, .gemma4OnDevice: return false
        case .cloud, .hybrid:            return true
        }
    }
}
