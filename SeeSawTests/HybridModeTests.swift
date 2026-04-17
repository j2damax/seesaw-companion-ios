// HybridModeTests.swift
// SeeSawTests
//
// 13 tests for hybrid mode: BackgroundStoryEnhancer racing, HybridBeatMetric
// Codable, and HybridMetricsStore analytics. Uses a MockCloudEnhancing actor
// — no network required.

import Foundation
import Testing
@testable import SeeSaw

// MARK: - Mock cloud service

actor MockCloudEnhancing: CloudEnhancing {
    // nonisolated(unsafe) lets tests configure the mock synchronously
    // before async operations begin — safe because tests set these before
    // any concurrent access starts.
    nonisolated(unsafe) var delay: Duration = .zero
    nonisolated(unsafe) var beatToReturn: StoryBeat = StoryBeat(
        storyText: "The mock cloud returned a story.",
        question: "What happens next?",
        isEnding: false
    )
    nonisolated(unsafe) var shouldFail = false
    private(set) var requestCount = 0
    private(set) var receivedHistories: [[StoryTurn]] = []

    func requestEnhancement(
        payload: ScenePayload,
        baseBeat: StoryBeat,
        childAnswer: String?,
        storyHistory: [StoryTurn],
        turnNumber: Int
    ) async throws -> StoryBeat {
        requestCount += 1
        receivedHistories.append(storyHistory)
        if delay > .zero {
            try await Task.sleep(for: delay)
        }
        if shouldFail { throw CloudError.notConfigured }
        return beatToReturn
    }
}

// MARK: - Shared fixtures

private let samplePayload = ScenePayload(
    objects: ["teddy_bear", "book"],
    scene: ["bedroom"],
    transcript: nil,
    childAge: 5,
    childName: "Alex",
    sessionId: "test-session",
    storyHistory: []
)

private let sampleBeat = StoryBeat(
    storyText: "Once upon a time there was a brave explorer.",
    question: "What do you think they found?",
    isEnding: false
)

private func makeMetric(source: HybridSource) -> HybridBeatMetric {
    HybridBeatMetric(
        turnNumber: 0,
        source: source,
        localGenerationMs: 500,
        cloudResponseMs: source == .cloud ? 800 : nil,
        cloudArrivedInTime: source == .cloud,
        endingDetectedBy: nil,
        timestamp: 0
    )
}

// MARK: - Test suites

@Suite("Hybrid Mode", .serialized)
struct HybridModeTests {

    // MARK: BackgroundStoryEnhancer

    @Suite("BackgroundStoryEnhancer")
    struct BackgroundStoryEnhancerTests {

        @Test func consumeEnhancedBeatReturnsNilWhenNoPendingTask() async {
            let mock = MockCloudEnhancing()
            let enhancer = BackgroundStoryEnhancer(cloudService: mock)
            // No requestEnhancement call — should return nil immediately
            let result = await enhancer.consumeEnhancedBeat(deadline: .milliseconds(100))
            #expect(result == nil)
        }

        @Test func consumeEnhancedBeatReturnsCloudBeatWhenFast() async {
            let mock = MockCloudEnhancing()
            // No delay — cloud responds before deadline
            let enhancer = BackgroundStoryEnhancer(cloudService: mock)
            await enhancer.requestEnhancement(
                payload: samplePayload,
                baseBeat: sampleBeat,
                childAnswer: nil,
                turnNumber: 0
            )
            // Give the unstructured task a moment to fire and set cachedResult
            try? await Task.sleep(for: .milliseconds(200))
            let result = await enhancer.consumeEnhancedBeat(deadline: .seconds(1))
            #expect(result != nil)
            if let (beat, ms) = result {
                let expectedText = mock.beatToReturn.storyText  // read before #expect closure
                #expect(beat.storyText == expectedText)
                #expect(ms >= 0)
            }
        }

        @Test func consumeEnhancedBeatReturnsNilWhenCloudExceedsDeadline() async {
            let mock = MockCloudEnhancing()
            mock.delay = .seconds(2)  // cloud takes 2s
            let enhancer = BackgroundStoryEnhancer(cloudService: mock)
            await enhancer.requestEnhancement(
                payload: samplePayload,
                baseBeat: sampleBeat,
                childAnswer: nil,
                turnNumber: 0
            )
            // 100ms deadline — cloud cannot respond in time
            let start = ContinuousClock.now
            let result = await enhancer.consumeEnhancedBeat(deadline: .milliseconds(100))
            let elapsed = ContinuousClock.now - start
            #expect(result == nil)
            // Should return within ~200ms (deadline + one poll interval)
            #expect(elapsed < .milliseconds(500))
        }

        @Test func resetCancelsPendingTask() async {
            let mock = MockCloudEnhancing()
            mock.delay = .seconds(10)  // very slow cloud
            let enhancer = BackgroundStoryEnhancer(cloudService: mock)
            await enhancer.requestEnhancement(
                payload: samplePayload,
                baseBeat: sampleBeat,
                childAnswer: nil,
                turnNumber: 0
            )
            // Reset should cancel the pending task
            await enhancer.reset()
            // After reset, consumeEnhancedBeat should return nil immediately
            let result = await enhancer.consumeEnhancedBeat(deadline: .milliseconds(50))
            #expect(result == nil)
        }

