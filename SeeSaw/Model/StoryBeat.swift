// StoryBeat.swift
// SeeSaw — Tier 2 companion app
//
// Structured output from the on-device Foundation Models LLM.
// Uses @Generable and @Guide macros for type-safe constrained generation.
// One of only two files that imports FoundationModels (the other is OnDeviceStoryService).

import FoundationModels

@Generable
struct StoryBeat: Sendable {

    @Guide(description: "A short story segment of 3-5 sentences, age-appropriate, to be spoken aloud")
    var storyText: String

    @Guide(description: "One open-ended imaginative question for the child to answer")
    var question: String

    @Guide(description: "True only when the story should reach its conclusion")
    var isEnding: Bool

    @Guide(description: "Current story theme such as adventure, friendship, or discovery")
    var theme: String

    @Guide(description: "Brief internal context hint for the next turn, never spoken aloud")
    var suggestedContinuation: String
}

// MARK: - Safe fallback

extension StoryBeat {

    /// Pre-written safe story segment used when all LLM retries fail.
    static let safeFallback = StoryBeat(
        storyText: "The friends decided to go on a peaceful walk through the meadow, picking wildflowers and watching butterflies dance in the sunlight.",
        question: "What kind of flower do you think they found?",
        isEnding: false,
        theme: "nature",
        suggestedContinuation: "Continue with gentle nature exploration."
    )

    /// Warm ending beat for graceful story conclusion.
    static let endingFallback = StoryBeat(
        storyText: "And so the adventure came to a happy end. Everyone smiled and felt grateful for the wonderful journey they had shared together.",
        question: "What was your favourite part of the story?",
        isEnding: true,
        theme: "friendship",
        suggestedContinuation: ""
    )
}
