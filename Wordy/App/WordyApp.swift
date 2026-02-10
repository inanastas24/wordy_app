//  WordyApp.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 27.01.2026.
//

import SwiftUI
import FirebaseCore
import SwiftData

@main
struct WordyApp: App {
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var appState = AppState()
    @StateObject private var profileViewModel = UserProfileViewModel.shared
    @StateObject private var permissionManager = PermissionManager.shared
    
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @AppStorage("learningLanguage") private var learningLanguage: String = "en"
    @State private var showSplash = true
    
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
        
        // Запитуємо всі пермішени при першому запуску
        // Tracking запитується з затримкою 2 секунди, щоб не налякати користувача відразу
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
       //     PermissionManager.shared.requestTrackingPermission()
       //     PermissionManager.shared.requestCameraPermission()
       //     PermissionManager.shared.requestMicrophonePermission()
       //     PermissionManager.shared.requestSpeechPermission()
        }
    }
    
    var body: some Scene {
            WindowGroup {
                ZStack {
                    // Головний контент
                    if hasSeenOnboarding {
                        ContentView()
                            .environmentObject(localizationManager)
                            .environmentObject(authViewModel)
                            .environmentObject(appState)
                            .modelContainer(for: SavedWord.self)
                    }
                    
                    // Splash Screen поверх усього
                    if showSplash {
                        SplashScreenView(isActive: $showSplash)
                            .environmentObject(localizationManager)
                            .transition(.opacity)
                            .zIndex(100)
                    }
                }
                .onAppear {
                    // Затримка перед показом splash (опціонально)
                    // або можна прибрати, щоб показувати одразу
                }
            }
        }
    }
