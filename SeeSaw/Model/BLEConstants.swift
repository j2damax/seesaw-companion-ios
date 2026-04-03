// BLEConstants.swift
// SeeSaw — Tier 2 companion app
//
// UUID values MUST remain byte-for-byte identical to seesaw-native/Constants.kt.
// Never change these without syncing with the Android seesaw-native team.

import CoreBluetooth

enum BLEConstants {

    // MARK: - Service & Characteristic UUIDs

    static let serviceUUID      = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")
    static let imageDataTXUUID  = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567891")
    static let audioDataRXUUID  = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567892")
    static let commandRXUUID    = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567893")
    static let statusTXUUID     = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567894")
    static let mtuConfigUUID    = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567895")

    // MARK: - Commands (sent TO AiSee via commandRX)

    static let cmdCapture = "CAPTURE"
    static let cmdStop    = "STOP"
    static let cmdReset   = "RESET"

    // MARK: - Status strings (received FROM AiSee via statusTX)

    static let statusReady      = "READY"
    static let statusCapturing  = "CAPTURING"
    static let statusImgDone    = "IMG_DONE"
    static let statusAudioDone  = "AUDIO_DONE"
    static let statusBusy       = "BUSY"
    static let statusError      = "ERROR"
    static let statusTimeout    = "TIMEOUT"

    // MARK: - Transfer

    static let chunkPayloadSize = 508   // MTU 512 - 4 bytes header
    static let audioWritePaceNs: UInt64 = 20_000_000    // 20 ms

    // MARK: - Peripheral naming prefix

    static let peripheralNamePrefix = "SEESAW_"
}
