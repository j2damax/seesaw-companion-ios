// SemanticTurnDetectorTests.swift
// SeeSaw — Unit tests for SemanticTurnDetector Layer 1 heuristic
//
// Layer 2 (Apple FM semantic check) requires a physical device with Apple
// Intelligence enabled and cannot be tested in CI. These tests cover the
// heuristic-only path (isIncomplete) exhaustively.

import Testing
import Foundation

@testable import SeeSaw

struct SemanticTurnDetectorTests {

    let detector = SemanticTurnDetector()

    // MARK: - Layer 1: Incomplete phrases (expect true)

    @Test func trailingAndThen() async {
        #expect(await detector.isIncomplete(transcript: "the dragon went and then") == true)
    }

    @Test func trailingBut() async {
        #expect(await detector.isIncomplete(transcript: "she wanted to go but") == true)
    }

    @Test func trailingMaybe() async {
        #expect(await detector.isIncomplete(transcript: "maybe") == true)
    }

    @Test func trailingBecause() async {
        #expect(await detector.isIncomplete(transcript: "he was scared because") == true)
    }

    @Test func trailingUm() async {
        #expect(await detector.isIncomplete(transcript: "the bear went um") == true)
    }

    @Test func trailingIThink() async {
        #expect(await detector.isIncomplete(transcript: "they should fly away i think") == true)
    }

    // MARK: - Layer 1: Complete responses (expect false)

    @Test func fullSentenceWithPeriod() async {
        #expect(await detector.isIncomplete(transcript: "the dragon flew over the mountain.") == false)
    }

    @Test func singleWordYes() async {
        #expect(await detector.isIncomplete(transcript: "yes") == false)
    }

    @Test func singleWordNo() async {
        #expect(await detector.isIncomplete(transcript: "no") == false)
    }

    @Test func concreteAnswer() async {
        #expect(await detector.isIncomplete(transcript: "he should go find his friend") == false)
    }

    @Test func andMidSentenceIsComplete() async {
        // "and" in the middle of a sentence should not trigger extension
        #expect(await detector.isIncomplete(transcript: "the cat and the dog played") == false)
    }

    // MARK: - Edge cases (expect false — no extension on silence-only)

    @Test func emptyStringIsComplete() async {
        #expect(await detector.isIncomplete(transcript: "") == false)
    }

    @Test func whitespaceOnlyIsComplete() async {
        #expect(await detector.isIncomplete(transcript: "   ") == false)
    }

    // MARK: - Case insensitivity

    @Test func caseInsensitiveTrailingPhrase() async {
        #expect(await detector.isIncomplete(transcript: "went to the tower AND THEN") == true)
    }
}
