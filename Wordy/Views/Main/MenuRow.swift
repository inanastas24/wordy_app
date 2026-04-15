//1
//  MenuRow.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI
import SwiftData
import StoreKit

// MARK: - MenuRow
struct MenuRow: View {
    let icon: String
    let title: String
    let color: String
    var isDarkMode: Bool = false
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: color).opacity(0.14))
                    .frame(width: 34, height: 34)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: color))
            }
            
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(isDarkMode ? .white : Color(hex: "#203044"))
                .lineLimit(1)
                .minimumScaleFactor(0.84)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "#7F8C8D").opacity(0.55))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - MenuItem Component
struct MenuItem: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#2C3E50"))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#7F8C8D"))
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 12)
        }
    }
}
