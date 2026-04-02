// TimelineTabView.swift
// SeeSaw — Tier 2 companion app
//
// "Timeline" tab on the home screen.
// Displays a reverse-chronological list of completed pipeline runs
// (each entry = one captured scene + story snippet).

import SwiftUI

struct TimelineTabView: View {

    var timeline: [TimelineEntry]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if timeline.isEmpty {
                    emptyState
                } else {
                    List(timeline) { entry in
                        TimelineRowView(entry: entry)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Timeline")
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 52))
                .foregroundStyle(.quaternary)
            Text("No stories yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Captured scenes will appear here after a story is generated.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Row

private struct TimelineRowView: View {

    let entry: TimelineEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(entry.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if !entry.sceneObjects.isEmpty {
                Text(entry.sceneObjects.joined(separator: " · "))
                    .font(.subheadline.bold())
                    .lineLimit(1)
            }

            if let snippet = entry.storySnippet {
                Text(snippet)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let sample = [
        TimelineEntry(sceneObjects: ["dinosaur", "book"], storySnippet: "Once upon a time in a magical library…"),
        TimelineEntry(sceneObjects: ["spaceship", "star"], storySnippet: "The little astronaut zoomed past Jupiter…")
    ]
    TimelineTabView(timeline: sample)
}
