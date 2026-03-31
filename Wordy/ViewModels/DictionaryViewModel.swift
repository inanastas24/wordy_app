//
//  DictionaryViewModel.swift
//  Wordy
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

final class DictionaryViewModel: ObservableObject {
    static let shared = DictionaryViewModel()

    @Published private(set) var savedWords: [SavedWordModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let storageKey = "saved_words_storage_v2"
    private var listener: ListenerRegistration?

    private init() {
        fetchSavedWords()
    }

    // MARK: - Derived Data

    var learningWords: [SavedWordModel] {
        savedWords
            .filter { !$0.isLearned }
            .sorted { lhs, rhs in
                if lhs.isDueForReview != rhs.isDueForReview {
                    return lhs.isDueForReview && !rhs.isDueForReview
                }
                return lhs.original.lowercased() < rhs.original.lowercased()
            }
    }

    var learnedWords: [SavedWordModel] {
        savedWords
            .filter { $0.isLearned }
            .sorted { $0.original.lowercased() < $1.original.lowercased() }
    }

    var learningCount: Int { learningWords.count }
    var learnedCount: Int { learnedWords.count }

    // MARK: - Public API

    func fetchSavedWords() {
        isLoading = true
        print("📚 Fetching words...")

        Task {
            do {
                let remoteWords = try await FirestoreService.shared.fetchWords()
                print("📚 Firestore returned: \(remoteWords.count) words")
                print("📚 Words: \(remoteWords.map { $0.original })")
                
                let uniqueWords = deduplicate(remoteWords)
                print("📚 After deduplication: \(uniqueWords.count) words")
                print("📚 Words: \(uniqueWords.map { $0.original })")

                await MainActor.run {
                    self.savedWords = uniqueWords
                    print("💾 savedWords updated: \(self.savedWords.count) words")
                    self.writeWordsToStorage(uniqueWords)
                    self.syncWidgetWords()
                    self.isLoading = false
                }
            } catch {
                print("❌ Failed to fetch: \(error)")
                let localWords = readWordsFromStorage()
                await MainActor.run {
                    let uniqueLocalWords = deduplicate(localWords)
                    self.savedWords = uniqueLocalWords
                    print("💾 Loaded from local: \(self.savedWords.count) words")
                    self.syncWidgetWords()
                    self.isLoading = false
                }
            }
        }
    }

    func saveWord(_ word: SavedWordModel) {
        var updatedWords = savedWords

        let normalized = normalizedWord(word)

        if let index = indexForExistingWord(normalized, in: updatedWords) {
            let preserved = mergeWord(new: normalized, existing: updatedWords[index])
            updatedWords[index] = preserved
        } else {
            updatedWords.append(normalized)
        }

        applyAndPersist(updatedWords)

        Task {
                do {
                    if let finalWord = updatedWords.first(where: {
                        stableKey(for: $0) == stableKey(for: normalized)
                    }) {
                        try await FirestoreService.shared.saveWord(finalWord)
                        print("✅ Saved to Firestore")
                    }
                } catch {
                    print("❌ Firestore save error: \(error)")
                }
            }
        }

    func saveWords(_ words: [SavedWordModel]) {
        guard !words.isEmpty else { return }

        var updatedWords = savedWords

        for word in words {
            let normalized = normalizedWord(word)
            if let index = indexForExistingWord(normalized, in: updatedWords) {
                updatedWords[index] = mergeWord(new: normalized, existing: updatedWords[index])
            } else {
                updatedWords.append(normalized)
            }
        }

        applyAndPersist(updatedWords)

        Task {
            do {
                try await FirestoreService.shared.saveWordsBatch(updatedWords)
            } catch {
                print("❌ Failed to batch save words to Firestore: \(error)")
            }
        }
    }

    func deleteWord(_ word: SavedWordModel) {
        let updatedWords = savedWords.filter { current in
            stableKey(for: current) != stableKey(for: word)
        }

        applyAndPersist(updatedWords)

        if let id = word.id {
            Task {
                do {
                    try await FirestoreService.shared.deleteWord(wordId: id)
                } catch {
                    print("❌ Failed to delete word from Firestore: \(error)")
                }
            }
        }
    }

    func markAsLearned(_ word: SavedWordModel) {
        updateWordStatus(word: word, isLearned: true)
    }

    func markAsLearning(_ word: SavedWordModel) {
        updateWordStatus(word: word, isLearned: false)
    }

    func markAsLearned(wordId: String) {
        guard let word = savedWords.first(where: { $0.id == wordId }) else { return }
        markAsLearned(word)
    }

    func markAsUnlearned(wordId: String) {
        guard let word = savedWords.first(where: { $0.id == wordId }) else { return }
        markAsLearning(word)
    }

    func updateWordStatus(wordId: String, isLearned: Bool) {
        guard let word = savedWords.first(where: { $0.id == wordId }) else { return }
        updateWordStatus(word: word, isLearned: isLearned)
    }
    
    func processReview(for word: SavedWordModel, quality: Int, on date: Date = Date()) {
        guard let index = indexForExistingWord(word, in: savedWords) else { return }
        var updated = savedWords[index]

        // Update statistics
        updated.reviewCount += 1
        let totalQuality = (updated.averageQuality * Double(updated.reviewCount - 1)) + Double(quality)
        updated.averageQuality = totalQuality / Double(updated.reviewCount)
        updated.lastReviewDate = date

        if quality >= 3 {
            updated.srsRepetition += 1
            if updated.srsRepetition == 1 {
                updated.srsInterval = 1
            } else if updated.srsRepetition == 2 {
                updated.srsInterval = 6
            } else {
                updated.srsInterval = updated.srsInterval * updated.srsEasinessFactor
            }
            let q = Double(quality)
            let newEF = updated.srsEasinessFactor - 0.8 + (0.28 * q) - (0.02 * q * q)
            updated.srsEasinessFactor = max(1.3, newEF)
            if updated.srsRepetition >= 3 {
                updated.isLearned = true
            }
        } else {
            updated.srsRepetition = 0
            updated.srsInterval = 1
            updated.isLearned = false
        }

        if let nextReview = Calendar.current.date(byAdding: .day, value: Int(updated.srsInterval), to: date) {
            updated.nextReviewDate = nextReview
        } else {
            updated.nextReviewDate = date.addingTimeInterval(86400)
        }

        var updatedWords = savedWords
        updatedWords[index] = updated
        applyAndPersist(updatedWords)
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }
    

    // MARK: - Status Update

    private func updateWordStatus(word: SavedWordModel, isLearned: Bool) {
        guard let index = indexForExistingWord(word, in: savedWords) else { return }

        var updatedWord = savedWords[index]
        updatedWord.isLearned = isLearned
        if isLearned {
            updatedWord.nextReviewDate = nil
        }

        var updatedWords = savedWords
        updatedWords[index] = updatedWord

        // 🔥 Просто оновлюємо масив - @Published сам сповістить SwiftUI
        savedWords = deduplicate(updatedWords)
        writeWordsToStorage(savedWords)
        syncWidgetWords()
        
        // Синхронізуємо з Firestore асинхронно
        Task {
            do {
                try await FirestoreService.shared.saveWord(updatedWord)
                print("✅ Status updated: \(updatedWord.original) -> isLearned: \(isLearned)")
            } catch {
                print("❌ Failed to update status: \(error)")
            }
        }
    }
    // MARK: - Apply / Persist

    // Погано:
    func applyAndPersist(_ words: [SavedWordModel]) {
        savedWords = words  // @Published сповіщає
        objectWillChange.send()  // 🔥 Зайве! Може викликати подвійне оновлення
    }

    // MARK: - Deduplication

    private func deduplicate(_ words: [SavedWordModel]) -> [SavedWordModel] {
        var unique: [SavedWordModel] = []
        var seen = Set<String>()

        for word in words {
            let normalized = normalizedWord(word)
            let key = stableKey(for: normalized)

            guard !seen.contains(key) else { continue }
            seen.insert(key)
            unique.append(normalized)
        }

        return unique
    }

    private func indexForExistingWord(_ word: SavedWordModel, in words: [SavedWordModel]) -> Int? {
        let key = stableKey(for: word)
        return words.firstIndex(where: { stableKey(for: $0) == key })
    }

    private func stableKey(for word: SavedWordModel) -> String {
        if let id = word.id, !id.isEmpty {
            return "id:\(id)"
        }

        return [
            word.original.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            word.translation.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            word.languagePair.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        ].joined(separator: "|")
    }

    private func normalizedWord(_ word: SavedWordModel) -> SavedWordModel {
        var normalized = word

        if normalized.id == nil || normalized.id?.isEmpty == true {
            normalized.id = UUID().uuidString
        }

        normalized.original = normalized.original.trimmingCharacters(in: .whitespacesAndNewlines)
        normalized.translation = normalized.translation.trimmingCharacters(in: .whitespacesAndNewlines)
        normalized.languagePair = normalized.languagePair.trimmingCharacters(in: .whitespacesAndNewlines)

        return normalized
    }

    private func mergeWord(new: SavedWordModel, existing: SavedWordModel) -> SavedWordModel {
        var result = normalizedWord(new)

        // Зберігаємо стабільний id
        result.id = existing.id ?? result.id

        // Не перетираємо корисні поля пустими значеннями
        if result.transcription?.isEmpty ?? true {
            result.transcription = existing.transcription
        }

        if result.exampleSentence?.isEmpty ?? true {
            result.exampleSentence = existing.exampleSentence
        }

        if result.languagePair.isEmpty {
            result.languagePair = existing.languagePair
        }

        // Якщо новий запис не несе явної зміни статусу, тримаємо існуючий
        if new.isLearned != existing.isLearned {
            result.isLearned = new.isLearned
        }

        // Беремо більш “повну” статистику
        result.reviewCount = max(existing.reviewCount, new.reviewCount)

        if result.nextReviewDate == nil {
            result.nextReviewDate = existing.nextReviewDate
        }

        return result
    }

    // MARK: - Local Storage

    private func readWordsFromStorage() -> [SavedWordModel] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([SavedWordModel].self, from: data)
        } catch {
            print("❌ Failed to decode saved words: \(error)")
            return []
        }
    }

    private func writeWordsToStorage(_ words: [SavedWordModel]) {
        do {
            let data = try JSONEncoder().encode(words)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("❌ Failed to encode saved words: \(error)")
        }
    }
    
    private func syncWidgetWords() {
        print("📱 syncWidgetWords() called with \(savedWords.count) words")
        print("📱 Words: \(savedWords.map { $0.original })")
        
        let widgetWords = savedWords.map {
            WidgetDataService.WidgetWord(
                id: $0.id ?? UUID().uuidString,
                original: $0.original,
                translation: $0.translation,
                transcription: $0.transcription,
                example: $0.exampleSentence,
                languagePair: $0.languagePair
            )
        }
        
        print("📱 Sending \(widgetWords.count) words to WidgetDataService")
        WidgetDataService.shared.updateWidgetWords(words: widgetWords)
    }
    
    // MARK: - Firestore Listener (optional safe merge)

    private func startListeningIfNeeded() {
        stopListening()

        listener = FirestoreService.shared.addWordsListener { [weak self] remoteWords in
            guard let self = self else { return }

            let unique = self.deduplicate(remoteWords)

            DispatchQueue.main.async {
                self.savedWords = unique
                self.writeWordsToStorage(unique)
                self.syncWidgetWords()
            }
        }
    }
}
