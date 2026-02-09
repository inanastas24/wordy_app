//1

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @AppStorage("userName") private var userName = ""
    @AppStorage("userAvatar") private var userAvatarData: Data?
    @AppStorage("learningLanguage") private var learningLanguage: LearningLanguage = .english
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @StateObject private var dictionaryVM = DictionaryViewModel.shared
    @StateObject private var profileVM = UserProfileViewModel.shared
    
    @State private var showMenu = false
    @State private var selectedTab: Int = 2
    @State private var showSettings = false
    @State private var showRegistration = false
    @State private var showLanguageSelection = false
    
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    
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
                        headerWithAvatar
                        
                        changeLanguageButton
                        
                        if !userName.isEmpty {
                            greetingText
                        }
                        
                        accountStatusSection
                        
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
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showRegistration) {
                RegistrationPromptView(
                    onComplete: { showRegistration = false },
                    onSkip: { showRegistration = false }
                )
                .environmentObject(authViewModel)
            }
            .navigationDestination(isPresented: $showLanguageSelection) {
                LearningLanguageSelectionView(
                    isChangeMode: true,
                    onLanguageChanged: {
                        Task {
                            await profileVM.updateLearningLanguage(learningLanguage.rawValue)
                        }
                    }
                )
                .navigationBarBackButtonHidden(true)
            }
            .onAppear {
                dictionaryVM.fetchSavedWords()
                
                Task {
                    await authViewModel.loadUserData()
                    
                    // Форсуємо оновлення UI
                    await MainActor.run {
                        // Перечитуємо значення з UserDefaults
                        if let name = UserDefaults.standard.string(forKey: "userName") {
                            userName = name
                        }
                        if let avatar = UserDefaults.standard.data(forKey: "userAvatar") {
                            userAvatarData = avatar
                        }
                    }
                }
            }
                
            .onChange(of: selectedImage) { newImage in
                            if let image = newImage {
                                saveAvatar(image: image)
                            }
                        }
        }
    }
    
    private func calculateStreak() -> Int {
        // Спробуємо отримати з Firestore пізніше
        // Поки що повертаємо мінімальне значення для демонстрації
        return min(totalWords, 7)
    }
    
    private var headerWithAvatar: some View {
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
            
            avatarView
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var avatarView: some View {
        Group {
            if let avatarData = userAvatarData,
               let uiImage = UIImage(data: avatarData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(hex: "#4ECDC4"), lineWidth: 2))
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: "#4ECDC4"))
            }
        }
        .onTapGesture {
            // Відкриваємо налаштування
            showSettings = true
        }
    }

    // Додай цей метод для вибору фото
    private func saveAvatar(image: UIImage) {
            guard let imageData = image.jpegData(compressionQuality: 0.7) else { return }
            
            // Зберігаємо локально
            userAvatarData = imageData
            
            // Зберігаємо в Firestore
            Task {
                await authViewModel.uploadAvatar(imageData)
            }
        }
    
    private var changeLanguageButton: some View {
        Button {
            showLanguageSelection = true
        } label: {
            HStack(spacing: 10) {
                Text(learningLanguage.flag)
                    .font(.system(size: 24))
                
                Text(learningLanguage.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#4ECDC4"))
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#4ECDC4").opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
    }
    
    private var greetingText: some View {
        Text("\(greeting), \(userName)! 👋")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
    }
    
    private var greeting: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Привіт"
        case .polish: return "Cześć"
        case .english: return "Hello"
        }
    }
    
    @ViewBuilder
    private var accountStatusSection: some View {
        if authViewModel.isAnonymous {
            Button {
                showRegistration = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizationManager.string(.signIn))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                        
                        Text(localizationManager.string(.tapToSave))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(hex: "#4ECDC4"))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 20)
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            // ВИПРАВЛЕНО: Кнопка ВИХОДУ замість статичного тексту
            Button {
                do {
                    try authViewModel.signOut()
                } catch {
                    print("❌ Помилка виходу: \(error)")
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizationManager.string(.logOut)) // Або просто "Вийти"
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                        
                        Text(authViewModel.user?.email ?? "User")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.red.opacity(0.5))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 20)
            }
            .buttonStyle(PlainButtonStyle())
        }
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
                    Text("Остання активність")
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
                
                Text(word.isLearned ? "Вивчено" : "Додано")
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
// MARK: - Supporting Views (додай в кінець ProfileView.swift)

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
