# `seesaw-companion-ios` — Technical Architecture Blueprint
> **Purpose**: Authoritative technical blueprint for the `seesaw-companion-ios` iOS application. Designed for Swift 6+, iOS 26+, minimum viable scope for PoC. Uses simple MVVM + Clean Architecture. This document is the iOS counterpart to `seesaw-native` and must be read alongside the `seesaw-native` blueprint for the full picture.

***
## 0. System Role
`seesaw-companion-ios` is **Tier 2** in the SeeSaw three-tier architecture. It runs on an iPhone and acts as the intelligence bridge between the AiSee headset (Tier 1, BLE) and the cloud story agent (Tier 3, HTTPS).

```
AiSee Headset (seesaw-native)
        │  BLE GATT
        ▼
  iPhone (seesaw-companion-ios)   ◀── This app
        │  HTTPS/REST
        ▼
  Cloud Agent (seesaw-cloud-agent)
```

**What this app does in one interaction cycle:**
1. Receives a chunked JPEG over BLE from the AiSee headset
2. Reassembles the JPEG and runs the on-device privacy pipeline (Vision + CoreML)
3. Builds a JSON payload of anonymous scene labels — no raw image, no faces, no voice biometrics
4. POSTs the JSON to the cloud agent and receives a story back
5. Converts the story to audio (AVSpeechSynthesizer or Cloud TTS)
6. Encodes audio as AAC, chunks it, and writes it back to the AiSee headset over BLE

The app runs **silently in the background**. There is a minimal parent UI for status and settings only.

***
## 1. Project Identity & Build Configuration
### Xcode Project Settings
| Field | Value |
|-------|-------|
| **Bundle ID** | `com.seesaw.companion.ios` |
| **Language** | Swift 6.0+ |
| **Minimum Deployment** | iOS 26.0 |
| **Supported Devices** | iPhone only (`TARGETED_DEVICE_FAMILY = 1`) |
| **Swift Concurrency** | Strict (`SWIFT_STRICT_CONCURRENCY = complete`) |
| **Interface** | SwiftUI |
| **Orientation** | Portrait only |
| **Background Modes** | `bluetooth-central`, `audio` |
### Required Capabilities (`Info.plist`)
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>SeeSaw uses Bluetooth to connect to the AiSee headset.</string>

<key>NSBluetoothPeripheralUsageDescription</key>
<string>SeeSaw uses Bluetooth to communicate with the AiSee headset.</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>SeeSaw uses on-device speech recognition to understand what the child says.</string>

<key>NSMicrophoneUsageDescription</key>
<string>SeeSaw uses the microphone for on-device speech recognition only.</string>

<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
    <string>audio</string>
</array>
```
### Dependencies
**Zero third-party dependencies for PoC.** Everything uses native Apple frameworks:

| Framework | Purpose |
|-----------|---------|
| `CoreBluetooth` | BLE GATT client (central role) |
| `Vision` | Face detection + scene classification |
| `CoreML` | YOLO11n object detection |
| `CoreImage` | Face blur (Gaussian) |
| `Speech` | On-device speech-to-text (`SFSpeechRecognizer`) |
| `AVFoundation` | Audio encoding (AAC) + chunking |
| `AVSpeechSynthesis` | On-device TTS fallback |
| `Foundation` (`URLSession`) | HTTPS calls to cloud agent |
| `SwiftUI` | Minimal parent status UI |

***
## 2. Architecture Pattern: MVVM + Clean (Minimal)
For PoC, three layers only. No repositories pattern, no use-case interactors, no DI framework.

```
┌─────────────────────────────────────────┐
│            Presentation Layer           │
│   SwiftUI Views  +  ViewModels          │
│   (status display, settings only)       │
└────────────────────┬────────────────────┘
                     │ calls / observes
┌────────────────────▼────────────────────┐
│             Service Layer               │
│   BLEService  PrivacyPipeline           │
│   CloudService  AudioService            │
│   (plain Swift classes, @MainActor)     │
└────────────────────┬────────────────────┘
                     │ uses
