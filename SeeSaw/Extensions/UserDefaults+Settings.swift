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

