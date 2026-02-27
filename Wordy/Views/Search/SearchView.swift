//
//  SearchView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 27.01.2026.
//

import SwiftUI
import AVFoundation

struct SearchView: View {
    @Binding var selectedTab: Int
    @Binding var deepLinkAction: DeepLinkAction?
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @AppStorage("learningLanguage") private var learningLanguage: LearningLanguage = .english
    
    @State private var searchText = ""
    @State private var showMenu = false
    @State private var isRecognizing = false
    @State private var translationResult: TranslationResult?
    @State private var isLoading = false
    @StateObject private var speechService = SpeechRecognitionService()
    @State private var showScanner = false
    @State private var scannedText = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var errorTitle = ""
    @State private var showSettings = false
    @State private var showTranslationCard = false
    @State private var showLanguagePicker = false
    @State private var showVoiceSearch = false
    @State private var showPaywall = false
    
    @FocusState private var isSearchFocused: Bool
    
    private let translationService = TranslationService()
    private let voiceColor = Color(hex: "#FFD93D")
    
    private var currentLearningLanguage: String {
        learningLanguage.rawValue
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: localizationManager.isDarkMode ? "#1C1C1E" : "#FFFDF5")
                    .ignoresSafeArea()
                    .onTapGesture {
                        isSearchFocused = false
                    }
                
