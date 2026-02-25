//
//  SettingsPremiumBanner.swift
//  Wordy
//

import SwiftUI

struct SettingsPremiumBanner: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Системна іконка замість magic_book
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#FFD700"), Color(hex: "#FFA500")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(titleText)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitleText)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: "#2C3E50"),
                        Color(hex: "#4ECDC4").opacity(0.3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var titleText: String {
            switch localizationManager.currentLanguage {
            case .ukrainian: return "Спробуй Wordy Premium"
            case .polish: return "Wypróbuj Wordy Premium"
            case .english: return "Try Wordy Premium"
            }
        }
        
        private var subtitleText: String {
            switch localizationManager.currentLanguage {
            case .ukrainian: return "Отримай доступ до всіх функцій та необмежених перекладів"
            case .polish: return "Uzyskaj dostęp do wszystkich funkcji i nieograniczonych tłumaczeń"
            case .english: return "Access all features and unlimited translations"
            }
        }
    }

