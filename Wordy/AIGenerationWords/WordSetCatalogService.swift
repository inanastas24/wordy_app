import FirebaseFunctions
import Foundation

/// Errors related to generating or fetching catalog content
enum GenerationError: Error {
    /// The response from a remote call was not in the expected format
    case invalidResponse
    /// A required value was missing from the server response
    case missingField(String)
    /// The server indicated a failure with a message
    case server(String)
}

@MainActor
final class WordSetCatalogService {
    static let shared = WordSetCatalogService()

    private let functions = Functions.functions()
    private var overviewCache: [String: WordSetCatalogOverview] = [:]
    private var wordsCache: [String: [Word]] = [:]
    private var searchCache: [String: [Word]] = [:]

    private init() {}

    func fetchOverview(languagePair: LanguagePair, forceRefresh: Bool = false) async throws -> WordSetCatalogOverview {
        let cacheKey = languagePair.languagePairString
        if !forceRefresh, let cached = overviewCache[cacheKey] {
            return cached
        }

        let data = try await performCall("getCatalogOverview", payload: [
            "sourceLanguage": languagePair.source.rawValue,
            "targetLanguage": languagePair.target.rawValue
        ])

        let overview = try parseOverview(data)
        overviewCache[cacheKey] = overview
        return overview
    }

    func fetchWords(
        category: WordCategory,
        difficulty: DifficultyLevel?,
        languagePair: LanguagePair,
        limit: Int = 250
    ) async throws -> [Word] {
        let cacheKey = wordsCacheKey(
            languagePair: languagePair,
            category: category.rawValue,
            difficulty: difficulty,
            limit: limit
        )

        if let cached = wordsCache[cacheKey] {
            return cached
        }

        var payload: [String: Any] = [
            "sourceLanguage": languagePair.source.rawValue,
            "targetLanguage": languagePair.target.rawValue,
            "category": category.rawValue,
            "limit": limit
        ]

        if let difficulty {
            payload["difficulty"] = difficulty.rawValue
        }

        let data = try await performCall("getCatalogWords", payload: payload)
        let words = try parseWords(from: data, fallbackCategory: category, languagePair: languagePair.languagePairString)
        wordsCache[cacheKey] = words
        return words
    }

    func fetchWords(
        difficulty: DifficultyLevel,
        languagePair: LanguagePair,
        limit: Int = 1000
    ) async throws -> [Word] {
        let cacheKey = wordsCacheKey(
            languagePair: languagePair,
            category: nil,
            difficulty: difficulty,
            limit: limit
        )

        if let cached = wordsCache[cacheKey] {
            return cached
        }

        let data = try await performCall("getCatalogWords", payload: [
            "sourceLanguage": languagePair.source.rawValue,
            "targetLanguage": languagePair.target.rawValue,
            "difficulty": difficulty.rawValue,
            "limit": limit
        ])

        let words = try parseWords(from: data, fallbackCategory: nil, languagePair: languagePair.languagePairString)
        wordsCache[cacheKey] = words
        return words
    }

    func searchWords(query: String, languagePair: LanguagePair, limit: Int = 20) async throws -> [Word] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let cacheKey = searchCacheKey(languagePair: languagePair, query: trimmedQuery, limit: limit)

        if let cached = searchCache[cacheKey] {
            return cached
        }

        let data = try await performCall("searchCatalogWords", payload: [
            "sourceLanguage": languagePair.source.rawValue,
            "targetLanguage": languagePair.target.rawValue,
            "query": trimmedQuery,
            "limit": limit
        ])

