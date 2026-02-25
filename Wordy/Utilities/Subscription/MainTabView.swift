//
//  MainTabView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 23.02.2026.
//

import SwiftUI

struct MainTabView: View {
    @Binding var selectedTab: Int
    @Binding var deepLinkAction: DeepLinkAction?
    let isFirstTime: Bool
    
    init(selectedTab: Binding<Int>, deepLinkAction: Binding<DeepLinkAction?>, isFirstTime: Bool) {
        self._selectedTab = selectedTab
        self._deepLinkAction = deepLinkAction
        self.isFirstTime = isFirstTime
    }
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    @State private var showPaywallFromNotification = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SearchView(
                selectedTab: $selectedTab,
                deepLinkAction: $deepLinkAction
            )
            .environmentObject(appState)
            .environmentObject(localizationManager)
            .environmentObject(authViewModel)
            .environmentObject(subscriptionManager)
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
                .environmentObject(authViewModel)
                .environmentObject(subscriptionManager)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text(localizationManager.string(.profile))
                }
                .tag(2)
        }
        .accentColor(Color(hex: "#4ECDC4"))
        .onAppear {
            setupTabBarAppearance()
            lockOrientationToPortrait()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPaywallFromNotification)) { _ in
            showPaywallFromNotification = true
        }
        .sheet(isPresented: $showPaywallFromNotification) {
            PaywallView(
                isFirstTime: false,
                onClose: nil,  // Не потрібен, бо dismiss() закриє
                onSubscribe: nil  // Не потрібен, бо dismiss() закриє
            )
            .environmentObject(subscriptionManager)
            .environmentObject(localizationManager)
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
    
    private func lockOrientationToPortrait() {
        // Для iOS 16+
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        }
        
        // Для iOS 15 та нижче
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        
        // Використовуємо новий API для iOS 16+
        if #available(iOS 16.0, *) {
            UIViewController.attemptRotationToDeviceOrientation()
        } else {
            UINavigationController.attemptRotationToDeviceOrientation()
        }
    }
}
