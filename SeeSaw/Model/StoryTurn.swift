// StoryTurn.swift
// SeeSaw — Tier 2 companion app
//
// One turn in the story conversation history sent to the cloud agent.
// Mirrors StoryTurn in seesaw-cloud-agent/app/models/scene_payload.py.

struct StoryTurn: Codable, Sendable {
    let role: String   // "model" (AI) or "user" (child)
    let text: String
}
