// UserDefaults+Settings.swift
// SeeSaw — Tier 2 companion app

import Foundation

extension UserDefaults {

    var cloudAgentURL: URL {
        get {
            let fallback = "https://your-cloud-run-url"
            let raw = string(forKey: "cloudAgentURL") ?? fallback
            guard let url = URL(string: raw) else {
                preconditionFailure("cloudAgentURL stored in UserDefaults is not a valid URL: \(raw)")
            }
            return url
        }
        set { set(newValue.absoluteString, forKey: "cloudAgentURL") }
    }

    var childAge: Int {
        get {
            let stored = integer(forKey: "childAge")
            return stored > 0 ? stored : 5
        }
        set { set(newValue, forKey: "childAge") }
    }
}
