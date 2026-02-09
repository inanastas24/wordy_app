//1
//  Flashcard.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI

struct Flashcard: View {
    let word: SavedWord
    @Binding var isFlipped: Bool
    @Binding var rotation: Double
    let isDarkMode: Bool
    
    var body: some View {
        ZStack {
            CardFace(
                title: word.original,
                subtitle: word.transcription.isEmpty || word.transcription == "[]" ? nil : word.transcription,
                hint: localizationManager.string(.tapToFlip),
                backgroundColor: isDarkMode ? Color(hex: "#2C2C2E") : Color.white,
                accentColor: Color(hex: "#4ECDC4"),
                textColor: isDarkMode ? .white : Color(hex: "#2C3E50"),
                isReversed: false
            )
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            
            CardFace(
                title: word.translation,
                subtitle: nil,
                hint: word.exampleSentence.isEmpty ? nil : word.exampleSentence,
                backgroundColor: Color(hex: "#4ECDC4"),
                accentColor: .white,
                textColor: .white,
                isReversed: true
            )
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
    }
}

struct CardFace: View {
    let title: String
    let subtitle: String?
    let hint: String?
    let backgroundColor: Color
    let accentColor: Color
    let textColor: Color
    var isReversed: Bool = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(backgroundColor)
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            
            VStack(spacing: 20) {
                Spacer()
                
                if isReversed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(accentColor.opacity(0.3))
                } else {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundColor(accentColor.opacity(0.3))
                }
                
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 20))
                        .foregroundColor(accentColor.opacity(0.8))
                }
                
                Spacer()
                
                if let hint = hint {
                    Text(hint)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isReversed ? .white.opacity(0.8) : (textColor == .white ? .white.opacity(0.8) : Color(hex: "#7F8C8D")))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .lineLimit(3)
                }
                
                Spacer()
            }
            .padding(30)
        }
        .scaleEffect(x: isReversed ? -1.0 : 1.0, y: 1.0)
    }
}

extension Flashcard {
    var localizationManager: LocalizationManager {
        LocalizationManager.shared
    }
}
