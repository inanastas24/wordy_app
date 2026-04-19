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
    @Published private(set) var dictionaries: [WordDictionaryModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let storageKey = "saved_words_storage_v3"
    private let dictionariesStorageKey = "saved_dictionaries_storage_v1"
    private var listener: ListenerRegistration?

    private init() {
        fetchSavedWords()
    }

    // MARK: - Derived Data

    var learningWords: [SavedWordModel] {
        learningWords(in: nil)
    }

    var learnedWords: [SavedWordModel] {
        learnedWords(in: nil)
    }

    var learningCount: Int { learningWords.count }
    var learnedCount: Int { learnedWords.count }

    func words(in dictionaryId: String?) -> [SavedWordModel] {
        let normalizedDictionaryId = resolvedDictionaryId(for: dictionaryId)
        return savedWords
            .filter { resolvedDictionaryId(for: $0.dictionaryId) == normalizedDictionaryId }
            .sorted { lhs, rhs in
                if lhs.isLearned != rhs.isLearned {
                    return !lhs.isLearned && rhs.isLearned
                }
                return lhs.original.lowercased() < rhs.original.lowercased()
            }
    }

    func learningWords(in dictionaryId: String?) -> [SavedWordModel] {
        words(in: dictionaryId)
            .filter { !$0.isLearned }
            .sorted { lhs, rhs in
                if lhs.isDueForReview != rhs.isDueForReview {
                    return lhs.isDueForReview && !rhs.isDueForReview
                }
                return lhs.original.lowercased() < rhs.original.lowercased()
            }
    }

    func learnedWords(in dictionaryId: String?) -> [SavedWordModel] {
        words(in: dictionaryId)
            .filter { $0.isLearned }
            .sorted { $0.original.lowercased() < $1.original.lowercased() }
    }

    func wordCount(in dictionaryId: String?) -> Int {
        words(in: dictionaryId).count
    }

    func dictionary(for id: String?) -> WordDictionaryModel? {
        let resolvedId = resolvedDictionaryId(for: id)
        return dictionaries.first(where: { ($0.id ?? "") == resolvedId })
    }

    func defaultDictionary() -> WordDictionaryModel {
        ensureDefaultDictionaryExists()
    }

    func defaultDictionaryId() -> String {
        ensureDefaultDictionaryExists().id ?? ""
    }

    func resolvedSelectionDictionaryId(for dictionary: WordDictionaryModel) -> String {
        if let dictionaryId = dictionary.id?.trimmingCharacters(in: .whitespacesAndNewlines),
           !dictionaryId.isEmpty {
            print("📚 DICTIONARY SELECT resolved existing id='\(dictionaryId)' name='\(dictionary.name)'")
            return dictionaryId
        }

        if let existing = dictionaries.first(where: {
            $0.name == dictionary.name &&
            (($0.id?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) == false)
        }), let existingId = existing.id {
            print("📚 DICTIONARY SELECT recovered id='\(existingId)' by name='\(dictionary.name)'")
            return existingId
        }

        let normalized = normalizedDictionary(dictionary)
        var updatedDictionaries = dictionaries

        if let index = updatedDictionaries.firstIndex(where: { $0.name == dictionary.name }) {
            updatedDictionaries[index] = normalized
        } else {
            updatedDictionaries.append(normalized)
        }

        applyAndPersist(words: savedWords, dictionaries: updatedDictionaries)

        Task {
            do {
                try await FirestoreService.shared.saveDictionary(normalized)
            } catch {
                print("❌ Failed to normalize dictionary id: \(error)")
            }
        }

        print("📚 DICTIONARY SELECT generated new id='\(normalized.id ?? "")' for name='\(dictionary.name)'")
        return normalized.id ?? defaultDictionaryId()
    }

    func createDictionary(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let dictionary = normalizedDictionary(WordDictionaryModel(
            id: UUID().uuidString,
            name: trimmed,
            createdAt: Date(),
            userId: Auth.auth().currentUser?.uid
        ))

        var updatedDictionaries = dictionaries
        updatedDictionaries.append(dictionary)
        updatedDictionaries.sort { $0.createdAt < $1.createdAt }
        applyAndPersist(words: savedWords, dictionaries: updatedDictionaries)

        Task {
            do {
                try await FirestoreService.shared.saveDictionary(dictionary)
            } catch {
                print("❌ Failed to save dictionary: \(error)")
            }
        }
    }

    func renameDictionary(_ dictionary: WordDictionaryModel, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let dictionaryId = dictionary.id else { return }

        guard let index = dictionaries.firstIndex(where: { $0.id == dictionaryId }) else { return }

        var updatedDictionary = dictionaries[index]
        updatedDictionary.name = trimmed

        var updatedDictionaries = dictionaries
        updatedDictionaries[index] = updatedDictionary
        updatedDictionaries.sort { $0.createdAt < $1.createdAt }

        applyAndPersist(words: savedWords, dictionaries: updatedDictionaries)

        Task {
            do {
                try await FirestoreService.shared.saveDictionary(updatedDictionary)
            } catch {
                print("❌ Failed to rename dictionary: \(error)")
            }
        }
    }

    func deleteDictionary(_ dictionary: WordDictionaryModel) {
        guard let dictionaryId = dictionary.id else { return }

        let updatedWords = savedWords.filter {
            resolvedDictionaryId(for: $0.dictionaryId) != dictionaryId
        }
        let updatedDictionaries = dictionaries.filter { $0.id != dictionaryId }

        applyAndPersist(words: updatedWords, dictionaries: updatedDictionaries)

        Task {
            do {
                try await FirestoreService.shared.deleteDictionary(dictionaryId: dictionaryId)
            } catch {
                print("❌ Failed to delete dictionary: \(error)")
            }
        }
    }

    func importPackages(_ packages: [DictionaryTransferPackage]) async -> DictionaryImportSummary {
        guard !packages.isEmpty else {
            return DictionaryImportSummary(
                importedWordCount: 0,
                duplicateCount: 0,
                importedDictionaryCount: 0,
                format: .json
            )
        }

        var updatedWords = savedWords
        var updatedDictionaries = dictionaries
        var wordsToPersist: [SavedWordModel] = []
        var dictionariesToPersist: [WordDictionaryModel] = []
        var importedWordCount = 0
        var duplicateCount = 0
        var createdDictionaryIds = Set<String>()
        var affectedDictionaryIds = Set<String>()

        for package in packages {
            let trimmedName = package.dictionaryName.trimmingCharacters(in: .whitespacesAndNewlines)
            let dictionaryName = trimmedName.isEmpty ? defaultDictionaryName : trimmedName

            let targetDictionary: WordDictionaryModel
            if let existingById = updatedDictionaries.first(where: { $0.id == package.sourceDictionaryId }),
               package.sourceDictionaryId != nil {
                targetDictionary = normalizedDictionary(existingById)
            } else if let existingByName = updatedDictionaries.first(where: {
                $0.name.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare(dictionaryName) == .orderedSame
            }) {
                targetDictionary = normalizedDictionary(existingByName)
            } else {
                let created = normalizedDictionary(
                    WordDictionaryModel(
                        id: package.sourceDictionaryId ?? UUID().uuidString,
                        name: dictionaryName,
                        createdAt: package.createdAt,
                        userId: Auth.auth().currentUser?.uid
                    )
                )
                updatedDictionaries.append(created)
                targetDictionary = created
                if let id = created.id {
                    createdDictionaryIds.insert(id)
                }
                dictionariesToPersist.append(created)
            }

            let targetDictionaryId = resolvedSelectionDictionaryId(for: targetDictionary)
            affectedDictionaryIds.insert(targetDictionaryId)

            for packageWord in package.words {
                var importedWord = packageWord
                importedWord.dictionaryId = targetDictionaryId

                let normalized = ensureUniqueWordIdIfNeeded(
                    for: normalizedWord(importedWord, fallbackDictionaryId: targetDictionaryId),
                    against: updatedWords
                )

                if indexForExistingWord(normalized, in: updatedWords) != nil {
                    duplicateCount += 1
                    continue
                }

                updatedWords.append(normalized)
                wordsToPersist.append(normalized)
                importedWordCount += 1
            }
        }

        updatedDictionaries.sort { $0.createdAt < $1.createdAt }
        applyAndPersist(words: updatedWords, dictionaries: updatedDictionaries)

        for dictionary in updatedDictionaries where createdDictionaryIds.contains(dictionary.id ?? "") {
            if !dictionariesToPersist.contains(where: { $0.id == dictionary.id }) {
                dictionariesToPersist.append(dictionary)
            }
        }

        for dictionary in dictionariesToPersist {
            do {
                try await FirestoreService.shared.saveDictionary(dictionary)
            } catch {
                print("❌ Failed to persist imported dictionary: \(error)")
            }
        }

        for word in wordsToPersist {
            do {
                try await FirestoreService.shared.saveWord(word)
            } catch {
                print("❌ Failed to persist imported word: \(error)")
            }
        }

        return DictionaryImportSummary(
            importedWordCount: importedWordCount,
            duplicateCount: duplicateCount,
            importedDictionaryCount: affectedDictionaryIds.count,
            format: .json
        )
    }

    func containsWord(_ word: SavedWordModel, in dictionaryId: String) -> Bool {
        let normalized = normalizedWord(word, fallbackDictionaryId: dictionaryId)
        return savedWords.contains { stableKey(for: $0) == stableKey(for: normalized) }
    }

    // MARK: - Public API

    func fetchSavedWords() {
        isLoading = true

        Task {
            do {
                let remoteDictionaries = try await FirestoreService.shared.fetchDictionaries()
                let remoteWords = try await FirestoreService.shared.fetchWords()
                let localWords = readWordsFromStorage()
                let localDictionaries = readDictionariesFromStorage()

                let mergedWords = mergeWordsPreservingLocal(local: localWords, remote: remoteWords)
                let mergedDictionaries = mergeDictionariesPreservingLocal(
                    local: localDictionaries,
                    remote: remoteDictionaries
                )
                let prepared = prepareData(words: mergedWords, dictionaries: mergedDictionaries)

                await MainActor.run {
                    self.applyAndPersist(words: prepared.words, dictionaries: prepared.dictionaries)
                    self.isLoading = false
                }

                if prepared.needsRemoteMigration {
                    Task {
                        await self.persistMigration(words: prepared.words, dictionaries: prepared.dictionaries)
                    }
                }
            } catch {
                print("❌ Failed to fetch dictionary data: \(error)")
                let localWords = readWordsFromStorage()
                let localDictionaries = readDictionariesFromStorage()
                let prepared = prepareData(words: localWords, dictionaries: localDictionaries)

                await MainActor.run {
                    self.applyAndPersist(words: prepared.words, dictionaries: prepared.dictionaries)
                    self.isLoading = false
                }
            }
        }
    }

    func saveWord(_ word: SavedWordModel) {
        var updatedWords = savedWords
        print("💾 VM saveWord input original='\(word.original)' dictionaryId='\(word.dictionaryId ?? "nil")'")
        let normalized = ensureUniqueWordIdIfNeeded(
            for: normalizedWord(word),
            against: updatedWords
        )
        print("💾 VM saveWord normalized original='\(normalized.original)' id='\(normalized.id ?? "nil")' dictionaryId='\(normalized.dictionaryId ?? "nil")'")

        if let index = indexForExistingWord(normalized, in: updatedWords) {
            updatedWords[index] = mergeWord(new: normalized, existing: updatedWords[index])
        } else {
            updatedWords.append(normalized)
        }

        applyAndPersist(words: updatedWords, dictionaries: dictionaries)

        Task {
            do {
                if let finalWord = self.savedWords.first(where: {
                    self.stableKey(for: $0) == self.stableKey(for: normalized)
                }) {
                    print("☁️ VM saveWord final original='\(finalWord.original)' id='\(finalWord.id ?? "nil")' dictionaryId='\(finalWord.dictionaryId ?? "nil")'")
                    try await FirestoreService.shared.saveWord(finalWord)
                }
            } catch {
                print("❌ Firestore save error: \(error)")
            }
        }
    }

    func saveWords(_ words: [SavedWordModel]) {
        guard !words.isEmpty else { return }

        var updatedWords = savedWords
        var normalizedWordsToPersist: [SavedWordModel] = []

        for word in words {
            let normalized = ensureUniqueWordIdIfNeeded(
                for: normalizedWord(word),
                against: updatedWords
            )
            normalizedWordsToPersist.append(normalized)
            if let index = indexForExistingWord(normalized, in: updatedWords) {
                updatedWords[index] = mergeWord(new: normalized, existing: updatedWords[index])
            } else {
                updatedWords.append(normalized)
            }
        }

        applyAndPersist(words: updatedWords, dictionaries: dictionaries)

        Task {
            do {
                for normalized in normalizedWordsToPersist {
                    if let finalWord = self.savedWords.first(where: {
                        self.stableKey(for: $0) == self.stableKey(for: normalized)
                    }) {
                        try await FirestoreService.shared.saveWord(finalWord)
                    }
                }
            } catch {
                print("❌ Failed to batch save words to Firestore: \(error)")
            }
        }
    }

    func deleteWord(_ word: SavedWordModel) {
        let updatedWords = savedWords.filter { current in
            stableKey(for: current) != stableKey(for: word)
        }

        applyAndPersist(words: updatedWords, dictionaries: dictionaries)

        if word.id != nil {
            Task {
                do {
                    try await FirestoreService.shared.deleteWord(word)
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
        applyAndPersist(words: updatedWords, dictionaries: dictionaries)
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
        applyAndPersist(words: updatedWords, dictionaries: dictionaries)

        Task {
            do {
                try await FirestoreService.shared.saveWord(updatedWord)
            } catch {
                print("❌ Failed to update status: \(error)")
            }
        }
    }

    // MARK: - Apply / Persist

    func applyAndPersist(words: [SavedWordModel], dictionaries: [WordDictionaryModel]) {
        let prepared = prepareData(words: words, dictionaries: dictionaries)
        savedWords = prepared.words
        self.dictionaries = prepared.dictionaries
        writeWordsToStorage(prepared.words)
        writeDictionariesToStorage(prepared.dictionaries)
        syncWidgetWords()
        NotificationManager.shared.refreshWordOfDayNotifications(words: prepared.words)
    }

    // MARK: - Data Preparation

    private func prepareData(
        words: [SavedWordModel],
        dictionaries: [WordDictionaryModel]
    ) -> (words: [SavedWordModel], dictionaries: [WordDictionaryModel], needsRemoteMigration: Bool) {
        var normalizedDictionaries = dictionaries
            .map { normalizedDictionary($0) }
            .sorted { $0.createdAt < $1.createdAt }

        var needsRemoteMigration = false

        if normalizedDictionaries.isEmpty {
            normalizedDictionaries = [makeDefaultDictionary()]
            needsRemoteMigration = true
        }

        let fallbackDictionaryId = normalizedDictionaries.first?.id ?? UUID().uuidString
        let validDictionaryIds = Set(normalizedDictionaries.compactMap { $0.id })

        let normalizedWords = deduplicate(
            words.map { word in
                var wordForNormalization = word
                let trimmedDictionaryId = word.dictionaryId?.trimmingCharacters(in: .whitespacesAndNewlines)

                if let trimmedDictionaryId,
                   !trimmedDictionaryId.isEmpty,
                   !validDictionaryIds.contains(trimmedDictionaryId) {
                    wordForNormalization.dictionaryId = fallbackDictionaryId
                    needsRemoteMigration = true
                }

                let normalized = normalizedWord(wordForNormalization, fallbackDictionaryId: fallbackDictionaryId)
                if word.dictionaryId == nil || word.dictionaryId?.isEmpty == true {
                    needsRemoteMigration = true
                }
                return normalized
            }
        )

        return (normalizedWords, normalizedDictionaries, needsRemoteMigration)
    }

    private func normalizedDictionary(_ dictionary: WordDictionaryModel) -> WordDictionaryModel {
        var normalized = dictionary
        if normalized.id == nil || normalized.id?.isEmpty == true {
            normalized.id = UUID().uuidString
        }
        normalized.name = normalized.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.name.isEmpty {
            normalized.name = defaultDictionaryName
        }
        return normalized
    }

    private func makeDefaultDictionary() -> WordDictionaryModel {
        WordDictionaryModel(
            id: UUID().uuidString,
            name: defaultDictionaryName,
            createdAt: Date(timeIntervalSince1970: 0),
            userId: Auth.auth().currentUser?.uid
        )
    }

    private var defaultDictionaryName: String {
        "My Dictionary"
    }

    private func ensureDefaultDictionaryExists() -> WordDictionaryModel {
        if let existing = dictionaries.first {
            return existing
        }

        let dictionary = makeDefaultDictionary()
        dictionaries = [dictionary]
        writeDictionariesToStorage(dictionaries)
        return dictionary
    }

    private func mergeDictionariesPreservingLocal(
        local: [WordDictionaryModel],
        remote: [WordDictionaryModel]
    ) -> [WordDictionaryModel] {
        var merged: [WordDictionaryModel] = []
        var seen = Set<String>()

        for dictionary in remote + local {
            let normalized = normalizedDictionary(dictionary)
            let key = normalized.id ?? UUID().uuidString

            guard !seen.contains(key) else { continue }
            seen.insert(key)
            merged.append(normalized)
        }

        return merged.sorted { $0.createdAt < $1.createdAt }
    }

    private func mergeWordsPreservingLocal(
        local: [SavedWordModel],
        remote: [SavedWordModel]
    ) -> [SavedWordModel] {
        deduplicate(remote + local)
    }

    private func persistMigration(words: [SavedWordModel], dictionaries: [WordDictionaryModel]) async {
        do {
            for dictionary in dictionaries {
                try await FirestoreService.shared.saveDictionary(dictionary)
            }

            for word in words {
                try await FirestoreService.shared.saveWord(word)
            }
        } catch {
            print("❌ Failed to persist dictionary migration: \(error)")
        }
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
            return "id:\(id)|dict:\(resolvedDictionaryId(for: word.dictionaryId))"
        }

        return [
            resolvedDictionaryId(for: word.dictionaryId),
            word.original.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            word.translation.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            word.languagePair.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        ].joined(separator: "|")
    }

    private func normalizedWord(_ word: SavedWordModel, fallbackDictionaryId: String? = nil) -> SavedWordModel {
        var normalized = word

        if normalized.id == nil || normalized.id?.isEmpty == true {
            normalized.id = UUID().uuidString
        }

        normalized.original = normalized.original.trimmingCharacters(in: .whitespacesAndNewlines)
        normalized.translation = normalized.translation.trimmingCharacters(in: .whitespacesAndNewlines)
        normalized.languagePair = normalized.languagePair.trimmingCharacters(in: .whitespacesAndNewlines)

        let normalizedDictionaryId = normalized.dictionaryId?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let resolvedId = ((normalizedDictionaryId?.isEmpty == false) ? normalizedDictionaryId : nil)
            ?? fallbackDictionaryId
            ?? dictionaries.first?.id
            ?? ensureDefaultDictionaryExists().id

        normalized.dictionaryId = resolvedId
        print("🧭 normalizedWord original='\(normalized.original)' incomingDictionaryId='\(word.dictionaryId ?? "nil")' fallback='\(fallbackDictionaryId ?? "nil")' resolved='\(resolvedId ?? "nil")'")
        return normalized
    }

    private func mergeWord(new: SavedWordModel, existing: SavedWordModel) -> SavedWordModel {
        var result = normalizedWord(new, fallbackDictionaryId: existing.dictionaryId)

        result.id = existing.id ?? result.id

        if result.transcription?.isEmpty ?? true {
            result.transcription = existing.transcription
        }

        if result.exampleSentence?.isEmpty ?? true {
            result.exampleSentence = existing.exampleSentence
        }

        if result.languagePair.isEmpty {
            result.languagePair = existing.languagePair
        }

        result.dictionaryId = existing.dictionaryId ?? result.dictionaryId

        if new.isLearned != existing.isLearned {
            result.isLearned = new.isLearned
        }

        result.reviewCount = max(existing.reviewCount, new.reviewCount)

        if result.nextReviewDate == nil {
            result.nextReviewDate = existing.nextReviewDate
        }

        return result
    }

    private func ensureUniqueWordIdIfNeeded(
        for word: SavedWordModel,
        against words: [SavedWordModel]
    ) -> SavedWordModel {
        guard let id = word.id, !id.isEmpty else {
            return word
        }

        let hasConflict = words.contains { existing in
            existing.id == id && stableKey(for: existing) != stableKey(for: word)
        }

        guard hasConflict else {
            return word
        }

        var uniqueWord = word
        uniqueWord.id = UUID().uuidString
        return uniqueWord
    }

    private func resolvedDictionaryId(for dictionaryId: String?) -> String {
        if let dictionaryId, !dictionaryId.isEmpty {
            return dictionaryId
        }
        return ensureDefaultDictionaryExists().id ?? ""
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

    private func readDictionariesFromStorage() -> [WordDictionaryModel] {
        guard let data = UserDefaults.standard.data(forKey: dictionariesStorageKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([WordDictionaryModel].self, from: data)
        } catch {
            print("❌ Failed to decode dictionaries: \(error)")
            return []
        }
    }

    private func writeDictionariesToStorage(_ dictionaries: [WordDictionaryModel]) {
        do {
            let data = try JSONEncoder().encode(dictionaries)
            UserDefaults.standard.set(data, forKey: dictionariesStorageKey)
        } catch {
            print("❌ Failed to encode dictionaries: \(error)")
        }
    }

    private func syncWidgetWords() {
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

        WidgetDataService.shared.updateWidgetWords(words: widgetWords)
    }

    // MARK: - Firestore Listener

    private func startListeningIfNeeded() {
        stopListening()

        listener = FirestoreService.shared.addWordsListener { [weak self] remoteWords in
            guard let self = self else { return }

            let prepared = self.prepareData(words: remoteWords, dictionaries: self.dictionaries)

            DispatchQueue.main.async {
                self.applyAndPersist(words: prepared.words, dictionaries: prepared.dictionaries)
            }
        }
    }
}
