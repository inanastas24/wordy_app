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
    @EnvironmentObject var onboardingManager: OnboardingManager
    
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
    @State private var showVoiceSearch = false
    @State private var showPaywall = false
    
    @State private var gradientRotation: Double = 0
    
    @State private var showSourcePicker = false
    @State private var showTargetPicker = false
    
    @FocusState private var isSearchFocused: Bool
    
    private let translationService = TranslationService()
    private var voiceColor: Color {
        Color(hex: localizationManager.isDarkMode ? "#FFCA28" : "#FFD93D")
    }
    private let maxCharacters = 254
    
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
                        VStack(spacing: 20) {
                            // Мови з онбордингом
                            languagePairContainer
                                .padding(.top, 5)
                            
                            searchBarWithButton
                                .focused($isSearchFocused)
                                                        
                                    if speechService.isRecording {
                                        recordingIndicator
                                }
                            
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .padding()
                            }
                            
                            // Кнопки сканування/голосу з онбордингом
                            HStack(spacing: 15) {
                                scanButtonContainer
                                voiceButtonContainer
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 5)
                            
                            historySection
                            
                            Spacer(minLength: 20)
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
                
                // Language Pickers
                if showSourcePicker {
                    languagePicker(
                        title: localizationManager.string(.language1),
                        selectedLanguage: appState.languagePair.source,
                        onSelect: { language in
                            appState.setSourceLanguage(language)
                            withAnimation(.spring(response: 0.35)) {
                                showSourcePicker = false
                            }
                        },
                        onClose: {
                            withAnimation(.spring(response: 0.35)) {
                                showSourcePicker = false
                            }
                        }
                    )
                }
                
                if showTargetPicker {
                    languagePicker(
                        title: localizationManager.string(.language2),
                        selectedLanguage: appState.languagePair.target,
                        onSelect: { language in
                            appState.setTargetLanguage(language)
                            withAnimation(.spring(response: 0.35)) {
                                showTargetPicker = false
                            }
                        },
                        onClose: {
                            withAnimation(.spring(response: 0.35)) {
                                showTargetPicker = false
                            }
                        }
                    )
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
                    .environmentObject(onboardingManager)
                }
                
                if showMenu {
                    MenuView(isShowing: $showMenu, selectedTab: $selectedTab, showSettings: $showSettings)
                        .transition(.move(edge: .leading))
                        .zIndex(100)
                        .onAppear {
                            isSearchFocused = false
                        }
                    }
            }
            .sheet(isPresented: $showScanner) {
                TextScannerView(
                    scannedText: $scannedText,
                    isRecognizing: $isRecognizing,
                    onTextRecognized: { text in },
                    onShowPaywall: {
                        showPaywall = true
                    }
                )
                .environmentObject(subscriptionManager)
            }
            .sheet(isPresented: $showVoiceSearch) {
                VoiceSearchView { text in
                    self.performVoiceSearch(text: text)
                }
                .environmentObject(localizationManager)
                .environmentObject(appState)
                .environmentObject(subscriptionManager)
            }
            .onChange(of: scannedText) { _, newText in
                if !newText.isEmpty {
                    let truncatedText = String(newText.prefix(254))
                    searchText = truncatedText
                    if newText.count > 254 {
                        ToastManager.shared.show(
                            message: localizationManager.string(.textTooLong),
                            style: .warning
                        )
                    }
                    performSearch()
                    scannedText = ""
                }
            }
            .onChange(of: deepLinkAction) { _, newAction in
                handleDeepLinkAction(newAction)
            }
            .onChange(of: showTranslationCard) { _, isShowing in
                if isShowing {
                    print("🎯 Setting hasTranslationResult = true")
                    onboardingManager.hasTranslationResult = true
                } else {
                    // Скидаємо коли картка закривається
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        print("🎯 Setting hasTranslationResult = false")
                        onboardingManager.hasTranslationResult = false
                    }
                }
            }
            .onAppear {
                OnboardingContext.isOnDictionaryScreen = false
                OnboardingContext.justAddedWord = false
                handleDeepLinkAction(deepLinkAction)
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
            .fullScreenCover(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(localizationManager)
            }
            .onChange(of: selectedTab) { _, _ in
                isSearchFocused = false
            }
        }
    }
    
    private var searchBarWithButton: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(localizationManager.string(.searchPlaceholder), text: $searchText)
                .font(.system(size: 16))
                .submitLabel(.search)
                .onChange(of: searchText) { _, newValue in
                    // Ліміт 254 символи
                    if newValue.count > 254 {
                        searchText = String(newValue.prefix(254))
                        ToastManager.shared.show(
                            message: localizationManager.string(.textTooLong),
                            style: .warning
                        )
                    }
                }
                .onSubmit {
                    performSearch()
                }
            
            // Кнопка пошуку
            if !searchText.isEmpty {
                Button {
                    isSearchFocused = false
                    performSearch()
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }
            
            // Кнопка очищення
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
        )
        .overlay(
            AngularGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#4ECDC4"),
                    Color(hex: "#FFD93D"),
                    Color(hex: "#FF6B6B"),
                    Color(hex: "#A8D8EA"),
                    Color(hex: "#4ECDC4")
                ]),
                center: .center,
                angle: .degrees(gradientRotation)
            )
            .mask(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(lineWidth: 3)
            )
            .allowsHitTesting(false)
        )
        .onAppear {
            withAnimation(
                .linear(duration: 3)
                .repeatForever(autoreverses: false)
            ) {
                gradientRotation = 360
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Voice Result Handler
    private func handleVoiceResult(text: String) {
        if text.count > 254 {
            let truncated = String(text.prefix(254))
            searchText = truncated
            ToastManager.shared.show(
                message: localizationManager.string(.voiceInputTooLong),
                style: .warning
            )
        } else {
            searchText = text
        }
        performVoiceSearch(text: searchText)
    }
    // MARK: - Контейнери з онбордингом
    
    private var languagePairContainer: some View {
        editableLanguagePairIndicator
            .padding(.top, 5)
            .onboardingStep(.languagePair)
    }
    
    private var scanButtonContainer: some View {
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
        .onboardingStep(.scanButton)
    }
    
    private var voiceButtonContainer: some View {
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
        .onboardingStep(.voiceButton)
    }
    
    // MARK: - Language Pair Indicator
    
    private var editableLanguagePairIndicator: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.35)) {
                    showSourcePicker = true
                }
            } label: {
                HStack(spacing: 6) {
                    Text(appState.languagePair.source.flag)
                        .font(.system(size: 20))
                    Text(appState.languagePair.source.localizedName(in: localizationManager.currentLanguage))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "#4ECDC4").opacity(0.15))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "#4ECDC4").opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    appState.swapLanguages()
                }
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#4ECDC4"))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color(hex: "#4ECDC4").opacity(0.15))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            Button {
                withAnimation(.spring(response: 0.35)) {
                    showTargetPicker = true
                }
            } label: {
                HStack(spacing: 6) {
                    Text(appState.languagePair.target.flag)
                        .font(.system(size: 20))
                    Text(appState.languagePair.target.localizedName(in: localizationManager.currentLanguage))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "#4ECDC4").opacity(0.15))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "#4ECDC4").opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Language Picker
    
    private func languagePicker(
        title: String,
        selectedLanguage: TranslationLanguage,
        onSelect: @escaping (TranslationLanguage) -> Void,
        onClose: @escaping () -> Void
    ) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)
            
            VStack(spacing: 0) {
                HStack {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(localizationManager.string(.popularLanguages))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "#4ECDC4"))
                                .padding(.horizontal, 4)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(TranslationLanguage.primaryLanguages) { language in
                                    languageGridItem(language: language, isSelected: selectedLanguage == language, onSelect: onSelect)
                                }
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text(localizationManager.string(.otherLanguages))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 4)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(TranslationLanguage.otherLanguages) { language in
                                    languageGridItem(language: language, isSelected: selectedLanguage == language, onSelect: onSelect)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(localizationManager.isDarkMode ? Color(hex: "#1C1C1E") : Color(hex: "#FFFDF5"))
                    .shadow(color: Color.black.opacity(0.2), radius: 40, x: 0, y: 20)
            )
            .padding(.horizontal, 20)
            .frame(maxHeight: 500)
        }
    }
    
    private func languageGridItem(
        language: TranslationLanguage,
        isSelected: Bool,
        onSelect: @escaping (TranslationLanguage) -> Void
    ) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onSelect(language)
        } label: {
            VStack(spacing: 6) {
                Text(language.flag)
                    .font(.system(size: 32))
                
                Text(language.localizedName(in: localizationManager.currentLanguage))
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : (localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50")))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "#4ECDC4") : (localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : (localizationManager.isDarkMode ? Color.gray.opacity(0.3) : Color(hex: "#E0E0E0")), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
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
            title = localizationManager.string(.permissionPermissionNotificationTitle)
            message = localizationManager.string(.permissionNotificationMessage)
        }
        
        errorTitle = title
        errorMessage = message
        showErrorAlert = true
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        // 🆕 БЛОКУВАННЯ: Перевіряємо підписку ПЕРЕД пошуком
        if subscriptionManager.isSubscriptionExpired || !subscriptionManager.canUseApp {
            showPaywall = true
            return
        }
        
        let detectedLang = translationService.detectLanguageSync(searchText)
        
        let fromLang: TranslationLanguage
        let toLang: TranslationLanguage
        
        if let detected = detectedLang,
           let detectedLanguage = TranslationLanguage(rawValue: detected) {
            if detectedLanguage == appState.languagePair.source {
                fromLang = appState.languagePair.source
                toLang = appState.languagePair.target
            } else if detectedLanguage == appState.languagePair.target {
                fromLang = appState.languagePair.target
                toLang = appState.languagePair.source
            } else {
                fromLang = appState.languagePair.source
                toLang = appState.languagePair.target
            }
        } else {
            fromLang = appState.languagePair.source
            toLang = appState.languagePair.target
        }
        
        executeTranslation(word: searchText, fromLang: fromLang, toLang: toLang)
    }
    
    private func performVoiceSearch(text: String) {
        guard !text.isEmpty else { return }
        
        if subscriptionManager.isSubscriptionExpired || !subscriptionManager.canUseApp {
            showPaywall = true
            return
        }
        
        let detectedLang = translationService.detectLanguageSync(text)
        
        let fromLang: TranslationLanguage
        let toLang: TranslationLanguage
        
        if let detected = detectedLang,
           let detectedLanguage = TranslationLanguage(rawValue: detected) {
            if detectedLanguage == appState.languagePair.source {
                fromLang = appState.languagePair.source
                toLang = appState.languagePair.target
            } else if detectedLanguage == appState.languagePair.target {
                fromLang = appState.languagePair.target
                toLang = appState.languagePair.source
            } else {
                fromLang = appState.languagePair.source
                toLang = appState.languagePair.target
            }
        } else {
            fromLang = appState.languagePair.source
            toLang = appState.languagePair.target
        }
        
        self.searchText = text
        executeTranslation(word: text, fromLang: fromLang, toLang: toLang)
    }
    
    private func executeTranslation(word: String, fromLang: TranslationLanguage, toLang: TranslationLanguage) {
        isSearchFocused = false
        isLoading = true
        
        translationService.translate(
            word: word,
            fromLanguage: fromLang.rawValue,
            toLanguage: toLang.rawValue
        ) { result in
            isLoading = false
            
            switch result {
            case .success(let translation):
                translationResult = translation
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showTranslationCard = true
                }
                let item = SearchItem(word: translation.original, translation: translation.translation, date: Date())
                appState.searchHistory.insert(item, at: 0)
                searchText = ""
                
            case .failure(let error):
                errorTitle = localizationManager.string(.error)
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}

enum PermissionType {
    case camera, microphone, speech, tracking, notification
}
