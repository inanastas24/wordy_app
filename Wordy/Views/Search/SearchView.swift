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
    @StateObject private var speechService = SpeechRecognitionService()
    @State private var showScanner = false
    @State private var scannedText = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var errorTitle = ""
    @State private var showSettings = false
    @State private var showVoiceSearch = false
    @State private var showPaywall = false
    @State private var showSaveDictionaryPicker = false
    @State private var saveDictionarySelectionId: String = ""
    @State private var pendingSaveAction: ((String) -> Void)?
    @State private var nextSearchInputMethod: String = "typed"
    
    @State private var hasAnimatedIn = false
    
    @State private var showSourcePicker = false
    @State private var showTargetPicker = false
    @State private var showSearchHistory = false
    
    @FocusState private var isSearchFocused: Bool
    
    @StateObject private var translationViewModel = TranslationViewModel()
    @StateObject private var dictionaryVM = DictionaryViewModel.shared
    @StateObject private var ttsManager = TextToSpeechService.shared
    private var voiceColor: Color {
        Color(hex: localizationManager.isDarkMode ? "#FFCA28" : "#FFD93D")
    }
    private let maxCharacters = 254
    
    var body: some View {
        NavigationStack {
            ZStack {
                (localizationManager.isDarkMode ? Color(hex: "#111214") : Color(hex: "#F7F8F9"))
                    .ignoresSafeArea()
                .onTapGesture {
                    isSearchFocused = false
                }
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 16) {
                            VStack(spacing: 8) {
                                HeaderView(
                                    showMenu: $showMenu,
                                    title: localizationManager.string(.search),
                                    trailingIconName: "clock.arrow.circlepath",
                                    trailingAction: {
                                        isSearchFocused = false
                                        showSearchHistory = true
                                    }
                                )
                                .environmentObject(localizationManager)

                                languagePairSection
                                    .opacity(hasAnimatedIn ? 1 : 0)
                                    .offset(y: hasAnimatedIn ? 0 : 10)

                                heroSearchSection
                                    .opacity(hasAnimatedIn ? 1 : 0)
                                    .offset(y: hasAnimatedIn ? 0 : 10)
                            }

                            if speechService.isRecording {
                                recordingIndicator
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            resultCardsSection
                                .opacity(hasAnimatedIn ? 1 : 0)
                                .offset(y: hasAnimatedIn ? 0 : 26)
                            
                            Spacer(minLength: 20)
                        }
                        .padding(.top, 2)
                        .padding(.bottom, 20)
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
            .sheet(isPresented: $showSaveDictionaryPicker, onDismiss: {
                pendingSaveAction = nil
            }) {
                DictionarySelectionSheet(
                    dictionaries: dictionaryVM.dictionaries,
                    selectedDictionaryId: saveDictionarySelectionId,
                    title: localizedSaveToDictionaryTitle
                ) { dictionary in
                    let selectedId = dictionaryVM.resolvedSelectionDictionaryId(for: dictionary)
                    AnalyticsService.shared.trackSaveDictionarySelected(
                        entityType: "mixed",
                        dictionaryId: selectedId,
                        dictionaryName: dictionary.name
                    )
                    pendingSaveAction?(selectedId)
                    pendingSaveAction = nil
                    saveDictionarySelectionId = selectedId
                }
                .environmentObject(localizationManager)
            }
            .onChange(of: scannedText) { _, newText in
                if !newText.isEmpty {
                    let truncatedText = String(newText.prefix(254))
                    searchText = truncatedText
                    nextSearchInputMethod = "camera"
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
            .onChange(of: searchText) { _, newValue in
                translationViewModel.updateSearchText(
                    newValue,
                    sourceLanguage: appState.languagePair.source.rawValue,
                    targetLanguage: appState.languagePair.target.rawValue
                )
            }
            .onChange(of: appState.languagePair) { _, newPair in
                translationViewModel.updateSearchText(
                    searchText,
                    sourceLanguage: newPair.source.rawValue,
                    targetLanguage: newPair.target.rawValue
                )
                AnalyticsService.shared.setUserProperties(
                    isPremium: subscriptionManager.isPremium,
                    hasActiveTrial: subscriptionManager.isTrialActive,
                    sourceLang: newPair.source.rawValue,
                    targetLang: newPair.target.rawValue
                )
            }
            .onChange(of: translationStateToken) { _, hasResult in
                onboardingManager.hasTranslationResult = hasResult
            }
            .onReceive(translationViewModel.$state) { state in
                guard case let .success(wordCard) = state else { return }
                addSearchHistoryItem(query: searchText, translation: wordCard.mainTranslation)
            }
            .onAppear {
                OnboardingContext.isOnDictionaryScreen = false
                OnboardingContext.justAddedWord = false
                handleDeepLinkAction(deepLinkAction)
                animateInIfNeeded()
                translationViewModel.updateSearchText(
                    searchText,
                    sourceLanguage: appState.languagePair.source.rawValue,
                    targetLanguage: appState.languagePair.target.rawValue
                )
                AnalyticsService.shared.trackTranslationEmptyState(
                    sourceLang: appState.languagePair.source.rawValue,
                    targetLang: appState.languagePair.target.rawValue,
                    reason: "not_searched_yet"
                )
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
            .navigationDestination(isPresented: $showSearchHistory) {
                SearchHistoryView { selectedWord in
                    searchText = selectedWord
                    translationViewModel.updateSearchText(
                        selectedWord,
                        sourceLanguage: appState.languagePair.source.rawValue,
                        targetLanguage: appState.languagePair.target.rawValue
                    )
                    performSearch()
                }
                .environmentObject(appState)
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

    private var languagePairSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            editableLanguagePairIndicator
                .padding(.horizontal, 14)
                .padding(.top, 0)
        }
    }

    private var heroSearchSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            searchBarWithButton
                .focused($isSearchFocused)
        }
        .padding(.horizontal, 14)
        .padding(.top, 0)
    }

    private var searchBarWithButton: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(localizationManager.isDarkMode ? Color.white.opacity(0.55) : Color(hex: "#7D8C92"))

            TextField(localizationManager.string(.searchPlaceholder), text: $searchText)
                .font(.system(size: 16))
                .submitLabel(.search)
                .onChange(of: searchText) { _, newValue in
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

            if !searchText.isEmpty {
                if shouldShowListenButton {
                    SpeakButton(
                        isActive: isSearchTextPlaying,
                        action: playSearchText,
                        activeSystemName: "speaker.wave.2.circle.fill",
                        inactiveSystemName: "speaker.wave.2.fill",
                        font: .system(size: 19, weight: .semibold),
                        foregroundColor: Color(hex: "#4ECDC4"),
                        activeForegroundColor: Color(hex: "#2FB7AE"),
                        frameSize: 36,
                        backgroundColor: nil,
                        activeScale: 1.06
                    )
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Button {
                        isSearchFocused = false
                        performSearch()
                    } label: {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: "#4ECDC4"))
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }

                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
                .frame(width: 36, height: 36)
            } else {
                Button {
                    isSearchFocused = false
                    checkCameraPermission()
                } label: {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                }
                .buttonStyle(.plain)
                .frame(width: 36, height: 36)

                Button {
                    isSearchFocused = false
                    showVoiceSearch = true
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(voiceColor)
                }
                .buttonStyle(.plain)
                .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(localizationManager.isDarkMode ? Color(hex: "#2A2D31") : Color.white.opacity(0.96))
        )
        .frame(maxWidth: .infinity)
    }
    
    private func playSearchText() {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        ttsManager.toggle(
            text: text,
            language: appState.languagePair.source.rawValue,
            utteranceID: searchTextUtteranceID
        )
    }

    private var searchTextUtteranceID: String {
        let languageCode = TextToSpeechService.appleSpeechLanguageCode(
            for: appState.languagePair.source.rawValue
        )

        let normalizedText = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .lowercased()

        return "\(languageCode)|\(normalizedText)"
    }

    private var isSearchTextPlaying: Bool {
        let id = searchTextUtteranceID
        return !id.isEmpty && ttsManager.isActive(id)
    }
    
    // MARK: - Language Pair Indicator
    
    private var editableLanguagePairIndicator: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.35)) {
                    showSourcePicker = true
                }
            } label: {
                Text(appState.languagePair.source.flag)
                    .font(.system(size: 22))
                    .frame(minWidth: 30, minHeight: 30)
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
                    .frame(width: 26, height: 26)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button {
                withAnimation(.spring(response: 0.35)) {
                    showTargetPicker = true
                }
            } label: {
                Text(appState.languagePair.target.flag)
                    .font(.system(size: 22))
                    .frame(minWidth: 30, minHeight: 30)
            }
            .buttonStyle(PlainButtonStyle())
            .layoutPriority(1)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .onboardingStep(.languagePair)
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
    
    private var resultCardsSection: some View {
        Group {
            switch translationViewModel.state {
            case .idle:
                emptySearchState
            case .loading:
                loadingState
            case .success(let wordCard):
                VStack(alignment: .leading, spacing: 12) {
                    if translationViewModel.resultSource == .cache {
                        cachedResultBanner
                    }

                    TranslationResultView(
                        wordCard: wordCard,
                        onSaveWordCard: {
                            saveWordCard(wordCard)
                        },
                        isWordSavedInDictionary: isWordCardSaved(wordCard),
                        onSaveTranslation: { option in
                            saveTranslationOption(option, from: wordCard)
                        },
                        onSaveExample: { example in
                            saveExample(example, from: wordCard)
                        },
                        onSaveSynonym: { synonym in
                            saveSynonym(synonym, from: wordCard)
                        },
                        onSearchSynonym: { synonym in
                            searchText = synonym
                            translationViewModel.searchNow(
                                query: synonym,
                                sourceLanguage: appState.languagePair.source.rawValue,
                                targetLanguage: appState.languagePair.target.rawValue,
                                inputMethod: "synonym_tap"
                            )
                        },
                        showsSourceWordInHeader: true
                    )
                    .environmentObject(localizationManager)
                }
                .padding(.horizontal, 14)
            case .error(let error):
                errorState(error)
            }
        }
    }

    private var translationStateToken: Bool {
        if case .success = translationViewModel.state {
            return true
        }
        return false
    }

    private func animateInIfNeeded() {
        guard !hasAnimatedIn else { return }
        withAnimation(.spring(response: 0.65, dampingFraction: 0.88).delay(0.04)) {
            hasAnimatedIn = true
        }
    }

    private var localizedCardsTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Почніть з пошуку слова"
        case .polish: return "Zacznij od wyszukania słowa"
        case .english: return "Start by searching a word"
        }
    }

    private var localizedCardsHint: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Введіть слово або фразу, щоб побачити переклад, тлумачення та синоніми."
        case .polish: return "Wpisz słowo lub frazę, aby zobaczyć tłumaczenie, znaczenia i synonimy."
        case .english: return "Type a word or phrase to see translation, meanings, and synonyms."
        }
    }

    private var localizedSaveLabel: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "До словника"
        case .polish: return "Do slownika"
        case .english: return "Save"
        }
    }

    private var emptySearchState: some View {
        VStack(spacing: 15) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 56))
                .foregroundColor(Color(hex: "#A8D8EA"))

            Text(localizedCardsTitle)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(localizationManager.isDarkMode ? .white.opacity(0.9) : Color(hex: "#2C3E50"))

            Text(localizedCardsHint)
                .font(.system(size: 14))
                .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
        .padding(.top, 40)
    }

    private var loadingState: some View {
        VStack(spacing: 14) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(localizationManager.isDarkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.85))
                    .frame(height: 120)
                    .redacted(reason: .placeholder)
            }
        }
        .padding(.horizontal, 14)
    }

    private var cachedResultBanner: some View {
        Text(localizedCachedBanner)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Color(hex: "#8A6A00"))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: "#FFD93D").opacity(0.18))
            )
    }

    #if DEBUG
    private var debugProviderBanner: some View {
        Text("DEV source: \(translationViewModel.debugProvider)")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color(hex: "#2C3E50"))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hex: "#4ECDC4").opacity(0.16))
            )
    }
    #endif

    private func errorState(_ error: TranslationError) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "#FF6B6B"))

            Text(error.localizedDescription)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                .multilineTextAlignment(.center)

            Text(error.recoverySuggestion ?? localizedRetryHint)
                .font(.system(size: 14))
                .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                .multilineTextAlignment(.center)

            Button(action: translationViewModel.retry) {
                Text(localizedRetryTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color(hex: "#4ECDC4")))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(localizationManager.isDarkMode ? Color.white.opacity(0.06) : Color.white.opacity(0.82))
        )
        .padding(.horizontal, 14)
    }

    private var localizedCachedBanner: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Показано кешований результат офлайн"
        case .polish: return "Pokazano wynik z pamieci podrecznej"
        case .english: return "Showing cached offline result"
        }
    }

    private var localizedRetryTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Спробувати знову"
        case .polish: return "Sprobuj ponownie"
        case .english: return "Retry"
        }
    }

    private var shouldShowListenButton: Bool {
        let trimmedInput = normalizedQuery(searchText)
        guard !trimmedInput.isEmpty else { return false }
        guard case let .success(wordCard) = translationViewModel.state else { return false }
        return normalizedQuery(wordCard.originalText) == trimmedInput
    }

    private func normalizedQuery(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    private func playCurrentTranslation() {
        guard case let .success(wordCard) = translationViewModel.state else { return }
        ttsManager.toggle(
            text: wordCard.mainTranslation,
            language: appState.languagePair.target.rawValue,
            utteranceID: currentTranslationUtteranceID
        )
    }

    private var currentTranslationUtteranceID: String {
        guard case let .success(wordCard) = translationViewModel.state else { return "" }
        let languageCode = TextToSpeechService.appleSpeechLanguageCode(for: appState.languagePair.target.rawValue)
        let normalizedText = wordCard.mainTranslation
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .lowercased()
        return "\(languageCode)|\(normalizedText)"
    }

    private var isCurrentTranslationPlaying: Bool {
        let id = currentTranslationUtteranceID
        guard !id.isEmpty else { return false }
        return ttsManager.isActive(id)
    }

    private var localizedRetryHint: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Перевірте мережу або спробуйте трохи пізніше."
        case .polish: return "Sprawdz polaczenie lub sprobuj pozniej."
        case .english: return "Check your connection or try again in a moment."
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

    private func saveWordCard(_ wordCard: WordCard) {
        saveWithDictionarySelectionIfNeeded { dictionaryId in
            dictionaryVM.saveWord(wordCard.asSavedWordModel(dictionaryId: dictionaryId))
            print("[DictionarySave] saved whole WordCard id=\(wordCard.id) dictionaryId=\(dictionaryId)")
            AnalyticsService.shared.trackSaveSuccess(entityType: "word", dictionaryId: dictionaryId)
            ToastManager.shared.show(
                message: localizationManager.currentLanguage == .ukrainian ? "Слово додано у словник" : "Word saved to dictionary",
                style: .success
            )
        }
    }

    private func isWordCardSaved(_ wordCard: WordCard) -> Bool {
        let normalizedOriginal = QueryNormalizer.normalize(wordCard.originalText, language: wordCard.sourceLanguage)
        return dictionaryVM.savedWords.contains { saved in
            let samePair = saved.sourceLanguage == wordCard.sourceLanguage && saved.targetLanguage == wordCard.targetLanguage
            if !samePair { return false }
            let savedNormalized = QueryNormalizer.normalize(saved.original, language: saved.sourceLanguage)
            return savedNormalized == normalizedOriginal
        }
    }

    private func saveTranslationOption(_ option: TranslationOption, from wordCard: WordCard) {
        AnalyticsService.shared.trackSaveClicked(entityType: "translation")
        saveWithDictionarySelectionIfNeeded { dictionaryId in
            let word = wordCard.asSavedWordModel(
                dictionaryId: dictionaryId,
                selectedTranslationOptionIds: [option.id.uuidString]
            )
            dictionaryVM.saveWord(word)
            print("[DictionarySave] saved translationOption id=\(option.id.uuidString) dictionaryId=\(dictionaryId)")
            AnalyticsService.shared.trackSaveSuccess(entityType: "translation", dictionaryId: dictionaryId)
            ToastManager.shared.show(
                message: localizationManager.currentLanguage == .ukrainian ? "Варіант перекладу збережено" : "Translation saved",
                style: .success
            )
        }
    }

    private func saveExample(_ example: WordExample, from wordCard: WordCard) {
        AnalyticsService.shared.trackSaveClicked(entityType: "example")
        let word = wordCard.asSavedWordModel(
            dictionaryId: dictionaryVM.defaultDictionaryId(),
            selectedExampleIds: [example.id.uuidString]
        )
        dictionaryVM.saveWord(word)
        let resolvedDictionaryId = word.dictionaryId ?? dictionaryVM.defaultDictionaryId()
        print("[DictionarySave] saved example id=\(example.id.uuidString) dictionaryId=\(resolvedDictionaryId)")
        AnalyticsService.shared.trackSaveSuccess(entityType: "example", dictionaryId: resolvedDictionaryId)
        ToastManager.shared.show(
            message: localizationManager.currentLanguage == .ukrainian ? "Приклад збережено" : "Example saved",
            style: .success
        )
    }

    private func saveSynonym(_ synonym: WordSynonym, from wordCard: WordCard) {
        let entityType = wordCard.antonyms.contains(where: { $0.id == synonym.id }) ? "antonym" : "synonym"
        AnalyticsService.shared.trackSaveClicked(entityType: entityType)
        saveWithDictionarySelectionIfNeeded { dictionaryId in
            let sourceLanguage = synonym.language.isEmpty ? wordCard.sourceLanguage : synonym.language
            let targetLanguage = (synonym.translationLanguage?.isEmpty == false ? synonym.translationLanguage : nil) ?? wordCard.targetLanguage
            let resolvedTranslation = (synonym.translation?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
                ? synonym.translation!.trimmingCharacters(in: .whitespacesAndNewlines)
                : wordCard.mainTranslation

            let word = SavedWordModel(
                original: synonym.word,
                translation: resolvedTranslation,
                normalizedText: QueryNormalizer.normalize(synonym.word, language: sourceLanguage),
                mainTranslation: resolvedTranslation,
                translations: [
                    TranslationOption(
                        value: resolvedTranslation,
                        partOfSpeech: synonym.partOfSpeech ?? "unknown",
                        meaningId: synonym.meaningId,
                        confidence: synonym.relevance ?? 0.64,
                        sourceType: .contextual,
                        examples: []
                    )
                ],
                languagePair: "\(sourceLanguage)-\(targetLanguage)",
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                synonyms: wordCard.synonyms.contains(where: { $0.id == synonym.id }) ? [synonym] : [],
                antonyms: wordCard.antonyms.contains(where: { $0.id == synonym.id }) ? [synonym] : [],
                source: .dictionaryAPI,
                dictionaryId: dictionaryId,
                wordCard: nil,
                selectedSynonymIds: [synonym.id.uuidString]
            )
            dictionaryVM.saveWord(word)
            print("[DictionarySave] saved synonym word='\(synonym.word)' translation='\(resolvedTranslation)' id=\(synonym.id.uuidString) dictionaryId=\(dictionaryId)")
            AnalyticsService.shared.trackSaveSuccess(entityType: entityType, dictionaryId: dictionaryId)
            ToastManager.shared.show(
                message: localizationManager.currentLanguage == .ukrainian ? "Синонім збережено" : "Synonym saved",
                style: .success
            )
        }
    }

    private func saveWithDictionarySelectionIfNeeded(_ save: @escaping (String) -> Void) {
        let dictionaries = dictionaryVM.dictionaries
        let defaultDictionaryId = dictionaryVM.defaultDictionaryId()

        guard dictionaries.count > 1 else {
            save(defaultDictionaryId)
            return
        }

        saveDictionarySelectionId = defaultDictionaryId
        AnalyticsService.shared.trackSaveDictionaryPickerOpened(
            entityType: "mixed",
            dictionariesCount: dictionaries.count
        )
        pendingSaveAction = save
        showSaveDictionaryPicker = true
    }

    private var localizedSaveToDictionaryTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Оберіть словник"
        case .polish: return "Wybierz slownik"
        case .english: return "Choose Dictionary"
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        // 🆕 БЛОКУВАННЯ: Перевіряємо підписку ПЕРЕД пошуком
        if subscriptionManager.isSubscriptionExpired || !subscriptionManager.canUseApp {
            showPaywall = true
            return
        }
        
        translationViewModel.searchNow(
            query: searchText,
            sourceLanguage: appState.languagePair.source.rawValue,
            targetLanguage: appState.languagePair.target.rawValue,
            inputMethod: nextSearchInputMethod
        )
        nextSearchInputMethod = "typed"
    }
    
    private func performVoiceSearch(text: String) {
        guard !text.isEmpty else { return }
        
        if subscriptionManager.isSubscriptionExpired || !subscriptionManager.canUseApp {
            showPaywall = true
            return
        }
        
        self.searchText = text
        nextSearchInputMethod = "voice"
        isSearchFocused = false
        translationViewModel.searchNow(
            query: text,
            sourceLanguage: appState.languagePair.source.rawValue,
            targetLanguage: appState.languagePair.target.rawValue,
            inputMethod: "voice"
        )
    }

    private func addSearchHistoryItem(query: String, translation: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTranslation = translation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty, !trimmedTranslation.isEmpty else { return }

        if let first = appState.searchHistory.first,
           first.word.caseInsensitiveCompare(trimmedQuery) == .orderedSame,
           first.translation.caseInsensitiveCompare(trimmedTranslation) == .orderedSame {
            return
        }

        appState.searchHistory.removeAll {
            $0.word.caseInsensitiveCompare(trimmedQuery) == .orderedSame
        }
        appState.searchHistory.insert(
            SearchItem(word: trimmedQuery, translation: trimmedTranslation, date: Date()),
            at: 0
        )

        let maxItems = 100
        if appState.searchHistory.count > maxItems {
            appState.searchHistory = Array(appState.searchHistory.prefix(maxItems))
        }
    }
}

enum PermissionType {
    case camera, microphone, speech, tracking, notification
}
