# KAZE Glass Integration Guide — SeeSaw iOS
**Reference document for implementing KAZE_0113 glass hardware capture in SeeSaw Companion**

---

## 1. Overview

### Goal
Wire the KAZE_0113 smart glass hardware button into the SeeSaw capture pipeline so that:
- **Single tap** → triggers `snapshot()` on the glass → JPEG delivered to `imageDataStream` → existing privacy pipeline and story generation run unchanged
- **Double tap** → hook point for record audio question answer
- **Long press** → hook point for cancel/stop action

### What does NOT change
The entire downstream pipeline is untouched:
- `CompanionViewModel.captureScene()` → `sendCommand("CAPTURE")` → accessory yields JPEG via `imageDataStream`
- Privacy pipeline (face blur, YOLO detection)
- Story generation routing
- `ScenePreviewView` display

The new `KazeGlassAccessory` conforms to the existing `WearableAccessory` protocol — it is a drop-in peer to `BLEService` and `LocalDeviceAccessory`.

### Android learnings applied here
This guide is informed by a fully verified Android implementation of the same hardware (KAZE_0113). Key findings carried forward:
- **Gesture codes are identical cross-platform**: single tap fires a named callback; double tap = action code `0x02`; long press = action code `0x04`
- **Single tap fires on press-down** (before photo arrives); double tap and long press fire **on release only**
- **Error code 5** = glass EMMC still writing previous file → retry once after 1.5 s
- The iOS SDK `snapshot()` → `getCapturedPicInfo()` → `getPictureData()` flow is the exact equivalent of Android's `startTakePhotoProcess()` → `onTakePhotoSuccess()` callback chain

---

## 2. SDK Setup

### 2.1 Frameworks required
The KAZE iOS SDK ships as a set of `.xcframework` bundles. All are located at:
```
/AiSee/v3_kaze_glass/SDK/iOS/RTKAIDeviceConnectionSDK_1.3.0_dist-beta/
```

Copy these into the SeeSaw Xcode project (e.g. `SeeSaw/Frameworks/KAZE/`):

| Framework | Purpose |
|-----------|---------|
| `RTKAIDeviceConnection.xcframework` | Main API — `AIDeviceConnection`, `MiscRoutine`, `CaptureImporter` |
| `RTKAudioConnectSDK.xcframework` | MMI (button events), `RTKACMMIRoutine`, `RTKBBproType` constants |
| `RTKLEFoundation.xcframework` | BLE connection manager, `RTKProfileConnectionManager`, `RTKProfileConnection` |
| `RTKUIiOS.framework` | Optional — pre-built device discovery UI (`DeviceDiscoveryViewController`) |

**Add to Xcode:**
1. Drag all four into the project navigator
2. In `SeeSaw` target → **General** → **Frameworks, Libraries, and Embedded Content** → set each to **Embed & Sign**
3. Under **Build Settings** → `FRAMEWORK_SEARCH_PATHS` → add the folder containing the `.xcframework` files

### 2.2 Info.plist permissions
Add these keys (the SDK requires them at runtime; missing entries cause silent failure):

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>SeeSaw uses Bluetooth to connect to the KAZE smart glass.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>SeeSaw uses Bluetooth to connect to the KAZE smart glass.</string>
<key>NSLocalNetworkUsageDescription</key>
<string>SeeSaw connects to the glass camera over the local Wi-Fi network.</string>
```

The existing `NSCameraUsageDescription` and `NSMicrophoneUsageDescription` entries are already present and sufficient.

### 2.3 Background modes (optional)
If you want BLE reconnection while the app is backgrounded, add to `Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
</array>
```

---

## 3. Architecture

### 3.1 Where this fits

```
WearableAccessory (protocol)
    ├── BLEService              — AiSee headset over BLE
    ├── LocalDeviceAccessory    — iPhone camera + mic
    ├── ExternalSDKAccessory    — Meta Glass / MFi stubs
    └── KazeGlassAccessory      ← NEW (this guide)
```

`KazeGlassAccessory` is a `@MainActor final class` that:
1. Manages `RTKProfileConnectionManager` (BLE scan + connect)
2. Holds a reference to `AIDeviceConnection.miscRoutine` for photo capture
3. Listens to MMI (button) events and routes single-tap → photo pipeline
4. Yields complete JPEG `Data` via `imageDataStream` — same stream `CompanionViewModel` already subscribes to

### 3.2 Photo capture sequence

```
Hardware single tap
        │
        ▼
