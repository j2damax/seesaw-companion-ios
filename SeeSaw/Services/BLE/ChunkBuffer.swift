// ChunkBuffer.swift
// SeeSaw — Tier 2 companion app
//
// Reassembles out-of-order BLE image chunks into a complete JPEG.
// Uses a dictionary keyed by sequence number to support out-of-order delivery.

import Foundation

final class ChunkBuffer: @unchecked Sendable {

    // MARK: - State

    private var buffer: [Int: Data] = [:]
    private var expectedTotal: Int = 0

    // MARK: - Public interface

    /// Adds a chunk. Returns the fully reassembled Data when all chunks have arrived;
    /// returns nil if more chunks are still expected.
    func add(_ chunk: TransferChunk) -> Data? {
        expectedTotal = Int(chunk.total)
        buffer[Int(chunk.seqNum)] = chunk.payload
        guard buffer.count == expectedTotal, expectedTotal > 0 else { return nil }
        // Pre-allocate a single buffer and append in sequence to avoid O(n²) copies.
        var result = Data()
        result.reserveCapacity(buffer.values.reduce(0) { $0 + $1.count })
        for index in 0..<expectedTotal {
            guard let slice = buffer[index] else { return nil }
            result.append(slice)
        }
        return result
    }

    func reset() {
        buffer.removeAll()
        expectedTotal = 0
    }
}
