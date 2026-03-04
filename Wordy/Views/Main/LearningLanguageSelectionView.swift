//
//  LearningLanguageSelectionView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 04.02.2026.
//

import SwiftUI

struct LearningLanguageSelectionView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    let onComplete: () -> Void
    
    // Для режиму зміни мови (коли вже пройшли онбординг)
    var isChangeMode: Bool = false
    var onLanguageChanged: (() -> Void)? = nil
    
    @State private var showSourcePicker = false
    @State private var showTargetPicker = false
    
    var body: some View {
        ZStack {
            Color(hex: localizationManager.isDarkMode ? "#1C1C1E" : "#FFFDF5")
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("🌐")
                        .font(.system(size: 60))
                    
                    Text(localizationManager.string(.selectLanguagesForTranslation))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Text(localizationManager.string(.translationWorksBothWays))
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 20)
                
                // Language Pair Selector (2 circles)
                languagePairSelector
                    .padding(.vertical, 30)
                
                // Helper text
                VStack(spacing: 8) {
                    Text(localizationManager.string(.tapFlagToChangeLanguage))
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 4) {
                        Text(localizationManager.string(.searchInLanguage))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(appState.languagePair.source.localizedName(in: localizationManager.currentLanguage))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#4ECDC4"))
                        Text(localizationManager.string(.translatesTo))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(appState.languagePair.target.localizedName(in: localizationManager.currentLanguage))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#4ECDC4"))
                    }
                    
                    HStack(spacing: 4) {
                        Text(localizationManager.string(.searchInLanguage))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(appState.languagePair.target.localizedName(in: localizationManager.currentLanguage))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#4ECDC4"))
                        Text(localizationManager.string(.translatesTo))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(appState.languagePair.source.localizedName(in: localizationManager.currentLanguage))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#4ECDC4"))
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Continue Button
                Button {
                    // 🎯 Тільки це! AppState автоматично встановить всі прапорці
                    appState.saveLanguagePair()
                    
                    if isChangeMode {
                        onLanguageChanged?()
                        dismiss()
                    } else {
                        onComplete()
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
                .padding(.bottom, 30)
            }
            
            // Language Pickers (overlays)
            if showSourcePicker {
                languagePicker(
                    title: localizationManager.string(.language1),
                    selectedLanguage: appState.languagePair.source,
                    onSelect: { language in
                        appState.setSourceLanguage(language)
                        withAnimation(.spring(response: 0.35)) {
                            showSourcePicker = false
                        }
                    },
                    onClose: {
                        withAnimation(.spring(response: 0.35)) {
                            showSourcePicker = false
                        }
                    }
                )
            }
            
            if showTargetPicker {
                languagePicker(
                    title: localizationManager.string(.language2),
                    selectedLanguage: appState.languagePair.target,
                    onSelect: { language in
                        appState.setTargetLanguage(language)
                        withAnimation(.spring(response: 0.35)) {
                            showTargetPicker = false
                        }
                    },
                    onClose: {
                        withAnimation(.spring(response: 0.35)) {
                            showTargetPicker = false
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Language Pair Selector
    private var languagePairSelector: some View {
        HStack(spacing: 30) {
            // Source Language Circle
            languageCircle(
                language: appState.languagePair.source,
                label: localizationManager.string(.language1),
                onTap: {
                    withAnimation(.spring(response: 0.35)) {
                        showSourcePicker = true
                    }
                }
            )
            
            // Swap Button
            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    appState.swapLanguages()
                }
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#4ECDC4").opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                }
            }
            
            // Target Language Circle
            languageCircle(
                language: appState.languagePair.target,
                label: localizationManager.string(.language2),
                onTap: {
                    withAnimation(.spring(response: 0.35)) {
                        showTargetPicker = true
                    }
                }
            )
        }
    }
    
    private func languageCircle(
        language: TranslationLanguage,
        label: String,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#4ECDC4").opacity(0.2), Color(hex: "#4ECDC4").opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "#4ECDC4").opacity(0.3), lineWidth: 2)
                        )
                    
                    Text(language.flag)
                        .font(.system(size: 50))
                }
                
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                
                Text(language.localizedName(in: localizationManager.currentLanguage))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Language Picker
    private func languagePicker(
        title: String,
        selectedLanguage: TranslationLanguage,
        onSelect: @escaping (TranslationLanguage) -> Void,
        onClose: @escaping () -> Void
    ) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Language List
                ScrollView {
                    VStack(spacing: 16) {
                        // Primary Languages Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text(localizationManager.string(.popularLanguages))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "#4ECDC4"))
                                .padding(.horizontal, 4)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(TranslationLanguage.primaryLanguages) { language in
                                    languageGridItem(language: language, isSelected: selectedLanguage == language, onSelect: onSelect)
                                }
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Other Languages Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text(localizationManager.string(.otherLanguages))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 4)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(TranslationLanguage.otherLanguages) { language in
                                    languageGridItem(language: language, isSelected: selectedLanguage == language, onSelect: onSelect)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(localizationManager.isDarkMode ? Color(hex: "#1C1C1E") : Color(hex: "#FFFDF5"))
                    .shadow(color: Color.black.opacity(0.2), radius: 40, x: 0, y: 20)
            )
            .padding(.horizontal, 20)
            .frame(maxHeight: 500)
        }
    }
    
    private func languageGridItem(
        language: TranslationLanguage,
        isSelected: Bool,
        onSelect: @escaping (TranslationLanguage) -> Void
    ) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onSelect(language)
        } label: {
            VStack(spacing: 6) {
                Text(language.flag)
                    .font(.system(size: 32))
                
                Text(language.localizedName(in: localizationManager.currentLanguage))
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : (localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50")))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "#4ECDC4") : (localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : (localizationManager.isDarkMode ? Color.gray.opacity(0.3) : Color(hex: "#E0E0E0")), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct LearningLanguageSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        LearningLanguageSelectionView(onComplete: {})
            .environmentObject(AppState())
            .environmentObject(LocalizationManager.shared)
    }
}
