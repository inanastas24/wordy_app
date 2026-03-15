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
    
    @StateObject private var ttsManager = FirebaseTTSManager.shared
    
    @State private var selectedWord: SavedWordModel?
    @State private var showWordDetail = false
    @State private var swipedWordId: String? = nil
    
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
                    
                    HStack {
                        Spacer()
                        addWordButton
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                    }
                    
                    if viewModel.savedWords.isEmpty && !viewModel.isLoading {
                        emptyStateView
                    } else {
                        listView
                    }
                    
                    Spacer(minLength: 0)
                }
                
                if showMenu {
                    MenuView(isShowing: $showMenu, selectedTab: $selectedTab, showSettings: $showSettings)
                        .transition(.move(edge: .leading))
                        .zIndex(100)
                }
                
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
            }
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
                onboardingManager.hasLearningWords = count > 0
            }
            .onAppear {
                OnboardingContext.isOnDictionaryScreen = true
                viewModel.fetchSavedWords()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onboardingManager.hasLearningWords = viewModel.learningCount > 0
                }
                onboardingManager.userHasVisitedDictionary = true
            }
            .onDisappear {
                viewModel.stopListening()
                OnboardingContext.isOnDictionaryScreen = false
            }
        }
    }
    
    private var addWordButton: some View {
        Button {
            wordToEdit = nil
            showAddWord = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                Text(addWordButtonTitle)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(Color(hex: "#4ECDC4"))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var addWordButtonTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Додати"
        case .polish: return "Dodaj"
        case .english: return "Add"
        }
    }
    
    private var studyButtonContainer: some View {
        Group {
            if viewModel.learningCount > 0 {
                studyButton
                    .onboardingStep(.flashcards)
                    .allowsHitTesting(!(onboardingManager.isBlockingInteraction && onboardingManager.currentStep == .flashcards))
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
                .background(Capsule().fill(Color(hex: "#4ECDC4")))
            }
            .padding(.top, 20)
        }
        .padding(.top, 100)
    }
    
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if !viewModel.learningWords.isEmpty {
                    sectionHeader(title: localizationManager.string(.learning) + " (\(viewModel.learningCount))")
                    
                    ForEach(viewModel.learningWords) { word in
                        CompactWordRow(
                            word: word,
                            isDarkMode: localizationManager.isDarkMode,
                            isSwiped: swipedWordId == word.id,
                            onSwipeRight: {
                                withAnimation(.spring(response: 0.3)) {
                                    swipedWordId = word.id
                                }
                            },
                            onSwipeLeft: {
                                withAnimation(.spring(response: 0.3)) {
                                    swipedWordId = word.id
                                }
                            },
                            onMarkLearned: {
                                viewModel.markAsLearned(word)
                                withAnimation { swipedWordId = nil }
                            },
                            onDelete: {
                                viewModel.deleteWord(word)
                                withAnimation { swipedWordId = nil }
                            },
                            onTap: {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                selectedWord = word
                                withAnimation(.spring(response: 0.35)) {
                                    showWordDetail = true
                                }
                            },
                            onSpeak: {
                                speakWord(word)
                            }
                        )
                        .padding(.horizontal, 16)
                    }
                }
                
                if !viewModel.learnedWords.isEmpty {
                    sectionHeader(title: localizationManager.string(.learned) + " ✅ (\(viewModel.learnedCount))")
                    
                    ForEach(viewModel.learnedWords) { word in
                        CompactWordRow(
                            word: word,
                            isDarkMode: localizationManager.isDarkMode,
                            isSwiped: swipedWordId == word.id,
                            onSwipeRight: {
                                withAnimation(.spring(response: 0.3)) {
                                    swipedWordId = word.id
                                }
                            },
                            onSwipeLeft: {
                                withAnimation(.spring(response: 0.3)) {
                                    swipedWordId = word.id
                                }
                            },
                            onMarkLearned: {
                                viewModel.markAsLearning(word)
                                withAnimation { swipedWordId = nil }
                            },
                            onDelete: {
                                let impact = UIImpactFeedbackGenerator(style: .rigid)
                                impact.impactOccurred()
                                viewModel.deleteWord(word)
                                withAnimation { swipedWordId = nil }
                            },
                            onTap: {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                selectedWord = word
                                withAnimation(.spring(response: 0.35)) {
                                    showWordDetail = true
                                }
                            },
                            onSpeak: {
                                speakWord(word)
                            }
                        )
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "#4ECDC4"))
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    private func speakWord(_ word: SavedWordModel) {
        let components = word.languagePair.components(separatedBy: "-")
        let sourceLang = components.first ?? "en"
        ttsManager.speak(text: word.original, language: sourceLang)
    }
    
    private var studyButton: some View {
        NavigationLink(destination: FlashcardsView().environmentObject(localizationManager).navigationBarHidden(true)) {
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

// MARK: - Compact Word Row з покращеними жестами
struct CompactWordRow: View {
    let word: SavedWordModel
    let isDarkMode: Bool
    let isSwiped: Bool
    let onSwipeRight: () -> Void
    let onSwipeLeft: () -> Void
    let onMarkLearned: () -> Void
    let onDelete: () -> Void
    let onTap: () -> Void
    let onSpeak: () -> Void
    
    @State private var offset: CGFloat = 0
    private let buttonWidth: CGFloat = 80
    private let swipeThreshold: CGFloat = 50
    private let rowHeight: CGFloat = 76
    
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                Button(action: onMarkLearned) {
                    VStack(spacing: 4) {
                        Image(systemName: word.isLearned ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill")
                            .font(.system(size: 22))
                        Text(word.isLearned ? "Назад" : "Вивчено")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.white)
                    .frame(width: buttonWidth)
                    .frame(maxHeight: .infinity)
                    .background(word.isLearned ? Color.orange : Color(hex: "#4ECDC4"))
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    VStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 22))
                        Text("Видалити")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.white)
                    .frame(width: buttonWidth)
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
                }
            }
            
            HStack(spacing: 12) {
                Button(action: onSpeak) {
                    Image(systemName: "speaker.wave.2")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                        .frame(width: 32, height: 32)
                        .background(Color(hex: "#4ECDC4").opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(word.original)
                            .font(.system(size: 17, weight: .semibold))
                            .lineLimit(1)
                        
                        if word.isDueForReview && !word.isLearned {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 6, height: 6)
                        }
                    }
                    
                    Text(word.translation)
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        if !word.languagePair.isEmpty {
                            let components = word.languagePair.components(separatedBy: "-")
                            if let source = components.first, let target = components.count > 1 ? components[1] : nil {
                                HStack(spacing: 2) {
                                    Text(TranslationLanguage(rawValue: source)?.flag ?? "🏳️")
                                        .font(.system(size: 11))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 8))
                                        .foregroundColor(.gray)
                                    Text(TranslationLanguage(rawValue: target)?.flag ?? "🏳️")
                                        .font(.system(size: 11))
                                }
                            }
                        }
                        
                        if word.reviewCount > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 9))
                                Text("\(word.reviewCount)")
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                        }
                    }
                }
                
                Spacer()
                
                if word.isLearned {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(height: rowHeight)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: "#E0E0E0").opacity(isDarkMode ? 0.2 : 0.5), lineWidth: 0.5)
            )
            .offset(x: offset)
            .highPriorityGesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onChanged { gesture in
                        let translation = gesture.translation.width
                        let velocity = gesture.velocity.width
                        
                        // Якщо швидкість велика по вертикалі - дозволяємо скролу працювати
                        let verticalVelocity = abs(gesture.velocity.height)
                        if verticalVelocity > abs(velocity) * 2 {
                            return
                        }
                        
                        // Горизонтальний свайп
                        if abs(translation) > abs(gesture.translation.height) * 2 {
                            if translation > 0 {
                                offset = min(translation, buttonWidth)
                            } else {
                                offset = max(translation, -buttonWidth)
                            }
                        }
                    }
                    .onEnded { gesture in
                        let translation = gesture.translation.width
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if translation > swipeThreshold {
                                offset = buttonWidth
                                onSwipeRight()
                            } else if translation < -swipeThreshold {
                                offset = -buttonWidth
                                onSwipeLeft()
                            } else {
                                offset = 0
                            }
                        }
                    }
            )
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        if offset != 0 {
                            withAnimation(.spring(response: 0.3)) {
                                offset = 0
                            }
                        } else {
                            onTap()
                        }
                    }
            )
            .onChange(of: isSwiped) { _, newValue in
                if !newValue {
                    withAnimation(.spring(response: 0.3)) {
                        offset = 0
                    }
                }
            }
        }
        .frame(height: rowHeight)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Word Detail Overlay з локалізацією
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
        return components.count > 1 ? components[1] : "uk"
    }
    
    // MARK: - Localized Strings
    private var examplesTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Приклади використання"
        case .polish: return "Przykłady użycia"
        case .english: return "Usage examples"
        }
    }
    
    private var progressTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Прогрес вивчення"
        case .polish: return "Postęp nauki"
        case .english: return "Learning progress"
        }
    }
    
    private var statusTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Статус"
        case .polish: return "Status"
        case .english: return "Status"
        }
    }
    
    private var statusLearning: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "В процесі"
        case .polish: return "W trakcie"
        case .english: return "In progress"
        }
    }
    
    private var statusLearned: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Вивчено"
        case .polish: return "Nauczone"
        case .english: return "Learned"
        }
    }
    
    private var reviewsTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Повторень"
        case .polish: return "Powtórzeń"
        case .english: return "Reviews"
        }
    }
    
    private var nextReviewTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Наступне повторення"
        case .polish: return "Następna powtórka"
        case .english: return "Next review"
        }
    }
    
    private var deleteAlertTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Видалити слово?"
        case .polish: return "Usunąć słowo?"
        case .english: return "Delete word?"
        }
    }
    
    private var deleteAlertMessage: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Це слово буде назавжди видалено з вашого словника"
        case .polish: return "To słowo zостanie trwale usunięte ze słownika"
        case .english: return "This word will be permanently deleted from your dictionary"
        }
    }
    
    private var cancelTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Скасувати"
        case .polish: return "Anuluj"
        case .english: return "Cancel"
        }
    }
    
    private var deleteTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Видалити"
        case .polish: return "Usuń"
        case .english: return "Delete"
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { closeOverlay() }
            
            GeometryReader { geometry in
                ScrollView {
                    VStack {
                        Spacer(minLength: geometry.size.height * 0.05)
                        
                        VStack(spacing: 20) {
                            // Header з кнопками редагування та видалення поруч
                            HStack(spacing: 16) {
                                Button(action: onEdit) {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(Color(hex: "#4ECDC4"))
                                }
                                
                                Button(action: {
                                    let impact = UIImpactFeedbackGenerator(style: .rigid)
                                    impact.impactOccurred()
                                    showingDeleteConfirm = true
                                }) {
                                    Image(systemName: "trash.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.red.opacity(0.8))
                                }
                                
                                Spacer()
                                
                                Button(action: closeOverlay) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(localizationManager.isDarkMode ? .white.opacity(0.6) : Color(hex: "#7F8C8D"))
                                        .padding(8)
                                        .background(Circle().fill(Color.gray.opacity(0.2)))
                                }
                            }
                            
                            wordSection(text: word.original, language: sourceLanguage, isPrimary: true)
                            
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
                            
                            wordSection(text: word.translation, language: targetLanguage, isPrimary: false)
                            
                            if let example = word.exampleSentence, !example.isEmpty {
                                examplesSection(original: example, originalLang: sourceLanguage)
                            }
                            
                            learningInfoSection
                            
                            Spacer(minLength: 20)
                        }
                        .padding(24)
                        .background(overlayBackground)
                        .frame(maxWidth: min(geometry.size.width - 40, 380))
                        .frame(minHeight: 0, maxHeight: .infinity, alignment: .center)
                        .shadow(color: Color(hex: "#4ECDC4").opacity(0.1), radius: 40, x: 0, y: 20)
                        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: geometry.size.height * 0.05)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .alert(deleteAlertTitle, isPresented: $showingDeleteConfirm) {
            Button(cancelTitle, role: .cancel) { }
            Button(deleteTitle, role: .destructive, action: onDelete)
        } message: {
            Text(deleteAlertMessage)
        }
    }
    
    private var overlayBackground: some View {
        let base = RoundedRectangle(cornerRadius: 24)
        let fillColor = localizationManager.isDarkMode ? Color.black.opacity(0.4) : Color.white.opacity(0.8)
        return base
            .fill(.ultraThinMaterial)
            .background(base.fill(fillColor))
            .overlay(base.stroke(Color.white.opacity(0.3), lineWidth: 1))
    }
    
    private func wordSection(text: String, language: String, isPrimary: Bool) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Text(text)
                    .font(.system(size: isPrimary ? 28 : 24, weight: isPrimary ? .bold : .semibold, design: .rounded))
                    .foregroundColor(isPrimary ? (localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50")) : Color(hex: "#4ECDC4"))
                    .fixedSize(horizontal: false, vertical: true)
                
                Button(action: { speak(text: text, language: language) }) {
                    let isSpeaking = ttsManager.isPlaying && ttsManager.currentLanguage == language
                    Image(systemName: isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                        .font(.system(size: 16))
                        .foregroundColor(isPrimary ? Color(hex: "#4ECDC4") : .white)
                        .frame(width: 36, height: 36)
                        .background(isPrimary ? Color(hex: "#4ECDC4").opacity(0.15) : Color(hex: "#4ECDC4"))
                        .clipShape(Circle())
                }
            }
        }
    }
    
    private func examplesSection(original: String, originalLang: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(examplesTitle)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
            
            HStack(spacing: 12) {
                Text("„\(original)\"")
                    .font(.system(size: 16))
                    .italic()
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                
                Spacer()
                
                Button(action: { speak(text: original, language: originalLang) }) {
                    Image(systemName: "speaker.wave.1")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E").opacity(0.8) : Color.white.opacity(0.5))
            )
        }
    }
    
    private var learningInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(progressTitle)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(statusTitle)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 6) {
                        Image(systemName: word.isLearned ? "checkmark.seal.fill" : "graduationcap.fill")
                            .foregroundColor(word.isLearned ? Color(hex: "#4ECDC4") : .orange)
                        Text(word.isLearned ? statusLearned : statusLearning)
                            .font(.system(size: 14, weight: .medium))
                    }
                }
                
                Divider().frame(height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(reviewsTitle)
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
                    Divider().frame(height: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(nextReviewTitle)
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