[MMI callback — single tap event received on phone]
        │
        ▼
miscRoutine.snapshot()            ← triggers glass camera shutter
        │
        ▼
miscRoutine.getCapturedPicInfo()  ← get file size + metadata
        │
        ▼
miscRoutine.getPictureData(picInfo) ← transfer JPEG via BT to phone
        │
        ▼
imageYielder.yield(jpegData)      ← into AsyncStream<Data>
        │
        ▼
CompanionViewModel.imageStreamTask ← existing subscriber
        │
        ▼
runDetectionPreview(jpegData:)    ← existing privacy pipeline, unchanged
```

---

## 4. Implementation

### 4.1 Step 1 — Add `WearableType.kazeGlass`

**File:** `SeeSaw/Model/WearableAccessory.swift`

Add one case to the `WearableType` enum:

```swift
enum WearableType: String, CaseIterable, Sendable {
    case iPhoneCamera  = "iPhone Camera + Mic"
    case aiSeeBLE      = "AiSee (BLE)"
    case metaGlass     = "Meta Glass"
    case mfiCamera     = "MFi Camera Accessory"
    case kazeGlass     = "KAZE Smart Glass"      // ← ADD THIS
}
```

Add the required computed properties inside the existing switch blocks:

```swift
var systemImage: String {
    switch self {
    // ... existing cases ...
    case .kazeGlass: return "eyeglasses"
    }
}

var connectActionLabel: String {
    switch self {
    // ... existing cases ...
    case .kazeGlass: return "Connect to KAZE Glass"
    }
}

var inputSourceDescription: String {
    switch self {
    // ... existing cases ...
    case .kazeGlass:
        return "Connects to KAZE smart glass via Bluetooth. Tap the glass hardware button to capture a scene."
    }
}

var isShownInOnboarding: Bool {
    switch self {
    // ... existing cases ...
    case .kazeGlass: return true
    }
}

var requiresBluetooth: Bool {
    switch self {
    case .aiSeeBLE, .kazeGlass: return true
    default: return false
    }
}
```

That's all for this file — `AccessoryPickerView` renders `WearableType.allCases`, so the new type appears in Settings automatically.

---

### 4.2 Step 2 — Create `KazeGlassAccessory.swift`

Create `SeeSaw/Services/Accessory/KazeGlassAccessory.swift`:

```swift
// KazeGlassAccessory.swift
// SeeSaw — Tier 2 companion app
//
// WearableAccessory conformor for KAZE_0113 smart glass.
// Uses the Realtek RTKAIDeviceConnection iOS SDK (v1.3.0).
//
// Hardware gesture map (confirmed on KAZE_0113, mirroring Android implementation):
//   Single tap  → photo capture (fires on press-down via named callback)
//   Double tap  → action code 0x02, fires on release
//   Long press  → action code 0x04, fires on release
//
// Photo capture sequence:
//   snapshot() → getCapturedPicInfo() → getPictureData() → yield to imageDataStream

import Foundation
import RTKAIDeviceConnection
import RTKAudioConnectSDK
import RTKLEFoundation

@MainActor
final class KazeGlassAccessory: NSObject, WearableAccessory {

    // MARK: - WearableAccessory identity

    let wearableType: WearableType = .kazeGlass
    var accessoryName: String { "KAZE Glass" }
    private(set) var isConnected = false

    // MARK: - WearableAccessory callbacks

    var onConnected: (() -> Void)?
    var onDisconnected: (() -> Void)?

    // MARK: - Streams

    private(set) var imageDataStream: AsyncStream<Data>
    private(set) var statusStream: AsyncStream<String>

    private var imageYielder: AsyncStream<Data>.Continuation?
    private var statusYielder: AsyncStream<String>.Continuation?

    // MARK: - SDK objects

    private var connectionManager: RTKProfileConnectionManager?
    private var deviceConnection: AIDeviceConnection?

    // MARK: - Error retry state (mirrors Android — EMMC busy retry on error code 5)
    private var captureRetryCount = 0
    private let maxCaptureRetries = 1
    private let captureRetryDelaySeconds: UInt64 = 1_500_000_000   // 1.5 s in nanoseconds

    // MARK: - Init

    override init() {
        var imageCont: AsyncStream<Data>.Continuation!
        var statusCont: AsyncStream<String>.Continuation!
        imageDataStream = AsyncStream { imageCont = $0 }
        statusStream    = AsyncStream { statusCont = $0 }
        super.init()
        imageYielder  = imageCont
        statusYielder = statusCont
    }

