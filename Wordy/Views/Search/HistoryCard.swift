//1
//  HistoryCard.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI

struct HistoryCard: View {
    let item: SearchItem
    let isDarkMode: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: "#4ECDC4").opacity(isDarkMode ? 0.14 : 0.12))
                    .frame(width: 50, height: 50)

                Image(systemName: "text.quote")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "#4ECDC4"))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.word)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "#2C3E50"))
                
                Text(item.translation)
                    .font(.system(size: 16))
                    .foregroundColor(isDarkMode ? .gray : Color(hex: "#7F8C8D"))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#A8D8EA"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(isDarkMode ? Color.white.opacity(0.05) : Color.white.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(isDarkMode ? 0.06 : 0.7), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isDarkMode ? 0.12 : 0.05), radius: 14, x: 0, y: 8)
        .padding(.horizontal, 20)
    }
}
