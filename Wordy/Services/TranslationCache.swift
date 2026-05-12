import Foundation

actor TranslationCache {
    static let shared = TranslationCache()

    private let storageKey = "wordy.translation.cache.v1"
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private struct CacheEntry: Codable {
        let key: String
        let wordCard: WordCard
        let savedAt: Date
    }

    private init() {}

    static func canonicalCacheText(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    func wordCard(
        normalizedText: String,
        sourceLanguage: String,
        targetLanguage: String,
        backendEngineVersion: String
    ) -> WordCard? {
        let key = cacheKey(
            normalizedText: normalizedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            backendEngineVersion: backendEngineVersion
        )

        let entries = loadEntries()
        let cached = entries[key]?.wordCard
        print("[TranslationCache] \(cached == nil ? "miss" : "hit") key=\(key)")
        return cached
    }

    func save(_ wordCard: WordCard) {
        var entries = loadEntries()
        let savedAt = Date()

        let normalizedKey = cacheKey(
            normalizedText: wordCard.normalizedText,
            sourceLanguage: wordCard.sourceLanguage,
            targetLanguage: wordCard.targetLanguage,
            backendEngineVersion: wordCard.backendEngineVersion
        )
        entries[normalizedKey] = CacheEntry(key: normalizedKey, wordCard: wordCard, savedAt: savedAt)

        let originalTextKey = cacheKey(
            normalizedText: Self.canonicalCacheText(wordCard.originalText),
            sourceLanguage: wordCard.sourceLanguage,
            targetLanguage: wordCard.targetLanguage,
            backendEngineVersion: wordCard.backendEngineVersion
        )
        entries[originalTextKey] = CacheEntry(key: originalTextKey, wordCard: wordCard, savedAt: savedAt)

        persist(entries)
    }

    private func cacheKey(
        normalizedText: String,
        sourceLanguage: String,
        targetLanguage: String,
        backendEngineVersion: String
    ) -> String {
        [
            normalizedText.lowercased(),
            sourceLanguage.lowercased(),
            targetLanguage.lowercased(),
            backendEngineVersion.lowercased()
        ].joined(separator: "|")
    }

    private func loadEntries() -> [String: CacheEntry] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let entries = try? decoder.decode([String: CacheEntry].self, from: data) else {
            return [:]
        }

        return entries
    }

    private func persist(_ entries: [String: CacheEntry]) {
        guard let data = try? encoder.encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
