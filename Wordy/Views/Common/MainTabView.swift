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
    @StateObject private var notificationInbox = NotificationInboxManager.shared
    
    @State private var showPaywallFromNotification = false
    @State private var showNotificationsInbox = false
    
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
            notificationInbox.refreshState()
            setupTabBarAppearance()
            lockOrientationToPortrait()
            if notificationInbox.shouldOpenInbox {
                showNotificationsInbox = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPaywallFromNotification)) { _ in
            showPaywallFromNotification = true
        }
        .onChange(of: notificationInbox.shouldOpenInbox) { _, shouldOpen in
            guard shouldOpen else { return }
            showNotificationsInbox = true
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
        .sheet(isPresented: $showNotificationsInbox, onDismiss: {
            notificationInbox.consumeOpenInboxRequest()
        }) {
            NotificationsInboxView()
                .environmentObject(localizationManager)
        }
    }
    // MARK: - Sets Tab Item з BETA бейджем
        private var setsTabItem: some View {
            ZStack {
                // Основний контент таба
                VStack(spacing: 2) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 22))
                        
                        // BETA плашка над іконкою
                        Text("BETA")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: "#FF6B6B"))
                            )
                            .offset(x: 10, y: -10)
                            .rotationEffect(.degrees(-5)) // Легкий нахил як на прикладі
                    }
                    
                    Text(localizationManager.string(.sets))
                        .font(.system(size: 10))
                }
            }
        }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColors.secondaryScreenBackground(isDarkMode: localizationManager.isDarkMode))

        let normalIconColor = UIColor(AppColors.tertiaryText(isDarkMode: localizationManager.isDarkMode))
        let normalTextColor = UIColor(AppColors.secondaryText(isDarkMode: localizationManager.isDarkMode))
        let selectedColor = UIColor(AppColors.primary)

        let stacked = appearance.stackedLayoutAppearance
        stacked.normal.iconColor = normalIconColor
        stacked.normal.titleTextAttributes = [.foregroundColor: normalTextColor]
        stacked.selected.iconColor = selectedColor
        stacked.selected.titleTextAttributes = [.foregroundColor: selectedColor]

        let inline = appearance.inlineLayoutAppearance
        inline.normal.iconColor = normalIconColor
        inline.normal.titleTextAttributes = [.foregroundColor: normalTextColor]
        inline.selected.iconColor = selectedColor
        inline.selected.titleTextAttributes = [.foregroundColor: selectedColor]

        let compactInline = appearance.compactInlineLayoutAppearance
        compactInline.normal.iconColor = normalIconColor
        compactInline.normal.titleTextAttributes = [.foregroundColor: normalTextColor]
        compactInline.selected.iconColor = selectedColor
        compactInline.selected.titleTextAttributes = [.foregroundColor: selectedColor]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func lockOrientationToPortrait() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        }
        
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        
        if #unavailable(iOS 16.0) {
            UINavigationController.attemptRotationToDeviceOrientation()
        }
    }
}
