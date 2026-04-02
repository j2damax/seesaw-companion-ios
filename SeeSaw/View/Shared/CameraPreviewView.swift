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
            // Safe: layerClass guarantees this cast succeeds.
            layer as! AVCaptureVideoPreviewLayer // swiftlint:disable:this force_cast
        }

        func setSession(_ session: AVCaptureSession?) {
            previewLayer.session      = session
            previewLayer.videoGravity = .resizeAspectFill
        }
    }
}
