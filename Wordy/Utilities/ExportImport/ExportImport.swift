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
    case duplicateWordsFound(Int) // НОВЕ: знайдено дублікати
    
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
        case .duplicateWordsFound(let count):
            switch language {
            case .ukrainian: return "Пропущено \(count) дублікатів слів, які вже існують у словнику."
            case .polish: return "Pominięto \(count) duplikatów słów, które już istnieją w słowniku."
            case .english: return "Skipped \(count) duplicate words that already exist in the dictionary."
            }
        }
    }
    
    var errorDescription: String? {
        return localizedDescription(for: .english)
    }
}

// MARK: - Import Result (НОВЕ)
struct ImportResult {
    let importedCount: Int
    let duplicateCount: Int
    let skippedCount: Int
    let format: ExportFormat
    let words: [SavedWordModel]
}

struct DictionaryTransferPackage: Identifiable {
    let id = UUID()
    let dictionaryName: String
    let createdAt: Date
    let sourceDictionaryId: String?
    let words: [SavedWordModel]
}

struct ParsedDictionaryImport {
    let packages: [DictionaryTransferPackage]
    let format: ExportFormat
    let sourceName: String
}

struct DictionaryImportSummary {
    let importedWordCount: Int
    let duplicateCount: Int
    let importedDictionaryCount: Int
    let format: ExportFormat
}

private struct DictionaryExportBundle: Codable {
    let version: Int
    let exportedAt: String
    let app: String
    let dictionaries: [DictionaryExportPayload]?
    let words: [DictionaryExportWordPayload]?
    let sets: [String]
    let tags: [String]

    private enum CodingKeys: String, CodingKey {
        case version
        case schemaVersion
        case exportedAt
        case app
        case dictionaries
        case words
        case sets
        case tags
    }

    init(
        version: Int,
        exportedAt: String,
        app: String,
        dictionaries: [DictionaryExportPayload]?,
        words: [DictionaryExportWordPayload]?,
        sets: [String],
        tags: [String]
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.app = app
        self.dictionaries = dictionaries
        self.words = words
        self.sets = sets
        self.tags = tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version)
            ?? container.decodeIfPresent(Int.self, forKey: .schemaVersion)
            ?? 1
        exportedAt = try container.decodeIfPresent(String.self, forKey: .exportedAt) ?? ""
        app = try container.decodeIfPresent(String.self, forKey: .app) ?? "Wordy"
        dictionaries = try container.decodeIfPresent([DictionaryExportPayload].self, forKey: .dictionaries)
        words = try container.decodeIfPresent([DictionaryExportWordPayload].self, forKey: .words)
        sets = try container.decodeIfPresent([String].self, forKey: .sets) ?? []
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(exportedAt, forKey: .exportedAt)
        try container.encode(app, forKey: .app)
        try container.encodeIfPresent(dictionaries, forKey: .dictionaries)
        try container.encodeIfPresent(words, forKey: .words)
        try container.encode(sets, forKey: .sets)
        try container.encode(tags, forKey: .tags)
    }
}

private struct DictionaryExportPayload: Codable {
    let id: String?
    let name: String
    let createdAt: String
    let words: [DictionaryExportWordPayload]
}

private struct DictionaryExportWordPayload: Codable {
    let id: String?
    let original: String
    let normalizedText: String?
    let translation: String
    let mainTranslation: String?
    let translations: [TranslationOption]?
    let transcription: String?
    let pronunciation: String?
    let exampleSentence: String?
    let languagePair: String
    let sourceLanguage: String
    let targetLanguage: String
    let examples: [WordExample]?
    let synonyms: [WordSynonym]?
    let antonyms: [WordSynonym]?
    let meanings: [MeaningContent]?
    let wordForms: [WordForm]?
    let wordFormGroups: [WordFormGroup]?
    let relatedTopics: [RelatedTopic]?
    let relatedPhrases: [RelatedPhrase]?
    let partOfSpeech: String?
    let gender: String?
    let tags: [String]?
    let setIds: [String]?
    let note: String?
    let wordCard: WordCard?
    let selectedTranslationOptionIds: [String]?
    let selectedExampleIds: [String]?
    let selectedSynonymIds: [String]?
    let isLearned: Bool
    let reviewCount: Int
    let srsInterval: Double
    let srsRepetition: Int
    let srsEasinessFactor: Double
    let nextReviewDate: String?
    let lastReviewDate: String?
    let averageQuality: Double
    let createdAt: String
    let updatedAt: String?
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
    
