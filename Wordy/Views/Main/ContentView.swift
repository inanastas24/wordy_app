//1
//  ContentView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 05.02.2026.
//

import SwiftUI
import Combine
import StoreKit
import NaturalLanguage
import AVFoundation

extension Notification.Name {
    static let showContactForm = Notification.Name("showContactForm")
}

struct ContentView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            Color(hex: localizationManager.isDarkMode ? "#1C1C1E" : "#FFFDF5")
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                VStack(spacing: 10) {
                    Text("🫧")
                        .font(.system(size: 80))
                    Text("Wordy")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                }
                .padding(.top, 60)
                
                Spacer()
                
                VStack(spacing: 20) {
                    Text(localizationManager.string(.selectAppLanguage))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                    
                    ForEach(Language.allCases, id: \.self) { language in
                        LanguageCard(
                            flag: flagForLanguage(language),
                            name: language.displayName,
                            isSelected: localizationManager.currentLanguage == language
                        ) {
                            localizationManager.setLanguage(language)
                            appState.appLanguage = language.rawValue
                        }
                    }
                }
                
                Spacer()
                
                NavigationLink(destination: LearningLanguageSelectionView()
                    .environmentObject(appState)
                    .environmentObject(localizationManager)
                    .environmentObject(authViewModel)) {
                    HStack {
                        Text(localizationManager.string(.continue))
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
    
    func flagForLanguage(_ lang: Language) -> String {
        switch lang {
        case .ukrainian: return "🇺🇦"
        case .english: return "🇬🇧"
        case .polish: return "🇵🇱"
        }
    }
}

// ВИДАЛЕНО: SearchView - він вже є в окремому файлі SearchView.swift

struct MainTabView: View {
    @Binding var selectedTab: Int
    @Binding var deepLinkAction: DeepLinkAction?
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SearchView(
                selectedTab: $selectedTab,
                deepLinkAction: $deepLinkAction
            )
                .environmentObject(appState)
                .environmentObject(localizationManager)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text(localizationManager.string(.search))
                }
                .tag(0)
            
            DictionaryView()
                .environmentObject(appState)
                .environmentObject(localizationManager)
                .tabItem {
                    Image(systemName: "book.fill")
                    Text(localizationManager.string(.dictionary))
                }
                .tag(1)
            
            ProfileView()
                .environmentObject(appState)
                .environmentObject(localizationManager)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text(localizationManager.string(.profile))
                }
                .tag(2)
        }
        .accentColor(Color(hex: "#4ECDC4"))
        .onAppear {
            setupTabBarAppearance()
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToSearchTab)) { _ in
            withAnimation {
                selectedTab = 0
            }
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        if localizationManager.isDarkMode {
            appearance.backgroundColor = UIColor(Color(hex: "#1C1C1E"))
        } else {
            appearance.backgroundColor = UIColor(Color(hex: "#FFFDF5"))
        }
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

extension Notification.Name {
    static let switchToSearchTab = Notification.Name("switchToSearchTab")
}

struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let isDarkMode: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(color)
            .cornerRadius(20)
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
