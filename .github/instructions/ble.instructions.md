---
applyTo: "**/BLE/**/*.swift, **/BLEConstants.swift, **/TransferChunk.swift"
---

# BLE File Rules — seesaw-companion-ios

- Never hardcode UUID strings — always reference `BLEConstants.*UUID`
- Never change UUID values in `BLEConstants.swift` without syncing `seesaw-native/Constants.kt`
- Audio chunk writes must always use `CBCharacteristicWriteType.withoutResponse`
- Always include `Task.sleep(nanoseconds: 20_000_000)` between audio chunk writes
- `ChunkBuffer` must use a `[Int: Data]` dictionary keyed by `seqNum` for out-of-order support
- Never use `centralManager.scanForPeripherals(withServices: nil)` — always pass `[BLEConstants.serviceUUID]`
