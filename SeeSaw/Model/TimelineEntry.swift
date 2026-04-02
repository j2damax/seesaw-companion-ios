// TimelineEntry.swift
// SeeSaw — Tier 2 companion app
//
// One completed pipeline run (capture → privacy → story).
// Held in-memory by CompanionViewModel for the Timeline tab.

import Foundation

struct TimelineEntry: Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    let sceneObjects: [String]
    let storySnippet: String?

    init(sceneObjects: [String], storySnippet: String?) {
        id            = UUID()
        timestamp     = Date()
        self.sceneObjects  = sceneObjects
        self.storySnippet  = storySnippet
    }
}
