// WearableAccessory.swift
// SeeSaw — Tier 2 companion app
//
// Hardware abstraction protocol. Conforming types represent physical input/output
// devices that can stream image data to the companion app and receive audio.
//
// Current conformors:
//   • BLEService         — AiSee headset over BLE GATT
//   • LocalDeviceAccessory — iPhone built-in camera + mic + speaker
//   • ExternalSDKAccessory — Meta Glass / MFi Camera (SDK stubs)

import Foundation

// MARK: - Protocol

/// @MainActor protocol so all conformors can be used from SwiftUI and ViewModels
/// without actor hops. Each conformor owns its own streams and manages its own
/// connection lifecycle.
@MainActor
protocol WearableAccessory: AnyObject {

    // MARK: Identity

    var accessoryName: String { get }
    var wearableType: WearableType { get }
    var isConnected: Bool { get }

    // MARK: Lifecycle callbacks (set by CompanionViewModel on each connect)

    var onConnected: (() -> Void)? { get set }
    var onDisconnected: (() -> Void)? { get set }

    // MARK: Streams

    /// Yields complete captured images (JPEG) ready for the privacy pipeline.
    var imageDataStream: AsyncStream<Data> { get }

    /// Yields status strings (see BLEConstants status values + "DISCONNECTED").
    var statusStream: AsyncStream<String> { get }

    // MARK: Lifecycle

    /// Start discovery / request permissions / open capture session.
    func startDiscovery() async throws

    /// Stop discovery / scanning without full teardown.
    func stopDiscovery() async

    /// Full teardown — release hardware resources.
    func disconnect() async

    // MARK: I/O

    /// Send PCM audio data to the accessory's output (BLE write, local speaker, etc.).
    func sendAudio(_ data: Data) async throws

    /// Send a control command string (see BLEConstants.cmd* values).
    func sendCommand(_ command: String) async throws
}

// MARK: - Wearable type catalogue

enum WearableType: String, CaseIterable, Sendable {
    case iPhoneCamera  = "iPhone Camera + Mic"
    case aiSeeBLE      = "AiSee (BLE)"
    case metaGlass     = "Meta Glass"
    case mfiCamera     = "MFi Camera Accessory"

    // MARK: Display helpers

    var systemImage: String {
        switch self {
        case .iPhoneCamera: return "iphone.gen2"
        case .aiSeeBLE:     return "antenna.radiowaves.left.and.right"
        case .metaGlass:    return "eyeglasses"
        case .mfiCamera:    return "camera"
        }
    }

    var connectActionLabel: String {
        switch self {
        case .iPhoneCamera: return "Use iPhone Camera"
        case .aiSeeBLE:     return "Connect to AiSee"
        case .metaGlass:    return "Connect to Meta Glass"
        case .mfiCamera:    return "Connect to MFi Camera"
        }
    }

    var inputSourceDescription: String {
        switch self {
        case .iPhoneCamera:
            return "Uses this iPhone's back camera and microphone as the scene input. No external hardware needed."
        case .aiSeeBLE:
            return "Connects to an AiSee wearable headset over Bluetooth LE. Requires Bluetooth permission."
        case .metaGlass:
            return "Connects to Meta smart glasses via SDK. Requires the Meta companion app."
        case .mfiCamera:
            return "Connects to an Apple-certified MFi camera accessory. Requires camera accessory hardware."
        }
    }

    var requiresBluetooth: Bool {
        switch self {
        case .aiSeeBLE: return true
        default:        return false
        }
    }
}

// MARK: - Wearable errors

enum WearableError: LocalizedError, Sendable {
    case bluetoothUnavailable
    case notConnected
    case characteristicUnavailable
    case transferFailed(String)
    case permissionDenied(String)
    case deviceUnavailable(String)
    case sdkUnavailable(String)

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
        case .permissionDenied(let resource):
            return "\(resource) access was denied. Please allow it in Settings."
        case .deviceUnavailable(let device):
            return "\(device) is not available on this device."
        case .sdkUnavailable(let sdkName):
            return "\(sdkName) SDK is not installed. Please install the companion app."
        }
    }
}

