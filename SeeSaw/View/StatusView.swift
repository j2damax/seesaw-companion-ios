// StatusView.swift
// SeeSaw — Tier 2 companion app
//
// Displays a human-readable status badge for each SessionState.
// Pure display — zero business logic.

import SwiftUI

struct StatusView: View {

    let state: SessionState
    let deviceName: String?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            statusIcon
            Text(state.displayTitle)
                .font(.headline)
                .multilineTextAlignment(.center)
            if let name = deviceName, state.isConnected {
                Text(name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Private

    @ViewBuilder
    private var statusIcon: some View {
        if state.isActive {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(iconColor)
        } else {
            Image(systemName: iconName)
                .font(.largeTitle)
                .foregroundStyle(iconColor)
        }
    }

    private var iconName: String {
        switch state {
        case .idle:          return "antenna.radiowaves.left.and.right.slash"
        case .connected:     return "checkmark.circle.fill"
        case .error:         return "exclamationmark.triangle.fill"
        default:             return "circle.dotted"
        }
    }

    private var iconColor: Color {
        switch state {
        case .connected:     return .green
        case .error:         return .red
        case .idle:          return .secondary
        default:             return .accentColor
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .connected:     return Color.green.opacity(0.12)
        case .error:         return Color.red.opacity(0.12)
        case .idle:          return Color.gray.opacity(0.12)
        default:             return Color.accentColor.opacity(0.10)
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        StatusView(state: .idle, deviceName: nil)
        StatusView(state: .connected, deviceName: "AiSee")
        StatusView(state: .processingPrivacy, deviceName: "AiSee")
        StatusView(state: .error("Cloud timeout"), deviceName: nil)
    }
    .padding()
}
