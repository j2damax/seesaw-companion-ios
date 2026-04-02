// AccessoryPickerView.swift
// SeeSaw — Tier 2 companion app
//
// Reusable Form Section for selecting the active input source.
// Embed inside a SwiftUI Form or List.

import SwiftUI

struct AccessoryPickerView: View {

    var accessoryManager: AccessoryManager

    var body: some View {
        Section {
            ForEach(WearableType.allCases, id: \.self) { type in
                Button {
                    accessoryManager.selectedType = type
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: type.systemImage)
                            .frame(width: 28)
                            .foregroundStyle(accessoryManager.selectedType == type ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(type.rawValue)
                                .foregroundStyle(.primary)
                                .font(.body)
                            Text(type.inputSourceDescription)
                                .foregroundStyle(.secondary)
                                .font(.caption)
                                .lineLimit(2)
                        }

                        Spacer()

                        if accessoryManager.selectedType == type {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                                .font(.body.bold())
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Input Source")
        } footer: {
            Text("Changes take effect when you tap the connect button. Switching while connected requires a reconnect.")
                .font(.caption)
        }
    }
}

#Preview {
    let container = AppDependencyContainer()
    Form {
        AccessoryPickerView(accessoryManager: container.accessoryManager)
    }
}
