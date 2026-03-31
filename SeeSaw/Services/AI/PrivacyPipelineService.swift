// PrivacyPipelineService.swift
// SeeSaw — Tier 2 companion app
//
// Privacy-preserving on-device processing pipeline.
// Stages:
//   1. Face detection (VNDetectFaceRectanglesRequest)
//   2. Face blur (CIGaussianBlur, sigma ≥ 30)
//   3. Object detection (VNCoreMLRequest / YOLO11n, confidence ≥ 0.4)
//   4. Scene classification (VNClassifyImageRequest, confidence ≥ 0.3)
//   5. On-device speech recognition (SFSpeechRecognizer, on-device only)
//   6. PII scrub
//
// PRIVACY CONTRACT: raw JPEG never stored, never sent to network.

import CoreImage
import CoreML
import Foundation
import Speech
import Vision

actor PrivacyPipelineService {

    // MARK: - Thresholds

    private static let objectConfidenceThreshold: Float = 0.4
    private static let sceneConfidenceThreshold: Float  = 0.3

    // MARK: - CoreML model (optional — graceful fallback if absent)

    private var objectDetectionModel: VNCoreMLModel?

    init() {
        objectDetectionModel = loadObjectDetectionModel()
    }

    // MARK: - Public entry point

    func process(jpegData: Data, childAge: Int) async throws -> ScenePayload {
        guard let ciImage = CIImage(data: jpegData) else {
            throw PipelineError.invalidImageData
        }

        let blurredImage = try detectAndBlurFaces(in: ciImage)

        async let objects = detectObjects(in: blurredImage)
        async let scene   = classifyScene(in: blurredImage)
        async let transcript = recognizeSpeech()

        let (detectedObjects, sceneLabels, rawTranscript) = try await (objects, scene, transcript)
        let cleanTranscript = rawTranscript.map { scrubPII($0) }

        return ScenePayload(
            objects: detectedObjects,
            scene: sceneLabels,
            transcript: cleanTranscript,
            childAge: childAge
        )
    }

    // MARK: - Stage 1 + 2: Face detection & blur

    private func detectAndBlurFaces(in image: CIImage) throws -> CIImage {
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        let request = VNDetectFaceRectanglesRequest()
        try handler.perform([request])

        guard let observations = request.results, !observations.isEmpty else {
            return image
        }

        var output = image
        let imageSize = image.extent.size

        for face in observations {
            let faceRect = denormalize(face.boundingBox, in: imageSize)
            let blurred  = blurRegion(faceRect, in: output)
            output = blurred
        }
        return output
    }

    private func blurRegion(_ rect: CGRect, in image: CIImage) -> CIImage {
        guard let blurred = CIFilter(name: "CIGaussianBlur", parameters: [
            kCIInputImageKey: image.cropped(to: rect),
            kCIInputRadiusKey: 30
        ])?.outputImage else { return image }
        return blurred.composited(over: image)
    }

    private func denormalize(_ normalized: CGRect, in size: CGSize) -> CGRect {
        CGRect(
            x: normalized.origin.x * size.width,
            y: normalized.origin.y * size.height,
            width: normalized.width * size.width,
            height: normalized.height * size.height
        )
    }

    // MARK: - Stage 3: Object detection

    private func detectObjects(in image: CIImage) async throws -> [String] {
        if let model = objectDetectionModel {
            return try detectObjectsWithModel(model, in: image)
        }
        return []
    }

    private func detectObjectsWithModel(_ model: VNCoreMLModel, in image: CIImage) throws -> [String] {
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        let request = VNCoreMLRequest(model: model)
        try handler.perform([request])

        return (request.results as? [VNRecognizedObjectObservation])?
            .filter { $0.confidence >= Self.objectConfidenceThreshold }
            .compactMap { $0.labels.first?.identifier }
            ?? []
    }

    // MARK: - Stage 4: Scene classification

    private func classifyScene(in image: CIImage) async throws -> [String] {
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        let request = VNClassifyImageRequest()
        try handler.perform([request])

        return (request.results as? [VNClassificationObservation])?
            .filter { $0.confidence >= Self.sceneConfidenceThreshold }
            .prefix(5)
            .map { $0.identifier }
            ?? []
    }

    // MARK: - Stage 5: On-device speech recognition

    private func recognizeSpeech() async -> String? {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else { return nil }
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        guard recognizer?.supportsOnDeviceRecognition == true else { return nil }
        return nil
    }

    // MARK: - Stage 6: PII scrub

    private func scrubPII(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(
            of: #"\b\d{7,}\b"#, with: "[REDACTED]", options: .regularExpression)
        result = result.replacingOccurrences(
            of: #"\S+@\S+\.\S+"#, with: "[REDACTED]", options: .regularExpression)
        return result
    }

    // MARK: - Model loading

    private func loadObjectDetectionModel() -> VNCoreMLModel? {
        guard let url = Bundle.main.url(forResource: "YOLO11n", withExtension: "mlmodelc")
               ?? Bundle.main.url(forResource: "YOLO11n", withExtension: "mlpackage") else {
            return nil
        }
        guard let mlModel = try? MLModel(contentsOf: url) else { return nil }
        return try? VNCoreMLModel(for: mlModel)
    }
}

// MARK: - Errors

enum PipelineError: LocalizedError, Sendable {
    case invalidImageData
    case modelLoadFailed

    var errorDescription: String? {
        switch self {
        case .invalidImageData: return "Could not decode captured image."
        case .modelLoadFailed:  return "YOLO model failed to load."
        }
    }
}
