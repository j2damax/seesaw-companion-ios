---
name: privacy-pipeline
description: >
  On-device privacy pipeline for seesaw-companion-ios using Vision, CoreML (YOLO11n),
  and SFSpeechRecognizer. Use when implementing or modifying face blur, object detection,
  scene classification, speech transcription, or PII scrubbing.
---

# On-Device Privacy Pipeline Skill

Teaches the complete implementation of `PrivacyPipelineService` — the privacy-preserving on-device AI pipeline that converts raw JPEG + optional audio into an anonymous `ScenePayload`.

## The 5-Stage Pipeline

```
Stage 1: Face Detect + Blur (Vision + CoreImage)
Stage 2: Object Detection (YOLO11n via CoreML)
Stage 3: Scene Classification (VNClassifyImageRequest)
Stage 4: Speech Recognition (SFSpeechRecognizer, on-device only)
Stage 5: PII Scrub (regex)
```

## Stage 1: Face Detection + Gaussian Blur

```swift
private func detectAndBlurFaces(in image: CIImage) throws -> CIImage {
    let request = VNDetectFaceRectanglesRequest()
    try VNImageRequestHandler(ciImage: image, options: [:]).perform([request])
    guard let faces = request.results, !faces.isEmpty else { return image }

    var result = image
    let w = Int(image.extent.width)
    let h = Int(image.extent.height)
    for face in faces {
        let rect = VNImageRectForNormalizedRect(face.boundingBox, w, h)
        let blurred = result.cropped(to: rect)
                            .applyingGaussianBlur(sigma: 30)
                            .composited(over: result)
        result = blurred
    }
    return result
}
```

**Note:** `sigma: 30` is the minimum required for GDPR-compliant anonymisation of faces at typical AiSee resolution. Do not reduce it.

## Stage 2: Object Detection (YOLO11n)

```swift
private func detectObjects(in image: CIImage) throws -> [String] {
    guard let model = try? VNCoreMLModel(for: YOLO11n(configuration: .init()).model) else {
        return []  // graceful degradation — pipeline continues without objects
    }
    let request = VNCoreMLRequest(model: model)
    request.imageCropAndScaleOption = .scaleFit
    try VNImageRequestHandler(ciImage: image, options: [:]).perform([request])
    return (request.results as? [VNRecognizedObjectObservation])?
        .filter { $0.confidence > 0.4 }
        .compactMap { $0.labels.first?.identifier }
        ?? []
}
```

**Note:** `confidence > 0.4` is the minimum quality threshold. Lower values increase false positives and noise in the cloud prompt.

## Stage 3: Scene Classification

```swift
private func classifyScene(in image: CIImage) throws -> [String] {
    let request = VNClassifyImageRequest()
    try VNImageRequestHandler(ciImage: image, options: [:]).perform([request])
    return (request.results as? [VNClassificationObservation])?
        .filter { $0.confidence > 0.3 }
        .prefix(5)
        .map { $0.identifier }
        ?? []
}
```

## Stage 4: On-Device Speech Recognition

```swift
private func transcribeSpeech(from audioURL: URL) async -> String? {
    guard SFSpeechRecognizer.authorizationStatus() == .authorized else { return nil }
    guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")),
          recognizer.supportsOnDeviceRecognition else {
        return nil  // device does not support on-device STT — do NOT fall back to cloud
    }

    let request = SFSpeechURLRecognitionRequest(url: audioURL)
    request.requiresOnDeviceRecognition = true  // hard enforcement

    return try? await withCheckedThrowingContinuation { continuation in
        recognizer.recognitionTask(with: request) { result, error in
            if let result, result.isFinal {
                continuation.resume(returning: result.bestTranscription.formattedString)
            } else if let error {
                continuation.resume(throwing: error)
            }
        }
    }
}
```

## Stage 5: PII Scrub

```swift
private func scrubPII(_ text: String) -> String {
    var result = text
    let patterns = [
        #"\b\d{7,}\b"#,             // phone-number-like sequences
        #"\S+@\S+\.\S+"#,           // email patterns
        #"\b[A-Z][a-z]+\s[A-Z][a-z]+\b"#  // simple name patterns (First Last)
    ]
    for pattern in patterns {
        result = result.replacingOccurrences(of: pattern,
                                              with: "[REDACTED]",
                                              options: .regularExpression)
    }
    return result
}
```

## Complete Pipeline Function

```swift
actor PrivacyPipelineService {
    func process(jpegData: Data, childAge: Int) async throws -> ScenePayload {
        guard let ciImage = CIImage(data: jpegData) else {
            throw PipelineError.invalidImage
        }
        let blurred = try detectAndBlurFaces(in: ciImage)
        async let objects = detectObjects(in: blurred)
        async let scene = classifyScene(in: blurred)
        let (detectedObjects, sceneLabels) = try await (objects, scene)
        // jpegData is not referenced after this point
        return ScenePayload(
            objects: detectedObjects,
            scene: sceneLabels,
            transcript: nil,   // wire up Stage 4 when audio capture is ready
            childAge: childAge
        )
    }
}
```

## Privacy Checklist

- [ ] `VNDetectFaceRectanglesRequest` runs BEFORE any CoreML request
- [ ] `sigma: 30` Gaussian blur applied to every detected face region
- [ ] `SFSpeechRecognizer` has `requiresOnDeviceRecognition = true`
- [ ] `ScenePayload` has no `Data` fields — only `[String]` and `Int`
- [ ] `jpegData` parameter not stored in any property or closure after `process()` returns
- [ ] Confidence thresholds not reduced below: objects 0.4, scene 0.3
