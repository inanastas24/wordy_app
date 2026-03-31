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
                original: "Hello",
                translation: "Привіт",
                transcription: "həˈloʊ",
                example: "Hello, world!",
                languagePair: "en-uk"
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
    let original: String
    let translation: String
    let transcription: String?
    let example: String?
    let languagePair: String
}