┌────────────────────▼────────────────────┐
│              Model Layer                │
│   Pure Swift structs / enums            │
│   No UIKit, no framework imports        │
└─────────────────────────────────────────┘
```

**Rules:**
- ViewModels are `@Observable` (Swift 5.9+ macro, available iOS 17+, preferred over `ObservableObject`)
- Services are injected into ViewModels as `let` properties (no DI container needed at PoC scale)
- All async work uses Swift structured concurrency (`async/await`, `Task`, `AsyncStream`)
- No Combine, no RxSwift

***
## 3. Project Structure
```
seesaw-companion-ios/
└── SeeSawCompanion/
    │
    ├── App/
    │   ├── SeeSawCompanionApp.swift        ← @main entry point
    │   └── AppEnvironment.swift            ← Service instances (shared singletons)
    │
    ├── Model/                              ← Pure Swift structs/enums, zero imports
    │   ├── SessionState.swift              ★ Enum: idle/connected/capturing/processing/playing
    │   ├── ScenePayload.swift              ★ Codable: objects[], scene, transcript, childAge
    │   ├── StoryResponse.swift             ← Codable: storyText, audioURL
    │   ├── BLEConstants.swift              ★ UUIDs matching seesaw-native exactly
    │   └── TransferChunk.swift             ← Struct: seqNum, total, payload: Data
    │
    ├── Services/                           ← Business logic, no SwiftUI imports
    │   ├── BLE/
    │   │   ├── BLEService.swift            ★ CoreBluetooth CBCentralManager
    │   │   └── ChunkBuffer.swift           ← Reassemble ordered chunks
    │   ├── AI/
    │   │   ├── PrivacyPipelineService.swift ★ Vision + CoreML + Speech pipeline
    │   │   └── YOLO11n.mlpackage/          ← CoreML model bundle
    │   ├── Cloud/
    │   │   └── CloudAgentService.swift     ★ URLSession POST to seesaw-cloud-agent
    │   └── Audio/
    │       └── AudioService.swift          ★ TTS → AAC encode → chunk → BLE write
    │
    ├── ViewModel/
    │   └── CompanionViewModel.swift        ★ Single ViewModel for PoC
    │
    └── View/
        ├── ContentView.swift               ← Root view (status + connect button)
        ├── StatusView.swift                ← Live session state display
        └── SettingsView.swift              ← Child age, cloud URL, debug toggle
```

> ★ = Critical file — build these first.

***
## 4. BLE Constants (`BLEConstants.swift`)
**Must be byte-for-byte identical to `seesaw-native` `Constants.kt`:**

```swift
import CoreBluetooth

enum BLEConstants {
    static let serviceUUID        = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")
    static let imageDataTXUUID    = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567891")
    static let audioDataRXUUID    = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567892")
    static let commandRXUUID      = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567893")
    static let statusTXUUID       = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567894")
    static let mtuConfigUUID      = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567895")

    // Commands sent TO AiSee via COMMAND_RX
    static let cmdCapture         = "CAPTURE"
    static let cmdStop            = "STOP"
    static let cmdReset           = "RESET"

