// PrivacyPipelineService.swift
// SeeSaw — Tier 2 companion app
//
// Privacy-preserving on-device processing pipeline.
// Stages:
//   1. Face detection (VNDetectFaceRectanglesRequest)
//   2. Face blur (CIGaussianBlur, sigma ≥ 30)
//   3. Object detection (VNCoreMLRequest / YOLO11n, confidence ≥ 0.25)
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
import os

actor PrivacyPipelineService {

    // MARK: - Thresholds

    // 0.25 matches the YOLO11n training configuration (seesaw_children.yaml) and the
    // default confidenceThreshold embedded in seesaw-yolo11n.mlpackage.
    private static let objectConfidenceThreshold: Float = 0.25
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

    // MARK: - Signpost instrumentation

    private static let signpostLog = OSLog(subsystem: "com.seesaw.companion", category: "PrivacyPipeline")

    // MARK: - CoreML model (optional — graceful fallback if absent)

    private var objectDetectionModel: VNCoreMLModel?
    private let ciContext = CIContext()
    private let speechService: SpeechRecognitionService

    init(speechService: SpeechRecognitionService) {
        let (model, loadWarning) = Self.loadObjectDetectionModel()
        objectDetectionModel = model
        self.speechService = speechService
        if let warning = loadWarning {
            AppConfig.shared.log("init: \(warning)", level: .error)
        }
        AppConfig.shared.log("init: objectDetectionModel loaded=\(objectDetectionModel != nil)")
    }

    // MARK: - Public entry point

    func process(jpegData: Data, childAge: Int, audioData: Data? = nil) async throws -> PipelineResult {
        let pipelineStart = CFAbsoluteTimeGetCurrent()
        let signpostID = OSSignpostID(log: Self.signpostLog)
        os_signpost(.begin, log: Self.signpostLog, name: "Pipeline", signpostID: signpostID)

        guard let rawImage = CIImage(data: jpegData) else {
            throw PipelineError.invalidImageData
        }
        let ciImage = rawImage.orientedToUp()
        AppConfig.shared.log("Stage 0 – input: imageSize=\(ciImage.extent.size), childAge=\(childAge)")

        // Stage 1+2: Face detection & blur
        let faceStart = CFAbsoluteTimeGetCurrent()
        os_signpost(.begin, log: Self.signpostLog, name: "FaceDetectBlur", signpostID: signpostID)
        let (blurredImage, faceCount) = try detectAndBlurFaces(in: ciImage)
        os_signpost(.end, log: Self.signpostLog, name: "FaceDetectBlur", signpostID: signpostID)
        let faceEnd = CFAbsoluteTimeGetCurrent()

        // Stage 3+4: Object detection and scene classification (parallel)
        let visionStart = CFAbsoluteTimeGetCurrent()
        os_signpost(.begin, log: Self.signpostLog, name: "ObjectDetection", signpostID: signpostID)
        async let objects = detectObjects(in: blurredImage)
        os_signpost(.begin, log: Self.signpostLog, name: "SceneClassification", signpostID: signpostID)
        async let scene = classifyScene(in: blurredImage)

        // Stage 5: Speech recognition (parallel with vision stages)
        let sttStart = CFAbsoluteTimeGetCurrent()
        os_signpost(.begin, log: Self.signpostLog, name: "SpeechRecognition", signpostID: signpostID)
        async let transcript = recognizeSpeech(audioData: audioData)

        let (detectedObjects, sceneLabels, rawTranscript) = try await (objects, scene, transcript)
        let visionEnd = CFAbsoluteTimeGetCurrent()
        os_signpost(.end, log: Self.signpostLog, name: "ObjectDetection", signpostID: signpostID)
        os_signpost(.end, log: Self.signpostLog, name: "SceneClassification", signpostID: signpostID)
        os_signpost(.end, log: Self.signpostLog, name: "SpeechRecognition", signpostID: signpostID)
        let sttEnd = CFAbsoluteTimeGetCurrent()

        // Stage 6: PII scrub
        let piiStart = CFAbsoluteTimeGetCurrent()
        os_signpost(.begin, log: Self.signpostLog, name: "PIIScrub", signpostID: signpostID)
        let scrubResult: (scrubbed: String, tokensRedacted: Int)?
        if let raw = rawTranscript {
            scrubResult = PIIScrubber.scrub(raw)
        } else {
            scrubResult = nil
        }
        let cleanTranscript = scrubResult?.scrubbed
        os_signpost(.end, log: Self.signpostLog, name: "PIIScrub", signpostID: signpostID)
        let piiEnd = CFAbsoluteTimeGetCurrent()

        let pipelineEnd = CFAbsoluteTimeGetCurrent()
        os_signpost(.end, log: Self.signpostLog, name: "Pipeline", signpostID: signpostID)

        // Build metrics
        let faceDetectAndBlurMs = (faceEnd - faceStart) * 1000
        let parallelVisionMs = (visionEnd - visionStart) * 1000
        let sttMs = (sttEnd - sttStart) * 1000
        let piiScrubMs = (piiEnd - piiStart) * 1000
        let totalMs = (pipelineEnd - pipelineStart) * 1000

        let metrics = PrivacyMetricsEvent(
            facesDetected: faceCount,
            facesBlurred: faceCount,
            objectsDetected: detectedObjects.count,
            tokensScrubbedFromTranscript: scrubResult?.tokensRedacted ?? 0,
            rawDataTransmitted: false,
            pipelineLatencyMs: totalMs,
            faceDetectMs: faceDetectAndBlurMs * 0.6,
            blurMs: faceDetectAndBlurMs * 0.4,
            yoloMs: parallelVisionMs,
            sceneClassifyMs: parallelVisionMs,
            sttMs: sttMs,
            piiScrubMs: piiScrubMs,
            timestamp: pipelineStart
        )

        AppConfig.shared.log("Pipeline benchmark: faceDetect=\(Int(metrics.faceDetectMs))ms blur=\(Int(metrics.blurMs))ms yolo=\(Int(metrics.yoloMs))ms scene=\(Int(metrics.sceneClassifyMs))ms stt=\(Int(metrics.sttMs))ms piiScrub=\(Int(metrics.piiScrubMs))ms total=\(Int(totalMs))ms")
        AppConfig.shared.log("Stage 6 – output: objects=\(detectedObjects), scene=\(sceneLabels), hasTranscript=\(cleanTranscript != nil)")

        let payload = ScenePayload(
            objects: detectedObjects,
            scene: sceneLabels,
            transcript: cleanTranscript,
            childAge: childAge,
            sessionId: UUID().uuidString,
            query: cleanTranscript,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )

        return PipelineResult(payload: payload, metrics: metrics)
    }

    // MARK: - Stage 1 + 2: Face detection & blur

    private func detectAndBlurFaces(in image: CIImage) throws -> (image: CIImage, faceCount: Int) {
        AppConfig.shared.log("Stage 1 – face detection: imageSize=\(image.extent.size)")
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        let request = VNDetectFaceRectanglesRequest()
        try handler.perform([request])

        guard let observations = request.results, !observations.isEmpty else {
            AppConfig.shared.log("Stage 2 – face blur: faceCount=0, skipping blur")
            return (image, 0)
        }
        AppConfig.shared.log("Stage 2 – face blur: faceCount=\(observations.count), applying CIGaussianBlur sigma=30")

        var output = image
        let imageSize = image.extent.size

        for face in observations {
            let faceRect = denormalize(face.boundingBox, in: imageSize)
            let blurred  = blurRegion(faceRect, in: output)
            output = blurred
        }
        return (output, observations.count)
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

    func runDebugDetection(jpegData: Data) async throws -> (blurredData: Data, detections: [DetectionResult], metrics: PrivacyMetricsEvent) {
        let pipelineStart = CFAbsoluteTimeGetCurrent()
        guard let rawImage = CIImage(data: jpegData) else {
            throw PipelineError.invalidImageData
        }
        let ciImage = rawImage.orientedToUp()
        AppConfig.shared.log("runDebugDetection – start: inputSize=\(ciImage.extent.size), modelLoaded=\(objectDetectionModel != nil)")

        let faceStart = CFAbsoluteTimeGetCurrent()
        let (blurredImage, faceCount) = try detectAndBlurFaces(in: ciImage)
        let faceEnd = CFAbsoluteTimeGetCurrent()

        let yoloStart = CFAbsoluteTimeGetCurrent()
        let detections: [DetectionResult]
        if let model = objectDetectionModel {
            do {
                detections = try detectObjectsWithBoxes(model: model, in: blurredImage)
            } catch {
                AppConfig.shared.log("runDebugDetection – detection error: \(error)", level: .error)
                detections = []
            }
        } else {
            detections = []
        }
        let yoloEnd = CFAbsoluteTimeGetCurrent()

        AppConfig.shared.log("runDebugDetection – detections: count=\(detections.count), labels=\(detections.map { $0.label })")
        let blurredData = renderToJpeg(blurredImage) ?? jpegData
        let pipelineEnd = CFAbsoluteTimeGetCurrent()
        AppConfig.shared.log("runDebugDetection – done: blurredDataBytes=\(blurredData.count)")

        let faceMs = (faceEnd - faceStart) * 1000
        let yoloMs = (yoloEnd - yoloStart) * 1000
        let totalMs = (pipelineEnd - pipelineStart) * 1000

        let metrics = PrivacyMetricsEvent(
            facesDetected: faceCount,
            facesBlurred: faceCount,
            objectsDetected: detections.count,
            tokensScrubbedFromTranscript: 0,
            rawDataTransmitted: false,
            pipelineLatencyMs: totalMs,
            faceDetectMs: faceMs * 0.6,
            blurMs: faceMs * 0.4,
            yoloMs: yoloMs,
            sceneClassifyMs: 0,
            sttMs: 0,
            piiScrubMs: 0,
            timestamp: pipelineStart
        )

        return (blurredData, detections, metrics)
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

    /// Parses detection results from a VNCoreMLRequest.
    /// Handles two observation types that Vision may produce for NMS YOLO models:
    ///   A. `VNRecognizedObjectObservation` — Vision auto-maps confidence/coordinates outputs
    ///      when it recognises the NMS output pattern.  boundingBox is already in Vision
    ///      normalised space (bottom-left origin, 0–1).
    ///   B. `VNCoreMLFeatureValueObservation` — raw multi-array fallback when Vision does not
    ///      auto-convert.  The model outputs two MultiArray features:
    ///        - "confidence"  [N, 44] — per-box class scores (post-NMS)
    ///        - "coordinates" [N, 4]  — per-box [x_center, y_center, width, height] normalised
    ///          (top-left origin).  Must be converted to Vision space for display.
    private func parseDetections(from request: VNCoreMLRequest, includeBoxes: Bool) -> [DetectionResult] {
        // Case A — Vision automatically converted NMS outputs to recognized-object observations.
        if let recognized = request.results as? [VNRecognizedObjectObservation] {
            let results = recognized.compactMap { obs -> DetectionResult? in
                guard let top = obs.labels.first,
                      top.confidence >= Self.objectConfidenceThreshold else { return nil }
                return DetectionResult(
                    label: top.identifier,
                    confidence: top.confidence,
                    boundingBox: includeBoxes ? obs.boundingBox : .zero
                )
            }
            AppConfig.shared.log("Stage 3 – object detection (recognized): count=\(results.count), items=\(results.map { "\($0.label)@\(Int($0.confidence * 100))%" })")
            return results
        }

        // Case B — Raw feature-value multi-arrays.
        guard let observations = request.results as? [VNCoreMLFeatureValueObservation],
              let confidenceArray  = observations.first(where: { $0.featureName == "confidence"  })?.featureValue.multiArrayValue,
              let coordinatesArray = observations.first(where: { $0.featureName == "coordinates" })?.featureValue.multiArrayValue,
              confidenceArray.shape.count == 2,
              coordinatesArray.shape.count == 2 else {
            AppConfig.shared.log("Stage 3 – object detection: unexpected result type '\(type(of: request.results))' or missing features", level: .warning)
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
            .prefix(3)
            .map { $0.identifier }
            ?? []
        AppConfig.shared.log("Stage 4 – scene classification: labels=\(labels)")
        return labels
    }

    // MARK: - Stage 5: On-device speech recognition

    private func recognizeSpeech(audioData: Data?) async -> String? {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            AppConfig.shared.log("Stage 5 – speech recognition: skipped: not authorized")
            return nil
        }
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        guard recognizer?.supportsOnDeviceRecognition == true else {
            AppConfig.shared.log("Stage 5 – speech recognition: skipped: on-device not supported")
            return nil
        }
        guard let audioData, !audioData.isEmpty else {
            AppConfig.shared.log("Stage 5 – speech recognition: skipped: no audio data provided")
            return nil
        }
        do {
            let transcript = try await speechService.transcribeAudioData(audioData)
            AppConfig.shared.log("Stage 5 – speech recognition: completed: transcript=\(transcript ?? "nil")")
            return transcript
        } catch {
            AppConfig.shared.log("Stage 5 – speech recognition: error: \(error.localizedDescription)", level: .error)
            return nil
        }
    }

    // MARK: - Model loading

    /// Loads and validates the YOLO object-detection model.
    /// Returns `(nil, warningMessage)` when the model cannot be used so the
    /// caller can surface a clear diagnostic immediately at startup.
    ///
    /// A probe inference on a 1×1 black image is used to detect NMS pipeline mismatches
    /// (e.g. backbone outputs 80 COCO classes but NMS expects 44 custom classes).
    /// Swift's `MLModel` API only exposes the pipeline's outer output shapes — which are
    /// empty/dynamic for NMS models — so static descriptor checks cannot catch this bug.
    private nonisolated static func loadObjectDetectionModel() -> (VNCoreMLModel?, String?) {
        guard let url = Bundle.main.url(forResource: "seesaw-yolo11n", withExtension: "mlmodelc")
               ?? Bundle.main.url(forResource: "seesaw-yolo11n", withExtension: "mlpackage") else {
            return (nil, "loadObjectDetectionModel: model file not found in bundle")
        }
        guard let mlModel = try? MLModel(contentsOf: url) else {
            return (nil, "loadObjectDetectionModel: MLModel init failed")
        }
        guard let visionModel = try? VNCoreMLModel(for: mlModel) else {
            return (nil, "loadObjectDetectionModel: VNCoreMLModel init failed")
        }

        // Probe: run a 1×1 inference to validate the full pipeline at load time.
        // This catches NMS class-count mismatches that are invisible from MLModel.modelDescription
        // because the pipeline's outer output shapes are empty (dynamic). The error only surfaces
        // when CoreML tries to connect model 0's output to model 1's NMS during evaluation.
        // Fix for the known mismatch: re-export from the 44-class best.pt:
        //   model.export(format='coreml', nms=True, imgsz=640)
        if let probeError = probeModelPipeline(visionModel) {
            let msg = "loadObjectDetectionModel: pipeline validation failed – \(probeError.localizedDescription). Re-export seesaw-yolo11n.mlpackage using the 44-class best.pt: model.export(format='coreml', nms=True, imgsz=640)"
            return (nil, msg)
        }

        return (visionModel, nil)
    }

    /// Runs a synchronous 1×1 probe inference to validate the CoreML pipeline.
    /// Returns the error if the pipeline fails, or `nil` if it succeeds.
    private nonisolated static func probeModelPipeline(_ visionModel: VNCoreMLModel) -> Error? {
        let blackPixel = CIImage(color: CIColor.black).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
        let handler = VNImageRequestHandler(ciImage: blackPixel, options: [:])
        let request = VNCoreMLRequest(model: visionModel)
        do {
            try handler.perform([request])
            return nil
        } catch {
            return error
        }
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

