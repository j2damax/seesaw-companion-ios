// OnboardingViewModel.swift
// SeeSaw — Tier 2 companion app
//
// Drives the 3-step post-sign-in onboarding flow:
//   Step 0 — Accessory Setup   (pick device, request permissions, connect)
//   Step 1 — Child Preferences (name, age, favourite topics)
//   Step 2 — Success           (welcome message, proceed to home)

import Foundation

@MainActor
@Observable
final class OnboardingViewModel {

    // MARK: - Step enum

    enum Step: Int, CaseIterable {
        case accessorySetup     = 0
        case childPreferences   = 1
        case success            = 2
    }

    // MARK: - Connection state (Step 0)

    enum ConnectionStatus: Equatable {
        case idle
        case connecting
        case connected
        case failed(String)

        var isConnected: Bool {
            if case .connected = self { return true }
            return false
        }
    }

    // MARK: - Observable state

    var currentStep: Step = .accessorySetup
    var connectionStatus: ConnectionStatus = .idle

    // Step 1 fields
    var childName: String = UserDefaults.standard.childName
    var childAge: Int = UserDefaults.standard.childAge
    var selectedPreferences: Set<String> = Set(UserDefaults.standard.childPreferences)

    // MARK: - Dependencies

    let accessoryManager: AccessoryManager
    private let coordinator: AppCoordinator

    // MARK: - Accessory types shown in onboarding (subset of all types)

    let onboardingAccessoryTypes: [WearableType] = [.iPhoneCamera, .aiSeeBLE, .metaGlass]

    // MARK: - Init

    init(accessoryManager: AccessoryManager, coordinator: AppCoordinator) {
        self.accessoryManager = accessoryManager
        self.coordinator      = coordinator
    }

    // MARK: - Step navigation

    func next() {
        guard let next = Step(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = next
    }

    func back() {
        guard let prev = Step(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prev
    }

    // MARK: - Step 0: Accessory connection

    func selectAccessoryType(_ type: WearableType) {
        accessoryManager.selectedType = type
        connectionStatus = .idle
    }

    func connectAccessory() {
        let wearable = accessoryManager.activeAccessory
        connectionStatus = .connecting

        wearable.onConnected    = { [weak self] in self?.connectionStatus = .connected }
        wearable.onDisconnected = { [weak self] in
            if case .connected = self?.connectionStatus { self?.connectionStatus = .idle }
        }

        Task {
            do {
                try await wearable.startDiscovery()
            } catch {
                connectionStatus = .failed(error.localizedDescription)
            }
        }
    }

    // MARK: - Step 1: Preference toggles

    func toggle(preference: String) {
        if selectedPreferences.contains(preference) {
            selectedPreferences.remove(preference)
        } else {
            selectedPreferences.insert(preference)
        }
    }

    // MARK: - Step 2: Complete onboarding

    func completeOnboarding() {
        UserDefaults.standard.childName         = childName
        UserDefaults.standard.childAge          = childAge
        UserDefaults.standard.childPreferences  = Array(selectedPreferences)
        UserDefaults.standard.hasCompletedOnboarding = true
        coordinator.onboardingCompleted()
    }
}
