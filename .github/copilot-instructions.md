# GitHub Copilot Instructions — seesaw-companion-ios

## Project Overview

`seesaw-companion-ios` is Tier 2 of the SeeSaw three-tier privacy-preserving AI storytelling system for children.
It runs on an iPhone and acts as the intelligence bridge between an AiSee BLE headset (Tier 1) and a cloud story agent (Tier 3).

**One interaction cycle:**
1. Receive chunked JPEG over BLE from AiSee headset (GATT Central role)
2. Run on-device privacy pipeline: face detect → blur → YOLO11n object detect → scene classify → on-device STT → PII scrub
3. POST anonymous `ScenePayload` (labels only, no raw data) to cloud agent
4. Receive story text → synthesise to audio → encode AAC → chunk → write back over BLE to AiSee

**The app has no child-facing UI.** It runs silently in the background. The SwiftUI UI is a minimal parent status/settings screen only.

---

## Technology Stack

- **Language**: Swift 6.0+, strict concurrency (`SWIFT_STRICT_CONCURRENCY = complete`)
- **Platform**: iOS 26.0+, iPhone only
- **UI**: SwiftUI
- **Concurrency**: Swift structured concurrency only — `async/await`, `Task`, `AsyncStream`, `actor`
- **Architecture**: MVVM + Clean (minimal, PoC scope)
- **Dependencies**: Zero third-party libraries. Native Apple frameworks only.

**Core Apple Frameworks:**
- `CoreBluetooth` — BLE GATT Central (client)
- `Vision` — face detection, scene classification (`VNDetectFaceRectanglesRequest`, `VNClassifyImageRequest`)
- `CoreML` — YOLO11n object detection (`VNCoreMLRequest`)
- `CoreImage` — face blur (`CIGaussianBlur`)
- `Speech` — on-device STT (`SFSpeechRecognizer`, `supportsOnDeviceRecognition = true`)
- `AVFoundation` — AAC audio encoding, `AVSpeechSynthesizer`
- `Foundation` `URLSession` — HTTPS to cloud agent

---

## Project Structure

```
SeeSawCompanion/
├── App/
│   ├── SeeSawCompanionApp.swift       ← @main entry
│   └── AppEnvironment.swift           ← shared service instances
├── Model/                             ← Pure Swift structs/enums, zero imports
│   ├── SessionState.swift
│   ├── ScenePayload.swift             ← Codable, sent to cloud
│   ├── StoryResponse.swift
│   ├── BLEConstants.swift             ← UUIDs — never change without syncing seesaw-native
│   └── TransferChunk.swift
├── Services/
│   ├── BLE/
│   │   ├── BLEService.swift           ← CBCentralManager, scan/connect/notify/write
│   │   └── ChunkBuffer.swift          ← Out-of-order chunk reassembly
│   ├── AI/
│   │   ├── PrivacyPipelineService.swift ← actor: Vision + CoreML + Speech
│   │   └── YOLO11n.mlpackage/
│   ├── Cloud/
│   │   └── CloudAgentService.swift    ← actor: URLSession POST
│   └── Audio/
│       └── AudioService.swift         ← actor: TTS + AAC encode
├── ViewModel/
│   └── CompanionViewModel.swift       ← @Observable @MainActor, single ViewModel
└── View/
    ├── ContentView.swift
    ├── StatusView.swift
    └── SettingsView.swift
```

---

## Architecture Rules

1. **Services are `actor`** — all service classes use `actor` keyword (Swift 6 strict concurrency).
2. **ViewModel is `@Observable @MainActor`** — never `ObservableObject` + `@Published`.
3. **Models are pure structs** — zero framework imports in the `Model/` layer.
4. **No Combine** — use `async/await` and `AsyncStream` instead.
5. **No third-party packages** — if you need something, use a native Apple API.
6. **Views are dumb** — no business logic in SwiftUI views. Only display `ViewModel` state.

---

## BLE Protocol — Critical Constants

These UUIDs are a shared contract with `seesaw-native` (Android). **Never change them unilaterally.**

```swift
// BLEConstants.swift
static let serviceUUID     = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")
static let imageDataTXUUID = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567891")  // NOTIFY from AiSee
static let audioDataRXUUID = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567892")  // WRITE to AiSee
static let commandRXUUID   = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567893")  // WRITE to AiSee
static let statusTXUUID    = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567894")  // NOTIFY from AiSee
static let mtuConfigUUID   = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567895")  // READ/WRITE
```

