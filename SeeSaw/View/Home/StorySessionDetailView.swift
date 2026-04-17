// StorySessionDetailView.swift
// SeeSaw — Detail screen for a stored story session.
//
// Sections:
//   1. Scene image (blurred / privacy-filtered)
//   2. Overview (child, date, mode, completion status)
//   3. Privacy Pipeline (stage latencies, face/object counts, PII summary)
//   4. Story Conversation (each beat with child's answer)
//   5. Research Metrics (average generation time, TTFT)
//
// Toolbar: like/dislike toggle, native share sheet, delete.

import SwiftUI
import SwiftData

struct StorySessionDetailView: View {

    let session: StorySessionRecord
    let store: StoryTimelineStore

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sceneImageSection
                overviewSection
                privacyPipelineSection
                conversationSection
                if !session.beats.isEmpty {
                    researchMetricsSection
                }
            }
            .padding()
        }
        .navigationTitle("\(session.displayChildName)'s Story")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
    }

    // MARK: - Scene image

    @ViewBuilder
    private var sceneImageSection: some View {
        VStack(spacing: 10) {
            // Original (unblurred) image — shown only if stored
            if let data = session.originalImageData,
               let uiImage = UIImage(data: data) {
                sceneImage(uiImage, label: "Original scene")
            }

            // Privacy-filtered (faces blurred) image
            if let data = session.capturedImageData,
               let uiImage = UIImage(data: data) {
                sceneImage(uiImage, label: "Privacy-filtered scene")
            }
        }
    }

    private func sceneImage(_ uiImage: UIImage, label: String) -> some View {
        // The pipeline's ciContext.jpegRepresentation encodes upright pixels but
        // retains the original EXIF orientation tag. Stripping it (forcing .up)
        // shows the correct upright pixels without an extra SwiftUI rotation.
        let display = uiImage.strippingExifOrientation()
        return Image(uiImage: display)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity, maxHeight: 200)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(alignment: .bottomLeading) {
                Text(label)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.black.opacity(0.55))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(10)
            }
    }

    // MARK: - Overview

    private var overviewSection: some View {
        SectionCard(title: "Overview", systemImage: "info.circle") {
            DetailRow("Child", value: "\(session.displayChildName), age \(session.childAge)")
            DetailRow("Date", value: session.createdAt.formatted(date: .long, time: .shortened))
            DetailRow("Story mode", value: session.storyMode.capitalized)
            DetailRow("Beats", value: "\(session.totalBeats)")
            DetailRow("Completed", value: session.isCompleted ? "Yes" : "Incomplete")
            if session.hadContextRestart {
                DetailRow("Context window", value: "Restarted mid-session")
                    .foregroundStyle(.orange)
            }
        }
    }

    // MARK: - Privacy Pipeline

    private var privacyPipelineSection: some View {
        SectionCard(title: "Privacy Pipeline", systemImage: "lock.shield") {
            // Detected objects
            if session.detectedObjects.isEmpty {
                DetailRow("Objects detected", value: "None")
            } else {
                DetailRow("Objects detected", value: session.detectedObjects.joined(separator: ", "))
            }

            // Scene labels
            if !session.sceneLabels.isEmpty {
                DetailRow("Scene labels", value: session.sceneLabels.joined(separator: ", "))
            }

            Divider().padding(.vertical, 2)

            // Face / privacy guarantee
            DetailRow("Faces detected", value: "\(session.facesDetected)")
            DetailRow("Faces blurred", value: "\(session.facesBlurred)")
            DetailRow("Raw data transmitted", value: "No ✓")
                .foregroundStyle(.green)

            Divider().padding(.vertical, 2)

            // Stage latencies
            VStack(alignment: .leading, spacing: 6) {
                Text("Stage latencies")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 2)
                LatencyBar(label: "Face detect", ms: session.faceDetectMs,    total: session.pipelineLatencyMs)
                LatencyBar(label: "Face blur",   ms: session.blurMs,          total: session.pipelineLatencyMs)
                LatencyBar(label: "YOLO detect", ms: session.yoloMs,          total: session.pipelineLatencyMs)
                LatencyBar(label: "Scene class", ms: session.sceneClassifyMs, total: session.pipelineLatencyMs)
                LatencyBar(label: "PII scrub",   ms: session.piiScrubMs,      total: session.pipelineLatencyMs)
            }

            DetailRow("Total pipeline", value: "\(Int(session.pipelineLatencyMs)) ms")
                .padding(.top, 2)

            Divider().padding(.vertical, 2)

            // PII summary
            if session.totalPiiTokensRedacted > 0 {
                HStack {
                    Image(systemName: "exclamationmark.shield")
                        .foregroundStyle(.orange)
                    DetailRow("PII tokens redacted", value: "\(session.totalPiiTokensRedacted)")
                        .foregroundStyle(.orange)
                }
            } else {
                DetailRow("PII tokens redacted", value: "0 — no PII detected")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Story Conversation

    private var conversationSection: some View {
        SectionCard(title: "Story Conversation", systemImage: "text.bubble.fill") {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(session.orderedBeats) { beat in
                    BeatCard(beat: beat, childName: session.displayChildName)
                    if beat.id != session.orderedBeats.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    // MARK: - Research Metrics

    private var researchMetricsSection: some View {
        let ordered = session.orderedBeats
        let avgGenMs = ordered.isEmpty ? 0.0
            : ordered.map(\.generationMs).reduce(0, +) / Double(ordered.count)
        let ttft = ordered.first?.ttftMs ?? 0

        return SectionCard(title: "Research Metrics", systemImage: "chart.bar") {
            DetailRow("Avg generation time", value: "\(Int(avgGenMs)) ms")
            DetailRow("TTFT (initial beat)", value: ttft > 0 ? "\(Int(ttft)) ms" : "—")
            DetailRow("Total beats", value: "\(ordered.count)")
            DetailRow("Context restarts", value: session.hadContextRestart ? "1" : "0")
            DetailRow("PII events", value: "\(session.totalPiiTokensRedacted) token(s) redacted")
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                store.toggleLike(session)
            } label: {
                Image(systemName: session.isLiked ? "heart.fill" : "heart")
                    .foregroundStyle(session.isLiked ? .pink : .primary)
            }

            ShareLink(item: session.shareText) {
                Image(systemName: "square.and.arrow.up")
            }

            if !session.trainingJSONL.isEmpty {
                ShareLink(
                    item: session.trainingJSONL,
                    preview: SharePreview(
                        "seesaw_training_\(session.id.uuidString.prefix(8)).jsonl",
                        image: Image(systemName: "brain")
                    )
                ) {
                    Image(systemName: "brain")
                }
            }

            Menu {
                Button(role: .destructive) {
                    store.delete(session)
                    dismiss()
                } label: {
                    Label("Delete Story", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
}

// MARK: - Section card container

private struct SectionCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Detail row

private struct DetailRow: View {
    let label: String
    let value: String

    init(_ label: String, value: String) {
        self.label = label
        self.value = value
    }

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(minWidth: 120, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

// MARK: - Latency bar

private struct LatencyBar: View {
    let label: String
    let ms: Double
    let total: Double

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return min(ms / total, 1.0)
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            // Scale a full-width bar rather than using GeometryReader
            // (GeometryReader inside ScrollView causes scroll stutter)
            RoundedRectangle(cornerRadius: 2)
                .fill(.teal)
                .frame(maxWidth: .infinity, maxHeight: 6)
                .scaleEffect(x: fraction, y: 1, anchor: .leading)
                .background(RoundedRectangle(cornerRadius: 2).fill(.quaternary))
                .frame(height: 6)
            Text("\(Int(ms)) ms")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(width: 48, alignment: .trailing)
        }
    }
}

// MARK: - Beat card

private struct BeatCard: View {
    let beat: StoryBeatRecord
    let childName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Beat header
            HStack {
                if beat.isInitialBeat {
                    Label("Opening", systemImage: "sparkles")
                        .font(.caption2.bold())
                        .foregroundStyle(.teal)
                } else if beat.isContextRestart {
                    Label("Story resumed", systemImage: "arrow.counterclockwise")
                        .font(.caption2.bold())
                        .foregroundStyle(.orange)
                } else {
                    Label("Beat \(beat.sequenceNumber)", systemImage: "text.badge.plus")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Text("\(Int(beat.generationMs)) ms")
                    if beat.ttftMs > 0 {
                        Text("· TTFT \(Int(beat.ttftMs)) ms")
                    }
                    if beat.isEnding {
                        Image(systemName: "flag.checkered")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }

            // Narration (what was spoken to the child via TTS)
            VStack(alignment: .leading, spacing: 4) {
                Label("Narration", systemImage: "speaker.wave.2.fill")
                    .font(.caption2.bold())
                    .foregroundStyle(.purple)
                Text(beat.storyText)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Question
            HStack(alignment: .top, spacing: 4) {
                Image(systemName: "questionmark.bubble")
                    .font(.caption)
                    .foregroundStyle(.teal)
                Text(beat.question)
                    .font(.caption)
                    .foregroundStyle(.teal)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Child's answer
            if let answer = beat.childAnswer, !answer.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "person.wave.2")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(childName): \"\(answer)\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if beat.piiTokensRedacted > 0 {
                        Image(systemName: "exclamationmark.shield")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            } else if !beat.isEnding {
                Text("(no answer recorded)")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
        }
    }
}

// MARK: - UIImage EXIF orientation fix

private extension UIImage {
    /// The pipeline's `ciContext.jpegRepresentation` writes upright pixels but can
    /// retain the original EXIF orientation tag from the camera source (e.g. .right
    /// for portrait captures). SwiftUI's `Image(uiImage:)` then applies the tagged
    /// rotation to already-upright pixels, rendering the image incorrectly.
    ///
    /// Stripping the tag — creating a new UIImage with the same CGImage pixels
    /// but `.up` orientation — displays the stored pixels as-is, which are correct.
    func strippingExifOrientation() -> UIImage {
        guard imageOrientation != .up, let cgImage = cgImage else { return self }
        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }
}

#Preview {
    let container = try! ModelContainer(for: StorySessionRecord.self, StoryBeatRecord.self)
    let session = StorySessionRecord(
        childName: "Vihas",
        childAge: 5,
        storyMode: "onDevice",
        originalImageData: nil,
        capturedImageData: nil,
        metrics: PrivacyMetricsData(
            objects: ["sofa", "table", "book"],
            scenes: ["living_room"],
            facesDetected: 0, facesBlurred: 0,
            pipelineLatencyMs: 143,
            faceDetectMs: 3, blurMs: 2, yoloMs: 135,
            sceneClassifyMs: 135, piiScrubMs: 0
        )
    )
    let beat = StoryBeatRecord(
        sequenceNumber: 0, localBeatIndex: 0,
        isInitialBeat: true, isContextRestart: false,
        storyText: "Vihas, imagine standing at the edge of a vast, mysterious forest.",
        question: "What do you feel most curious about in the forest?",
        isEnding: false, generationMs: 8376, ttftMs: 4680
    )
    beat.childAnswer = "I'm curious about the animals"
    beat.answerLength = 30
    session.beats.append(beat)
    container.mainContext.insert(session)

    return NavigationStack {
        StorySessionDetailView(session: session, store: StoryTimelineStore())
    }
    .modelContainer(container)
}
