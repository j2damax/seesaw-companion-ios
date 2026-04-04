// AccessoryManager.swift
// SeeSaw — Tier 2 companion app
//
// Owns one concrete WearableAccessory instance per WearableType and exposes
// the currently-selected one as `activeAccessory`.
//
// Persists the selection to UserDefaults so it survives app restarts.
// Changing `selectedType` while connected does NOT auto-disconnect;
// the change takes effect on the next `startDiscovery()` call.

import Foundation
import AVFoundation

@MainActor
@Observable
final class AccessoryManager {

    // MARK: - State

    var selectedType: WearableType {
        didSet {
            guard selectedType != oldValue else { return }
            UserDefaults.standard.selectedWearableType = selectedType
            AppConfig.shared.log("selectedType changed: \(oldValue.displayName) → \(selectedType.displayName)")
        }
    }

    // MARK: - Accessory instances (one per type)

    private let bleAccessory: BLEService
    private let localDevice: LocalDeviceAccessory
    private let metaGlass: ExternalSDKAccessory
    private let mfiCamera: ExternalSDKAccessory

    // MARK: - Init

    init(
        bleAccessory: BLEService,
        localDevice: LocalDeviceAccessory,
        metaGlass: ExternalSDKAccessory,
        mfiCamera: ExternalSDKAccessory
    ) {
        self.bleAccessory = bleAccessory
        self.localDevice  = localDevice
        self.metaGlass    = metaGlass
        self.mfiCamera    = mfiCamera
        selectedType = UserDefaults.standard.selectedWearableType
    }

    // MARK: - Active accessory

    /// Returns the concrete accessory for the current `selectedType`.
    /// Exhaustive switch guarantees compile-time coverage of all `WearableType` cases.
    var activeAccessory: any WearableAccessory {
        switch selectedType {
        case .iPhoneCamera: return localDevice
        case .aiSeeBLE:     return bleAccessory
        case .metaGlass:    return metaGlass
        case .mfiCamera:    return mfiCamera
        }
    }

    // MARK: - Camera preview passthrough

    /// Returns an AVCaptureSession only when the active accessory is the local iPhone camera
    /// and it is currently running. Used by `CameraPreviewView`.
    var previewSession: AVCaptureSession? {
        guard selectedType == .iPhoneCamera else { return nil }
        return localDevice.previewSession
    }

    // MARK: - Convenience

    var availableTypes: [WearableType] { WearableType.allCases }

    func disconnectAll() async {
        await bleAccessory.disconnect()
        await localDevice.disconnect()
        await metaGlass.disconnect()
        await mfiCamera.disconnect()
    }
}
