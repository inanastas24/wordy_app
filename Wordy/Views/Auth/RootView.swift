//  RootView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        Group {
            if authViewModel.isCheckingAuth {
                LoadingScreen()
            } else if !authViewModel.isAuthenticated {
                // Тільки авторизація - немає гостьового режиму
                LoginView()
            } else {
                // Користувач авторизований - показуємо онбординг або додаток
                AuthenticatedRootView()
            }
        }
    }
}

struct AuthenticatedRootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var appState: AppState
    
    @AppStorage("hasSelectedLanguage") private var hasSelectedLanguage = false
    @AppStorage("hasSelectedLearningLanguage") private var hasSelectedLearningLanguage = false
    
    var body: some View {
        Group {
            if !hasSelectedLanguage {
                LanguageSelectionView()
            } else if !hasSelectedLearningLanguage {
                LearningLanguageSelectionView()
            } else {
                MainTabView()
            }
        }
    }
}

struct LoadingScreen: View {
    var body: some View {
        ZStack {
            Color(hex: "#FFFDF5")
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(Color(hex: "#4ECDC4"))
            }
        }
    }
}
