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

    // MARK: - YOLO class labels (must match seesaw-yolo11n.mlpackage training config)

    private static let classLabels: [String] = [
        "bed", "sofa", "chair", "table", "lamp", "tv", "laptop", "wardrobe",
        "window", "door", "potted_plant", "photo_frame", "teddy_bear", "book",
        "sports_ball", "backpack", "bottle", "cup", "building_blocks", "dinosaur_toy",
        "stuffed_animal", "picture_book", "crayon", "toy_car", "puzzle_piece", "carpet",
        "chimney", "clock", "crib", "cupboard", "curtains", "faucet", "floor_decor",
        "glass", "pillows", "pots", "rugs", "shelf", "stairs", "storage", "whiteboard",
        "toy_airplane", "toy_fire_truck", "toy_jeep"
    ]

    // MARK: - CoreML model (optional — graceful fallback if absent)

    private var objectDetectionModel: VNCoreMLModel?
    private let ciContext = CIContext()

    init() {
        objectDetectionModel = Self.loadObjectDetectionModel()
        AppConfig.shared.log("init: objectDetectionModel loaded=\(objectDetectionModel != nil)")
    }

    // MARK: - Public entry point

    func process(jpegData: Data, childAge: Int) async throws -> ScenePayload {
        guard let rawImage = CIImage(data: jpegData) else {
            throw PipelineError.invalidImageData
        }
        let ciImage = rawImage.orientedToUp()
        AppConfig.shared.log("Stage 0 – input: imageSize=\(ciImage.extent.size), childAge=\(childAge)")

        let blurredImage = try detectAndBlurFaces(in: ciImage)

        async let objects = detectObjects(in: blurredImage)
        async let scene   = classifyScene(in: blurredImage)
        async let transcript = recognizeSpeech()

        let (detectedObjects, sceneLabels, rawTranscript) = try await (objects, scene, transcript)
        let cleanTranscript = rawTranscript.map { scrubPII($0) }
        AppConfig.shared.log("Stage 6 – output: objects=\(detectedObjects), scene=\(sceneLabels), hasTranscript=\(cleanTranscript != nil)")

        return ScenePayload(
            objects: detectedObjects,
            scene: sceneLabels,
            transcript: cleanTranscript,
            childAge: childAge
        )
    }

    // MARK: - Stage 1 + 2: Face detection & blur

    private func detectAndBlurFaces(in image: CIImage) throws -> CIImage {
        AppConfig.shared.log("Stage 1 – face detection: imageSize=\(image.extent.size)")
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        let request = VNDetectFaceRectanglesRequest()
        try handler.perform([request])

        guard let observations = request.results, !observations.isEmpty else {
            AppConfig.shared.log("Stage 2 – face blur: faceCount=0, skipping blur")
            return image
        }
        AppConfig.shared.log("Stage 2 – face blur: faceCount=\(observations.count), applying CIGaussianBlur sigma=30")

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
        AppConfig.shared.log("runDebugDetection – start: inputSize=\(ciImage.extent.size), modelLoaded=\(objectDetectionModel != nil)")

        let blurredImage = try detectAndBlurFaces(in: ciImage)
        let detections: [DetectionResult]
        if let model = objectDetectionModel {
            detections = (try? detectObjectsWithBoxes(model: model, in: blurredImage)) ?? []
        } else {
            detections = []
        }
        AppConfig.shared.log("runDebugDetection – detections: count=\(detections.count), labels=\(detections.map { $0.label })")
        let blurredData = renderToJpeg(blurredImage) ?? jpegData
        AppConfig.shared.log("runDebugDetection – done: blurredDataBytes=\(blurredData.count)")
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

        let detections = parseDetections(from: request, includeBoxes: false)
        let labels = detections.map { $0.label }
        AppConfig.shared.log("Stage 3 – object detection: labels=\(labels)")
        return labels
    }

    private func detectObjectsWithBoxes(model: VNCoreMLModel, in image: CIImage) throws -> [DetectionResult] {
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        let request = configuredDetectionRequest(model: model)
        try handler.perform([request])

        let results = parseDetections(from: request, includeBoxes: true)
        AppConfig.shared.log("Stage 3 – object detection (boxes): count=\(results.count), items=\(results.map { "\($0.label)@\(Int($0.confidence * 100))%" })")
        return results
    }

    /// Parses `VNCoreMLFeatureValueObservation` results produced by the YOLO11n NMS model.
    /// The model outputs two MultiArray features:
    ///   - "confidence"  [N, 44] — per-box class scores (post-NMS)
    ///   - "coordinates" [N, 4]  — per-box [x_center, y_center, width, height] normalised (top-left origin)
    /// Vision does not automatically map these to `VNRecognizedObjectObservation`; they must be read directly.
    private func parseDetections(from request: VNCoreMLRequest, includeBoxes: Bool) -> [DetectionResult] {
        guard let observations = request.results as? [VNCoreMLFeatureValueObservation],
              let confidenceArray  = observations.first(where: { $0.featureName == "confidence"  })?.featureValue.multiArrayValue,
              let coordinatesArray = observations.first(where: { $0.featureName == "coordinates" })?.featureValue.multiArrayValue,
              confidenceArray.shape.count == 2,
              coordinatesArray.shape.count == 2 else {
            AppConfig.shared.log("Stage 3 – object detection: unexpected result type or missing features", level: .warning)
            return []
        }

        let numBoxes   = confidenceArray.shape[0].intValue
        let numClasses = confidenceArray.shape[1].intValue
        var results: [DetectionResult] = []

        for boxIdx in 0..<numBoxes {
            var maxConf: Float = 0
            var maxClass = 0
            for clsIdx in 0..<numClasses {
                let conf = confidenceArray[[boxIdx, clsIdx] as [NSNumber]].floatValue
                if conf > maxConf { maxConf = conf; maxClass = clsIdx }
            }
            guard maxConf >= Self.objectConfidenceThreshold,
                  maxClass < Self.classLabels.count else { continue }

            let boundingBox: CGRect
            if includeBoxes {
                let xCenter = coordinatesArray[[boxIdx, 0] as [NSNumber]].floatValue
                let yCenter = coordinatesArray[[boxIdx, 1] as [NSNumber]].floatValue
                let width   = coordinatesArray[[boxIdx, 2] as [NSNumber]].floatValue
                let height  = coordinatesArray[[boxIdx, 3] as [NSNumber]].floatValue
                // YOLO outputs [xc, yc, w, h] with top-left origin (0,0 = top-left corner).
                // Vision expects [x, y, w, h] with bottom-left origin (0,0 = bottom-left corner).
                // Convert: x = xc - w/2  (left edge),  y = 1 - yc - h/2  (flip + move to bottom edge)
                boundingBox = CGRect(x: CGFloat(xCenter - width / 2),
                                     y: CGFloat(1 - yCenter - height / 2),
                                     width: CGFloat(width),
                                     height: CGFloat(height))
            } else {
                boundingBox = .zero
            }
            results.append(DetectionResult(label: Self.classLabels[maxClass],
                                            confidence: maxConf,
                                            boundingBox: boundingBox))
        }
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
        AppConfig.shared.log("Stage 4 – scene classification: labels=\(labels)")
        return labels
    }

    // MARK: - Stage 5: On-device speech recognition

    private func recognizeSpeech() async -> String? {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            AppConfig.shared.log("Stage 5 – speech recognition: skipped: not authorized")
            return nil
        }
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        guard recognizer?.supportsOnDeviceRecognition == true else {
            AppConfig.shared.log("Stage 5 – speech recognition: skipped: on-device not supported")
            return nil
        }
        AppConfig.shared.log("Stage 5 – speech recognition: completed: transcript=nil (stub)")
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

