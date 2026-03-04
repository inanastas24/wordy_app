//
//  ExportImport.swift
//  Wordy
//

import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Errors (локалізовані)
enum ExportImportError: Error, LocalizedError {
    case noWordsToExport
    case encodingFailed
    case fileCreationFailed
    case importFailed
    case invalidFileFormat
    case noWordsImported
    case invalidCSVFormat
    
    func localizedDescription(for language: AppLanguage) -> String {
        switch self {
        case .noWordsToExport:
            switch language {
            case .ukrainian: return "Словник порожній. Додайте слова перед експортом."
            case .polish: return "Słownik jest pusty. Dodaj słowa przed eksportem."
            case .english: return "Dictionary is empty. Add words before exporting."
            }
        case .encodingFailed:
            switch language {
            case .ukrainian: return "Помилка кодування даних. Спробуйте ще раз."
            case .polish: return "Błąd kodowania danych. Spróbuj ponownie."
            case .english: return "Data encoding error. Please try again."
            }
        case .fileCreationFailed:
            switch language {
            case .ukrainian: return "Не вдалося створити файл. Перевірте вільне місце."
            case .polish: return "Nie udało się utworzyć pliku. Sprawdź wolne miejsce."
            case .english: return "Failed to create file. Check available storage."
            }
        case .importFailed:
            switch language {
            case .ukrainian: return "Помилка читання файлу. Перевірте формат."
            case .polish: return "Błąd odczytu pliku. Sprawdź format."
            case .english: return "File reading error. Check the format."
            }
        case .invalidFileFormat:
            switch language {
            case .ukrainian: return "Невірний формат файлу. Підтримуються: JSON, CSV, TXT"
            case .polish: return "Nieprawidłowy format pliku. Obsługiwane: JSON, CSV, TXT"
            case .english: return "Invalid file format. Supported: JSON, CSV, TXT"
            }
        case .noWordsImported:
            switch language {
            case .ukrainian: return "У файлі не знайдено слів для імпорту."
            case .polish: return "Nie znaleziono słów do importu w pliku."
            case .english: return "No words found for import in the file."
            }
        case .invalidCSVFormat:
            switch language {
            case .ukrainian: return "Невірний формат CSV. Перевірте роздільники."
            case .polish: return "Nieprawidłowy format CSV. Sprawdź separatory."
            case .english: return "Invalid CSV format. Check separators."
            }
        }
    }
    
    var errorDescription: String? {
        return localizedDescription(for: .english)
    }
}

// MARK: - Export Format
enum ExportFormat: String, CaseIterable, Identifiable {
    case json = "json"
    case csv = "csv"
    case txt = "txt"
    
    var id: String { rawValue }
    
    func localizedName(for language: AppLanguage) -> String {
        switch (self, language) {
        case (.json, .ukrainian): return "JSON (.json)"
        case (.json, .polish): return "JSON (.json)"
        case (.json, .english): return "JSON (.json)"
            
        case (.csv, .ukrainian): return "CSV (.csv)"
        case (.csv, .polish): return "CSV (.csv)"
        case (.csv, .english): return "CSV (.csv)"
            
        case (.txt, .ukrainian): return "Текст (.txt)"
        case (.txt, .polish): return "Tekst (.txt)"
        case (.txt, .english): return "Text (.txt)"
        }
    }
    
    func localizedDescription(for language: AppLanguage) -> String {
        switch (self, language) {
        case (.json, .ukrainian):
            return "Повне резервне копіювання з прогресом вивчення"
        case (.json, .polish):
            return "Pełna kopia zapasowa z postępem nauki"
        case (.json, .english):
            return "Full backup with learning progress"
            
        case (.csv, .ukrainian):
            return "Таблиця з прикладами для Excel"
        case (.csv, .polish):
            return "Tabela z przykładami dla Excel"
        case (.csv, .english):
            return "Table with examples for Excel"
            
        case (.txt, .ukrainian):
            return "Простий список для друку"
        case (.txt, .polish):
            return "Prosta lista do druku"
        case (.txt, .english):
            return "Simple list for printing"
        }
    }
    
    var fileExtension: String { rawValue }
    
    var mimeType: String {
        switch self {
        case .json: return "application/json"
        case .csv: return "text/csv"
        case .txt: return "text/plain"
        }
    }
}

// MARK: - Import Word Model
struct ImportWord {
    let original: String
    let translation: String
    let transcription: String?
    let examples: [(original: String, translation: String)]
    
    var exampleSentence: String? {
        guard !examples.isEmpty else { return nil }
        return examples.map { $0.original }.joined(separator: "; ")
    }
    
    var exampleTranslation: String? {
        guard !examples.isEmpty else { return nil }
        return examples.map { $0.translation }.joined(separator: "; ")
    }
}

