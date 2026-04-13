// UserDefaults+Settings.swift
// SeeSaw — Tier 2 companion app

import Foundation

extension UserDefaults {

    // MARK: - Cloud agent

    var cloudAgentURL: URL {
        get {
            let fallbackString = "https://your-cloud-run-url"
            let raw = string(forKey: "cloudAgentURL") ?? fallbackString
            if let url = URL(string: raw) { return url }
            // Stored value is malformed — fall back to the hardcoded default.
            // This is safe: fallbackString is a valid URL constant.
            guard let fallback = URL(string: fallbackString) else {
                return URL(fileURLWithPath: "/")  // unreachable in practice
            }
            return fallback
        }
        set { set(newValue.absoluteString, forKey: "cloudAgentURL") }
    }

    var cloudAgentKey: String {
        get { string(forKey: "cloudAgentKey") ?? "" }
        set { set(newValue, forKey: "cloudAgentKey") }
    }

    // MARK: - Child profile

    var childAge: Int {
        get {
            let stored = integer(forKey: "childAge")
            return stored > 0 ? stored : 5
        }
        set { set(newValue, forKey: "childAge") }
    }

    var childName: String {
        get { string(forKey: "childName") ?? "" }
        set { set(newValue, forKey: "childName") }
    }

    var childPreferences: [String] {
        get { stringArray(forKey: "childPreferences") ?? [] }
        set { set(newValue, forKey: "childPreferences") }
    }

    // MARK: - Story generation

    /// Vocabulary difficulty level set by AdjustDifficultyTool (1=simple, 2=moderate, 3=advanced).
    var storyDifficultyLevel: Int {
        get {
            let stored = integer(forKey: "storyDifficultyLevel")
            return stored > 0 ? min(stored, 3) : 2
        }
        set { set(max(1, min(3, newValue)), forKey: "storyDifficultyLevel") }
    }

    var storyMode: StoryGenerationMode {
        get {
            let raw = string(forKey: "storyMode") ?? StoryGenerationMode.onDevice.rawValue
            return StoryGenerationMode(rawValue: raw) ?? .onDevice
        }
        set { set(newValue.rawValue, forKey: "storyMode") }
    }

    // MARK: - Accessory

    var selectedWearableType: WearableType {
        get {
            let raw = string(forKey: "selectedWearableType") ?? WearableType.iPhoneCamera.rawValue
            return WearableType(rawValue: raw) ?? .iPhoneCamera
        }
        set { set(newValue.rawValue, forKey: "selectedWearableType") }
    }

    // MARK: - Onboarding / terms flow

    var hasAcceptedTerms: Bool {
        get { bool(forKey: "hasAcceptedTerms") }
        set { set(newValue, forKey: "hasAcceptedTerms") }
    }

    var hasCompletedOnboarding: Bool {
        get { bool(forKey: "hasCompletedOnboarding") }
        set { set(newValue, forKey: "hasCompletedOnboarding") }
    }
}

