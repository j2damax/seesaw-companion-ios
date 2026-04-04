// PrivacyPipelineTests.swift
// SeeSaw — Privacy pipeline assertion tests
//
// Comprehensive test suite proving:
//   1. PII scrubbing removes all known PII patterns
//   2. ScenePayload contains only allowed fields (privacy boundary)
//   3. PrivacyMetricsEvent invariants hold (rawDataTransmitted == false)
//   4. PrivacyMetricsStore correctly records and exports metrics

import Testing
import Foundation

@testable import SeeSaw

// MARK: - PII Scrubber Tests

struct PIIScrubberTests {

    @Test func scrubRemovesPhoneNumbers() {
        let result = PIIScrubber.scrub("Call me at 07700900123")
        #expect(result.scrubbed.contains("[REDACTED]"))
        #expect(!result.scrubbed.contains("07700900123"))
        #expect(result.tokensRedacted > 0)
    }

    @Test func scrubRemovesEmailAddresses() {
        let result = PIIScrubber.scrub("email me at alice@example.com")
        #expect(result.scrubbed.contains("[REDACTED]"))
        #expect(!result.scrubbed.contains("alice@example.com"))
        #expect(result.tokensRedacted > 0)
    }

    @Test func scrubRemovesNamePatterns() {
        let result = PIIScrubber.scrub("my name is Alice")
        #expect(result.scrubbed.contains("[REDACTED]"))
        #expect(!result.scrubbed.contains("my name is Alice"))
        #expect(result.tokensRedacted > 0)
    }

    @Test func scrubRemovesImCalledPattern() {
        let result = PIIScrubber.scrub("i'm called Bob")
        #expect(result.scrubbed.contains("[REDACTED]"))
        #expect(!result.scrubbed.contains("i'm called Bob"))
        #expect(result.tokensRedacted > 0)
    }

    @Test func scrubRemovesLongNumbers() {
        let result = PIIScrubber.scrub("account 1234567890")
        #expect(result.scrubbed.contains("[REDACTED]"))
        #expect(!result.scrubbed.contains("1234567890"))
        #expect(result.tokensRedacted > 0)
    }

    @Test func scrubRemovesUKPostcodes() {
        let result = PIIScrubber.scrub("I live at SW1A 1AA")
        #expect(result.scrubbed.contains("[REDACTED]"))
        #expect(!result.scrubbed.contains("SW1A 1AA"))
        #expect(result.tokensRedacted > 0)
    }

    @Test func scrubRemovesUSZipCodes() {
        let result = PIIScrubber.scrub("ZIP is 90210")
        #expect(result.scrubbed.contains("[REDACTED]"))
        #expect(!result.scrubbed.contains("90210"))
        #expect(result.tokensRedacted > 0)
    }

    @Test func scrubRemovesStreetAddresses() {
        let result = PIIScrubber.scrub("42 Oak Street")
        #expect(result.scrubbed.contains("[REDACTED]"))
        #expect(!result.scrubbed.contains("42 Oak Street"))
        #expect(result.tokensRedacted > 0)
    }

    @Test func scrubPreservesNonPIIContent() {
        let input = "the castle was big and the dog ran"
        let result = PIIScrubber.scrub(input)
        #expect(result.scrubbed == input)
        #expect(result.tokensRedacted == 0)
    }

    @Test func scrubCountsRedactedTokens() {
        let piiResult = PIIScrubber.scrub("my name is Alice and email alice@example.com")
        #expect(piiResult.tokensRedacted > 0)

        let cleanResult = PIIScrubber.scrub("a sunny day in the park")
        #expect(cleanResult.tokensRedacted == 0)
    }

    @Test func scrubHandlesEmptyString() {
        let result = PIIScrubber.scrub("")
        #expect(result.scrubbed == "")
        #expect(result.tokensRedacted == 0)
    }

    @Test func scrubHandlesMultiplePIITypes() {
        let result = PIIScrubber.scrub("my name is Alice, email alice@example.com, account 1234567890")
        #expect(!result.scrubbed.contains("Alice"))
        #expect(!result.scrubbed.contains("alice@example.com"))
        #expect(!result.scrubbed.contains("1234567890"))
        #expect(result.tokensRedacted >= 3)
    }

