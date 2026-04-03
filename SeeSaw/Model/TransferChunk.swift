// TransferChunk.swift
// SeeSaw — Tier 2 companion app
//
// Packet format (matches seesaw-native byte layout):
//   Bytes 0–1 : SEQ_NUM  (UInt16 big-endian)
//   Bytes 2–3 : TOTAL    (UInt16 big-endian)
//   Bytes 4–N : PAYLOAD  (raw data, up to 508 bytes at MTU 512)

import Foundation

struct TransferChunk: Sendable {
    let seqNum: UInt16
    let total: UInt16
    let payload: Data

    // MARK: - Decode from raw BLE packet

    init?(from data: Data) {
        guard data.count >= 4 else { return nil }
        seqNum = data[0..<2].withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }
        total  = data[2..<4].withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }
        payload = data.subdata(in: 4..<data.count)
    }

    // MARK: - Encode to raw BLE packet

    func toPacket() -> Data {
        var packet = Data(capacity: 4 + payload.count)
        packet.append(contentsOf: seqNum.bigEndianBytes)
        packet.append(contentsOf: total.bigEndianBytes)
        packet.append(payload)
        return packet
    }

    // MARK: - Build chunks from a large Data blob

    static func makeChunks(from data: Data, payloadSize: Int = BLEConstants.chunkPayloadSize) -> [TransferChunk] {
        let slices = stride(from: 0, to: data.count, by: payloadSize).map {
            data.subdata(in: $0..<min($0 + payloadSize, data.count))
        }
        let totalCount = UInt16(slices.count)
        return slices.enumerated().map { index, slice in
            TransferChunk(seqNum: UInt16(index), total: totalCount, payload: slice)
        }
    }

    // Private init used by makeChunks
    private init(seqNum: UInt16, total: UInt16, payload: Data) {
        self.seqNum  = seqNum
        self.total   = total
        self.payload = payload
    }
}

// MARK: - UInt16 big-endian helpers

private extension UInt16 {
    var bigEndianBytes: [UInt8] {
        [UInt8((self >> 8) & 0xFF), UInt8(self & 0xFF)]
    }
}
