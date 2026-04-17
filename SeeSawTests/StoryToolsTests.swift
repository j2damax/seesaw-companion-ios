// StoryToolsTests.swift
// SeeSaw — Unit tests for Foundation Models Tool protocol conformances.
//
// Tests focus on argument validation, UserDefaults side-effects,
// and StoryBookmarkStore behaviour. Tools require no LLM session.
//
// All suites are nested under a single @Suite(.serialized) parent.
// BookmarkMomentTool.Arguments and SwitchSceneTool.Arguments are @Generable types.
// The @Generable macro uses FoundationModels' type schema registration, which
// calls internal dispatch locks on first use. Concurrent Swift Tasks hitting
// first-use initialization simultaneously trigger "unsafeForcedSync called from
// Swift Concurrent context" → EXC_GUARD Mach port violations. Serializing all
// tool tests prevents this without affecting any test's logic or assertions.

import Testing
import Foundation

@testable import SeeSaw

@Suite("Story Tools", .serialized)
struct StoryToolsTests {

// MARK: - Difficulty-level tests (serialized — all suites share UserDefaults.standard)
//
// AdjustDifficultyToolTests and StoryDifficultyLevelTests both read/write
// "storyDifficultyLevel" in UserDefaults.standard. Wrapping them under a single
// @Suite(.serialized) parent prevents cross-suite parallel contamination when
// Xcode runs tests on multiple simulator clones simultaneously.

@Suite(.serialized)
struct DifficultyLevelTests {

    // MARK: AdjustDifficultyTool

    struct AdjustDifficultyToolTests {

        @Test func callClampsLevelBelowOne() async throws {
            defer { UserDefaults.standard.removeObject(forKey: "storyDifficultyLevel") }
            let tool = AdjustDifficultyTool()
            let result = try await tool.call(arguments: .init(level: 0))
            #expect(result.contains("1"))
            #expect(UserDefaults.standard.storyDifficultyLevel == 1)
        }

        @Test func callClampsLevelAboveThree() async throws {
            defer { UserDefaults.standard.removeObject(forKey: "storyDifficultyLevel") }
            let tool = AdjustDifficultyTool()
            let result = try await tool.call(arguments: .init(level: 99))
            #expect(result.contains("3"))
            #expect(UserDefaults.standard.storyDifficultyLevel == 3)
        }

        @Test func callPersistsValidLevel() async throws {
            defer { UserDefaults.standard.removeObject(forKey: "storyDifficultyLevel") }
            let tool = AdjustDifficultyTool()
            for level in 1...3 {
                let result = try await tool.call(arguments: .init(level: level))
                #expect(result.contains("\(level)"))
                #expect(UserDefaults.standard.storyDifficultyLevel == level)
            }
        }

        @Test func callReturnsNonEmptyString() async throws {
            defer { UserDefaults.standard.removeObject(forKey: "storyDifficultyLevel") }
            let tool = AdjustDifficultyTool()
            let result = try await tool.call(arguments: .init(level: 2))
            #expect(!result.isEmpty)
        }
    }

    // MARK: UserDefaults storyDifficultyLevel

    struct StoryDifficultyLevelTests {

        @Test func defaultLevelIsTwo() {
            defer { UserDefaults.standard.removeObject(forKey: "storyDifficultyLevel") }
            UserDefaults.standard.removeObject(forKey: "storyDifficultyLevel")
            #expect(UserDefaults.standard.storyDifficultyLevel == 2)
        }

        @Test func roundTripValidValues() {
            defer { UserDefaults.standard.removeObject(forKey: "storyDifficultyLevel") }
            for level in 1...3 {
                UserDefaults.standard.storyDifficultyLevel = level
                #expect(UserDefaults.standard.storyDifficultyLevel == level)
            }
        }

        @Test func clampsBelowOne() {
            defer { UserDefaults.standard.removeObject(forKey: "storyDifficultyLevel") }
            UserDefaults.standard.storyDifficultyLevel = 0
            #expect(UserDefaults.standard.storyDifficultyLevel >= 1)
        }

        @Test func clampsAboveThree() {
            defer { UserDefaults.standard.removeObject(forKey: "storyDifficultyLevel") }
            UserDefaults.standard.storyDifficultyLevel = 10
            #expect(UserDefaults.standard.storyDifficultyLevel <= 3)
        }
    }
}

// MARK: - BookmarkMomentTool

struct BookmarkMomentToolTests {

    @Test func callAddsBookmarkToStore() async throws {
        await StoryBookmarkStore.shared.clear()

        let tool = BookmarkMomentTool()
        let description = "The child bravely jumped over the lava river."
        _ = try await tool.call(arguments: .init(description: description))

        let bookmarks = await StoryBookmarkStore.shared.bookmarks
        #expect(bookmarks.count == 1)
        #expect(bookmarks.first?.description == description)
    }

    @Test func callReturnsConfirmationString() async throws {
        await StoryBookmarkStore.shared.clear()

        let tool = BookmarkMomentTool()
        let result = try await tool.call(arguments: .init(description: "A funny moment"))
        #expect(result == "Moment bookmarked: A funny moment")
    }

    @Test func multipleCallsAccumulateBookmarks() async throws {
        await StoryBookmarkStore.shared.clear()

        let tool = BookmarkMomentTool()
        _ = try await tool.call(arguments: .init(description: "First moment"))
        _ = try await tool.call(arguments: .init(description: "Second moment"))

        let count = await StoryBookmarkStore.shared.bookmarks.count
        #expect(count == 2)
    }
}

// MARK: - SwitchSceneTool

struct SwitchSceneToolTests {

    @Test func callReturnsNewSettingInOutput() async throws {
        let tool = SwitchSceneTool()
        let result = try await tool.call(arguments: .init(newSetting: "outer space"))
        #expect(result.contains("outer space"))
    }

    @Test func callReturnsNonEmptyString() async throws {
        let tool = SwitchSceneTool()
        let result = try await tool.call(arguments: .init(newSetting: "an enchanted forest"))
        #expect(!result.isEmpty)
    }

    @Test func callDoesNotMutatePersistentState() async throws {
        let tool = SwitchSceneTool()
        let beforeDifficulty = UserDefaults.standard.storyDifficultyLevel
        _ = try await tool.call(arguments: .init(newSetting: "underwater"))
        #expect(UserDefaults.standard.storyDifficultyLevel == beforeDifficulty)
    }
}

// MARK: - StoryBookmarkStore

@Suite(.serialized)
struct StoryBookmarkStoreTests {

    @Test func addAndRetrieve() async {
        await StoryBookmarkStore.shared.clear()

        let description = "The hero found the magic key"
        await StoryBookmarkStore.shared.add(description)

        let bookmarks = await StoryBookmarkStore.shared.bookmarks
        #expect(bookmarks.count == 1)
        #expect(bookmarks.first?.description == description)
    }

    @Test func clearRemovesAll() async {
        await StoryBookmarkStore.shared.add("Test 1")
        await StoryBookmarkStore.shared.add("Test 2")
        await StoryBookmarkStore.shared.clear()

        #expect(await StoryBookmarkStore.shared.bookmarks.isEmpty)
    }

    @Test func bookmarkHasTimestamp() async {
        await StoryBookmarkStore.shared.clear()

        let before = Date()
        await StoryBookmarkStore.shared.add("Time check")
        let after = Date()

        let bookmark = await StoryBookmarkStore.shared.bookmarks.first
        #expect(bookmark?.timestamp != nil)
        if let ts = bookmark?.timestamp {
            #expect(ts >= before && ts <= after)
        }
    }
}

} // end StoryToolsTests