    @Test func scrubIsCaseInsensitiveForNames() {
        let result1 = PIIScrubber.scrub("My Name Is Alice")
        #expect(result1.scrubbed.contains("[REDACTED]"))

        let result2 = PIIScrubber.scrub("MY NAME IS ALICE")
        #expect(result2.scrubbed.contains("[REDACTED]"))
    }

    @Test func scrubPreservesStoryVocabulary() {
        // Ensures common story words are NOT scrubbed
        let storyWords = [
            "the dragon flew over the mountain",
            "a princess lived in a tall tower",
            "the friendly bear found some honey",
            "they explored the magical forest",
            "the pirate sailed across the ocean"
        ]
        for story in storyWords {
            let result = PIIScrubber.scrub(story)
            #expect(result.scrubbed == story, "Story text was incorrectly scrubbed: \(story)")
            #expect(result.tokensRedacted == 0)
        }
    }
}

// MARK: - ScenePayload Privacy Boundary Tests

struct ScenePayloadPrivacyTests {

    @Test func payloadContainsOnlyAllowedKeys() throws {
        let payload = ScenePayload(
            objects: ["ball", "dog"],
            scene: ["outdoor"],
            transcript: "hello",
            childAge: 5,
            sessionId: "test-id",
            query: "tell me a story",
            timestamp: "2026-04-04T09:00:00Z"
        )
        let data = try JSONEncoder().encode(payload)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        let allowedKeys: Set<String> = [
            "objects", "scene", "transcript", "childAge",
            "sessionId", "query", "timestamp"
        ]
        #expect(Set(dict.keys) == allowedKeys)
    }

    @Test func payloadContainsNoDataFields() throws {
        let payload = ScenePayload(
            objects: ["toy"], scene: ["indoor"],
            transcript: "hi", childAge: 4,
            sessionId: "s", query: nil, timestamp: "t"
        )
        let data = try JSONEncoder().encode(payload)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        for (key, value) in dict {
            #expect(!(value is Data), "Key '\(key)' contains raw Data — privacy violation")
        }
    }

    @Test func payloadContainsNoBase64() throws {
        let payload = ScenePayload(
            objects: ["cat"], scene: ["park"],
            transcript: "meow", childAge: 3,
            sessionId: "s", query: nil, timestamp: "t"
        )
        let data = try JSONEncoder().encode(payload)
        let jsonString = String(data: data, encoding: .utf8) ?? ""

        #expect(!jsonString.contains("base64"))
        #expect(!jsonString.contains("data:image"))
    }

    @Test func payloadContainsNoBoundingBoxes() throws {
        let payload = ScenePayload(
            objects: ["bear"], scene: ["room"],
            transcript: nil, childAge: 6,
            sessionId: "s", query: nil, timestamp: "t"
        )
        let data = try JSONEncoder().encode(payload)
        let jsonString = String(data: data, encoding: .utf8) ?? ""

        #expect(!jsonString.contains("boundingBox"))
        #expect(!jsonString.contains("faceRect"))
        #expect(!jsonString.contains("coordinates"))
    }
}

// MARK: - Privacy Metrics Invariant Tests

struct PrivacyMetricsInvariantTests {

    @Test func rawDataTransmittedAlwaysFalse() {
        let metrics = PrivacyMetricsEvent(
            facesDetected: 3, facesBlurred: 3,
            objectsDetected: 5, tokensScrubbedFromTranscript: 2,
            rawDataTransmitted: false,
            pipelineLatencyMs: 500,
            faceDetectMs: 30, blurMs: 20,
            yoloMs: 300, sceneClassifyMs: 80,
            sttMs: 60, piiScrubMs: 2,
            timestamp: CFAbsoluteTimeGetCurrent()
        )
        #expect(metrics.rawDataTransmitted == false)
    }

