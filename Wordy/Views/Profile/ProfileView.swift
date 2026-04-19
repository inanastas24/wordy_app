//
//  ProfileView.swift
//  Wordy
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @AppStorage("TranslationLanguage") private var learningLanguage: TranslationLanguage = .english
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var profileViewModel: UserProfileViewModel
    
    @ObservedObject private var dictionaryVM = DictionaryViewModel.shared
    @StateObject private var notificationInbox = NotificationInboxManager.shared
    
    @State private var showMenu = false
    @State private var selectedTab: Int = 2
    @State private var showSettings = false
    @State private var showLanguageSelection = false
    @State private var showPaywall = false
    
    @State private var currentStreak: Int = 0
    @State private var streakColor: String = "#F38BA8"
    @State private var streakTitle: String = "0 days"
    
    private var totalWords: Int { dictionaryVM.savedWords.count }
    private var learnedWords: Int { dictionaryVM.savedWords.filter { $0.isLearned }.count }
    private var learningWords: Int { dictionaryVM.savedWords.filter { !$0.isLearned }.count }
    private var recentActivityWords: [SavedWordModel] {
        dictionaryVM.savedWords
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(5)
            .map { $0 }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                profileBackground
                
                ScrollView {
                    VStack(spacing: 24) {
                        header
                        userEmailSection
                        statsGrid
                        achievementsSection
                        activitySection
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.top, 20)
                }
                
                if showMenu {
                    MenuView(isShowing: $showMenu, selectedTab: $selectedTab, showSettings: $showSettings)
                        .transition(.move(edge: .leading))
                        .zIndex(100)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(localizationManager)
                    .environmentObject(appState)
                    .environmentObject(subscriptionManager)
                    .environmentObject(profileViewModel)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    isFirstTime: true,
                    onClose: {
                        showPaywall = false
                    },
                    onSubscribe: {
                        showPaywall = false
                    }
                )
                .environmentObject(subscriptionManager)
            }

            .navigationDestination(isPresented: $showLanguageSelection) {
                LearningLanguageSelectionView(
                    onComplete: {
                        // Completed language selection
                    },
                    isChangeMode: true,
                    onLanguageChanged: {}
                )
                .navigationBarBackButtonHidden(true)
            }
            .onAppear {
                OnboardingContext.isOnDictionaryScreen = true
                dictionaryVM.fetchSavedWords()
                updateStreak()
                profileViewModel.loadProfile()
            }
        }
    }

    private var profileBackground: some View {
        ZStack {
            AppColors.screenBackground(isDarkMode: localizationManager.isDarkMode)
                .ignoresSafeArea()

            Circle()
                .fill(Color(hex: "#4ECDC4").opacity(localizationManager.isDarkMode ? 0.16 : 0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 54)
                .offset(x: -150, y: -280)

            Circle()
                .fill(Color(hex: streakColor).opacity(localizationManager.isDarkMode ? 0.12 : 0.10))
                .frame(width: 260, height: 260)
                .blur(radius: 56)
                .offset(x: 170, y: -110)

            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(localizationManager.isDarkMode ? 0.03 : 0.45),
                            Color(hex: "#A8D8EA").opacity(localizationManager.isDarkMode ? 0.06 : 0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 300)
                .blur(radius: 44)
                .offset(y: -210)
        }
    }
    
    private func updateStreak() {
        StreakService.shared.updateStreak()
        currentStreak = StreakService.shared.currentStreak
        streakColor = StreakService.shared.getStreakColor(for: currentStreak)
        streakTitle = StreakService.shared.getStreakTitle(for: currentStreak)
    }
    
    private var header: some View {
        HStack {
            Button(action: { showMenu = true }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "line.horizontal.3")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryText(isDarkMode: localizationManager.isDarkMode))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(AppColors.controlFill(isDarkMode: localizationManager.isDarkMode))
                        )
                        .overlay(
                            Circle()
                                .stroke(AppColors.cardBorder(isDarkMode: localizationManager.isDarkMode), lineWidth: 1)
                        )
                        .shadow(color: AppColors.shadow(isDarkMode: localizationManager.isDarkMode), radius: 12, x: 0, y: 8)

                    if notificationInbox.unreadCount > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                            .offset(x: -3, y: 3)
                    }
                }
            }
            
            Spacer()
            
            VStack(spacing: 3) {
                Text(localizationManager.string(.profile))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryText(isDarkMode: localizationManager.isDarkMode))

                Text(progressHeaderSubtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.secondaryText(isDarkMode: localizationManager.isDarkMode))
            }
            
            Spacer()
            
            Button(action: { showSettings = true }) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#4ECDC4"))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(AppColors.controlFill(isDarkMode: localizationManager.isDarkMode))
                    )
                    .overlay(
                        Circle()
                            .stroke(AppColors.cardBorder(isDarkMode: localizationManager.isDarkMode), lineWidth: 1)
                    )
                    .shadow(color: AppColors.shadow(isDarkMode: localizationManager.isDarkMode), radius: 12, x: 0, y: 8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var userEmailSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
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

                            Text(initialsText)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(width: 88, height: 88)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(AppColors.cardBorder(isDarkMode: localizationManager.isDarkMode), lineWidth: 3)
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text(currentDisplayName)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryText(isDarkMode: localizationManager.isDarkMode))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(currentEmail)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.secondaryText(isDarkMode: localizationManager.isDarkMode))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        Image(systemName: "bolt.heart.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text(localizationManager.string(.yourProgress))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(Color(hex: "#4ECDC4"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(hex: "#4ECDC4").opacity(0.12))
                    )

                    HStack(spacing: 8) {
                        if subscriptionManager.isPremium {
                            PremiumBadgeView(type: .premium)
                        } else if case .trial = subscriptionManager.status {
                            PremiumBadgeView(type: .trial)
                        } else {
                            Text(localizationManager.string(.freeLabel))
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(hex: "#7F8C8D"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(localizationManager.isDarkMode ? Color(hex: "#1F1F21") : Color(hex: "#F2EEE2"))
                                )
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !subscriptionManager.isPremium {
                    Button {
                        showPaywall = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#FFD700").opacity(0.15))
                                .frame(width: 42, height: 42)

                            Image(systemName: "crown.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(hex: "#FFD700"))
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }

            HStack(spacing: 12) {
                progressHighlightCard(
                    icon: "flame.fill",
                    title: localizedCurrentStreakTitle,
                    value: streakTitle,
                    tint: streakColor
                )

                progressHighlightCard(
                    icon: "book.pages.fill",
                    title: localizedVocabularyTitle,
                    value: "\(totalWords)",
                    tint: "#4ECDC4"
                )
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: localizationManager.isDarkMode
                        ? [Color(hex: "#23252B"), Color(hex: "#17181D")]
                        : [Color.white, Color(hex: "#F7F4EB")]
                        ,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(AppColors.cardBorder(isDarkMode: localizationManager.isDarkMode), lineWidth: 1)
                )
                .shadow(color: AppColors.shadow(isDarkMode: localizationManager.isDarkMode), radius: 22, x: 0, y: 14)
        )
        .padding(.horizontal, 20)
    }

    private var currentDisplayName: String {
        let trimmed = profileViewModel.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? localizationManager.string(.user) : trimmed
    }

    private var currentEmail: String {
        if !authViewModel.appleEmail.isEmpty {
            return authViewModel.appleEmail
        }

        if let email = authViewModel.user?.email, !email.isEmpty {
            return email
        }

        return localizationManager.string(.user)
    }

    private var initialsText: String {
        let source = currentDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else { return "U" }

        let parts = source.split(separator: " ").prefix(2)
        let initials = parts.compactMap { $0.first }.map { String($0).uppercased() }.joined()
        return initials.isEmpty ? "U" : initials
    }
    
    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            profileSectionHeader(
                title: localizedSnapshotTitle,
                subtitle: localizedSnapshotSubtitle,
                icon: "chart.xyaxis.line",
                tint: "#4ECDC4"
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
            StatCard(
                icon: "book.fill",
                value: "\(totalWords)",
                label: localizationManager.string(.totalWords),
                color: Color(hex: "#4ECDC4"),
                isDarkMode: localizationManager.isDarkMode
            )
            
            StatCard(
                icon: "checkmark.circle.fill",
                value: "\(learnedWords)",
                label: localizationManager.string(.learned),
                color: Color(hex: "#95E1D3"),
                isDarkMode: localizationManager.isDarkMode
            )
            
            StatCard(
                icon: "clock.fill",
                value: "\(learningWords)",
                label: localizationManager.string(.learning),
                color: Color(hex: "#A8D8EA"),
                isDarkMode: localizationManager.isDarkMode
            )
            
            StatCard(
                icon: "flame.fill",
                value: streakTitle,
                label: localizationManager.string(.streakDays),
                color: Color(hex: streakColor),
                isDarkMode: localizationManager.isDarkMode
            )
        }
        }
        .padding(.horizontal, 20)
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            profileSectionHeader(
                title: localizationManager.string(.achievements) + " 🏆",
                subtitle: localizedAchievementsSubtitle,
                icon: "sparkles.rectangle.stack.fill",
                tint: "#FFD166"
            )
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    AchievementCard(
                        icon: "star.fill",
                        title: localizationManager.string(.firstWord),
                        isUnlocked: totalWords >= 1,
                        color: "#FFD700",
                        isDarkMode: localizationManager.isDarkMode
                    )
                    
                    AchievementCard(
                        icon: "book.fill",
                        title: localizationManager.string(.tenWords),
                        isUnlocked: totalWords >= 10,
                        color: "#4ECDC4",
                        isDarkMode: localizationManager.isDarkMode
                    )
                    
                    AchievementCard(
                        icon: "crown.fill",
                        title: localizationManager.string(.hundredWords),
                        isUnlocked: totalWords >= 100,
                        color: "#FFD700",
                        isDarkMode: localizationManager.isDarkMode
                    )
                    
                    AchievementCard(
                        icon: "flame.fill",
                        title: localizationManager.string(.sevenDays),
                        isUnlocked: currentStreak >= 7,
                        color: "#FF6B6B",
                        isDarkMode: localizationManager.isDarkMode
                    )
                    
                    AchievementCard(
                        icon: "calendar.badge.clock",
                        title: localizationManager.string(.thirtyDays),
                        isUnlocked: currentStreak >= 30,
                        color: "#9B59B6",
                        isDarkMode: localizationManager.isDarkMode
                    )
                    
                    AchievementCard(
                        icon: "flame.circle.fill",
                        title: localizationManager.string(.hundredWords),
                        isUnlocked: currentStreak >= 100,
                        color: "#FF8C00",
                        isDarkMode: localizationManager.isDarkMode
                    )
                    
                    // Premium achievement
                    AchievementCard(
                        icon: "crown.fill",
                        title: localizationManager.string(.premiumLabel),
                        isUnlocked: subscriptionManager.isPremium,
                        color: "#FFD700",
                        isDarkMode: localizationManager.isDarkMode
                    )
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var activitySection: some View {
        Group {
            if !recentActivityWords.isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    profileSectionHeader(
                        title: localizationManager.string(.recentActivity),
                        subtitle: localizedActivitySubtitle,
                        icon: "clock.arrow.circlepath",
                        tint: "#FF8A65"
                    )
                    
                    ForEach(recentActivityWords) { word in
                        FirestoreActivityRow(word: word, isDarkMode: localizationManager.isDarkMode)
                    }
                }
            }
        }
    }
    
    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            profileSectionHeader(
                title: localizationManager.string(.subscription),
                subtitle: localizedSubscriptionSubtitle,
                icon: "crown.fill",
                tint: "#FFD166"
            )
            
            SettingsSubscriptionSection(
                manager: subscriptionManager,
                onManage: {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                },
                onRestore: {
                    Task {
                        await subscriptionManager.restorePurchases()
                    }
                }
            )
            .padding(.horizontal, 20)
        }
    }

    private var progressHeaderSubtitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Щоденна динаміка, досягнення й мотивація"
        case .polish: return "Codzienny postęp, osiągnięcia i motywacja"
        case .english: return "Daily momentum, achievements and motivation"
        }
    }

    private var localizedCurrentStreakTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Серія"
        case .polish: return "Seria"
        case .english: return "Streak"
        }
    }

    private var localizedVocabularyTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Словник"
        case .polish: return "Słownictwo"
        case .english: return "Vocabulary"
        }
    }

    private var localizedSnapshotTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Ваш зріз"
        case .polish: return "Twoja migawka"
        case .english: return "Your snapshot"
        }
    }

    private var localizedSnapshotSubtitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Головні метрики в одному погляді"
        case .polish: return "Najważniejsze wskaźniki na jednym ekranie"
        case .english: return "Key metrics collected in one glance"
        }
    }

    private var localizedAchievementsSubtitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Маленькі перемоги, які збираються у великий результат"
        case .polish: return "Małe zwycięstwa, które składają się na duży wynik"
        case .english: return "Small wins that build into real language progress"
        }
    }

    private var localizedActivitySubtitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Останні дії, щоб легко повернутись у ритм"
        case .polish: return "Ostatnie działania, aby łatwo wrócić do rytmu"
        case .english: return "Recent actions so you can jump back into flow"
        }
    }

    private var localizedSubscriptionSubtitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Статус плану та швидкий шлях до керування"
        case .polish: return "Status planu i szybka ścieżka do zarządzania"
        case .english: return "Your plan status with a quick path to manage it"
        }
    }

    @ViewBuilder
    private func profileSectionHeader(title: String, subtitle: String, icon: String, tint: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: tint).opacity(0.14))
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: tint))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#203044"))

                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(localizationManager.isDarkMode ? Color.white.opacity(0.56) : Color(hex: "#6E7C89"))
            }

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func progressHighlightCard(icon: String, title: String, value: String, tint: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: tint).opacity(0.13))
                    .frame(width: 38, height: 38)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: tint))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(localizationManager.isDarkMode ? Color.white.opacity(0.62) : Color(hex: "#6E7C89"))

                Text(value)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#203044"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(localizationManager.isDarkMode ? Color.white.opacity(0.04) : Color.white.opacity(0.62))
        )
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let isDarkMode: Bool
    
    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 46, height: 46)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(spacing: 8) {
                Text(value)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "#203044"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity)

                Text(label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(isDarkMode ? Color(hex: "#8E8E93") : Color(hex: "#6E7C89"))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 36, alignment: .top)
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 168, alignment: .top)
        .padding(.vertical, 22)
        .padding(.horizontal, 18)
        .background(isDarkMode ? Color(hex: "#23252B") : Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(isDarkMode ? 0.05 : 0.7), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 8)
    }
}

