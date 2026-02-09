//1
//  StatBadge.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI

struct StatBadge: View {
    let icon: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "#2C3E50"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.15))
        .cornerRadius(12)
    }
}
