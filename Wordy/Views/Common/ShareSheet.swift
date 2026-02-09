//1
//  ShareSheet.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
