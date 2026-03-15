//
//  SetsView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 10.03.2026.
//

import SwiftUI
import AVFoundation
import Combine

// MARK: - TTS Manager (ОНОВЛЕНИЙ - без memory leaks)
@MainActor
final class TTSManager: ObservableObject {
    static let shared = TTSManager()
    
    @Published var isPlaying = false
    @Published var currentText: String = ""
    
    private let synthesizer = AVSpeechSynthesizer()
    private var delegate: TTSDelegate?
    
    private init() {
        let newDelegate = TTSDelegate()
        self.delegate = newDelegate
        synthesizer.delegate = newDelegate
        newDelegate.manager = self
    }
    
    func speak(text: String, language: String = "en") {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        currentText = text
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language == "en" ? "en-US" : language)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        isPlaying = true
        synthesizer.speak(utterance)
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isPlaying = false
        currentText = ""
    }
    
    fileprivate func handleDidFinish() {
        isPlaying = false
        currentText = ""
    }
}

// MARK: - TTS Delegate
private final class TTSDelegate: NSObject, AVSpeechSynthesizerDelegate {
    weak var manager: TTSManager?
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.manager?.handleDidFinish()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.manager?.handleDidFinish()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.manager?.handleDidFinish()
        }
    }
}

// MARK: - Word Set Store
class WordSetStore: ObservableObject {
    static let shared = WordSetStore()
    
    @Published private(set) var addedWordIds: Set<String> = []
    
    func markAsAdded(wordId: String) {
        addedWordIds.insert(wordId)
    }
    
    func isAdded(wordId: String) -> Bool {
        return addedWordIds.contains(wordId)
    }
    
    func removeWordId(wordId: String) {
        addedWordIds.remove(wordId)
    }
}

struct SetsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var selectedCategory: WordCategory?
    @State private var selectedDifficulty: DifficultyLevel?
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var showCategoryWords = false
    @State private var showDifficultyWords = false
    @State private var selectedSet: WordSet?
    
    @State private var showMenu = false
    @State private var selectedTab: Int = 1
    @State private var showSettings = false
    
    @State private var gradientRotation: Double = 0
        
    @FocusState private var isSearchFocused: Bool
    
    private var filteredWords: [Word] {
        if searchText.isEmpty {
            return []
        }
        return PredefinedWordSets.searchWords(query: searchText)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HeaderView(showMenu: $showMenu, title: localizationManager.string(.wordSets))
                        .environmentObject(localizationManager)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            searchBarWithButton
                                .padding(.top, 8)
                                .focused($isSearchFocused)
                            
                            if !searchText.isEmpty {
                                searchResultsSection
                            }
                            
                            filtersSection
                            difficultyLevelsSection
                            categoriesSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onAppear {
                        OnboardingContext.isOnDictionaryScreen = false
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
            }
            .navigationDestination(isPresented: $showCategoryWords) {
                if let category = selectedCategory {
                    CategoryWordsView(
                        category: category,
                        selectedDifficulty: selectedDifficulty
                    )
                }
            }
            .navigationDestination(isPresented: $showDifficultyWords) {
                if let set = selectedSet {
                    WordSetDetailView(set: set)
                }
            }
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color(hex: "#F5F5F5"))
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
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localizationManager.string(.wordSetsSubtitle))
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(localizationManager.string(.searchSets), text: $searchText)
                .font(.system(size: 16))
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color(hex: "#F5F5F5"))
        )
    }
    
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(filteredWords.count) \(localizationManager.string(.words))")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button {
                    searchText = ""
                } label: {
                    Text(localizationManager.string(.clear))
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                }
            }
            
            LazyVStack(spacing: 12) {
                ForEach(filteredWords.prefix(20)) { word in
                    SearchResultWordRow(word: word)
                }
            }
        }
    }
    
    private var filtersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localizationManager.string(.filterBy))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            
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
            Text(localizationManager.string(.difficultyLevel))
                .font(.system(size: 20, weight: .bold))
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(PredefinedWordSets.allSets) { set in
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
            Text(localizationManager.string(.popularLanguages))
                .font(.system(size: 20, weight: .bold))
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(WordCategory.allCases, id: \.self) { category in
                    CategoryCard(
                        category: category,
                        wordCount: wordCountForCategory(category)
                    ) {
                        selectedCategory = category
                        showCategoryWords = true
                    }
                }
            }
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
        let words = PredefinedWordSets.words(for: category)
        if let difficulty = selectedDifficulty {
            return words.filter { $0.difficulty == difficulty }.count
        }
        return words.count
    }
}

