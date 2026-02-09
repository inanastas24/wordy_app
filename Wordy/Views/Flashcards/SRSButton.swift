//1
//  SRSButton.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI

struct SRSButton: View {
    let quality: SRSService.ReviewQuality
    let color: Color
    let icon: String
    let label: String
    let interval: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                
                Text(interval)
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(color)
            .cornerRadius(12)
            .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
