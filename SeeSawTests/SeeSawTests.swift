// SeeSawTests.swift
// SeeSaw — Unit tests

import Testing
import Foundation

@testable import SeeSaw

// MARK: - TransferChunk tests

struct TransferChunkTests {

    @Test func roundTrip() async throws {
        let original = Data([0x01, 0x02, 0x03, 0x04, 0x05])
        let chunks = TransferChunk.makeChunks(from: original, payloadSize: 3)
        #expect(chunks.count == 2)

        let reconstructed = chunks.map { $0.payload }.reduce(Data(), +)
        #expect(reconstructed == original)
    }

    @Test func headerParsing() async throws {
        var raw = Data()
        raw.append(contentsOf: [0x00, 0x01])
        raw.append(contentsOf: [0x00, 0x04])
        raw.append(0xAB)

        let chunk = try #require(TransferChunk(from: raw))
        #expect(chunk.seqNum == 1)
        #expect(chunk.total == 4)
        #expect(chunk.payload == Data([0xAB]))
    }

    @Test func rejectsTooShortPacket() async throws {
        let raw = Data([0x00, 0x01, 0x00])
        #expect(TransferChunk(from: raw) == nil)
    }
}

// MARK: - ChunkBuffer tests

struct ChunkBufferTests {

    @Test func inOrderReassembly() async throws {
        let buffer = ChunkBuffer()
        let payloads = [Data([1, 2]), Data([3, 4]), Data([5, 6])]
        let total = UInt16(payloads.count)

        var raw = Data()
        raw.append(contentsOf: [0x00, 0x00])
        raw.append(contentsOf: [0x00, UInt8(total)])
        raw.append(contentsOf: payloads[0])
        let chunk0 = try #require(TransferChunk(from: raw))

        raw = Data()
        raw.append(contentsOf: [0x00, 0x01])
        raw.append(contentsOf: [0x00, UInt8(total)])
        raw.append(contentsOf: payloads[1])
        let chunk1 = try #require(TransferChunk(from: raw))

        raw = Data()
        raw.append(contentsOf: [0x00, 0x02])
        raw.append(contentsOf: [0x00, UInt8(total)])
        raw.append(contentsOf: payloads[2])
        let chunk2 = try #require(TransferChunk(from: raw))

        #expect(buffer.add(chunk0) == nil)
        #expect(buffer.add(chunk1) == nil)
        let result = try #require(buffer.add(chunk2))
        #expect(result == Data([1, 2, 3, 4, 5, 6]))
    }

    @Test func resetClearsBuffer() async throws {
        let buffer = ChunkBuffer()
        var raw = Data([0x00, 0x01, 0x00, 0x01, 0xFF])
        let chunk = try #require(TransferChunk(from: raw))
        _ = buffer.add(chunk)
        buffer.reset()

        raw = Data([0x00, 0x00, 0x00, 0x01, 0xAB])
        let chunk2 = try #require(TransferChunk(from: raw))
        let result = try #require(buffer.add(chunk2))
        #expect(result == Data([0xAB]))
    }
}

// MARK: - ScenePayload encoding tests

struct ScenePayloadTests {

    @Test func encodesCorrectly() async throws {
        let payload = ScenePayload(
            objects: ["dinosaur", "book"],
            scene: ["bedroom", "indoor"],
            transcript: "let's go on an adventure",
            childAge: 5
        )

        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(ScenePayload.self, from: data)

        #expect(decoded.objects == payload.objects)
        #expect(decoded.scene == payload.scene)
        #expect(decoded.transcript == payload.transcript)
        #expect(decoded.childAge == payload.childAge)
    }

    @Test func nilTranscriptEncodes() async throws {
        let payload = ScenePayload(objects: [], scene: [], transcript: nil, childAge: 7)
        let data    = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(ScenePayload.self, from: data)
        #expect(decoded.transcript == nil)
    }
}

// MARK: - SessionState tests

struct SessionStateTests {

    @Test func activeStates() async throws {
        #expect(SessionState.scanning.isActive)
        #expect(SessionState.processingPrivacy.isActive)
        #expect(!SessionState.idle.isActive)
        #expect(!SessionState.connected.isActive)
    }

    @Test func connectedStates() async throws {
        #expect(SessionState.connected.isConnected)
        #expect(SessionState.receivingImage.isConnected)
        #expect(!SessionState.idle.isConnected)
        #expect(!SessionState.scanning.isConnected)
    }

    @Test func errorEquality() async throws {
        #expect(SessionState.error("foo") == SessionState.error("foo"))
        #expect(SessionState.error("foo") != SessionState.error("bar"))
    }

    @Test func scanningDisplayTitleIsGeneric() async throws {
        // Must not mention "AiSee" so it works for all accessory types
        #expect(!SessionState.scanning.displayTitle.contains("AiSee"))
    }
}

// MARK: - WearableType display property tests

struct WearableTypeTests {

    @Test func allTypesHaveNonEmptyDisplayProperties() async throws {
        for type in WearableType.allCases {
            #expect(!type.rawValue.isEmpty,             "rawValue empty for \(type)")
            #expect(!type.systemImage.isEmpty,          "systemImage empty for \(type)")
            #expect(!type.connectActionLabel.isEmpty,   "connectActionLabel empty for \(type)")
            #expect(!type.inputSourceDescription.isEmpty, "inputSourceDescription empty for \(type)")
        }
    }

    @Test func bluetoothRequirementIsCorrect() async throws {
        #expect(WearableType.aiSeeBLE.requiresBluetooth)
        #expect(!WearableType.iPhoneCamera.requiresBluetooth)
        #expect(!WearableType.metaGlass.requiresBluetooth)
        #expect(!WearableType.mfiCamera.requiresBluetooth)
    }

    @Test func allCasesCount() async throws {
        // Ensure no cases are accidentally removed
        #expect(WearableType.allCases.count == 4)
    }
}

// MARK: - UserDefaults selectedWearableType round-trip tests

struct UserDefaultsWearableTypeTests {

    @Test func roundTripAllTypes() async throws {
        let key = "selectedWearableType"
        let original = UserDefaults.standard.string(forKey: key)
        defer { UserDefaults.standard.set(original, forKey: key) }

        for type in WearableType.allCases {
            UserDefaults.standard.selectedWearableType = type
            #expect(UserDefaults.standard.selectedWearableType == type)
        }
    }

    @Test func unknownRawValueFallsBackToDefault() async throws {
        let key = "selectedWearableType"
        let original = UserDefaults.standard.string(forKey: key)
        defer { UserDefaults.standard.set(original, forKey: key) }

        UserDefaults.standard.set("NonExistentType", forKey: key)
        #expect(UserDefaults.standard.selectedWearableType == .iPhoneCamera)
    }
}


