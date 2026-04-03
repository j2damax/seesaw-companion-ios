// ChildProfile.swift
// SeeSaw — Tier 2 companion app
//
// Value type describing the child's profile used by the privacy pipeline
// and story generation. Stored field-by-field in UserDefaults for PoC.

struct ChildProfile: Sendable {
    var name: String
    var age: Int
    var preferences: [String]

    // MARK: - Preset preference topics shown during onboarding

    static let presetTopics: [String] = [
        "Dinosaurs", "Space", "Fairy Tales", "Animals",
        "Superheroes", "Ocean", "Robots", "Nature"
    ]
}