struct AchievementCard: View {
    let icon: String
    let title: String
    let isUnlocked: Bool
    let color: String
    let isDarkMode: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(isUnlocked ? Color(hex: color) : (isDarkMode ? .gray : .gray))
                .opacity(isUnlocked ? 1.0 : 0.3)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isUnlocked ? (isDarkMode ? .white : Color(hex: "#2C3E50")) : .gray)
                .multilineTextAlignment(.center)
        }
        .frame(width: 108, height: 108)
        .background(isUnlocked ? Color(hex: color).opacity(0.1) : (isDarkMode ? Color(hex: "#2C2C2E") : Color(hex: "#F4EFE4")))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(isUnlocked ? 0.05 : 0.03), radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isUnlocked ? Color(hex: color) : Color.clear, lineWidth: 2)
        )
    }
}

struct FirestoreActivityRow: View {
    let word: SavedWordModel
    let isDarkMode: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill((word.isLearned ? Color(hex: "#4ECDC4") : Color(hex: "#A8D8EA")).opacity(0.14))
                    .frame(width: 42, height: 42)

                Image(systemName: word.isLearned ? "checkmark.circle.fill" : "clock.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(word.isLearned ? Color(hex: "#4ECDC4") : Color(hex: "#A8D8EA"))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(word.original)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "#203044"))
                
                Text(word.isLearned ?
                     (LocalizationManager.shared.currentLanguage == .ukrainian ? "Вивчено" :
                      LocalizationManager.shared.currentLanguage == .polish ? "Nauczone" : "Learned") :
                     (LocalizationManager.shared.currentLanguage == .ukrainian ? "Додано" :
                      LocalizationManager.shared.currentLanguage == .polish ? "Dodane" : "Added"))
                .font(.system(size: 14))
                .foregroundColor(isDarkMode ? .gray : Color(hex: "#7F8C8D"))
            }
            
            Spacer()
            
            Text(formattedDate(word.createdAt))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(isDarkMode ? Color.white.opacity(0.52) : Color(hex: "#7F8C8D"))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(isDarkMode ? Color(hex: "#23252B") : Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(isDarkMode ? 0.05 : 0.7), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
        .padding(.horizontal, 20)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