    var contentType: UTType {
        switch self {
        case .json: return .json
        case .csv: return .commaSeparatedText
        case .txt: return .plainText
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
enum DictionaryExportService {
    
    // MARK: - Export Methods

    static func exportPackages(
        _ packages: [DictionaryTransferPackage],
        scopeName: String,
        format: ExportFormat = .json,
        language: AppLanguage = .english
    ) async throws -> URL {
        let nonEmptyPackages = packages.filter { !$0.words.isEmpty }
        guard !nonEmptyPackages.isEmpty else {
            throw ExportImportError.noWordsToExport
        }

        let data: Data
        switch format {
        case .json:
            data = try exportStructuredJSON(nonEmptyPackages)
        case .csv:
            data = try exportStructuredCSV(nonEmptyPackages, language: language)
        case .txt:
            data = try exportStructuredTXT(nonEmptyPackages, language: language)
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let dateString = dateFormatter.string(from: Date())

        let safeScope = sanitizedFileComponent(scopeName)
        let filename = "wordy_\(safeScope)_\(dateString).\(format.fileExtension)"
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
    
    static func exportWords(
        _ words: [SavedWordModel],
        format: ExportFormat = .json,
        language: AppLanguage = .english
    ) async throws -> URL {
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

    static func importPackages(
        from urls: [URL],
        language: AppLanguage = .english
    ) async throws -> [ParsedDictionaryImport] {
        guard !urls.isEmpty else {
            throw ExportImportError.noWordsImported
        }

        var parsed: [ParsedDictionaryImport] = []
        for url in urls {
            parsed.append(try await importPackages(from: url, language: language))
        }
        return parsed
    }
    
    // MARK: - JSON Export
    
    private static func exportJSON(_ words: [SavedWordModel], language: AppLanguage) throws -> Data {
        _ = language
        let package = DictionaryTransferPackage(
            dictionaryName: "Wordy",
            createdAt: Date(),
            sourceDictionaryId: nil,
            words: words
        )
        return try exportStructuredJSON([package])
    }
    
    // MARK: - CSV Export
    
    private static func exportCSV(_ words: [SavedWordModel], language: AppLanguage) throws -> Data {
        var lines: [String] = []
        
        let header: String
        switch language {
        case .ukrainian:
            header = "Слово;Основний переклад;Мова джерела;Мова перекладу;Частина мови;Приклад;Теги;Набори;Наступне повторення"
        case .polish:
            header = "Slowo;Glowne tlumaczenie;Jezyk zrodla;Jezyk docelowy;Czesc mowy;Przyklad;Tagi;Zestawy;Nastepna powtorka"
        case .english:
            header = "originalText;mainTranslation;sourceLanguage;targetLanguage;partOfSpeech;example;tags;setNames;nextReviewDate"
        }
        lines.append(header)
        
        for word in words {
            let example = word.examples.first?.sourceText ?? word.exampleSentence ?? ""
            let pos = word.partOfSpeech ?? word.wordCard?.translations.first?.partOfSpeech ?? ""
            let nextReview = word.nextReviewDate?.ISO8601Format() ?? ""
            lines.append([
                escapeCSV(word.original),
                escapeCSV(word.mainTranslation),
                escapeCSV(word.sourceLanguage),
                escapeCSV(word.targetLanguage),
                escapeCSV(pos),
                escapeCSV(example),
                escapeCSV(word.tags.joined(separator: ", ")),
                escapeCSV(word.setIds.joined(separator: ", ")),
                escapeCSV(nextReview)
            ].joined(separator: ";"))
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
            
            // Додаємо languagePair для можливості відновлення
            lines.append("   [\(word.languagePair)]")
            
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

    private static func exportStructuredJSON(_ packages: [DictionaryTransferPackage]) throws -> Data {
        let isoFormatter = ISO8601DateFormatter()
        let bundle = DictionaryExportBundle(
            version: 2,
            exportedAt: isoFormatter.string(from: Date()),
            app: "Wordy",
            dictionaries: packages.map { package in
                DictionaryExportPayload(
                    id: package.sourceDictionaryId,
                    name: package.dictionaryName,
                    createdAt: isoFormatter.string(from: package.createdAt),
                    words: package.words.map { word in
                        DictionaryExportWordPayload(
                            id: word.id,
                            original: word.original,
                            normalizedText: word.normalizedText,
                            translation: word.translation,
                            mainTranslation: word.mainTranslation,
                            translations: word.translations,
                            transcription: word.transcription,
                            pronunciation: word.pronunciation,
                            exampleSentence: word.exampleSentence,
                            languagePair: word.languagePair,
                            sourceLanguage: word.sourceLanguage,
                            targetLanguage: word.targetLanguage,
                            examples: word.examples,
                            synonyms: word.synonyms,
                            antonyms: word.antonyms,
                            meanings: word.meanings,
                            wordForms: word.wordForms,
                            wordFormGroups: word.wordFormGroups,
                            relatedTopics: word.relatedTopics,
                            relatedPhrases: word.relatedPhrases,
                            partOfSpeech: word.partOfSpeech,
                            gender: word.gender,
                            tags: word.tags,
                            setIds: word.setIds,
                            note: word.note,
                            wordCard: word.wordCard,
                            selectedTranslationOptionIds: word.selectedTranslationOptionIds,
                            selectedExampleIds: word.selectedExampleIds,
                            selectedSynonymIds: word.selectedSynonymIds,
                            isLearned: word.isLearned,
                            reviewCount: word.reviewCount,
                            srsInterval: word.srsInterval,
                            srsRepetition: word.srsRepetition,
                            srsEasinessFactor: word.srsEasinessFactor,
                            nextReviewDate: word.nextReviewDate.map { isoFormatter.string(from: $0) },
                            lastReviewDate: word.lastReviewDate.map { isoFormatter.string(from: $0) },
                            averageQuality: word.averageQuality,
                            createdAt: isoFormatter.string(from: word.createdAt),
                            updatedAt: isoFormatter.string(from: word.updatedAt)
                        )
                    }
                )
            },
            words: nil,
            sets: Array(Set(packages.flatMap { $0.words.flatMap(\.setIds) })).sorted(),
            tags: Array(Set(packages.flatMap { $0.words.flatMap(\.tags) })).sorted()
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(bundle)
    }

    private static func exportStructuredCSV(
        _ packages: [DictionaryTransferPackage],
        language: AppLanguage
    ) throws -> Data {
        var lines: [String] = []
        let header: String

        switch language {
        case .ukrainian:
            header = "Словник;Слово;Транскрипція;Переклад;Приклад;Мова"
        case .polish:
            header = "Słownik;Słowo;Transkrypcja;Tłumaczenie;Przykład;Język"
        case .english:
            header = "Dictionary;Word;Transcription;Translation;Example;Language"
        }

        lines.append(header)

        for package in packages {
            for word in package.words {
                lines.append([
                    escapeCSV(package.dictionaryName),
                    escapeCSV(word.original),
                    escapeCSV(word.transcription ?? ""),
                    escapeCSV(word.translation),
                    escapeCSV(word.exampleSentence ?? ""),
                    escapeCSV(word.languagePair)
                ].joined(separator: ";"))
            }
        }

        guard let data = lines.joined(separator: "\n").data(using: .utf8) else {
            throw ExportImportError.encodingFailed
        }
        return data
    }

    private static func exportStructuredTXT(
        _ packages: [DictionaryTransferPackage],
        language: AppLanguage
    ) throws -> Data {
        var lines: [String] = []
        let title: String
        let dictionaryLabel: String

        switch language {
        case .ukrainian:
            title = "📚 Експорт словників Wordy"
            dictionaryLabel = "Словник"
        case .polish:
            title = "📚 Eksport słowników Wordy"
            dictionaryLabel = "Słownik"
        case .english:
            title = "📚 Wordy Dictionary Export"
            dictionaryLabel = "Dictionary"
        }

        lines.append(title)
        lines.append("")

        for package in packages {
            lines.append("## \(dictionaryLabel): \(package.dictionaryName)")
            for (index, word) in package.words.enumerated() {
                let transcription = (word.transcription ?? "").isEmpty ? "" : " [\(word.transcription!)]"
                lines.append("\(index + 1). \(word.original)\(transcription) - \(word.translation)")
                lines.append("   [\(word.languagePair)]")
                if let example = word.exampleSentence, !example.isEmpty {
                    lines.append("   • \(example)")
                }
                lines.append("")
            }
        }

        guard let data = lines.joined(separator: "\n").data(using: .utf8) else {
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

    private static func sanitizedFileComponent(_ value: String) -> String {
        let cleaned = value
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9а-яіїєґ]+", with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        return cleaned.isEmpty ? "dictionary" : cleaned
    }
    
    // MARK: - Import Methods

    private static func importPackages(
        from url: URL,
        language: AppLanguage
    ) async throws -> ParsedDictionaryImport {
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

        let fallbackName = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension.lowercased()

        switch ext {
        case "json":
            if let structured = try? importStructuredJSONPackages(data) {
                return ParsedDictionaryImport(packages: structured, format: .json, sourceName: fallbackName)
            }
            let words = try await importJSON(data, language: language)
            return ParsedDictionaryImport(
                packages: [DictionaryTransferPackage(dictionaryName: fallbackName, createdAt: Date(), sourceDictionaryId: nil, words: words)],
                format: .json,
                sourceName: fallbackName
            )
        case "csv":
            return ParsedDictionaryImport(
                packages: try importStructuredCSVPackages(data, fallbackName: fallbackName),
                format: .csv,
                sourceName: fallbackName
            )
        case "txt":
            return ParsedDictionaryImport(
                packages: try await importStructuredTXTPackages(data, fallbackName: fallbackName, language: language),
                format: .txt,
                sourceName: fallbackName
            )
        default:
            if let structured = try? importStructuredJSONPackages(data) {
                return ParsedDictionaryImport(packages: structured, format: .json, sourceName: fallbackName)
            }
            if let csvPackages = try? importStructuredCSVPackages(data, fallbackName: fallbackName) {
                return ParsedDictionaryImport(packages: csvPackages, format: .csv, sourceName: fallbackName)
            }
            let words = try await importTXT(data, language: language)
            return ParsedDictionaryImport(
                packages: [DictionaryTransferPackage(dictionaryName: fallbackName, createdAt: Date(), sourceDictionaryId: nil, words: words)],
                format: .txt,
                sourceName: fallbackName
            )
        }
    }

    static func importWords(
        from url: URL,
        existingWords: [SavedWordModel] = [], // НОВЕ: для перевірки дублікатів
        language: AppLanguage = .english
    ) async throws -> ImportResult {
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
        
        // НОВЕ: Фільтрація дублікатів
        let existingKeys = Set(existingWords.map {
            [
                $0.normalizedText.lowercased(),
                $0.sourceLanguage.lowercased(),
                $0.targetLanguage.lowercased()
            ].joined(separator: "|")
        })
        var uniqueWords: [SavedWordModel] = []
        var duplicateCount = 0
        
        for word in words {
            let key = [
                word.normalizedText.lowercased(),
                word.sourceLanguage.lowercased(),
                word.targetLanguage.lowercased()
            ].joined(separator: "|")

            if existingKeys.contains(key) {
                duplicateCount += 1
            } else {
                uniqueWords.append(word)
            }
        }
        
        return ImportResult(
            importedCount: uniqueWords.count,
            duplicateCount: duplicateCount,
            skippedCount: 0,
            format: format,
            words: uniqueWords
        )
    }

    private static func importStructuredJSONPackages(_ data: Data) throws -> [DictionaryTransferPackage] {
        let decoder = JSONDecoder()
        let bundle = try decoder.decode(DictionaryExportBundle.self, from: data)
        let isoFormatter = ISO8601DateFormatter()

        if let standaloneWords = bundle.words, !standaloneWords.isEmpty {
            let words = standaloneWords.map { word in
                SavedWordModel(
                    id: word.id ?? UUID().uuidString,
                    original: word.original,
                    translation: word.translation,
                    normalizedText: word.normalizedText,
                    mainTranslation: word.mainTranslation,
                    translations: word.translations ?? [],
                    transcription: word.transcription,
                    pronunciation: word.pronunciation,
                    exampleSentence: word.exampleSentence,
                    languagePair: word.languagePair,
                    sourceLanguage: word.sourceLanguage,
                    targetLanguage: word.targetLanguage,
                    examples: word.examples ?? [],
                    synonyms: word.synonyms ?? [],
                    antonyms: word.antonyms ?? [],
                    meanings: word.meanings ?? [],
                    wordForms: word.wordForms ?? [],
                    wordFormGroups: word.wordFormGroups ?? [],
                    relatedTopics: word.relatedTopics ?? [],
                    relatedPhrases: word.relatedPhrases ?? [],
                    partOfSpeech: word.partOfSpeech,
                    gender: word.gender,
                    tags: word.tags ?? [],
                    setIds: word.setIds ?? [],
                    note: word.note,
                    dictionaryId: nil,
                    isLearned: word.isLearned,
                    reviewCount: word.reviewCount,
                    srsInterval: word.srsInterval,
                    srsRepetition: word.srsRepetition,
                    srsEasinessFactor: word.srsEasinessFactor,
                    nextReviewDate: word.nextReviewDate.flatMap { isoFormatter.date(from: $0) },
                    lastReviewDate: word.lastReviewDate.flatMap { isoFormatter.date(from: $0) },
                    averageQuality: word.averageQuality,
                    createdAt: isoFormatter.date(from: word.createdAt) ?? Date(),
                    updatedAt: word.updatedAt.flatMap { isoFormatter.date(from: $0) } ?? Date(),
                    wordCard: word.wordCard,
                    selectedTranslationOptionIds: word.selectedTranslationOptionIds ?? [],
                    selectedExampleIds: word.selectedExampleIds ?? [],
                    selectedSynonymIds: word.selectedSynonymIds ?? []
                )
            }

            return [
                DictionaryTransferPackage(
                    dictionaryName: "Imported",
                    createdAt: Date(),
                    sourceDictionaryId: nil,
                    words: words
                )
            ]
        }

        let packages = (bundle.dictionaries ?? []).map { dictionary in
            DictionaryTransferPackage(
                dictionaryName: dictionary.name,
                createdAt: isoFormatter.date(from: dictionary.createdAt) ?? Date(),
                sourceDictionaryId: dictionary.id,
                words: dictionary.words.map { word in
                    SavedWordModel(
                        id: word.id ?? UUID().uuidString,
                        original: word.original,
                        translation: word.translation,
                        normalizedText: word.normalizedText,
                        mainTranslation: word.mainTranslation,
                        translations: word.translations ?? [],
                        transcription: word.transcription,
                        pronunciation: word.pronunciation,
                        exampleSentence: word.exampleSentence,
                        languagePair: word.languagePair,
                        sourceLanguage: word.sourceLanguage,
                        targetLanguage: word.targetLanguage,
                        examples: word.examples ?? [],
                        synonyms: word.synonyms ?? [],
                        antonyms: word.antonyms ?? [],
                        meanings: word.meanings ?? [],
                        wordForms: word.wordForms ?? [],
                        wordFormGroups: word.wordFormGroups ?? [],
                        relatedTopics: word.relatedTopics ?? [],
                        relatedPhrases: word.relatedPhrases ?? [],
                        partOfSpeech: word.partOfSpeech,
                        gender: word.gender,
                        tags: word.tags ?? [],
                        setIds: word.setIds ?? [],
                        note: word.note,
                        dictionaryId: nil,
                        isLearned: word.isLearned,
                        reviewCount: word.reviewCount,
                        srsInterval: word.srsInterval,
                        srsRepetition: word.srsRepetition,
                        srsEasinessFactor: word.srsEasinessFactor,
                        nextReviewDate: word.nextReviewDate.flatMap { isoFormatter.date(from: $0) },
                        lastReviewDate: word.lastReviewDate.flatMap { isoFormatter.date(from: $0) },
                        averageQuality: word.averageQuality,
                        createdAt: isoFormatter.date(from: word.createdAt) ?? Date(),
                        updatedAt: word.updatedAt.flatMap { isoFormatter.date(from: $0) } ?? Date(),
                        wordCard: word.wordCard,
                        selectedTranslationOptionIds: word.selectedTranslationOptionIds ?? [],
                        selectedExampleIds: word.selectedExampleIds ?? [],
                        selectedSynonymIds: word.selectedSynonymIds ?? []
                    )
                }
            )
        }

        guard !packages.isEmpty else {
            throw ExportImportError.noWordsImported
        }

        return packages
    }

    private static func importStructuredCSVPackages(
        _ data: Data,
        fallbackName: String
    ) throws -> [DictionaryTransferPackage] {
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw ExportImportError.encodingFailed
        }

        let lines = csvString.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard lines.count > 1 else {
            throw ExportImportError.invalidCSVFormat
        }

        let header = parseCSVLine(lines[0]).map { $0.lowercased() }
        let hasDictionaryColumn = header.first.map { $0.contains("dictionary") || $0.contains("словник") || $0.contains("słownik") } ?? false
        let originalIndex = hasDictionaryColumn ? 1 : 0
        let transcriptionIndex = hasDictionaryColumn ? 2 : 1
        let translationIndex = hasDictionaryColumn ? 3 : 2
        let exampleIndex = hasDictionaryColumn ? 4 : 3
        let languageIndex = max(header.count - 1, hasDictionaryColumn ? 5 : 4)

        var groupedWords: [String: [SavedWordModel]] = [:]

        for line in lines.dropFirst() {
            let columns = parseCSVLine(line)
            guard columns.indices.contains(originalIndex),
                  columns.indices.contains(translationIndex) else {
                continue
            }

            let dictionaryName = hasDictionaryColumn ? columns[0] : fallbackName

            let word = SavedWordModel(
                id: UUID().uuidString,
                original: columns[originalIndex],
                translation: columns[translationIndex],
                transcription: columns.indices.contains(transcriptionIndex) && !columns[transcriptionIndex].isEmpty ? columns[transcriptionIndex] : nil,
                exampleSentence: columns.indices.contains(exampleIndex) && !columns[exampleIndex].isEmpty ? columns[exampleIndex] : nil,
                languagePair: columns.indices.contains(languageIndex) && !columns[languageIndex].isEmpty ? columns[languageIndex] : "en-uk",
                sourceLanguage: languagePairSource(columns.indices.contains(languageIndex) && !columns[languageIndex].isEmpty ? columns[languageIndex] : "en-uk"),
                targetLanguage: languagePairTarget(columns.indices.contains(languageIndex) && !columns[languageIndex].isEmpty ? columns[languageIndex] : "en-uk"),
                dictionaryId: nil,
                createdAt: Date()
            )

            groupedWords[dictionaryName, default: []].append(word)
        }

        let packages = groupedWords.map { name, words in
            DictionaryTransferPackage(dictionaryName: name, createdAt: Date(), sourceDictionaryId: nil, words: words)
        }
        .sorted { $0.dictionaryName.localizedCaseInsensitiveCompare($1.dictionaryName) == .orderedAscending }

        guard !packages.isEmpty else {
            throw ExportImportError.noWordsImported
        }

        return packages
    }

    private static func importStructuredTXTPackages(
        _ data: Data,
        fallbackName: String,
        language: AppLanguage
    ) async throws -> [DictionaryTransferPackage] {
        guard let txtString = String(data: data, encoding: .utf8) else {
            throw ExportImportError.encodingFailed
        }

        let lines = txtString.components(separatedBy: .newlines)
        var groupedRawLines: [String: [String]] = [:]
        var currentDictionary = fallbackName

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("## ") {
                if let range = trimmed.range(of: ":") {
                    currentDictionary = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                continue
            }

            groupedRawLines[currentDictionary, default: []].append(line)
        }

        var packages: [DictionaryTransferPackage] = []
        for (name, rawLines) in groupedRawLines {
            let groupString = rawLines.joined(separator: "\n")
            let words = try await importTXT(groupString.data(using: .utf8) ?? Data(), language: language)
            if !words.isEmpty {
                packages.append(
                    DictionaryTransferPackage(dictionaryName: name, createdAt: Date(), sourceDictionaryId: nil, words: words)
                )
            }
        }

        if packages.isEmpty {
            let words = try await importTXT(data, language: language)
            return [DictionaryTransferPackage(dictionaryName: fallbackName, createdAt: Date(), sourceDictionaryId: nil, words: words)]
        }

        return packages.sorted { $0.dictionaryName.localizedCaseInsensitiveCompare($1.dictionaryName) == .orderedAscending }
    }
    
    // MARK: - JSON Import
    
    private static func importJSON(_ data: Data, language: AppLanguage) async throws -> [SavedWordModel] {
        if let packages = try? importStructuredJSONPackages(data) {
            return packages.flatMap(\.words)
        }

        _ = language
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
                sourceLanguage: item["sourceLanguage"] as? String,
                targetLanguage: item["targetLanguage"] as? String,
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
        var currentLanguagePair = "en-uk"
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
                languagePair: currentLanguagePair,
                sourceLanguage: languagePairSource(currentLanguagePair),
                targetLanguage: languagePairTarget(currentLanguagePair),
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
                currentLanguagePair = columns.count > 5 && !columns[5].isEmpty ? columns[5] : "en-uk"
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
            
            var languagePair = "en-uk"
            var examples: [String] = []
            
            i += 1
            while i < lines.count {
                let nextLine = lines[i]
                
                // Перевіряємо чи це рядок з languagePair
                if nextLine.hasPrefix("[") && nextLine.hasSuffix("]") && nextLine.count < 10 {
                    languagePair = String(nextLine.dropFirst().dropLast())
                    i += 1
                    continue
                }
                
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
                languagePair: languagePair,
                sourceLanguage: languagePairSource(languagePair),
                targetLanguage: languagePairTarget(languagePair),
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

    private static func languagePairSource(_ pair: String) -> String {
        pair.components(separatedBy: "-").first ?? "en"
    }

    private static func languagePairTarget(_ pair: String) -> String {
        let components = pair.components(separatedBy: "-")
        return components.count > 1 ? components[1] : "uk"
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
