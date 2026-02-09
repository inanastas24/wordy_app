//1
//  RootView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var appState: AppState
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasSelectedLanguage") private var hasSelectedLanguage = false
    @AppStorage("hasSelectedLearningLanguage") private var hasSelectedLearningLanguage = false
    
    var body: some View {
        Group {
            if authViewModel.isCheckingAuth {
                LoadingScreen()
            } else if !hasSelectedLanguage {
                // Крок 1: Вибір мови додатка
                LanguageSelectionView()
            } else if !hasSelectedLearningLanguage {
                // Крок 2: Вибір мови вивчення
                LearningLanguageSelectionView()
            } else if !hasCompletedOnboarding {
                // Крок 3: Логін/Реєстрація
                LoginPromptView()
            } else {
                // Основний додаток
                MainTabView()
            }
        }
    }
}

struct LoadingScreen: View {
    var body: some View {
        ZStack {
            Color(hex: "#1C1C1E")
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(Color(hex: "#4ECDC4"))
                
                Text("Завантаження...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }
}
