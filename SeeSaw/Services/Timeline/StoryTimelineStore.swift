// StoryTimelineStore.swift
// SeeSaw — SwiftData persistence layer for the Story Timeline.
//
// Owns the ModelContainer (shared with the SwiftUI view hierarchy) and
// provides write operations. Views read via @Query using the shared container
// injected through the environment via .modelContainer() on AppRootView.
//
// @MainActor: ModelContext is not Sendable — all mutations happen on the main thread.

import Foundation
import SwiftData

@MainActor
final class StoryTimelineStore {

    // MARK: - Container

    /// The shared ModelContainer. Pass to `.modelContainer(storyTimelineStore.container)`
    /// on the root view so @Query-based views can read from the same store.
    let container: ModelContainer
    private let context: ModelContext

    // MARK: - Init

    init() {
        do {
            let schema = Schema([StorySessionRecord.self, StoryBeatRecord.self])
            let config = ModelConfiguration("SeeSawTimeline", schema: schema)
            container = try ModelContainer(for: schema, configurations: config)
            context = container.mainContext
        } catch {
            fatalError("SeeSaw: Failed to initialise StoryTimelineStore — \(error)")
        }
    }

    // MARK: - Session lifecycle

    /// Inserts a new (incomplete) session and persists immediately.
    func insert(_ session: StorySessionRecord) {
        context.insert(session)
        save()
        AppConfig.shared.log("StoryTimeline: session inserted id=\(session.id)")
    }

    /// Marks a session as complete and records whether a context restart occurred.
    func finalizeSession(_ session: StorySessionRecord, hadContextRestart: Bool) {
        session.isCompleted       = true
        session.hadContextRestart = hadContextRestart
        save()
        AppConfig.shared.log("StoryTimeline: session finalised beats=\(session.totalBeats), restart=\(hadContextRestart)")
    }

    // MARK: - Beat management

    /// Appends a beat to a session and saves.
    func addBeat(_ beat: StoryBeatRecord, to session: StorySessionRecord) {
        beat.session = session
        session.beats.append(beat)
        session.totalBeats = session.beats.count
        save()
    }

    /// Records the child's answer on the pending beat and accumulates the PII count.
    func setAnswer(_ answer: String, piiCount: Int, on beat: StoryBeatRecord, session: StorySessionRecord) {
        beat.childAnswer           = answer
        beat.answerLength          = answer.count
        beat.piiTokensRedacted     = piiCount
        session.totalPiiTokensRedacted += piiCount
        save()
    }

    // MARK: - User interactions

    /// Toggles the liked state of a session.
    func toggleLike(_ session: StorySessionRecord) {
        session.isLiked.toggle()
        save()
    }

    // MARK: - Deletion

    func delete(_ session: StorySessionRecord) {
        context.delete(session)
        save()
        AppConfig.shared.log("StoryTimeline: session deleted id=\(session.id)")
    }

    func deleteAll() {
        do {
            try context.delete(model: StorySessionRecord.self)
            save()
            AppConfig.shared.log("StoryTimeline: all sessions deleted")
        } catch {
            AppConfig.shared.log("StoryTimeline: deleteAll failed — \(error.localizedDescription)", level: .error)
        }
    }

    // MARK: - Private

    private func save() {
        do {
            try context.save()
        } catch {
            AppConfig.shared.log("StoryTimeline: save failed — \(error.localizedDescription)", level: .error)
        }
    }
}
