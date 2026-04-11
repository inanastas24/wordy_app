//
//  ActionButton.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 23.02.2026.
//


import SwiftUI

struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let isDarkMode: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .center, spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isDarkMode ? Color.white.opacity(0.16) : Color.white.opacity(0.24))
                        .frame(width: 34, height: 34)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .center, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.82))
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 84, alignment: .top)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(isDarkMode ? 0.92 : 1),
                                color.opacity(isDarkMode ? 0.7 : 0.82)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(isDarkMode ? 0.08 : 0.28), lineWidth: 1)
            )
            .shadow(color: color.opacity(isDarkMode ? 0.18 : 0.24), radius: 18, x: 0, y: 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
