//
//  SetsView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 10.03.2026.
//

import SwiftUI
import AVFoundation
import Combine

// MARK: - Word Set Store
final class WordSetStore: ObservableObject {
    static let shared = WordSetStore()

    @Published private(set) var addedWordIds: Set<String> = []

    func markAsAdded(wordId: String) {
        addedWordIds.insert(wordId)
    }

    func isAdded(wordId: String) -> Bool {
        addedWordIds.contains(wordId)
    }

    func removeWordId(wordId: String) {
        addedWordIds.remove(wordId)
    }
}

struct SetsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var viewModel = AdaptiveSetsViewModel()

    @State private var selectedCategory: WordCategory?
    @State private var selectedCategoryTitle: String?
    @State private var selectedCategoryEmoji: String?
    @State private var selectedDifficulty: DifficultyLevel?
    @State private var searchText = ""
    @State private var showCategoryWords = false
    @State private var showDifficultyWords = false
    @State private var selectedSet: WordSet?

    @State private var showMenu = false
    @State private var selectedTab: Int = 1
    @State private var showSettings = false

    @State private var gradientRotation: Double = 0
    @FocusState private var isSearchFocused: Bool

    private var filteredWords: [Word] { viewModel.searchResults }

    var body: some View {
        NavigationStack {
            ZStack {
                setsBackground

                VStack(spacing: 0) {
                    HeaderView(showMenu: $showMenu, title: localizationManager.string(.wordSets))
                        .environmentObject(localizationManager)

                    ScrollView {
                        VStack(spacing: 22) {
                            searchBarWithButton
                                .padding(.top, 8)
                                .focused($isSearchFocused)

                            if viewModel.isLoading && !viewModel.hasRemoteContent && searchText.isEmpty {
                                loadingOverviewCard
                            }

                            if !searchText.isEmpty {
                                searchResultsSection
                            }

                            if !viewModel.isLoading || viewModel.hasRemoteContent {
                                filtersSection
                                difficultyLevelsSection
                                categoriesSection
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onAppear {
                        OnboardingContext.isOnDictionaryScreen = false
                    }
                    .task(id: appState.languagePair.languagePairString) {
                        await viewModel.loadOverview(for: appState.languagePair)
                    }
                    .task(id: searchText) {
                        await viewModel.search(query: searchText, languagePair: appState.languagePair)
                    }
                }

                if showMenu {
                    MenuView(isShowing: $showMenu, selectedTab: $selectedTab, showSettings: $showSettings)
                        .transition(.move(edge: .leading))
                        .zIndex(100)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(localizationManager)
                    .environmentObject(appState)
            }
            .navigationDestination(isPresented: $showCategoryWords) {
                if let category = selectedCategory {
                    CategoryWordsView(
                        category: category,
                        selectedDifficulty: selectedDifficulty,
                        languagePair: appState.languagePair,
                        titleOverride: selectedCategoryTitle,
                        emojiOverride: selectedCategoryEmoji
                    )
                }
            }
            .navigationDestination(isPresented: $showDifficultyWords) {
                if let set = selectedSet {
                    WordSetDetailView(set: set, languagePair: appState.languagePair)
                }
            }
        }
    }

    private var setsBackground: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            Circle()
                .fill(Color(hex: "#4ECDC4").opacity(localizationManager.isDarkMode ? 0.16 : 0.14))
                .frame(width: 300, height: 300)
                .blur(radius: 54)
                .offset(x: -150, y: -250)

            Circle()
                .fill(Color(hex: "#FFD166").opacity(localizationManager.isDarkMode ? 0.11 : 0.13))
                .frame(width: 250, height: 250)
                .blur(radius: 56)
                .offset(x: 180, y: -140)
        }
    }

    private var searchBarWithButton: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField(localizationManager.string(.searchSets), text: $searchText)
                .font(.system(size: 16))
                .submitLabel(.search)
                .onSubmit {
                    isSearchFocused = false
                }

            if !searchText.isEmpty {
                Button {
                    isSearchFocused = false
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }

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
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(localizationManager.isDarkMode ? Color(hex: "#23252B") : Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(localizationManager.isDarkMode ? 0.06 : 0.8), lineWidth: 1)
                )
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
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(lineWidth: 3)
            )
            .allowsHitTesting(false)
        )
        .shadow(color: Color.black.opacity(localizationManager.isDarkMode ? 0.14 : 0.06), radius: 14, x: 0, y: 10)
        .onAppear {
            withAnimation(
                .linear(duration: 3)
                .repeatForever(autoreverses: false)
            ) {
                gradientRotation = 360
            }
        }
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            modernSectionHeader(
                title: "\(filteredWords.count) \(localizationManager.string(.words))",
                subtitle: searchResultsSubtitle,
                icon: "sparkle.magnifyingglass",
                tint: "#4ECDC4"
            )

            LazyVStack(spacing: 12) {
                ForEach(filteredWords.prefix(20)) { word in
                    SearchResultWordRow(word: word)
                        .environmentObject(appState)
                }
            }

            if filteredWords.isEmpty && !viewModel.isSearching {
                emptyStateCard(
                    title: "No words yet",
                    message: appState.languagePair.languagePairString == "en-uk"
                        ? "Nothing matched your search."
                        : "The catalog for \(appState.languagePair.source.displayName) → \(appState.languagePair.target.displayName) is still empty."
                )
            }
        }
    }

    private var loadingOverviewCard: some View {
        HStack(spacing: 14) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color(hex: "#4ECDC4"))
                .scaleEffect(0.9)

            VStack(alignment: .leading, spacing: 4) {
                Text(loadingSetsTitle)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#203044"))

                Text(loadingSetsSubtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(localizationManager.isDarkMode ? Color.white.opacity(0.58) : Color(hex: "#6E7C89"))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(localizationManager.isDarkMode ? Color(hex: "#23252B").opacity(0.92) : Color.white.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(localizationManager.isDarkMode ? 0.06 : 0.78), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(localizationManager.isDarkMode ? 0.12 : 0.05), radius: 12, x: 0, y: 8)
    }

    private var filtersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            modernSectionHeader(
                title: localizationManager.string(.filterBy),
                subtitle: filtersSubtitle,
                icon: "line.3.horizontal.decrease.circle.fill",
                tint: "#9B8CFF"
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    SelectableFilterChip(
                        title: localizationManager.string(.filterAll),
                        isSelected: selectedDifficulty == nil && selectedCategory == nil,
                        color: Color(hex: "#4ECDC4")
                    ) {
                        selectedDifficulty = nil
                        selectedCategory = nil
                    }

                    ForEach(DifficultyLevel.allCases, id: \.self) { level in
                        SelectableFilterChip(
                            title: level.displayName,
                            isSelected: selectedDifficulty == level,
                            color: difficultyColor(level)
                        ) {
                            selectedDifficulty = selectedDifficulty == level ? nil : level
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private var difficultyLevelsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            modernSectionHeader(
                title: localizationManager.string(.difficultyLevel),
                subtitle: difficultySubtitle,
                icon: "bolt.badge.checkmark",
                tint: "#FF8A65"
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.availableSets) { set in
                    if selectedDifficulty == nil || set.difficulty == selectedDifficulty {
                        DifficultySetCard(set: set) {
                            selectedSet = set
                            showDifficultyWords = true
                        }
                    }
                }
            }
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                modernSectionHeader(
                    title: localizationManager.string(.popularLanguages),
                    subtitle: categoriesSubtitle,
                    icon: "square.grid.2x2.fill",
                    tint: "#4ECDC4"
                )

                Spacer()

                Text(appState.languagePair.source.flag + " " + appState.languagePair.target.flag)
                    .font(.system(size: 22))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(localizationManager.isDarkMode ? Color.white.opacity(0.07) : Color.white.opacity(0.82))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(localizationManager.isDarkMode ? 0.08 : 0.8), lineWidth: 1)
                    )
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.availableCategories) { summary in
                    CategoryCard(
                        category: summary.category,
                        wordCount: wordCountForCategory(summary.category),
                        titleOverride: viewModel.hasRemoteContent ? summary.title : nil,
                        emojiOverride: viewModel.hasRemoteContent ? summary.emoji : nil
                    ) {
                        selectedCategory = summary.category
                        selectedCategoryTitle = summary.title
                        selectedCategoryEmoji = summary.emoji
                        showCategoryWords = true
                    }
                }
            }

            if !viewModel.hasRemoteContent && appState.languagePair.languagePairString != "en-uk" {
                emptyStateCard(
                    title: "Catalog is empty",
                    message: "Remote sets for \(appState.languagePair.source.displayName) → \(appState.languagePair.target.displayName) will appear here after the catalog is filled."
                )
            }
        }
    }

    private var loadingSetsTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Завантажуємо набори"
        case .polish: return "Ładujemy zestawy"
        case .english: return "Loading sets"
        }
    }

    private var loadingSetsSubtitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Ще мить і підвантажимо категорії та рівні."
        case .polish: return "Jeszcze chwila i pobierzemy kategorie oraz poziomy."
        case .english: return "Just a moment while we load categories and levels."
        }
    }

    private var backgroundColor: Color {
        localizationManager.isDarkMode ? Color(hex: "#1C1C1E") : Color(hex: "#FFFDF5")
    }

    private func difficultyColor(_ level: DifficultyLevel) -> Color {
        switch level {
        case .a1: return .green
        case .a2: return .blue
        case .b1: return .purple
        case .b2: return .pink
        case .c1: return .orange
        case .c2: return .red
        }
    }

    private func wordCountForCategory(_ category: WordCategory) -> Int {
        if let categorySummary = viewModel.availableCategories.first(where: { $0.category == category }) {
            if let difficulty = selectedDifficulty {
                return categorySummary.supportedDifficulties.contains(difficulty) ? categorySummary.wordCount : 0
            }
            return categorySummary.wordCount
        }

        return 0
    }

    private func emptyStateCard(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(localizationManager.isDarkMode ? Color(hex: "#23252B") : Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(localizationManager.isDarkMode ? 0.06 : 0.8), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(localizationManager.isDarkMode ? 0.12 : 0.05), radius: 12, x: 0, y: 8)
    }

    private var searchResultsSubtitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Швидкий доступ до окремих слів і готових фрагментів"
        case .polish: return "Szybki dostęp do słów i gotowych fragmentów"
        case .english: return "Quick access to standalone words and ready-made entries"
        }
    }

    private var filtersSubtitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Звузьте добірки за рівнем і контекстом"
        case .polish: return "Zawężaj zestawy według poziomu i kontekstu"
        case .english: return "Narrow the catalog by level and learning context"
        }
    }

    private var difficultySubtitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Швидкі набори, коли хочеться вчити за рівнем"
        case .polish: return "Szybkie zestawy do nauki według poziomu"
        case .english: return "Fast bundles when you want to learn by level"
        }
    }

    private var categoriesSubtitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Тематичні набори під поточну мовну пару"
        case .polish: return "Tematyczne zestawy dla aktualnej pary językowej"
        case .english: return "Thematic collections tailored to your current language pair"
        }
    }

    @ViewBuilder
    private func modernSectionHeader(title: String, subtitle: String, icon: String, tint: String) -> some View {
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
    }
}

