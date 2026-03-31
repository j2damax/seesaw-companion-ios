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

@MainActor
@Observable
final class AccessoryManager {

    // MARK: - State

    var selectedType: WearableType {
        didSet {
            guard selectedType != oldValue else { return }
            UserDefaults.standard.selectedWearableType = selectedType
        }
    }

    // MARK: - Accessory registry (one instance per type)

    private let registry: [WearableType: any WearableAccessory]

    // MARK: - Init

    init(
        bleAccessory: BLEService,
        localDevice: LocalDeviceAccessory,
        metaGlass: ExternalSDKAccessory,
        mfiCamera: ExternalSDKAccessory
    ) {
        registry = [
            .aiSeeBLE:     bleAccessory,
            .iPhoneCamera: localDevice,
            .metaGlass:    metaGlass,
            .mfiCamera:    mfiCamera
        ]
        selectedType = UserDefaults.standard.selectedWearableType
    }

    // MARK: - Active accessory

    var activeAccessory: any WearableAccessory {
        guard let accessory = registry[selectedType] else {
            preconditionFailure("No accessory registered for \(selectedType)")
        }
        return accessory
    }

    // MARK: - Convenience

    var availableTypes: [WearableType] { WearableType.allCases }

    func disconnectAll() async {
        for accessory in registry.values {
            await accessory.disconnect()
        }
    }
}