                VStack(spacing: 0) {
                    HeaderView(showMenu: $showMenu, title: localizationManager.string(.search))
                        .environmentObject(localizationManager)
                    
                    ScrollView {
                        VStack(spacing: 25) {
                            
                            languageSelector
                            
                            SearchBar(text: $searchText, onSubmit: performSearch)
                                .focused($isSearchFocused)
                            
                            if speechService.isRecording {
                                recordingIndicator
                            }
                            
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .padding()
                            }
                            
                            HStack(spacing: 15) {
                                ActionButton(
                                    icon: "camera.fill",
                                    title: localizationManager.string(.scan),
                                    subtitle: localizationManager.string(.scanText),
                                    color: Color(hex: "#A8D8EA"),
                                    isDarkMode: localizationManager.isDarkMode
                                ) {
                                    isSearchFocused = false
                                    checkCameraPermission()
                                }
                                
                                // 🆕 СПРОЩЕНО: Просто відкриваємо VoiceSearchView по тапу
                                ActionButton(
                                    icon: "mic.fill",
                                    title: localizationManager.string(.voice),
                                    subtitle: localizationManager.string(.holdToSpeak),
                                    color: voiceColor,
                                    isDarkMode: localizationManager.isDarkMode
                                ) {
                                    isSearchFocused = false
                                    showVoiceSearch = true
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            historySection
                            
                            Spacer(minLength: 30)
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
                
                if let result = translationResult, showTranslationCard {
                    TranslationBubbleOverlay(
                        result: result,
                        showTranslationCard: $showTranslationCard,
                        translationResult: $translationResult
                    )
                    .environmentObject(localizationManager)
                    .environmentObject(appState)
                    .environmentObject(authViewModel)
                }
                
                if showMenu {
                    MenuView(isShowing: $showMenu, selectedTab: $selectedTab, showSettings: $showSettings)
                        .transition(.move(edge: .leading))
                        .zIndex(100)
                        .onAppear {
                            isSearchFocused = false
                        }
                }
                
                if showLanguagePicker {
                    languagePickerOverlay
                }
            }
            .sheet(isPresented: $showScanner) {
                TextScannerView(
                    scannedText: $scannedText,
                    isRecognizing: $isRecognizing,
                    onTextRecognized: { text in }
                )
            }
            // 🆕 ОНОВЛЕНО: VoiceSearchView з callback
            .sheet(isPresented: $showVoiceSearch) {
                VoiceSearchView { text, language in
                    print("🎤 SearchView received callback: '\(text)', language: \(language)")
                    self.performVoiceSearch(text: text, spokenLanguage: language)
                }
                .environmentObject(localizationManager)
                .environmentObject(appState)
            }
            .onChange(of: scannedText) { _, newText in
                if !newText.isEmpty {
                    searchText = newText
                    performSearch()
                    scannedText = ""
                }
            }
            .onChange(of: deepLinkAction) { _, newAction in
                handleDeepLinkAction(newAction)
            }
            .onAppear {
                syncLanguageSettings()
                handleDeepLinkAction(deepLinkAction)
            }
            .onChange(of: learningLanguage) { _, newLang in
                appState.learningLanguage = newLang.rawValue
            }
            .alert(errorTitle, isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .fullScreenCover(isPresented: $showPaywall) {
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
            .onChange(of: selectedTab) { _, _ in
                isSearchFocused = false
            }
        }
        .modifier(SubscriptionPaywallModifier())
    }
    
    // MARK: - UI Components
    
    private var recordingIndicator: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "waveform")
                    .font(.system(size: 32))
                    .foregroundColor(voiceColor)
                
                Text("🎙️ \(speechService.recognizedText)")
                    .font(.system(size: 16))
                    .foregroundColor(voiceColor)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(.top, 10)
    }
    
    private var languageSelector: some View {
        Button {
            withAnimation(.spring(response: 0.35)) {
                showLanguagePicker = true
            }
        } label: {
            HStack(spacing: 12) {
                Text(learningLanguage.flag)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(localizationManager.string(.selectLearningLanguage))
                        .font(.system(size: 12))
                        .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                    
                    Text(learningLanguage.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#4ECDC4"))
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
    
    private var languagePickerOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.35)) {
                        showLanguagePicker = false
                    }
                }
            
            VStack(spacing: 20) {
                Text(localizationManager.string(.selectLearningLanguage))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(LearningLanguage.allCases) { language in
                        Button {
                            withAnimation(.spring(response: 0.35)) {
                                learningLanguage = language
                                appState.learningLanguage = language.rawValue
                                showLanguagePicker = false
                            }
                        } label: {
                            VStack(spacing: 8) {
                                Text(language.flag)
                                    .font(.system(size: 40))
                                
                                Text(language.displayName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(learningLanguage == language ? .white : (localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50")))
                            }
                            .frame(maxWidth: .infinity, minHeight: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(learningLanguage == language ? Color(hex: "#4ECDC4") : (localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(learningLanguage == language ? Color.clear : Color(hex: "#E0E0E0"), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Button {
                    withAnimation(.spring(response: 0.35)) {
                        showLanguagePicker = false
                    }
                } label: {
                    Text(localizationManager.currentLanguage == .ukrainian ? "Скасувати" :
                         localizationManager.currentLanguage == .polish ? "Anuluj" : "Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#7F8C8D"))
                        .padding(.vertical, 12)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(localizationManager.isDarkMode ? Color(hex: "#1C1C1E") : Color(hex: "#FFFDF5"))
                    .shadow(color: Color.black.opacity(0.2), radius: 40, x: 0, y: 20)
            )
            .padding(.horizontal, 40)
        }
    }
    
    private var historySection: some View {
        Group {
            if !appState.searchHistory.isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text(localizationManager.string(.recent))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                        
                        Spacer()
                        
                        Button(localizationManager.string(.clear)) {
                            appState.searchHistory.removeAll()
                        }
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                    }
                    .padding(.horizontal, 20)
                    
                    ForEach(appState.searchHistory.prefix(5)) { item in
                        HistoryCard(item: item, isDarkMode: localizationManager.isDarkMode)
                            .onTapGesture {
                                searchText = item.word
                                isSearchFocused = true
                            }
                    }
                }
            } else {
                VStack(spacing: 15) {
                    Image(systemName: "text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(Color(hex: "#A8D8EA"))
                    
                    Text(localizationManager.string(.search))
                        .font(.system(size: 18))
                        .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                    
                    Text(localizationManager.string(.searchPlaceholder))
                        .font(.system(size: 14))
                        .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
            }
        }
    }
    
    // MARK: - Methods
    
    private func syncLanguageSettings() {
        let lang = learningLanguage.rawValue
        appState.learningLanguage = lang
    }
    
    private func handleDeepLinkAction(_ action: DeepLinkAction?) {
        guard let action = action else { return }
        
        switch action {
        case .camera:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.checkCameraPermission()
                self.deepLinkAction = nil
            }
            
        case .voice(let autoStart):
            if autoStart {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.showVoiceSearch = true
                    self.deepLinkAction = nil
                }
            }
        }
    }
    
    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.showScanner = true
                    }
                }
            }
        case .authorized:
            showScanner = true
        case .denied, .restricted:
            showPermissionAlert(for: .camera)
        @unknown default:
            break
        }
    }
    
    private func showPermissionAlert(for type: PermissionType) {
        let title: String
        let message: String
        
        switch type {
        case .camera:
            title = localizationManager.string(.cameraPermission)
            message = localizationManager.string(.permissionMessage)
        case .microphone:
            title = localizationManager.string(.microphonePermission)
            message = localizationManager.string(.permissionMessage)
        case .speech:
            title = localizationManager.string(.speechPermission)
            message = localizationManager.string(.permissionMessage)
        case .tracking:
            title = localizationManager.string(.trackingPermission)
            message = localizationManager.string(.permissionMessage)
        case .notification:
            title = localizationManager.string(.permissionNotificationTitle)
            message = localizationManager.string(.permissionNotificationMessage)
        }
        
        errorTitle = title
        errorMessage = message
        showErrorAlert = true
    }
    
    // MARK: - Search Methods
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        // Визначаємо напрямок перекладу для текстового пошуку
        let detectedLang = translationService.detectLanguageSync(searchText)
        let fromLang: String
        let toLang: String
        
        if let detected = detectedLang {
            if detected == appState.appLanguage {
                fromLang = appState.appLanguage
                toLang = currentLearningLanguage
            } else {
                fromLang = currentLearningLanguage
                toLang = appState.appLanguage
            }
        } else {
            fromLang = currentLearningLanguage
            toLang = appState.appLanguage
        }
        
        executeTranslation(word: searchText, fromLang: fromLang, toLang: toLang)
    }
    
