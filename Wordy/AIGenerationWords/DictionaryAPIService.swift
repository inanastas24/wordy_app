//
//  DictionaryAPIService.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 09.03.2026.
//

import Foundation

class DictionaryAPIService {
    static let shared = DictionaryAPIService()
    
    private let baseURL = "https://api.dictionaryapi.dev/api/v2/entries"
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Fetch Word Details
    
    func fetchWordDetails(
        word: String,
        language: String = "en"
    ) async throws -> WordDetails {
        let encodedWord = word.lowercased().addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? word.lowercased()
        let urlString = "\(baseURL)/\(language)/\(encodedWord)"
        
        guard let url = URL(string: urlString) else {
            throw DictionaryError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DictionaryError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            let entries = try JSONDecoder().decode([DictionaryEntry].self, from: data)
            guard let entry = entries.first else {
                throw DictionaryError.wordNotFound
            }
            return try parseEntryToWordDetails(entry, originalWord: word)
        case 404:
            throw DictionaryError.wordNotFound
        default:
            throw DictionaryError.apiError("Status code: \(httpResponse.statusCode)")
        }
    }
    
    // MARK: - Batch Fetch (для завантаження набору)
    
    func fetchWordsBatch(
        words: [String],
        language: String = "en",
        progressHandler: ((Int, Int) -> Void)? = nil
    ) async throws -> [WordDetails] {
        var results: [WordDetails] = []
        let total = words.count
        
        for (index, word) in words.enumerated() {
            do {
                let details = try await fetchWordDetails(word: word, language: language)
                results.append(details)
                progressHandler?(index + 1, total)
                
                // Невелика затримка щоб не перевантажити API
                if index < total - 1 {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 сек
                }
            } catch {
                print("Failed to fetch '\(word)': \(error.localizedDescription)")
                // Продовжуємо з наступним словом, не падаємо
            }
        }
        
        return results
    }
    
    // MARK: - Search with Suggestions
    
    func searchSimilarWords(
        query: String,
        language: String = "en"
    ) async throws -> [String] {
        // API не має пошуку, тому пробуємо прямий запит
        // і повертаємо близькі варіанти якщо слово не знайдено
        
        do {
            let _ = try await fetchWordDetails(word: query, language: language)
            return [query]
        } catch DictionaryError.wordNotFound {
            // Пробуємо варіанти з закінченнями
            let variations = generateVariations(query)
            var found: [String] = []
            
            for variation in variations {
                do {
                    let _ = try await fetchWordDetails(word: variation, language: language)
                    found.append(variation)
                    if found.count >= 5 { break }
                } catch {
                    continue
                }
            }
            
            return found
        }
    }
    
    // MARK: - Parsing
    
    private func parseEntryToWordDetails(
        _ entry: DictionaryEntry,
        originalWord: String
    ) throws -> WordDetails {
        
        // Знаходимо найкращу транскрипцію
        let phonetic = entry.phonetics?.first { $0.audio != nil }?.text
            ?? entry.phonetics?.first?.text
            ?? entry.phonetic
        
        // Знаходимо аудіо URL
        let audioURL = entry.phonetics?.first { $0.audio?.isEmpty == false }?.audio
        
        // Збираємо значення та приклади
        var definitions: [String] = []
        var examples: [String] = []
        var synonyms: [String] = []
        var antonyms: [String] = []
        
        for meaning in entry.meanings {
            for def in meaning.definitions {
                if !definitions.contains(def.definition) {
                    definitions.append(def.definition)
                }
                if let example = def.example, !examples.contains(example) {
                    examples.append(example)
                }
                synonyms.append(contentsOf: def.synonyms ?? [])
                antonyms.append(contentsOf: def.antonyms ?? [])
            }
        }
        
        // Обмежуємо кількість
        let limitedDefinitions = Array(definitions.prefix(3))
        let limitedExamples = Array(examples.prefix(2))
        let limitedSynonyms = Array(synonyms.uniqued().prefix(5))
        
        return WordDetails(
            id: "api_\(originalWord.lowercased())_\(UUID().uuidString.prefix(8))",
            original: originalWord,
            translation: "", // Буде заповнено через переклад
            transcription: phonetic,
            audioURL: audioURL,
            definitions: limitedDefinitions,
            examples: limitedExamples,
            synonyms: limitedSynonyms,
            antonyms: antonyms,
            partOfSpeech: entry.meanings.first?.partOfSpeech,
            source: "free_dictionary_api"
        )
    }
    
    private func generateVariations(_ word: String) -> [String] {
        let base = word.lowercased()
        return [
            base,
            base + "s",      // множина
            base + "es",
            base + "ed",     // минуле
            base + "ing",    // дієприкметник
            String(base.dropLast()), // без останньої літери
            base.replacingOccurrences(of: "y", with: "ie") + "s",
            base.replacingOccurrences(of: "f", with: "ves"),
        ]
    }
}

// MARK: - Models

struct WordDetails: Identifiable, Codable {
    let id: String
    let original: String
    var translation: String
    let transcription: String?
    let audioURL: String?
    let definitions: [String]
    let examples: [String]
    let synonyms: [String]
    let antonyms: [String]
    let partOfSpeech: String?
    let source: String
    
    // Конвертація в локальний формат Word
    func toLocalWord(
        translation: String,
        exampleTranslation: String? = nil
    ) -> Word {
        Word(
            id: id,
            original: original,
            translation: translation,
            transcription: transcription,
            exampleSentence: examples.first,
            exampleTranslation: exampleTranslation,
            synonyms: synonyms,
            difficulty: .b1, // API не дає рівня, встановлюємо середній
            audioUrl: audioURL
        )
    }
}

// MARK: - API Response Models

struct DictionaryEntry: Codable {
    let word: String
    let phonetic: String?
    let phonetics: [Phonetic]?
    let meanings: [Meaning]
    let license: License?
    let sourceUrls: [String]?
}

struct Phonetic: Codable {
    let text: String?
    let audio: String?
    let sourceUrl: String?
    let license: License?
}

struct Meaning: Codable {
    let partOfSpeech: String
    let definitions: [Definition]
    let synonyms: [String]?
    let antonyms: [String]?
}

struct Definition: Codable {
    let definition: String
    let synonyms: [String]?
    let antonyms: [String]?
    let example: String?
}

struct License: Codable {
    let name: String
    let url: String
}

enum DictionaryError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case wordNotFound
    case apiError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .wordNotFound:
            return "Word not found in dictionary"
        case .apiError(let message):
            return "API Error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Extensions

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
