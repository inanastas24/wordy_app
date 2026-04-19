//
//  MenuView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI
import StoreKit
import Observation
import FirebaseAuth

// MARK: - Review Manager
@MainActor
@Observable
class ReviewManager {
    static let shared = ReviewManager()
    
    private let appStoreID = "6759168234"
    private let lastReviewRequestKey = "lastReviewRequestDate"
    private let appUsageCountKey = "appUsageCount"
    private let lastUsageRecordedDateKey = "lastUsageRecordedDate"
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
    
    func handleAppBecameActive() {
        recordAppUsageIfNeeded()
        requestReviewIfAppropriate()
    }

    func recordAppUsageIfNeeded() {
        let calendar = Calendar.current

        if let lastRecordedDate = UserDefaults.standard.object(forKey: lastUsageRecordedDateKey) as? Date,
           calendar.isDateInToday(lastRecordedDate) {
            return
        }

        let current = UserDefaults.standard.integer(forKey: appUsageCountKey)
        UserDefaults.standard.set(current + 1, forKey: appUsageCountKey)
        UserDefaults.standard.set(Date(), forKey: lastUsageRecordedDateKey)
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
    @EnvironmentObject var profileViewModel: UserProfileViewModel
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    @StateObject private var dictionaryVM = DictionaryViewModel.shared
    @StateObject private var notificationInbox = NotificationInboxManager.shared
    @State private var reviewManager = ReviewManager.shared
    
    @State private var bubbleOffsets: [CGFloat] = [0, 0, 0, 0, 0]
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @GestureState private var dragOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Color.black.opacity(localizationManager.isDarkMode ? 0.42 : 0.28)
                    .ignoresSafeArea()
                    .onTapGesture {
                        closeMenu()
                    }
                
                VStack(alignment: .leading, spacing: 0) {
                    menuHeader
                    profileStrip
                    quickStats

                    actionsSection
                    
                    Spacer()
                    footerSection
                }
                .frame(width: min(geometry.size.width * 0.75, 300))
                .frame(maxHeight: geometry.size.height - (geometry.safeAreaInsets.bottom + 160))
                .background(menuBackground)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(AppColors.cardBorder(isDarkMode: localizationManager.isDarkMode), lineWidth: 1)
                )
                .shadow(color: AppColors.shadow(isDarkMode: localizationManager.isDarkMode), radius: 24, x: 10, y: 0)
                .padding(.top, 50)
                .padding(.bottom, geometry.safeAreaInsets.bottom + 84)
                .padding(.leading, 10)
                .offset(x: max(dragOffset, 0))
                .gesture(closeDragGesture)
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

