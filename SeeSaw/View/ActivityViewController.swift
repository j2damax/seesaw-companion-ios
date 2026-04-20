// ActivityViewController.swift
// SeeSaw — Tier 2 companion app
//
// UIViewControllerRepresentable bridge for UIActivityViewController.
// Used to share multiple files simultaneously from the Settings Export All button.

import SwiftUI
import UIKit

struct ActivityViewController: UIViewControllerRepresentable {

    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
