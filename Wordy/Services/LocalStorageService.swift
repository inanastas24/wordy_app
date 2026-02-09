//1
//  LocalStorageService.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 07.02.2026.
//

import Foundation
import FirebaseFirestore

class LocalStorageService {
    static let shared = LocalStorageService()
    
    private let wordsKey = "local_saved_words"
    private let needsMigrationKey = "needs_words_migration"
    
    // Публічний ініціалізатор
    init() {}
    
    // MARK: - Local Words Storage
    
    /// Конвертує Firestore модель в локальну структуру для зберігання
    private func convertToLocalModel(_ word: SavedWordModel) -> LocalSavedWord {
        return LocalSavedWord(
            id: word.id ?? UUID().uuidString,
            original: word.original,
            translation: word.translation,
            transcription: word.transcription,
            exampleSentence: word.exampleSentence,
            languagePair: word.languagePair,
            isLearned: word.isLearned,
            reviewCount: word.reviewCount,
            srsInterval: word.srsInterval,
            srsRepetition: word.srsRepetition,
            srsEasinessFactor: word.srsEasinessFactor,
            nextReviewDate: word.nextReviewDate,
            lastReviewDate: word.lastReviewDate,
            averageQuality: word.averageQuality,
            createdAt: word.createdAt,
            userId: word.userId,
            isSynced: word.id != nil && word.userId != nil
        )
    }
    
    /// Конвертує локальну структуру назад в Firestore модель
    private func convertToFirestoreModel(_ local: LocalSavedWord) -> SavedWordModel {
        return SavedWordModel(
            id: local.id,
            original: local.original,
            translation: local.translation,
            transcription: local.transcription,
            exampleSentence: local.exampleSentence,
            languagePair: local.languagePair,
            isLearned: local.isLearned,
            reviewCount: local.reviewCount,
            srsInterval: local.srsInterval,
            srsRepetition: local.srsRepetition,
            srsEasinessFactor: local.srsEasinessFactor,
            nextReviewDate: local.nextReviewDate,
            lastReviewDate: local.lastReviewDate,
            averageQuality: local.averageQuality,
            createdAt: local.createdAt,
            userId: local.userId
        )
    }
    
    func saveWordLocally(_ word: SavedWordModel) {
        var localWords = fetchLocalWordsRaw()
        let localWord = convertToLocalModel(word)
        
        // Перевіряємо чи слово вже існує
        if let existingIndex = localWords.firstIndex(where: { $0.id == localWord.id }) {
            localWords[existingIndex] = localWord
            print("📝 Оновлено існуюче слово: \(localWord.original)")
        } else {
            localWords.append(localWord)
            print("➕ Додано нове слово: \(localWord.original), id: \(localWord.id)")
        }
        
        saveLocalWordsRaw(localWords)
        print("💾 Всього слів в UserDefaults: \(localWords.count)")
    }
    
    func fetchLocalWords() -> [SavedWordModel] {
        let localWords = fetchLocalWordsRaw()
        return localWords.map { convertToFirestoreModel($0) }
    }
    
    private func fetchLocalWordsRaw() -> [LocalSavedWord] {
        guard let data = UserDefaults.standard.data(forKey: wordsKey) else {
            print("❌ Немає даних в UserDefaults для ключа: \(wordsKey)")
            return []
        }
        
        do {
            let words = try JSONDecoder().decode([LocalSavedWord].self, from: data)
            print("📖 Зчитано \(words.count) слів з UserDefaults")
            return words
        } catch {
            print("❌ Помилка декодування: \(error)")
            return []
        }
    }
    
    private func saveLocalWordsRaw(_ words: [LocalSavedWord]) {
        do {
            let data = try JSONEncoder().encode(words)
            UserDefaults.standard.set(data, forKey: wordsKey)
            print("💾 Збережено \(words.count) слів в UserDefaults")
        } catch {
            print("❌ Помилка кодування: \(error)")
        }
    }
    
    func deleteLocalWord(id: String) {
        var words = fetchLocalWordsRaw()
        words.removeAll { $0.id == id }
        saveLocalWordsRaw(words)
    }
    
    func clearLocalWords() {
        UserDefaults.standard.removeObject(forKey: wordsKey)
    }
    
    // MARK: - Migration Flag
    
    func setNeedsMigration(_ needs: Bool) {
        UserDefaults.standard.set(needs, forKey: needsMigrationKey)
    }
    
