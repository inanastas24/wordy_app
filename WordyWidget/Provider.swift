//
//  Provider.swift
//  WordyWidgetExtension
//

import WidgetKit
import SwiftUI

struct WordEntry: TimelineEntry {
    let date: Date
    let word: WidgetWidgetWordModel?
    let isEmpty: Bool
}

struct Provider: TimelineProvider {
    private let suiteName = "group.com.inzercreator.wordyapp"
    private let storageKey = "widgetWords"
    private let rotationIndexKey = "widgetRotationIndex"

    private func sharedDefaults() -> UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    private func loadWords() -> [WidgetWidgetWordModel] {
        guard let defaults = sharedDefaults(),
              let data = defaults.data(forKey: storageKey) else {
            print("📱 Widget: Немає збережених слів")
            return []
        }

        do {
            let words = try JSONDecoder().decode([WidgetWidgetWordModel].self, from: data)
            print("📱 Widget: Завантажено \(words.count) слів")
            return words
        } catch {
            print("❌ Widget: Помилка декодування: \(error)")
            return []
        }
    }

    private func loadRotationIndex() -> Int {
        guard let defaults = sharedDefaults() else { return 0 }
        return defaults.integer(forKey: rotationIndexKey)
    }

    private func safeWord(
        from words: [WidgetWidgetWordModel],
        startIndex: Int,
        offset: Int
    ) -> WidgetWidgetWordModel? {
        guard !words.isEmpty else { return nil }
        let index = (startIndex + offset) % words.count
        return words[index]
    }

    func placeholder(in context: Context) -> WordEntry {
        WordEntry(
            date: Date(),
            word: WidgetWidgetWordModel(
                id: "1",
                originalText: "Hello",
                translation: "Привіт",
                example: "Hello, world!",
                sourceLanguage: "en",
                targetLanguage: "uk",
                difficultyLevel: "A1",
                nextReviewDate: nil,
                updatedAt: Date()
            ),
            isEmpty: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WordEntry) -> Void) {
        let words = loadWords()
        let startIndex = loadRotationIndex()

        let entry = WordEntry(
            date: Date(),
            word: safeWord(from: words, startIndex: startIndex, offset: 0),
            isEmpty: words.isEmpty
        )

        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WordEntry>) -> Void) {
        let words = loadWords()
        let startIndex = loadRotationIndex()
        let currentDate = Date()
        
        guard words.count > 1 else {
            // Якщо слово одне - оновлювати частіше для швидшої реакції на зміни
            let entry = WordEntry(date: currentDate, word: words.first, isEmpty: words.isEmpty)
            let nextRefresh = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
            return
        }
        
        // Для кількох слів - різні слова на різні години
        var entries: [WordEntry] = []
        for hourOffset in 0..<24 {
            guard let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)
                  else { continue }
            
            let wordIndex = (startIndex + hourOffset) % words.count
            let entry = WordEntry(date: entryDate, word: words[wordIndex], isEmpty: false)
            entries.append(entry)
        }
        
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 24, to: currentDate)!
        completion(Timeline(entries: entries, policy: .after(nextRefresh)))
    }
}

// MARK: - Shared widget model

struct WidgetWidgetWordModel: Codable, Equatable {
    let id: String
    let originalText: String
    let translation: String
    let example: String?
    let sourceLanguage: String
    let targetLanguage: String
    let difficultyLevel: String?
    let nextReviewDate: Date?
    let updatedAt: Date

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
