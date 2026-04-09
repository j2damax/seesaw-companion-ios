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
            childAge: 5,
            sessionId: "test-session-id",
            query: "tell me a story",
            timestamp: "2026-04-04T09:00:00Z"
        )

        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(ScenePayload.self, from: data)

        #expect(decoded.objects == payload.objects)
        #expect(decoded.scene == payload.scene)
        #expect(decoded.transcript == payload.transcript)
        #expect(decoded.childAge == payload.childAge)
        #expect(decoded.sessionId == payload.sessionId)
        #expect(decoded.query == payload.query)
        #expect(decoded.timestamp == payload.timestamp)
    }

    @Test func nilTranscriptEncodes() async throws {
        let payload = ScenePayload(
            objects: [], scene: [], transcript: nil, childAge: 7,
            sessionId: "s", query: nil, timestamp: "2026-04-04T09:00:00Z"
        )
        let data    = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(ScenePayload.self, from: data)
        #expect(decoded.transcript == nil)
        #expect(decoded.query == nil)
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

    @Test func onboardingFilterExcludesMFiCamera() async throws {
        let onboarding = WearableType.allCases.filter { $0.isShownInOnboarding }
        #expect(!onboarding.contains(.mfiCamera))
        #expect(onboarding.contains(.iPhoneCamera))
        #expect(onboarding.contains(.aiSeeBLE))
        #expect(onboarding.contains(.metaGlass))
    }

    @Test func allCasesCount() async throws {
        // Ensure no cases are accidentally removed
        #expect(WearableType.allCases.count == 4)
    }
}

// MARK: - UserDefaults selectedWearableType round-trip tests

@Suite(.serialized)
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

// MARK: - UserDefaults onboarding flags tests

struct UserDefaultsOnboardingTests {

    @Test func termsAndOnboardingFlagsRoundTrip() async throws {
        let termsKey     = "hasAcceptedTerms"
        let onboardKey   = "hasCompletedOnboarding"
        let origTerms    = UserDefaults.standard.bool(forKey: termsKey)
        let origOnboard  = UserDefaults.standard.bool(forKey: onboardKey)
        defer {
            UserDefaults.standard.set(origTerms,   forKey: termsKey)
            UserDefaults.standard.set(origOnboard, forKey: onboardKey)
        }

        UserDefaults.standard.hasAcceptedTerms      = true
        UserDefaults.standard.hasCompletedOnboarding = true
        #expect(UserDefaults.standard.hasAcceptedTerms)
        #expect(UserDefaults.standard.hasCompletedOnboarding)

        UserDefaults.standard.hasAcceptedTerms      = false
        UserDefaults.standard.hasCompletedOnboarding = false
        #expect(!UserDefaults.standard.hasAcceptedTerms)
        #expect(!UserDefaults.standard.hasCompletedOnboarding)
    }
}

// MARK: - ChildProfile tests

struct ChildProfileTests {

    @Test func presetTopicsAreNonEmpty() async throws {
        #expect(!ChildProfile.presetTopics.isEmpty)
    }

    @Test func presetTopicsAreUnique() async throws {
        let unique = Set(ChildProfile.presetTopics)
        #expect(unique.count == ChildProfile.presetTopics.count)
    }
}

// MARK: - TimelineEntry tests

struct TimelineEntryTests {

    @Test func entryHasUniqueID() async throws {
        let a = TimelineEntry(sceneObjects: ["cat"], storySnippet: "Once…")
        let b = TimelineEntry(sceneObjects: ["cat"], storySnippet: "Once…")
        #expect(a.id != b.id)
    }

    @Test func entryPreservesFields() async throws {
        let objects  = ["dinosaur", "book"]
        let snippet  = "A long time ago…"
        let entry    = TimelineEntry(sceneObjects: objects, storySnippet: snippet)
        #expect(entry.sceneObjects == objects)
        #expect(entry.storySnippet == snippet)
    }

    @Test func nilSnippetIsAllowed() async throws {
        let entry = TimelineEntry(sceneObjects: [], storySnippet: nil)
        #expect(entry.storySnippet == nil)
    }
}
