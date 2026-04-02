// CameraPreviewView.swift
// SeeSaw — Tier 2 companion app
//
// UIViewRepresentable that wraps AVCaptureVideoPreviewLayer.
// Renders the live camera feed when an AVCaptureSession is running,
// or a grey placeholder when session is nil.

import AVFoundation
import SwiftUI

struct CameraPreviewView: UIViewRepresentable {

    var session: AVCaptureSession?

    func makeUIView(context: Context) -> PreviewView { PreviewView() }

    func updateUIView(_ view: PreviewView, context: Context) {
        view.setSession(session)
    }

    // MARK: - UIView subclass with AVCaptureVideoPreviewLayer as backing layer

    final class PreviewView: UIView {

        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var previewLayer: AVCaptureVideoPreviewLayer {
            guard let layer = layer as? AVCaptureVideoPreviewLayer else {
                // layerClass guarantees this type — if it ever fails, surface loudly in debug.
                assertionFailure("Expected AVCaptureVideoPreviewLayer as backing layer")
                return AVCaptureVideoPreviewLayer()
            }
            return layer
        }

        func setSession(_ session: AVCaptureSession?) {
            previewLayer.session      = session
            previewLayer.videoGravity = .resizeAspectFill
        }
    }
}