    private func resetStreams() {
        var imageCont: AsyncStream<Data>.Continuation!
        var statusCont: AsyncStream<String>.Continuation!
        imageDataStream = AsyncStream { imageCont = $0 }
        statusStream    = AsyncStream { statusCont = $0 }
        imageYielder  = imageCont
        statusYielder = statusCont
    }

    // MARK: - WearableAccessory: Lifecycle

    func startDiscovery() async throws {
        resetStreams()
        captureRetryCount = 0

        // RTKProfileConnectionManager is the BLE scan + connection entry point.
        // Register AIDeviceConnection as the class to instantiate for discovered peripherals.
        let manager = RTKProfileConnectionManager(delegate: self)
        manager.registerConnectionClass(forInstantiateGATTPeripheral: AIDeviceConnection.self)
        connectionManager = manager

        // Optional: use the SDK's built-in discovery UI by presenting
        // RTKUIiOS.DeviceDiscoveryViewController (see Section 5.2).
        // For a custom flow, call manager.scanForPeripherals() here and
        // handle discovery in profileManager(_:didDiscoverPeripheralOfConnection:...).
        manager.scanForPeripherals()

        statusYielder?.yield("SCANNING")
    }

    func stopDiscovery() async {
        connectionManager?.stopScan()
        statusYielder?.yield("SCAN_STOPPED")
    }

    func disconnect() async {
        guard isConnected, let connection = deviceConnection else { return }
        connection.deactivate { [weak self] _, _ in
            Task { @MainActor in
                self?.handleDisconnect()
            }
        }
    }

    // MARK: - WearableAccessory: I/O (not used for glass — capture is button-triggered)

    func sendAudio(_ data: Data) async throws {
        // Glass does not accept audio input via this SDK path.
        throw WearableError.deviceUnavailable("Audio output not supported on KAZE glass")
    }

    func sendCommand(_ command: String) async throws {
        // The existing pipeline calls sendCommand("CAPTURE") from CompanionViewModel.captureScene().
        // Route that command to a programmatic snapshot — same as the hardware button path.
        guard command == "CAPTURE" else { return }
        await triggerCapture()
    }

    // MARK: - Photo capture

    /// Programmatic capture — mirrors hardware single-tap path.
    func triggerCapture() async {
        guard let misc = deviceConnection?.miscRoutine else {
            statusYielder?.yield("ERROR: not connected")
            return
        }
        do {
            try await performCapture(using: misc)
        } catch {
            statusYielder?.yield("ERROR: \(error.localizedDescription)")
        }
    }

    /// Core capture sequence: snapshot → info → download → yield.
    private func performCapture(using misc: MiscRoutine) async throws {
        // Step 1: Trigger the glass shutter
        try await misc.snapshot()

        // Step 2: Get file metadata (size + handle)
        let picInfo = try await misc.getCapturedPicInfo()

        // Step 3: Transfer JPEG bytes to phone
        let jpegData = try await misc.getPictureData(with: picInfo)

        captureRetryCount = 0
        imageYielder?.yield(jpegData)
        statusYielder?.yield("IMG_DONE")

    }

    // MARK: - Disconnect cleanup

    private func handleDisconnect() {
        isConnected = false
        deviceConnection = nil
        statusYielder?.yield("DISCONNECTED")
        imageYielder?.finish()
        imageYielder = nil
        statusYielder?.finish()
        statusYielder = nil
        onDisconnected?()
    }
}

// MARK: - RTKProfileConnectionManagerDelegate

extension KazeGlassAccessory: RTKProfileConnectionManagerDelegate {

    nonisolated func profileManagerDidUpdateGATTAvailability(
        _ manager: RTKProfileConnectionManager
    ) {
        // BT state changed (e.g. user toggled Bluetooth in Control Center).
        // No action needed; scan will auto-resume when BT becomes available again.
    }

    nonisolated func profileManager(
        _ manager: RTKProfileConnectionManager,
        didDiscoverPeripheralOfConnection connection: RTKProfileConnection,
        advertisementData: [String: Any],
        RSSI: NSNumber
    ) {
        // A glass device was found. Activate it (establish GATT connection).
        // For production: filter by device name or known MAC address.
        // Example filter: guard connection.deviceName?.hasPrefix("KAZE") == true else { return }
        guard let aiConnection = connection as? AIDeviceConnection else { return }
        manager.stopScan()

        Task { @MainActor in
            self.statusYielder?.yield("CONNECTING")
            do {
                try await aiConnection.activate()
                self.deviceConnection = aiConnection
                self.isConnected = true

                // Wire up button event callbacks (MMI routine).
                self.registerMMICallbacks(on: aiConnection)

                self.statusYielder?.yield("CONNECTED")
                self.onConnected?()
            } catch {
                self.statusYielder?.yield("ERROR: \(error.localizedDescription)")
            }
        }
    }

