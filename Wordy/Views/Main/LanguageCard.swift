//1
//  LanguageCard.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI

struct LanguageCard: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    let flag: String
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Text(flag)
                    .font(.system(size: 32))
                Text(name)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "#4ECDC4"))
                        .font(.system(size: 24))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color(hex: "#4ECDC4").opacity(0.15) : (localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color(hex: "#4ECDC4") : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 30)
    }
}
