//1
//  TranslationBubbleOverlay.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI
import AVFoundation
import FirebaseAuth

struct TranslationBubbleOverlay: View {
    let result: TranslationResult
    @Binding var showTranslationCard: Bool
    @Binding var translationResult: TranslationResult?
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var appState: AppState
    
    @State private var showingSynonymAlert = false
    @State private var selectedSynonym = ""
    @State private var saveState: SaveState = .idle
    
    @State private var showingSynonymDetail = false
    @State private var selectedSynonymDetail: SynonymDetail?
    @State private var synonymSaveState: SaveState = .idle
    @State private var synonymScale: CGFloat = 1.0
    
    @StateObject private var dictionaryVM = DictionaryViewModel.shared
    
    @State private var synonymTranslations: [String: String] = [:]
    @State private var isLoadingSynonyms = false
    
    enum SaveState: Equatable {
        case idle, loading, success, error(String)
    }
    
    private var originalLanguage: String {
        if result.ipaTranscription != nil {
            return "en"
        }
        if isUkrainian(result.original) {
            return "uk"
        }
        return appState.learningLanguage
    }
    
    private var translationLanguage: String {
        return appState.appLanguage
    }
    
    private func isUkrainian(_ text: String) -> Bool {
        let ukrainianChars = CharacterSet(charactersIn: "а-яА-ЯїЇєЄіІґҐ")
        return text.rangeOfCharacter(from: ukrainianChars) != nil
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(showingSynonymDetail ? 0.7 : 0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    if !showingSynonymDetail {
                        closeCard()
                    }
                }
                .blur(radius: showingSynonymDetail ? 5 : 2)
                .animation(.easeInOut(duration: 0.3), value: showingSynonymDetail)
            
            GeometryReader { geometry in
                ScrollView {
                    VStack {
                        Spacer(minLength: geometry.size.height * 0.05)
                        
                        VStack(spacing: 20) {
                            HStack {
                                Spacer()
                                Button(action: closeCard) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(localizationManager.isDarkMode ? .white.opacity(0.6) : Color(hex: "#7F8C8D"))
                                        .padding(8)
                                        .background(Circle().fill(Color.gray.opacity(0.2)))
                                }
                            }
                            
                            // Оригінальне слово з переносом
                            VStack(spacing: 8) {
                                HStack(spacing: 12) {
                                    Text(result.original)
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                                        .lineLimit(nil) // Без обмеження рядків
                                        .fixedSize(horizontal: false, vertical: true) // Перенос на новий рядок
                                        .multilineTextAlignment(.center)
                                    
                                    Button(action: { speak(text: result.original, language: originalLanguage) }) {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color(hex: "#4ECDC4"))
                                            .frame(width: 36, height: 36)
                                            .background(Color(hex: "#4ECDC4").opacity(0.15))
                                            .clipShape(Circle())
                                    }
                                }
                                
                                if let ipa = result.ipaTranscription {
                                    Text(ipa)
                                        .font(.system(size: 16, design: .serif))
                                        .foregroundColor(Color(hex: "#4ECDC4").opacity(0.8))
                                }
                            }
                            
                            Divider().opacity(0.5)
                            
                            // Переклад з переносом
                            VStack(spacing: 8) {
                                HStack(spacing: 12) {
                                    Text(result.translation)
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(Color(hex: "#4ECDC4"))
                                        .lineLimit(nil) // Без обмеження рядків
                                        .fixedSize(horizontal: false, vertical: true) // Перенос на новий рядок
                                        .multilineTextAlignment(.center)
                                    
                                    Button(action: { speak(text: result.translation, language: translationLanguage) }) {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                            .frame(width: 36, height: 36)
                                            .background(Color(hex: "#4ECDC4"))
                                            .clipShape(Circle())
                                    }
                                }
                            }
                            
                            examplesSection
                            
                            if !filteredSynonyms.isEmpty {
                                synonymsSection
                            }
                            
                            saveButton
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(.ultraThinMaterial)
                                .background(
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(localizationManager.isDarkMode ? Color.black.opacity(0.4) : Color.white.opacity(0.8))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .frame(maxWidth: min(geometry.size.width - 40, 380))
                        .shadow(color: Color(hex: "#4ECDC4").opacity(0.1), radius: 40, x: 0, y: 20)
                        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: geometry.size.height * 0.05)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
            .blur(radius: showingSynonymDetail ? 3 : 0)
            .animation(.easeInOut(duration: 0.3), value: showingSynonymDetail)
            
            if showingSynonymDetail, let detail = selectedSynonymDetail {
                synonymDetailModal(detail: detail)
            }
        }
        .onAppear {
            loadSynonymTranslations()
        }
    }
    
    private var filteredSynonyms: [String] {
        let blockedWords = ["motherfucker", "fuck", "shit", "damn", "ass", "bitch", "bastard", "crap", "hell"]
        let blockedPatterns = ["fuck", "shit", "damn", "ass", "bitch", "bastard", "hell", "crap"]
        
        return result.synonyms.filter { synonym in
            let lowercased = synonym.lowercased()
            if blockedWords.contains(lowercased) {
                return false
            }
            for pattern in blockedPatterns {
                if lowercased.contains(pattern) {
                    return false
                }
            }
            return true
        }
    }
    
    private func loadSynonymTranslations() {
        guard !filteredSynonyms.isEmpty else { return }
        
        let sourceLang = "en"
        let targetLang = appState.appLanguage
        
        isLoadingSynonyms = true
        
        let translationService = TranslationService()
        translationService.translateSynonyms(
            synonyms: filteredSynonyms,
            sourceLang: sourceLang,
            targetLang: targetLang
        ) { details in
            var translations: [String: String] = [:]
            for detail in details {
                translations[detail.word] = detail.translation
            }
            
            DispatchQueue.main.async {
                self.synonymTranslations = translations
                self.isLoadingSynonyms = false
            }
        }
    }
    
    private func synonymDetailModal(detail: SynonymDetail) -> some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { closeSynonymDetail() }
            
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 5)
                        .padding(.top, 12)
                    