    nonisolated func profileManager(
        _ manager: RTKProfileConnectionManager,
        didDetectDisconnectionOf connection: RTKProfileConnection
    ) {
        Task { @MainActor in self.handleDisconnect() }
    }
}

// MARK: - MMI (hardware button) wiring

extension KazeGlassAccessory {

    /// Register for hardware button events after connection is established.
    ///
    /// From Android KAZE_0113 verified gesture map:
    ///   Single tap  → dedicated callback (`onDeviceTriggeredTakePhoto` on Android)
    ///   Double tap  → `onReceivedDeviceAction(2)` — fires on release
    ///   Long press  → `onReceivedDeviceAction(4)` — fires on release
    ///
    /// The iOS equivalent callback mechanism is one of:
    ///   (a) RTKProfileConnection.delegate — didReceiveMessage(msgData:)
    ///   (b) RTKACMMIRoutine delegate      — additional protocol methods not in public header
    ///
    /// ⚠️ PROBE REQUIRED: Run the instrumentation block below first to identify
    /// which iOS callback receives which gesture. Remove probes once confirmed.
    private func registerMMICallbacks(on connection: AIDeviceConnection) {

        // --- PROBE: Set RTKProfileConnection delegate for raw message inspection ---
        connection.delegate = self

        // --- PROBE: Set MMI routine delegate if available ---
        if let mmiRoutine = connection.MMIRoutine {
            mmiRoutine.delegate = self
        }

        // Log that we're ready to observe
        AppConfig.shared.log("[KazeGlass] MMI callbacks registered — press hardware button to probe")
    }
}

// MARK: - RTKProfileConnectionDelegate (raw message probe + button routing)

extension KazeGlassAccessory: RTKProfileConnectionDelegate {

    nonisolated func profileConnection(
        _ connection: RTKProfileConnection,
        didReceiveMessage msgData: Data
    ) {
        // PROBE: Log raw bytes to identify button event format.
        // Compare with Android: single tap delivers no raw message (named callback only);
        // double tap delivers action=0x02; long press delivers action=0x04.
        let hexBytes = msgData.map { String(format: "%02X", $0) }.joined(separator: " ")
        AppConfig.shared.log("[KazeGlass][PROBE] didReceiveMessage: \(hexBytes)")

        // Once the format is confirmed, parse here:
        // Example (adjust offsets/format based on observed output):
        //   if msgData.count >= 2 {
        //       let actionCode = msgData[0]
        //       switch actionCode {
        //       case 0x01:  // single tap → photo
        //           Task { @MainActor in await self.triggerCapture() }
        //       case 0x02:  // double tap
        //           break   // future: start audio recording
        //       case 0x04:  // long press
        //           break   // future: cancel activity
        //       default:
        //           break
        //       }
        //   }
    }

    nonisolated func profileConnection(
        _ connection: RTKProfileConnection,
        deviceDidBeDisconnected error: Error?
    ) {
        AppConfig.shared.log("[KazeGlass] device disconnected: \(error?.localizedDescription ?? "none")")
        Task { @MainActor in self.handleDisconnect() }
    }

    nonisolated func profileConnection(
        _ connection: RTKProfileConnection,
        deviceFailedToConnect error: Error?
    ) {
        AppConfig.shared.log("[KazeGlass] connection failed: \(error?.localizedDescription ?? "none")")
        Task { @MainActor in
            self.statusYielder?.yield("ERROR: connection failed")
        }
    }
}

// MARK: - RTKACMMIRoutineStateReporting (MMI delegate probe)

extension KazeGlassAccessory: RTKACMMIRoutineStateReporting {

    nonisolated func BBproMMIRoutine(
        _ routine: RTKACMMIRoutine,
        didReceiveUpdateOfButtonLockState isLocked: Bool
    ) {
        AppConfig.shared.log("[KazeGlass][PROBE] buttonLockState changed: isLocked=\(isLocked)")
    }