// MARK: - Search Result Word Row
struct SearchResultWordRow: View {
    let word: Word

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var ttsManager = TextToSpeechService.shared
    @StateObject private var dictionaryVM = DictionaryViewModel.shared
    @State private var showAlreadyExistsAlert = false
    @State private var showPermissionAlert = false
    @State private var showDictionaryPicker = false

    private var sourceLanguage: String {
        word.languagePair.components(separatedBy: "-").first ?? appState.languagePair.source.rawValue
    }

    private var targetLanguage: String {
        word.languagePair.components(separatedBy: "-").last ?? appState.languagePair.target.rawValue
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(word.original)
                    .font(.system(size: 16, weight: .semibold))

                HStack(spacing: 6) {
                    Text(word.translation)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#4ECDC4"))

                    Button {
                        ttsManager.toggle(text: word.translation, language: targetLanguage, utteranceID: "set-search-translation-\(word.id)")
                    } label: {
                        Image(systemName: ttsManager.isActive("set-search-translation-\(word.id)") ? "speaker.wave.2.fill" : "speaker.wave.1")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#4ECDC4"))
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                if let transcription = word.transcription {
                    Text(transcription)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            Button {
                checkAndSpeak()
            } label: {
                Image(systemName: ttsManager.isActive(utteranceID) ? "speaker.wave.2.fill" : "speaker.wave.2")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#4ECDC4"))
                    .frame(width: 36, height: 36)
                    .background(Color(hex: "#4ECDC4").opacity(0.15))
                    .clipShape(Circle())
                    .scaleEffect(ttsManager.isActive(utteranceID) ? 0.92 : 1.0)
                    .animation(.spring(response: 0.18, dampingFraction: 0.75), value: ttsManager.isActive(utteranceID))
            }
            .buttonStyle(PlainButtonStyle())
            .alert(localizationManager.string(.permissionRequired), isPresented: $showPermissionAlert) {
                Button(localizationManager.string(.openSettings)) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button(localizationManager.string(.cancel), role: .cancel) {}
            } message: {
                Text(localizationManager.string(.audioPermissionMessage))
            }

            addButton
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(localizationManager.isDarkMode ? Color(hex: "#23252B") : Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(localizationManager.isDarkMode ? 0.05 : 0.76), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(localizationManager.isDarkMode ? 0.12 : 0.05), radius: 12, x: 0, y: 8)
        .alert(localizationManager.string(.wordAlreadyExists), isPresented: $showAlreadyExistsAlert) {
            Button(localizationManager.string(.ok), role: .cancel) { }
        } message: {
            Text(localizationManager.string(.wordAlreadyInDictionary))
        }
        .sheet(isPresented: $showDictionaryPicker) {
            DictionarySelectionSheet(
                dictionaries: dictionaryVM.dictionaries,
                selectedDictionaryId: dictionaryVM.defaultDictionaryId(),
                title: dictionaryTitle
            ) { dictionary in
                let resolvedId = dictionaryVM.resolvedSelectionDictionaryId(for: dictionary)
                print("🎯 SET SEARCH selected dictionary name='\(dictionary.name)' rawId='\(dictionary.id ?? "nil")' resolvedId='\(resolvedId)' word='\(word.original)'")
                saveWord(
                    word,
                    dictionaryId: resolvedId
                )
            }
            .environmentObject(localizationManager)
        }
    }

    private var utteranceID: String {
        "set-search-\(word.id)"
    }
    
    private func checkAndSpeak() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            ttsManager.toggle(text: word.original, language: sourceLanguage, utteranceID: utteranceID)
        } catch {
            print("⚠️ TTS audio session error: \(error)")
            ttsManager.toggle(text: word.original, language: sourceLanguage, utteranceID: utteranceID)
        }
    }

    private var addButton: some View {
        Button {
            addToDictionary(word)
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "#4ECDC4"))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func addToDictionary(_ word: Word) {
        showDictionaryPicker = true
    }

    private func saveWord(_ word: Word, dictionaryId: String) {
        print("🎯 SET SEARCH save word='\(word.original)' dictionaryId='\(dictionaryId)'")
        let savedWord = SavedWordModel(
            id: word.id,
            original: word.original,
            translation: word.translation,
            transcription: word.transcription,
            exampleSentence: word.exampleSentence,
            languagePair: word.languagePair,
            dictionaryId: dictionaryId,
            isLearned: false,
            reviewCount: 0,
            srsInterval: 0,
            srsRepetition: 0,
            srsEasinessFactor: 2.5,
            nextReviewDate: nil,
            lastReviewDate: nil,
            averageQuality: 0.0,
            createdAt: Date(),
            userId: nil
        )

        if dictionaryVM.containsWord(savedWord, in: dictionaryId) {
            showAlreadyExistsAlert = true
            return
        }

        dictionaryVM.saveWord(savedWord)
    }

    private var dictionaryTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Словник"
        case .polish: return "Slownik"
        case .english: return "Dictionary"
        }
    }
}

