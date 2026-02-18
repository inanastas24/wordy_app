//1
//  DictionaryViewModel.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 29.01.2026.
//

import FirebaseFirestore
import FirebaseAuth
import Foundation
import Combine

@MainActor
class DictionaryViewModel: ObservableObject {
    static let shared = DictionaryViewModel()
    
    @Published var savedWords: [SavedWordModel] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    var onShowAccountProtection: (() -> Void)?
    
    private var listenerRegistration: ListenerRegistration?
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var hasShownProtection = false
    
    // MARK: - Computed Properties
    var learningWords: [SavedWordModel] {
        savedWords.filter { !$0.isLearned }
    }
    
    var learnedWords: [SavedWordModel] {
        savedWords.filter { $0.isLearned }
    }
    
    var learningCount: Int {
        learningWords.count
    }
    
    var learnedCount: Int {
        learnedWords.count
    }
    
    var totalWords: Int {
        savedWords.count
    }
    
    // MARK: - SRS Properties
    var wordsDueForReview: [SavedWordModel] {
        let now = Date()
        return savedWords.filter {
            guard let nextDate = $0.nextReviewDate else { return true }
            return nextDate <= now && !$0.isLearned
        }
    }
    
    var newWords: [SavedWordModel] {
        savedWords.filter { $0.srsRepetition == 0 && $0.reviewCount == 0 }
    }
    
    init() {
        setupNotificationObserver()
        setupAuthStateListener()
    }
    
