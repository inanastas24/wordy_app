//1
//  SearchBar.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    let onSubmit: () -> Void
    @FocusState private var isFocused: Bool
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "#7F8C8D"))
            
            TextField(localizationManager.string(.enterWord), text: $text)
                .font(.system(size: 16))
                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                .focused($isFocused)
                .submitLabel(.search)
                .onSubmit(onSubmit)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#7F8C8D"))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 20)
    }
}
