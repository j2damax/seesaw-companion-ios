// ExternalSDKAccessory.swift
// SeeSaw — Tier 2 companion app
//
// Stub WearableAccessory for SDK-backed accessories (Meta Glass, MFi Camera).
// Each instance is created with a specific WearableType.
// All operations fail with `sdkUnavailable` until the real SDK is linked.
//
// To add real Meta Glass support:
//   1. Import the Meta Spatial SDK
//   2. Subclass or replace this file for .metaGlass
//   3. Implement `startDiscovery()` using the SDK's session API

import Foundation

@MainActor
final class ExternalSDKAccessory: WearableAccessory {

    // MARK: - WearableAccessory identity

    var accessoryName: String { wearableType.rawValue }
    let wearableType: WearableType

    var isConnected = false

    // MARK: - WearableAccessory callbacks

    var onConnected: (() -> Void)?
    var onDisconnected: (() -> Void)?

    // MARK: - Streams

    private(set) var imageDataStream: AsyncStream<Data>
    private(set) var statusStream: AsyncStream<String>

    private var imageYielder: AsyncStream<Data>.Continuation?
    private var statusYielder: AsyncStream<String>.Continuation?

    // MARK: - Init

    init(wearableType: WearableType) {
        self.wearableType = wearableType
        imageDataStream = AsyncStream { $0.finish() }
        statusStream    = AsyncStream { $0.finish() }
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
        throw WearableError.sdkUnavailable(wearableType.rawValue)
    }

    func stopDiscovery() async {}

    func disconnect() async {
        guard isConnected else { return }
        isConnected = false
        statusYielder?.yield("DISCONNECTED")
        imageYielder?.finish()
        imageYielder = nil
        statusYielder?.finish()
        statusYielder = nil
        onDisconnected?()
    }

    // MARK: - WearableAccessory: I/O

    func sendAudio(_ data: Data) async throws {
        throw WearableError.notConnected
    }

    func sendCommand(_ command: String) async throws {
        throw WearableError.notConnected
    }
}
