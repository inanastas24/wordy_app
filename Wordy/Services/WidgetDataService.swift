import Foundation
import WidgetKit

final class WidgetDataService {
    static let shared = WidgetDataService()

    private let suiteName = "group.com.inzercreator.wordyapp"
    private let storageKey = "widgetWords"
    private let rotationIndexKey = "widgetRotationIndex"
    private var lastSavedWords: [WidgetWord] = []

    struct WidgetWord: Codable, Equatable {
        let id: String
        let originalText: String
        let translation: String
        let example: String?
        let sourceLanguage: String
        let targetLanguage: String
        let difficultyLevel: String?
        let nextReviewDate: Date?
        let updatedAt: Date

        var languageContext: LanguagePairContext {
            LanguagePairContext(sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
        }

        private enum CodingKeys: String, CodingKey {
            case id
            case originalText
            case original
            case translation
            case example
            case sourceLanguage
            case targetLanguage
            case difficultyLevel
            case nextReviewDate
            case updatedAt
        }

        init(
            id: String,
            originalText: String,
            translation: String,
            example: String?,
            sourceLanguage: String,
            targetLanguage: String,
            difficultyLevel: String?,
            nextReviewDate: Date?,
            updatedAt: Date
        ) {
            self.id = id
            self.originalText = originalText
            self.translation = translation
            self.example = example
            self.sourceLanguage = sourceLanguage
            self.targetLanguage = targetLanguage
            self.difficultyLevel = difficultyLevel
            self.nextReviewDate = nextReviewDate
            self.updatedAt = updatedAt
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
            originalText = try container.decodeIfPresent(String.self, forKey: .originalText)
                ?? container.decodeIfPresent(String.self, forKey: .original)
                ?? ""
            translation = try container.decodeIfPresent(String.self, forKey: .translation) ?? ""
            example = try container.decodeIfPresent(String.self, forKey: .example)
            sourceLanguage = try container.decodeIfPresent(String.self, forKey: .sourceLanguage) ?? "en"
            targetLanguage = try container.decodeIfPresent(String.self, forKey: .targetLanguage) ?? "uk"
            difficultyLevel = try container.decodeIfPresent(String.self, forKey: .difficultyLevel)
            nextReviewDate = try container.decodeIfPresent(Date.self, forKey: .nextReviewDate)
            updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(originalText, forKey: .originalText)
            try container.encode(translation, forKey: .translation)
            try container.encodeIfPresent(example, forKey: .example)
            try container.encode(sourceLanguage, forKey: .sourceLanguage)
            try container.encode(targetLanguage, forKey: .targetLanguage)
            try container.encodeIfPresent(difficultyLevel, forKey: .difficultyLevel)
            try container.encodeIfPresent(nextReviewDate, forKey: .nextReviewDate)
            try container.encode(updatedAt, forKey: .updatedAt)
        }
    }

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    func updateWidgetWords(words: [WidgetWord]) {
        guard let defaults = sharedDefaults else {
            print("[WidgetDataService] skipped no shared defaults")
            return
        }

        do {
            let normalizedWords = words
            let existingWords = lastSavedWords.isEmpty ? loadWidgetWords() : lastSavedWords
            guard existingWords != normalizedWords else {
                print("[WidgetDataService] skipped unchanged")
                return
            }
            
            let data = try JSONEncoder().encode(normalizedWords)
            
            let currentIndex = defaults.integer(forKey: rotationIndexKey)
            let normalizedIndex = normalizedWords.isEmpty ? 0 : currentIndex % normalizedWords.count
            
            defaults.set(data, forKey: storageKey)
            defaults.set(normalizedIndex, forKey: rotationIndexKey)
            lastSavedWords = normalizedWords

            print("[WidgetDataService] updated count=\(normalizedWords.count)")
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("[WidgetDataService] skipped encoding error=\(error)")
        }
    }

    func clearWidgetWords() {
        guard let defaults = sharedDefaults else { return }

        defaults.removeObject(forKey: storageKey)
        defaults.removeObject(forKey: rotationIndexKey)
        lastSavedWords = []

        print("[WidgetDataService] updated count=0")
        WidgetCenter.shared.reloadAllTimelines()
    }

    func loadWidgetWords() -> [WidgetWord] {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: storageKey) else {
            return []
        }

        do {
            let words = try JSONDecoder().decode([WidgetWord].self, from: data)
            lastSavedWords = words
            return words
        } catch {
            print("❌ WidgetDataService: Помилка декодування: \(error)")
            return []
        }
    }

    func loadRotationIndex() -> Int {
        guard let defaults = sharedDefaults else { return 0 }
        return defaults.integer(forKey: rotationIndexKey)
    }
}
