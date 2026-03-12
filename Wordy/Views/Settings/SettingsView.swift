//
//  SettingsView.swift
//  Wordy
//

import SwiftUI
import FirebaseAuth
import SwiftData
import UniformTypeIdentifiers
import LocalAuthentication


struct BiometricSettingsRow: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showExportImport = false
    
    var body: some View {
        if authViewModel.biometricManager.isBiometricAvailable {
            Toggle(isOn: $authViewModel.biometricManager.isEnabled) {
                HStack {
                    Image(systemName: biometricIcon)
                        .foregroundColor(Color(hex: "#4ECDC4"))
                        .frame(width: 30)
                    
                    VStack(alignment: .leading) {
                        Text("Увійти з \(authViewModel.biometricManager.biometricName)")
                            .font(.system(size: 16))
                        
                        Text("Швидкий та безпечний доступ")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            .onChange(of: authViewModel.biometricManager.isEnabled) { _, isEnabled in
                if isEnabled {
                    // Просимо підтвердити біометрію при ввімкненні
                    Task {
                        let success = await authViewModel.biometricManager.authenticate()
                        if !success {
                            authViewModel.biometricManager.setEnabled(false)
                        }
                    }
                }
            }
        }
    }
    
    private var biometricIcon: String {
        switch authViewModel.biometricManager.biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock.shield"
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    @AppStorage("appLanguage") private var appLanguageString: String = "en"
    
    @State private var showExportSheet = false
    @State private var showImportPicker = false
    @State private var exportURL: URL?
    @State private var showImportSuccess = false
    @State private var importedCount = 0
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showLogoutConfirmation = false
    @State private var showPaywall = false
    
    private var appLanguage: Language {
        get { Language(rawValue: appLanguageString) ?? .english }
        set { appLanguageString = newValue.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: localizationManager.isDarkMode ? "#1C1C1E" : "#FFFDF5")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        header
                        userEmailSection
                        subscriptionSection
                        languageSection
                        dataManagementSection
                        appearanceSection
                        logoutSection
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showExportSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
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
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result)
            }
            .alert(importCompletedTitle(), isPresented: $showImportSuccess) {
                Button("OK") { }
            } message: {
                Text(importCompletedMessage(count: importedCount))
            }
            .alert(localizationManager.string(.error), isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
            .confirmationDialog(
                logoutConfirmationTitle(),
                isPresented: $showLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button(logoutButtonTitle(), role: .destructive) { performLogout() }
                Button(cancelButtonTitle(), role: .cancel) { }
            } message: {
                Text(logoutConfirmationMessage())
            }
        }
    }
    
    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
            }
            
            Spacer()
            
            Text(localizationManager.string(.settings))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
            
            Spacer()
            
            Color.clear.frame(width: 20, height: 20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var userEmailSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 44))
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
                
                Text(localizationManager.string(.settings))
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
    
    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Підписка")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                .padding(.horizontal, 20)
            
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
            
            if !subscriptionManager.isPremium {
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 15) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#FFD700").opacity(0.15))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "#FFD700"))
                        }
                        
                        Text(upgradeToPremiumTitle)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "#FFD700"))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#7F8C8D"))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#FFD700").opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var upgradeToPremiumTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Оновити до Premium"
        case .polish: return "Ulepsz do Premium"
        case .english: return "Upgrade to Premium"
        }
    }
    
    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(localizationManager.string(.appLanguage))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Language.allCases) { language in
                        LanguageChip(
                            language: language,
                            isSelected: appLanguage == language,
                            isDarkMode: localizationManager.isDarkMode
                        ) {
                            selectLanguage(language)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
        }
    }
    
    private func selectLanguage(_ language: Language) {
        withAnimation(.spring(response: 0.35)) {
            appLanguageString = language.rawValue
            localizationManager.setLanguage(language)
        }
    }
    
    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(localizationManager.string(.backup))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                .padding(.horizontal, 20)
            
            NavigationLink {
                ExportImportView()
                    .environmentObject(localizationManager)
            } label: {
                SettingsRow(
                    icon: "arrow.up.arrow.down.square",
                    title: localizedExportImportTitle,
                    color: "#4ECDC4",
                    isDarkMode: localizationManager.isDarkMode
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    // НОВЕ: Локалізація для заголовка
    private var localizedExportImportTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Експорт / Імпорт"
        case .polish: return "Eksport / Import"
        case .english: return "Export / Import"
        }
    }
    
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(localizationManager.string(.appearance))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                .padding(.horizontal, 20)
            
            Toggle(isOn: Binding(
                get: { localizationManager.isDarkMode },
                set: { newValue in
                    localizationManager.toggleDarkMode(newValue)
                }
            )) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(localizationManager.isDarkMode ? Color(hex: "#4ECDC4").opacity(0.2) : Color(hex: "#FFD93D").opacity(0.2))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: localizationManager.isDarkMode ? "moon.fill" : "sun.max.fill")
                            .font(.system(size: 18))
                            .foregroundColor(localizationManager.isDarkMode ? Color(hex: "#4ECDC4") : Color(hex: "#FFD93D"))
                    }
                    
                    Text(localizationManager.currentThemeName())
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            )
            .padding(.horizontal, 20)
            .tint(Color(hex: "#4ECDC4"))
        }
    }
    
    private var logoutSection: some View {
        Button {
            showLogoutConfirmation = true
        } label: {
            HStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#F38BA8").opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "arrow.right.square.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "#F38BA8"))
                }
                
                Text(localizationManager.string(.logOut))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#F38BA8"))
                
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
        .buttonStyle(PlainButtonStyle())
    }
    
    private func performLogout() {
        do {
            // Скидаємо всі onboarding прапорці
            UserDefaults.standard.set(false, forKey: "hasSelectedLanguage")
            UserDefaults.standard.set(false, forKey: "hasSelectedLearningLanguage")
            UserDefaults.standard.set(false, forKey: "hasSeenPermissions")
            UserDefaults.standard.set(false, forKey: "hasSeenPaywall")
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            
            // Скидаємо мову навчання
            UserDefaults.standard.removeObject(forKey: "learningLanguage")
            
            try authViewModel.signOut()
            
            // Закриваємо Settings і повертаємось до RootView
            dismiss()
            
            // Надсилаємо нотифікацію для RootView
            NotificationCenter.default.post(name: Notification.Name("userDidLogout"), object: nil)
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func performExport() {
            Task {
                do {
                    let words = try await FirestoreService.shared.fetchWords()
                    
                    let format: ExportFormat = .json
                    let url = try await DictionaryExportService.exportWords(
                        words,
                        format: format,
                        language: localizationManager.currentLanguage
                    )
                    
                    await MainActor.run {
                        exportURL = url
                        showExportSheet = true
                    }
                } catch let error as ExportImportError {
                    await MainActor.run {
                        errorMessage = error.localizedDescription(for: localizationManager.currentLanguage)
                        showError = true
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = ExportImportError.fileCreationFailed.localizedDescription(for: localizationManager.currentLanguage)
                        showError = true
                    }
                }
            }
        }

    private func handleImport(result: Result<[URL], Error>) {
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                
                Task {
                    do {
                        // ВИПРАВЛЕНО: використовуємо ImportResult замість tuple
                        let importResult = try await DictionaryExportService.importWords(
                            from: url,
                            language: localizationManager.currentLanguage
                        )
                        
                        // Зберігаємо імпортовані слова
                        for word in importResult.words {
                            try? await FirestoreService.shared.saveWord(word)
                        }
                        
                        await MainActor.run {
                            importedCount = importResult.importedCount
                            showImportSuccess = true
                        }
                    } catch let error as ExportImportError {
                        await MainActor.run {
                            errorMessage = error.localizedDescription(for: localizationManager.currentLanguage)
                            showError = true
                        }
                    } catch {
                        await MainActor.run {
                            errorMessage = ExportImportError.importFailed.localizedDescription(for: localizationManager.currentLanguage)
                            showError = true
                        }
                    }
                }
                
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    
    private func importCompletedTitle() -> String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Імпорт завершено"
        case .polish: return "Import zakończony"
        case .english: return "Import completed"
        }
    }

    private func importCompletedMessage(count: Int) -> String {
        switch localizationManager.currentLanguage {
        case .ukrainian:
            let word = pluralizeUkrainian(count)
            return "Імпортовано \(count) \(word)"
        case .polish:
            let word = pluralizePolish(count)
            return "Zaimportowano \(count) \(word)"
        case .english:
            return "Imported \(count) \(count == 1 ? "word" : "words")"
        }
    }

    private func pluralizeUkrainian(_ count: Int) -> String {
        let lastDigit = count % 10
        let lastTwoDigits = count % 100
        
        if lastTwoDigits >= 11 && lastTwoDigits <= 19 {
            return "слів"
        }
        
        switch lastDigit {
        case 1: return "слово"
        case 2...4: return "слова"
        default: return "слів"
        }
    }

    private func pluralizePolish(_ count: Int) -> String {
        if count == 1 { return "słowo" }
        let lastDigit = count % 10
        let lastTwoDigits = count % 100
        
        if lastDigit >= 2 && lastDigit <= 4 && (lastTwoDigits < 10 || lastTwoDigits >= 20) {
            return "słowa"
        }
        return "słów"
    }
    
    private func logoutConfirmationTitle() -> String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Вийти з акаунту?"
        case .polish: return "Wylogować się?"
        case .english: return "Sign out?"
        }
    }
    
    private func logoutConfirmationMessage() -> String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Ви впевнені, що хочете вийти?"
        case .polish: return "Czy na pewno chcesz się wylogować?"
        case .english: return "Are you sure you want to sign out?"
        }
    }
    
    private func logoutButtonTitle() -> String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Вийти"
        case .polish: return "Wyloguj"
        case .english: return "Sign out"
        }
    }
    
    private func cancelButtonTitle() -> String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Скасувати"
        case .polish: return "Anuluj"
        case .english: return "Cancel"
        }
    }
}

// MARK: - Supporting Views
struct LanguageChip: View {
    let language: Language
    let isSelected: Bool
    let isDarkMode: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(language.flag)
                    .font(.system(size: 24))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: "#4ECDC4") : (isDarkMode ? Color(hex: "#2C2C2E") : Color.white))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color(hex: "#E0E0E0"), lineWidth: 1)
            )
            .shadow(color: isSelected ? Color(hex: "#4ECDC4").opacity(0.3) : Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: String
    let isDarkMode: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color(hex: color).opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: color))
            }
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isDarkMode ? .white : Color(hex: "#2C3E50"))
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#7F8C8D"))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}
