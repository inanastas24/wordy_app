//
//  ExportImport.swift
//  Wordy
//

import Foundation
import SwiftData

enum ExportImportError: Error, LocalizedError {
    case noWordsToExport
    case encodingFailed
    case fileCreationFailed
    case importFailed
    case invalidFileFormat
    case noWordsImported
    
    var errorDescription: String? {
        switch self {
        case .noWordsToExport:
            return "Словник порожній"
        case .encodingFailed:
            return "Помилка кодування даних"
        case .fileCreationFailed:
            return "Не вдалося створити файл"
        case .importFailed:
            return "Помилка читання файлу"
        case .invalidFileFormat:
            return "Невірний формат файлу"
        case .noWordsImported:
            return "У файлі не знайдено слів"
        }
    }
}

class DictionaryExportService {
    static func exportWords(_ words: [SavedWord]) throws -> URL {
        guard !words.isEmpty else {
            throw ExportImportError.noWordsToExport
        }
        
        var exportData: [[String: Any]] = []
        
        for word in words {
            var wordDict: [String: Any] = [
                "original": word.original,
                "translation": word.translation,
                "transcription": word.transcription,
                "exampleSentence": word.exampleSentence,
                "languagePair": word.languagePair,
                "dateAdded": ISO8601DateFormatter().string(from: word.dateAdded),
                "isLearned": word.isLearned,
                "reviewCount": word.reviewCount,
                "srsInterval": word.srsInterval,
                "srsRepetition": word.srsRepetition,
                "srsEasinessFactor": word.srsEasinessFactor,
                "averageQuality": word.averageQuality
            ]
            
            if let lastReview = word.lastReviewDate {
                wordDict["lastReviewDate"] = ISO8601DateFormatter().string(from: lastReview)
            }
            
            if let nextReview = word.nextReviewDate {
                wordDict["nextReviewDate"] = ISO8601DateFormatter().string(from: nextReview)
            }
            
            exportData.append(wordDict)
        }
        
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys])
        } catch {
            throw ExportImportError.encodingFailed
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let dateString = dateFormatter.string(from: Date())
        
        let filename = "wordy_backup_\(dateString).json"
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = path.appendingPathComponent(filename)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        do {
            try jsonData.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            throw ExportImportError.fileCreationFailed
        }
    }
    
    static func importWords(from url: URL) async throws -> Int {
        guard url.startAccessingSecurityScopedResource() else {
            throw ExportImportError.importFailed
        }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: url)
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                throw ExportImportError.invalidFileFormat
            }
            
            print("📥 Імпорт: знайдено \(json.count) записів у файлі")
            
            var importedWords: [SavedWordModel] = []
            
            let existingWords = DictionaryViewModel.shared.savedWords
            let existingOriginals = Set(existingWords.map { $0.original.lowercased() })
            
            for item in json {
                guard let original = item["original"] as? String,
                      let translation = item["translation"] as? String,
                      !original.isEmpty else {
                    print("⚠️ Пропущено запис: відсутні original або translation")
                    continue
                }
                
                if existingOriginals.contains(original.lowercased()) {
                    print("⚠️ Пропущено дублікат: \(original)")
                    continue
                }
                
                let languagePair = item["languagePair"] as? String ?? "en-uk"
                let isLearned = item["isLearned"] as? Bool ?? false
                let reviewCount = item["reviewCount"] as? Int ?? 0
                
                var word = SavedWordModel(
                    id: UUID().uuidString,
                    original: original,
                    translation: translation,
                    transcription: item["transcription"] as? String,
                    exampleSentence: item["exampleSentence"] as? String,
                    languagePair: languagePair,
                    isLearned: isLearned,
                    reviewCount: reviewCount,
                    srsInterval: item["srsInterval"] as? Double ?? 0,
                    srsRepetition: item["srsRepetition"] as? Int ?? 0,
                    srsEasinessFactor: item["srsEasinessFactor"] as? Double ?? 2.5,
                    nextReviewDate: nil,
                    lastReviewDate: nil,
                    averageQuality: item["averageQuality"] as? Double ?? 0,
                    createdAt: Date(),
                    userId: nil
                )
                
                // Відновлюємо дати
                if let dateString = item["dateAdded"] as? String,
                   let date = ISO8601DateFormatter().date(from: dateString) {
                    word.createdAt = date
                }
                
                if let lastReviewString = item["lastReviewDate"] as? String,
                   let lastReview = ISO8601DateFormatter().date(from: lastReviewString) {
                    word.lastReviewDate = lastReview
                }
                
                if let nextReviewString = item["nextReviewDate"] as? String,
                   let nextReview = ISO8601DateFormatter().date(from: nextReviewString) {
                    word.nextReviewDate = nextReview
                }
                
                importedWords.append(word)
            }
            
            guard !importedWords.isEmpty else {
                throw ExportImportError.noWordsImported
            }
            
            await MainActor.run {
                DictionaryViewModel.shared.saveWords(importedWords)
            }
            
            print("✅ Імпорт завершено: \(importedWords.count) слів")
            return importedWords.count
            
        } catch let error as ExportImportError {
            throw error
        } catch {
            print("❌ Помилка імпорту: \(error)")
            throw ExportImportError.importFailed
        }
    }
}
