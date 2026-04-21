// StoryRatingView.swift
// SeeSaw — Tier 2 companion app
//
// Post-session parent rating sheet. Shown after every completed story.
// Three 5-star criteria plus Skip/Submit buttons.

import SwiftUI

struct StoryRatingView: View {

    let beatsPlayed: Int
    let onSubmit: (Int, Int, Int) -> Void
    let onSkip: () -> Void

    @State private var enjoyment = 0
    @State private var ageAppropriateness = 0
    @State private var sceneGrounding = 0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("The story just finished — how did it go? Your ratings help improve SeeSaw.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init())
                        .padding(.vertical, 4)
                }

                Section("Story Quality") {
                    StarRatingRow(label: "Child enjoyed it", rating: $enjoyment)
                    StarRatingRow(label: "Age-appropriate", rating: $ageAppropriateness)
                    StarRatingRow(label: "Matched what was seen", rating: $sceneGrounding)
                }

                Section {
                    LabeledContent("Story beats", value: "\(beatsPlayed)")
                }
            }
            .navigationTitle("Rate This Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { onSkip() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        onSubmit(
                            max(1, enjoyment),
                            max(1, ageAppropriateness),
                            max(1, sceneGrounding)
                        )
                    }
                    .disabled(enjoyment == 0 || ageAppropriateness == 0 || sceneGrounding == 0)
                }
            }
        }
    }
}

// MARK: - Star row

private struct StarRatingRow: View {

    let label: String
    @Binding var rating: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .foregroundStyle(star <= rating ? .yellow : .secondary)
                        .font(.title3)
                        .onTapGesture { rating = star }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    StoryRatingView(
        beatsPlayed: 4,
        onSubmit: { _, _, _ in },
        onSkip: {}
    )
}