                    Text("Синонім")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(localizationManager.isDarkMode ? Color.gray.opacity(0.8) : .secondary)
                        .tracking(1)
                }
                
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            Text(detail.word)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                speak(text: detail.word, language: "en")
                            }) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: "#4ECDC4"))
                                    .frame(width: 44, height: 44)
                                    .background(Color(hex: "#4ECDC4").opacity(0.15))
                                    .clipShape(Circle())
                            }
                        }
                        
                        if let ipa = detail.ipaTranscription, !ipa.isEmpty {
                            Text(ipa)
                                .font(.system(size: 18, design: .serif))
                                .foregroundColor(Color(hex: "#4ECDC4"))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(hex: "#4ECDC4").opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 8) {
                        Text("Переклад")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(localizationManager.isDarkMode ? Color.gray.opacity(0.8) : .secondary)
                            .tracking(0.5)
                        
                        let translation = detail.translation
                        let isValidTranslation = !translation.isEmpty &&
                                                translation.lowercased() != detail.word.lowercased() &&
                                                translation != "-"
                        
                        if isValidTranslation {
                            Text(translation)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(Color(hex: "#4ECDC4"))
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            if translation.isEmpty || translation == "-" {
                                Text("Завантаження...")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color.gray)
                                    .multilineTextAlignment(.center)
                                    .onAppear {
                                        reloadTranslationForDetail(detail)
                                    }
                            } else {
                                Text(translation)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(Color(hex: "#4ECDC4"))
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    
                    Spacer(minLength: 10)
                    
                    Button(action: { saveSynonymToDictionary(detail) }) {
                        HStack(spacing: 12) {
                            switch synonymSaveState {
                            case .idle:
                                Image(systemName: "book.fill")
                                    .font(.system(size: 18))
                                Text("Додати до словника")
                                    .font(.system(size: 17, weight: .semibold))
                                
                            case .loading:
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.9)
                                Text("Збереження...")
                                    .font(.system(size: 17, weight: .semibold))
                                
                            case .success:
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .transition(.scale)
                                Text("Збережено!")
                                    .font(.system(size: 17, weight: .semibold))
                                    .transition(.opacity)
                                
                            case .error(let msg):
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 18))
                                Text(msg)
                                    .font(.system(size: 15, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    synonymSaveState == .success ?
                                        LinearGradient(
                                            colors: [Color(hex: "#2ECC71"), Color(hex: "#2ECC71")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ) :
                                        LinearGradient(
                                            colors: [Color(hex: "#4ECDC4"), Color(hex: "#44A08D")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                )
                        )
                        .shadow(
                            color: (synonymSaveState == .success ? Color(hex: "#2ECC71") : Color(hex: "#4ECDC4")).opacity(0.3),
                            radius: 12,
                            x: 0,
                            y: 6
                        )
                    }
                    .disabled(synonymSaveState == .loading || synonymSaveState == .success)
                    .padding(.horizontal, 20)
                    
                    Button(action: closeSynonymDetail) {
                        Text("Скасувати")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(localizationManager.isDarkMode ? Color.white.opacity(0.7) : .secondary)
                            .padding(.vertical, 12)
                    }
                }
                .padding(.vertical, 20)
            }
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(localizationManager.isDarkMode ? Color(hex: "#1C1C1E") : Color.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 40, x: 0, y: 20)
            )
            .frame(width: 320, height: 420)
            .scaleEffect(synonymScale)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: synonymScale)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.8).combined(with: .opacity),
                removal: .scale(scale: 0.9).combined(with: .opacity)
            ))
        }
    }
    
    private func reloadTranslationForDetail(_ detail: SynonymDetail) {
        let translationService = TranslationService()
        translationService.translateSynonyms(
            synonyms: [detail.word],
            sourceLang: "en",
            targetLang: appState.appLanguage
        ) { details in
            guard let newDetail = details.first else { return }
            
            DispatchQueue.main.async {
                self.selectedSynonymDetail = SynonymDetail(
                    word: detail.word,
                    ipaTranscription: detail.ipaTranscription,
                    translation: newDetail.translation
                )
                self.synonymTranslations[detail.word] = newDetail.translation
            }
        }
    }
    
    private func saveSynonymToDictionary(_ detail: SynonymDetail) {
        guard synonymSaveState != .loading else { return }
        
        synonymSaveState = .loading
        
        Task {
            let wordModel = SavedWordModel(
                original: detail.word,
                translation: detail.translation,
                transcription: detail.ipaTranscription,
                exampleSentence: nil,
                languagePair: "en-\(appState.appLanguage)",
                isLearned: false,
                reviewCount: 0,
                srsInterval: 0,
                srsRepetition: 0,
                srsEasinessFactor: 2.5,
                nextReviewDate: nil,
                lastReviewDate: nil,
                averageQuality: 0,
                createdAt: Date()
            )
            
            // ВИКОРИСТОВУЄМО DictionaryViewModel
            dictionaryVM.saveWord(wordModel)
            
            await MainActor.run {
                synonymSaveState = .success
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    closeSynonymDetail()
                }
            }
        }
    }
    
    private func closeSynonymDetail() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            synonymScale = 0.9
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showingSynonymDetail = false
                selectedSynonymDetail = nil
            }
            synonymSaveState = .idle
            synonymScale = 1.0
        }
    }
    
    private var synonymsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Синоніми")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                
                Spacer()
                
                if isLoadingSynonyms {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("\(filteredSynonyms.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#4ECDC4"))
                        .cornerRadius(10)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(filteredSynonyms, id: \.self) { synonym in
                        Button(action: {
                            openSynonymDetail(synonym)
                        }) {
                            VStack(spacing: 4) {
                                Text(synonym)
                                    .font(.system(size: 14, weight: .medium))
                                
                                if let translation = synonymTranslations[synonym],
                                   !translation.isEmpty,
                                   translation.lowercased() != synonym.lowercased() {
                                    Text(translation)
                                        .font(.system(size: 11))
                                        .lineLimit(1)
                                        .opacity(0.9)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [synonymColor(for: synonym).opacity(0.9), synonymColor(for: synonym)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .shadow(color: synonymColor(for: synonym).opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .scaleEffect(selectedSynonym == synonym ? 0.92 : 1.0)
                        .animation(.spring(response: 0.2), value: selectedSynonym)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private func openSynonymDetail(_ synonym: String) {
        selectedSynonym = synonym
        
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        withAnimation(.spring(response: 0.2)) {
            selectedSynonym = synonym
        }
        
        Task {
            await fetchSynonymDetail(synonym)
        }
    }
    
    private func fetchSynonymDetail(_ synonym: String) async {
        await MainActor.run {
            synonymSaveState = .idle
            synonymScale = 0.9
        }
        
        let cachedTranslation = synonymTranslations[synonym]
        
        var ipa: String? = nil
        let encodedWord = synonym.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? synonym
        let urlString = "https://api.dictionaryapi.dev/api/v2/entries/en/\(encodedWord.lowercased())"
        
        if let url = URL(string: urlString) {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    if let entry = jsonArray.first,
                       let phonetics = entry["phonetics"] as? [[String: Any]] {
                        for phonetic in phonetics {
                            if let text = phonetic["text"] as? String, !text.isEmpty {
                                ipa = text
                                break
                            }
                        }
                    }
                }
            } catch {
                print("Помилка отримання IPA для синоніма: \(error)")
            }
        }
        
        var finalTranslation: String
        
        if let cached = cachedTranslation, !cached.isEmpty, cached != synonym {
            finalTranslation = cached
        } else {
            let translationService = TranslationService()
            finalTranslation = await withCheckedContinuation { continuation in
                translationService.translateSynonyms(
                    synonyms: [synonym],
                    sourceLang: "en",
                    targetLang: appState.appLanguage
                ) { details in
                    let translation = details.first?.translation ?? synonym
                    continuation.resume(returning: translation)
                }
            }
            
            await MainActor.run {
                synonymTranslations[synonym] = finalTranslation
            }
        }
        
        await MainActor.run {
            selectedSynonymDetail = SynonymDetail(
                word: synonym,
                ipaTranscription: ipa,
                translation: finalTranslation
            )
            showSynonymModal()
        }
    }
    
    private func showSynonymModal() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showingSynonymDetail = true
            synonymScale = 1.0
        }
    }
    
    private func synonymColor(for synonym: String) -> Color {
        let colors = [
            Color(hex: "#4ECDC4"),
            Color(hex: "#44A08D"),
            Color(hex: "#A8D8EA"),
            Color(hex: "#95E1D3"),
            Color(hex: "#F38BA8"),
            Color(hex: "#FFD93D"),
            Color(hex: "#6BCB77"),
            Color(hex: "#4D96FF"),
            Color(hex: "#9B59B6"),
        ]
        let hash = abs(synonym.hashValue)
        return colors[hash % colors.count]
    }
    
    private var examplesSection: some View {
        VStack(spacing: 16) {
            if !result.exampleSentence.isEmpty {
                exampleCard(
                    original: result.exampleSentence,
                    translation: result.exampleTranslation
                )
            }
            
            if let ex2 = result.exampleSentence2, !ex2.isEmpty,
               let tr2 = result.exampleTranslation2, !tr2.isEmpty {
                if !result.exampleSentence.isEmpty {
                    Divider()
                }
                exampleCard(
                    original: ex2,
                    translation: tr2
                )
            }
        }
    }
    
    private func exampleCard(original: String, translation: String) -> some View {
        VStack(spacing: 8) {
            Text(original)
                .font(.system(size: 16))
                .italic()
                .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            if !translation.isEmpty && translation != original {
                Text(translation)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#4ECDC4"))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private var saveButton: some View {
        Button(action: saveWordWithCloud) {
            HStack(spacing: 10) {
                switch saveState {
                case .idle:
                    Image(systemName: "plus.circle.fill")
                    Text(localizationManager.currentLanguage == .ukrainian ? "Зберегти до словника" : "Save to dictionary")
                    
                case .loading:
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                    Text("Збереження...")
                    
                case .success:
                    Image(systemName: "checkmark.circle.fill")
                        .transition(.scale)
                    Text("Збережено!")
                        .transition(.opacity)
                    
                case .error(let message):
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(message)
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColorForState)
            .cornerRadius(25)
            .animation(.spring(response: 0.3), value: saveState)
        }
        .disabled(saveState == .loading || saveState == .success)
        .padding(.top, 10)
    }
    
    private var backgroundColorForState: Color {
        switch saveState {
        case .idle: return Color(hex: "#4ECDC4")
        case .loading: return Color(hex: "#4ECDC4").opacity(0.7)
        case .success: return Color(hex: "#2ECC71")
        case .error(_): return Color(hex: "#F38BA8")
        }
    }
    
    private func saveWordWithCloud() {
        guard saveState != .loading else { return }
        
        saveState = .loading
        
        Task {
            do {
                let wordModel = SavedWordModel(
                    original: result.original,
                    translation: result.translation,
                    transcription: result.ipaTranscription,
                    exampleSentence: result.exampleSentence,
                    languagePair: "\(originalLanguage)-\(translationLanguage)",
                    isLearned: false,
                    reviewCount: 0,
                    srsInterval: 0,
                    srsRepetition: 0,
                    srsEasinessFactor: 2.5,
                    nextReviewDate: nil,
                    lastReviewDate: nil,
                    averageQuality: 0,
                    createdAt: Date()
                )
                
                // ВИКОРИСТОВУЄМО DictionaryViewModel замість FirestoreService напряму
                dictionaryVM.saveWord(wordModel)
                
                // Якщо анонімний - одразу показуємо успіх (бо локальне збереження швидке)
                if Auth.auth().currentUser?.isAnonymous == true {
                    await MainActor.run {
                        saveState = .success
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            closeCard()
                        }
                    }
                } else {
                    // Для авторизованих чекаємо на Firebase
                    await MainActor.run {
                        saveState = .success
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            closeCard()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    saveState = .error("Помилка збереження")
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        saveState = .idle
                    }
                }
            }
        }
    }
    
    private func closeCard() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showTranslationCard = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            translationResult = nil
        }
    }
    
    private func speak(text: String, language: String) {
        SpeechService.shared.speak(text, language: language)
    }
}
