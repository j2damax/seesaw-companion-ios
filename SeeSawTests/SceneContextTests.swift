// SceneContextTests.swift
// SeeSaw — Unit tests for SceneContext model

import Testing
import Foundation

@testable import SeeSaw

// MARK: - SceneContext construction tests

struct SceneContextTests {

    @Test func constructionFromScenePayload() {
        let payload = ScenePayload(
            objects: ["dog", "ball"],
            scene: ["park", "outdoor"],
            transcript: "I see a puppy",
            childAge: 5,
            childName: "Test",
            sessionId: UUID().uuidString
        )

        let context = SceneContext(from: payload)

        #expect(context.labels == ["dog", "ball"])
        #expect(context.sceneCategories == ["park", "outdoor"])
        #expect(context.transcript == "I see a puppy")
        #expect(context.childAge == 5)
    }

    @Test func constructionWithEmptyArrays() {
        let payload = ScenePayload(
            objects: [],
            scene: [],
            transcript: nil,
            childAge: 3,
            childName: "Test",
            sessionId: UUID().uuidString
        )

        let context = SceneContext(from: payload)

        #expect(context.labels.isEmpty)
        #expect(context.sceneCategories.isEmpty)
        #expect(context.transcript == nil)
        #expect(context.childAge == 3)
    }

    @Test func directInitialiserPreservesFields() {
        let context = SceneContext(
            labels: ["cat", "tree"],
            sceneCategories: ["garden"],
            transcript: "Hello kitty",
            childAge: 7
        )

        #expect(context.labels == ["cat", "tree"])
        #expect(context.sceneCategories == ["garden"])
        #expect(context.transcript == "Hello kitty")
        #expect(context.childAge == 7)
    }

    @Test func nilTranscriptPreserved() {
        let context = SceneContext(
            labels: ["car"],
            sceneCategories: ["road"],
            transcript: nil,
            childAge: 4
        )

        #expect(context.transcript == nil)
    }

    @Test func sendableConformance() {
        let context = SceneContext(
            labels: ["sun"],
            sceneCategories: ["sky"],
            transcript: nil,
            childAge: 6
        )
        let task = Task { @Sendable in
            return context.labels
        }
        _ = task
    }
}
