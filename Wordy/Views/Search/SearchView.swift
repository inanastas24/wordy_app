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
    @State private var hasAnimatedIn = false
    
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
                LinearGradient(
                    colors: localizationManager.isDarkMode
                    ? [Color(hex: "#111214"), Color(hex: "#191C1F"), Color(hex: "#131516")]
                    : [Color(hex: "#FFFDF5"), Color(hex: "#F6FFF9"), Color(hex: "#EEF8FF")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Color(hex: "#4ECDC4").opacity(localizationManager.isDarkMode ? 0.12 : 0.16))
                        .frame(width: 220, height: 220)
                        .blur(radius: 30)
                        .offset(x: 70, y: -40)
                }
                .overlay(alignment: .topLeading) {
                    Circle()
                        .fill(Color(hex: "#FFD93D").opacity(localizationManager.isDarkMode ? 0.08 : 0.12))
                        .frame(width: 180, height: 180)
                        .blur(radius: 26)
                        .offset(x: -40, y: 40)
                }
                .onTapGesture {
                    isSearchFocused = false
                }
                
                VStack(spacing: 0) {
                    HeaderView(showMenu: $showMenu, title: localizationManager.string(.search))
                        .environmentObject(localizationManager)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            heroSearchSection
                                .opacity(hasAnimatedIn ? 1 : 0)
                                .offset(y: hasAnimatedIn ? 0 : 18)

                            if speechService.isRecording {
                                recordingIndicator
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            if isLoading {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .padding(.top, 8)
                            }

                            historySection
                                .opacity(hasAnimatedIn ? 1 : 0)
                                .offset(y: hasAnimatedIn ? 0 : 26)
                            
                            Spacer(minLength: 20)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 30)
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
                animateInIfNeeded()
            }
            .alert(errorTitle, isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .dismissKeyboardOnTap()
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
                    .environmentObject(appState)
            }
            .onChange(of: selectedTab) { _, _ in
                isSearchFocused = false
            }
        }
    }

    private var heroSearchSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            languagePairContainer

            searchBarWithButton
                .focused($isSearchFocused)

            HStack(spacing: 10) {
                scanButtonContainer
                voiceButtonContainer
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(localizationManager.isDarkMode ? Color.white.opacity(0.05) : Color.white.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.white.opacity(localizationManager.isDarkMode ? 0.08 : 0.7), lineWidth: 1)
                )
                .shadow(
                    color: Color.black.opacity(localizationManager.isDarkMode ? 0.18 : 0.06),
                    radius: 24,
                    x: 0,
                    y: 16
                )
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color(hex: "#4ECDC4").opacity(localizationManager.isDarkMode ? 0.12 : 0.18))
                .frame(width: 108, height: 108)
                .blur(radius: 18)
                .offset(x: 16, y: -20)
        }
        .padding(.horizontal, 14)
    }

    private var searchBarWithButton: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(localizationManager.isDarkMode ? Color.white.opacity(0.55) : Color(hex: "#7D8C92"))
            
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
        .padding(.horizontal, 15)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(localizationManager.isDarkMode ? Color(hex: "#2A2D31") : Color.white.opacity(0.96))
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
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(lineWidth: 2.5)
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
            .onboardingStep(.languagePair)
    }
    
    private var scanButtonContainer: some View {
        ActionButton(
            icon: "camera.viewfinder",
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
            icon: "waveform.badge.mic",
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
        HStack(spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.35)) {
                    showSourcePicker = true
                }
            } label: {
                HStack(spacing: 6) {
                    Text(appState.languagePair.source.flag)
                        .font(.system(size: 17))
                    Text(appState.languagePair.source.localizedName(in: localizationManager.currentLanguage))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                        .fixedSize(horizontal: false, vertical: true)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(hex: "#4ECDC4").opacity(0.15))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(hex: "#4ECDC4").opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .layoutPriority(1)
            
            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    appState.swapLanguages()
                }
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#4ECDC4"))
                    .frame(width: 32, height: 32)
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
                        .font(.system(size: 17))
                    Text(appState.languagePair.target.localizedName(in: localizationManager.currentLanguage))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                        .fixedSize(horizontal: false, vertical: true)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(hex: "#4ECDC4").opacity(0.15))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(hex: "#4ECDC4").opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .layoutPriority(1)
        }
        .frame(maxWidth: .infinity, alignment: .center)
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
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(localizationManager.isDarkMode ? Color.white.opacity(0.05) : Color.white.opacity(0.62))
        )
        .padding(.horizontal, 20)
    }
    
    private var historySection: some View {
        Group {
            if !appState.searchHistory.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
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
                    
                    VStack(spacing: 10) {
                        ForEach(appState.searchHistory.prefix(6)) { item in
                            recentCompactRow(item)
                        }
                    }
                    .padding(.horizontal, 20)
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

    private func recentCompactRow(_ item: SearchItem) -> some View {
        Button {
            searchText = item.word
            isSearchFocused = true
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.word)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#203743"))
                        .lineLimit(1)

                    Text(item.translation)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#6F7F86"))
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#A8D8EA"))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(localizationManager.isDarkMode ? Color.white.opacity(0.07) : Color.white.opacity(0.86))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(localizationManager.isDarkMode ? 0.06 : 0.7), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func animateInIfNeeded() {
        guard !hasAnimatedIn else { return }
        withAnimation(.spring(response: 0.65, dampingFraction: 0.88).delay(0.04)) {
            hasAnimatedIn = true
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

        let normalized = QueryNormalizer.normalize(
            word,
            language: fromLang.rawValue
        )

        let queryToUse = normalized.isEmpty ? word : normalized
        
        translationService.translate(
            word: queryToUse,
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