        let words = try parseWords(from: data, fallbackCategory: nil, languagePair: languagePair.languagePairString)
        searchCache[cacheKey] = words
        return words
    }

    func invalidateCache(for languagePair: LanguagePair? = nil) {
        guard let languagePair else {
            overviewCache.removeAll()
            wordsCache.removeAll()
            searchCache.removeAll()
            return
        }

        let pairKey = languagePair.languagePairString
        overviewCache.removeValue(forKey: pairKey)
        wordsCache = wordsCache.filter { !$0.key.hasPrefix("\(pairKey)|") }
        searchCache = searchCache.filter { !$0.key.hasPrefix("\(pairKey)|") }
    }

    private func parseOverview(_ data: [String: Any]) throws -> WordSetCatalogOverview {
        let languagePair = data["languagePair"] as? String ?? "en-uk"
        let categoriesData = data["categories"] as? [[String: Any]] ?? []
        let setsData = data["difficultySets"] as? [[String: Any]] ?? []
        let hasRemoteContent = data["hasRemoteContent"] as? Bool ?? false

        let categories = categoriesData.compactMap(parseCategorySummary)
        let sets = setsData.compactMap { parseSet($0, languagePair: languagePair) }

        return WordSetCatalogOverview(
            languagePair: languagePair,
            categories: categories,
            difficultySets: sets,
            hasRemoteContent: hasRemoteContent
        )
    }

    private func parseWords(
        from data: [String: Any],
        fallbackCategory: WordCategory?,
        languagePair: String
    ) throws -> [Word] {
        guard let wordsData = data["words"] as? [[String: Any]] else {
            throw GenerationError.invalidResponse
        }

        return wordsData.compactMap {
            parseWord($0, fallbackCategory: fallbackCategory, languagePair: languagePair)
        }
    }

    private func parseCategorySummary(_ data: [String: Any]) -> WordSetCategorySummary? {
        let id = data["id"] as? String ?? UUID().uuidString
        let rawCategory = data["category"] as? String ?? id
        guard let category = WordCategory(rawValue: rawCategory) else { return nil }

        let difficulties = (data["supportedDifficulties"] as? [String] ?? [])
            .compactMap(DifficultyLevel.init(rawValue:))

        return WordSetCategorySummary(
            id: id,
            category: category,
            title: data["title"] as? String ?? rawCategory.capitalized,
            emoji: data["emoji"] as? String ?? category.defaultEmoji,
            gradientColors: data["gradientColors"] as? [String] ?? ["#4ECDC4", "#6C5CE7"],
            wordCount: data["wordCount"] as? Int ?? 0,
            supportedDifficulties: difficulties
        )
    }

    private func parseSet(_ data: [String: Any], languagePair: String) -> WordSet? {
        let id = data["id"] as? String ?? UUID().uuidString
        let titleKey = data["titleKey"] as? String ?? id
        let difficultyString = data["difficulty"] as? String ?? "a1"
        guard let difficulty = DifficultyLevel(rawValue: difficultyString) else { return nil }
        let category = WordCategory(rawValue: data["category"] as? String ?? "basics") ?? .basics

        return WordSet(
            id: id,
            titleKey: titleKey,
            titleLocalized: data["titleLocalized"] as? [String: String] ?? ["en": titleKey],
            emoji: data["emoji"] as? String ?? category.defaultEmoji,
            gradientColors: data["gradientColors"] as? [String] ?? ["#4ECDC4", "#6C5CE7"],
            difficulty: difficulty,
            category: category,
            wordCount: data["wordCount"] as? Int ?? 0,
            words: [],
            languagePair: languagePair
        )
    }

    private func parseWord(
        _ data: [String: Any],
        fallbackCategory: WordCategory?,
        languagePair: String
    ) -> Word? {
        guard let id = data["id"] as? String,
              let original = data["original"] as? String,
              let translation = data["translation"] as? String else {
            return nil
        }

        let rawDifficulty = data["difficulty"] as? String ?? "a1"
        let difficulty = DifficultyLevel(rawValue: rawDifficulty) ?? .a1
        let category = WordCategory(rawValue: data["category"] as? String ?? "") ?? fallbackCategory

        return Word(
            id: id,
            original: original,
            translation: translation,
            transcription: data["transcription"] as? String,
            exampleSentence: data["exampleSentence"] as? String,
            exampleTranslation: data["exampleTranslation"] as? String,
            synonyms: data["synonyms"] as? [String] ?? [],
            difficulty: difficulty,
            category: category,
            languagePair: data["languagePair"] as? String ?? languagePair,
            audioUrl: data["audioUrl"] as? String
        )
    }

    private func performCall(_ name: String, payload: [String: Any]) async throws -> [String: Any] {
        let result = try await functions.httpsCallable(name).call(payload)

        guard let data = result.data as? [String: Any] else {
            throw GenerationError.invalidResponse
        }

        return data
    }

    private func wordsCacheKey(
        languagePair: LanguagePair,
        category: String?,
        difficulty: DifficultyLevel?,
        limit: Int
    ) -> String {
        "\(languagePair.languagePairString)|\(category ?? "all")|\(difficulty?.rawValue ?? "all")|\(limit)"
    }

    private func searchCacheKey(languagePair: LanguagePair, query: String, limit: Int) -> String {
        "\(languagePair.languagePairString)|\(query.lowercased())|\(limit)"
    }
}
