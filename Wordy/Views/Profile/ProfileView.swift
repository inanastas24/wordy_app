//  ProfileView.swift
//  Wordy
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @AppStorage("learningLanguage") private var learningLanguage: LearningLanguage = .english
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @StateObject private var dictionaryVM = DictionaryViewModel.shared
    
    @State private var showMenu = false
    @State private var selectedTab: Int = 2
    @State private var showSettings = false
    @State private var showLanguageSelection = false
    
    private var totalWords: Int { dictionaryVM.totalWords }
    private var learnedWords: Int { dictionaryVM.learnedCount }
    private var learningWords: Int { dictionaryVM.learningCount }
    private var streak: Int { calculateStreak() }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: localizationManager.isDarkMode ? "#1C1C1E" : "#FFFDF5")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        header
                        
                        // Email користувача (компактно)
                        userEmailSection
                        
                        // Кнопка зміни мови (тільки прапор)
                        changeLanguageButton
                        
                        Text(localizationManager.string(.yourProgress))
                            .font(.system(size: 20))
                            .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                            .padding(.bottom, 10)
                        
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
            }
            .navigationDestination(isPresented: $showLanguageSelection) {
                LearningLanguageSelectionView(
                    isChangeMode: true,
                    onLanguageChanged: {}
                )
                .navigationBarBackButtonHidden(true)
            }
            .onAppear {
                dictionaryVM.fetchSavedWords()
            }
        }
    }
    
    private func calculateStreak() -> Int {
        return min(totalWords, 7)
    }
    
    private var header: some View {
        HStack {
            Button(action: { showMenu = true }) {
                Image(systemName: "line.horizontal.3")
                    .font(.system(size: 24))
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
            }
            
            Spacer()
            
            Text(localizationManager.string(.profile))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
            
            Spacer()
            
            Button(action: { showSettings = true }) {
                Image(systemName: "gear")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#4ECDC4"))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Email користувача (компактний блок)
    private var userEmailSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "#4ECDC4"))
            
            VStack(alignment: .leading, spacing: 4) {
                if !authViewModel.appleEmail.isEmpty {
                    Text(authViewModel.appleEmail)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                } else if let email = authViewModel.user?.email {
                    Text(email)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                } else {
                    Text(localizationManager.string(.user))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                }
                
                Text(localizationManager.string(.profile))
                    .font(.system(size: 12))
                    .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Кнопка зміни мови (тільки прапор, без тексту)
    private var changeLanguageButton: some View {
        Button {
            showLanguageSelection = true
        } label: {
            HStack(spacing: 16) {
                // Прапор поточної мови
                Text(learningLanguage.flag)
                    .font(.system(size: 40))
                
                // Інші прапори (невеликі)
                HStack(spacing: -8) {
                    ForEach(LearningLanguage.allCases.filter { $0 != learningLanguage }) { lang in
                        Text(lang.flag)
                            .font(.system(size: 24))
                            .opacity(0.5)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#4ECDC4"))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
    }
    
    private var statsGrid: some View {
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
                value: "\(streak)",
                label: localizationManager.string(.streakDays),
                color: Color(hex: "#F38BA8"),
                isDarkMode: localizationManager.isDarkMode
            )
        }
        .padding(.horizontal, 20)
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(localizationManager.string(.achievements) + " 🏆")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(localizationManager.isDarkMode ? .white : .primary)
                .padding(.horizontal, 20)
            
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
                        icon: "flame.fill",
                        title: localizationManager.string(.sevenDays),
                        isUnlocked: streak >= 7,
                        color: "#F38BA8",
                        isDarkMode: localizationManager.isDarkMode
                    )
                    
                    AchievementCard(
                        icon: "crown.fill",
                        title: localizationManager.string(.hundredWords),
                        isUnlocked: totalWords >= 100,
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
            if !dictionaryVM.savedWords.isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    Text(localizationManager.currentLanguage == .ukrainian ? "Остання активність" :
                         localizationManager.currentLanguage == .polish ? "Ostatnia aktywność" : "Recent activity")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(localizationManager.isDarkMode ? .white : .primary)
                        .padding(.horizontal, 20)
                    
                    ForEach(dictionaryVM.savedWords.prefix(5)) { word in
                        FirestoreActivityRow(word: word, isDarkMode: localizationManager.isDarkMode)
                    }
                }
            }
        }
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
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(isDarkMode ? .white : Color(hex: "#2C3E50"))
            
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(isDarkMode ? .gray : Color(hex: "#7F8C8D"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
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
                .font(.system(size: 30))
                .foregroundColor(isUnlocked ? Color(hex: color) : (isDarkMode ? .gray : .gray))
                .opacity(isUnlocked ? 1.0 : 0.3)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isUnlocked ? (isDarkMode ? .white : Color(hex: "#2C3E50")) : .gray)
                .multilineTextAlignment(.center)
        }
        .frame(width: 100, height: 100)
        .background(isUnlocked ? Color(hex: color).opacity(0.1) : (isDarkMode ? Color(hex: "#2C2C2E") : Color.gray.opacity(0.1)))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isUnlocked ? Color(hex: color) : Color.clear, lineWidth: 2)
        )
    }
}

struct FirestoreActivityRow: View {
    let word: SavedWordModel
    let isDarkMode: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: word.isLearned ? "checkmark.circle.fill" : "clock.fill")
                .font(.system(size: 24))
                .foregroundColor(word.isLearned ? Color(hex: "#4ECDC4") : Color(hex: "#A8D8EA"))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(word.original)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isDarkMode ? .white : .primary)
                
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
                .font(.caption)
                .foregroundColor(isDarkMode ? .gray : Color(hex: "#7F8C8D"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
