//1
//  SwipeIndicator.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 30.01.2026.
//

import SwiftUI

struct SwipeIndicator: View {
    let text: String
    let color: Color
    let rotation: Double
    let opacity: Double  // ← Double замість CGFloat
    
    var body: some View {
        Text(text)
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(opacity))
            )
            .rotationEffect(.degrees(rotation))
    }
}
