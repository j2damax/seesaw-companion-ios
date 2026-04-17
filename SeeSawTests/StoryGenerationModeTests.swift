// StoryGenerationModeTests.swift
// SeeSaw — Unit tests for StoryGenerationMode enum

import Testing
import Foundation

@testable import SeeSaw

// MARK: - StoryGenerationMode tests

struct StoryGenerationModeTests {

    @Test func rawValueRoundTrip() {
        for mode in StoryGenerationMode.allCases {
            let recovered = StoryGenerationMode(rawValue: mode.rawValue)
            #expect(recovered == mode)
        }
    }

    @Test func caseIterableContainsAllModes() {
        let cases = StoryGenerationMode.allCases
        #expect(cases.count == 4)
        #expect(cases.contains(.onDevice))
        #expect(cases.contains(.gemma4OnDevice))
        #expect(cases.contains(.cloud))
        #expect(cases.contains(.hybrid))
    }

    @Test func displayNamesAreNonEmpty() {
        for mode in StoryGenerationMode.allCases {
            #expect(!mode.displayName.isEmpty)
        }
    }

    @Test func descriptionsAreNonEmpty() {
        for mode in StoryGenerationMode.allCases {
            #expect(!mode.description.isEmpty)
        }
    }

    @Test func rawValues() {
        #expect(StoryGenerationMode.onDevice.rawValue == "onDevice")
        #expect(StoryGenerationMode.gemma4OnDevice.rawValue == "gemma4OnDevice")
        #expect(StoryGenerationMode.cloud.rawValue == "cloud")
        #expect(StoryGenerationMode.hybrid.rawValue == "hybrid")
    }

    @Test func requiresNetworkFlags() {
        #expect(!StoryGenerationMode.onDevice.requiresNetwork)
        #expect(!StoryGenerationMode.gemma4OnDevice.requiresNetwork)
        #expect(StoryGenerationMode.cloud.requiresNetwork)
        #expect(StoryGenerationMode.hybrid.requiresNetwork)
    }

    @Test func invalidRawValueReturnsNil() {
        #expect(StoryGenerationMode(rawValue: "invalid") == nil)
        #expect(StoryGenerationMode(rawValue: "") == nil)
    }

    @Test func sendableConformance() {
        let mode = StoryGenerationMode.onDevice
        let task = Task { @Sendable in
            return mode.rawValue
        }
        _ = task
    }
}
