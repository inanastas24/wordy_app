//
//  SettingsView.swift
//  Wordy
//

import SwiftUI
import FirebaseAuth
import SwiftData
import UniformTypeIdentifiers
import LocalAuthentication
import UIKit


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
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var profileViewModel: UserProfileViewModel
    
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
    @State private var nicknameDraft = ""
    @State private var showNicknameEditor = false
    @State private var showImageSourcePicker = false
    @State private var showDeleteAvatarConfirmation = false
    @State private var showImagePicker = false
    @State private var selectedImageSource: UIImagePickerController.SourceType = .photoLibrary
    
    private var appLanguage: Language {
        get { Language(rawValue: appLanguageString) ?? .english }
        set { appLanguageString = newValue.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                settingsBackground
                
                ScrollView {
                    VStack(spacing: 24) {
                        header
                        profileSection
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
                    ShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    isFirstTime: false,
                    onClose: {
                        showPaywall = false
                    },
                    onSubscribe: {
                        showPaywall = false
                    }
                )
                .environmentObject(subscriptionManager)
                .environmentObject(localizationManager)
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
                avatarPickerTitle,
                isPresented: $showImageSourcePicker,
                titleVisibility: .visible
            ) {
                Button(cameraOptionTitle) {
                    presentImagePicker(sourceType: .camera)
                }
                Button(photoLibraryOptionTitle) {
                    presentImagePicker(sourceType: .photoLibrary)
                }
                if profileViewModel.avatarImage != nil {
                    Button(localizationManager.string(.deletePhoto), role: .destructive) {
                        showDeleteAvatarConfirmation = true
                    }
                }
                Button(cancelButtonTitle(), role: .cancel) { }
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
            .alert(deleteAvatarTitle, isPresented: $showDeleteAvatarConfirmation) {
                Button(localizationManager.string(.deletePhoto), role: .destructive) {
                    Task {
                        await profileViewModel.deleteAvatar()
                    }
                }
                Button(cancelButtonTitle(), role: .cancel) { }
            } message: {
                Text(deleteAvatarMessage)
            }
            .alert(localizedNicknameTitle, isPresented: $showNicknameEditor) {
                TextField(localizedNicknamePlaceholder, text: $nicknameDraft)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)

                Button(cancelButtonTitle(), role: .cancel) {
                    nicknameDraft = profileViewModel.displayName
                }

                Button(localizationManager.string(.saveChanges)) {
                    Task {
                        await profileViewModel.updateDisplayName(nicknameDraft)
                    }
                }
            } message: {
                Text(localizedNicknameEditorMessage)
            }
            .sheet(isPresented: $showImagePicker) {
                AvatarImagePicker(sourceType: selectedImageSource) { image in
                    if let image {
                        Task {
                            await profileViewModel.uploadAvatar(image)
                        }
                    }
                }
            }
            .onAppear {
                nicknameDraft = profileViewModel.displayName
                profileViewModel.loadProfile()
            }
            .onChange(of: profileViewModel.displayName) { _, newValue in
                nicknameDraft = newValue
            }
            .onChange(of: profileViewModel.errorMessage) { _, newValue in
                guard let newValue, !newValue.isEmpty else { return }
                errorMessage = newValue
                showError = true
            }
        }
    }
    
    private var settingsBackground: some View {
        ZStack {
            Color(hex: localizationManager.isDarkMode ? "#16171B" : "#FBF8F0")
                .ignoresSafeArea()

            Circle()
                .fill(Color(hex: "#4ECDC4").opacity(localizationManager.isDarkMode ? 0.18 : 0.16))
                .frame(width: 280, height: 280)
                .blur(radius: 50)
                .offset(x: -140, y: -280)

            Circle()
                .fill(Color(hex: "#FFD166").opacity(localizationManager.isDarkMode ? 0.10 : 0.14))
                .frame(width: 240, height: 240)
                .blur(radius: 48)
                .offset(x: 160, y: -170)

            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(localizationManager.isDarkMode ? 0.04 : 0.50),
                            Color(hex: "#4ECDC4").opacity(localizationManager.isDarkMode ? 0.06 : 0.09)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 260)
                .blur(radius: 44)
                .offset(y: -230)
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#203044"))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(localizationManager.isDarkMode ? Color.white.opacity(0.07) : Color.white.opacity(0.92))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(localizationManager.isDarkMode ? 0.08 : 0.7), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(localizationManager.isDarkMode ? 0.12 : 0.06), radius: 12, x: 0, y: 8)
            }
            
            Spacer()
            
            VStack(spacing: 3) {
                Text(localizationManager.string(.settings))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#203044"))

                Text(currentSectionSubtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(localizationManager.isDarkMode ? Color.white.opacity(0.55) : Color(hex: "#6E7C89"))
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color(hex: "#4ECDC4").opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "sparkles")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(hex: "#4ECDC4"))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                avatarButton
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .center, spacing: 10) {
                        Text(currentDisplayName)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#203044"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Button {
                            nicknameDraft = profileViewModel.displayName
                            showNicknameEditor = true
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: "#4ECDC4"))
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(Color(hex: "#4ECDC4").opacity(0.12))
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    Text(currentEmail)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(localizationManager.isDarkMode ? Color.white.opacity(0.68) : Color(hex: "#6E7C89"))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 11, weight: .semibold))
                        Text(profileCardHint)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(Color(hex: "#4ECDC4"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(hex: "#4ECDC4").opacity(0.12))
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 12) {
                profileInfoPill(
                    icon: "person.crop.circle.badge.checkmark",
                    title: profileInfoPrimaryTitle,
                    subtitle: profileInfoPrimarySubtitle,
                    tint: "#4ECDC4"
                )

                profileInfoPill(
                    icon: subscriptionManager.isPremium ? "crown.fill" : "sparkles",
                    title: membershipTitle,
                    subtitle: membershipSubtitle,
                    tint: subscriptionManager.isPremium ? "#FFD166" : "#FF8A65"
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
                        : [Color.white, Color(hex: "#F5F3EA")]
                        ,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.white.opacity(localizationManager.isDarkMode ? 0.06 : 0.7), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(localizationManager.isDarkMode ? 0.16 : 0.07), radius: 22, x: 0, y: 14)
        )
        .padding(.horizontal, 20)
    }
    
    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            settingsSectionHeader(
                title: localizationManager.string(.subscription),
                subtitle: subscriptionSectionSubtitle,
                icon: "crown.fill",
                tint: "#FFD166"
            )
            
            SettingsSubscriptionSection(
                manager: subscriptionManager,
                onManage: {
                    switch subscriptionManager.status {
                    case .premium, .trial:
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            UIApplication.shared.open(url)
                        }
                    case .unknown, .expired, .trialExpired, .billingRetry:
                        showPaywall = true
                    }
                },
                onRestore: {
                    Task {
                        _ = await subscriptionManager.restorePurchases()
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
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "#DDAA27"))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: localizationManager.isDarkMode
                                    ? [Color(hex: "#2A2420"), Color(hex: "#181513")]
                                    : [Color(hex: "#FFF7D8"), Color(hex: "#FFF0BE")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color(hex: "#FFD700").opacity(0.34), lineWidth: 1)
                    )
                    .shadow(color: Color(hex: "#FFD700").opacity(0.12), radius: 12, x: 0, y: 8)
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
        VStack(alignment: .leading, spacing: 14) {
            settingsSectionHeader(
                title: localizationManager.string(.appLanguage),
                subtitle: languageSectionSubtitle,
                icon: "globe.europe.africa.fill",
                tint: "#4ECDC4"
            )
            
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
        VStack(alignment: .leading, spacing: 14) {
            settingsSectionHeader(
                title: localizationManager.string(.backup),
                subtitle: backupSectionSubtitle,
                icon: "arrow.trianglehead.2.clockwise.rotate.90.icloud.fill",
                tint: "#7CC6FE"
            )
            
            NavigationLink {
                ExportImportView()
                    .environmentObject(localizationManager)
                    .environmentObject(appState)
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
        VStack(alignment: .leading, spacing: 14) {
            settingsSectionHeader(
                title: localizationManager.string(.appearance),
                subtitle: appearanceSectionSubtitle,
                icon: localizationManager.isDarkMode ? "moon.stars.fill" : "sun.max.fill",
                tint: localizationManager.isDarkMode ? "#9B8CFF" : "#FFD166"
            )
            
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
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#203044"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(localizationManager.isDarkMode ? Color(hex: "#23252B") : Color.white.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(localizationManager.isDarkMode ? 0.06 : 0.7), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 8)
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
                        .fill(Color(hex: "#F38BA8").opacity(0.14))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "arrow.right.square.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "#F38BA8"))
                }
                
                Text(localizationManager.string(.logOut))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#F38BA8"))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(localizationManager.isDarkMode ? Color(hex: "#23252B") : Color.white.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color(hex: "#F38BA8").opacity(0.16), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 8)
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

    private var avatarButton: some View {
        Button {
            showImageSourcePicker = true
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let avatarImage = profileViewModel.avatarImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#4ECDC4"), Color(hex: "#6BCB77")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text(initialsText)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 84, height: 84)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(localizationManager.isDarkMode ? 0.14 : 0.8), lineWidth: 3)
                )

                ZStack {
                    Circle()
                        .fill(Color(hex: "#4ECDC4"))
                        .frame(width: 28, height: 28)

                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: 4, y: 4)
            }
        }
        .buttonStyle(.plain)
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

    private var currentDisplayName: String {
        let trimmed = profileViewModel.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? localizationManager.string(.user) : trimmed
    }

    private var initialsText: String {
        let source = currentDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else { return "U" }

        let parts = source.split(separator: " ").prefix(2)
        let initials = parts.compactMap { $0.first }.map { String($0).uppercased() }.joined()
        return initials.isEmpty ? "U" : initials
    }

    private var localizedNicknameTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Нікнейм"
        case .polish: return "Pseudonim"
        case .english: return "Nickname"
        }
    }

    private var localizedNicknamePlaceholder: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Введіть нікнейм"
        case .polish: return "Wpisz pseudonim"
        case .english: return "Enter your nickname"
        }
    }

    private var localizedNicknameEditorMessage: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Оновіть нікнейм для свого профілю."
        case .polish: return "Zaktualizuj pseudonim swojego profilu."
        case .english: return "Update your profile nickname."
        }
    }

    private var avatarPickerTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Оберіть дію"
        case .polish: return "Wybierz działanie"
        case .english: return "Choose action"
        }
    }

    private var cameraOptionTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Камера"
        case .polish: return "Aparat"
        case .english: return "Camera"
        }
    }

    private var photoLibraryOptionTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Фотоальбом"
        case .polish: return "Biblioteka zdjęć"
        case .english: return "Photo Library"
        }
    }

    private var deleteAvatarTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Видалити аватар?"
        case .polish: return "Usunąć awatar?"
        case .english: return "Delete avatar?"
        }
    }

    private var deleteAvatarMessage: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Аватар буде видалено з вашого акаунта."
        case .polish: return "Awatar zostanie usunięty z Twojego konta."
        case .english: return "Your avatar will be removed from your account."
        }
    }

    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            errorMessage = cameraUnavailableMessage
            showError = true
            return
        }

        selectedImageSource = sourceType
        showImagePicker = true
    }

    private var cameraUnavailableMessage: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Камера недоступна на цьому пристрої."
        case .polish: return "Aparat nie jest dostępny na tym urządzeniu."
        case .english: return "Camera is not available on this device."
        }
    }

    private var currentSectionSubtitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Профіль, підписка й персональні налаштування"
        case .polish: return "Profil, subskrypcja i ustawienia osobiste"
        case .english: return "Profile, subscription and personal preferences"
        }
    }

    private var profileCardHint: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Редагуйте профіль у кілька дотиків"
        case .polish: return "Edytuj profil w kilku dotknięciach"
        case .english: return "Refresh your profile in a few taps"
        }
    }

    private var profileInfoPrimaryTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Профіль синхронізовано"
        case .polish: return "Profil zsynchronizowany"
        case .english: return "Profile synced"
        }
    }

    private var profileInfoPrimarySubtitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Нікнейм і фото збережені в акаунті"
        case .polish: return "Pseudonim i zdjęcie są zapisane na koncie"
        case .english: return "Nickname and avatar are saved to your account"
        }
    }

    private var membershipTitle: String {
        switch subscriptionManager.status {
        case .premium:
            return localizationManager.currentLanguage == .ukrainian ? "Premium" :
                   localizationManager.currentLanguage == .polish ? "Premium" : "Premium"
        case .trial:
            return localizationManager.currentLanguage == .ukrainian ? "Тріал" :
                   localizationManager.currentLanguage == .polish ? "Okres próbny" : "Trial"
        default:
            return localizationManager.currentLanguage == .ukrainian ? "Вільний план" :
                   localizationManager.currentLanguage == .polish ? "Plan darmowy" : "Free plan"
        }
    }

    private var membershipSubtitle: String {
        switch subscriptionManager.status {
        case .premium:
            return localizationManager.currentLanguage == .ukrainian ? "Розширені можливості активні" :
                   localizationManager.currentLanguage == .polish ? "Rozszerzone funkcje są aktywne" : "Enhanced features are active"
        case .trial:
            return localizationManager.currentLanguage == .ukrainian ? "Знайомство з Premium у процесі" :
                   localizationManager.currentLanguage == .polish ? "Testujesz funkcje Premium" : "You are trying Premium features"
        default:
            return localizationManager.currentLanguage == .ukrainian ? "Можна оновити будь-коли" :
                   localizationManager.currentLanguage == .polish ? "Możesz ulepszyć w dowolnym momencie" : "You can upgrade any time"
        }
    }

    private var subscriptionSectionSubtitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Керуйте підпискою без пошуку в системних меню"
        case .polish: return "Zarządzaj subskrypcją bez szukania w menu systemowym"
        case .english: return "Manage your plan without digging through system menus"
        }
    }

    private var languageSectionSubtitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Змінюйте мову інтерфейсу одним дотиком"
        case .polish: return "Zmieniaj język interfejsu jednym dotknięciem"
        case .english: return "Switch the interface language with one tap"
        }
    }

    private var backupSectionSubtitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Експорт та імпорт для спокійного резервного копіювання"
        case .polish: return "Eksport i import dla spokojnego tworzenia kopii"
        case .english: return "Export and import to keep your vocabulary safe"
        }
    }

    private var appearanceSectionSubtitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Підлаштуйте атмосферу застосунку під себе"
        case .polish: return "Dostosuj klimat aplikacji do siebie"
        case .english: return "Tune the app atmosphere to match your style"
        }
    }

    @ViewBuilder
    private func settingsSectionHeader(title: String, subtitle: String, icon: String, tint: String) -> some View {
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
                    .font(.system(size: 18, weight: .bold, design: .rounded))
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
    private func profileInfoPill(icon: String, title: String, subtitle: String, tint: String) -> some View {
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
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#203044"))

                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(localizationManager.isDarkMode ? Color.white.opacity(0.55) : Color(hex: "#6E7C89"))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(localizationManager.isDarkMode ? Color.white.opacity(0.04) : Color.white.opacity(0.62))
        )
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
            HStack(spacing: 10) {
                Text(language.flag)
                    .font(.system(size: 24))

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.95))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        isSelected
                        ? LinearGradient(
                            colors: [Color(hex: "#4ECDC4"), Color(hex: "#57D7B8")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: isDarkMode ? [Color(hex: "#23252B"), Color(hex: "#1C1D23")] : [Color.white, Color(hex: "#F6F2E7")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? Color.clear : Color.white.opacity(isDarkMode ? 0.08 : 0.9), lineWidth: 1)
            )
            .shadow(color: isSelected ? Color(hex: "#4ECDC4").opacity(0.28) : Color.black.opacity(0.05), radius: 12, x: 0, y: 8)
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
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: color).opacity(0.14))
                    .frame(width: 42, height: 42)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: color))
            }
            
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(isDarkMode ? .white : Color(hex: "#203044"))
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: "#7F8C8D"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(isDarkMode ? Color(hex: "#23252B") : Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(isDarkMode ? 0.06 : 0.7), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 8)
        )
    }
}

struct AvatarImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage?) -> Void


    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: AvatarImagePicker

        init(parent: AvatarImagePicker) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onImagePicked(nil)
            picker.dismiss(animated: true)
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            parent.onImagePicked(image)
            picker.dismiss(animated: true)
        }
    }
}