    // Note: The public header only declares didReceiveUpdateOfButtonLockState.
    // If the SDK delivers button action events through additional undocumented
    // protocol methods, they will surface here as unrecognised selector warnings
    // in the console — watch for those during probe testing.
}
```

---

### 4.3 Step 3 — Handle EMMC busy retry

Inside `KazeGlassAccessory`, add an error-aware capture wrapper. `DeviceFailure.failure(code: 5)` is the iOS SDK equivalent of Android error code 5 (glass EMMC still writing the previous file):

```swift
/// Capture with retry on EMMC-busy error (SDK error code 5).
/// Mirrors Android GlassPhotoManager retry behaviour — max 1 retry after 1.5 s.
private func captureWithRetry(using misc: MiscRoutine) async {
    do {
        try await performCapture(using: misc)
    } catch DeviceFailure.failure(let code) where code == 5 && captureRetryCount < maxCaptureRetries {
        captureRetryCount += 1
        AppConfig.shared.log("[KazeGlass] EMMC busy (code 5) — retrying in 1.5 s (attempt \(captureRetryCount))")
        try? await Task.sleep(nanoseconds: captureRetryDelaySeconds)
        await captureWithRetry(using: misc)
    } catch {
        captureRetryCount = 0
        AppConfig.shared.log("[KazeGlass] capture failed: \(error.localizedDescription)")
        statusYielder?.yield("ERROR: \(error.localizedDescription)")
    }
}
```

Replace `triggerCapture()`'s inner call with `captureWithRetry(using:)`.

---

### 4.4 Step 4 — Wire into `AccessoryManager`

**File:** `SeeSaw/Services/Accessory/AccessoryManager.swift`

```swift
// Add new property alongside the others
private let kazeGlass: KazeGlassAccessory

// Update init
init(
    bleAccessory: BLEService,
    localDevice: LocalDeviceAccessory,
    metaGlass: ExternalSDKAccessory,
    mfiCamera: ExternalSDKAccessory,
    kazeGlass: KazeGlassAccessory          // ← ADD
) {
    self.bleAccessory = bleAccessory
    self.localDevice  = localDevice
    self.metaGlass    = metaGlass
    self.mfiCamera    = mfiCamera
    self.kazeGlass    = kazeGlass          // ← ADD
    selectedType = UserDefaults.standard.selectedWearableType
}

// Update activeAccessory switch
var activeAccessory: any WearableAccessory {
    switch selectedType {
    case .iPhoneCamera: return localDevice
    case .aiSeeBLE:     return bleAccessory
    case .metaGlass:    return metaGlass
    case .mfiCamera:    return mfiCamera
    case .kazeGlass:    return kazeGlass   // ← ADD
    }
}

// Update disconnectAll
func disconnectAll() async {
    await bleAccessory.disconnect()
    await localDevice.disconnect()
    await metaGlass.disconnect()
    await mfiCamera.disconnect()
    await kazeGlass.disconnect()           // ← ADD
}
```

---

### 4.5 Step 5 — Wire into `AppDependencyContainer`

**File:** Find `AppDependencyContainer.swift` (or equivalent DI setup file).

```swift
// Add alongside the other accessory instantiations:
let kazeGlass = KazeGlassAccessory()

// Pass into AccessoryManager:
let accessoryManager = AccessoryManager(
    bleAccessory: bleAccessory,
    localDevice: localDevice,
    metaGlass: metaGlass,
    mfiCamera: mfiCamera,
    kazeGlass: kazeGlass    // ← ADD
)
```

No other changes are needed — `CompanionViewModel` receives `accessoryManager` already and will automatically route through `KazeGlassAccessory` when it is the selected type.

---

## 5. Settings UI Integration

### 5.1 Automatic appearance
Because `AccessoryPickerView` renders `WearableType.allCases` and `SettingsTabView` embeds `AccessoryPickerView`, the **KAZE Smart Glass** row appears automatically once the `WearableType.kazeGlass` case is added. No UI changes are needed.

### 5.2 Optional: SDK device discovery UI
The SDK ships a pre-built device picker (`RTKUIiOS.DeviceDiscoveryViewController`). To present it when the user taps Connect:

```swift
// In the view/coordinator that handles the connect button:
import RTKUIiOS