    private var closeDragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .updating($dragOffset) { value, state, _ in
                if value.translation.width > 0 {
                    state = value.translation.width
                }
            }
            .onEnded { value in
                if value.translation.width > 90 || value.predictedEndTranslation.width > 140 {
                    closeMenu()
                }
            }
    }

    private var menuBackground: some View {
        LinearGradient(
            colors: localizationManager.isDarkMode
            ? [Color(hex: "#23252B"), Color(hex: "#17181D")]
            : [Color.white, Color(hex: "#F7F4EB")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var menuHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
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
                .frame(width: 86, height: 86)
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

                Spacer()

                Button(action: closeMenu) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppColors.secondaryText(isDarkMode: localizationManager.isDarkMode))
                        .frame(width: 34, height: 34)
                        .background(
                            Circle()
                                .fill(AppColors.softCardBackground(isDarkMode: localizationManager.isDarkMode))
                        )
                }
                .buttonStyle(.plain)
            }

            Text("Wordy")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryText(isDarkMode: localizationManager.isDarkMode))

            Text(menuSubtitle)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.secondaryText(isDarkMode: localizationManager.isDarkMode))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
    
    private var quickStats: some View {
        HStack(spacing: 12) {
            let streak = calculateStreak()
            let streakColor = StreakService.shared.getStreakColor(for: streak)
            
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(hex: streakColor).opacity(0.14))
                        .frame(width: 38, height: 38)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: streakColor))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(localizedStreakTitle)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.secondaryText(isDarkMode: localizationManager.isDarkMode))

                    Text("\(streak)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryText(isDarkMode: localizationManager.isDarkMode))
                        .contentTransition(.numericText())
                }

                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }

    private var profileStrip: some View {
        HStack(spacing: 12) {
            Group {
                if let avatarImage = profileViewModel.avatarImage {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#4ECDC4"), Color(hex: "#6BCB77")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text(menuInitials)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(width: 54, height: 54)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(localizationManager.isDarkMode ? 0.08 : 0.8), lineWidth: 2)
            )

            VStack(alignment: .leading, spacing: 6) {
                profilePlanBadge
                Text(localizedProfileHint)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#4ECDC4"))
                    .lineLimit(1)
            }

            Spacer()

            Button {
                showSettings = true
                closeMenu()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppColors.softCardBackground(isDarkMode: localizationManager.isDarkMode))
                        .frame(width: 38, height: 38)

                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(localizationManager.isDarkMode ? Color.white.opacity(0.05) : Color.white.opacity(0.7))
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private var profilePlanBadge: some View {
        if subscriptionManager.isPremium {
            PremiumBadgeView(type: .premium)
                .scaleEffect(0.82, anchor: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if case .trial = subscriptionManager.status {
            PremiumBadgeView(type: .trial)
                .scaleEffect(0.82, anchor: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(localizedFreePlan)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#7F8C8D"))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(AppColors.softCardBackground(isDarkMode: localizationManager.isDarkMode))
                )
        }
    }
    
    private func calculateStreak() -> Int {
        return StreakService.shared.currentStreak
    }
    
    private var actionsSection: some View {
        VStack(spacing: 10) {
            Button(action: {
                NotificationInboxManager.shared.requestOpenInbox()
                closeMenu()
            }) {
                MenuRow(
                    icon: "bell.fill",
                    title: notificationsMenuTitle,
                    color: "#FF6B6B",
                    isDarkMode: localizationManager.isDarkMode,
                    showsUnreadDot: notificationInbox.unreadCount > 0
                )
            }

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
        }
        .padding(.horizontal, 14)
    }

    private var notificationsMenuTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Нотифікації"
        case .polish: return "Powiadomienia"
        case .english: return "Notifications"
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 8) {
            Button(action: {
                if reviewManager.canRequestReview {
                    ReviewManager.shared.requestReviewIfAppropriate()
                } else {
                    ReviewManager.shared.openAppStoreForReview()
                }
                closeMenu()
            }) {
                compactFooterAction(
                    icon: "star.fill",
                    title: localizationManager.string(.rateInAppStore),
                    color: "#FFD700"
                )
            }
            .buttonStyle(.plain)
            .opacity(reviewManager.canRequestReview ? 1.0 : 0.72)
            .padding(.horizontal, 14)
            .padding(.bottom, 6)

            HStack {
                Text("Wordy v4.2")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.tertiaryText(isDarkMode: localizationManager.isDarkMode))
                
                Spacer()

                Text(localizedSwipeHint)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.tertiaryText(isDarkMode: localizationManager.isDarkMode))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private func compactFooterAction(icon: String, title: String, color: String) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: color).opacity(0.14))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: color))
                )

            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.primaryText(isDarkMode: localizationManager.isDarkMode))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppColors.tertiaryText(isDarkMode: localizationManager.isDarkMode))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
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

    private var menuSubtitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Швидкі дії, підтримка й налаштування в одному місці"
        case .polish: return "Szybkie akcje, wsparcie i ustawienia w jednym miejscu"
        case .english: return "Quick actions, support and settings in one place"
        }
    }

    private var localizedStreakTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Серія"
        case .polish: return "Seria"
        case .english: return "Streak"
        }
    }

    private var localizedSwipeHint: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Потягни вправо, щоб закрити"
        case .polish: return "Przesuń w prawo, aby zamknąć"
        case .english: return "Swipe right to close"
        }
    }

    private var localizedFreePlan: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Free"
        case .polish: return "Free"
        case .english: return "Free"
        }
    }

    private var localizedProfileHint: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Профіль синхронізовано"
        case .polish: return "Profil zsynchronizowany"
        case .english: return "Profile synced"
        }
    }

    private var menuDisplayName: String {
        let trimmed = profileViewModel.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return localizationManager.string(.user)
        }
        return trimmed
    }

    private var menuEmail: String {
        Auth.auth().currentUser?.email ?? "wordy.app"
    }

    private var menuInitials: String {
        let source = menuDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else { return "W" }

        let parts = source.split(separator: " ").prefix(2)
        let initials = parts.compactMap { $0.first }.map { String($0).uppercased() }.joined()
        return initials.isEmpty ? "W" : initials
    }
}
