//1
//  LearningLanguageSelectionView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 04.02.2026.
//

import SwiftUI

enum LearningLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case polish = "pl"
    case german = "de"
    case french = "fr"
    case spanish = "es"
    case italian = "it"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .polish: return "Polski"
        case .german: return "Deutsch"
        case .french: return "Français"
        case .spanish: return "Español"
        case .italian: return "Italiano"
        }
    }
    
    var flag: String {
        switch self {
        case .english: return "🇬🇧"
        case .polish: return "🇵🇱"
        case .german: return "🇩🇪"
        case .french: return "🇫🇷"
        case .spanish: return "🇪🇸"
        case .italian: return "🇮🇹"
        }
    }
}

struct LearningLanguageSelectionView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("learningLanguage") private var selectedLanguage: LearningLanguage = .english
    @AppStorage("hasSelectedLearningLanguage") private var hasSelectedLearningLanguage = false
    
    // Для режиму зміни мови (коли вже пройшли онбординг)
    var isChangeMode: Bool = false
    var onLanguageChanged: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            Color(hex: localizationManager.isDarkMode ? "#1C1C1E" : "#FFFDF5")
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Text("🎯")
                        .font(.system(size: 60))
                    
                    Text(localizationManager.string(.selectLearningLanguage))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Text(localizationManager.string(.canChangeLater))
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 10)
                
                // Grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        ForEach(LearningLanguage.allCases) { language in
                            LanguageSelectionCard(
                                flag: language.flag,
                                name: language.displayName,
                                isSelected: selectedLanguage == language
                            ) {
                                withAnimation(.spring(response: 0.35)) {
                                    selectedLanguage = language
                                    appState.learningLanguage = language.rawValue
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Continue Button
                Button {
                    if isChangeMode {
                        // Режим зміни мови - просто закриваємо
                        onLanguageChanged?()
                        dismiss()
                    } else {
                        // Режим онбордингу - переходимо далі
                        hasSelectedLearningLanguage = true
                    }
                } label: {
                    HStack {
                        Text(isChangeMode ? localizationManager.string(.save) : localizationManager.string(.startLearning))
                            .font(.system(size: 18, weight: .semibold))
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(hex: "#4ECDC4"))
                    .cornerRadius(25)
                    .shadow(color: Color(hex: "#4ECDC4").opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 10)
                .opacity(1.0) // Кнопка завжди активна
            }
        }
    }
}

struct LanguageSelectionCard: View {
    let flag: String
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(flag)
                    .font(.system(size: 50))
                
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : Color(hex: "#2C3E50"))
            }
            .frame(maxWidth: .infinity, minHeight: 110)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color(hex: "#4ECDC4") : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Color(hex: "#E0E0E0"), lineWidth: 2)
            )
            .shadow(
                color: isSelected ? Color(hex: "#4ECDC4").opacity(0.3) : Color.black.opacity(0.05),
                radius: isSelected ? 10 : 5,
                x: 0,
                y: isSelected ? 5 : 2
            )
            .overlay(
                Group {
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 24))
                                    .padding(12)
                            }
                            Spacer()
                        }
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}
