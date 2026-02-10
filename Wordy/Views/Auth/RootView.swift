//  RootView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isCheckingAuth {
                LoadingScreen()
            } else if !authViewModel.isAuthenticated {
                RegistrationPromptView(
                    onComplete: {
                        print("✅ onComplete called - user authenticated")
                        // Нічого не треба робити, isAuthenticated вже true
                    },
                    onSkip: {
                            // Користувач пропустив - робимо anonymous login
                            UserDefaults.standard.set(true, forKey: "skippedRegistration")
                            Task {
                                await authViewModel.signInAnonymouslyForTesting()
                            }
                        }                )
            } else {
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
    @AppStorage("skippedRegistration") private var skippedRegistration = false
    
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
