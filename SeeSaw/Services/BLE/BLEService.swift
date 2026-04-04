// BLEService.swift
// SeeSaw — Tier 2 companion app
//
// GATT Central implementation. Scans for the AiSee headset, connects,
// subscribes to notifications, reassembles image chunks, and writes audio back.

import CoreBluetooth
import Foundation

// MARK: - BLEService

@MainActor
final class BLEService: NSObject, WearableAccessory {

    // MARK: - WearableAccessory identity

    let accessoryName = "AiSee BLE Wearable"
    let wearableType: WearableType = .aiSeeBLE

    var isConnected: Bool { connectedPeripheral != nil }

    // MARK: - Streams

    private(set) var imageDataStream: AsyncStream<Data>
    private(set) var statusStream: AsyncStream<String>

    private var imageYielder: AsyncStream<Data>.Continuation?
    private var statusYielder: AsyncStream<String>.Continuation?

    // MARK: - CoreBluetooth

    private var centralManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var imageDataCharacteristic: CBCharacteristic?
    private var audioDataCharacteristic: CBCharacteristic?
    private var commandCharacteristic: CBCharacteristic?
    private var statusCharacteristic: CBCharacteristic?

    // MARK: - Chunk reassembly

    private let chunkBuffer = ChunkBuffer()

    // MARK: - Callbacks (used by CompanionViewModel)

    var onConnected: (() -> Void)?
    var onDisconnected: (() -> Void)?

    // MARK: - Init

    override init() {
        imageDataStream = AsyncStream { $0.finish() }
        statusStream    = AsyncStream { $0.finish() }
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    /// Creates fresh AsyncStream/continuation pairs so a new `for await` consumer
    /// receives all values yielded during this connection session.
    private func resetStreams() {
        var imageCont: AsyncStream<Data>.Continuation!
        var statusCont: AsyncStream<String>.Continuation!
        imageDataStream = AsyncStream { imageCont = $0 }
        statusStream    = AsyncStream { statusCont = $0 }
        imageYielder  = imageCont
        statusYielder = statusCont
    }

    // MARK: - WearableAccessory conformance

    func startDiscovery() async throws {
        resetStreams()
        guard let cm = centralManager, cm.state == .poweredOn else {
            throw WearableError.bluetoothUnavailable
        }
        cm.scanForPeripherals(withServices: [BLEConstants.serviceUUID])
    }

    func stopDiscovery() async {
        centralManager?.stopScan()
    }

    func disconnect() async {
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        centralManager?.stopScan()
        imageYielder?.finish()
        imageYielder = nil
        statusYielder?.finish()
        statusYielder = nil
    }

    func sendAudio(_ data: Data) async throws {
        guard let peripheral = connectedPeripheral,
              let characteristic = audioDataCharacteristic else {
            throw WearableError.notConnected
        }
        let chunks = TransferChunk.makeChunks(from: data)
        for chunk in chunks {
            let packet = chunk.toPacket()
            peripheral.writeValue(packet, for: characteristic, type: .withoutResponse)
            try await Task.sleep(nanoseconds: BLEConstants.audioWritePaceNs)
        }
    }

    func sendCommand(_ command: String) async throws {
        guard let peripheral = connectedPeripheral,
              let characteristic = commandCharacteristic else {
            throw WearableError.notConnected
        }
        guard let data = command.data(using: .utf8) else { return }
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEService: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            connectedPeripheral = nil
            onDisconnected?()
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        guard let name = peripheral.name,
              name.hasPrefix(BLEConstants.peripheralNamePrefix) else { return }
        connectedPeripheral = peripheral
        central.stopScan()
        central.connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([BLEConstants.serviceUUID])
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        connectedPeripheral = nil
        imageDataCharacteristic = nil
        audioDataCharacteristic = nil
        commandCharacteristic = nil
        statusCharacteristic = nil
        onDisconnected?()
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        connectedPeripheral = nil
        onDisconnected?()
    }
}

// MARK: - CBPeripheralDelegate

extension BLEService: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == BLEConstants.serviceUUID {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            switch characteristic.uuid {
            case BLEConstants.imageDataTXUUID:
                imageDataCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            case BLEConstants.audioDataRXUUID:
                audioDataCharacteristic = characteristic
            case BLEConstants.commandRXUUID:
                commandCharacteristic = characteristic
            case BLEConstants.statusTXUUID:
                statusCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            case BLEConstants.mtuConfigUUID:
                    // Negotiate MTU: write 512 zero bytes to signal that the iPhone
                    // can accept up to 512-byte ATT PDUs (508 bytes payload + 4 byte header).
                    // AiSee reads this and adjusts its chunk size accordingly.
                    let mtuData = Data(repeating: 0, count: 512)
                    peripheral.writeValue(mtuData, for: characteristic, type: .withResponse)
            default:
                break
            }
        }
        onConnected?()
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard let data = characteristic.value else { return }
        switch characteristic.uuid {
        case BLEConstants.imageDataTXUUID:
            guard let chunk = TransferChunk(from: data) else { return }
            handleImageChunk(chunk)
        case BLEConstants.statusTXUUID:
            let status = String(data: data, encoding: .utf8) ?? ""
            statusYielder?.yield(status)
        default:
            break
        }
    }

    // MARK: - Private helpers

    private func handleImageChunk(_ chunk: TransferChunk) {
        if let fullImageData = chunkBuffer.add(chunk) {
            chunkBuffer.reset()
            imageYielder?.yield(fullImageData)
        }
    }
}
