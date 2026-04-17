// OnDeviceStoryServiceTests.swift
// SeeSaw — Unit tests for story generation via StoryGenerating protocol
//
// These tests use MockStoryService to verify ViewModel-level story logic
// without requiring a physical device with Apple Intelligence.
// Protocol-driven testing per Decision 1 in the implementation plan.

import Testing
import Foundation

@testable import SeeSaw

// MARK: - MockStoryService

actor MockStoryService: StoryGenerating {

    var startCallCount = 0
    var continueCallCount = 0
    var endCallCount = 0
    var isSessionActive = false
    var currentTurnCount = 0
    var shouldThrow: StoryError?
    var beatToReturn: StoryBeat = .safeFallback

    func startStory(context: SceneContext, profile: ChildProfile) async throws -> StoryBeat {
        if let error = shouldThrow { throw error }
        startCallCount += 1
        isSessionActive = true
        currentTurnCount = 0
        return beatToReturn
    }

    func continueTurn(childAnswer: String) async throws -> StoryBeat {
        if let error = shouldThrow { throw error }
        continueCallCount += 1
        currentTurnCount += 1
        return beatToReturn
    }

    func endSession() {
        endCallCount += 1
        isSessionActive = false
        currentTurnCount = 0
    }
}

// MARK: - MockStoryService lifecycle tests

struct MockStoryServiceLifecycleTests {

    @Test func startStoryActivatesSession() async throws {
        let mock = MockStoryService()
        let context = SceneContext(labels: ["dog"], sceneCategories: ["park"], transcript: nil, childAge: 5)
        let profile = ChildProfile(name: "Test", age: 5, preferences: [])

        let beat = try await mock.startStory(context: context, profile: profile)

        #expect(await mock.isSessionActive == true)
        #expect(await mock.startCallCount == 1)
        #expect(!beat.storyText.isEmpty)
    }

    @Test func continueTurnIncrementsTurnCount() async throws {
        let mock = MockStoryService()
        let context = SceneContext(labels: [], sceneCategories: [], transcript: nil, childAge: 6)
        let profile = ChildProfile(name: "Child", age: 6, preferences: [])

        _ = try await mock.startStory(context: context, profile: profile)
        _ = try await mock.continueTurn(childAnswer: "A blue dragon!")
        _ = try await mock.continueTurn(childAnswer: "She flies!")

        #expect(await mock.continueCallCount == 2)
        #expect(await mock.currentTurnCount == 2)
    }

    @Test func endSessionResetsState() async throws {
        let mock = MockStoryService()
        let context = SceneContext(labels: [], sceneCategories: [], transcript: nil, childAge: 5)
        let profile = ChildProfile(name: "Kid", age: 5, preferences: [])

        _ = try await mock.startStory(context: context, profile: profile)
        await mock.endSession()

        #expect(await mock.isSessionActive == false)
        #expect(await mock.currentTurnCount == 0)
        #expect(await mock.endCallCount == 1)
    }

