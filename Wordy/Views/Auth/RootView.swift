//
//  RootView.swift
//  Wordy
//

import SwiftUI
import WidgetKit
import FirebaseAuth
import LocalAuthentication

// MARK: - Loading Screen
struct LoadingScreen: View {
    var body: some View {
        ZStack {
            Color(hex: "#1C1C1E")
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(Color(hex: "#4ECDC4"))
                
                Text("Wordy")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(hex: "#4ECDC4"))
            }
        }
    }
}

// MARK: - Deep Link
enum DeepLinkAction: Identifiable, Equatable {
    case camera
    case voice(autoStart: Bool)
    
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

// MARK: - App Flow
enum AppFlow: Equatable {
    case loading
    case login
    case appLanguage
    case learningLanguage
    case notifications
    case paywall
    case mainApp
    case biometricAuth
}

// MARK: - Root View
struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var appState: AppState
    
    @State private var currentFlow: AppFlow = .loading
    @State private var deepLinkAction: DeepLinkAction?
    @State private var selectedTab = 0
    @State private var isSubscriptionLoaded = false
    @State private var isAuthChecked = false
    
    // MARK: - AppStorage flags
    @AppStorage("hasSelectedLanguage") private var hasSelectedLanguage = false
    @AppStorage("hasSelectedLearningLanguage") private var hasSelectedLearningLanguage = false
    @AppStorage("hasSeenNotifications") private var hasSeenNotifications = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appLanguage") private var appLanguage: String = ""
    @AppStorage("learningLanguage") private var learningLanguage: String = ""
    
