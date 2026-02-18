//
//  WordyApp.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 27.01.2026.
//

import SwiftUI
import FirebaseCore
import SwiftData
import WidgetKit

@main
struct WordyApp: App {
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var appState = AppState()
    @StateObject private var profileViewModel = UserProfileViewModel.shared
    @StateObject private var permissionManager = PermissionManager.shared
    
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @AppStorage("learningLanguage") private var learningLanguage: String = "en"
   
    init() {
        FirebaseApp.configure()
        
        // Дебаг: перевіряємо конфігурацію Firebase
        if let options = FirebaseApp.app()?.options {
            print("✅ Firebase configured:")
            print("   - Project ID: \(options.projectID ?? "nil")")
            print("   - API Key: \(options.apiKey?.prefix(10) ?? "nil")...")
            print("   - Bundle ID: \(options.bundleID ?? "nil")")
        } else {
            print("❌ Firebase not configured properly!")
        }
        
        _authViewModel = StateObject(wrappedValue: AuthViewModel())
        
        // ВИПРАВЛЕНО: Оновлюємо streak при запуску додатку
        StreakService.shared.updateStreak()
        print("🔥 Streak updated: \(StreakService.shared.currentStreak) days")
        
        // Запитуємо всі пермішени при першому запуску
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            PermissionManager.shared.requestTrackingPermission()
            PermissionManager.shared.requestCameraPermission()
            PermissionManager.shared.requestMicrophonePermission()
            PermissionManager.shared.requestSpeechPermission()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(localizationManager)
                .environmentObject(appState)
                .environmentObject(profileViewModel)
                .environmentObject(permissionManager)
        }
    }
}
