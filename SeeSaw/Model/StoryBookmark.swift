// StoryBookmark.swift
// SeeSaw — Tier 2 companion app
//
// Model + shared actor store for story bookmarks created by BookmarkMomentTool.
// Parents can view bookmarked moments in the Settings dashboard.

import Foundation

// MARK: - Model

struct StoryBookmark: Sendable {
    let description: String
    let timestamp: Date
}

// MARK: - Store

actor StoryBookmarkStore {

    static let shared = StoryBookmarkStore()

    private(set) var bookmarks: [StoryBookmark] = []

    func add(_ description: String) {
        bookmarks.append(StoryBookmark(description: description, timestamp: Date()))
    }

    func clear() {
        bookmarks = []
    }
}
