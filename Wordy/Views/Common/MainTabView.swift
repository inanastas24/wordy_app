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
    
    @StateObject private var onboardingManager = OnboardingManager.shared
    
    @State private var showPaywallFromNotification = false
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // MARK: - Search (Пошук)
                SearchView(
                    selectedTab: $selectedTab,
                    deepLinkAction: $deepLinkAction
                )
                .environmentObject(appState)
                .environmentObject(localizationManager)
                .environmentObject(authViewModel)
                .environmentObject(subscriptionManager)
                .environmentObject(onboardingManager)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text(localizationManager.string(.search))
                }
                .tag(0)
                
                // MARK: - Sets (Набори слів)
                SetsView()
                    .environmentObject(appState)
                    .environmentObject(localizationManager)
                    .environmentObject(onboardingManager)
                    .tabItem {
                        Image(systemName: "square.stack.3d.up.fill")
                        Text(localizationManager.string(.sets))
                    }
                    .tag(1)
                
                // MARK: - My Dictionary (Мій словник)
                DictionaryView()
                    .environmentObject(appState)
                    .environmentObject(localizationManager)
                    .environmentObject(onboardingManager)
                    .tabItem {
                        Image(systemName: "book.fill")
                        Text(localizationManager.string(.myDictionary))
                    }
                    .tag(2)
                
                // MARK: - Profile (Профіль)
                ProfileView()
                    .environmentObject(appState)
                    .environmentObject(localizationManager)
                    .environmentObject(authViewModel)
                    .environmentObject(subscriptionManager)
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text(localizationManager.string(.profile))
                    }
                    .tag(3)
            }
            .accentColor(Color(hex: "#4ECDC4"))
            
            // Onboarding overlay
            if onboardingManager.isShowingOverlay {
                OnboardingContainerView()
                    .environmentObject(onboardingManager)
                    .environmentObject(localizationManager)
                    .zIndex(1000)
                    .transition(.opacity)
                    .ignoresSafeArea()
            }
        }
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
                onClose: nil,
                onSubscribe: nil
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
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        }
        
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        
        if #available(iOS 16.0, *) {
            UIViewController.attemptRotationToDeviceOrientation()
        } else {
            UINavigationController.attemptRotationToDeviceOrientation()
        }
    }
}
