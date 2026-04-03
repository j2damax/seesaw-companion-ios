// SessionState.swift
// SeeSaw — Tier 2 companion app

enum SessionState: Equatable, Sendable {
    case idle
    case scanning
    case connected
    case receivingImage
    case processingPrivacy
    case requestingStory
    case encodingAudio
    case sendingAudio
    case error(String)

    // MARK: - Display

    var displayTitle: String {
        switch self {
        case .idle:              return "Idle"
        case .scanning:          return "Connecting…"
        case .connected:         return "Connected"
        case .receivingImage:    return "Receiving image…"
        case .processingPrivacy: return "Processing on-device…"
        case .requestingStory:   return "Requesting story…"
        case .encodingAudio:     return "Encoding audio…"
        case .sendingAudio:      return "Sending audio…"
        case .error(let msg):    return "Error: \(msg)"
        }
    }

    var isActive: Bool {
        switch self {
        case .idle, .connected, .error: return false
        default: return true
        }
    }

    var isConnected: Bool {
        switch self {
        case .connected, .receivingImage, .processingPrivacy,
             .requestingStory, .encodingAudio, .sendingAudio:
            return true
        default:
            return false
        }
    }
}
