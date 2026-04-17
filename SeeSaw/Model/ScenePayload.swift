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
    let childName: String
    let sessionId: String
    let storyHistory: [StoryTurn]

    init(
        objects: [String],
        scene: [String],
        transcript: String?,
        childAge: Int,
        childName: String,
        sessionId: String,
        storyHistory: [StoryTurn] = []
    ) {
        self.objects      = objects
        self.scene        = scene
        self.transcript   = transcript
        self.childAge     = childAge
        self.childName    = childName
        self.sessionId    = sessionId
        self.storyHistory = storyHistory
    }

    enum CodingKeys: String, CodingKey {
        case objects
        case scene
        case transcript
        case childAge     = "child_age"
        case childName    = "child_name"
        case sessionId    = "session_id"
        case storyHistory = "story_history"
    }
}
