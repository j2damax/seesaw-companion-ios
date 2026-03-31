// WearableAccessory.swift
// SeeSaw — Tier 2 companion app
//
// Hardware abstraction protocol. Conforming types represent physical wearable
// devices that can stream image data to the companion app and receive audio.
// Current conformors: BLEService (AiSee headset).
// Future conformors: MetaGlassService, MFiCameraService, iPhoneCameraService.

import Foundation

// MARK: - Protocol

@MainActor
protocol WearableAccessory: AnyObject {

    var accessoryName: String { get }
    var wearableType: WearableType { get }
    var isConnected: Bool { get }

    func startDiscovery() async throws
    func stopDiscovery() async
    func disconnect() async
    func sendAudio(_ data: Data) async throws
    func sendCommand(_ command: String) async throws

    var imageDataStream: AsyncStream<Data> { get }
    var statusStream: AsyncStream<String> { get }
}

// MARK: - Wearable type catalogue

enum WearableType: String, CaseIterable, Sendable {
    case aiSeeBLE      = "AiSee (BLE)"
    case metaGlass     = "Meta Glass"
    case mfiCamera     = "MFi Camera Accessory"
    case iPhoneCamera  = "iPhone Camera + Mic"
}

// MARK: - Wearable errors

enum WearableError: LocalizedError, Sendable {
    case bluetoothUnavailable
    case notConnected
    case characteristicUnavailable
    case transferFailed(String)

    var errorDescription: String? {
        switch self {
        case .bluetoothUnavailable:
            return "Bluetooth is unavailable. Please enable it in Settings."
        case .notConnected:
            return "No wearable accessory is connected."
        case .characteristicUnavailable:
            return "Required BLE characteristic is not available."
        case .transferFailed(let reason):
            return "Transfer failed: \(reason)"
        }
    }
}
