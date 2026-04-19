//
//  DictionaryView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 29.01.2026.
//

import FirebaseFirestore
import FirebaseAuth
import SwiftUI
import Combine

struct DictionaryView: View {
    @StateObject private var viewModel = DictionaryViewModel.shared

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var onboardingManager: OnboardingManager

    @State private var showMenu = false
    @State private var selectedTab: Int = 1
    @State private var showSettings = false

    @State private var showAddWord = false
    @State private var showCreateDictionary = false
    @State private var showExportImport = false
    @State private var wordToEdit: SavedWordModel?
    @State private var selectedDictionary: WordDictionaryModel?
    @State private var dictionaryToRename: WordDictionaryModel?
    @State private var dictionaryToDelete: WordDictionaryModel?

    private var backgroundColor: Color {
        AppColors.secondaryScreenBackground(isDarkMode: localizationManager.isDarkMode)
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
            rootContent
        }
    }
    
    private var rootContent: some View {
        ZStack {
            backgroundLayer
            contentColumn
            menuOverlay
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .safeAreaInset(edge: .bottom) {
            studyInset
        }
        .sheet(isPresented: $showAddWord, onDismiss: onAddWordDismiss) {
            addWordSheetContent
        }
        .sheet(isPresented: $showCreateDictionary) {
            CreateDictionarySheet { name in
                viewModel.createDictionary(named: name)
            }
            .environmentObject(localizationManager)
        }
        .sheet(isPresented: $showExportImport) {
            ExportImportView()
                .environmentObject(localizationManager)
                .environmentObject(appState)
        }
        .sheet(item: $dictionaryToRename) { dictionary in
            CreateDictionarySheet(
                onCreate: { name in
                    viewModel.renameDictionary(dictionary, to: name)
                },
                initialName: dictionary.name,
                customTitle: renameDictionaryTitle,
                customConfirmText: renameDictionaryConfirmTitle
            )
            .environmentObject(localizationManager)
        }
        .fullScreenCover(isPresented: $showSettings) {
            settingsScreen
        }
        .alert(deleteDictionaryTitle, isPresented: Binding(
            get: { dictionaryToDelete != nil },
            set: { newValue in
                if !newValue {
                    dictionaryToDelete = nil
                }
            }
        ), presenting: dictionaryToDelete) { dictionary in
            Button(deleteDictionaryConfirmTitle, role: .destructive) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    viewModel.deleteDictionary(dictionary)
                }
                dictionaryToDelete = nil
            }
            Button(cancelTitle, role: .cancel) {
                dictionaryToDelete = nil
            }
        } message: { dictionary in
            Text(deleteDictionaryMessage(for: dictionary))
        }
        .navigationDestination(item: $selectedDictionary) { dictionary in
            DictionaryWordsListView(dictionary: dictionary)
                .environmentObject(localizationManager)
                .environmentObject(appState)
        }
        .onChange(of: viewModel.learningCount) { _, count in
            onboardingManager.hasLearningWords = count > 0
        }
        .onAppear(perform: onAppearActions)
        .onDisappear(perform: onDisappearActions)
    }

    private var settingsScreen: some View {
        SettingsView()
            .environmentObject(localizationManager)
            .environmentObject(appState)
    }

    private var addWordSheetContent: some View {
        AddWordView(existingWord: wordToEdit) {
            viewModel.fetchSavedWords()
        }
        .environmentObject(localizationManager)
        .environmentObject(appState)
    }

    private func onAddWordDismiss() {
        wordToEdit = nil
    }

    private var backgroundLayer: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            Circle()
                .fill(Color(hex: "#4ECDC4").opacity(localizationManager.isDarkMode ? 0.16 : 0.14))
                .frame(width: 300, height: 300)
                .blur(radius: 56)
                .offset(x: -160, y: -240)

            Circle()
                .fill(Color(hex: "#FFD166").opacity(localizationManager.isDarkMode ? 0.10 : 0.12))
                .frame(width: 250, height: 250)
                .blur(radius: 56)
                .offset(x: 180, y: -120)
        }
    }

    private var contentColumn: some View {
        VStack(spacing: 0) {
            HeaderView(showMenu: $showMenu, title: localizationManager.string(.dictionary))
                .environmentObject(localizationManager)

            HStack(spacing: 10) {
                createDictionaryButton
                exportImportButton
                Spacer()
                addWordButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            contentBody

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var contentBody: some View {
        dictionariesGrid
    }

    @ViewBuilder
    private var menuOverlay: some View {
        if showMenu {
            MenuView(isShowing: $showMenu, selectedTab: $selectedTab, showSettings: $showSettings)
                .transition(.move(edge: .leading))
                .zIndex(100)
        }
    }

    @ViewBuilder
    private var studyInset: some View {
        EmptyView()
    }

    private func onAppearActions() {
        OnboardingContext.isOnDictionaryScreen = true
        viewModel.fetchSavedWords()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onboardingManager.hasLearningWords = viewModel.learningCount > 0
        }

        onboardingManager.userHasVisitedDictionary = true
    }

    private func onDisappearActions() {
        viewModel.stopListening()
        OnboardingContext.isOnDictionaryScreen = false
    }

    private var addWordButton: some View {
        Button {
            wordToEdit = nil
            showAddWord = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 48, height: 48)
                .foregroundColor(Color(hex: "#4ECDC4"))
            .background(
                Circle()
                    .fill(AppColors.controlFill(isDarkMode: localizationManager.isDarkMode))
            )
            .overlay(
                Circle()
                    .stroke(AppColors.cardBorder(isDarkMode: localizationManager.isDarkMode), lineWidth: 1)
            )
            .shadow(color: AppColors.shadow(isDarkMode: localizationManager.isDarkMode), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(addWordButtonTitle)
    }

    private var createDictionaryButton: some View {
        Button {
            showCreateDictionary = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 18, alignment: .center)

                Text(createDictionaryTitle)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundColor(Color(hex: "#4ECDC4"))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppColors.controlFill(isDarkMode: localizationManager.isDarkMode))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AppColors.cardBorder(isDarkMode: localizationManager.isDarkMode), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var exportImportButton: some View {
        Button {
            showExportImport = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up.on.square.fill")
                    .font(.system(size: 14, weight: .bold))
                Text(exportImportShortTitle)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#4ECDC4"), Color(hex: "#2FB3AA")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: Color(hex: "#4ECDC4").opacity(0.26), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(exportImportTitle)
    }

    private var addWordButtonTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Додати"
        case .polish: return "Dodaj"
        case .english: return "Add"
        }
    }

    private var createDictionaryTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Додати словник"
        case .polish: return "Dodaj slownik"
        case .english: return "Add Dictionary"
        }
    }

    private var exportImportTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Експорт та імпорт"
        case .polish: return "Eksport i import"
        case .english: return "Export and Import"
        }
    }

    private var exportImportShortTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Експорт"
        case .polish: return "Eksport"
        case .english: return "Export"
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
                .foregroundColor(AppColors.secondaryText(isDarkMode: localizationManager.isDarkMode))

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
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(AppColors.cardBackground(isDarkMode: localizationManager.isDarkMode))
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(AppColors.cardBorder(isDarkMode: localizationManager.isDarkMode), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }

    private var dictionariesGrid: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                if viewModel.dictionaries.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    ForEach(viewModel.dictionaries) { dictionary in
                        dictionaryTile(dictionary)
                    }
                }
            }
            .padding(.vertical, 12)
        }
    }

    private func dictionaryTile(_ dictionary: WordDictionaryModel) -> some View {
        let words = viewModel.words(in: dictionary.id)
        let learningCount = viewModel.learningWords(in: dictionary.id).count
        let learnedCount = viewModel.learnedWords(in: dictionary.id).count

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dictionary.name)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryText(isDarkMode: localizationManager.isDarkMode))

                    Text(dictionarySubtitle(words.count))
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.secondaryText(isDarkMode: localizationManager.isDarkMode))
                }

                Spacer()

                HStack(spacing: 10) {
                    Button {
                        dictionaryToDelete = dictionary
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.red.opacity(0.82))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())

                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                }
            }

            HStack(spacing: 10) {
                dictionaryStatPill(title: localizationManager.string(.words), value: "\(words.count)")
                dictionaryStatPill(title: localizationManager.string(.learning), value: "\(learningCount)")
                dictionaryStatPill(title: localizationManager.string(.learned), value: "\(learnedCount)")
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AppColors.cardBackground(isDarkMode: localizationManager.isDarkMode))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(AppColors.cardBorder(isDarkMode: localizationManager.isDarkMode), lineWidth: 1)
                )
        )
        .shadow(color: AppColors.shadow(isDarkMode: localizationManager.isDarkMode), radius: 16, x: 0, y: 8)
        .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .onTapGesture {
            selectedDictionary = dictionary
        }
        .padding(.horizontal, 18)
        .contextMenu {
            Button {
                dictionaryToRename = dictionary
            } label: {
                Label(renameDictionaryTitle, systemImage: "pencil")
            }
            Button(role: .destructive) {
                dictionaryToDelete = dictionary
            } label: {
                Label(deleteDictionaryConfirmTitle, systemImage: "trash")
            }
        }
    }

    private func dictionaryStatPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "#4ECDC4"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: "#4ECDC4").opacity(0.12))
        )
    }

    private func dictionarySubtitle(_ count: Int) -> String {
        switch localizationManager.currentLanguage {
        case .ukrainian:
            return count == 1 ? "1 слово" : "\(count) слів"
        case .polish:
            return count == 1 ? "1 slowo" : "\(count) slow"
        case .english:
            return count == 1 ? "1 word" : "\(count) words"
        }
    }

    private var renameDictionaryTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Редагувати назву"
        case .polish: return "Edytuj nazwe"
        case .english: return "Rename Dictionary"
        }
    }

    private var renameDictionaryConfirmTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Зберегти"
        case .polish: return "Zapisz"
        case .english: return "Save"
        }
    }

    private var deleteDictionaryTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Видалити словник?"
        case .polish: return "Usunąć słownik?"
        case .english: return "Delete dictionary?"
        }
    }

    private var deleteDictionaryConfirmTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Видалити словник"
        case .polish: return "Usuń słownik"
        case .english: return "Delete Dictionary"
        }
    }

    private var cancelTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Скасувати"
        case .polish: return "Anuluj"
        case .english: return "Cancel"
        }
    }

    private func deleteDictionaryMessage(for dictionary: WordDictionaryModel) -> String {
        let count = viewModel.wordCount(in: dictionary.id)

        switch localizationManager.currentLanguage {
        case .ukrainian:
            return "Словник \"\(dictionary.name)\" і всі \(count) слів у ньому буде видалено з пристрою та з хмари."
        case .polish:
            return "Słownik \"\(dictionary.name)\" i wszystkie \(count) słów w nim zostaną usunięte z urządzenia i z chmury."
        case .english:
            return "The dictionary \"\(dictionary.name)\" and all \(count) words inside it will be deleted from the device and the cloud."
        }
    }

}

