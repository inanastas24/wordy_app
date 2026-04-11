//
//  AddWordView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 02.03.2026.
//

import SwiftUI

struct AddWordView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var appState: AppState
    
    @StateObject private var viewModel = DictionaryViewModel.shared
    
    // Для редагування існуючого слова (nil якщо додаємо нове)
    var existingWord: SavedWordModel?
    var preselectedDictionaryId: String? = nil
    var onSave: (() -> Void)?
    
    @State private var original: String = ""
    @State private var translation: String = ""
    @State private var transcription: String = ""
    @State private var exampleSentence: String = ""
    @State private var selectedLanguagePair: String = ""
    @State private var selectedDictionaryId: String = ""
    
    @State private var showSourcePicker = false
    @State private var showTargetPicker = false
    @State private var showDictionaryPicker = false
    @State private var showConfirmation = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    private var isEditing: Bool { existingWord != nil }
    
    private var navigationTitle: String {
        if isEditing {
            switch localizationManager.currentLanguage {
            case .ukrainian: return "Редагувати слово"
            case .polish: return "Edytuj słowo"
            case .english: return "Edit Word"
            }
        } else {
            switch localizationManager.currentLanguage {
            case .ukrainian: return "Додати слово"
            case .polish: return "Dodaj słowo"
            case .english: return "Add Word"
            }
        }
    }
    
    private var saveButtonTitle: String {
        if isEditing {
            switch localizationManager.currentLanguage {
            case .ukrainian: return "Зберегти"
            case .polish: return "Zapisz"
            case .english: return "Save"
            }
        } else {
            switch localizationManager.currentLanguage {
            case .ukrainian: return "Додати"
            case .polish: return "Dodaj"
            case .english: return "Add"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: localizationManager.isDarkMode ? "#1C1C1E" : "#FFFDF5")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Language Pair Selector (новий дизайн як у DictionaryView)
                        languagePairSection
                            .padding(.top, 10)

                        dictionarySection
                        
                        // Original Word
                        inputSection(
                            title: localizationManager.string(.originalWord),
                            placeholder: localizationManager.string(.enterWord),
                            text: $original,
                            icon: "textformat",
                            isRequired: true
                        )
                        
                        // Translation
                        inputSection(
                            title: localizationManager.string(.translation),
                            placeholder: localizationManager.string(.enterTranslation),
                            text: $translation,
                            icon: "arrow.left.arrow.right",
                            isRequired: true
                        )
                        
                        // Transcription (Optional)
                        inputSection(
                            title: localizationManager.string(.transcription),
                            placeholder: localizationManager.string(.optional),
                            text: $transcription,
                            icon: "speaker.wave.1",
                            isRequired: false
                        )
                        
                        // Example (Optional)
                        inputSection(
                            title: localizationManager.string(.example),
                            placeholder: localizationManager.string(.enterExample),
                            text: $exampleSentence,
                            icon: "text.quote",
                            isRequired: false,
                            isMultiline: true
                        )
                        
                        // Preview Card
                        if !original.isEmpty || !translation.isEmpty {
                            previewCard
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
                
                // Source Language Picker
                if showSourcePicker {
                    languagePicker(
                        title: localizationManager.string(.language1),
                        selectedLanguage: currentSourceLanguage,
                        onSelect: { language in
                            // Оновлюємо selectedLanguagePair при зміні source
                            let target = currentTargetLanguage
                            selectedLanguagePair = "\(language.rawValue)-\(target.rawValue)"
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
                
                // Target Language Picker
                if showTargetPicker {
                    languagePicker(
                        title: localizationManager.string(.language2),
                        selectedLanguage: currentTargetLanguage,
                        onSelect: { language in
                            // Оновлюємо selectedLanguagePair при зміні target
                            let source = currentSourceLanguage
                            selectedLanguagePair = "\(source.rawValue)-\(language.rawValue)"
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
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showDictionaryPicker) {
                DictionarySelectionSheet(
                    dictionaries: viewModel.dictionaries,
                    selectedDictionaryId: selectedDictionaryId,
                    title: dictionaryTitle
                ) { dictionary in
                    let resolvedId = viewModel.resolvedSelectionDictionaryId(for: dictionary)
                    print("🎯 ADD WORD selected dictionary name='\(dictionary.name)' rawId='\(dictionary.id ?? "nil")' resolvedId='\(resolvedId)'")
                    selectedDictionaryId = resolvedId
                }
                .environmentObject(localizationManager)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizationManager.string(.cancel)) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(saveButtonTitle) {
                        saveWord()
                    }
                    .disabled(!isValid)
                    .font(.system(size: 17, weight: .semibold))
                }
            }
            .alert(localizationManager.string(.error), isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? localizationManager.string(.unknownError))
            }
            .alert(localizationManager.string(.wordAdded), isPresented: $showConfirmation) {
                Button(localizationManager.string(.addAnother)) {
                    resetFields()
                }
                Button(localizationManager.string(.done), role: .cancel) {
                    onSave?()
                    dismiss()
                }
            } message: {
                Text(isEditing ?
                    localizationManager.string(.wordUpdatedMessage) :
                    localizationManager.string(.wordAddedMessage))
            }
            .onAppear {
                loadExistingWord()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentSourceLanguage: TranslationLanguage {
        let pair = currentLanguagePair
        let components = pair.components(separatedBy: "-")
        return TranslationLanguage(rawValue: components.first ?? "en") ?? .english
    }
    
    private var currentTargetLanguage: TranslationLanguage {
        let pair = currentLanguagePair
        let components = pair.components(separatedBy: "-")
        return TranslationLanguage(rawValue: components.count > 1 ? components[1] : "uk") ?? .ukrainian
    }
    
    private var isValid: Bool {
        !original.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var currentLanguagePair: String {
        if !selectedLanguagePair.isEmpty {
            return selectedLanguagePair
        }
        return appState.languagePair.languagePairString
    }

    private var currentDictionaryName: String {
        if let dictionary = viewModel.dictionary(for: selectedDictionaryId) {
            return dictionary.name
        }
        return viewModel.defaultDictionary().name
    }

    private var dictionaryTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Словник"
        case .polish: return "Slownik"
        case .english: return "Dictionary"
        }
    }
    
    // MARK: - Data Loading
    
    private func loadExistingWord() {
        guard let word = existingWord else {
            selectedLanguagePair = appState.languagePair.languagePairString
            selectedDictionaryId = preselectedDictionaryId ?? viewModel.defaultDictionaryId()
            return
        }
        
        original = word.original
        translation = word.translation
        transcription = word.transcription ?? ""
        exampleSentence = word.exampleSentence ?? ""
        selectedLanguagePair = word.languagePair
        selectedDictionaryId = word.dictionaryId ?? preselectedDictionaryId ?? viewModel.defaultDictionaryId()
    }
    
    private func resetFields() {
        if !isEditing {
            original = ""
            translation = ""
            transcription = ""
            exampleSentence = ""
        }
    }
    
    private func saveWord() {
        guard isValid else { return }
        
        let trimmedOriginal = original.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTranslation = translation.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTranscription = transcription.isEmpty ? nil : transcription.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedExample = exampleSentence.isEmpty ? nil : exampleSentence.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("🎯 ADD WORD save original='\(trimmedOriginal)' selectedDictionaryId='\(selectedDictionaryId)'")
        let wordModel = SavedWordModel(
            id: existingWord?.id ?? UUID().uuidString,
            original: trimmedOriginal,
            translation: trimmedTranslation,
            transcription: trimmedTranscription,
            exampleSentence: trimmedExample,
            languagePair: currentLanguagePair,
            dictionaryId: selectedDictionaryId.isEmpty ? viewModel.defaultDictionaryId() : selectedDictionaryId,
            isLearned: existingWord?.isLearned ?? false,
            reviewCount: existingWord?.reviewCount ?? 0,
            srsInterval: existingWord?.srsInterval ?? 0,
            srsRepetition: existingWord?.srsRepetition ?? 0,
            srsEasinessFactor: existingWord?.srsEasinessFactor ?? 2.5,
            nextReviewDate: existingWord?.nextReviewDate,
            lastReviewDate: existingWord?.lastReviewDate,
            averageQuality: existingWord?.averageQuality ?? 0,
            createdAt: existingWord?.createdAt ?? Date()
        )
        
        viewModel.saveWord(wordModel)
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        showConfirmation = true
    }
    
    // MARK: - UI Components
    
    private var languagePairSection: some View {
        HStack(spacing: 12) {
            // Source Language Button
            Button {
                withAnimation(.spring(response: 0.35)) {
                    showSourcePicker = true
                }
            } label: {
                HStack(spacing: 6) {
                    Text(currentSourceLanguage.flag)
                        .font(.system(size: 20))
                    Text(currentSourceLanguage.localizedName(in: localizationManager.currentLanguage))
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
            
            // Swap Button
            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    let source = currentSourceLanguage
                    let target = currentTargetLanguage
                    selectedLanguagePair = "\(target.rawValue)-\(source.rawValue)"
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
            
            // Target Language Button
            Button {
                withAnimation(.spring(response: 0.35)) {
                    showTargetPicker = true
                }
            } label: {
                HStack(spacing: 6) {
                    Text(currentTargetLanguage.flag)
                        .font(.system(size: 20))
                    Text(currentTargetLanguage.localizedName(in: localizationManager.currentLanguage))
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

    private var dictionarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dictionaryTitle)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))

            Button {
                showDictionaryPicker = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "#4ECDC4"))

                    Text(currentDictionaryName)
                        .font(.system(size: 16))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "#4ECDC4").opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Language Picker (скопійовано з DictionaryView)
    
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
    
    private func inputSection(
        title: String,
        placeholder: String,
        text: Binding<String>,
        icon: String,
        isRequired: Bool,
        isMultiline: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                
                if isRequired {
                    Text("*")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "#F38BA8"))
                }
            }
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#4ECDC4"))
                    .frame(width: 24)
                
                if isMultiline {
                    TextEditor(text: text)
                        .font(.system(size: 16))
                        .frame(minHeight: 80, maxHeight: 120)
                } else {
                    TextField(placeholder, text: text)
                        .font(.system(size: 16))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, isMultiline ? 12 : 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "#E0E0E0").opacity(localizationManager.isDarkMode ? 0.3 : 1), lineWidth: 1)
            )
        }
    }
    
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localizationManager.string(.preview))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(original.isEmpty ? "—" : original)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                        
                        if !transcription.isEmpty {
                            Text(transcription)
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#4ECDC4"))
                        }
                    }
                    
                    Spacer()
                }
                
                if !translation.isEmpty {
                    Divider()
                    
                    Text(translation)
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                }
                
                if !exampleSentence.isEmpty {
                    Divider()
                    
                    Text(exampleSentence)
                        .font(.system(size: 14, weight: .medium))
                        .italic()
                        .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                        .lineLimit(2)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(hex: "#4ECDC4").opacity(0.2), lineWidth: 1)
            )
        }
    }
}
