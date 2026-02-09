//
//  WordyTests.swift
//  WordyTests
//
//  Created by Anastasiia Inzer on 26.01.2026.
//

import Testing
@main
struct WordyApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
                    .environmentObject(appState)
                    .environmentObject(localizationManager)
                    .preferredColorScheme(localizationManager.isDarkMode ? .dark : .light)
            }
            .modelContainer(for: [SavedWord.self, LearningDay.self])
        }
    }
}
