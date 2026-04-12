// StoryBeat.swift
// SeeSaw — Tier 2 companion app
//
// Structured output from the on-device Foundation Models LLM.
// Kept intentionally minimal (3 fields) so the @Generable JSON schema is small.
// Fewer fields = fewer tokens generated per beat = avoids context-window overflow
// on the on-device 3B-parameter model.

import FoundationModels

@Generable
struct StoryBeat: Sendable {

    @Guide(description: "Story text, 2-3 short sentences, max 30 words, spoken aloud to the child")
    var storyText: String

    @Guide(description: "One very short question for the child, max 10 words")
    var question: String

    @Guide(description: "True only when this is the final story beat")
    var isEnding: Bool
}

// MARK: - Safe fallbacks

extension StoryBeat {

    /// Pre-written safe segment used when all LLM retries fail.
    static let safeFallback = StoryBeat(
        storyText: "The friends decided to go on a peaceful walk through the meadow, picking wildflowers and watching butterflies dance in the sunlight.",
        question: "What kind of flower do you think they found?",
        isEnding: false
    )

    /// Warm ending beat for graceful story conclusion.
    static let endingFallback = StoryBeat(
        storyText: "And so the adventure came to a happy end. Everyone smiled and felt grateful for the wonderful journey they had shared together.",
        question: "What was your favourite part of the story?",
        isEnding: true
    )
}
