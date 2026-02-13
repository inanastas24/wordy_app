//
//  RootView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI
import WidgetKit

// MARK: - Deep Link Enum
enum DeepLinkAction: Identifiable, Equatable {
    case camera
    case voice(autoStart: Bool)  // Додаємо параметр autoStart
    
    var id: String {
        switch self {
        case .camera: return "camera"
        case .voice(let autoStart): return "voice_\(autoStart)"
        }
    }
    
    static func == (lhs: DeepLinkAction, rhs: DeepLinkAction) -> Bool {
        switch (lhs, rhs) {
        case (.camera, .camera): return true
        case (.voice(let lhsAuto), .voice(let rhsAuto)): return lhsAuto == rhsAuto
        default: return false
        }
    }
}

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var deepLinkAction: DeepLinkAction?
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if authViewModel.isCheckingAuth {
                LoadingScreen()
            } else if !authViewModel.isAuthenticated {
                RegistrationPromptView(
                    onComplete: { },
                    onSkip: {
                        UserDefaults.standard.set(true, forKey: "skippedRegistration")
                        Task {
                            await authViewModel.signInAnonymouslyForTesting()
                        }
                    }
                )
            } else {
                AuthenticatedRootView(
                    deepLinkAction: $deepLinkAction,
                    selectedTab: $selectedTab
                )
            }
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "wordy" else { return }
        
        switch url.host {
        case "camera":
            deepLinkAction = .camera
            selectedTab = 0  // Перемикаємо на вкладку пошуку
        case "voice":
            deepLinkAction = .voice(autoStart: true)  // Автозапуск голосового пошуку
            selectedTab = 0  // Перемикаємо на вкладку пошуку
        default:
            break
        }
    }
}

// MARK: - Loading Screen
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

// MARK: - Authenticated Root View
struct AuthenticatedRootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var appState: AppState
    
    @Binding var deepLinkAction: DeepLinkAction?
    @Binding var selectedTab: Int
    
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
                MainTabView(
                    selectedTab: $selectedTab,
                    deepLinkAction: $deepLinkAction
                )
            }
        }
    }
}
