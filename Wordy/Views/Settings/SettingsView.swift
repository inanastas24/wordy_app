//1
//  SettingsView.swift
//  Wordy
//

import SwiftUI
import FirebaseAuth
import PhotosUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @StateObject private var profileVM = UserProfileViewModel.shared
    
    @AppStorage("userName") private var userName = ""
    @AppStorage("userAvatar") private var userAvatarData: Data?
    @AppStorage("appLanguage") private var appLanguageString: String = "en"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("hasSelectedLanguage") private var hasSelectedLanguage = true
    @AppStorage("hasSelectedLearningLanguage") private var hasSelectedLearningLanguage = true
    
    @State private var showLogoutConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showReauthAlert = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var tempName: String = ""
    @State private var isEditingName = false
    @FocusState private var isNameFocused: Bool
    
    @State private var showImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
    @State private var showExportSheet = false
    @State private var showImportPicker = false
    @State private var exportURL: URL?
    @State private var showImportSuccess = false
    @State private var importedCount = 0
    
    // MARK: - Computed Properties
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
                        profileSection
                        languageSection
                        dataManagementSection
                        appearanceSection
                        
                        if !authViewModel.isAnonymous {
                            accountManagementSection
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Спочатку перевіряємо UserDefaults, потім ViewModel
                if !userName.isEmpty {
                    tempName = userName
                } else {
                    tempName = profileVM.displayName
                }
                
                selectedImageData = userAvatarData
                
                // Якщо дані відсутні, завантажуємо з Firebase
                if profileVM.displayName.isEmpty && userName.isEmpty {
                    Task {
                        await profileVM.fetchProfile()
                        await MainActor.run {
                            if !profileVM.displayName.isEmpty {
                                tempName = profileVM.displayName
                                userName = profileVM.displayName
                            }
                        }
                    }
                }
            }
            .onChange(of: authViewModel.isAnonymous) { oldValue, newValue in
                        if newValue {
                            // Користувач став анонімним - очищаємо UI
                            tempName = ""
                            selectedImageData = nil
                        } else {
                            // Користувач залогінився - завантажуємо дані
                            Task {
                                await profileVM.fetchProfile()
                                await MainActor.run {
                                    tempName = profileVM.displayName
                                    selectedImageData = profileVM.avatarImage?.jpegData(compressionQuality: 1.0)
                                }
                            }
                        }
                    }
            .confirmationDialog(
                localizationManager.string(.login) + "?",
                isPresented: $showLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button(localizationManager.string(.login), role: .destructive) { performLogout() }
                Button(cancelText(), role: .cancel) { }
            } message: {
                Text(logoutConfirmationText())
            }
            .alert(deleteAccountTitle(), isPresented: $showDeleteAccountConfirmation) {
                Button(cancelText(), role: .cancel) { }
                Button(deleteText(), role: .destructive) { performDeleteAccount() }
            } message: {
                Text(deleteAccountMessage())
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
            .photosPicker(
                isPresented: $showImagePicker,
                selection: $selectedItem,
                matching: .images
            )
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                        userAvatarData = data
                        
                        if let image = UIImage(data: data) {
                            await profileVM.uploadAvatar(image)
                        }
                    }
                }
            }
            .sheet(isPresented: $showExportSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
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
        }
    }
    
    // MARK: - Helper Methods
    private func cancelText() -> String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Скасувати"
        case .polish: return "Anuluj"
        case .english: return "Cancel"
        }
    }
    
    private func logoutConfirmationText() -> String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Ви впевнені, що хочете вийти?"
        case .polish: return "Czy na pewno chcesz się wylogować?"
        case .english: return "Are you sure you want to log out?"
        }
    }
    
    private func deleteAccountTitle() -> String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Видалити акаунт?"
        case .polish: return "Usunąć konto?"
        case .english: return "Delete account?"
        }
    }
    
    private func deleteText() -> String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Видалити"
        case .polish: return "Usuń"
        case .english: return "Delete"
        }
    }
    
    private func deleteAccountMessage() -> String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Цю дію неможливо скасувати. Всі ваші дані будуть назавжди видалені."
        case .polish: return "Tej operacji nie można cofnąć. Wszystkie Twoje dane zostaną trwale usunięte."
        case .english: return "This action cannot be undone. All your data will be permanently deleted."
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
        case .ukrainian: return "Імпортовано \(count) слів"
        case .polish: return "Zaimportowano \(count) słów"
        case .english: return "Imported \(count) words"
        }
    }
    
    private func accountManagementTitle() -> String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Управління акаунтом"
        case .polish: return "Zarządzanie kontem"
        case .english: return "Account Management"
        }
    }
    
    private func deleteAccountButtonTitle() -> String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Видалити акаунт"
        case .polish: return "Usuń konto"
        case .english: return "Delete Account"
        }
    }
    
    // MARK: - UI Sections
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
    
    private var profileSection: some View {
        VStack(spacing: 25) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color(hex: "#4ECDC4").opacity(0.2))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Group {
                            if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .clipShape(Circle())
                            } else if let profileImage = profileVM.avatarImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(Color(hex: "#4ECDC4"))
                            }
                        }
                    )
                
                Circle()
                    .fill(Color(hex: "#4ECDC4"))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    )
                    .offset(x: 5, y: 5)
            }
            .onTapGesture {
                showImagePicker = true
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text(localizationManager.string(.yourName))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                    .padding(.horizontal, 4)
                
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                    
                    TextField(localizationManager.string(.yourName), text: $tempName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                        .focused($isNameFocused)
                        .onTapGesture {
                            if !isEditingName {
                                isEditingName = true
                                isNameFocused = true
                            }
                        }
                    
                    Spacer()
                    
                    Button {
                        if isEditingName {
                            // Save
                            isNameFocused = false
                            Task {
                                await profileVM.updateDisplayName(tempName)
                                await MainActor.run {
                                    userName = tempName  // Оновлюємо AppStorage
                                }
                            }
                        } else {
                            isNameFocused = true
                        }
                        isEditingName.toggle()
                    } label: {
                        Image(systemName: isEditingName ? "checkmark.circle.fill" : "pencil.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(isEditingName ? Color(hex: "#2ECC71") : Color(hex: "#4ECDC4"))
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isEditingName ? Color(hex: "#4ECDC4") : Color.clear, lineWidth: 2)
                )
                .animation(.spring(response: 0.3), value: isEditingName)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
    }
    
    // ОДИН languageSection - виправлений
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
            }
        }
    }
    
    private func selectLanguage(_ language: Language) {
        // Змінюємо напряму appLanguageString замість appLanguage
        withAnimation(.spring(response: 0.35)) {
            appLanguageString = language.rawValue
            localizationManager.setLanguage(language)
        }
        Task {
            await profileVM.updateAppLanguage(language.rawValue)
        }
    }
    
    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(localizationManager.string(.backup))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                Button {
                    performExport()
                } label: {
                    SettingsRow(
                        icon: "square.and.arrow.up",
                        title: localizationManager.string(.exportDictionary),
                        color: "#4ECDC4",
                        isDarkMode: localizationManager.isDarkMode
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button {
                    showImportPicker = true
                } label: {
                    SettingsRow(
                        icon: "square.and.arrow.down",
                        title: localizationManager.string(.importDictionary),
                        color: "#A8D8EA",
                        isDarkMode: localizationManager.isDarkMode
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
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
    
    private var accountManagementSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(accountManagementTitle())
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                Button {
                    showLogoutConfirmation = true
                } label: {
                    SettingsRow(
                        icon: "arrow.right.square.fill",
                        title: localizationManager.string(.login),
                        color: "#FFA07A",
                        isDarkMode: localizationManager.isDarkMode
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button {
                    showDeleteAccountConfirmation = true
                } label: {
                    SettingsRow(
                        icon: "trash.fill",
                        title: deleteAccountButtonTitle(),
                        color: "#F38BA8",
                        isDarkMode: localizationManager.isDarkMode
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Actions
    private func performExport() {
        Task {
            do {
                let words = try await FirestoreService.shared.fetchWords()
                let savedWords = words.map { model in
                    SavedWord(
                        original: model.original,
                        translation: model.translation,
                        transcription: model.transcription ?? "",
                        exampleSentence: model.exampleSentence ?? "",
                        languagePair: model.languagePair
                    )
                }
                let fileURL = try DictionaryExportService.exportWords(savedWords)
                exportURL = fileURL
                showExportSheet = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            Task {
                do {
                    let count = try DictionaryExportService.importWords(from: url, context: modelContext)
                    importedCount = count
                    showImportSuccess = true
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func performLogout() {
        do {
            try Auth.auth().signOut()
            clearLocalUserData()
            authViewModel.user = nil
            authViewModel.isAnonymous = true
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func performDeleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        
        user.delete { error in
            if let error = error {
                let nsError = error as NSError
                if nsError.code == AuthErrorCode.requiresRecentLogin.rawValue {
                    showReauthAlert = true
                } else {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            } else {
                clearLocalUserData()
                authViewModel.user = nil
                authViewModel.isAnonymous = true
                hasCompletedOnboarding = false
                hasSelectedLanguage = false
                hasSelectedLearningLanguage = false
                dismiss()
            }
        }
    }
    
    private func clearLocalUserData() {
        userName = ""
        userAvatarData = nil
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
                
                Text(language.displayName)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .white : (isDarkMode ? .white : Color(hex: "#2C3E50")))
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
