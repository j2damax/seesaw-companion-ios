// StoryBeatTests.swift
// SeeSaw — Unit tests for StoryBeat model

import Testing
import Foundation

@testable import SeeSaw

// MARK: - StoryBeat field tests

struct StoryBeatTests {

    @Test func safeFallbackHasNonEmptyFields() {
        let beat = StoryBeat.safeFallback
        #expect(!beat.storyText.isEmpty)
        #expect(!beat.question.isEmpty)
        #expect(!beat.theme.isEmpty)
        #expect(!beat.suggestedContinuation.isEmpty)
        #expect(beat.isEnding == false)
    }

    @Test func endingFallbackMarkedAsEnding() {
        let beat = StoryBeat.endingFallback
        #expect(beat.isEnding == true)
        #expect(!beat.storyText.isEmpty)
        #expect(!beat.question.isEmpty)
    }

    @Test func safeFallbackIsNotEnding() {
        #expect(StoryBeat.safeFallback.isEnding == false)
    }

    @Test func endingFallbackHasEmptyContinuation() {
        #expect(StoryBeat.endingFallback.suggestedContinuation.isEmpty)
    }

    @Test func manualConstructionPreservesFields() {
        let beat = StoryBeat(
            storyText: "Once upon a time, there was a kind dragon.",
            question: "What colour was the dragon?",
            isEnding: false,
            theme: "adventure",
            suggestedContinuation: "The dragon befriends a knight."
        )
        #expect(beat.storyText.contains("dragon"))
        #expect(beat.question.contains("colour"))
        #expect(beat.theme == "adventure")
        #expect(beat.isEnding == false)
    }

    @Test func sendableConformance() {
        // StoryBeat is Sendable — verify it can cross isolation boundaries
        let beat = StoryBeat.safeFallback
        let task = Task { @Sendable in
            return beat.storyText
        }
        // Compilation success proves Sendable conformance
        _ = task
    }
}