// MARK: - Export Import Service
actor DictionaryExportService {
    
    // MARK: - Export Methods
    
    static func exportWords(
        _ words: [SavedWordModel],
        format: ExportFormat = .json,
        language: AppLanguage = .english
    ) throws -> URL {
        guard !words.isEmpty else {
            throw ExportImportError.noWordsToExport
        }
        
        let data: Data
        
        switch format {
        case .json:
            data = try exportJSON(words, language: language)
        case .csv:
            data = try exportCSV(words, language: language)
        case .txt:
            data = try exportTXT(words, language: language)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let dateString = dateFormatter.string(from: Date())
        
        let filename = "wordy_\(dateString).\(format.fileExtension)"
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = path.appendingPathComponent(filename)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            throw ExportImportError.fileCreationFailed
        }
    }
    
    // MARK: - JSON Export
    
    private static func exportJSON(_ words: [SavedWordModel], language: AppLanguage) throws -> Data {
        var exportData: [[String: Any]] = []
        
        for word in words {
            var wordDict: [String: Any] = [
                "original": word.original,
                "translation": word.translation,
                "transcription": word.transcription ?? "",
                "exampleSentence": word.exampleSentence ?? "",
                "languagePair": word.languagePair,
                "dateAdded": ISO8601DateFormatter().string(from: word.createdAt),
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
        
        return try JSONSerialization.data(withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys])
    }
    
    // MARK: - CSV Export
    
    private static func exportCSV(_ words: [SavedWordModel], language: AppLanguage) throws -> Data {
        var lines: [String] = []
        
        let header: String
        switch language {
        case .ukrainian:
            header = "Слово;Транскрипція;Переклад;Приклад;Переклад прикладу"
        case .polish:
            header = "Słowo;Transkrypcja;Tłumaczenie;Przykład;Tłumaczenie przykładu"
        case .english:
            header = "Word;Transcription;Translation;Example;Example Translation"
        }
        lines.append(header)
        
        for word in words {
            let original = escapeCSV(word.original)
            let transcription = escapeCSV(word.transcription ?? "")
            let translation = escapeCSV(word.translation)
            
            let examples = parseExamples(word.exampleSentence ?? "")
            
            if examples.isEmpty {
                lines.append("\(original);\(transcription);\(translation);;")
            } else {
                let first = examples[0]
                lines.append("\(original);\(transcription);\(translation);\(escapeCSV(first.original));\(escapeCSV(first.translation))")
                
                for i in 1..<examples.count {
                    lines.append(";;; \(escapeCSV(examples[i].original));\(escapeCSV(examples[i].translation))")
                }
            }
        }
        
        let csvString = lines.joined(separator: "\n")
        guard let data = csvString.data(using: .utf8) else {
            throw ExportImportError.encodingFailed
        }
        return data
    }
    
    // MARK: - TXT Export
    
    private static func exportTXT(_ words: [SavedWordModel], language: AppLanguage) throws -> Data {
        var lines: [String] = []
        
        let title: String
        let totalWords: String
        let exportedAt: String
        
        switch language {
        case .ukrainian:
            title = "📚 Мій словник Wordy"
            totalWords = "Всього слів"
            exportedAt = "Експортовано"
        case .polish:
            title = "📚 Mój słownik Wordy"
            totalWords = "Wszystkich słów"
            exportedAt = "Wyeksportowano"
        case .english:
            title = "📚 My Wordy Dictionary"
            totalWords = "Total words"
            exportedAt = "Exported"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: language.rawValue)
        
        lines.append(title)
        lines.append(String(repeating: "=", count: title.count))
        lines.append("")
        lines.append("\(totalWords): \(words.count)")
        lines.append("\(exportedAt): \(dateFormatter.string(from: Date()))")
        lines.append("")
        lines.append(String(repeating: "-", count: 40))
        lines.append("")
        
        for (index, word) in words.enumerated() {
            let transcription = (word.transcription ?? "").isEmpty ? "" : " [\(word.transcription!)]"
            lines.append("\(index + 1). \(word.original)\(transcription) - \(word.translation)")
            
            if let exampleSentence = word.exampleSentence, !exampleSentence.isEmpty {
                let examples = exampleSentence.components(separatedBy: "; ")
                for example in examples {
                    lines.append("   • \(example)")
                }
            }
            
            lines.append("")
        }
        
        let txtString = lines.joined(separator: "\n")
        guard let data = txtString.data(using: .utf8) else {
            throw ExportImportError.encodingFailed
        }
        return data
    }
    
    // MARK: - Helper Methods
    
    private static func escapeCSV(_ string: String) -> String {
        let escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(";") || escaped.contains("\"") || escaped.contains("\n") {
            return "\"\(escaped)\""
        }
        return escaped
    }
    
    private static func parseExamples(_ sentence: String) -> [(original: String, translation: String)] {
        guard !sentence.isEmpty else { return [] }
        
        let parts = sentence.components(separatedBy: "; ")
        var result: [(String, String)] = []
        
        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            if let range = trimmed.range(of: " (", options: .backwards),
               trimmed.hasSuffix(")") {
                let original = String(trimmed[..<range.lowerBound])
                let translationStart = trimmed.index(range.upperBound, offsetBy: 0)
                let translationEnd = trimmed.index(before: trimmed.endIndex)
                let translation = String(trimmed[translationStart..<translationEnd])
                result.append((original, translation))
            } else {
                result.append((trimmed, ""))
            }
        }
        
        return result
    }
    
    // MARK: - Import Methods
    
    static func importWords(
        from url: URL,
        language: AppLanguage = .english
    ) async throws -> (count: Int, format: ExportFormat, words: [SavedWordModel]) {
        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        
        defer {
            if shouldStopAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ExportImportError.importFailed
        }
        
        let ext = url.pathExtension.lowercased()
        let format: ExportFormat
        let words: [SavedWordModel]
        
        switch ext {
        case "json":
            format = .json
            words = try await importJSON(data, language: language)
        case "csv":
            format = .csv
            words = try await importCSV(data, language: language)
        case "txt":
            format = .txt
            words = try await importTXT(data, language: language)
        default:
            if let string = String(data: data, encoding: .utf8) {
                let trimmed = string.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("[") {
                    format = .json
                    words = try await importJSON(data, language: language)
                } else if string.contains(";") {
                    format = .csv
                    words = try await importCSV(data, language: language)
                } else {
                    format = .txt
                    words = try await importTXT(data, language: language)
                }
            } else {
                throw ExportImportError.invalidFileFormat
            }
        }
        
        guard !words.isEmpty else {
            throw ExportImportError.noWordsImported
        }
        
        return (words.count, format, words)
    }
    
    // MARK: - JSON Import
    
    private static func importJSON(_ data: Data, language: AppLanguage) async throws -> [SavedWordModel] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw ExportImportError.invalidFileFormat
        }
        
        var importedWords: [SavedWordModel] = []
        
        for item in json {
            guard let original = item["original"] as? String,
                  let translation = item["translation"] as? String,
                  !original.isEmpty else {
                continue
            }
            
            let word = SavedWordModel(
                id: item["id"] as? String ?? UUID().uuidString,
                original: original,
                translation: translation,
                transcription: item["transcription"] as? String,
                exampleSentence: item["exampleSentence"] as? String,
                languagePair: item["languagePair"] as? String ?? "en-uk",
                isLearned: item["isLearned"] as? Bool ?? false,
                reviewCount: item["reviewCount"] as? Int ?? 0,
                srsInterval: item["srsInterval"] as? Double ?? 0,
                srsRepetition: item["srsRepetition"] as? Int ?? 0,
                srsEasinessFactor: item["srsEasinessFactor"] as? Double ?? 2.5,
                nextReviewDate: (item["nextReviewDate"] as? String).flatMap { ISO8601DateFormatter().date(from: $0) },
                lastReviewDate: (item["lastReviewDate"] as? String).flatMap { ISO8601DateFormatter().date(from: $0) },
                averageQuality: item["averageQuality"] as? Double ?? 0,
                createdAt: (item["dateAdded"] as? String).flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()
            )
            
            importedWords.append(word)
        }
        
        return importedWords
    }
    
    // MARK: - CSV Import
    
    private static func importCSV(_ data: Data, language: AppLanguage) async throws -> [SavedWordModel] {
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw ExportImportError.encodingFailed
        }
        
        let lines = csvString.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard lines.count > 1 else {
            throw ExportImportError.invalidCSVFormat
        }
        
        let dataLines = Array(lines.dropFirst())
        
        var importedWords: [SavedWordModel] = []
        
        var currentOriginal = ""
        var currentTranslation = ""
        var currentTranscription: String?
        var currentExamples: [(String, String)] = []
        
        func saveCurrentWord() {
            guard !currentOriginal.isEmpty else { return }
            
            let exampleSentence = currentExamples.isEmpty ? nil :
                currentExamples.map { $0.0 }.joined(separator: "; ")
            
            let word = SavedWordModel(
                id: UUID().uuidString,
                original: currentOriginal,
                translation: currentTranslation,
                transcription: currentTranscription,
                exampleSentence: exampleSentence,
                languagePair: "en-uk",
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
            
            importedWords.append(word)
        }
        
        for line in dataLines {
            let columns = parseCSVLine(line)
            let isContinuation = columns[0].trimmingCharacters(in: .whitespaces).isEmpty
            
            if !isContinuation {
                saveCurrentWord()
                
                guard columns.count >= 2 else { continue }
                
                currentOriginal = columns[0]
                currentTranslation = columns.count > 2 ? columns[2] : columns[1]
                currentTranscription = columns.count > 1 && !columns[1].isEmpty ? columns[1] : nil
                currentExamples = []
                
                if columns.count > 3 && !columns[3].isEmpty {
                    let exOriginal = columns[3]
                    let exTranslation = columns.count > 4 ? columns[4] : ""
                    currentExamples.append((exOriginal, exTranslation))
                }
            } else {
                if columns.count > 3 && !columns[3].isEmpty {
                    let exOriginal = columns[3]
                    let exTranslation = columns.count > 4 ? columns[4] : ""
                    currentExamples.append((exOriginal, exTranslation))
                }
            }
        }
        
        saveCurrentWord()
        
        return importedWords
    }
    
    // MARK: - TXT Import
    
    private static func importTXT(_ data: Data, language: AppLanguage) async throws -> [SavedWordModel] {
        guard let txtString = String(data: data, encoding: .utf8) else {
            throw ExportImportError.encodingFailed
        }
        
        let lines = txtString.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var importedWords: [SavedWordModel] = []
        
        var i = 0
        while i < lines.count {
            let line = lines[i]
            
            if line.hasPrefix("=") || line.hasPrefix("-") || line.hasPrefix("📚") ||
               line.hasPrefix("Всього") || line.hasPrefix("Wszystkich") || line.hasPrefix("Total") ||
               line.hasPrefix("Експортовано") || line.hasPrefix("Wyeksportowano") || line.hasPrefix("Exported") {
                i += 1
                continue
            }
            
            guard let separatorRange = line.range(of: " - ") else {
                i += 1
                continue
            }
            
            let leftPart = String(line[..<separatorRange.lowerBound])
            let translation = String(line[separatorRange.upperBound...])
            
            let cleanLeftPart: String
            if let dotRange = leftPart.range(of: ". ") {
                cleanLeftPart = String(leftPart[dotRange.upperBound...])
            } else {
                cleanLeftPart = leftPart
            }
            
            let original: String
            let transcription: String?
            
            if let bracketOpen = cleanLeftPart.range(of: " ["),
               let bracketClose = cleanLeftPart.range(of: "]", options: .backwards) {
                original = String(cleanLeftPart[..<bracketOpen.lowerBound])
                transcription = String(cleanLeftPart[bracketOpen.upperBound..<bracketClose.lowerBound])
            } else {
                original = cleanLeftPart
                transcription = nil
            }
            
            guard !original.isEmpty && !translation.isEmpty else {
                i += 1
                continue
            }
            
            var examples: [String] = []
            i += 1
            while i < lines.count {
                let nextLine = lines[i]
                if nextLine.hasPrefix("•") || nextLine.hasPrefix("   ") {
                    let example = nextLine.trimmingCharacters(in: .whitespaces)
                        .replacingOccurrences(of: "•", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    if !example.isEmpty {
                        examples.append(example)
                    }
                    i += 1
                } else {
                    break
                }
            }
            
            let word = SavedWordModel(
                id: UUID().uuidString,
                original: original,
                translation: translation,
                transcription: transcription,
                exampleSentence: examples.isEmpty ? nil : examples.joined(separator: "; "),
                languagePair: "en-uk",
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
            
            importedWords.append(word)
        }
        
        return importedWords
    }
    
    // MARK: - Helper Methods
    
    private static func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var insideQuotes = false
        
        for char in line {
            switch char {
            case "\"":
                insideQuotes.toggle()
            case ";":
                if insideQuotes {
                    current.append(char)
                } else {
                    result.append(current)
                    current = ""
                }
            default:
                current.append(char)
            }
        }
        
        result.append(current)
        return result
    }
    
    // MARK: - Pluralization Helpers
    
    private static func pluralizeUkrainian(count: Int, one: String, few: String, many: String) -> String {
        let lastDigit = count % 10
        let lastTwoDigits = count % 100
        
        if lastTwoDigits >= 11 && lastTwoDigits <= 19 {
            return many
        }
        
        switch lastDigit {
        case 1: return one
        case 2...4: return few
        default: return many
        }
    }
    
    private static func pluralizePolish(count: Int, one: String, few: String, many: String) -> String {
        let lastDigit = count % 10
        let lastTwoDigits = count % 100
        
        if count == 1 {
            return one
        }
        
        if lastDigit >= 2 && lastDigit <= 4 && (lastTwoDigits < 10 || lastTwoDigits >= 20) {
            return few
        }
        
        return many
    }
}

// MARK: - Type Aliases для сумісності
typealias AppLanguage = Language
