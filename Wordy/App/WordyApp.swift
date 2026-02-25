//
//  WordyApp.swift
//  Wordy
//

import SwiftUI
import FirebaseCore
import SwiftData
import WidgetKit

// MARK: - AppDelegate для блокування орієнтації
class AppDelegate: NSObject, UIApplicationDelegate {
    
    /// 🔒 Блокуємо всі орієнтації окрім портретної — викликається при кожній спробі повороту
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Примусово встановлюємо портрет при старті
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        
        // Реєстрація категорій сповіщень
        registerNotificationCategories()
        
        return true
    }
    
    private func registerNotificationCategories() {
        let trialReminderCategory = UNNotificationCategory(
            identifier: "TRIAL_REMINDER",
            actions: [
                UNNotificationAction(identifier: "BUY_PREMIUM", title: "Купити Premium", options: .foreground),
                UNNotificationAction(identifier: "LATER", title: "Пізніше", options: .destructive)
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let trialEndedCategory = UNNotificationCategory(
            identifier: "TRIAL_ENDED",
            actions: [
                UNNotificationAction(identifier: "BUY_PREMIUM", title: "Купити Premium", options: .foreground),
                UNNotificationAction(identifier: "CLOSE", title: "Закрити", options: .destructive)
            ],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([trialReminderCategory, trialEndedCategory])
    }
}

@main
struct WordyApp: App {
    // 🔗 Підключаємо AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var appState = AppState()
    @StateObject private var profileViewModel = UserProfileViewModel.shared
    @StateObject private var permissionManager = PermissionManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager()
    
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @AppStorage("hasSelectedLanguage") private var hasSelectedLanguage: Bool = false
    @AppStorage("hasSelectedLearningLanguage") private var hasSelectedLearningLanguage: Bool = false
    @AppStorage("learningLanguage") private var learningLanguage: String = ""
   
    init() {
        FirebaseApp.configure()
        _authViewModel = StateObject(wrappedValue: AuthViewModel())
        StreakService.shared.updateStreak()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(localizationManager)
                .environmentObject(appState)
                .environmentObject(profileViewModel)
                .environmentObject(permissionManager)
                .environmentObject(subscriptionManager)
        }
    }
}