    var body: some View {
        content
            .onAppear {
                print("🚀 RootView appeared")
                checkInitialState()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openPaywallFromNotification)) { _ in
                if currentFlow == .mainApp {
                    // Показуємо paywall як sheet з mainApp
                } else {
                    currentFlow = .paywall
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .userDidLogout)) { _ in
                print("👤 User logged out, resetting flow")
                withAnimation {
                    resetStateOnLogout()
                    currentFlow = .login
                }
            }
            .onChange(of: authViewModel.isCheckingAuth) { _, isChecking in
                print("🔍 Auth checking changed: \(isChecking)")
                if !isChecking && !isAuthChecked {
                    isAuthChecked = true
                    handleAuthState()
                }
            }
            .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
                print("🔐 Auth state changed: \(isAuthenticated)")
                if isAuthenticated {
                    handleSuccessfulLogin()
                }
            }
            .onChange(of: isSubscriptionLoaded) { _, loaded in
                print("📦 Subscription loaded: \(loaded)")
                if loaded {
                    determineNextFlow()
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
    }
    
    @ViewBuilder
    private var content: some View {
        switch currentFlow {
        case .loading:
            LoadingScreen()
            
        case .login:
            LoginView(onComplete: {
                print("✅ LoginView onComplete called")
                handleSuccessfulLogin()
            })
            
        case .appLanguage:
            LanguageSelectionView(onComplete: {_ in 
                hasSelectedLanguage = true
                withAnimation {
                    determineNextFlow()
                }
            })
            
        case .learningLanguage:
            LearningLanguageSelectionView(onComplete: { selectedLearningLang in
                // ✅ Отримуємо вибрану мову вивчення і зберігаємо
                learningLanguage = selectedLearningLang
                appState.learningLanguage = selectedLearningLang
                hasSelectedLearningLanguage = true
                withAnimation {
                    determineNextFlow()
                }
            })
            
        case .notifications:
            NotificationsPermissionView(onComplete: {
                hasSeenNotifications = true
                withAnimation {
                    determineNextFlow()
                }
            })
            
        case .paywall:
            PaywallView(
                isFirstTime: true,
                onClose: {
                    print("⚠️ Paywall cannot be dismissed on first run")
                },
                onSubscribe: {
                    hasCompletedOnboarding = true
                    withAnimation {
                        currentFlow = .mainApp
                    }
                }
            )
            
        case .mainApp:
            MainTabView(
                selectedTab: $selectedTab,
                deepLinkAction: $deepLinkAction,
                isFirstTime: false
            )
            
        case .biometricAuth:
            BiometricAuthView {
                withAnimation {
                    handleAuthState()
                }
            }
        }
    }
    
    // MARK: - State Management
    
    private func resetStateOnLogout() {
        // ✅ Скидаємо тільки auth-related стани
        isAuthChecked = false
        isSubscriptionLoaded = false
        hasCompletedOnboarding = false
        // НЕ скидаємо: hasSelectedLanguage, hasSelectedLearningLanguage,
        // appLanguage, learningLanguage
    }
    
    private func handleSuccessfulLogin() {
        print("🎯 Handling successful login")
        
        // ✅ Відновлюємо збережені мовні налаштування
        restoreLanguageSettings()
        
        // Завантажуємо дані підписки
        loadSubscriptionData()
    }
    
    private func restoreLanguageSettings() {
        // Відновлюємо мову додатка
        if !appLanguage.isEmpty, let savedLanguage = Language(rawValue: appLanguage) {
            print("🌍 Restoring app language: \(appLanguage)")
            localizationManager.setLanguage(savedLanguage)
            hasSelectedLanguage = true
        }
        
        // Відновлюємо мову вивчення
        if !learningLanguage.isEmpty {
            print("📚 Restoring learning language: \(learningLanguage)")
            appState.learningLanguage = learningLanguage
            hasSelectedLearningLanguage = true
        } else {
            // Якщо learningLanguage порожній, скидаємо флаг
            print("📚 No learning language saved, resetting flag")
            hasSelectedLearningLanguage = false
        }
    }
    
    private func checkInitialState() {
        if Auth.auth().currentUser != nil &&
           authViewModel.biometricManager.isEnabled {
            currentFlow = .biometricAuth
        } else if !authViewModel.isCheckingAuth {
            isAuthChecked = true
            handleAuthState()
        }
    }
    
    private func handleAuthState() {
        if authViewModel.isAuthenticated {
            print("✅ User is authenticated, loading subscription...")
            loadSubscriptionData()
        } else {
            print("👤 User not authenticated, showing login")
            withAnimation {
                currentFlow = .login
            }
        }
    }
    
    private func loadSubscriptionData() {
        guard authViewModel.isAuthenticated else {
            withAnimation { currentFlow = .login }
            return
        }
        
        Task {
            await subscriptionManager.loadSubscriptionData()
                        
            await MainActor.run {
                isSubscriptionLoaded = true
            }
        }
    }
    
    private func determineNextFlow() {
        print("🔄 Determining next flow...")
        print("   - isAuthenticated: \(authViewModel.isAuthenticated)")
        print("   - hasSelectedLanguage: \(hasSelectedLanguage)")
        print("   - hasSelectedLearningLanguage: \(hasSelectedLearningLanguage)")
        print("   - hasSeenNotifications: \(hasSeenNotifications)")
        print("   - hasCompletedOnboarding: \(hasCompletedOnboarding)")
        print("   - appLanguage: \(appLanguage)")
        print("   - learningLanguage: \(learningLanguage)")
        print("   - status: \(subscriptionManager.status)")
        
        let nextFlow: AppFlow
        
        if !authViewModel.isAuthenticated {
            nextFlow = .login
        } else if !hasSelectedLanguage || appLanguage.isEmpty {
            nextFlow = .appLanguage
        } else if !hasSelectedLearningLanguage || learningLanguage.isEmpty {
            // ✅ Тепер правильно перевіряємо І флаг І значення
            nextFlow = .learningLanguage
        } else if !hasCompletedOnboarding {
            hasSeenNotifications = true
            
            if subscriptionManager.status == .unknown {
                nextFlow = .paywall
            } else {
                hasCompletedOnboarding = true
                nextFlow = .mainApp
            }
        } else {
            nextFlow = .mainApp
        }
        
        print("➡️ Next flow: \(nextFlow)")
     
        withAnimation {
            currentFlow = nextFlow
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "wordy" else { return }
        
        switch url.host {
        case "camera":
            deepLinkAction = .camera
            selectedTab = 0
        case "voice":
            deepLinkAction = .voice(autoStart: true)
            selectedTab = 0
        default:
            break
        }
    }
}

extension Notification.Name {
    static let userDidLogout = Notification.Name("userDidLogout")
}

struct BiometricAuthView: View {
    let onComplete: () -> Void
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            Color(hex: "#1C1C1E")
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color(hex: "#4ECDC4"))
                
                Text("Безпечний вхід")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Використовуйте \(authViewModel.biometricManager.biometricName) для швидкого доступу")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                Button {
                    Task {
                        let success = await authViewModel.authenticateWithBiometric()
                        if success {
                            await MainActor.run {
                                onComplete()
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: authViewModel.biometricManager.biometricType == .faceID ? "faceid" : "touchid")
                            .font(.system(size: 24))
                        
                        Text("Увійти з \(authViewModel.biometricManager.biometricName)")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(hex: "#4ECDC4"))
                    .cornerRadius(28)
                }
                .padding(.horizontal, 30)
                
                Button {
                    onComplete()
                } label: {
                    Text("Використати пароль")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .padding(.top, 10)
                
                Spacer()
            }
        }
        .onAppear {
            Task {
                let success = await authViewModel.authenticateWithBiometric()
                if success {
                    await MainActor.run {
                        onComplete()
                    }
                }
            }
        }
    }
}
