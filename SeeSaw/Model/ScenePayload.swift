// ScenePayload.swift
// SeeSaw — Tier 2 companion app
//
// Sent to the cloud story agent. Contains ONLY anonymous labels — no raw
// pixels, no face data, no voice biometrics. This is the privacy boundary.

struct ScenePayload: Codable, Sendable {
    let objects: [String]
    let scene: [String]
    let transcript: String?
    let childAge: Int
    let sessionId: String
    let query: String?
    let timestamp: String
}
