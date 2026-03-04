//
//  ContentView.swift
//  Wordy
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    @State private var onboardingStep: OnboardingStep = .appLanguage
    @State private var selectedAppLanguage: Language = .english

    
    @State private var showPaywall = false
    @State private var showMainApp = false
    
    enum OnboardingStep {
        case appLanguage
        case learningLanguage  // Це тепер LanguagePair, не LearningLanguage
        case paywall
        case permissions
        case mainApp
    }
    
    var body: some View {
        Group {
            switch onboardingStep {
            case .appLanguage:
                OnboardingAppLanguageSelectionView(
                    selectedLanguage: $selectedAppLanguage,
                    onContinue: {
                        localizationManager.setLanguage(selectedAppLanguage)
                        withAnimation {
                            onboardingStep = .learningLanguage
                        }
                    }
                )
                
            case .learningLanguage:
                // ВИКОРИСТОВУЄМО LearningLanguageSelectionView замість OnboardingLearningLanguageSelectionView
                LearningLanguageSelectionView(
                    onComplete: {
                        withAnimation {
                            onboardingStep = .paywall
                        }
                    }
                )
                .environmentObject(appState)
                .environmentObject(localizationManager)
                
            case .paywall:
                PaywallView(
                    isFirstTime: true,
                    onClose: {
                        withAnimation {
                            onboardingStep = .permissions
                        }
                    },
                    onSubscribe: {
                        withAnimation {
                            onboardingStep = .permissions
                        }
                    }
                )
                .environmentObject(subscriptionManager)
                .environmentObject(localizationManager)
                .onChange(of: subscriptionManager.isPremium) { _, isPremium in
                    if isPremium {
                        withAnimation {
                            onboardingStep = .permissions
                        }
                    }
                }
                .overlay(
                    VStack {
                        Spacer()
                        if subscriptionManager.isTrialActive {
                            Button {
                                withAnimation {
                                    onboardingStep = .permissions
                                }
                            } label: {
                                Text("Продовжити з тріалом")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "#4ECDC4"))
                                    .padding()
                            }
                        }
                    }
                )
                
            case .permissions:
                OnboardingPermissionsRequestView {
                    withAnimation {
                        onboardingStep = .mainApp
                    }
                }
                
            case .mainApp:
                MainTabView(selectedTab: .constant(0), deepLinkAction: .constant(nil), isFirstTime: false)
                    .environmentObject(appState)
                    .environmentObject(localizationManager)
                    .environmentObject(authViewModel)
                    .environmentObject(subscriptionManager)
            }
        }
    }
}

// MARK: - App Language Selection
struct OnboardingAppLanguageSelectionView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var selectedLanguage: Language
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            Color(hex: "#FFFDF5")
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                Text("🫧")
                    .font(.system(size: 80))
                
                Text("Wordy")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#2C3E50"))
                
                Text("Оберіть мову додатку")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "#2C3E50"))
                
                VStack(spacing: 12) {
                    ForEach(Language.allCases) { language in
                        // ВИКОРИСТОВУЄМО LanguageButton замість LanguageSelectionCard
                        LanguageButton(
                            language: language,
                            isSelected: selectedLanguage == language
                        ) {
                            selectedLanguage = language
                        }
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                Button(action: onContinue) {
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
        }
    }
}

// MARK: - Permissions Request View
struct OnboardingPermissionsRequestView: View {
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            Color(hex: "#FFFDF5")
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                Text("Останній крок")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(hex: "#2C3E50"))
                
                Text("Дозволи потрібні для повноцінної роботи додатку")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#7F8C8D"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                VStack(spacing: 16) {
                    OnboardingPermissionRow(icon: "camera.fill", title: "Камера", description: "Для сканування тексту")
                    OnboardingPermissionRow(icon: "mic.fill", title: "Мікрофон", description: "Для голосового пошуку")
                    OnboardingPermissionRow(icon: "waveform", title: "Розпізнавання мови", description: "Для перетворення мови в текст")
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                Button(action: {
                    requestAllPermissions()
                    onComplete()
                }) {
                    Text("Надати дозволи")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "#4ECDC4"))
                        .cornerRadius(25)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func requestAllPermissions() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            PermissionManager.shared.requestCameraPermission()
            PermissionManager.shared.requestMicrophonePermission()
            PermissionManager.shared.requestSpeechPermission()
            PermissionManager.shared.requestTrackingPermission()
        }
    }
}

// MARK: - Supporting Views

// ВИДАЛЕНО: OnboardingLearningLanguageSelectionView - використовуємо LearningLanguageSelectionView з окремого файлу

struct OnboardingPermissionRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "#4ECDC4"))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(hex: "#2C3E50"))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#7F8C8D"))
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}
