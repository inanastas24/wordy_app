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
        .background(isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
}
