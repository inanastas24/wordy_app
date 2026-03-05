//  DictionaryView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 29.01.2026.
//


import FirebaseFirestore
import FirebaseAuth
import SwiftUI

struct DictionaryView: View {
    @StateObject private var viewModel = DictionaryViewModel.shared
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var onboardingManager: OnboardingManager
    
    @State private var isButtonPulsing = false
    @State private var showMenu = false
    @State private var selectedTab: Int = 1
    @State private var showSettings = false
    
    @State private var showAddWord = false
    @State private var wordToEdit: SavedWordModel?
    
    @State private var showSourcePicker = false
    @State private var showTargetPicker = false
    
    // MARK: - Нові стани для детального перегляду
    @State private var selectedWord: SavedWordModel?
    @State private var showWordDetail = false
    
    private var studyButtonTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Час повторити!"
        case .polish: return "Czas na powtórkę!"
        case .english: return "Time to review!"
        }
    }
    
    private var studyButtonSubtitle: String {
        let count = viewModel.learningCount
        switch localizationManager.currentLanguage {
        case .ukrainian:
            if count == 1 { return "1 картка чекає" }
            else if count >= 2 && count <= 4 { return "\(count) картки чекають" }
            else { return "\(count) карток чекають" }
        case .polish:
            if count == 1 { return "1 karta czeka" }
            else if count >= 2 && count <= 4 { return "\(count) karty czekają" }
            else { return "\(count) kart czeka" }
        case .english:
            return count == 1 ? "1 card waiting" : "\(count) cards waiting"
        }
    }
    
    private var emptyTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Словник порожній"
        case .polish: return "Słownik jest pusty"
        case .english: return "Dictionary is empty"
        }
    }
    
    private var emptySubtitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Збережіть слова під час перекладу або додайте вручну"
        case .polish: return "Zapisz słowa podczas tłumaczenia lub dodaj ręcznie"
        case .english: return "Save words during translation or add manually"
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: localizationManager.isDarkMode ? "#1C1C1E" : "#FFFDF5")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HeaderView(showMenu: $showMenu, title: localizationManager.string(.dictionary))
                        .environmentObject(localizationManager)
                    
                    languagePairSelector
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    
                    if viewModel.savedWords.isEmpty && !viewModel.isLoading {
                        emptyStateView
                    } else {
                        listView
                    }
                    
                    Spacer(minLength: 0)
                }
                
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
                }
                
                // MARK: - Детальний перегляд слова
                if showWordDetail, let word = selectedWord {
                    WordDetailOverlay(
                        word: word,
                        isShowing: $showWordDetail,
                        onEdit: {
                            wordToEdit = word
                            showAddWord = true
                        },
                        onDelete: {
                            viewModel.deleteWord(word)
                            showWordDetail = false
                        }
                    )
                    .environmentObject(localizationManager)
                    .environmentObject(appState)
                    .transition(.opacity)
                    .zIndex(200)
                }
                
                // Онбординг флешкарток тепер на studyButton
                
            } // <-- закриваюча дужка ZStack
            .navigationTitle("")
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(localizationManager)
            }
            .sheet(isPresented: $showAddWord) {
                AddWordView(existingWord: wordToEdit) {
                    viewModel.fetchSavedWords()
                    if let edited = wordToEdit,
                       let updated = viewModel.savedWords.first(where: { $0.id == edited.id }) {
                        selectedWord = updated
                    }
                }
                .environmentObject(localizationManager)
                .environmentObject(appState)
            }
            .safeAreaInset(edge: .bottom) {
                if viewModel.learningCount > 0 && !showMenu && !showWordDetail {
                    VStack(spacing: 0) {
                        studyButtonContainer
                            .padding(.horizontal, 20)
                            .padding(.bottom, 10)
                    }
                    .background(
                        Color(hex: localizationManager.isDarkMode ? "#1C1C1E" : "#FFFDF5")
                            .opacity(0.9)
                            .ignoresSafeArea()
                    )
                }
            }
            .onChange(of: viewModel.learningCount) { _, count in
                print("📚 learningCount changed to: \(count)")
                onboardingManager.hasLearningWords = count > 0
            }
            .onAppear {
                viewModel.fetchSavedWords()
                // Встановлюємо hasLearningWords з затримкою щоб дані завантажились
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let hasWords = viewModel.learningCount > 0
                    onboardingManager.hasLearningWords = hasWords
                    print("🎯 Initial hasLearningWords = \(hasWords) (count: \(viewModel.learningCount))")
                }
            }
            .onAppear {
                viewModel.fetchSavedWords()
                onboardingManager.userHasVisitedDictionary = true
                    print("📖 User visited Dictionary")
                    
                    // Встановлюємо hasLearningWords з затримкою щоб дані завантажились
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        let hasWords = viewModel.learningCount > 0
                        onboardingManager.hasLearningWords = hasWords
                        print("🎯 Initial hasLearningWords = \(hasWords) (count: \(viewModel.learningCount))")
                    }
                }
            .onDisappear {
                viewModel.stopListening()
            }
        }
    }
    
    // MARK: - Language Pair Selector
    
    private var languagePairSelector: some View {
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
    
    private var addWordButton: some View {
        Button {
            wordToEdit = nil
            showAddWord = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                
                Text(addWordButtonTitle)
                    .font(.system(size: 14, weight: .semibold))
                
                Spacer()
            }
            .foregroundColor(Color(hex: "#4ECDC4"))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#4ECDC4").opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#4ECDC4").opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var addWordButtonTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Додати слово"
        case .polish: return "Dodaj słowo"
        case .english: return "Add word"
        }
    }
    
    private var studyButtonContainer: some View {
        Group {
            if viewModel.learningCount > 0 {
                studyButton
                    .onboardingStep(.flashcards)
                    .allowsHitTesting(!(onboardingManager.isBlockingInteraction &&
                                       onboardingManager.currentStep == .flashcards))
            } else {
                EmptyView()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 80))
                .foregroundColor(Color(hex: "#A8D8EA"))
            
            Text(emptyTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
            
            Text(emptySubtitle)
                .font(.system(size: 16))
                .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
            
            Button {
                showAddWord = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text(addWordButtonTitle)
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color(hex: "#4ECDC4"))
                )
            }
            .padding(.top, 20)
        }
        .padding(.top, 100)
    }
    
    private var listView: some View {
        List {
            Section {
                addWordButton
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
            
            if !viewModel.learningWords.isEmpty {
                Section {
                    ForEach(viewModel.learningWords) { word in
                        WordRow(word: word, isDarkMode: localizationManager.isDarkMode)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                selectedWord = word
                                withAnimation(.spring(response: 0.35)) {
                                    showWordDetail = true
                                }
                            }
                            .listRowBackground(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
                    }
                } header: {
                    Text(localizationManager.string(.learning) + " (\(viewModel.learningCount))")
                }
            }
            
            if !viewModel.learnedWords.isEmpty {
                Section {
                    ForEach(viewModel.learnedWords) { word in
                        WordRow(word: word, isDarkMode: localizationManager.isDarkMode)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                selectedWord = word
                                withAnimation(.spring(response: 0.35)) {
                                    showWordDetail = true
                                }
                            }
                            .listRowBackground(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
                    }
                } header: {
                    Text(localizationManager.string(.learned) + " ✅ (\(viewModel.learnedCount))")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(localizationManager.isDarkMode ? Color(hex: "#1C1C1E") : Color(hex: "#FFFDF5"))
    }
    
    private var studyButton: some View {
        NavigationLink(destination:
            FlashcardsView()
                .environmentObject(localizationManager)
                .navigationBarHidden(true)) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#4ECDC4").opacity(0.2))
                        .frame(width: 50, height: 50)
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                        .scaleEffect(isButtonPulsing ? 1.1 : 1.0)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(studyButtonTitle)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(localizationManager.isDarkMode ? .white : .primary)
                    
                    Text(studyButtonSubtitle)
                        .font(.system(size: 14))
                        .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: "#4ECDC4"))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isButtonPulsing = true
            }
        }
    }
}

