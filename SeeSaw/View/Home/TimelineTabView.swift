// TimelineTabView.swift
// SeeSaw — Story Timeline tab.
//
// Shows all stored StorySessionRecords in reverse-chronological order via @Query.
// Each row provides object-detection tags, the story snippet, and metadata badges.
// Tapping a row navigates to StorySessionDetailView for the full session.
// Swipe-to-delete and "Delete All" are available in the toolbar.

import SwiftUI
import SwiftData

struct TimelineTabView: View {

    @Query(sort: \StorySessionRecord.createdAt, order: .reverse)
    private var sessions: [StorySessionRecord]

    private let store: StoryTimelineStore

    init(store: StoryTimelineStore) {
        self.store = store
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    emptyState
                } else {
                    sessionList
                }
            }
            .navigationTitle("Timeline")
            .toolbar { toolbarContent }
        }
    }

    // MARK: - Session list

    private var sessionList: some View {
        List {
            ForEach(sessions) { session in
                NavigationLink {
                    StorySessionDetailView(session: session, store: store)
                } label: {
                    SessionRowView(session: session)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .onDelete { indexSet in
                for index in indexSet {
                    store.delete(sessions[index])
                }
            }
        }
        .listStyle(.plain)
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
            Text("Captured scenes and full conversations will appear here after a story is generated.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !sessions.isEmpty {
                let allJSONL = sessions.map(\.trainingJSONL).filter { !$0.isEmpty }.joined(separator: "\n")
                if !allJSONL.isEmpty {
                    ShareLink(
                        item: allJSONL,
                        preview: SharePreview(
                            "seesaw_training_all.jsonl",
                            image: Image(systemName: "brain")
                        )
                    ) {
                        Label("Export Training Data", systemImage: "brain")
                            .font(.caption)
                    }
                }
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            if !sessions.isEmpty {
                Button("Delete All", role: .destructive) {
                    store.deleteAll()
                }
                .font(.caption)
            }
        }
    }
}

// MARK: - Session row

private struct SessionRowView: View {

    let session: StorySessionRecord

    private var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: session.createdAt, relativeTo: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            // Timestamp + badges
            // NOTE: Text(date, style: .relative) triggers "TimeDataFormattingStorage was
            // resolved without idiom" log spam on iOS 26 beta inside @Query-backed Lists.
            // Pre-formatting to a String avoids the live-update formatter machinery.
            HStack(spacing: 6) {
                Text(relativeTimeString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if session.isLiked {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(.pink)
                }
                if !session.isCompleted {
                    Image(systemName: "exclamationmark.circle")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                Text(session.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // Child name + age
            Text("\(session.displayChildName), age \(session.childAge)")
                .font(.subheadline.bold())

            // Object detection tags
            if !session.detectedObjects.isEmpty {
                objectTags(for: session.detectedObjects)
            }

            // Story snippet
            if let snippet = session.storySnippet {
                Text(snippet)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Metadata row
            metadataRow
        }
        .padding(.vertical, 4)
    }

    private func objectTags(for objects: [String]) -> some View {
        // Avoid horizontal ScrollView inside List — it steals vertical scroll gestures.
        // Show up to 5 tags in a clipped HStack instead.
        HStack(spacing: 4) {
            ForEach(objects.prefix(5), id: \.self) { object in
                Text(object)
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.teal.opacity(0.15))
                    .foregroundStyle(.teal)
                    .clipShape(Capsule())
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metadataRow: some View {
        HStack(spacing: 4) {
            Label("\(session.totalBeats) beats", systemImage: "text.bubble")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text("·")
                .font(.caption2)
                .foregroundStyle(.quaternary)
            Text(session.storyMode)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            if session.hadContextRestart {
                Text("· restarted")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
            if session.totalPiiTokensRedacted > 0 {
                Text("· PII redacted")
                    .font(.caption2)
                    .foregroundStyle(.teal)
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: StorySessionRecord.self, StoryBeatRecord.self,
        configurations: config
    )
    let session = StorySessionRecord(
        childName: "Vihas", childAge: 5, storyMode: "onDevice",
        originalImageData: nil, capturedImageData: nil,
        metrics: PrivacyMetricsData(
            objects: ["sofa", "table", "book"], scenes: ["living_room"],
            facesDetected: 0, facesBlurred: 0, pipelineLatencyMs: 143,
            faceDetectMs: 3, blurMs: 2, yoloMs: 135, sceneClassifyMs: 135, piiScrubMs: 0
        )
    )
    session.isCompleted = true
    session.totalBeats = 3
    container.mainContext.insert(session)

    return TimelineTabView(store: StoryTimelineStore())
        .modelContainer(container)
}
