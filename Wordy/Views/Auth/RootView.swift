//
//  RootView.swift
//  Wordy
//


import SwiftUI
import WidgetKit
import FirebaseAuth
import LocalAuthentication
import FirebaseCrashlytics

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
    @AppStorage("hasSelectedLanguagePair") private var hasSelectedLanguagePair = false
    @AppStorage("hasSeenNotifications") private var hasSeenNotifications = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appLanguage") private var appLanguage: String = ""
    
    // Для LanguagePair
    @AppStorage("sourceLanguage") private var sourceLanguage: String = ""
    @AppStorage("targetLanguage") private var targetLanguage: String = ""
    
    @AppStorage("hasSelectedLearningLanguage") private var hasSelectedLearningLanguage = false
    @AppStorage("learningLanguage") private var learningLanguage: String = ""
    
    var body: some View {
        ZStack(alignment: .top) {
            content
            ToastView()
                .environmentObject(ToastManager.shared)
                .environmentObject(localizationManager)
                .ignoresSafeArea(edges: .top)
                .zIndex(9999)
        }
        .onAppear {
            print("🚀 RootView appeared")
            checkInitialState()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPaywallFromNotification)) { _ in
            if currentFlow == .mainApp {
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
            LearningLanguageSelectionView(onComplete: {
                hasSelectedLanguagePair = true
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
                    hasCompletedOnboarding = true
                    withAnimation {
                        currentFlow = .mainApp
                    }
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
        
        UserDefaults.standard.removeObject(forKey: "hasSelectedLanguage")
        UserDefaults.standard.removeObject(forKey: "appLanguage")
        UserDefaults.standard.removeObject(forKey: "hasSelectedLanguagePair")
        UserDefaults.standard.removeObject(forKey: "sourceLanguage")
        UserDefaults.standard.removeObject(forKey: "targetLanguage")
        UserDefaults.standard.removeObject(forKey: "hasSelectedLearningLanguage")
        UserDefaults.standard.removeObject(forKey: "learningLanguage")
        UserDefaults.standard.removeObject(forKey: "hasSeenNotifications")
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "hasRequestedPermissions")
        UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
        
        // Скидаємо й локальні @AppStorage змінні
        hasSelectedLanguage = false
        hasSelectedLanguagePair = false
        hasSeenNotifications = false
        hasCompletedOnboarding = false
        appLanguage = ""
        sourceLanguage = ""
        targetLanguage = ""
        
        print("🧹 All onboarding flags reset")
    }
    
    private func handleSuccessfulLogin() {
        print("🎯 Handling successful login")
        
        restoreLanguageSettings()
        
        Task {
            // 🆕 Спочатку завантажуємо дані підписки (не відновлюємо, а просто перевіряємо)
            await subscriptionManager.loadSubscriptionData()
            
            await MainActor.run {
                isSubscriptionLoaded = true
                
                // 🆕 Тепер determineNextFlow() вирішить куди йти
                // Він перевірить hasSelectedLanguagePair і покаже learningLanguage якщо треба
                determineNextFlow()
            }
        }
    }
    
    private func restoreLanguageSettings() {
        // Відновлюємо мову додатка
        if !appLanguage.isEmpty, let savedLanguage = Language(rawValue: appLanguage) {
            print("🌍 Restoring app language: \(appLanguage)")
            localizationManager.setLanguage(savedLanguage)
            hasSelectedLanguage = true
        }
        
        // Відновлюємо LanguagePair (новий формат)
        if !sourceLanguage.isEmpty && !targetLanguage.isEmpty {
            print("🌍 Restoring language pair: \(sourceLanguage) ↔️ \(targetLanguage)")
            if let source = TranslationLanguage(rawValue: sourceLanguage),
               let target = TranslationLanguage(rawValue: targetLanguage) {
                appState.languagePair = LanguagePair(source: source, target: target)
                hasSelectedLanguagePair = true
            }
        }
        // Зворотна сумісність: якщо є старий формат
        else if !learningLanguage.isEmpty {
            print("📚 Restoring learning language (legacy): \(learningLanguage)")
            // Конвертуємо стару мову в пару (наприклад, en ↔️ uk за замовчуванням)
            if let lang = TranslationLanguage(rawValue: learningLanguage) {
                let defaultPair = LanguagePair(source: .english, target: lang)
                appState.languagePair = defaultPair
                // Зберігаємо в новому форматі
                sourceLanguage = defaultPair.source.rawValue
                targetLanguage = defaultPair.target.rawValue
                hasSelectedLanguagePair = true
            }
        } else {
            print("📚 No language pair saved, resetting flag")
            hasSelectedLanguagePair = false
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
        print("   - hasSelectedLanguagePair: \(hasSelectedLanguagePair)")
        print("   - hasSeenNotifications: \(hasSeenNotifications)")
        print("   - hasCompletedOnboarding: \(hasCompletedOnboarding)")
        print("   - appLanguage: \(appLanguage)")
        print("   - sourceLanguage: \(sourceLanguage)")
        print("   - targetLanguage: \(targetLanguage)")
        print("   - status: \(subscriptionManager.status)")
        
        let nextFlow: AppFlow
        
        if !authViewModel.isAuthenticated {
            nextFlow = .login
        } else if !hasSelectedLanguage || appLanguage.isEmpty {
            nextFlow = .appLanguage
        } else if !hasSelectedLanguagePair || sourceLanguage.isEmpty || targetLanguage.isEmpty {
            nextFlow = .learningLanguage
        } else if !hasCompletedOnboarding {
            hasSeenNotifications = true

            switch subscriptionManager.status {
            case .premium(_, let isInGracePeriod):
                if isInGracePeriod {
                    nextFlow = .paywall
                } else {
                    hasCompletedOnboarding = true
                    nextFlow = .mainApp
                }
            case .trial:
                hasCompletedOnboarding = true
                nextFlow = .mainApp
            case .unknown, .expired, .trialExpired, .billingRetry:
                nextFlow = .paywall
            }
        } else {
            nextFlow = .mainApp
            selectedTab = 0
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
