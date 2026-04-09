// StoryGenerating.swift
// SeeSaw — Tier 2 companion app
//
// Protocol abstraction for story generation. Enables testability via
// MockStoryService without requiring a physical device with Apple Intelligence.
// Both OnDeviceStoryService and future CloudStoryService wrappers conform.

protocol StoryGenerating: Sendable {
    func startStory(context: SceneContext, profile: ChildProfile) async throws -> StoryBeat
    func continueTurn(childAnswer: String) async throws -> StoryBeat
    func endSession() async
    var isSessionActive: Bool { get async }
    var currentTurnCount: Int { get async }
}