    // 🆕 ОНОВЛЕНИЙ МЕТОД: З явною мовою
    private func performVoiceSearch(text: String, spokenLanguage: String) {
        let detectedLang = translationService.detectLanguageSync(text)
           let actualLanguage = detectedLang ?? spokenLanguage
        print("🎤 performVoiceSearch called with: '\(text)', spokenLanguage: \(spokenLanguage)")
        print("🎤 App language: \(appState.appLanguage), Learning: \(currentLearningLanguage)")
        
        guard !text.isEmpty else {
            print("🎤 Text is empty, returning")
            return
        }
        
        if subscriptionManager.isSubscriptionExpired {
            showPaywall = true
            return
        }
        
        if !subscriptionManager.canUseApp {
            showPaywall = true
            return
        }
        
        // 🆕 ПРАВИЛЬНА ЛОГІКА:
        // Якщо spokenLanguage == мова додатка (uk) → перекладаємо на мову вивчення (pl)
        // Якщо spokenLanguage == мова вивчення (pl) → перекладаємо на мову додатка (uk)
        
        let fromLang: String
        let toLang: String
        
        if spokenLanguage == appState.appLanguage {
            // Користувач говорить мовою додатка (українською)
            // uk → pl
            fromLang = appState.appLanguage      // uk
            toLang = currentLearningLanguage      // pl
            print("🎤 User spoke APP language (\(spokenLanguage)): \(fromLang) → \(toLang)")
        } else if spokenLanguage == currentLearningLanguage {
            // Користувач говорить мовою вивчення (польською)
            // pl → uk
            fromLang = currentLearningLanguage    // pl
            toLang = appState.appLanguage         // uk
            print("🎤 User spoke LEARNING language (\(spokenLanguage)): \(fromLang) → \(toLang)")
        } else {
            // Інша мова → перекладаємо на мову додатка
            fromLang = spokenLanguage
            toLang = appState.appLanguage
            print("🎤 User spoke OTHER language (\(spokenLanguage)): \(fromLang) → \(toLang)")
        }
        
        print("🎤 Final direction: \(fromLang) → \(toLang)")
        
        // Оновлюємо поле пошуку
        self.searchText = text
        
        executeTranslation(word: text, fromLang: fromLang, toLang: toLang)
    }
    
    // 🆕 УНІВЕРСАЛЬНИЙ МЕТОД: Виконання перекладу
    private func executeTranslation(word: String, fromLang: String, toLang: String) {
        print("🎤 executeTranslation: \(word), \(fromLang) → \(toLang)")
        
        isSearchFocused = false
        isLoading = true
        
        Task {
            do {
                try await FirestoreService.shared.logSearch(query: word, result: "searching")
            } catch {
                print("Помилка логування: \(error)")
            }
        }
        
        translationService.translate(
            word: word,
            fromLanguage: fromLang,
            toLanguage: toLang
        ) { result in
            isLoading = false
            
            switch result {
            case .success(let translation):
                print("🎤 Translation success: \(translation.original) → \(translation.translation)")
                
                Task {
                    do {
                        try await FirestoreService.shared.logSearch(query: word, result: translation.translation)
                    } catch {
                        print("Помилка логування: \(error)")
                    }
                }
                
                translationResult = translation
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showTranslationCard = true
                }
                let item = SearchItem(word: translation.original, translation: translation.translation, date: Date())
                appState.searchHistory.insert(item, at: 0)
                searchText = ""
                
            case .failure(let error):
                print("🎤 Translation error: \(error)")
                
                Task {
                    do {
                        try await FirestoreService.shared.logSearch(query: word, result: "error: \(error.localizedDescription)")
                    } catch {
                        print("Помилка логування: \(error)")
                    }
                }
                
                errorTitle = localizationManager.string(.error)
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}

// MARK: - Permission Type
enum PermissionType {
    case camera, microphone, speech, tracking, notification
}
