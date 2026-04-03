// StoryResponse.swift
// SeeSaw — Tier 2 companion app

struct StoryResponse: Codable, Sendable {
    let storyText: String
    let audioURL: String?
}
