---
applyTo: "**/AI/**/*.swift, **/PrivacyPipeline*.swift"
---

# Privacy Pipeline Rules — seesaw-companion-ios

- `VNDetectFaceRectanglesRequest` must ALWAYS be Stage 1 — never reorder
- Face blur sigma must be >= 30 — never reduce
- `SFSpeechRecognizer` must have `requiresOnDeviceRecognition = true`
- `ScenePayload` must never contain `Data` fields
- The `jpegData: Data` parameter must not be stored or captured after `process()` returns
- Object detection confidence threshold must be >= 0.4
- Scene classification confidence threshold must be >= 0.3
- Never add network calls inside `PrivacyPipelineService`
