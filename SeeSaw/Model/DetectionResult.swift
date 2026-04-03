// DetectionResult.swift
// SeeSaw — Tier 2 companion app
//
// One detected object returned by the YOLO debug pass.
// boundingBox is in Vision normalised space:
//   origin = bottom-left, values 0–1 relative to image size.

import CoreGraphics

struct DetectionResult: Sendable {
    let label: String
    let confidence: Float
    let boundingBox: CGRect
}
