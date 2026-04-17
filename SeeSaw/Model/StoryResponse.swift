// StoryResponse.swift
// SeeSaw — Tier 2 companion app
//
// Decoded from the cloud agent's POST /story/generate response.
// Field names use CodingKeys to map snake_case JSON → camelCase Swift.
// Schema is fixed — matches StoryBeatResponse in seesaw-cloud-agent/app/models/story_beat.py.

struct StoryResponse: Codable, Sendable {
    let storyText: String
    let question: String
    let isEnding: Bool
    let sessionId: String
    let beatIndex: Int

    enum CodingKeys: String, CodingKey {
        case storyText  = "story_text"
        case question
        case isEnding   = "is_ending"
        case sessionId  = "session_id"
        case beatIndex  = "beat_index"
    }
}