**Chunk packet format** (matches Android side exactly):
```
Byte 0-1 : SEQ_NUM  (UInt16 big-endian)
Byte 2-3 : TOTAL    (UInt16 big-endian)
Byte 4-N : PAYLOAD  (raw bytes, max 508 bytes at MTU 512)
```

**BLE audio write pacing**: always add `Task.sleep(nanoseconds: 20_000_000)` (20ms) between writes to avoid AiSee buffer overflow.

---

## Privacy Pipeline Rules (Non-Negotiable)

The `PrivacyPipelineService` enforces these rules — **never remove or bypass them:**

1. Raw JPEG `Data` is **never stored to disk**, **never written to `UserDefaults`**, **never sent to any network endpoint**
2. `VNDetectFaceRectanglesRequest` → `CIGaussianBlur(sigma: 30)` must run **before** any other analysis
3. `SFSpeechRecognizer` must have `supportsOnDeviceRecognition = true` — never allow cloud fallback
4. `ScenePayload` sent to cloud contains **only**: `objects: [String]`, `scene: [String]`, `transcript: String?`, `childAge: Int`
5. No face coordinates, no raw pixels, no voice audio ever leave the device

---

## Coding Standards

### Naming
- Types: `UpperCamelCase`
- Functions/properties: `lowerCamelCase`
- Constants: `lowerCamelCase` (Swift style, not `SCREAMING_SNAKE`)
- File names match the primary type they contain exactly

### Swift 6 Concurrency
```swift
// ✅ Correct — actor for service isolation
actor CloudAgentService {
    func requestStory(payload: ScenePayload) async throws -> StoryResponse { ... }
}

// ✅ Correct — @MainActor for ViewModel
@MainActor @Observable final class CompanionViewModel { ... }

// ❌ Never — DispatchQueue.main.async in new code
// ❌ Never — completion handlers where async/await works
// ❌ Never — @escaping closures for async work
```

### Error Handling
- All service functions `throws` — never `fatalError` or `!` force-unwrap in service layer
- All errors surface to `CompanionViewModel.lastError: String?`
- Errors are displayed in `StatusView` — never silent failures

### No Force Unwrap
```swift
// ✅
guard let data = characteristic.value else { return }
// ❌
let data = characteristic.value!
```

---

## Key Patterns

### Chunk Reassembly
```swift
// ChunkBuffer.swift — call add() on every incoming chunk
// Returns non-nil Data only when ALL chunks have arrived
if let fullData = imageBuffer.add(chunk) {
    imageBuffer.reset()
    Task { await runFullPipeline(jpegData: fullData) }
}
```

### Privacy Pipeline Invocation
```swift
// Always the first step after image reassembly
let payload = try await privacyPipeline.process(jpegData: fullData, childAge: childAge)
// jpegData is not referenced after this call — let ARC collect it
```

### Cloud Request
```swift
// POST to /story endpoint, 15s timeout, Codable encode/decode
let story = try await cloudService.requestStory(payload: payload)
```

### Audio Send Back to AiSee
```swift
let audioData = try await audioService.generateAndEncodeAudio(from: story.storyText)
await bleService.sendAudioChunks(audioData)  // includes 20ms pacing internally
```

---

## Session States

```
idle → scanning → connected → receivingImage → processingPrivacy
    → requestingStory → encodingAudio → sendingAudio → connected
```

Any error at any stage → `error(String)` → display in UI → return to `connected` if BLE still live.

---

## File Size & Targets

| Metric | Target |
|--------|--------|
| On-device pipeline latency | < 700ms |
| Cloud round-trip | < 3000ms |
| Total end-to-end | < 8000ms |
| Audio BLE transfer (10s story) | ~1600ms (~80 chunks × 20ms) |
| JPEG size (from AiSee) | ~25–40 KB |
| AAC audio size (10s story) | ~40 KB |

---

## What NOT To Do

- ❌ Do NOT add `import UIKit` anywhere
- ❌ Do NOT use `ObservableObject` or `@Published` (use `@Observable` instead)
- ❌ Do NOT add any Swift Package dependencies
- ❌ Do NOT store raw images or audio to disk or UserDefaults
- ❌ Do NOT allow `SFSpeechRecognizer` cloud fallback
- ❌ Do NOT add UI animations or visual polish (PoC scope)
- ❌ Do NOT hardcode the cloud agent URL — read from `UserDefaults` via `SettingsView`