// MARK: - WordRow (оновлений для кращого вигляду)
struct WordRow: View {
    let word: SavedWordModel
    let isDarkMode: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(word.original)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "#2C3E50"))
                    .lineLimit(2)
                
                Spacer()
                
                if word.isLearned {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(Color(hex: "#4ECDC4"))
                } else if word.isDueForReview {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                }
            }
            
            Text(word.translation)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#4ECDC4"))
                .lineLimit(2)
            
            // Показуємо транскрипцію якщо є
            if let transcription = word.transcription, !transcription.isEmpty {
                Text(transcription)
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(isDarkMode ? .gray : Color(hex: "#7F8C8D"))
            }
            
            // Показуємо приклад якщо є
            if let example = word.exampleSentence, !example.isEmpty {
                Text("„\(example)\"")
                    .font(.system(size: 13))
                    .italic()
                    .foregroundColor(isDarkMode ? Color.white.opacity(0.7) : Color(hex: "#7F8C8D"))
                    .lineLimit(1)
            }
            
            HStack {
                if !word.languagePair.isEmpty {
                    let components = word.languagePair.components(separatedBy: "-")
                    if let source = components.first, let target = components.count > 1 ? components[1] : nil {
                        HStack(spacing: 4) {
                            Text(TranslationLanguage(rawValue: source)?.flag ?? "🏳️")
                                .font(.system(size: 12))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 8))
                                .foregroundColor(.gray)
                            Text(TranslationLanguage(rawValue: target)?.flag ?? "🏳️")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Індикатор прогресу вивчення
                if word.reviewCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                        Text("\(word.reviewCount)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var timeUntilReview: String {
        guard let nextReview = word.nextReviewDate else { return "зараз" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: nextReview, relativeTo: Date())
    }
}

// MARK: - WordDetailOverlay (новий компонент)
struct WordDetailOverlay: View {
    let word: SavedWordModel
    @Binding var isShowing: Bool
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var appState: AppState
    @StateObject private var ttsManager = FirebaseTTSManager.shared
    
    @State private var showingDeleteConfirm = false
    
    private var sourceLanguage: String {
        let components = word.languagePair.components(separatedBy: "-")
        return components.first ?? "en"
    }
    
    private var targetLanguage: String {
        let components = word.languagePair.components(separatedBy: "-")
        if components.count > 1 {
            return components[1]
        } else {
            return "uk"
        }
    }
    
    var body: some View {
        ZStack {
            // Фон
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    closeOverlay()
                }
            
            GeometryReader { geometry in
                ScrollView {
                    VStack {
                        Spacer(minLength: geometry.size.height * 0.05)
                        
                        VStack(spacing: 20) {
                            // Шапка з кнопками
                            HStack {
                                // Кнопка редагування
                                Button(action: onEdit) {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(Color(hex: "#4ECDC4"))
                                }
                                
                                Spacer()
                                
                                // Кнопка закриття
                                Button(action: closeOverlay) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(localizationManager.isDarkMode ? .white.opacity(0.6) : Color(hex: "#7F8C8D"))
                                        .padding(8)
                                        .background(Circle().fill(Color.gray.opacity(0.2)))
                                }
                                
                                // Кнопка видалення
                                Button(action: { showingDeleteConfirm = true }) {
                                    Image(systemName: "trash.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.red.opacity(0.8))
                                }
                            }
                            
                            // Оригінальне слово
                            wordSection(
                                text: word.original,
                                language: sourceLanguage,
                                isPrimary: true
                            )
                            
                            // Транскрипція IPA
                            if let ipa = word.transcription, !ipa.isEmpty {
                                Text(ipa)
                                    .font(.system(size: 18, design: .serif))
                                    .foregroundColor(Color(hex: "#4ECDC4").opacity(0.8))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color(hex: "#4ECDC4").opacity(0.1))
                                    .cornerRadius(12)
                            }
                            
                            Divider().opacity(0.5)
                            
                            // Переклад
                            wordSection(
                                text: word.translation,
                                language: targetLanguage,
                                isPrimary: false
                            )
                            
                            // Приклади речень
                            if let example = word.exampleSentence, !example.isEmpty {
                                examplesSection(
                                    original: example,
                                    translation: "",
                                    originalLang: sourceLanguage,
                                    transLang: targetLanguage
                                )
                            }
                            
                            // Інформація про вивчення
                            learningInfoSection
                            
                            Spacer(minLength: 20)
                        }
                        .padding(24)
                        .background(overlayBackground)
                        .frame(maxWidth: min(geometry.size.width - 40, 380))
                        .shadow(color: Color(hex: "#4ECDC4").opacity(0.1), radius: 40, x: 0, y: 20)
                        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: geometry.size.height * 0.05)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .alert("Видалити слово?", isPresented: $showingDeleteConfirm) {
            Button("Скасувати", role: .cancel) { }
            Button("Видалити", role: .destructive, action: onDelete)
        } message: {
            Text("Це слово буде назавжди видалено з вашого словника")
        }
    }
    
    private var overlayBackground: some View {
        let base = RoundedRectangle(cornerRadius: 24)
        let fillColor = localizationManager.isDarkMode ? Color.black.opacity(0.4) : Color.white.opacity(0.8)
        return base
            .fill(.ultraThinMaterial)
            .background(
                base.fill(fillColor)
            )
            .overlay(
                base.stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
    }
    
    private func wordSection(text: String, language: String, isPrimary: Bool) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Text(text)
                    .font(.system(size: isPrimary ? 28 : 24, weight: isPrimary ? .bold : .semibold, design: .rounded))
                    .foregroundColor(isPrimary ? (localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50")) : Color(hex: "#4ECDC4"))
                    .fixedSize(horizontal: false, vertical: true)
                
                Button(action: { speak(text: text, language: language) }) {
                    let isSpeakingThisLanguage = ttsManager.isPlaying && ttsManager.currentLanguage == language
                    Image(systemName: isSpeakingThisLanguage ? "speaker.wave.2.fill" : "speaker.wave.2")
                        .font(.system(size: 16))
                        .foregroundColor(isPrimary ? Color(hex: "#4ECDC4") : .white)
                        .frame(width: 36, height: 36)
                        .background(isPrimary ? Color(hex: "#4ECDC4").opacity(0.15) : Color(hex: "#4ECDC4"))
                        .clipShape(Circle())
                }
            }
        }
    }
    
    private func examplesSection(original: String, translation: String, originalLang: String, transLang: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Приклади використання")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
            
            VStack(spacing: 12) {
                exampleRow(text: original, language: originalLang, isOriginal: true)
                
                if !translation.isEmpty && translation != original {
                    Divider().opacity(0.3)
                    exampleRow(text: translation, language: transLang, isOriginal: false)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E").opacity(0.8) : Color.white.opacity(0.5))
            )
        }
    }
    
    private func exampleRow(text: String, language: String, isOriginal: Bool) -> some View {
        HStack {
            Text(text)
                .font(.system(size: isOriginal ? 16 : 14))
                .italic(isOriginal)
                .foregroundColor(isOriginal
                    ? (localizationManager.isDarkMode ? Color.white.opacity(0.9) : Color(hex: "#2C3E50"))
                    : Color(hex: "#4ECDC4"))
            
            Spacer()
            
            Button(action: { speak(text: text, language: language) }) {
                Image(systemName: "speaker.wave.1")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#4ECDC4"))
            }
        }
    }
    
    private var learningInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Прогрес вивчення")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
            
            HStack(spacing: 16) {
                // Статус
                VStack(alignment: .leading, spacing: 4) {
                    Text("Статус")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 6) {
                        Image(systemName: word.isLearned ? "checkmark.seal.fill" : "graduationcap.fill")
                            .foregroundColor(word.isLearned ? Color(hex: "#4ECDC4") : .orange)
                        Text(word.isLearned ? "Вивчено" : "В процесі")
                            .font(.system(size: 14, weight: .medium))
                    }
                }
                
                Divider()
                    .frame(height: 40)
                
                // Кількість повторень
                VStack(alignment: .leading, spacing: 4) {
                    Text("Повторень")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Color(hex: "#4ECDC4"))
                        Text("\(word.reviewCount)")
                            .font(.system(size: 14, weight: .medium))
                    }
                }
                
                if let nextReview = word.nextReviewDate {
                    Divider()
                        .frame(height: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Наступне повторення")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .foregroundColor(.orange)
                            Text(timeString(from: nextReview))
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E").opacity(0.8) : Color.white.opacity(0.5))
            )
        }
    }
    
    private func speak(text: String, language: String) {
        ttsManager.speak(text: text, language: language)
    }
    
    private func closeOverlay() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isShowing = false
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
