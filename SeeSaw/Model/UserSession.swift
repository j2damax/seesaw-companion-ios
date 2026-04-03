// UserSession.swift
// SeeSaw — Tier 2 companion app

struct UserSession: Sendable {
    let userID: String
    let fullName: String?
    let email: String?
    let provider: AuthProvider
}

enum AuthProvider: String, Sendable {
    case apple  = "apple"
    case google = "google"
}