    func needsMigration() -> Bool {
        return UserDefaults.standard.bool(forKey: needsMigrationKey)
    }
    
    func clearMigrationFlag() {
        UserDefaults.standard.removeObject(forKey: needsMigrationKey)
    }
    
    func updateWordLocally(_ word: SavedWordModel) {
        var words = fetchLocalWordsRaw()
        let localWord = convertToLocalModel(word)
        if let index = words.firstIndex(where: { $0.id == localWord.id }) {
            words[index] = localWord
            saveLocalWordsRaw(words)
        }
    }
    
    // MARK: - Migration Logic
    
    /// Отримує всі несинхронізовані слова (додані офлайн до логіну)
    func getUnsyncedWords() -> [SavedWordModel] {
        let localWords = fetchLocalWordsRaw()
        return localWords
            .filter { !$0.isSynced }
            .map { convertToFirestoreModel($0) }
    }
    
    /// Позначає слова як синхронізовані після завантаження в Firestore
    func markWordsAsSynced(ids: [String]) {
        var words = fetchLocalWordsRaw()
        for id in ids {
            if let index = words.firstIndex(where: { $0.id == id }) {
                words[index].isSynced = true
            }
        }
        saveLocalWordsRaw(words)
    }
    
    /// Оновлює локальні слова даними з Firestore (при логіні)
    func mergeWithFirestoreWords(_ firestoreWords: [SavedWordModel], userId: String) {
        var localWords = fetchLocalWordsRaw()
        var updatedLocalWords: [LocalSavedWord] = []
        
        // Додаємо слова з Firestore (вони пріоритетні)
        for firestoreWord in firestoreWords {
            var local = convertToLocalModel(firestoreWord)
            local.isSynced = true
            local.userId = userId
            updatedLocalWords.append(local)
        }
        
        // Додаємо несинхронізовані локальні слова (яких немає в Firestore)
        let unsyncedLocal = localWords.filter { !$0.isSynced }
        for unsynced in unsyncedLocal {
            // Перевіряємо чи такого слова ще немає в списку (по original)
            if !updatedLocalWords.contains(where: { $0.original.lowercased() == unsynced.original.lowercased() }) {
                var newUnsynced = unsynced
                newUnsynced.userId = userId
                updatedLocalWords.append(newUnsynced)
            }
        }
        
        saveLocalWordsRaw(updatedLocalWords)
        print("🔄 Міграція завершена: \(updatedLocalWords.count) слів (з Firestore: \(firestoreWords.count), локальних несинхронізованих: \(unsyncedLocal.count))")
    }
}

// MARK: - Local Model

/// Локальна структура для зберігання в UserDefaults (без @DocumentID)
struct LocalSavedWord: Codable {
    var id: String
    var original: String
    var translation: String
    var transcription: String?
    var exampleSentence: String?
    var languagePair: String
    var isLearned: Bool
    var reviewCount: Int
    var srsInterval: Double
    var srsRepetition: Int
    var srsEasinessFactor: Double
    var nextReviewDate: Date?
    var lastReviewDate: Date?
    var averageQuality: Double
    var createdAt: Date
    var userId: String?
    var isSynced: Bool
    
    init(
        id: String,
        original: String,
        translation: String,
        transcription: String? = nil,
        exampleSentence: String? = nil,
        languagePair: String = "",
        isLearned: Bool = false,
        reviewCount: Int = 0,
        srsInterval: Double = 0,
        srsRepetition: Int = 0,
        srsEasinessFactor: Double = 2.5,
        nextReviewDate: Date? = nil,
        lastReviewDate: Date? = nil,
        averageQuality: Double = 0,
        createdAt: Date = Date(),
        userId: String? = nil,
        isSynced: Bool = false
    ) {
        self.id = id
        self.original = original
        self.translation = translation
        self.transcription = transcription
        self.exampleSentence = exampleSentence
        self.languagePair = languagePair
        self.isLearned = isLearned
        self.reviewCount = reviewCount
        self.srsInterval = srsInterval
        self.srsRepetition = srsRepetition
        self.srsEasinessFactor = srsEasinessFactor
        self.nextReviewDate = nextReviewDate
        self.lastReviewDate = lastReviewDate
        self.averageQuality = averageQuality
        self.createdAt = createdAt
        self.userId = userId
        self.isSynced = isSynced
    }
}