let navVC = DeviceDiscoveryViewController.instantiateNavigationController(
    forDiscovery: kazeGlass.connectionManager!
) { selectedConnection in
    // selectedConnection is the chosen AIDeviceConnection.
    // KazeGlassAccessory's delegate will handle activation automatically.
    dismiss(animated: true)
}
present(navVC, animated: true)
```

Alternatively, keep the existing "Connect to KAZE Glass" button in `CameraTabView` → calls `vm.startScanning()` → `startDiscovery()` → SDK scans automatically. The SDK-provided UI is optional.

---

## 6. Hardware Button Probing & Final Wiring

### 6.1 Why probing is needed
The Android SDK exposed button events via a clearly-named `onReceivedDeviceAction(Int)` callback. The iOS SDK's equivalent is not named in the public headers. Based on the SDK structure, events arrive through one of:

| Candidate | Where |
|-----------|-------|
| `RTKProfileConnectionDelegate.profileConnection(_:didReceiveMessage:)` | Raw GATT message bytes |
| `RTKACMMIRoutineStateReporting` additional methods | MMI delegate (may have undocumented methods) |
| `NotificationCenter` | SDK may post notifications — watch for `RTK*` notification names |

The probe callbacks in `KazeGlassAccessory` (Section 4.2) log all candidates. Run the app with a connected device and observe Xcode console output.

### 6.2 Probe test procedure
1. Build and install with the probe logging in place
2. Connect glass from Settings
3. Perform each gesture and note which probe log line appears:

| Gesture | Expected Android equivalent | Watch for in iOS console |
|---------|----------------------------|--------------------------|
| Single tap | `onDeviceTriggeredTakePhoto()` | `[PROBE] didReceiveMessage: XX XX ...` |
| Double tap | `onReceivedDeviceAction(2)` | `[PROBE]` with byte containing `0x02` |
| Long press + release | `onReceivedDeviceAction(4)` | `[PROBE]` with byte containing `0x04` |

### 6.3 Wiring after probe confirms format
Once you know which callback fires and what the byte format is, replace the probe comment block in `profileConnection(_:didReceiveMessage:)` with the actual routing:

```swift
nonisolated func profileConnection(
    _ connection: RTKProfileConnection,
    didReceiveMessage msgData: Data
) {
    // Example — adjust byte offsets to match observed output:
    guard msgData.count >= 1 else { return }
    let actionCode = msgData[0]   // or msgData[1], etc. — confirm from probe

    Task { @MainActor in
        switch actionCode {
        case 0x01:  // single tap → photo capture
            await self.triggerCapture()

        case 0x02:  // double tap → future: audio recording toggle
            AppConfig.shared.log("[KazeGlass] double tap received")

        case 0x04:  // long press → future: cancel activity
            AppConfig.shared.log("[KazeGlass] long press received")

        default:
            AppConfig.shared.log("[KazeGlass] unhandled action=0x\(String(format: "%02X", actionCode))")
        }
    }
}
```

> **Note on single tap:** On Android, single tap fired a **named callback** (`onDeviceTriggeredTakePhoto`), NOT through the generic `onReceivedDeviceAction`. On iOS, single tap may come through a **different** delegate method than double/long press. If the probe shows no raw message for single tap but the shutter fires anyway, the SDK may auto-call `snapshot()` internally — in which case you only need to subscribe to the result (see `onReceiveAvailableAssetsHandler` in `MiscRoutine`).

---

## 7. Full Photo Capture Flow Reference

```swift
// Complete capture sequence with error handling and retry:

func triggerCapture() async {
    guard let misc = deviceConnection?.miscRoutine else {
        statusYielder?.yield("ERROR: not connected")
        return
    }
    captureRetryCount = 0
    await captureWithRetry(using: misc)
}

