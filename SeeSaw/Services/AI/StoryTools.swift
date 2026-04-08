// StoryTools.swift
// SeeSaw — Tier 2 companion app
//
// Foundation Models Tool protocol implementations.
// Allows the on-device LLM to call app functions mid-generation:
//   - AdjustDifficultyTool — raise or lower vocabulary complexity
//   - BookmarkMomentTool   — mark memorable moments for the parent dashboard
//   - SwitchSceneTool      — transition to a new story setting

import FoundationModels

// MARK: - AdjustDifficultyTool

/// Lets the model respond to cues that a child finds the story too easy or hard.
/// The new difficulty level is persisted in UserDefaults and applies to future
/// story sessions (and to continuation prompts within the same session).
struct AdjustDifficultyTool: Tool {

    let name = "adjustDifficulty"
    let description = """
        Adjust the vocabulary and sentence complexity of the story. \
        Call this when the child seems confused (lower) or bored / too advanced (raise). \
        Level 1 = simple words for ages 3-5, 2 = moderate for ages 6-8, \
        3 = advanced for ages 9-12.
        """

    @Generable struct Arguments {
        @Guide(description: "Vocabulary complexity level: 1 (simple), 2 (moderate), or 3 (advanced)")
        var level: Int
    }

    func call(arguments: Arguments) async throws -> String {
        let clamped = max(1, min(3, arguments.level))
        UserDefaults.standard.storyDifficultyLevel = clamped
        return "Story vocabulary adjusted to difficulty level \(clamped)."
    }
}

// MARK: - BookmarkMomentTool

/// Lets the model tag memorable or significant story moments so parents can
/// review them later in the Settings → Story History dashboard.
struct BookmarkMomentTool: Tool {

    let name = "bookmarkMoment"
    let description = """
        Bookmark a memorable or meaningful story moment for the parent dashboard. \
        Call this when something notable happens — a brave choice, a funny line, \
        a child's creative answer — so parents can revisit it.
        """

    @Generable struct Arguments {
        @Guide(description: "A concise one-sentence description of the moment to bookmark")
        var description: String
    }

    func call(arguments: Arguments) async throws -> String {
        await StoryBookmarkStore.shared.add(arguments.description)
        return "Moment bookmarked: \(arguments.description)"
    }
}

// MARK: - SwitchSceneTool

/// Lets the model gracefully transition the story to a new setting when the
/// child expresses boredom or explicitly asks to go somewhere else.
struct SwitchSceneTool: Tool {

    let name = "switchScene"
    let description = """
        Transition the story to a completely new setting when the child is bored \
        or requests a change (e.g. "I want to go to space" or "this is boring"). \
        The new setting should feel like a natural story jump.
        """

    @Generable struct Arguments {
        @Guide(description: "The new scene or setting, e.g. 'a magical forest', 'outer space', 'an underwater kingdom'")
        var newSetting: String
    }

    func call(arguments: Arguments) async throws -> String {
        return "Scene changed to: \(arguments.newSetting). Continue the story in this new setting, starting with an exciting arrival."
    }
}
