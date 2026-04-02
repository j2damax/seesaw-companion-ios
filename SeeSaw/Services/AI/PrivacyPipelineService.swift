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
    private let ciContext = CIContext()

    init() {
        objectDetectionModel = Self.loadObjectDetectionModel()
        #if DEBUG
        PipelineLog.log("init", "objectDetectionModel loaded=\(objectDetectionModel != nil)")
        #endif
    }

    // MARK: - Public entry point

    func process(jpegData: Data, childAge: Int) async throws -> ScenePayload {
        guard let rawImage = CIImage(data: jpegData) else {
            throw PipelineError.invalidImageData
        }
        let ciImage = rawImage.orientedToUp()
        #if DEBUG
        PipelineLog.log("Stage 0 – input", "imageSize=\(ciImage.extent.size), childAge=\(childAge)")
        #endif

        let blurredImage = try detectAndBlurFaces(in: ciImage)

        async let objects = detectObjects(in: blurredImage)
        async let scene   = classifyScene(in: blurredImage)
        async let transcript = recognizeSpeech()

        let (detectedObjects, sceneLabels, rawTranscript) = try await (objects, scene, transcript)
        let cleanTranscript = rawTranscript.map { scrubPII($0) }
        #if DEBUG
        PipelineLog.log("Stage 6 – output", "objects=\(detectedObjects), scene=\(sceneLabels), hasTranscript=\(cleanTranscript != nil)")
        #endif

        return ScenePayload(
            objects: detectedObjects,
            scene: sceneLabels,
            transcript: cleanTranscript,
            childAge: childAge
        )
    }

    // MARK: - Stage 1 + 2: Face detection & blur

    private func detectAndBlurFaces(in image: CIImage) throws -> CIImage {
        #if DEBUG
        PipelineLog.log("Stage 1 – face detection", "imageSize=\(image.extent.size)")
        #endif
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        let request = VNDetectFaceRectanglesRequest()
        try handler.perform([request])

        guard let observations = request.results, !observations.isEmpty else {
            #if DEBUG
            PipelineLog.log("Stage 2 – face blur", "faceCount=0, skipping blur")
            #endif
            return image
        }
        #if DEBUG
        PipelineLog.log("Stage 2 – face blur", "faceCount=\(observations.count), applying CIGaussianBlur sigma=30")
        #endif

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

    // MARK: - Debug detection (face-blurred image + bounding boxes for preview)

    func runDebugDetection(jpegData: Data) async throws -> (blurredData: Data, detections: [DetectionResult]) {
        guard let rawImage = CIImage(data: jpegData) else {
            throw PipelineError.invalidImageData
        }
        let ciImage = rawImage.orientedToUp()
        #if DEBUG
        PipelineLog.log("runDebugDetection – start", "inputSize=\(ciImage.extent.size), modelLoaded=\(objectDetectionModel != nil)")
        #endif

        let blurredImage = try detectAndBlurFaces(in: ciImage)
        let detections: [DetectionResult]
        if let model = objectDetectionModel {
            detections = (try? detectObjectsWithBoxes(model: model, in: blurredImage)) ?? []
        } else {
            detections = []
        }
        #if DEBUG
        PipelineLog.log("runDebugDetection – detections", "count=\(detections.count), labels=\(detections.map { $0.label })")
        #endif
        let blurredData = renderToJpeg(blurredImage) ?? jpegData
        #if DEBUG
        PipelineLog.log("runDebugDetection – done", "blurredDataBytes=\(blurredData.count)")
        #endif
        return (blurredData, detections)
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
        let request = configuredDetectionRequest(model: model)
        try handler.perform([request])

        let labels = (request.results as? [VNRecognizedObjectObservation])?
            .filter { $0.confidence >= Self.objectConfidenceThreshold }
            .compactMap { $0.labels.first?.identifier }
            ?? []
        #if DEBUG
        PipelineLog.log("Stage 3 – object detection", "labels=\(labels)")
        #endif
        return labels
    }

    private func detectObjectsWithBoxes(model: VNCoreMLModel, in image: CIImage) throws -> [DetectionResult] {
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        let request = configuredDetectionRequest(model: model)
        try handler.perform([request])

        let results = (request.results as? [VNRecognizedObjectObservation])?
            .filter { $0.confidence >= Self.objectConfidenceThreshold }
            .compactMap { obs -> DetectionResult? in
                guard let top = obs.labels.first else { return nil }
                return DetectionResult(label: top.identifier,
                                       confidence: obs.confidence,
                                       boundingBox: obs.boundingBox)
            }
            ?? []
        #if DEBUG
        PipelineLog.log("Stage 3 – object detection (boxes)", "count=\(results.count), items=\(results.map { "\($0.label)@\(Int($0.confidence * 100))%" })")
        #endif
        return results
    }

    private func configuredDetectionRequest(model: VNCoreMLModel) -> VNCoreMLRequest {
        let request = VNCoreMLRequest(model: model)
        request.imageCropAndScaleOption = .scaleFit
        return request
    }

    private func renderToJpeg(_ image: CIImage) -> Data? {
        ciContext.jpegRepresentation(of: image,
                                     colorSpace: CGColorSpaceCreateDeviceRGB())
    }

    // MARK: - Stage 4: Scene classification

    private func classifyScene(in image: CIImage) async throws -> [String] {
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        let request = VNClassifyImageRequest()
        try handler.perform([request])

        let labels = (request.results)?
            .filter { $0.confidence >= Self.sceneConfidenceThreshold }
            .prefix(5)
            .map { $0.identifier }
            ?? []
        #if DEBUG
        PipelineLog.log("Stage 4 – scene classification", "labels=\(labels)")
        #endif
        return labels
    }

    // MARK: - Stage 5: On-device speech recognition

    private func recognizeSpeech() async -> String? {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            #if DEBUG
            PipelineLog.log("Stage 5 – speech recognition", "skipped: not authorized")
            #endif
            return nil
        }
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        guard recognizer?.supportsOnDeviceRecognition == true else {
            #if DEBUG
            PipelineLog.log("Stage 5 – speech recognition", "skipped: on-device not supported")
            #endif
            return nil
        }
        #if DEBUG
        PipelineLog.log("Stage 5 – speech recognition", "completed: transcript=nil (stub)")
        #endif
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

    private nonisolated static func loadObjectDetectionModel() -> VNCoreMLModel? {
        guard let url = Bundle.main.url(forResource: "seesaw-yolo11n", withExtension: "mlmodelc")
               ?? Bundle.main.url(forResource: "seesaw-yolo11n", withExtension: "mlpackage") else {
            return nil
        }
        guard let mlModel = try? MLModel(contentsOf: url) else { return nil }
        return try? VNCoreMLModel(for: mlModel)
    }
}

// MARK: - CIImage orientation helper

private extension CIImage {
    /// Returns a version of the image rotated to upright orientation (EXIF value 1)
    /// by applying the transform encoded in the EXIF orientation metadata.
    /// If the image is already upright (value 1) or has no orientation metadata,
    /// the original image is returned unchanged.
    func orientedToUp() -> CIImage {
        guard let orientationValue = properties[kCGImagePropertyOrientation as String] as? UInt32,
              orientationValue != 1 else {
            return self
        }
        return oriented(forExifOrientation: Int32(orientationValue))
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