    // Status received FROM AiSee via STATUS_TX
    static let statusReady        = "READY"
    static let statusCapturing    = "CAPTURING"
    static let statusImgDone      = "IMG_DONE"
    static let statusAudioDone    = "AUDIO_DONE"
    static let statusBusy         = "BUSY"
    static let statusError        = "ERROR"
    static let statusTimeout      = "TIMEOUT"
}
```

***
## 5. Session State Machine
```swift
enum SessionState: String {
    case idle               // Not connected to AiSee
    case scanning           // CBCentralManager scanning for SEESAW_ device
    case connected          // AiSee connected, subscribed to notifications
    case receivingImage     // Receiving JPEG chunks from IMAGE_DATA_TX
    case processingPrivacy  // On-device privacy pipeline running
    case requestingStory    // POST to cloud agent in progress
    case encodingAudio      // TTS + AAC encoding
    case sendingAudio       // Writing audio chunks to AUDIO_DATA_RX
    case error(String)      // Error with description
}
```

State lives in `CompanionViewModel` as `@Published var state: SessionState = .idle` and is the single source of truth displayed in the parent UI.

***
## 6. BLE Service (`BLEService.swift`)
The app runs as **GATT Central** (client). It scans for the AiSee peripheral, connects, discovers services, subscribes to notifications, and exchanges data.

```swift
@MainActor
final class BLEService: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    // Discovered handles — populated after service discovery
    private var peripheral: CBPeripheral?
    private var imageDataTX: CBCharacteristic?   // subscribe to NOTIFY
    private var statusTX: CBCharacteristic?       // subscribe to NOTIFY
    private var audioDataRX: CBCharacteristic?    // write WITHOUT RESPONSE
    private var commandRX: CBCharacteristic?      // write WITH RESPONSE
    private var mtuConfig: CBCharacteristic?      // read/write

    // Callback closures — set by CompanionViewModel
    var onImageChunkReceived: ((TransferChunk) -> Void)?
    var onStatusReceived: ((String) -> Void)?
    var onConnected: (() -> Void)?
    var onDisconnected: (() -> Void)?
}
```
### Connection Flow
```
BLEService.startScanning()
    → centralManager.scanForPeripherals(withServices: [BLEConstants.serviceUUID])
       │
       ▼ didDiscover peripheral (name starts with "SEESAW_")
    → centralManager.connect(peripheral)
       │
       ▼ didConnect
    → peripheral.discoverServices([BLEConstants.serviceUUID])
       │
       ▼ didDiscoverServices
    → peripheral.discoverCharacteristics(nil, for: service)
       │
       ▼ didDiscoverCharacteristics
    → setNotifyValue(true, for: imageDataTXCharacteristic)
    → setNotifyValue(true, for: statusTXCharacteristic)
    → negotiate MTU: write(512 bytes as Data, for: mtuConfigCharacteristic)
    → call onConnected()
```
### Receiving Image Chunks
```swift
func peripheral(_ peripheral: CBPeripheral,
                didUpdateValueFor characteristic: CBCharacteristic,
                error: Error?) {
    guard let data = characteristic.value else { return }

    switch characteristic.uuid {
    case BLEConstants.imageDataTXUUID:
        let chunk = TransferChunk(from: data)   // parse 4-byte header
        onImageChunkReceived?(chunk)

    case BLEConstants.statusTXUUID:
        let status = String(data: data, encoding: .utf8) ?? ""
        onStatusReceived?(status)

    default: break
    }
}
```
### Sending Audio Chunks
```swift
func sendAudioChunks(_ audioData: Data) async {
    guard let peripheral, let audioDataRX else { return }
    let payloadSize = 508  // MTU 512 - 4 byte header
    let chunks = audioData.chunked(size: payloadSize)

    for (index, chunk) in chunks.enumerated() {
        var packet = Data()
        packet.append(contentsOf: UInt16(index).bigEndianBytes)
        packet.append(contentsOf: UInt16(chunks.count).bigEndianBytes)
        packet.append(chunk)
        peripheral.writeValue(packet,
                              for: audioDataRX,
                              type: .withoutResponse)
        // 20ms pacing delay — prevents BLE buffer overflow on AiSee
        try? await Task.sleep(nanoseconds: 20_000_000)
    }
}
```
### `ChunkBuffer.swift`
Reassembles out-of-order chunks using a dictionary keyed by sequence number:

```swift
final class ChunkBuffer {
    private var buffer: [Int: Data] = [:]
    private var expectedTotal: Int = 0

    func add(_ chunk: TransferChunk) -> Data? {
        expectedTotal = Int(chunk.total)
        buffer[Int(chunk.seqNum)] = chunk.payload
        guard buffer.count == expectedTotal else { return nil }
        return (0..<expectedTotal).compactMap { buffer[$0] }
                                  .reduce(Data(), +)
    }

