//1
//  WordyApp.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 27.01.2026.
//

import SwiftUI
import FirebaseCore

@main
struct WordyApp: App {
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var appState = AppState()
    @StateObject private var profileViewModel = UserProfileViewModel.shared
    @StateObject private var permissionManager = PermissionManager.shared
    
    init() {
        FirebaseApp.configure()
        _authViewModel = StateObject(wrappedValue: AuthViewModel())
        
        // Запитуємо всі пермішени при першому запуску
        // Tracking запитується з затримкою 2 секунди, щоб не налякати користувача відразу
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            PermissionManager.shared.requestTrackingPermission()
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