// MARK: - Supporting Views
struct DifficultySetCard: View {
    let set: WordSet
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(set.emoji)
                        .font(.system(size: 40))

                    Spacer()

                    Text("\(set.wordCount) words")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                        )
                }

                Text(set.title(for: Locale.current.language.languageCode?.identifier ?? "en"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)

                Text(set.difficulty.description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .frame(height: 140)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: set.gradientColors.map { Color(hex: $0) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.18), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                )
            .shadow(color: Color.black.opacity(0.12), radius: 14, x: 0, y: 10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryCard: View {
    let category: WordCategory
    let wordCount: Int
    let titleOverride: String?
    let emojiOverride: String?
    let action: () -> Void

    @EnvironmentObject var localizationManager: LocalizationManager

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(emojiOverride ?? category.defaultEmoji)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color(hex: "#4ECDC4").opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(titleOverride ?? localizationManager.string(category.localizationKey))
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text("\(wordCount) \(localizationManager.string(.words))")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(localizationManager.isDarkMode ? Color(hex: "#23252B") : Color.white.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(localizationManager.isDarkMode ? 0.05 : 0.76), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(localizationManager.isDarkMode ? 0.12 : 0.05), radius: 10, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


struct SelectableFilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? color : Color.gray.opacity(0.15))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Category Words View
struct CategoryWordsView: View {
    let category: WordCategory
    let selectedDifficulty: DifficultyLevel?
    let languagePair: LanguagePair
    let titleOverride: String?
    let emojiOverride: String?

    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AdaptiveSetsViewModel()
    @State private var words: [Word] = []
    @State private var isLoadingWords = false

    var body: some View {
        ZStack {
            contentBackground

            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        Text(emojiOverride ?? category.defaultEmoji)
                            .font(.system(size: 60))

                        Text(titleOverride ?? localizationManager.string(category.localizationKey))
                            .font(.system(size: 24, weight: .bold))

                        Text("\(localizationManager.string(.wordsInCategory)) \((titleOverride ?? localizationManager.string(category.localizationKey)).lowercased())")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    Text("\(words.count) \(localizationManager.string(.words))")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)

                    Group {
                        if isLoadingWords {
                            inlineWordsLoader
                        } else if words.isEmpty {
                            VStack(spacing: 8) {
                                Text("No words in this category yet")
                                    .font(.system(size: 16, weight: .semibold))

                                Text("Fill the remote catalog for \(languagePair.source.displayName) → \(languagePair.target.displayName) to show this section.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(words) { word in
                                    CategoryWordRow(word: word)
                                        .environmentObject(appState)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationTitle(titleOverride ?? localizationManager.string(category.localizationKey))
        .navigationBarTitleDisplayMode(.inline)
        .task(id: languagePair.languagePairString + (selectedDifficulty?.rawValue ?? "all") + category.rawValue) {
            isLoadingWords = true
            words = await viewModel.loadWords(
                for: category,
                difficulty: selectedDifficulty,
                languagePair: languagePair
            )
            isLoadingWords = false
        }
    }

    private var backgroundColor: Color {
        localizationManager.isDarkMode ? Color(hex: "#1C1C1E") : Color(hex: "#FFFDF5")
    }

    private var contentBackground: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            Circle()
                .fill(Color(hex: "#4ECDC4").opacity(localizationManager.isDarkMode ? 0.14 : 0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 56)
                .offset(x: -140, y: -230)
        }
    }

    private var inlineWordsLoader: some View {
        HStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color(hex: "#4ECDC4"))
                .scaleEffect(0.9)

            Text(loadingWordsText)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#203044"))

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(localizationManager.isDarkMode ? Color(hex: "#23252B").opacity(0.9) : Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(localizationManager.isDarkMode ? 0.05 : 0.8), lineWidth: 1)
                )
        )
    }

    private var loadingWordsText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Завантажуємо слова..."
        case .polish: return "Ładujemy słowa..."
        case .english: return "Loading words..."
        }
    }
}

// MARK: - Category Word Row
struct CategoryWordRow: View {
    let word: Word

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var ttsManager = TextToSpeechService.shared
    @StateObject private var dictionaryVM = DictionaryViewModel.shared
    @State private var isExpanded = false
    @State private var showAlreadyExistsAlert = false
    @State private var showPermissionAlert = false
    @State private var showDictionaryPicker = false

    private var sourceLanguage: String {
        word.languagePair.components(separatedBy: "-").first ?? appState.languagePair.source.rawValue
    }

    private var targetLanguage: String {
        word.languagePair.components(separatedBy: "-").last ?? appState.languagePair.target.rawValue
    }

    private var isIrregularVerb: Bool {
        word.category == .irregularVerbs
    }

    private var irregularVerbForms: (base: String, past: String, pastParticiple: String)? {
        guard isIrregularVerb else { return nil }
        let components = word.original.components(separatedBy: " - ")
        guard components.count >= 3 else { return nil }
        return (
            base: components[0].trimmingCharacters(in: .whitespaces),
            past: components[1].trimmingCharacters(in: .whitespaces),
            pastParticiple: components[2].trimmingCharacters(in: .whitespaces)
        )
    }
    
    private var utteranceID: String {
        "set-detail-\(word.id)"
    }
    
    private var displayOriginal: String {
        if isIrregularVerb, let forms = irregularVerbForms {
            return forms.base
        }
        return word.original
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayOriginal)
                        .font(.system(size: 18, weight: .semibold))

                    HStack(spacing: 6) {
                        Text(word.translation)
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#4ECDC4"))

                        Button {
                            ttsManager.toggle(text: word.translation, language: targetLanguage, utteranceID: "set-translation-\(word.id)")
                        } label: {
                            Image(systemName: ttsManager.isActive("set-translation-\(word.id)") ? "speaker.wave.2.fill" : "speaker.wave.1")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#4ECDC4"))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    if let transcription = word.transcription {
                        Text(transcription)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        checkAndSpeak()
                    } label: {
                        Image(systemName: ttsManager.isActive(utteranceID) ? "speaker.wave.2.fill" : "speaker.wave.2")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#4ECDC4"))
                            .frame(width: 36, height: 36)
                            .background(Color(hex: "#4ECDC4").opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .alert(localizationManager.string(.permissionRequired), isPresented: $showPermissionAlert) {
                        Button(localizationManager.string(.openSettings)) {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        Button(localizationManager.string(.cancel), role: .cancel) {}
                    } message: {
                        Text(localizationManager.string(.audioPermissionMessage))
                    }

                    addButton

                    Button {
                        withAnimation(.spring(response: 0.35)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    if isIrregularVerb, let forms = irregularVerbForms {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(localizationManager.string(.verbForms))
                                .font(.system(size: 12))
                                .foregroundColor(.gray)

                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(forms.base)
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Infinitive")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                }

                                Image(systemName: "arrow.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(forms.past)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(hex: "#FF6B6B"))
                                    Text("Past")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                }

                                Image(systemName: "arrow.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(forms.pastParticiple)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(hex: "#4ECDC4"))
                                    Text("Participle")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.1))
                            )
                        }
                    }

                    if let example = word.exampleSentence {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(localizationManager.string(.example))
                                .font(.system(size: 12))
                                .foregroundColor(.gray)

                            HStack {
                                Text("\"\(example)\"")
                                    .font(.system(size: 14))
                                    .italic()

                                Spacer()

                                Button {
                                    ttsManager.toggle(
                                        text: example,
                                        language: sourceLanguage,
                                        utteranceID: "set-example-\(word.id)"
                                    )
                                } label: {
                                    Image(systemName: ttsManager.isActive("set-example-\(word.id)") ? "speaker.wave.2.fill" : "speaker.wave.1")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "#4ECDC4"))
                                        .scaleEffect(ttsManager.isActive("set-example-\(word.id)") ? 0.92 : 1.0)
                                        .animation(.spring(response: 0.18, dampingFraction: 0.75),
                                                   value: ttsManager.isActive("set-example-\(word.id)"))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }

                            if let exampleTranslation = word.exampleTranslation {
                                HStack(alignment: .top, spacing: 8) {
                                    Text(exampleTranslation)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)

                                    Spacer()

                                    Button {
                                        ttsManager.toggle(
                                            text: exampleTranslation,
                                            language: targetLanguage,
                                            utteranceID: "set-example-translation-\(word.id)"
                                        )
                                    } label: {
                                        Image(systemName: ttsManager.isActive("set-example-translation-\(word.id)") ? "speaker.wave.2.fill" : "speaker.wave.1")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(hex: "#4ECDC4"))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }

                    if !word.synonyms.isEmpty {
                        HStack {
                            Text("\(localizationManager.string(.synonyms)): ")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)

                            Text(word.synonyms.joined(separator: ", "))
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#4ECDC4"))
                        }
                    }

                    HStack {
                        Text(word.difficulty.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(difficultyColor(word.difficulty))
                            )
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(localizationManager.isDarkMode ? Color(hex: "#23252B") : Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(localizationManager.isDarkMode ? 0.05 : 0.76), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(localizationManager.isDarkMode ? 0.12 : 0.05), radius: 10, x: 0, y: 8)
        .alert(localizationManager.string(.wordAlreadyExists), isPresented: $showAlreadyExistsAlert) {
            Button(localizationManager.string(.ok), role: .cancel) { }
        } message: {
            Text(localizationManager.string(.wordAlreadyInDictionary))
        }
        .sheet(isPresented: $showDictionaryPicker) {
            DictionarySelectionSheet(
                dictionaries: dictionaryVM.dictionaries,
                selectedDictionaryId: dictionaryVM.defaultDictionaryId(),
                title: dictionaryTitle
            ) { dictionary in
                let resolvedId = dictionaryVM.resolvedSelectionDictionaryId(for: dictionary)
                print("🎯 SET DETAIL selected dictionary name='\(dictionary.name)' rawId='\(dictionary.id ?? "nil")' resolvedId='\(resolvedId)' word='\(word.original)'")
                saveWord(
                    word,
                    dictionaryId: resolvedId
                )
            }
            .environmentObject(localizationManager)
        }
    }

    private func checkAndSpeak() {
        let textToSpeak = isIrregularVerb ? (irregularVerbForms?.base ?? word.original) : word.original

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            ttsManager.toggle(text: textToSpeak, language: sourceLanguage, utteranceID: utteranceID)
        } catch {
            print("⚠️ TTS audio session error: \(error)")
            ttsManager.toggle(text: textToSpeak, language: sourceLanguage, utteranceID: utteranceID)
        }
    }

    private var addButton: some View {
        Button {
            addToDictionary(word)
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(Color(hex: "#4ECDC4"))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func difficultyColor(_ level: DifficultyLevel) -> Color {
        switch level {
        case .a1: return .green
        case .a2: return .blue
        case .b1: return .purple
        case .b2: return .pink
        case .c1: return .orange
        case .c2: return .red
        }
    }

    private func addToDictionary(_ word: Word) {
        showDictionaryPicker = true
    }

    private func saveWord(_ word: Word, dictionaryId: String) {
        print("🎯 SET DETAIL save word='\(word.original)' dictionaryId='\(dictionaryId)'")
        let savedWord = SavedWordModel(
            id: word.id,
            original: word.original,
            translation: word.translation,
            transcription: word.transcription,
            exampleSentence: word.exampleSentence,
            languagePair: word.languagePair,
            dictionaryId: dictionaryId,
            isLearned: false,
            reviewCount: 0,
            srsInterval: 0,
            srsRepetition: 0,
            srsEasinessFactor: 2.5,
            nextReviewDate: nil,
            lastReviewDate: nil,
            averageQuality: 0.0,
            createdAt: Date(),
            userId: nil
        )

        if dictionaryVM.containsWord(savedWord, in: dictionaryId) {
            showAlreadyExistsAlert = true
            return
        }

        dictionaryVM.saveWord(savedWord)
    }

    private var dictionaryTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Словник"
        case .polish: return "Slownik"
        case .english: return "Dictionary"
        }
    }
}

// MARK: - Word Set Detail View
struct WordSetDetailView: View {
    let set: WordSet
    let languagePair: LanguagePair

    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AdaptiveSetsViewModel()
    @State private var words: [Word] = []
    @State private var isLoadingWords = false

    private var isDifficultyBucket: Bool {
        return set.id == "\(languagePair.languagePairString)_\(set.difficulty.rawValue)"
    }

    var body: some View {
        ZStack {
            contentBackground

            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        Text(set.emoji)
                            .font(.system(size: 60))

                        Text(set.title(for: Locale.current.language.languageCode?.identifier ?? "en"))
                            .font(.system(size: 24, weight: .bold))

                        HStack(spacing: 16) {
                            Label("\(set.wordCount) \(localizationManager.string(.words))", systemImage: "text.word.spacing")
                                .font(.system(size: 14))

                            Text("•")

                            Text(set.difficulty.description)
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.gray)
                    }
                    .padding(.top, 20)

                    if isLoadingWords {
                        inlineWordsLoader
                            .padding(.horizontal, 20)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(words) { word in
                                CategoryWordRow(word: word)
                                    .environmentObject(appState)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
        .navigationTitle(set.title(for: Locale.current.language.languageCode?.identifier ?? "en"))
        .navigationBarTitleDisplayMode(.inline)
        .task(id: set.id + languagePair.languagePairString) {
            await reloadWords()
        }
    }

    private var backgroundColor: Color {
        localizationManager.isDarkMode ? Color(hex: "#1C1C1E") : Color(hex: "#FFFDF5")
    }

    private var contentBackground: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            Circle()
                .fill(Color(hex: "#FFD166").opacity(localizationManager.isDarkMode ? 0.10 : 0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 56)
                .offset(x: 150, y: -220)
        }
    }

    private func reloadWords() async {
        isLoadingWords = true
        let loadedWords: [Word]

        if isDifficultyBucket {
            loadedWords = await viewModel.loadDifficultyWords(
                set.difficulty,
                languagePair: languagePair
            )
        } else {
            loadedWords = await viewModel.loadWords(
                for: set.category,
                difficulty: set.difficulty,
                languagePair: languagePair
            )
        }

        words = loadedWords.isEmpty && !set.words.isEmpty ? set.words : loadedWords
        isLoadingWords = false
    }

    private var inlineWordsLoader: some View {
        HStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color(hex: "#4ECDC4"))
                .scaleEffect(0.9)

            Text(loadingWordsText)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#203044"))

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(localizationManager.isDarkMode ? Color(hex: "#23252B").opacity(0.9) : Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(localizationManager.isDarkMode ? 0.05 : 0.8), lineWidth: 1)
                )
        )
    }

    private var loadingWordsText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Завантажуємо слова..."
        case .polish: return "Ładujemy słowa..."
        case .english: return "Loading words..."
        }
    }
}
