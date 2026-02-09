//1
//  LearningLanguageCard.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI

struct LearningLanguageCard: View {
    let flag: String
    let nameLocal: String
    let isSelected: Bool
    let isDarkMode: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(flag)
                    .font(.system(size: 48))
                
                Text(nameLocal)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "#2C3E50"))
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "#4ECDC4"))
                        .font(.system(size: 24))
                        .padding(.top, 4)
                } else {
                    // Placeholder для вирівнювання висоти карток
                    Color.clear
                        .frame(height: 24)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color(hex: "#4ECDC4").opacity(0.15) : (isDarkMode ? Color(hex: "#2C2C2E") : Color.white))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color(hex: "#4ECDC4") : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