        @Test func storyHistoryAccumulatesAcrossEnhancementRequests() async {
            let mock = MockCloudEnhancing()
            mock.delay = .milliseconds(10)
            let enhancer = BackgroundStoryEnhancer(cloudService: mock)

            // Turn 0: no child answer
            await enhancer.requestEnhancement(
                payload: samplePayload,
                baseBeat: sampleBeat,
                childAnswer: nil,
                turnNumber: 0
            )
            try? await Task.sleep(for: .milliseconds(100))
            _ = await enhancer.consumeEnhancedBeat(deadline: .milliseconds(200))

            // Turn 1: with child answer
            let beat2 = StoryBeat(storyText: "Turn 1 beat.", question: "And then?", isEnding: false)
            await enhancer.requestEnhancement(
                payload: samplePayload,
                baseBeat: beat2,
                childAnswer: "I found a dragon!",
                turnNumber: 1
            )
            try? await Task.sleep(for: .milliseconds(100))
            _ = await enhancer.consumeEnhancedBeat(deadline: .milliseconds(200))

            let histories = await mock.receivedHistories
            // Turn 0 request: history has 1 entry (model beat from turn 0)
            #expect(histories.count >= 1)
            // Turn 1 request: history should have grown (model + user answer from turn 0, plus model from turn 1)
            if histories.count >= 2 {
                #expect(histories[1].count > histories[0].count)
            }
        }
    }

    // MARK: HybridBeatMetric

    @Suite("HybridBeatMetric")
    struct HybridBeatMetricTests {

        @Test func codableRoundTrip() throws {
            let metric = HybridBeatMetric(
                turnNumber: 2,
                source: .cloud,
                localGenerationMs: 45.5,
                cloudResponseMs: 820.3,
                cloudArrivedInTime: true,
                endingDetectedBy: .cloudLLM,
                timestamp: 1_700_000_000.0
            )
            let data = try JSONEncoder().encode(metric)
            let decoded = try JSONDecoder().decode(HybridBeatMetric.self, from: data)
            #expect(decoded.turnNumber == metric.turnNumber)
            #expect(decoded.source == metric.source)
            #expect(decoded.localGenerationMs == metric.localGenerationMs)
            #expect(decoded.cloudResponseMs == metric.cloudResponseMs)
            #expect(decoded.cloudArrivedInTime == metric.cloudArrivedInTime)
            #expect(decoded.endingDetectedBy == metric.endingDetectedBy)
            #expect(decoded.timestamp == metric.timestamp)
        }

        @Test func hybridSourceRawValues() {
            #expect(HybridSource.cloud.rawValue == "cloud")
            #expect(HybridSource.localGemma4.rawValue == "localGemma4")
            #expect(HybridSource.localOnDevice.rawValue == "localOnDevice")
        }

        @Test func endingSourceRawValues() {
            #expect(EndingSource.localHeuristic.rawValue == "localHeuristic")
            #expect(EndingSource.cloudLLM.rawValue == "cloudLLM")
            #expect(EndingSource.turnCap.rawValue == "turnCap")
        }
    }

    // MARK: HybridMetricsStore

    @Suite("HybridMetricsStore")
    struct HybridMetricsStoreTests {

        @Test func cloudHitRateZeroWhenAllLocal() async {
            let store = HybridMetricsStore()
            await store.record(makeMetric(source: .localGemma4))
            await store.record(makeMetric(source: .localOnDevice))
            let rate = await store.cloudHitRate()
            #expect(rate == 0.0)
        }

        @Test func cloudHitRateOneWhenAllCloud() async {
            let store = HybridMetricsStore()
            await store.record(makeMetric(source: .cloud))
            await store.record(makeMetric(source: .cloud))
            let rate = await store.cloudHitRate()
            #expect(rate == 1.0)
        }

        @Test func cloudHitRateFractionMixed() async {
            let store = HybridMetricsStore()
            await store.record(makeMetric(source: .cloud))      // 1
            await store.record(makeMetric(source: .localGemma4)) // 2
            await store.record(makeMetric(source: .cloud))      // 3
            await store.record(makeMetric(source: .localGemma4)) // 4
            let rate = await store.cloudHitRate()
            #expect(abs(rate - 0.5) < 0.001)
        }

        @Test func csvExportContainsCorrectHeader() async {
            let store = HybridMetricsStore()
            let csv = await store.exportCSV()
            let firstLine = csv.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? ""
            #expect(firstLine == "turn,source,local_ms,cloud_ms,cloud_arrived,ending_by,timestamp")
        }

        @Test func exportCSVRowCountMatchesRecordCount() async {
            let store = HybridMetricsStore()
            await store.record(makeMetric(source: .cloud))
            await store.record(makeMetric(source: .localGemma4))
            await store.record(makeMetric(source: .localOnDevice))
            let csv = await store.exportCSV()
            let lines = csv.split(separator: "\n")
            // 1 header + 3 data rows
            #expect(lines.count == 4)
        }
    }
}
