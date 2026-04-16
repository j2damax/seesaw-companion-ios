// StoryBeatCodable.swift
// SeeSaw — Tier 2 companion app
//
// Manual Codable conformance for StoryBeat. @Generable does NOT synthesise
// Codable — it only synthesises the Foundation Models structured-output
// protocol conformance. This extension adds JSON encode/decode for the
// hybrid mode cloud enhancement path (EnhancementRequest body and
// /story/enhance response decoding).

import Foundation
import FoundationModels

extension StoryBeat: Codable {
    enum CodingKeys: String, CodingKey {
        case storyText = "story_text"
        case question
        case isEnding  = "is_ending"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let text     = try container.decode(String.self, forKey: .storyText)
        let question = try container.decode(String.self, forKey: .question)
        let ending   = try container.decode(Bool.self,   forKey: .isEnding)
        self.init(storyText: text, question: question, isEnding: ending)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(storyText, forKey: .storyText)
        try container.encode(question,  forKey: .question)
        try container.encode(isEnding,  forKey: .isEnding)
    }
}
