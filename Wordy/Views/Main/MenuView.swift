//
//  MenuView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI
import StoreKit
import Observation

// MARK: - Review Manager
@MainActor
@Observable
class ReviewManager {
    static let shared = ReviewManager()
    
    private let appStoreID = "6759168234"
    private let lastReviewRequestKey = "lastReviewRequestDate"
    private let appUsageCountKey = "appUsageCount"
    private let minUsageCountForReview = 5 // Мінімум 5 разів відкрив додаток
    
    private init() {}
    
    var canRequestReview: Bool {
        let usageCount = UserDefaults.standard.integer(forKey: appUsageCountKey)
        guard usageCount >= minUsageCountForReview else { return false }
        
        guard let lastDate = UserDefaults.standard.object(forKey: lastReviewRequestKey) as? Date else {
            return true
        }
        
        let calendar = Calendar.current
        return !calendar.isDateInToday(lastDate)
    }
    
    func recordAppUsage() {
        let current = UserDefaults.standard.integer(forKey: appUsageCountKey)
        UserDefaults.standard.set(current + 1, forKey: appUsageCountKey)
    }
    
    func markReviewRequested() {
        UserDefaults.standard.set(Date(), forKey: lastReviewRequestKey)
    }
    
    func requestReviewIfAppropriate() {
        guard canRequestReview else { return }
        
        requestReview()
        markReviewRequested()
    }
    
    func openAppStoreForReview() {
        let urlString = "https://apps.apple.com/app/id\(appStoreID)?action=write-review"
        guard let url = URL(string: urlString) else { return }
        
        guard UIApplication.shared.canOpenURL(url) else { return }
        
        UIApplication.shared.open(url) { _ in
            self.markReviewRequested()
        }
    }
    
    private func requestReview() {
        if #available(iOS 14.0, *) {
            guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first else { return }
            
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

struct MenuView: View {
    @Binding var isShowing: Bool
    @Binding var selectedTab: Int
    @Binding var showSettings: Bool
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @StateObject private var dictionaryVM = DictionaryViewModel.shared
    @State private var reviewManager = ReviewManager.shared
    
    @State private var bubbleOffsets: [CGFloat] = [0, 0, 0, 0, 0]
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        closeMenu()
                    }
                
                VStack(alignment: .leading, spacing: 0) {
                    menuHeader
                    quickStats
                    
                    Divider()
                        .background(Color.gray.opacity(0.2))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    
                    actionsSection
                    
                    Spacer()
                    footerSection
                }
                .frame(width: min(geometry.size.width * 0.75, 300))
                .frame(maxHeight: geometry.size.height - 100)
                .background(localizationManager.isDarkMode ? Color(hex: "#1C1C1E") : Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 5, y: 0)
                .padding(.top, 50)
                .padding(.bottom, 20)
                .padding(.leading, 10)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .onAppear {
            dictionaryVM.fetchSavedWords()
            reviewManager.recordAppUsage()
            reviewManager.requestReviewIfAppropriate()
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if oldValue != newValue {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isShowing = false
                }
            }
        }
    }
    
    private func closeMenu() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isShowing = false
        }
    }
    
    private var menuHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                ForEach(0..<4) { i in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#4ECDC4").opacity(0.3),
                                    Color(hex: "#A8D8EA").opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 30 + CGFloat(i * 10), height: 30 + CGFloat(i * 10))
                        .offset(
                            x: CGFloat(i % 2 == 0 ? 20 : -10) + bubbleOffsets[i],
                            y: CGFloat(i % 2 == 0 ? -10 : 20) + bubbleOffsets[i]
                        )
                        .blur(radius: 2)
                }
                
                Text("🫧")
                    .font(.system(size: 50))
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .frame(height: 80)
            .onAppear {
                for i in 0..<4 {
                    withAnimation(
                        .easeInOut(duration: 2 + Double(i) * 0.3)
                        .repeatForever(autoreverses: true)
                    ) {
                        bubbleOffsets[i] = CGFloat.random(in: -10...10)
                    }
                }
            }
            
            Text("Wordy")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
    
    private var quickStats: some View {
        HStack(spacing: 12) {
            let streak = calculateStreak()
            let streakColor = StreakService.shared.getStreakColor(for: streak)
            
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: streakColor))
                Text("\(streak)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(hex: streakColor).opacity(0.15))
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
    
    private func calculateStreak() -> Int {
        return StreakService.shared.currentStreak
    }
    
    private var actionsSection: some View {
        VStack(spacing: 4) {
            Button(action: {
                shareApp()
                closeMenu()
            }) {
                MenuRow(
                    icon: "square.and.arrow.up",
                    title: localizationManager.string(.shareWordy),
                    color: "#4ECDC4",
                    isDarkMode: localizationManager.isDarkMode
                )
            }
            
            Button(action: {
                showSettings = true
                closeMenu()
            }) {
                MenuRow(
                    icon: "gear",
                    title: localizationManager.string(.settings),
                    color: "#7F8C8D",
                    isDarkMode: localizationManager.isDarkMode
                )
            }
            
            Button(action: {
                if let url = URL(string: "https://t.me/ms_wordybot") {
                    UIApplication.shared.open(url)
                }
                closeMenu()
            }) {
                MenuRow(
                    icon: "paperplane.fill",
                    title: localizationManager.string(.supportChat),
                    color: "#F38BA8",
                    isDarkMode: localizationManager.isDarkMode
                )
            }
            
            Divider()
                .background(Color.gray.opacity(0.2))
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
            
            Button(action: {
                if reviewManager.canRequestReview {
                    ReviewManager.shared.requestReviewIfAppropriate()
                } else {
                    ReviewManager.shared.openAppStoreForReview()
                }
                closeMenu()
            }) {
                MenuRow(
                    icon: "star.fill",
                    title: localizationManager.string(.rateInAppStore),
                    color: "#FFD700",
                    isDarkMode: localizationManager.isDarkMode
                )
            }
            .opacity(reviewManager.canRequestReview ? 1.0 : 0.6)
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 8) {
            Divider()
                .background(Color.gray.opacity(0.2))
                .padding(.horizontal, 20)
            
            HStack {
                Text("Wordy v1.1")
                    .font(.system(size: 12))
                    .foregroundColor(localizationManager.isDarkMode ? .gray.opacity(0.6) : Color(hex: "#7F8C8D").opacity(0.6))
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    private func shareApp() {
        let text = shareMessage
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        // 🔑 ОБОВ'ЯЗКОВО для iPad - встановлюємо sourceView
        if let popover = activityVC.popoverPresentationController {
            // Знаходимо вікно та view для прив'язки popover
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootView = windowScene.windows.first?.rootViewController?.view {
                popover.sourceView = rootView
                popover.sourceRect = CGRect(
                    x: rootView.bounds.midX,
                    y: rootView.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = [] // Без стрілки, по центру
            }
        }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private var shareMessage: String {
        let appStoreURL = "https://apps.apple.com/app/wordy/id6759168234"
        
        switch localizationManager.currentLanguage {
        case .ukrainian:
            return "Вчу мови з Wordy! 📚 Спробуй і ти: \(appStoreURL)"
        case .polish:
            return "Uczę się języków z Wordy! 📚 Spróbuj też: \(appStoreURL)"
        case .english:
            return "I'm learning languages with Wordy! 📚 Check it out: \(appStoreURL)"
        }
    }
}

