// ScenePreviewView.swift
// SeeSaw — Tier 2 companion app
//
// Full-screen debug preview shown after "Capture Scene".
// Displays the face-blurred captured image with YOLO bounding boxes
// and confidence labels drawn on top.
// A Cancel button dismisses back to the camera preview.

import CoreImage
import SwiftUI

struct ScenePreviewView: View {

    let imageData: Data
    let detections: [DetectionResult]
    let onDismiss: () -> Void
    let onGenerateStory: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let cg = cgImage {
                imageWithOverlay(cgImage: cg)
            }
            controlsOverlay
        }
    }

    // MARK: - Image + bounding-box canvas

    private func imageWithOverlay(cgImage cg: CGImage) -> some View {
        GeometryReader { geo in
            let renderedRect = aspectFitRect(
                imageSize: CGSize(width: cg.width, height: cg.height),
                in: geo.size
            )
            ZStack(alignment: .topLeading) {
                Image(cg, scale: 1.0, orientation: .up, label: Text("Captured scene"))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geo.size.width, height: geo.size.height)

                Canvas { context, _ in
                    drawDetections(context: context, in: renderedRect)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }

    // MARK: - Controls overlay

    private var controlsOverlay: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onDismiss) {
                    Label("Cancel", systemImage: "xmark")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6),
                                    in: RoundedRectangle(cornerRadius: 10))
                }
                .padding()
                Spacer()
            }
            Spacer()
            labelChipsBar
            Button(action: onGenerateStory) {
                Label("Generate Story", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.teal, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var labelChipsBar: some View {
        Group {
            if detections.isEmpty {
                Text("No objects detected")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.5))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(detections.indices, id: \.self) { idx in
                            detectionChip(detections[idx])
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(Color.black.opacity(0.5))
            }
        }
    }

    private func detectionChip(_ detection: DetectionResult) -> some View {
        Text("\(detection.label) · \(Int(detection.confidence * 100))%")
            .font(.caption.bold())
            .foregroundStyle(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.green.opacity(0.9), in: Capsule())
    }

    // MARK: - Canvas drawing

    private func drawDetections(context: GraphicsContext, in rect: CGRect) {
        for detection in detections {
            let box = visionToView(detection.boundingBox, in: rect)
            context.stroke(Path(box), with: .color(.green), lineWidth: 2.5)
            let labelText = Text("\(detection.label) \(Int(detection.confidence * 100))%")
                .font(.caption2)
                .foregroundColor(.green)
            context.draw(labelText,
                         at: CGPoint(x: box.minX + 4, y: box.minY + 2),
                         anchor: .topLeading)
        }
    }

    // MARK: - Coordinate helpers

    /// Converts a Vision bounding box (bottom-left origin, 0–1) to view coordinates.
    private func visionToView(_ box: CGRect, in displayRect: CGRect) -> CGRect {
        CGRect(
            x: displayRect.origin.x + box.origin.x * displayRect.width,
            y: displayRect.origin.y + (1 - box.origin.y - box.height) * displayRect.height,
            width: box.width * displayRect.width,
            height: box.height * displayRect.height
        )
    }

    /// Returns the rect occupied by the image after aspect-fit scaling into containerSize.
    private func aspectFitRect(imageSize: CGSize, in containerSize: CGSize) -> CGRect {
        let imageAspect     = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height
        if imageAspect > containerAspect {
            let height = containerSize.width / imageAspect
            return CGRect(x: 0,
                          y: (containerSize.height - height) / 2,
                          width: containerSize.width,
                          height: height)
        } else {
            let width = containerSize.height * imageAspect
            return CGRect(x: (containerSize.width - width) / 2,
                          y: 0,
                          width: width,
                          height: containerSize.height)
        }
    }

    // MARK: - Image decoding

    private static let ciContext = CIContext()

    private var cgImage: CGImage? {
        guard let ciImage = CIImage(data: imageData) else { return nil }
        return Self.ciContext.createCGImage(ciImage, from: ciImage.extent)
    }
}

// MARK: - Preview

#Preview {
    ScenePreviewView(
        imageData: Data(),
        detections: [
            DetectionResult(label: "chair",  confidence: 0.92, boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)),
            DetectionResult(label: "laptop", confidence: 0.78, boundingBox: CGRect(x: 0.5, y: 0.4, width: 0.25, height: 0.3))
        ],
        onDismiss: {},
        onGenerateStory: {}
    )
}