// MARK: - Search Result Word Row
struct SearchResultWordRow: View {
    let word: Word
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var ttsManager = TTSManager.shared
    @StateObject private var dictionaryVM = DictionaryViewModel.shared
    @State private var isAdded = false
    @State private var showAlreadyExistsAlert = false
    @State private var showPermissionAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(word.original)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(word.translation)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#4ECDC4"))
                
                if let transcription = word.transcription {
                    Text(transcription)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Listen button with permission check
            Button {
                checkAndSpeak()
            } label: {
                Image(systemName: ttsManager.isPlaying && ttsManager.currentText == word.original ? "speaker.wave.2.fill" : "speaker.wave.2")
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
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
        )
        .onAppear {
            updateAddedState()
        }
        .onChange(of: dictionaryVM.savedWords.count, initial: false) { _, _ in
            updateAddedState()
        }
        .alert(localizationManager.string(.wordAlreadyExists), isPresented: $showAlreadyExistsAlert) {
            Button(localizationManager.string(.ok), role: .cancel) { }
        } message: {
            Text(localizationManager.string(.wordAlreadyInDictionary))
        }
    }
    
    private func checkAndSpeak() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            ttsManager.speak(text: word.original, language: "en")
        } catch {
            print("⚠️ TTS audio session error: \(error)")
            ttsManager.speak(text: word.original, language: "en")
        }
    }
    
    private func updateAddedState() {
        isAdded = dictionaryVM.savedWords.contains { $0.id == word.id }
    }
    
    private var addButton: some View {
        Button {
            addToDictionary(word)
        } label: {
            Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "#4ECDC4"))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isAdded)
    }
    
    private func addToDictionary(_ word: Word) {
        let isInDictionary = dictionaryVM.savedWords.contains { $0.id == word.id }
        guard !isInDictionary else {
            showAlreadyExistsAlert = true
            return
        }
        
        let savedWord = SavedWordModel(
            id: word.id,
            original: word.original,
            translation: word.translation,
            transcription: word.transcription,
            exampleSentence: word.exampleSentence,
            languagePair: "en-uk",
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
        
        dictionaryVM.saveWord(savedWord)
        
        withAnimation {
            isAdded = true
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
                    .font(.system(size: 16, weight: .semibold))
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
                LinearGradient(
                    colors: set.gradientColors.map { Color(hex: $0) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryCard: View {
    let category: WordCategory
    let wordCount: Int
    let action: () -> Void
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(category.defaultEmoji)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color(hex: "#4ECDC4").opacity(0.15))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(localizationManager.string(category.localizationKey))
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
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
            )
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
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? color : Color.gray.opacity(0.2))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Category Words View
struct CategoryWordsView: View {
    let category: WordCategory
    let selectedDifficulty: DifficultyLevel?
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var appState: AppState
    @StateObject private var ttsManager = TTSManager.shared
    
    private var words: [Word] {
        let allWords = PredefinedWordSets.words(for: category)
        if let difficulty = selectedDifficulty {
            return allWords.filter { $0.difficulty == difficulty }
        }
        return allWords
    }
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        Text(category.defaultEmoji)
                            .font(.system(size: 60))
                        
                        Text(localizationManager.string(category.localizationKey))
                            .font(.system(size: 24, weight: .bold))
                        
                        Text("\(localizationManager.string(.wordsInCategory)) \(localizationManager.string(category.localizationKey).lowercased())")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    Text("\(words.count) \(localizationManager.string(.words))")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(words) { word in
                            CategoryWordRow(word: word)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationTitle(localizationManager.string(category.localizationKey))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var backgroundColor: Color {
        localizationManager.isDarkMode ? Color(hex: "#1C1C1E") : Color(hex: "#FFFDF5")
    }
}

// MARK: - Category Word Row
struct CategoryWordRow: View {
    let word: Word
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var ttsManager = TTSManager.shared
    @StateObject private var dictionaryVM = DictionaryViewModel.shared
    @State private var isExpanded = false
    @State private var isAdded = false
    @State private var showAlreadyExistsAlert = false
    @State private var showPermissionAlert = false
    
    private var isIrregularVerb: Bool {
        word.category == .irregularVerbs
    }
    
    private var irregularVerbForms: (base: String, past: String, pastParticiple: String)? {
        guard isIrregularVerb else { return nil }
        let components = word.original.components(separatedBy: " - ")
        guard components.count >= 3 else { return nil }
        return (base: components[0].trimmingCharacters(in: .whitespaces),
                past: components[1].trimmingCharacters(in: .whitespaces),
                pastParticiple: components[2].trimmingCharacters(in: .whitespaces))
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
                    
                    Text(word.translation)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                    
                    if let transcription = word.transcription {
                        Text(transcription)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Listen button with permission check
                    Button {
                        checkAndSpeak()
                    } label: {
                        let textToSpeak = isIrregularVerb ? (irregularVerbForms?.base ?? word.original) : word.original
                        Image(systemName: ttsManager.isPlaying && ttsManager.currentText == textToSpeak ? "speaker.wave.2.fill" : "speaker.wave.2")
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
                                    ttsManager.speak(text: example, language: "en")
                                } label: {
                                    Image(systemName: "speaker.wave.1")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "#4ECDC4"))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            if let exampleTranslation = word.exampleTranslation {
                                Text(exampleTranslation)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
        .onAppear {
            updateAddedState()
        }
        .onChange(of: dictionaryVM.savedWords.count, initial: false) { _, _ in
            updateAddedState()
        }
        .alert(localizationManager.string(.wordAlreadyExists), isPresented: $showAlreadyExistsAlert) {
            Button(localizationManager.string(.ok), role: .cancel) { }
        } message: {
            Text(localizationManager.string(.wordAlreadyInDictionary))
        }
    }
    
    private func checkAndSpeak() {
        let textToSpeak = isIrregularVerb ? (irregularVerbForms?.base ?? word.original) : word.original
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            ttsManager.speak(text: textToSpeak, language: "en")
        } catch {
            print("⚠️ TTS audio session error: \(error)")
            ttsManager.speak(text: textToSpeak, language: "en")
        }
    }
    
    private func updateAddedState() {
        isAdded = dictionaryVM.savedWords.contains { $0.id == word.id }
    }
    
    private var addButton: some View {
        Button {
            addToDictionary(word)
        } label: {
            Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(Color(hex: "#4ECDC4"))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isAdded)
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
        let isInDictionary = dictionaryVM.savedWords.contains { $0.id == word.id }
        guard !isInDictionary else {
            showAlreadyExistsAlert = true
            return
        }
        
        let savedWord = SavedWordModel(
            id: word.id,
            original: word.original,
            translation: word.translation,
            transcription: word.transcription,
            exampleSentence: word.exampleSentence,
            languagePair: "en-uk",
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
        
        dictionaryVM.saveWord(savedWord)
        
        withAnimation {
            isAdded = true
        }
    }
}

// MARK: - Word Set Detail View
struct WordSetDetailView: View {
    let set: WordSet
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var ttsManager = TTSManager.shared
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
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
                    
                    LazyVStack(spacing: 12) {
                        ForEach(set.words) { word in
                            CategoryWordRow(word: word)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationTitle(set.title(for: Locale.current.language.languageCode?.identifier ?? "en"))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var backgroundColor: Color {
        localizationManager.isDarkMode ? Color(hex: "#1C1C1E") : Color(hex: "#FFFDF5")
    }
}

