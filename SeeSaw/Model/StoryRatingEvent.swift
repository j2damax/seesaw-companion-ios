// StoryRatingEvent.swift
// SeeSaw — Tier 2 companion app
//
// Parent-submitted rating for a completed story session.

import Foundation

struct StoryRatingEvent: Sendable {
    let sessionId: UUID
    let generationMode: StoryGenerationMode
    let childAge: Int
    let beatsPlayed: Int
    let sessionDurationMs: Double

    /// 1–5 star ratings submitted by the parent.
    let enjoyment: Int
    let ageAppropriateness: Int
    let sceneGrounding: Int

    let timestamp: Date

    init(
        sessionId: UUID = UUID(),
        generationMode: StoryGenerationMode,
        childAge: Int,
        beatsPlayed: Int,
        sessionDurationMs: Double,
        enjoyment: Int,
        ageAppropriateness: Int,
        sceneGrounding: Int,
        timestamp: Date = Date()
    ) {
        self.sessionId            = sessionId
        self.generationMode       = generationMode
        self.childAge             = childAge
        self.beatsPlayed          = beatsPlayed
        self.sessionDurationMs    = sessionDurationMs
        self.enjoyment            = enjoyment
        self.ageAppropriateness   = ageAppropriateness
        self.sceneGrounding       = sceneGrounding
        self.timestamp            = timestamp
    }
}