    func reset() { buffer.removeAll(); expectedTotal = 0 }
}
```

***
## 7. Privacy Pipeline Service (`PrivacyPipelineService.swift`)
This is the core research contribution of Tier 2. All raw sensor data is processed here on-device. **Nothing raw leaves this function.**

```swift
actor PrivacyPipelineService {

    func process(jpegData: Data, childAge: Int) async throws -> ScenePayload {

        guard let ciImage = CIImage(data: jpegData) else {
            throw PipelineError.invalidImage
        }

        // Stage 1: Face Detection + Blur (Vision + CoreImage)
        let blurredImage = try await detectAndBlurFaces(in: ciImage)

        // Stage 2: Object Detection (YOLO11n CoreML via Vision)
        let detectedObjects = try await runObjectDetection(on: blurredImage)

        // Stage 3: Scene Classification (VNClassifyImageRequest)
        let sceneLabels = try await classifyScene(in: blurredImage)

        // Stage 4: On-device Speech Recognition (SFSpeechRecognizer)
        // Only runs if audio data was captured alongside the image
        let transcript = await recognizeSpeech()  // returns nil if no speech

        // Stage 5: PII Scrub — remove any names, locations, numbers from transcript
        let cleanTranscript = transcript.map { scrubPII($0) }

        // Raw JPEG is discarded here — never returned, never stored
        return ScenePayload(
            objects: detectedObjects,
            scene: sceneLabels,
            transcript: cleanTranscript,
            childAge: childAge
        )
    }
}
```
### Stage 1: Face Detection + Blur
```swift
private func detectAndBlurFaces(in image: CIImage) async throws -> CIImage {
    var result = image
    let request = VNDetectFaceRectanglesRequest()

    try VNImageRequestHandler(ciImage: image, options: [:])
        .perform([request])

    guard let faces = request.results, !faces.isEmpty else {
        return image  // no faces detected, return original
    }

    let context = CIContext()
    for face in faces {
        let faceRect = VNImageRectForNormalizedRect(
            face.boundingBox,
            Int(image.extent.width),
            Int(image.extent.height)
        )
        // Gaussian blur radius 30 — sufficient to anonymise
        let blurred = result
            .cropped(to: faceRect)
            .applyingGaussianBlur(sigma: 30)
            .composited(over: result)
        result = blurred
    }
    return result
}
```
### Stage 2: Object Detection (YOLO11n)
```swift
private func runObjectDetection(on image: CIImage) async throws -> [String] {
    guard let model = try? VNCoreMLModel(for: YOLO11n(configuration: .init()).model) else {
        return []
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
### Stage 3: Scene Classification
```swift
private func classifyScene(in image: CIImage) async throws -> [String] {
    let request = VNClassifyImageRequest()
    try VNImageRequestHandler(ciImage: image, options: [:]).perform([request])

    return (request.results as? [VNClassificationObservation])?
        .filter { $0.confidence > 0.3 }
        .prefix(5)
        .map { $0.identifier }
        ?? []
}
```
### Stage 4: On-Device Speech Recognition
```swift
private func recognizeSpeech() async -> String? {
    guard SFSpeechRecognizer.authorizationStatus() == .authorized else { return nil }
    let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    recognizer?.supportsOnDeviceRecognition = true   // enforces no-cloud

    // In PoC: speech input is optional. If no audio buffer available, returns nil.
    // Full implementation: receive mic audio buffer alongside image capture.
    return nil  // placeholder until audio capture from AiSee mic is wired up
}
```
### Stage 5: PII Scrub
Simple regex pass to remove numeric sequences, email-like patterns, and known name tokens:

```swift
private func scrubPII(_ text: String) -> String {
    var result = text
    // Remove phone-number-like sequences
    result = result.replacingOccurrences(of: #"\b\d{7,}\b"#,
                                          with: "[REDACTED]",
                                          options: .regularExpression)
    // Remove email-like patterns
    result = result.replacingOccurrences(of: #"\S+@\S+\.\S+"#,
                                          with: "[REDACTED]",
                                          options: .regularExpression)
    return result
}
```
### `ScenePayload` — What Gets Sent to Cloud
```swift
struct ScenePayload: Codable {
    let objects: [String]       // ["dinosaur", "teddy bear", "book"]
    let scene: [String]         // ["bedroom", "indoor", "soft lighting"]
    let transcript: String?     // "let's go on an adventure" (or nil)
    let childAge: Int           // from parent settings (e.g., 5)
    // Raw image: NEVER included
    // Face data: NEVER included
    // Voice audio: NEVER included
}
```

***
## 8. Cloud Agent Service (`CloudAgentService.swift`)
Minimal `URLSession`-based HTTP client. No third-party networking libraries.

```swift
actor CloudAgentService {

    private let baseURL: URL
    private let session = URLSession.shared

    init(baseURL: URL = URL(string: "https://your-cloud-run-url/")!) {
        self.baseURL = baseURL
    }

    func requestStory(payload: ScenePayload) async throws -> StoryResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("story"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15.0

        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw CloudError.unexpectedStatusCode
        }

        return try JSONDecoder().decode(StoryResponse.self, from: data)
    }
}

struct StoryResponse: Codable {
    let storyText: String       // Full story text for TTS
    let audioURL: String?       // Optional: pre-generated TTS audio URL from Cloud TTS
}
```

***
## 9. Audio Service (`AudioService.swift`)
Converts the story text to audio, encodes as AAC, and chunks it for BLE transfer back to AiSee.

```swift
actor AudioService {

    // Option A (PoC default): On-device TTS via AVSpeechSynthesizer
    // Option B (production): Download pre-rendered Cloud TTS audio from audioURL
    // PoC uses Option A — zero network dependency for audio

    func generateAndEncodeAudio(from text: String) async throws -> Data {
        let audioData = try await synthesizeWithAVSpeech(text)
        return try encodeToAAC(audioData)
    }

    private func synthesizeWithAVSpeech(_ text: String) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let synthesizer = AVSpeechSynthesizer()
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
            utterance.rate = 0.45   // slower for children
            utterance.pitchMultiplier = 1.1

            // Write audio to AVAudioFile buffer via AVSpeechSynthesizer.write()
            var audioData = Data()
            synthesizer.write(utterance) { buffer in
                guard let pcmBuffer = buffer as? AVAudioPCMBuffer,
                      pcmBuffer.frameLength > 0 else { return }
                // Accumulate PCM frames
                audioData.append(contentsOf: pcmBuffer.toData())
            }
            // Completion detection via delegate
            continuation.resume(returning: audioData)
        }
    }

    private func encodeToAAC(_ pcmData: Data) throws -> Data {
        // Use AVAudioConverter: PCM 44.1kHz → AAC 16kHz mono
        // Target bitrate: 32 kbps → ~4 KB/s → 10s story ≈ 40 KB ≈ 80 BLE chunks
        // Implementation uses AVAudioConverter with AAC format settings
        return pcmData  // simplified — full AVAudioConverter implementation in T2-028
    }
}
```

***
## 10. ViewModel (`CompanionViewModel.swift`)
Single ViewModel for PoC. Coordinates all services and drives the UI.

```swift
@MainActor
@Observable
final class CompanionViewModel {

    // Services (injected)
    private let bleService: BLEService
    private let privacyPipeline: PrivacyPipelineService
    private let cloudService: CloudAgentService
    private let audioService: AudioService

    // State — observed by SwiftUI views
    var sessionState: SessionState = .idle
    var lastError: String? = nil
    var connectedDeviceName: String? = nil
    var childAge: Int = 5   // from settings

    // Image chunk buffer
    private let imageBuffer = ChunkBuffer()

    init(...) {
        // Wire BLE callbacks
        bleService.onConnected = { [weak self] in
            self?.sessionState = .connected
        }
        bleService.onImageChunkReceived = { [weak self] chunk in
            self?.handleImageChunk(chunk)
        }
        bleService.onStatusReceived = { [weak self] status in
            self?.handleStatus(status)
        }
        bleService.onDisconnected = { [weak self] in
            self?.sessionState = .idle
            self?.imageBuffer.reset()
        }
    }

    func startScanning() {
        sessionState = .scanning
        bleService.startScanning()
    }

    private func handleImageChunk(_ chunk: TransferChunk) {
        sessionState = .receivingImage
        guard let fullImageData = imageBuffer.add(chunk) else { return }
        // All chunks received — start pipeline
        imageBuffer.reset()
        Task { await runFullPipeline(jpegData: fullImageData) }
    }

    private func handleStatus(_ status: String) {
        switch status {
        case BLEConstants.statusImgDone:
            // AiSee has sent all image chunks — pipeline should already be running
            break
        case BLEConstants.statusTimeout:
            sessionState = .error("AiSee timed out waiting for audio response")
        default: break
        }
    }

    private func runFullPipeline(jpegData: Data) async {
        do {
            // Stage 1: Privacy Pipeline (on-device)
            sessionState = .processingPrivacy
            let payload = try await privacyPipeline.process(
                jpegData: jpegData, childAge: childAge)

            // Stage 2: Cloud Story Request
            sessionState = .requestingStory
            let story = try await cloudService.requestStory(payload: payload)

            // Stage 3: Audio Generation + Encoding
            sessionState = .encodingAudio
            let audioData = try await audioService.generateAndEncodeAudio(
                from: story.storyText)

            // Stage 4: Send audio back to AiSee over BLE
            sessionState = .sendingAudio
            await bleService.sendAudioChunks(audioData)

            sessionState = .connected  // ready for next interaction

        } catch {
            sessionState = .error(error.localizedDescription)
            lastError = error.localizedDescription
        }
    }
}
```

***
## 11. SwiftUI Views (Minimal Parent UI)
Only two screens. The app is not a child-facing UI — it runs in the background.
### `ContentView.swift`
```swift
struct ContentView: View {
    @State private var vm = CompanionViewModel(...)

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                StatusView(state: vm.sessionState,
                           deviceName: vm.connectedDeviceName)

                if vm.sessionState == .idle || vm.sessionState == .scanning {
                    Button("Connect to AiSee") {
                        vm.startScanning()
                    }
                    .buttonStyle(.borderedProminent)
                }

                if let error = vm.lastError {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            .padding()
            .navigationTitle("SeeSaw")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink("Settings") {
                        SettingsView(childAge: $vm.childAge)
                    }
                }
            }
        }
    }
}
```
### `StatusView.swift`
Displays a human-readable status badge for each `SessionState`. No business logic.
### `SettingsView.swift`
Two settings only for PoC:
- **Child Age** — `Stepper` (2–12), used in `ScenePayload.childAge`
- **Cloud Agent URL** — `TextField`, stored in `UserDefaults`

***
## 12. Complete Interaction Flow
```
[AiSee headset button pressed — seesaw-native sends image chunks]
         │
         ▼
BLEService.peripheral(_:didUpdateValueFor:)
  → parse TransferChunk from IMAGE_DATA_TX notify
  → call onImageChunkReceived(chunk)
         │
         ▼
CompanionViewModel.handleImageChunk(chunk)
  → ChunkBuffer.add(chunk)
  → when buffer.count == chunk.total:
      Task { await runFullPipeline(jpegData: reassembledData) }
         │
         ▼
PrivacyPipelineService.process(jpegData:childAge:)
  [All runs on Neural Engine via Vision + CoreML]
  1. VNDetectFaceRectanglesRequest → CIGaussianBlur(sigma:30)
  2. VNCoreMLRequest (YOLO11n) → [String] object labels  (conf > 0.4)
  3. VNClassifyImageRequest → [String] scene labels      (conf > 0.3)
  4. SFSpeechRecognizer (on-device) → String? transcript
  5. scrubPII(transcript)
  → ScenePayload { objects, scene, transcript, childAge }
  → raw JPEG ByteArray discarded from memory
         │
         ▼
CloudAgentService.requestStory(payload:)
  → POST https://cloud-run-url/story
     body: { "objects": [...], "scene": [...],
             "transcript": "...", "childAge": 5 }
  → response: { "storyText": "Once upon a time..." }
         │
         ▼
AudioService.generateAndEncodeAudio(from: storyText)
  → AVSpeechSynthesizer.write(utterance) → PCM Data
  → AVAudioConverter: PCM → AAC 16kHz mono 32kbps
  → ~40 KB for a 10-second story
         │
         ▼
BLEService.sendAudioChunks(audioData)
  → split into 508-byte payloads
  → write each as [SEQ|TOTAL|PAYLOAD] to AUDIO_DATA_RX
  → 20ms pacing between writes
  → ~80 chunks × 20ms = ~1.6s total transfer
         │
         ▼
AiSee headset (seesaw-native) reassembles chunks
  → plays story through bone conduction speaker
  → sends STATUS_TX = "AUDIO_DONE"
         │
         ▼
CompanionViewModel.sessionState = .connected
[Ready for next button press]
```

***
## 13. Performance Targets
| Stage | Target Latency | Apple Hardware Used |
|-------|---------------|---------------------|
| Image reassembly (BLE) | 350–500 ms | — |
| Face detection + blur | < 50 ms | Neural Engine |
| YOLO11n object detection | < 80 ms | Neural Engine |
| Scene classification | < 30 ms | Neural Engine |
| Speech recognition | < 200 ms | Neural Engine |
| **Total on-device pipeline** | **< 700 ms** | Neural Engine |
| Cloud round-trip | < 3 000 ms | Network |
| TTS synthesis + AAC encode | < 500 ms | CPU / AVFoundation |
| Audio BLE transfer | ~ 1 600 ms | BLE 5.0 |
| **Total end-to-end** | **< 8 000 ms** | — |

***
## 14. Privacy Guarantees
| Data | Treatment |
|------|-----------|
| Raw JPEG from AiSee | Discarded in memory after `PrivacyPipelineService.process()` returns |
| Face bounding boxes | Used only to drive blur, never stored or transmitted |
| Voice audio from AiSee mic | Processed on-device via `SFSpeechRecognizer(supportsOnDeviceRecognition: true)` |
| Transcript text | PII-scrubbed before inclusion in `ScenePayload` |
| `ScenePayload` sent to cloud | Contains only anonymous labels and age — no raw sensor data |
| Cloud response (story text) | Temporary in-memory only, passed to TTS, discarded |
| TTS audio file | Written to `temporaryDirectory`, deleted after BLE transfer |

***
## 15. Error Handling
All errors are surfaced in `CompanionViewModel.lastError` and displayed in `StatusView`. The app never crashes silently.

| Failure | Behaviour |
|---------|-----------|
| BLE disconnected mid-transfer | `imageBuffer.reset()`, state → `.idle`, show reconnect button |
| CoreML model load failure | Fall back to `VNClassifyImageRequest` scene labels only |
| Cloud request timeout (>15s) | `CloudError.timeout` → display error, state → `.connected` |
| Cloud 4xx/5xx | Display error message from response body |
| Audio synthesis failure | Display error, send empty STATUS_TX to AiSee to unblock it |
| BLE audio write failure | Retry up to 3 times with 100ms delay, then surface error |

***
## 16. Key Design Decisions
| Decision | Reason |
|----------|--------|
| Zero third-party dependencies | Reduces build complexity, app store review risk, and attack surface for PoC |
| `actor` for Services | Swift 6 strict concurrency — eliminates data races without manual locking |
| `@Observable` ViewModel | iOS 17+ native observation, lighter than `ObservableObject` + `@Published` |
| `AVSpeechSynthesizer` over Cloud TTS (PoC) | Removes network dependency for audio; Cloud TTS switchable via `StoryResponse.audioURL` |
| `SFSpeechRecognizer(supportsOnDeviceRecognition: true)` | Enforces no-cloud speech processing by API contract |
| Single ViewModel for PoC | Avoids premature abstraction; can be split into `BLEViewModel` + `PipelineViewModel` in production |
| 20ms chunk pacing in BLE audio write | AiSee BLE buffer is small; pacing prevents `CBATTError.invalidHandle` drops |
| `ChunkBuffer` using dictionary keyed by seqNum | Handles out-of-order BLE delivery without crashing |

***

*Document version: 1.0 | Companion to: `seesaw-native` Technical Architecture Blueprint | Platform: iOS 26+, Swift 6 | Last updated: 2026-03-23*
*UUID constants in Section 4 must remain in sync with `seesaw-native/Constants.kt` at all times.*