private func captureWithRetry(using misc: MiscRoutine) async {
    do {
        // 1. Trigger glass shutter (async — waits for ACK from firmware)
        try await misc.snapshot()

        // 2. Query result metadata
        let picInfo = try await misc.getCapturedPicInfo()
        // picInfo.fileLen = JPEG file size in bytes
        // picInfo.rsvd    = SDK-internal handle

        // 3. Transfer JPEG from glass to phone
        let jpegData = try await misc.getPictureData(with: picInfo)
        // jpegData is a complete, valid JPEG

        captureRetryCount = 0

        // 4. Feed into existing pipeline
        imageYielder?.yield(jpegData)
        statusYielder?.yield("IMG_DONE")

    } catch DeviceFailure.failure(let code) where code == 5
              && captureRetryCount < maxCaptureRetries {
        // EMMC busy — glass still writing the previous file
        captureRetryCount += 1
        AppConfig.shared.log("[KazeGlass] EMMC busy retry \(captureRetryCount)/\(maxCaptureRetries)")
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        await captureWithRetry(using: misc)

    } catch DeviceFailure.timeout {
        captureRetryCount = 0
        statusYielder?.yield("ERROR: capture timed out")

    } catch DeviceFailure.deviceCancelled {
        captureRetryCount = 0
        // User cancelled or glass went to sleep — no action needed

    } catch {
        captureRetryCount = 0
        AppConfig.shared.log("[KazeGlass] capture error: \(error)")
        statusYielder?.yield("ERROR: \(error.localizedDescription)")
    }
}
```

### Alternative: CaptureImporter (bulk / streaming)
For importing multiple photos after a session, use `CaptureImporter` instead:

```swift
let importer = CaptureImporter(miscRoutine: misc)
let stream = try await importer.captureImport(
    to: URL.temporaryDirectory,
    timeout: 60
)
for try await photoURL in stream {
    let data = try Data(contentsOf: photoURL)
    imageYielder?.yield(data)
}
```

Not needed for the single-shot capture use case but useful for future batch import.

---

## 8. Error Handling Reference

| `DeviceFailure` case | Meaning | Action |
|---------------------|---------|--------|
| `.failure(code: 5)` | EMMC busy | Retry once after 1.5 s |
| `.timeout` | No response from glass | Surface error, allow retry |
| `.deviceCancelled` | Glass rejected (e.g. low battery) | Surface error |
| `.noAvailableTransport` | BT or WiFi not available | Check permissions, show alert |
| `.invalidResponse` | SDK parse error | Log and skip |
| `.notSupported` | Firmware too old | Show update prompt |

---

## 9. Connection State → SessionState Mapping

The existing `SessionState` enum in `SessionState.swift` covers all states. Map glass events to it via `statusStream`:

| Glass event | `statusStream` value | `SessionState` in `CompanionViewModel` |
|-------------|---------------------|---------------------------------------|
| Scan started | `"SCANNING"` | `.scanning` |
| Connected | `"CONNECTED"` | `.connected` |
| Photo downloading | `"RECEIVING"` | `.receivingImage` |
| Photo done | `"IMG_DONE"` | → `runDetectionPreview()` |
| Disconnected | `"DISCONNECTED"` | `.idle` |
| Error | `"ERROR: ..."` | `.error(message)` |

`CompanionViewModel.startScanning()` already subscribes to `statusStream` and maps these strings to `SessionState` — no changes needed there.

---

## 10. Known Limitations (from Android KAZE_0113 experience)

| Limitation | Detail | Workaround |
|-----------|--------|-----------|
| **A2DP audio muted** | Glass firmware silences A2DP audio while SDK SPP session is active. TTS and audio playback routed to glass are suppressed/throttled. | Route audio to phone speaker only while connected. Pending manufacturer fix. |
| **EMMC retry** | Taking two photos in rapid succession triggers error code 5 (EMMC still writing). | 1.5 s retry implemented above. |
| **Single photo only** | The glass captures one photo per press; continuous burst not supported. | Use `CaptureImporter` for post-session bulk import if needed. |
| **WiFi impact** | Live streaming (not used here) requires WiFi hotspot to glass, cutting phone internet. Photo capture (`snapshot()`) goes via BT — no WiFi required. | N/A for snapshot-only use case. |
| **Firmware version** | Some SDK callbacks may not be available on older firmware. Always guard with nil checks. | N/A for known KAZE_0113 hardware. |

---

## 11. Testing Checklist

Run in order; each step builds on the previous.

### Phase 1 — SDK integration
- [ ] Project builds without errors after adding `.xcframework` bundles
- [ ] `KazeGlassAccessory` compiles and all protocol requirements satisfied
- [ ] `WearableType.kazeGlass` appears in SettingsTabView accessory picker

### Phase 2 — Connection
- [ ] Selecting KAZE Glass in Settings → tapping Connect → glass discovered via BLE
- [ ] `statusStream` yields `"SCANNING"` then `"CONNECTING"` then `"CONNECTED"`
- [ ] `CompanionViewModel.sessionState` transitions to `.connected`
- [ ] Tapping Disconnect → glass disconnects, state returns to `.idle`

### Phase 3 — Button probe (instrumentation step)
- [ ] Single tap: Xcode console shows probe output → identify callback and byte format
- [ ] Double tap: Xcode console shows probe output → identify action code byte
- [ ] Long press + release: Xcode console shows probe output → identify action code byte
- [ ] Update routing in `profileConnection(_:didReceiveMessage:)` based on findings

### Phase 4 — Photo capture
- [ ] Single tap → `snapshot()` called → `getCapturedPicInfo()` returns metadata → `getPictureData()` returns non-empty JPEG
- [ ] JPEG yielded to `imageDataStream` → `CompanionViewModel.runDetectionPreview()` called
- [ ] `ScenePreviewView` shows face-blurred image with YOLO overlays
- [ ] "Generate Story" works through to story text output
- [ ] Rapid second tap → error code 5 caught → retry after 1.5 s succeeds
- [ ] `sendCommand("CAPTURE")` (in-app capture button) triggers same flow

### Phase 5 — Lifecycle
- [ ] App backgrounds while connected → on foreground, still connected
- [ ] Glass out of range → disconnect detected, `statusStream` yields `"DISCONNECTED"`, `sessionState` → `.idle`
- [ ] Re-connect after disconnect works without app restart

---

## 12. File Map

| File | Change |
|------|--------|
| `SeeSaw/Model/WearableAccessory.swift` | Add `WearableType.kazeGlass` + computed properties |
| `SeeSaw/Services/Accessory/KazeGlassAccessory.swift` | **CREATE** — full implementation |
| `SeeSaw/Services/Accessory/AccessoryManager.swift` | Add `kazeGlass` property + switch case + disconnectAll |
| `AppDependencyContainer.swift` (or equivalent) | Instantiate `KazeGlassAccessory` + inject into `AccessoryManager` |
| `Info.plist` | Add Bluetooth + local network usage descriptions |
| `SeeSaw.xcodeproj` | Add SDK frameworks + embed settings |

**No changes needed in:**
- `CompanionViewModel.swift` — protocol abstraction handles it
- `CameraTabView.swift` — connect button already routes through `activeAccessory`
- `SettingsTabView.swift` / `AccessoryPickerView.swift` — `allCases` handles it
- Privacy pipeline, story generation, audio — completely unchanged

---

## 13. SDK Paths Reference

| Component | Path |
|-----------|------|
| SDK root | `/AiSee/v3_kaze_glass/SDK/iOS/RTKAIDeviceConnectionSDK_1.3.0_dist-beta/` |
| Main Swift API | `RTKAIDeviceConnection.xcframework/.../RTKAIDeviceConnection.swiftmodule/arm64-apple-ios.swiftinterface` |
| MMI header | `RTKAudioConnectSDK.xcframework/.../Headers/RTKACMMIRoutine.h` |
| Button action codes | `RTKAudioConnectSDK.xcframework/.../Headers/RTKBBproType.h` |
| Connection manager header | `RTKLEFoundation.xcframework/.../Headers/RTKProfileConnectionManager.h` |
| Profile connection header | `RTKLEFoundation.xcframework/.../Headers/RTKProfileConnection.h` |
| Discovery UI header | `Demo/RTKUIiOS.framework/Headers/RTKUIiOS-Swift.h` |
| Demo (Swift) | `Demo/AIDeviceConnectionDemo/ViewController.swift` |

---

## 14. Key SDK Types Quick Reference

```swift
// Connection entry point
RTKProfileConnectionManager(delegate:)
    .registerConnectionClass(forInstantiateGATTPeripheral: AIDeviceConnection.self)
    .scanForPeripherals()

