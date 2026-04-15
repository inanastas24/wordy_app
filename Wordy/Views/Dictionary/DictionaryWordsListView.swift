import SwiftUI

struct DictionaryWordsListView: View {
    let dictionary: WordDictionaryModel

    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var appState: AppState

    @StateObject private var viewModel = DictionaryViewModel.shared
    @StateObject private var ttsManager = TextToSpeechService.shared

    @State private var showAddWord = false
    @State private var wordToEdit: SavedWordModel?
    @State private var selectedWord: SavedWordModel?
    @State private var showWordDetail = false
    @State private var swipedWordId: String?
    @State private var animateStudyCTA = false
    @State private var isSelectionMode = false
    @State private var selectedWordKeys = Set<String>()
    @State private var pendingDeleteScope: DeleteScope?

    var body: some View {
        rootContent
    }

    private var rootContent: some View {
        ZStack {
            backgroundLayer

            contentScrollView
            wordDetailOverlay
        }
        .navigationTitle(dictionary.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            studyInset
        }
        .toolbar { toolbarContent }
        .sheet(isPresented: $showAddWord, onDismiss: onAddWordDismiss) { addWordSheet }
        .onChange(of: viewModel.savedWords) { _, newValue in
            handleSavedWordsChange(newValue)
        }
        .alert(deleteAlertTitle, isPresented: Binding(
            get: { pendingDeleteScope != nil },
            set: { newValue in
                if !newValue {
                    pendingDeleteScope = nil
                }
            }
        )) {
            Button(deleteAlertConfirmTitle, role: .destructive) {
                performPendingDeletion()
            }
            Button(cancelTitle, role: .cancel) {
                pendingDeleteScope = nil
            }
        } message: {
            Text(deleteAlertMessage)
        }
    }