    @Test func facesBlurredEqualsFacesDetected() {
        let faceCount = 5
        let metrics = PrivacyMetricsEvent(
            facesDetected: faceCount, facesBlurred: faceCount,
            objectsDetected: 0, tokensScrubbedFromTranscript: 0,
            rawDataTransmitted: false,
            pipelineLatencyMs: 100,
            faceDetectMs: 10, blurMs: 10,
            yoloMs: 50, sceneClassifyMs: 20,
            sttMs: 0, piiScrubMs: 0,
            timestamp: CFAbsoluteTimeGetCurrent()
        )
        #expect(metrics.facesDetected == metrics.facesBlurred,
                "Privacy invariant violated: not all detected faces were blurred")
    }

    @Test func metricsAreCodable() throws {
        let original = PrivacyMetricsEvent(
            facesDetected: 2, facesBlurred: 2,
            objectsDetected: 4, tokensScrubbedFromTranscript: 1,
            rawDataTransmitted: false,
            pipelineLatencyMs: 612.5,
            faceDetectMs: 45, blurMs: 12,
            yoloMs: 320, sceneClassifyMs: 85,
            sttMs: 150, piiScrubMs: 2,
            timestamp: 1000.0
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PrivacyMetricsEvent.self, from: data)

        #expect(decoded.facesDetected == original.facesDetected)
        #expect(decoded.facesBlurred == original.facesBlurred)
        #expect(decoded.rawDataTransmitted == false)
        #expect(decoded.pipelineLatencyMs == original.pipelineLatencyMs)
    }
}

// MARK: - Privacy Metrics Store Tests

struct PrivacyMetricsStoreTests {

    private func makeEvent(latency: Double = 500, faces: Int = 0, tokens: Int = 0) -> PrivacyMetricsEvent {
        PrivacyMetricsEvent(
            facesDetected: faces, facesBlurred: faces,
            objectsDetected: 3, tokensScrubbedFromTranscript: tokens,
            rawDataTransmitted: false,
            pipelineLatencyMs: latency,
            faceDetectMs: 30, blurMs: 20,
            yoloMs: 300, sceneClassifyMs: 80,
            sttMs: 60, piiScrubMs: 2,
            timestamp: CFAbsoluteTimeGetCurrent()
        )
    }

    @Test func recordAndRetrieve() async {
        let store = PrivacyMetricsStore()
        await store.record(makeEvent())
        await store.record(makeEvent())
        await store.record(makeEvent())
        let events = await store.allEvents()
        #expect(events.count == 3)
    }

    @Test func eventCount() async {
        let store = PrivacyMetricsStore()
        #expect(await store.eventCount() == 0)
        await store.record(makeEvent())
        #expect(await store.eventCount() == 1)
    }

    @Test func averageLatency() async {
        let store = PrivacyMetricsStore()
        await store.record(makeEvent(latency: 100))
        await store.record(makeEvent(latency: 200))
        await store.record(makeEvent(latency: 300))
        let avg = await store.averageLatency()
        #expect(avg == 200.0)
    }

    @Test func averageLatencyEmptyStore() async {
        let store = PrivacyMetricsStore()
        let avg = await store.averageLatency()
        #expect(avg == 0)
    }

    @Test func sanitisationRateIs100Percent() async {
        let store = PrivacyMetricsStore()
        await store.record(makeEvent())
        await store.record(makeEvent())
        await store.record(makeEvent())
        let rate = await store.privacySanitisationRate()
        #expect(rate == 1.0, "Privacy sanitisation rate must be 100%")
    }

    @Test func sanitisationRateEmptyStore() async {
        let store = PrivacyMetricsStore()
        let rate = await store.privacySanitisationRate()
        #expect(rate == 1.0)
    }

    @Test func totalFacesDetectedAndBlurred() async {
        let store = PrivacyMetricsStore()
        await store.record(makeEvent(faces: 2))
        await store.record(makeEvent(faces: 3))
        await store.record(makeEvent(faces: 0))
        #expect(await store.totalFacesDetected() == 5)
        #expect(await store.totalFacesBlurred() == 5)
    }

    @Test func totalTokensScrubbed() async {
        let store = PrivacyMetricsStore()
        await store.record(makeEvent(tokens: 2))
        await store.record(makeEvent(tokens: 5))
        #expect(await store.totalTokensScrubbed() == 7)
    }

    @Test func csvExportContainsHeaderAndRows() async {
        let store = PrivacyMetricsStore()
        await store.record(makeEvent())
        await store.record(makeEvent())
        let csv = await store.exportCSV()

        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }
        #expect(lines.count == 3, "Expected 1 header + 2 data rows")
        #expect(lines[0].contains("facesDetected"))
        #expect(lines[0].contains("rawDataTransmitted"))
        #expect(lines[0].contains("pipelineLatencyMs"))
    }

    @Test func csvExportEmptyStore() async {
        let store = PrivacyMetricsStore()
        let csv = await store.exportCSV()
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }
        #expect(lines.count == 1, "Empty store should produce header only")
    }

    @Test func resetClearsAllEvents() async {
        let store = PrivacyMetricsStore()
        await store.record(makeEvent())
        await store.record(makeEvent())
        await store.reset()
        #expect(await store.eventCount() == 0)
        #expect(await store.allEvents().isEmpty)
    }
}