// Per-device connection (one instance per glass)
AIDeviceConnection
    .activate()                         // async throws — establish GATT
    .deactivate(completionHandler:)     // tear down
    .miscRoutine: MiscRoutine           // photo capture routines
    .MMIRoutine: RTKACMMIRoutine?       // button event routines
    .delegate: RTKProfileConnectionDelegate

// Photo capture (sequential async)
MiscRoutine
    .snapshot()                         // async throws — trigger shutter
    .getCapturedPicInfo()               // async throws → PicInfo
    .getPictureData(with picInfo:)      // async throws → Data (JPEG)

// Bulk import (optional)
CaptureImporter(miscRoutine:)
    .captureImport(to:timeout:)         // async throws → AsyncThrowingStream<URL, Error>

// Button action codes (RTKBBproType.h)
RTKBBproPeripheralMMIClickType_Single      = 0x01
RTKBBproPeripheralMMIClickType_Multi2      = 0x02   // double tap
RTKBBproPeripheralMMIClickType_LongPress   = 0x04   // long press
MMI_TAKE_LIFE_PHOTO                        = 0x25   // photo action

// Error handling
DeviceFailure.failure(code: 5)   // EMMC busy — retry
DeviceFailure.timeout            // no firmware response
DeviceFailure.deviceCancelled    // firmware rejected request
```
