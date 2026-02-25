//1
//  LanguageSelectionView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 04.02.2026.
//

import SwiftUI

struct LanguageSelectionView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var appState: AppState
    @AppStorage("hasSelectedLanguage") private var hasSelectedLanguage = false
    @AppStorage("appLanguage") private var appLanguage: Language = .english
    
    let onComplete: () -> Void 
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 10) {
                    Text("🫧")
                        .font(.system(size: 80))
                    Text("Wordy")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#2C3E50"))
                }
                .padding(.top, 60)
                
                Spacer()
                
                VStack(spacing: 20) {
                    Text("Оберіть мову додатка")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "#2C3E50"))
                    
                    ForEach(Language.allCases) { language in
                        LanguageButton(
                            language: language,
                            isSelected: localizationManager.currentLanguage == language
                        ) {
                            localizationManager.setLanguage(language)
                            appLanguage = language
                            appState.appLanguage = language.rawValue
                        }
                    }
                }
                
                Spacer()
                
                Button {
                    hasSelectedLanguage = true
                    onComplete()
                } label: {
                    HStack {
                        Text("Продовжити")
                            .font(.system(size: 18, weight: .semibold))
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(hex: "#4ECDC4"))
                    .cornerRadius(25)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
            .background(Color(hex: "#FFFDF5").ignoresSafeArea())
        }
    }
}

struct LanguageButton: View {
    let language: Language
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Text(language.flag)
                    .font(.system(size: 32))
                
                Text(language.displayName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "#2C3E50"))
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "#4ECDC4"))
                        .font(.system(size: 24))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color(hex: "#4ECDC4").opacity(0.1) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color(hex: "#4ECDC4") : Color.gray.opacity(0.2), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 30)
    }
}