// MARK: - Compact Word Row

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

    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var ttsManager = TextToSpeechService.shared

    @State private var offset: CGFloat = 0
    @State private var localIsLearned: Bool

    private let buttonWidth: CGFloat = 80
    private let swipeThreshold: CGFloat = 50
    private let rowHeight: CGFloat = 76
    
    init(word: SavedWordModel,
         isDarkMode: Bool,
         isSwiped: Bool,
         onSwipeRight: @escaping () -> Void,
         onSwipeLeft: @escaping () -> Void,
         onMarkLearned: @escaping () -> Void,
         onDelete: @escaping () -> Void,
         onTap: @escaping () -> Void,
         onSpeak: @escaping () -> Void) {
        self.word = word
        self.isDarkMode = isDarkMode
        self.isSwiped = isSwiped
        self.onSwipeRight = onSwipeRight
        self.onSwipeLeft = onSwipeLeft
        self.onMarkLearned = onMarkLearned
        self.onDelete = onDelete
        self.onTap = onTap
        self.onSpeak = onSpeak
        _localIsLearned = State(initialValue: word.isLearned)
    }
    
    private var leftActionTitle: String {
        if localIsLearned {
            switch localizationManager.currentLanguage {
            case .ukrainian: return "Назад"
            case .english: return "Back"
            case .polish: return "Powrót"
            }
        } else {
            switch localizationManager.currentLanguage {
            case .ukrainian: return "Вивчено"
            case .english: return "Learned"
            case .polish: return "Nauczone"
            }
        }
    }

    private var leftActionIcon: String {
        localIsLearned ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill"
    }

    private var leftActionColor: Color {
        localIsLearned ? Color.orange : Color(hex: "#4ECDC4")
    }

    var body: some View {
        ZStack {
            // Background buttons
            HStack(spacing: 0) {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        localIsLearned.toggle()
                    }
                    onMarkLearned()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: leftActionIcon)
                            .font(.system(size: 22))
                        Text(leftActionTitle)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.white)
                    .frame(width: buttonWidth)
                    .frame(maxHeight: .infinity)
                    .background(leftActionColor)
                }

                Spacer()

                Button(action: onDelete) {
                    VStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 22))
                        Text(localizationManager.string(.deleteButton))
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.white)
                    .frame(width: buttonWidth)
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
                }
            }

            // Main content
            HStack(spacing: 12) {
                let utteranceID = "dictionary-\(word.id ?? "")"
                Button(action: onSpeak) {
                    Image(systemName: ttsManager.isActive(utteranceID) ? "speaker.wave.2.fill" : "speaker.wave.2")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                        .frame(width: 32, height: 32)
                        .background(Color(hex: "#4ECDC4").opacity(0.15))
                        .clipShape(Circle())
                        .scaleEffect(ttsManager.isActive(utteranceID) ? 0.92 : 1.0)
                        .animation(.spring(response: 0.18, dampingFraction: 0.75), value: ttsManager.isActive(utteranceID))
                }
                .buttonStyle(PlainButtonStyle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(word.original)
                            .font(.system(size: 17, weight: .semibold))
                            .lineLimit(1)

                        if word.isDueForReview && !localIsLearned {
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
                            if let source = components.first,
                               let target = components.count > 1 ? components[1] : nil {
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

                if localIsLearned {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(height: rowHeight)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isDarkMode ? Color(hex: "#23252B") : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(isDarkMode ? 0.06 : 0.76), lineWidth: 1)
            )
            .offset(x: offset)
            .animation(.spring(response: 0.3), value: offset)
            .animation(.spring(response: 0.3), value: localIsLearned)
            .highPriorityGesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onChanged { gesture in
                        let horizontal = gesture.translation.width
                        let vertical = abs(gesture.translation.height)
                        guard abs(horizontal) > vertical * 1.5 else { return }
                        offset = horizontal > 0 ? min(horizontal, buttonWidth) : max(horizontal, -buttonWidth)
                    }
                    .onEnded { gesture in
                        let horizontal = gesture.translation.width
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if horizontal > swipeThreshold {
                                offset = buttonWidth
                                onSwipeRight()
                            } else if horizontal < -swipeThreshold {
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
            .onChange(of: isSwiped) { oldValue, newValue in
                // 🔥 Додай перевірку щоб уникнути зайвих анімацій
                guard oldValue != newValue else { return }
                if !newValue && abs(offset) > 0 {
                    withAnimation(.spring(response: 0.3)) {
                        offset = 0
                    }
                }
            }
        }
        .frame(height: rowHeight)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(isDarkMode ? 0.12 : 0.05), radius: 10, x: 0, y: 8)
    }
}

// MARK: - Word Detail Overlay

struct WordDetailOverlay: View {
    let word: SavedWordModel
    @Binding var isShowing: Bool
    var onEdit: () -> Void
    var onDelete: () -> Void

    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var appState: AppState

    @StateObject private var ttsManager = TextToSpeechService.shared
    @State private var showingDeleteConfirm = false

    private var sourceLanguage: String {
        let components = word.languagePair.components(separatedBy: "-")
        return components.first ?? "en"
    }

    private var targetLanguage: String {
        let components = word.languagePair.components(separatedBy: "-")
        return components.count > 1 ? components[1] : "uk"
    }

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
        case .ukrainian: return "Наступне"
        case .polish: return "Następna"
        case .english: return "Next"
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
        case .ukrainian: return "Це слово буде назавжди видалено"
        case .polish: return "To słowo zostanie trwale usunięte"
        case .english: return "This word will be permanently deleted"
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
                .onTapGesture {
                    closeOverlay()
                }
                .transition(.opacity)

            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    ViewThatFits(in: .vertical) {
                        overlayContent
                        ScrollView(showsIndicators: false) {
                            overlayContent
                        }
                        .scrollBounceBehavior(.basedOnSize)
                        .frame(maxHeight: geometry.size.height * 0.74)
                    }
                    .frame(maxWidth: min(geometry.size.width - 24, 420))
                    .background(overlayBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 12)
                    .shadow(color: Color(hex: "#4ECDC4").opacity(0.08), radius: 18, x: 0, y: 8)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: isShowing)
        .alert(deleteAlertTitle, isPresented: $showingDeleteConfirm) {
            Button(cancelTitle, role: .cancel) { }
            Button(deleteTitle, role: .destructive, action: onDelete)
        } message: {
            Text(deleteAlertMessage)
        }
    }

    private var overlayContent: some View {
        VStack(spacing: 20) {
            dragIndicator
            headerButtons
            sourceWordSection
            
            if let ipa = word.transcription, !ipa.isEmpty {
                transcriptionView(ipa)
            }

            targetWordSection

            if let example = word.exampleSentence, !example.isEmpty {
                examplesSection(original: example, originalLang: sourceLanguage)
            }

            learningInfoSection
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 24)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var dragIndicator: some View {
        Capsule()
            .fill(localizationManager.isDarkMode ? Color.white.opacity(0.14) : Color.black.opacity(0.12))
            .frame(width: 38, height: 5)
            .frame(maxWidth: .infinity)
    }

    private var headerButtons: some View {
        HStack(spacing: 12) {
            Button(action: onEdit) {
                overlayIconButton(
                    systemName: "pencil",
                    tint: Color(hex: "#4ECDC4"),
                    background: Color(hex: "#4ECDC4").opacity(localizationManager.isDarkMode ? 0.18 : 0.12)
                )
            }

            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .rigid)
                impact.impactOccurred()
                showingDeleteConfirm = true
            }) {
                overlayIconButton(
                    systemName: "trash",
                    tint: Color(red: 1.0, green: 0.35, blue: 0.35),
                    background: Color.red.opacity(localizationManager.isDarkMode ? 0.18 : 0.1)
                )
            }

            Spacer()

            Button(action: closeOverlay) {
                overlayIconButton(
                    systemName: "xmark",
                    tint: localizationManager.isDarkMode ? .white.opacity(0.7) : Color(hex: "#6C7A89"),
                    background: localizationManager.isDarkMode ? Color.white.opacity(0.08) : Color(hex: "#F3F7F7")
                )
            }
        }
    }

    private var sourceWordSection: some View {
        wordSection(text: word.original, language: sourceLanguage, isPrimary: true)
    }

    private var targetWordSection: some View {
        wordSection(text: word.translation, language: targetLanguage, isPrimary: false)
    }

    private func transcriptionView(_ ipa: String) -> some View {
        Text(ipa)
            .font(.system(size: 15, weight: .medium, design: .serif))
            .foregroundColor(Color(hex: "#4ECDC4").opacity(0.82))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(hex: "#4ECDC4").opacity(localizationManager.isDarkMode ? 0.18 : 0.12))
            )
    }

    private var overlayBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: localizationManager.isDarkMode
                        ? [Color(hex: "#1A1C1F"), Color(hex: "#20252B")]
                        : [Color.white, Color(hex: "#F6FBFB")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(localizationManager.isDarkMode ? 0.08 : 0.85),
                                Color(hex: "#4ECDC4").opacity(localizationManager.isDarkMode ? 0.12 : 0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }

    private func wordSection(text: String, language: String, isPrimary: Bool) -> some View {
        let prefix = isPrimary ? "dictionary-original" : "dictionary-translation"

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(isPrimary ? sourceWordTitle : translationWordTitle)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "#7B8A97"))
                        .textCase(.uppercase)

                    Text(text)
                        .font(.system(size: isPrimary ? 30 : 26, weight: isPrimary ? .bold : .semibold, design: .rounded))
                        .foregroundColor(isPrimary ? (localizationManager.isDarkMode ? .white : Color(hex: "#243447")) : Color(hex: "#4ECDC4"))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                }

                Spacer(minLength: 8)

                Button(action: {
                    speak(text: text, language: language, prefix: prefix)
                }) {
                    Image(systemName: isSpeaking(text: text, language: language, prefix: prefix) ? "speaker.wave.2.fill" : "speaker.wave.2")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isPrimary ? Color(hex: "#4ECDC4") : .white)
                        .frame(width: 46, height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(isPrimary ? Color(hex: "#4ECDC4").opacity(0.12) : Color(hex: "#4ECDC4"))
                        )
                        .scaleEffect(isSpeaking(text: text, language: language, prefix: prefix) ? 0.94 : 1.0)
                        .animation(.spring(response: 0.18, dampingFraction: 0.75),
                                   value: isSpeaking(text: text, language: language, prefix: prefix))
                }
            }

            HStack(spacing: 8) {
                languagePill(text: language.uppercased(), tint: isPrimary ? Color(hex: "#4ECDC4") : Color(hex: "#6C7A89"))

                if isPrimary {
                    languagePill(text: primaryWordBadge, tint: Color(hex: "#FFB648"))
                } else {
                    languagePill(text: translatedWordBadge, tint: Color(hex: "#4ECDC4"))
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(detailCardBackground)
    }

    private func examplesSection(original: String, originalLang: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(examplesTitle)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "#7B8A97"))

            HStack(spacing: 10) {
                Text("„\(original)\"")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .italic()
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(4)

                Spacer(minLength: 0)

                Button(action: {
                    speak(text: original, language: originalLang, prefix: "dictionary-example")
                }) {
                    Image(systemName: isSpeaking(text: original, language: originalLang, prefix: "dictionary-example") ? "speaker.wave.2.fill" : "speaker.wave.1")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(hex: "#4ECDC4").opacity(0.12))
                        )
                        .scaleEffect(isSpeaking(text: original, language: originalLang, prefix: "dictionary-example") ? 0.92 : 1.0)
                        .animation(.spring(response: 0.18, dampingFraction: 0.75),
                                   value: isSpeaking(text: original, language: originalLang, prefix: "dictionary-example"))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(detailCardBackground)
        }
    }

    private var learningInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(progressTitle)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "#7B8A97"))

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: word.isLearned ? "checkmark.seal.fill" : "graduationcap.fill")
                        .foregroundColor(word.isLearned ? Color(hex: "#4ECDC4") : .orange)
                        .font(.system(size: 16))
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(statusTitle)
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Text(word.isLearned ? statusLearned : statusLearning)
                            .font(.system(size: 13, weight: .medium))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Color(hex: "#4ECDC4"))
                            .font(.system(size: 16))
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(reviewsTitle)
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                            Text("\(word.reviewCount)")
                                .font(.system(size: 13, weight: .medium))
                        }
                    }
                }
                
                if let nextReview = word.nextReviewDate {
                    Divider()
                        .opacity(0.3)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundColor(.orange)
                            .font(.system(size: 16))
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(nextReviewTitle)
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                            Text(timeString(from: nextReview))
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(detailCardBackground)
        }
    }

    private var detailCardBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(localizationManager.isDarkMode ? Color.white.opacity(0.05) : Color.white.opacity(0.96))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(localizationManager.isDarkMode ? 0.08 : 0.75), lineWidth: 1)
            )
    }

    private func overlayIconButton(systemName: String, tint: Color, background: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(tint)
            .frame(width: 42, height: 42)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(background)
            )
    }

    private func languagePill(text: String, tint: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(localizationManager.isDarkMode ? 0.18 : 0.1))
            )
    }

    private var sourceWordTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Оригінал"
        case .polish: return "Oryginał"
        case .english: return "Original"
        }
    }

    private var translationWordTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Переклад"
        case .polish: return "Tłumaczenie"
        case .english: return "Translation"
        }
    }

    private var primaryWordBadge: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Вивчаєш"
        case .polish: return "Uczysz się"
        case .english: return "Learning"
        }
    }

    private var translatedWordBadge: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Значення"
        case .polish: return "Znaczenie"
        case .english: return "Meaning"
        }
    }

    private func utteranceID(text: String, language: String, prefix: String) -> String {
        "\(prefix)|\(word.id ?? "unknown")|\(language)|\(text.lowercased())"
    }

    private func speak(text: String, language: String, prefix: String) {
        let id = utteranceID(text: text, language: language, prefix: prefix)
        ttsManager.toggle(text: text, language: language, utteranceID: id)
    }

    private func isSpeaking(text: String, language: String, prefix: String) -> Bool {
        let id = utteranceID(text: text, language: language, prefix: prefix)
        return ttsManager.isActive(id)
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