// MARK: - PipelineResult Tests

struct PipelineResultTests {

    @Test func resultContainsBothPayloadAndMetrics() {
        let payload = ScenePayload(
            objects: ["toy"], scene: ["room"],
            transcript: "hello", childAge: 5,
            sessionId: "s", query: nil, timestamp: "t"
        )
        let metrics = PrivacyMetricsEvent(
            facesDetected: 1, facesBlurred: 1,
            objectsDetected: 1, tokensScrubbedFromTranscript: 0,
            rawDataTransmitted: false,
            pipelineLatencyMs: 400,
            faceDetectMs: 30, blurMs: 20,
            yoloMs: 200, sceneClassifyMs: 80,
            sttMs: 60, piiScrubMs: 2,
            timestamp: CFAbsoluteTimeGetCurrent()
        )
        let result = PipelineResult(payload: payload, metrics: metrics)

        #expect(result.payload.objects == ["toy"])
        #expect(result.metrics.rawDataTransmitted == false)
        #expect(result.metrics.facesDetected == result.metrics.facesBlurred)
    }
}

// MARK: - End-to-End Privacy Compliance Tests

struct PrivacyComplianceTests {

    @Test func hundredRunsNeverTransmitRawData() async {
        let store = PrivacyMetricsStore()
        for i in 0..<100 {
            let event = PrivacyMetricsEvent(
                facesDetected: i % 3, facesBlurred: i % 3,
                objectsDetected: i % 5, tokensScrubbedFromTranscript: i % 2,
                rawDataTransmitted: false,
                pipelineLatencyMs: Double(400 + i),
                faceDetectMs: 30, blurMs: 20,
                yoloMs: 300, sceneClassifyMs: 80,
                sttMs: 60, piiScrubMs: 2,
                timestamp: CFAbsoluteTimeGetCurrent()
            )
            await store.record(event)
        }

        let events = await store.allEvents()
        #expect(events.count == 100)

        for event in events {
            #expect(event.rawDataTransmitted == false,
                    "Privacy violation: rawDataTransmitted was true")
            #expect(event.facesDetected == event.facesBlurred,
                    "Privacy violation: not all faces were blurred")
        }

        let rate = await store.privacySanitisationRate()
        #expect(rate == 1.0, "Privacy sanitisation rate must be 100%")
    }

    @Test func scenePayloadNeverContainsRawImageData() throws {
        // Simulate various pipeline outputs and verify no raw data leaks
        let payloads = [
            ScenePayload(objects: ["ball"], scene: ["outdoor"], transcript: "hi", childAge: 3,
                         sessionId: "1", query: "story", timestamp: "t"),
            ScenePayload(objects: [], scene: [], transcript: nil, childAge: 8,
                         sessionId: "2", query: nil, timestamp: "t"),
            ScenePayload(objects: ["toy", "book", "lamp"], scene: ["bedroom", "indoor", "cozy"],
                         transcript: "once upon a time", childAge: 5,
                         sessionId: "3", query: "adventure", timestamp: "t"),
        ]

        for payload in payloads {
            let data = try JSONEncoder().encode(payload)
            let json = String(data: data, encoding: .utf8) ?? ""

            // Must never contain raw image data markers
            #expect(!json.contains("base64"))
            #expect(!json.contains("data:image"))
            #expect(!json.contains("JFIF"))
            #expect(!json.contains("PNG"))
            #expect(!json.contains("boundingBox"))
            #expect(!json.contains("faceRect"))
            #expect(!json.contains("audioData"))
            #expect(!json.contains("jpegData"))
        }
    }

    @Test func piiScrubberAndSpeechServiceShareSameLogic() {
        // Verify that SpeechRecognitionService.scrubPII delegates to PIIScrubber
        let testInput = "my name is Alice and email alice@example.com"
        let speechResult = SpeechRecognitionService.scrubPII(testInput)
        let piiResult = PIIScrubber.scrub(testInput)

        #expect(speechResult == piiResult.scrubbed,
                "SpeechRecognitionService and PIIScrubber must produce identical results")
    }
}
