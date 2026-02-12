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
   
    @State private var deepLinkAction: DeepLinkAction?
    
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
    
    @ViewBuilder
    private var mainContent: some View {
        if hasSeenOnboarding {
            ContentView()
                .environmentObject(localizationManager)
                .environmentObject(authViewModel)
                .environmentObject(appState)
                .modelContainer(for: SavedWord.self)
                .sheet(item: $deepLinkAction) { action in
                    switch action {
                    case .camera:
                        CameraSearchView()
                            .environmentObject(localizationManager)
                            .environmentObject(appState)
                    case .voice:
                        VoiceSearchView()
                            .environmentObject(localizationManager)
                            .environmentObject(appState)
                    }
                }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "wordy" else { return }
        
        switch url.host {
        case "camera":
            deepLinkAction = .camera
        case "voice":
            deepLinkAction = .voice
        default:
            break
        }
    }
    
    private func updateWidgetData() {
        // Оновлюємо дані віджета при запуску
        WidgetCenter.shared.reloadAllTimelines()
    }
}

enum DeepLinkAction: Identifiable {
    case camera
    case voice
    
    var id: String {
        switch self {
        case .camera: return "camera"
        case .voice: return "voice"
        }
    }
}