    // MARK: - Auth State Listener
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user = user {
                    // Користувач залогінений
                    if !user.isAnonymous {
                        // Якщо це не анонімний користувач - синхронізуємо
                        Task {
                            await self?.syncLocalWordsWithFirestore(userId: user.uid)
                        }
                    }
                    self?.fetchSavedWords()
                } else {
                    // Користувач вилогінений - очищаємо
                    self?.savedWords = []
                    self?.listenerRegistration?.remove()
                }
            }
        }
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWordSaved),
            name: .wordSaved,
            object: nil
        )
        
        // НОВЕ: Підписка на імпорт слів
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWordsImported),
            name: .wordsImported,
            object: nil
        )
    }
    
    @objc private func handleWordSaved() {
        fetchSavedWords()
    }
    
    // НОВИЙ МЕТОД: Обробка імпорту слів
    @objc private func handleWordsImported() {
        print("📥 DictionaryViewModel: Отримано сповіщення про імпорт слів")
        fetchSavedWords()
    }
    
    /// Синхронізує локальні слова з Firestore при логіні
    private func syncLocalWordsWithFirestore(userId: String) async {
        let unsyncedWords = LocalStorageService.shared.getUnsyncedWords()
        
        guard !unsyncedWords.isEmpty else {
            // Якщо немає несинхронізованих слів - просто завантажуємо з Firestore
            await loadWordsFromFirestore(userId: userId)
            return
        }
        
        // Завантажуємо несинхронізовані слова в Firestore
        var uploadedIds: [String] = []
        for word in unsyncedWords {
            var wordToUpload = word
            wordToUpload.userId = userId
            
            do {
                try await FirestoreService.shared.saveWord(wordToUpload)
                if let id = wordToUpload.id {
                    uploadedIds.append(id)
                }
                print("✅ Завантажено слово в Firestore: \(wordToUpload.original)")
            } catch {
                print("❌ Помилка завантаження слова \(wordToUpload.original): \(error)")
            }
        }
        
        // Позначаємо як синхронізовані
        if !uploadedIds.isEmpty {
            LocalStorageService.shared.markWordsAsSynced(ids: uploadedIds)
        }
        
        // Тепер завантажуємо всі слова з Firestore (включаючи щойно завантажені)
        await loadWordsFromFirestore(userId: userId)
    }
    
    /// Завантажує слова з Firestore та оновлюєє локальне сховище
    private func loadWordsFromFirestore(userId: String) async {
        do {
            let firestoreWords = try await FirestoreService.shared.fetchWords()
            
            // Оновлюємо локальне сховище злиттям даних
            LocalStorageService.shared.mergeWithFirestoreWords(firestoreWords, userId: userId)
            
            // Оновлюємо UI
            await MainActor.run {
                self.savedWords = LocalStorageService.shared.fetchLocalWords()
            }
        } catch {
            print("❌ Помилка завантаження з Firestore: \(error)")
        }
    }
    
    func fetchSavedWords() {
        print("📱 fetchSavedWords викликано")
        
        // Завжди спочатку завантажуємо локальні слова (для миттєвого відображення)
        let localWords = LocalStorageService.shared.fetchLocalWords()
        self.savedWords = localWords
        print("📱 Завантажено \(localWords.count) локальних слів")
        
        // Якщо анонімний - більше нічого не робимо
        if Auth.auth().currentUser?.isAnonymous == true {
            print("📱 Анонімний користувач: завантажено \(localWords.count) слів")
            isLoading = false
            return
        }
        
        // Якщо залогінений - налаштовуємо реальтайм слухач
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Користувач не авторизований"
            return
        }
        
        isLoading = true
        listenerRegistration?.remove()
        
        listenerRegistration = FirestoreService.shared.addWordsListener { [weak self] words in
            DispatchQueue.main.async {
                // Оновлюємо локальне сховище
                LocalStorageService.shared.mergeWithFirestoreWords(words, userId: userId)
                // Оновлюємо UI з локального сховища (щоб мати всі слова включно з несинхронізованими)
                self?.savedWords = LocalStorageService.shared.fetchLocalWords()
                self?.isLoading = false
            }
        }
    }
    
    // MARK: - Save Word
    func saveWord(_ word: SavedWordModel) {
        // Генеруємо id якщо його нема
        var wordToSave = word
        if wordToSave.id == nil || wordToSave.id?.isEmpty == true {
            wordToSave.id = UUID().uuidString
        }
        
        print("💾 Збереження слова: \(wordToSave.original), id: \(wordToSave.id ?? "nil")")
        
        // Зберігаємо локально одразу (для всіх користувачів)
        LocalStorageService.shared.saveWordLocally(wordToSave)
        
        // Оновлюємо UI
        DispatchQueue.main.async {
            // Перевіряємо чи слово вже є в списку
            if let index = self.savedWords.firstIndex(where: { $0.id == wordToSave.id }) {
                self.savedWords[index] = wordToSave
            } else {
                self.savedWords.append(wordToSave)
            }
            print("✅ Слово додано до savedWords, тепер їх \(self.savedWords.count)")
            NotificationCenter.default.post(name: .wordSaved, object: nil)
        }
        
        // Якщо користувач залогінений - синхронізуємо з Firestore
        if let userId = Auth.auth().currentUser?.uid, Auth.auth().currentUser?.isAnonymous == false {
            Task {
                do {
                    var wordForFirestore = wordToSave
                    wordForFirestore.userId = userId
                    try await FirestoreService.shared.saveWord(wordForFirestore)
                    // Позначаємо як синхронізоване після успішного збереження
                    LocalStorageService.shared.markWordsAsSynced(ids: [wordToSave.id!])
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
        Task {
            await MainActor.run {
                let items = savedWords.map { word in
                    WidgetDataService.WidgetWordItem(
                        id: word.id,
                        original: word.original,
                        translation: word.translation,
                        transcription: word.transcription,
                        exampleSentence: word.exampleSentence,
                        languagePair: word.languagePair
                    )
                }
                WidgetDataService.shared.updateWidgetWords(words: items)
            }
        }
    }
    
    // НОВИЙ МЕТОД: Масове збереження слів (для імпорту)
    func saveWords(_ words: [SavedWordModel]) {
        print("💾 Масове збереження \(words.count) слів")
        
        for var word in words {
            // Генеруємо id якщо потрібно
            if word.id == nil || word.id?.isEmpty == true {
                word.id = UUID().uuidString
            }
            
            // Зберігаємо локально
            LocalStorageService.shared.saveWordLocally(word)
            
            // Додаємо в масив якщо немає
            if !savedWords.contains(where: { $0.id == word.id }) {
                savedWords.append(word)
            }
        }
        
        print("✅ Масово додано \(words.count) слів, тепер їх \(savedWords.count)")
        NotificationCenter.default.post(name: .wordSaved, object: nil)
        
        // Синхронізація з Firestore для залогінених користувачів
        if let userId = Auth.auth().currentUser?.uid, Auth.auth().currentUser?.isAnonymous == false {
            Task {
                for var word in words {
                    do {
                        word.userId = userId
                        try await FirestoreService.shared.saveWord(word)
                        LocalStorageService.shared.markWordsAsSynced(ids: [word.id!])
                    } catch {
                        print("❌ Помилка синхронізації слова \(word.original): \(error)")
                    }
                }
            }
        }
        Task {
            await MainActor.run {
                let items = savedWords.map { word in
                    WidgetDataService.WidgetWordItem(
                        id: word.id,
                        original: word.original,
                        translation: word.translation,
                        transcription: word.transcription,
                        exampleSentence: word.exampleSentence,
                        languagePair: word.languagePair
                    )
                }
                WidgetDataService.shared.updateWidgetWords(words: items)
            }
        }
    }
    
    // MARK: - Update Word (НОВИЙ МЕТОД)
    func updateWord(_ word: SavedWordModel) {
        // Оновлюємо локально
        LocalStorageService.shared.updateWordLocally(word)
        
        // Оновлюємо UI
        if let index = savedWords.firstIndex(where: { $0.id == word.id }) {
            savedWords[index] = word
        }
        
        NotificationCenter.default.post(name: .wordSaved, object: nil)
        
        // Якщо залогінений - оновлюємо в Firestore
        if Auth.auth().currentUser?.isAnonymous == false {
            Task {
                do {
                    try await FirestoreService.shared.updateWord(word)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Delete Word
    func deleteWord(_ wordId: String) {
        // Видаляємо локально
        LocalStorageService.shared.deleteLocalWord(id: wordId)
        savedWords.removeAll { $0.id == wordId }
        NotificationCenter.default.post(name: .wordSaved, object: nil)
        
        // Якщо залогінений - видаляємо з Firestore
        if Auth.auth().currentUser?.isAnonymous == false {
            Task {
                do {
                    try await FirestoreService.shared.deleteWord(wordId: wordId)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
        Task {
            await MainActor.run {
                let items = savedWords.map { word in
                    WidgetDataService.WidgetWordItem(
                        id: word.id,
                        original: word.original,
                        translation: word.translation,
                        transcription: word.transcription,
                        exampleSentence: word.exampleSentence,
                        languagePair: word.languagePair
                    )
                }
                WidgetDataService.shared.updateWidgetWords(words: items)
            }
        }
    }
    
    // MARK: - Word Status Updates
    func markAsLearned(wordId: String) {
        updateWordStatus(wordId: wordId, isLearned: true)
    }
    
    func markAsUnlearned(wordId: String) {
        updateWordStatus(wordId: wordId, isLearned: false)
    }
    
    private func updateWordStatus(wordId: String, isLearned: Bool) {
        // Оновлюємо локально
        if let index = savedWords.firstIndex(where: { $0.id == wordId }) {
            savedWords[index].isLearned = isLearned
            LocalStorageService.shared.updateWordLocally(savedWords[index])
            NotificationCenter.default.post(name: .wordSaved, object: nil)
        }
        
        // Якщо залогінений - оновлюємо в Firestore
        if Auth.auth().currentUser?.isAnonymous == false {
            Task {
                do {
                    try await FirestoreService.shared.updateWordStatus(wordId: wordId, isLearned: isLearned)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - SRS Methods
    func processReview(for word: SavedWordModel, quality: Int) {
        var updatedWord = word
        
        let q = Double(quality)
        updatedWord.reviewCount += 1
        let oldAvg = updatedWord.averageQuality
        let newCount = Double(updatedWord.reviewCount)
        updatedWord.averageQuality = ((oldAvg * (newCount - 1)) + q) / newCount
        updatedWord.lastReviewDate = Date()
        
        if quality >= 3 {
            updatedWord.srsRepetition += 1
            
            if updatedWord.srsRepetition == 1 {
                updatedWord.srsInterval = 1
            } else if updatedWord.srsRepetition == 2 {
                updatedWord.srsInterval = 6
            } else {
                updatedWord.srsInterval *= updatedWord.srsEasinessFactor
            }
            
            let newEF = updatedWord.srsEasinessFactor - 0.8 + (0.28 * q) - (0.02 * q * q)
            updatedWord.srsEasinessFactor = max(1.3, newEF)
            
            if updatedWord.srsRepetition >= 3 {
                updatedWord.isLearned = true
            }
        } else {
            updatedWord.srsRepetition = 0
            updatedWord.srsInterval = 1
            updatedWord.isLearned = false
        }
        
        let daysToAdd = updatedWord.srsInterval
        updatedWord.nextReviewDate = Calendar.current.date(
            byAdding: .day,
            value: Int(daysToAdd),
            to: Date()
        ) ?? Date().addingTimeInterval(86400)
        
        // Оновлюємо в масиві та локальному сховищі
        if let index = savedWords.firstIndex(where: { $0.id == word.id }) {
            savedWords[index] = updatedWord
            LocalStorageService.shared.updateWordLocally(updatedWord)
        }
        
        // Якщо залогінений - оновлюємо в Firestore
        if Auth.auth().currentUser?.isAnonymous == false {
            Task {
                do {
                    try await FirestoreService.shared.updateWord(updatedWord)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func resetSRS(for word: SavedWordModel) {
        var updatedWord = word
        updatedWord.srsInterval = 0
        updatedWord.srsRepetition = 0
        updatedWord.srsEasinessFactor = 2.5
        updatedWord.nextReviewDate = Date()
        updatedWord.lastReviewDate = nil
        updatedWord.reviewCount = 0
        updatedWord.averageQuality = 0.0
        updatedWord.isLearned = false
        
        // Оновлюємо локально
        if let index = savedWords.firstIndex(where: { $0.id == word.id }) {
            savedWords[index] = updatedWord
            LocalStorageService.shared.updateWordLocally(updatedWord)
        }
        
        // Якщо залогінений - оновлюємо в Firestore
        if Auth.auth().currentUser?.isAnonymous == false {
            Task {
                do {
                    try await FirestoreService.shared.updateWord(updatedWord)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func stopListening() {
        listenerRegistration?.remove()
    }
    
    deinit {
        listenerRegistration?.remove()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let wordsImported = Notification.Name("wordsImported") // НОВЕ
}
