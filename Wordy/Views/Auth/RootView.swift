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
    case paywall        // Обов'язковий paywall для нових
    case mainApp        // 🆕 Для всіх авторизованих (включаючи expired)
    case biometricAuth  // 🆕 ДОДАЙТЕ цей case
}

// MARK: - Root View
struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    
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
    
    let onClose: () -> Void = {}
    let onSubscribe: () -> Void = {}
    var isBlocker: Bool = false
    
    var body: some View {
        content
            .onAppear {
                print("🚀 RootView appeared")
                checkInitialState()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openPaywallFromNotification)) { _ in
                if currentFlow == .mainApp {
                    // Показуємо paywall як sheet з mainApp
                    // Це обробляється в MainTabView
                } else {
                    currentFlow = .paywall
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .userDidLogout)) { _ in
                print("👤 User logged out, resetting flow")
                withAnimation {
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
                // Скидаємо onboarding при новому логіні
                hasCompletedOnboarding = false
                loadSubscriptionData()
            })
            
        case .appLanguage:
            LanguageSelectionView(onComplete: {
                hasSelectedLanguage = true
                withAnimation {
                    determineNextFlow()
                }
            })
            
        case .learningLanguage:
            LearningLanguageSelectionView(onComplete: {
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
                isFirstTime: true,  // Обов'язковий
                onClose: {
                    // Не можна закрити без підписки
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
            // 🆕 Всі авторизовані користувачі йдуть сюди (включаючи expired)
            MainTabView(
                selectedTab: $selectedTab,
                deepLinkAction: $deepLinkAction,
                isFirstTime: false
            )
            
        case .biometricAuth:  // 🆕 ДОДАЙТЕ обробку цього case
            BiometricAuthView {
                // Після успішної біометричної автентифікації
                withAnimation {
                    handleAuthState()
                }
            }
        }
    }
    
    private func checkInitialState() {
        // 🆕 Якщо є збережена сесія і біометрія ввімкнена — пропонуємо її
        if Auth.auth().currentUser != nil &&
           authViewModel.biometricManager.isEnabled {
            // Показуємо екран з біометрією
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
        print("   - status: \(subscriptionManager.status)")
        print("   - isPremium: \(subscriptionManager.isPremium)")
        print("   - isTrialActive: \(subscriptionManager.isTrialActive)")
        print("   - isSubscriptionExpired: \(subscriptionManager.isSubscriptionExpired)")
        print("   - canUseApp: \(subscriptionManager.canUseApp)")
        
        let nextFlow: AppFlow
        
        if !authViewModel.isAuthenticated {
            nextFlow = .login
        } else if !hasSelectedLanguage {
            nextFlow = .appLanguage
        } else if !hasSelectedLearningLanguage {
            nextFlow = .learningLanguage
        } else if !hasCompletedOnboarding {
            // 🆕 Тільки якщо НІКОЛИ не було підписки (unknown), а не expired
            // Expired користувачі вже проходили onboarding
            hasSeenNotifications = true
            
            if subscriptionManager.status == .unknown {
                nextFlow = .paywall
            } else {
                // Якщо була підписка (навіть expired) - пропускаємо paywall
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

// 🆕 ДОДАЙТЕ цей View для біометричної автентифікації
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
                    // Пропускаємо біометрію
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
            // Автоматично пробуємо біометрію при появі
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