    private var contentScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                headerCard
                wordsContent
            }
            .padding(.vertical, 12)
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            Circle()
                .fill(Color(hex: "#4ECDC4").opacity(localizationManager.isDarkMode ? 0.14 : 0.13))
                .frame(width: 280, height: 280)
                .blur(radius: 56)
                .offset(x: -150, y: -250)

            Circle()
                .fill(Color(hex: "#FFD166").opacity(localizationManager.isDarkMode ? 0.10 : 0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 52)
                .offset(x: 160, y: -120)
        }
    }

    @ViewBuilder
    private var wordsContent: some View {
        if learningWords.isEmpty && learnedWords.isEmpty {
            emptyStateView
        } else {
            if isSelectionMode {
                selectionToolbar
            }
            learningSection
            learnedSection
        }
    }

    @ViewBuilder
    private var learningSection: some View {
        if !learningWords.isEmpty {
            sectionHeader(title: "\(learningTitle) (\(learningWords.count))")

            ForEach(learningWords) { word in
                wordRow(word, isLearnedSection: false)
            }
        }
    }

    @ViewBuilder
    private var learnedSection: some View {
        if !learnedWords.isEmpty {
            sectionHeader(title: "\(learnedTitle) (\(learnedWords.count))")

            ForEach(learnedWords) { word in
                wordRow(word, isLearnedSection: true)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if hasWords {
                Button(isSelectionMode ? cancelTitle : selectTitle) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
                        toggleSelectionMode()
                    }
                }
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            if isSelectionMode {
                Button {
                    pendingDeleteScope = selectedWordKeys.count == allWords.count ? .all : .selected
                } label: {
                    Image(systemName: "trash.fill")
                        .foregroundColor(selectedWordKeys.isEmpty ? .gray : .red)
                }
                .disabled(selectedWordKeys.isEmpty)
            } else {
                Button {
                    wordToEdit = nil
                    showAddWord = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color(hex: "#4ECDC4"))
                }
            }
        }
    }

    private var addWordSheet: some View {
        AddWordView(
            existingWord: wordToEdit,
            preselectedDictionaryId: viewModel.resolvedSelectionDictionaryId(for: dictionary)
        ) {
            viewModel.fetchSavedWords()

            if let edited = wordToEdit,
               let updated = viewModel.savedWords.first(where: { $0.id == edited.id }) {
                selectedWord = updated
            }
        }
        .environmentObject(localizationManager)
        .environmentObject(appState)
    }

    @ViewBuilder
    private var wordDetailOverlay: some View {
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
                    selectedWord = nil
                }
            )
            .environmentObject(localizationManager)
            .environmentObject(appState)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(100)
        }
    }

    private func onAddWordDismiss() {
        wordToEdit = nil
    }

    private func handleSavedWordsChange(_ newWords: [SavedWordModel]) {
        if let current = selectedWord {
            if let updated = newWords.first(where: { $0.id == current.id && $0.dictionaryId == current.dictionaryId }) {
                selectedWord = updated
            } else {
                selectedWord = nil
                showWordDetail = false
            }
        }

        if let swipedId = swipedWordId,
           !newWords.contains(where: { $0.id == swipedId && $0.dictionaryId == dictionary.id }) {
            swipedWordId = nil
        }

        let validKeys = Set(wordsForDictionary.map(selectionKey(for:)))
        selectedWordKeys = selectedWordKeys.intersection(validKeys)
    }

    private var learningWords: [SavedWordModel] {
        viewModel.learningWords(in: dictionary.id)
    }

    private var learnedWords: [SavedWordModel] {
        viewModel.learnedWords(in: dictionary.id)
    }

    private var backgroundColor: Color {
        Color(hex: localizationManager.isDarkMode ? "#1C1C1E" : "#FFFDF5")
    }

    private var wordsForDictionary: [SavedWordModel] {
        viewModel.words(in: dictionary.id)
    }

    private var allWords: [SavedWordModel] {
        learningWords + learnedWords
    }

    private var hasWords: Bool {
        !allWords.isEmpty
    }

    private var studyCTAStartColor: Color {
        localizationManager.isDarkMode ? Color(hex: "#1F6C70") : Color(hex: "#5EDAD2")
    }

    private var studyCTAEndColor: Color {
        localizationManager.isDarkMode ? Color(hex: "#2E8B7C") : Color(hex: "#42B8A3")
    }

    private var studyCTAGlowColor: Color {
        Color(hex: "#4ECDC4").opacity(localizationManager.isDarkMode ? 0.22 : 0.18)
    }

    private var learningTitle: String {
        localizationManager.string(.learning)
    }

    private var learnedTitle: String {
        localizationManager.string(.learned)
    }

    private var totalWordsText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Усього слів"
        case .polish: return "Wszystkie slowa"
        case .english: return "Total words"
        }
    }

    private var emptyTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "У цьому словнику ще немає слів"
        case .polish: return "Ten slownik jest pusty"
        case .english: return "This dictionary is empty"
        }
    }

    private var emptyButtonTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Додати слово"
        case .polish: return "Dodaj slowo"
        case .english: return "Add Word"
        }
    }

    private var selectTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Вибрати"
        case .polish: return "Wybierz"
        case .english: return "Select"
        }
    }

    private var cancelTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Скасувати"
        case .polish: return "Anuluj"
        case .english: return "Cancel"
        }
    }

    private var selectAllTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Обрати всі"
        case .polish: return "Zaznacz wszystko"
        case .english: return "Select All"
        }
    }

    private var clearSelectionTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Очистити"
        case .polish: return "Wyczyść"
        case .english: return "Clear"
        }
    }

    private var selectedWordsTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Вибрано"
        case .polish: return "Wybrano"
        case .english: return "Selected"
        }
    }

    private var deleteSelectedTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Видалити"
        case .polish: return "Usuń"
        case .english: return "Delete"
        }
    }

    private var deleteAlertTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Видалити слова?"
        case .polish: return "Usunąć słowa?"
        case .english: return "Delete words?"
        }
    }

    private var deleteAlertConfirmTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Видалити"
        case .polish: return "Usuń"
        case .english: return "Delete"
        }
    }

    private var deleteAlertMessage: String {
        let count = pendingDeleteCount
        switch localizationManager.currentLanguage {
        case .ukrainian:
            return "Буде видалено \(count) слів із цього словника та з хмари."
        case .polish:
            return "Zostanie usuniętych \(count) słów z tego słownika i z chmury."
        case .english:
            return "\(count) words will be deleted from this dictionary and from the cloud."
        }
    }

    private var pendingDeleteCount: Int {
        switch pendingDeleteScope {
        case .all:
            return allWords.count
        case .selected:
            return selectedWordKeys.count
        case .none:
            return 0
        }
    }

    private var studyButtonTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Повторити словник"
        case .polish: return "Powtorz slownik"
        case .english: return "Review Dictionary"
        }
    }

    private var studyButtonSubtitle: String {
        let count = learningWords.count
        switch localizationManager.currentLanguage {
        case .ukrainian:
            if count == 1 { return "1 картка чекає" }
            else if count >= 2 && count <= 4 { return "\(count) картки чекають" }
            else { return "\(count) карток чекають" }
        case .polish:
            if count == 1 { return "1 karta czeka" }
            else if count >= 2 && count <= 4 { return "\(count) karty czekaja" }
            else { return "\(count) kart czeka" }
        case .english:
            return count == 1 ? "1 card waiting" : "\(count) cards waiting"
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(dictionary.name)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#203044"))

                    Text(dictionaryHeaderSubtitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(localizationManager.isDarkMode ? Color.white.opacity(0.62) : Color(hex: "#6E7C89"))
                }

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(hex: "#4ECDC4").opacity(0.14))
                        .frame(width: 54, height: 54)

                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                }
            }

            HStack(spacing: 16) {
                statPill(title: totalWordsText, value: "\(viewModel.wordCount(in: dictionary.id))", tint: "#4ECDC4")
                statPill(title: learningTitle, value: "\(learningWords.count)", tint: "#A8D8EA")
                statPill(title: learnedTitle, value: "\(learnedWords.count)", tint: "#6BCB77")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: localizationManager.isDarkMode
                        ? [Color(hex: "#23252B"), Color(hex: "#17181D")]
                        : [Color.white, Color(hex: "#F5F3EA")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.white.opacity(localizationManager.isDarkMode ? 0.06 : 0.7), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(localizationManager.isDarkMode ? 0.16 : 0.07), radius: 22, x: 0, y: 14)
        .padding(.horizontal, 18)
    }

    private func statPill(title: String, value: String, tint: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(localizationManager.isDarkMode ? Color.white.opacity(0.58) : Color(hex: "#6E7C89"))
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#203044"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(hex: tint).opacity(0.12))
        )
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 56))
                .foregroundColor(Color(hex: "#A8D8EA"))

            Text(emptyTitle)
                .font(.system(size: 18, weight: .semibold))
                .multilineTextAlignment(.center)

            Button {
                wordToEdit = nil
                showAddWord = true
            } label: {
                Text(emptyButtonTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color(hex: "#4ECDC4")))
            }
        }
        .padding(.top, 60)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(localizationManager.isDarkMode ? Color(hex: "#23252B") : Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.white.opacity(localizationManager.isDarkMode ? 0.06 : 0.7), lineWidth: 1)
                )
        )
        .padding(.horizontal, 18)
    }

    @ViewBuilder
    private var studyInset: some View {
        if !learningWords.isEmpty && !showWordDetail && !isSelectionMode {
            VStack(spacing: 0) {
                NavigationLink(
                    destination: FlashcardsView(
                        dictionaryId: dictionary.id,
                        dictionaryName: dictionary.name
                    )
                    .environmentObject(localizationManager)
                    .navigationBarHidden(true)
                ) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(localizationManager.isDarkMode ? 0.12 : 0.24))
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                                )

                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundColor(.white)
                                .scaleEffect(animateStudyCTA ? 1.05 : 1.0)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(studyButtonTitle)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)

                            Text(studyButtonSubtitle)
                                .font(.system(size: 14))
                                .foregroundColor(Color.white.opacity(0.86))
                        }

                        Spacer()

                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(localizationManager.isDarkMode ? 0.14 : 0.24))
                                .frame(width: 52, height: 52)
                                .scaleEffect(animateStudyCTA ? 1.04 : 1.0)

                            Image(systemName: "arrow.right")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: animateStudyCTA ? 1.5 : 0)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [studyCTAStartColor, studyCTAEndColor],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(localizationManager.isDarkMode ? 0.08 : 0.18),
                                                Color.clear
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                Color.white.opacity(localizationManager.isDarkMode ? 0.1 : 0.24),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: studyCTAGlowColor, radius: animateStudyCTA ? 20 : 14, x: 0, y: 10)
                    .shadow(color: Color.black.opacity(localizationManager.isDarkMode ? 0.18 : 0.08), radius: 14, x: 0, y: 8)
                    .scaleEffect(animateStudyCTA ? 1.01 : 1.0)
                }
                .buttonStyle(.plain)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                        animateStudyCTA = true
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
            .background(
                backgroundColor
                    .opacity(0.9)
                    .ignoresSafeArea()
            )
        }
    }

    private func wordRow(_ word: SavedWordModel, isLearnedSection: Bool) -> some View {
        Group {
            if isSelectionMode {
                selectionWordRow(word)
            } else {
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
                        if isLearnedSection {
                            viewModel.markAsLearning(word)
                        } else {
                            viewModel.markAsLearned(word)
                        }
                        withAnimation {
                            swipedWordId = nil
                        }
                    },
                    onDelete: {
                        viewModel.deleteWord(word)
                        withAnimation {
                            swipedWordId = nil
                        }
                    },
                    onTap: {
                        selectedWord = word
                        withAnimation(.spring(response: 0.35)) {
                            showWordDetail = true
                        }
                    },
                    onSpeak: {
                        speakWord(word)
                    }
                )
            }
        }
        .padding(.horizontal, 18)
    }

    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#4ECDC4"))
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func speakWord(_ word: SavedWordModel) {
        let components = word.languagePair.components(separatedBy: "-")
        let sourceLang = components.first ?? "en"
        let utteranceID = "dictionary-\(word.id ?? "")"
        ttsManager.toggle(text: word.original, language: sourceLang, utteranceID: utteranceID)
    }

    private var selectionToolbar: some View {
        HStack(spacing: 12) {
            Text("\(selectedWordsTitle): \(selectedWordKeys.count)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))

            Spacer()

            Button(selectedWordKeys.count == allWords.count ? clearSelectionTitle : selectAllTitle) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                    if selectedWordKeys.count == allWords.count {
                        selectedWordKeys.removeAll()
                    } else {
                        selectedWordKeys = Set(allWords.map(selectionKey(for:)))
                    }
                }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Color(hex: "#4ECDC4"))

            Button(deleteSelectedTitle) {
                pendingDeleteScope = selectedWordKeys.count == allWords.count ? .all : .selected
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(selectedWordKeys.isEmpty ? .gray : .red)
            .disabled(selectedWordKeys.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private func selectionWordRow(_ word: SavedWordModel) -> some View {
        let key = selectionKey(for: word)
        let isSelected = selectedWordKeys.contains(key)

        return HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                    toggleSelection(for: word)
                }
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(isSelected ? Color(hex: "#4ECDC4") : .gray.opacity(0.7))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(word.original)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                    .lineLimit(1)

                Text(word.translation)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "#4ECDC4"))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(localizationManager.isDarkMode ? Color(hex: "#23252B") : Color.white.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    isSelected ? Color(hex: "#4ECDC4").opacity(0.7) : Color.white.opacity(localizationManager.isDarkMode ? 0.06 : 0.76),
                    lineWidth: isSelected ? 1.3 : 1
                )
        )
        .shadow(color: Color.black.opacity(localizationManager.isDarkMode ? 0.12 : 0.05), radius: 10, x: 0, y: 8)
    }

    private func toggleSelectionMode() {
        isSelectionMode.toggle()
        swipedWordId = nil
        if !isSelectionMode {
            selectedWordKeys.removeAll()
        }
    }

    private func toggleSelection(for word: SavedWordModel) {
        let key = selectionKey(for: word)
        if selectedWordKeys.contains(key) {
            selectedWordKeys.remove(key)
        } else {
            selectedWordKeys.insert(key)
        }
    }

    private func selectionKey(for word: SavedWordModel) -> String {
        let wordId = word.id ?? word.original.lowercased()
        return "\(wordId)|\(word.dictionaryId ?? dictionary.id ?? "")"
    }

    private func performPendingDeletion() {
        let wordsToDelete: [SavedWordModel]

        switch pendingDeleteScope {
        case .all:
            wordsToDelete = allWords
        case .selected:
            wordsToDelete = allWords.filter { selectedWordKeys.contains(selectionKey(for: $0)) }
        case .none:
            wordsToDelete = []
        }

        for word in wordsToDelete {
            viewModel.deleteWord(word)
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
            selectedWordKeys.removeAll()
            isSelectionMode = false
        }
        pendingDeleteScope = nil
    }

    private var dictionaryHeaderSubtitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Редагуйте, слухайте й повторюйте слова в одному просторі"
        case .polish: return "Edytuj, słuchaj i powtarzaj słowa w jednym miejscu"
        case .english: return "Edit, listen and review your words in one focused space"
        }
    }
}

private extension DictionaryWordsListView {
    enum DeleteScope {
        case selected
        case all
    }
}
