// PrivacyPipelineIntegrationTests.swift
// SeeSaw — End-to-end integration tests for the six-stage privacy pipeline.
//
// These tests call PrivacyPipelineService.process() with a synthetic JPEG
// produced entirely in-process (no file I/O, no network, no speech auth).
// They directly prove the dissertation's core privacy invariant:
//   rawDataTransmitted == false, always, across all pipeline outcomes.
//
// audioData is passed as nil throughout — PrivacyPipelineService.recognizeSpeech
// returns nil immediately when audioData is nil (no SFSpeechRecognizer invoked).

import Testing
import CoreImage
import Foundation

@testable import SeeSaw

// MARK: - Helpers

private func makeSyntheticJPEG(
    width: Int = 64,
    height: Int = 64,
    color: CIColor = CIColor(red: 0.5, green: 0.7, blue: 0.4)
) -> Data? {
    let image = CIImage(color: color).cropped(to: CGRect(x: 0, y: 0, width: width, height: height))
    let context = CIContext()
    return context.jpegRepresentation(of: image, colorSpace: CGColorSpaceCreateDeviceRGB())
}

private func makePipeline() -> PrivacyPipelineService {
    PrivacyPipelineService(speechService: SpeechRecognitionService())
}

// MARK: - Privacy invariant tests

struct PrivacyPipelineInvariantTests {

    /// Core dissertation claim: rawDataTransmitted is always false.
    @Test func rawDataTransmittedAlwaysFalse() async throws {
        guard let jpeg = makeSyntheticJPEG() else {
            throw TestingError("Failed to create synthetic JPEG")
        }
        let pipeline = makePipeline()
        let result = try await pipeline.process(jpegData: jpeg, childAge: 5, audioData: nil)
        #expect(result.metrics.rawDataTransmitted == false)
    }

    /// 20-run invariant — mirrors the 100-run invariant in PrivacyMetricsInvariantTests
    /// but exercises the full pipeline code path, not just the metrics struct.
    @Test func rawDataTransmittedNeverTrueAcross20Runs() async throws {
        guard let jpeg = makeSyntheticJPEG() else {
            throw TestingError("Failed to create synthetic JPEG")
        }
        let pipeline = makePipeline()
        for run in 1...20 {
            let result = try await pipeline.process(
                jpegData: jpeg,
                childAge: (run % 6) + 3,     // vary age 3–8
                childName: "Child\(run)",
                audioData: nil
            )
            #expect(result.metrics.rawDataTransmitted == false,
                    "Invariant broken on run \(run)")
        }
    }
}

// MARK: - Payload safety tests

struct PrivacyPipelinePayloadSafetyTests {

    /// ScenePayload must contain only label strings — no binary/base64 pixel data.
    @Test func payloadObjectsAreLabelsNotBase64() async throws {
        guard let jpeg = makeSyntheticJPEG() else {
            throw TestingError("Failed to create synthetic JPEG")
        }
        let pipeline = makePipeline()
        let result = try await pipeline.process(jpegData: jpeg, childAge: 5, audioData: nil)

        for label in result.payload.objects {
            // Base64 strings are long and lack spaces; YOLO labels are short ASCII words
            #expect(label.count < 64, "Object label looks like binary data: \(label.prefix(32))")
            #expect(!label.contains("/"), "Object label contains '/' — looks like base64: \(label.prefix(32))")
            #expect(!label.contains("+"), "Object label contains '+' — looks like base64: \(label.prefix(32))")
        }
    }

    /// ScenePayload scene labels must be short human-readable strings.
    @Test func payloadSceneLabelsAreReadable() async throws {
        guard let jpeg = makeSyntheticJPEG() else {
            throw TestingError("Failed to create synthetic JPEG")
        }
        let pipeline = makePipeline()
        let result = try await pipeline.process(jpegData: jpeg, childAge: 5, audioData: nil)

        for label in result.payload.scene {
            #expect(label.count < 64, "Scene label too long — possible encoding issue: \(label.prefix(32))")
        }
    }

    /// When transcript is nil (no audio), payload.transcript must be nil.
    @Test func nilAudioProducesNilTranscript() async throws {
        guard let jpeg = makeSyntheticJPEG() else {
            throw TestingError("Failed to create synthetic JPEG")
        }
        let pipeline = makePipeline()
        let result = try await pipeline.process(jpegData: jpeg, childAge: 4, audioData: nil)
        #expect(result.payload.transcript == nil)
    }

    /// childAge is passed through the pipeline unchanged.
    @Test func childAgePassedThroughIntact() async throws {
        guard let jpeg = makeSyntheticJPEG() else {
            throw TestingError("Failed to create synthetic JPEG")
        }
        let pipeline = makePipeline()
        let result = try await pipeline.process(jpegData: jpeg, childAge: 7, childName: "Test", audioData: nil)
        #expect(result.payload.childAge == 7)
    }