    @Test func throwsOnModelUnavailable() async {
        let mock = MockStoryService()
        await mock.setError(.modelUnavailable)
        let context = SceneContext(labels: [], sceneCategories: [], transcript: nil, childAge: 5)
        let profile = ChildProfile(name: "Test", age: 5, preferences: [])

        do {
            _ = try await mock.startStory(context: context, profile: profile)
            #expect(Bool(false), "Expected StoryError.modelUnavailable")
        } catch let error as StoryError {
            #expect(error == .modelUnavailable)
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test func throwsOnModelDownloading() async {
        let mock = MockStoryService()
        await mock.setError(.modelDownloading)
        let context = SceneContext(labels: [], sceneCategories: [], transcript: nil, childAge: 5)
        let profile = ChildProfile(name: "Test", age: 5, preferences: [])

        do {
            _ = try await mock.startStory(context: context, profile: profile)
            #expect(Bool(false), "Expected StoryError.modelDownloading")
        } catch let error as StoryError {
            #expect(error == .modelDownloading)
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test func throwsOnNoActiveSession() async {
        let mock = MockStoryService()
        await mock.setError(.noActiveSession)
        let context = SceneContext(labels: [], sceneCategories: [], transcript: nil, childAge: 5)
        let profile = ChildProfile(name: "Test", age: 5, preferences: [])

        do {
            _ = try await mock.startStory(context: context, profile: profile)
            #expect(Bool(false), "Expected StoryError.noActiveSession")
        } catch let error as StoryError {
            #expect(error == .noActiveSession)
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test func customBeatReturnedFromStart() async throws {
        let mock = MockStoryService()
        let customBeat = StoryBeat(
            storyText: "A custom test story.",
            question: "What happens next?",
            isEnding: true
        )
        await mock.setBeat(customBeat)
        let context = SceneContext(labels: ["toy"], sceneCategories: ["room"], transcript: nil, childAge: 4)
        let profile = ChildProfile(name: "Tester", age: 4, preferences: [])

        let result = try await mock.startStory(context: context, profile: profile)

        #expect(result.storyText == "A custom test story.")
        #expect(result.isEnding == true)
    }
}

// MARK: - StoryError equality tests

struct StoryErrorTests {

    @Test func modelUnavailableHasDescription() {
        let error = StoryError.modelUnavailable
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test func generationFailedIncludesDetail() {
        let error = StoryError.generationFailed("timeout")
        #expect(error.errorDescription?.contains("timeout") == true)
    }

    @Test func allCasesHaveDescriptions() {
        let cases: [StoryError] = [
            .noActiveSession,
            .modelUnavailable,
            .modelDownloading,
            .contextWindowExceeded,
            .guardrailViolation,
            .generationFailed("test")
        ]
        for error in cases {
            #expect(error.errorDescription != nil)
        }
    }
}

// MARK: - StoryMetricsStore tests

struct StoryMetricsStoreTests {

    @Test func recordAndRetrieve() async {
        let store = StoryMetricsStore()
        let event = StoryMetricsEvent(
            generationMode: "onDevice",
            timeToFirstTokenMs: 450,
            totalGenerationMs: 1200,
            turnCount: 1,
            guardrailViolations: 0,
            storyTextLength: 180,
            timestamp: Date().timeIntervalSince1970
        )

        await store.record(event)

        #expect(await store.eventCount() == 1)
        #expect(await store.averageGenerationMs() == 1200)
    }

    @Test func averageAcrossMultipleEvents() async {
        let store = StoryMetricsStore()
        await store.record(makeEvent(totalMs: 1000))
        await store.record(makeEvent(totalMs: 2000))
        await store.record(makeEvent(totalMs: 3000))

        let avg = await store.averageGenerationMs()
        #expect(avg == 2000)
    }

    @Test func csvExportContainsHeader() async {
        let store = StoryMetricsStore()
        await store.record(makeEvent(totalMs: 500))

        let csv = await store.exportCSV()

        #expect(csv.hasPrefix("generationMode,"))
        #expect(csv.contains("timeToFirstTokenMs"))
        #expect(csv.contains("onDevice"))
    }

    @Test func emptyStoreReturnsZeros() async {
        let store = StoryMetricsStore()

        #expect(await store.eventCount() == 0)
        #expect(await store.averageGenerationMs() == 0)
        #expect(await store.averageStoryLength() == 0)
        #expect(await store.totalGuardrailViolations() == 0)
    }

    @Test func guardrailViolationsSummed() async {
        let store = StoryMetricsStore()
        await store.record(makeEvent(violations: 1))
        await store.record(makeEvent(violations: 2))

        #expect(await store.totalGuardrailViolations() == 3)
    }

    // MARK: - Helper

    private func makeEvent(
        totalMs: Double = 1000,
        violations: Int = 0
    ) -> StoryMetricsEvent {
        StoryMetricsEvent(
            generationMode: "onDevice",
            timeToFirstTokenMs: totalMs * 0.3,
            totalGenerationMs: totalMs,
            turnCount: 1,
            guardrailViolations: violations,
            storyTextLength: 150,
            timestamp: Date().timeIntervalSince1970
        )
    }
}

// MARK: - StoryMetricsEvent tests

struct StoryMetricsEventTests {

    @Test func codableRoundTrip() throws {
        let event = StoryMetricsEvent(
            generationMode: "onDevice",
            timeToFirstTokenMs: 300,
            totalGenerationMs: 1500,
            turnCount: 3,
            guardrailViolations: 1,
            storyTextLength: 200,
            timestamp: Date().timeIntervalSince1970
        )

        let data = try JSONEncoder().encode(event)
        let decoded = try JSONDecoder().decode(StoryMetricsEvent.self, from: data)

        #expect(decoded.generationMode == "onDevice")
        #expect(decoded.timeToFirstTokenMs == 300)
        #expect(decoded.totalGenerationMs == 1500)
        #expect(decoded.turnCount == 3)
        #expect(decoded.guardrailViolations == 1)
        #expect(decoded.storyTextLength == 200)
    }
}

// MARK: - Three-Architecture Benchmark Tests
//
// Validates the StoryMetricsStore CSV structure that Chapter 6 comparative
// evaluation relies on. Each architecture writes events with a distinct
// generationMode label — the CSV is consumed by the dissertation's
// Friedman test and latency comparison table.

struct ThreeArchitectureBenchmarkTests {

    private let modes = ["onDevice", "gemma4OnDevice", "cloud"]

    /// All three mode labels survive a CSV round-trip.
    @Test func allThreeModeLabelsAppearInCSV() async throws {
        let store = StoryMetricsStore()

        for mode in modes {
            await store.record(StoryMetricsEvent(
                generationMode: mode,
                timeToFirstTokenMs: 300,
                totalGenerationMs: 1200,
                turnCount: 3,
                guardrailViolations: 0,
                storyTextLength: 160,
                timestamp: Date().timeIntervalSince1970
            ))
        }

        let csv = await store.exportCSV()
        for mode in modes {
            #expect(csv.contains(mode), "CSV missing mode: \(mode)")
        }
    }

    /// Each mode's event count is tracked separately via eventCount.
    @Test func eventCountCoversAllThreeModes() async {
        let store = StoryMetricsStore()

        for mode in modes {
            for _ in 1...3 {
                await store.record(StoryMetricsEvent(
                    generationMode: mode,
                    timeToFirstTokenMs: 200,
                    totalGenerationMs: 1000,
                    turnCount: 2,
                    guardrailViolations: 0,
                    storyTextLength: 140,
                    timestamp: Date().timeIntervalSince1970
                ))
            }
        }

        // 3 modes × 3 events = 9 total
        #expect(await store.eventCount() == 9)
    }

    /// Average generation time is positive after recording events from all modes.
    @Test func averageGenerationMsPositiveAcrossAllModes() async {
        let store = StoryMetricsStore()

        for (index, mode) in modes.enumerated() {
            await store.record(StoryMetricsEvent(
                generationMode: mode,
                timeToFirstTokenMs: Double(index + 1) * 100,
                totalGenerationMs: Double(index + 1) * 500,
                turnCount: 3,
                guardrailViolations: 0,
                storyTextLength: 150,
                timestamp: Date().timeIntervalSince1970
            ))
        }

        let avg = await store.averageGenerationMs()
        #expect(avg > 0)
    }

    /// CSV header contains all fields needed for dissertation analysis.
    @Test func csvHeaderContainsDissertationFields() async {
        let store = StoryMetricsStore()
        await store.record(StoryMetricsEvent(
            generationMode: "onDevice",
            timeToFirstTokenMs: 400,
            totalGenerationMs: 1100,
            turnCount: 4,
            guardrailViolations: 0,
            storyTextLength: 180,
            timestamp: Date().timeIntervalSince1970
        ))

        let csv = await store.exportCSV()
        let requiredFields = ["generationMode", "timeToFirstTokenMs", "totalGenerationMs", "turnCount"]
        for field in requiredFields {
            #expect(csv.contains(field), "CSV missing required dissertation field: \(field)")
        }
    }

    /// Guardrail violations sum is zero across all modes for a clean session.
    @Test func zeroGuardrailViolationsAcrossAllModes() async {
        let store = StoryMetricsStore()

        for mode in modes {
            await store.record(StoryMetricsEvent(
                generationMode: mode,
                timeToFirstTokenMs: 300,
                totalGenerationMs: 1200,
                turnCount: 3,
                guardrailViolations: 0,
                storyTextLength: 160,
                timestamp: Date().timeIntervalSince1970
            ))
        }

        #expect(await store.totalGuardrailViolations() == 0)
    }
}

// MARK: - MockStoryService helpers

extension MockStoryService {
    func setError(_ error: StoryError?) {
        shouldThrow = error
    }

    func setBeat(_ beat: StoryBeat) {
        beatToReturn = beat
    }
}
