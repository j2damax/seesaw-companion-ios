---
name: ble-gatt-central
description: >
  CoreBluetooth GATT Central implementation for seesaw-companion-ios.
  Use when asked to scan for AiSee, connect, subscribe to notifications,
  reassemble image chunks, or send audio chunks back over BLE.
---

# BLE GATT Central Skill

This skill teaches you how to implement CoreBluetooth GATT Central role for the `seesaw-companion-ios` project.

## When To Apply This Skill

- Writing or editing `BLEService.swift`
- Writing or editing `ChunkBuffer.swift`
- Adding BLE state restoration
- Debugging BLE connection or transfer issues
- Implementing background BLE support

## Step-by-Step: New BLEService Implementation

### 1. Create CBCentralManager with Background Restoration

```swift
actor BLEService: NSObject {
    private var centralManager: CBCentralManager!

    func setup() {
        let options: [String: Any] = [
            CBCentralManagerOptionRestoreIdentifierKey: "com.seesaw.companion.ble"
        ]
        centralManager = CBCentralManager(delegate: self,
                                          queue: .global(qos: .userInitiated),
                                          options: options)
    }
}
```

### 2. Scan Only When Powered On

```swift
extension BLEService: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            central.scanForPeripherals(
                withServices: [BLEConstants.serviceUUID],
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
            )
        }
    }
}
```

### 3. Connect on Discovery (Filter by Name Prefix)

```swift
nonisolated func centralManager(_ central: CBCentralManager,
                                 didDiscover peripheral: CBPeripheral,
                                 advertisementData: [String: Any],
                                 rssi RSSI: NSNumber) {
    guard peripheral.name?.hasPrefix("SEESAW_") == true else { return }
    central.stopScan()
    central.connect(peripheral, options: nil)
}
```

### 4. Discover Services After Connection

```swift
nonisolated func centralManager(_ central: CBCentralManager,
                                 didConnect peripheral: CBPeripheral) {
    peripheral.delegate = self
    peripheral.discoverServices([BLEConstants.serviceUUID])
}
```

### 5. Subscribe to Notifications

```swift
nonisolated func peripheral(_ peripheral: CBPeripheral,
                              didDiscoverCharacteristicsFor service: CBService,
                              error: Error?) {
    for char in service.characteristics ?? [] {
        switch char.uuid {
        case BLEConstants.imageDataTXUUID, BLEConstants.statusTXUUID:
            peripheral.setNotifyValue(true, for: char)
        case BLEConstants.mtuConfigUUID:
            // Write 512-byte MTU negotiation signal
            peripheral.writeValue(Data(repeating: 0, count: 512),
                                  for: char,
                                  type: .withResponse)
        default: break
        }
    }
}
```

### 6. Parse Incoming Chunks

```swift
nonisolated func peripheral(_ peripheral: CBPeripheral,
                              didUpdateValueFor characteristic: CBCharacteristic,
                              error: Error?) {
    guard let data = characteristic.value else { return }
    switch characteristic.uuid {
    case BLEConstants.imageDataTXUUID:
        guard let chunk = TransferChunk(from: data) else { return }
        Task { await handleChunk(chunk) }
    case BLEConstants.statusTXUUID:
        let status = String(data: data, encoding: .utf8) ?? ""
        Task { await handleStatus(status) }
    default: break
    }
}
```

### 7. Send Audio Chunks (With 20ms Pacing)

```swift
func sendAudioChunks(_ audioData: Data) async {
    guard let peripheral, let audioDataRX else { return }
    let payloadSize = 508
    var offset = 0
    var index = 0
    let total = Int(ceil(Double(audioData.count) / Double(payloadSize)))

    while offset < audioData.count {
        let end = min(offset + payloadSize, audioData.count)
        let payload = audioData[offset..<end]

        var packet = Data()
        packet.append(contentsOf: UInt16(index).bigEndianBytes)
        packet.append(contentsOf: UInt16(total).bigEndianBytes)
        packet.append(payload)

        peripheral.writeValue(packet, for: audioDataRX, type: .withoutResponse)

        offset += payloadSize
        index += 1
        try? await Task.sleep(nanoseconds: 20_000_000)  // 20ms — do not remove
    }
}
```

## Helper Extension

```swift
extension UInt16 {
    var bigEndianBytes: [UInt8] {
        [UInt8(self >> 8), UInt8(self & 0xFF)]
    }
}
```

## Checklist Before Committing BLE Changes

- [ ] `setNotifyValue(true)` called for both `imageDataTXUUID` and `statusTXUUID`
- [ ] `withoutResponse` used for audio writes (not `withResponse`)
- [ ] 20ms `Task.sleep` between every audio chunk write
- [ ] `CBCentralManagerOptionRestoreIdentifierKey` set on init
- [ ] Disconnect handler calls `centralManager.connect(peripheral)` for reconnect
- [ ] `BLEConstants.serviceUUID` used in `scanForPeripherals` (not `nil`)