    /// childName is passed through the pipeline unchanged.
    @Test func childNamePassedThroughIntact() async throws {
        guard let jpeg = makeSyntheticJPEG() else {
            throw TestingError("Failed to create synthetic JPEG")
        }
        let pipeline = makePipeline()
        let result = try await pipeline.process(
            jpegData: jpeg, childAge: 5, childName: "Aria", audioData: nil
        )
        #expect(result.payload.childName == "Aria")
    }
}

// MARK: - Metrics non-negativity tests

struct PrivacyPipelineMetricsTests {

    /// All stage latencies must be non-negative.
    @Test func allLatenciesAreNonNegative() async throws {
        guard let jpeg = makeSyntheticJPEG() else {
            throw TestingError("Failed to create synthetic JPEG")
        }
        let pipeline = makePipeline()
        let result = try await pipeline.process(jpegData: jpeg, childAge: 5, audioData: nil)
        let m = result.metrics

        #expect(m.pipelineLatencyMs >= 0)
        #expect(m.faceDetectMs >= 0)
        #expect(m.blurMs >= 0)
        #expect(m.yoloMs >= 0)
        #expect(m.sceneClassifyMs >= 0)
        #expect(m.sttMs >= 0)
        #expect(m.piiScrubMs >= 0)
    }

    /// Total pipeline latency must be positive (pipeline actually ran).
    @Test func pipelineLatencyIsPositive() async throws {
        guard let jpeg = makeSyntheticJPEG() else {
            throw TestingError("Failed to create synthetic JPEG")
        }
        let pipeline = makePipeline()
        let result = try await pipeline.process(jpegData: jpeg, childAge: 5, audioData: nil)
        #expect(result.metrics.pipelineLatencyMs > 0)
    }

    /// tokensScrubbedFromTranscript must be zero when no audio is provided.
    @Test func noTokensScrubbedWithoutAudio() async throws {
        guard let jpeg = makeSyntheticJPEG() else {
            throw TestingError("Failed to create synthetic JPEG")
        }
        let pipeline = makePipeline()
        let result = try await pipeline.process(jpegData: jpeg, childAge: 5, audioData: nil)
        #expect(result.metrics.tokensScrubbedFromTranscript == 0)
    }

    /// facesDetected and facesBlurred must always be equal (every detected face is blurred).
    @Test func facesDetectedEqualsBlurred() async throws {
        guard let jpeg = makeSyntheticJPEG() else {
            throw TestingError("Failed to create synthetic JPEG")
        }
        let pipeline = makePipeline()
        let result = try await pipeline.process(jpegData: jpeg, childAge: 5, audioData: nil)
        #expect(result.metrics.facesDetected == result.metrics.facesBlurred)
    }
}

// MARK: - Error handling tests

struct PrivacyPipelineErrorTests {

    /// Empty Data must throw PipelineError.invalidImageData.
    @Test func emptyDataThrowsInvalidImageData() async {
        let pipeline = makePipeline()
        do {
            _ = try await pipeline.process(jpegData: Data(), childAge: 5, audioData: nil)
            #expect(Bool(false), "Expected PipelineError.invalidImageData")
        } catch PipelineError.invalidImageData {
            // correct
        } catch {
            #expect(Bool(false), "Unexpected error: \(error)")
        }
    }

    /// Random bytes (not a JPEG) must throw PipelineError.invalidImageData.
    @Test func randomBytesThrowsInvalidImageData() async {
        let pipeline = makePipeline()
        let garbage = Data(repeating: 0xFF, count: 128)
        do {
            _ = try await pipeline.process(jpegData: garbage, childAge: 5, audioData: nil)
            #expect(Bool(false), "Expected PipelineError.invalidImageData")
        } catch PipelineError.invalidImageData {
            // correct
        } catch {
            #expect(Bool(false), "Unexpected error: \(error)")
        }
    }
}

// MARK: - PipelineResult struct tests

struct PipelineResultStructTests {

    @Test func pipelineResultExposesBothPayloadAndMetrics() async throws {
        guard let jpeg = makeSyntheticJPEG() else {
            throw TestingError("Failed to create synthetic JPEG")
        }
        let pipeline = makePipeline()
        let result = try await pipeline.process(jpegData: jpeg, childAge: 6, audioData: nil)

        // Payload is accessible
        _ = result.payload.objects
        _ = result.payload.scene
        _ = result.payload.childAge

        // Metrics are accessible
        _ = result.metrics.rawDataTransmitted
        _ = result.metrics.pipelineLatencyMs
    }
}

// MARK: - TestingError helper

private struct TestingError: Error, CustomStringConvertible {
    let description: String
    init(_ message: String) { description = message }
}
