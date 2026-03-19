//
//  Provider.swift
//  WordyWidgetExtension
//

import WidgetKit
import SwiftUI


struct WordEntry: TimelineEntry {
    let date: Date
    let word: WidgetWord?
    let isEmpty: Bool
}

struct Provider: TimelineProvider {
    private let suiteName = "group.com.inzercreator.wordyapp"
    
    private func loadWords() -> [WidgetWord] {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: "widgetWords") else {
            print("📱 Widget: Немає збережених слів")
            return []
        }
        
        do {
            let words = try JSONDecoder().decode([WidgetWord].self, from: data)
            print("📱 Widget: Завантажено \(words.count) слів")
            return words
        } catch {
            print("❌ Widget: Помилка декодування: \(error)")
            return []
        }
    }
    
    func placeholder(in context: Context) -> WordEntry {
        WordEntry(
            date: Date(),
            word: WidgetWord(
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
        let entry: WordEntry
        
        if let randomWord = words.randomElement() {
            entry = WordEntry(date: Date(), word: randomWord, isEmpty: false)
        } else {
            entry = WordEntry(date: Date(), word: nil, isEmpty: true)
        }
        
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WordEntry>) -> Void) {
        let words = loadWords()
        var entries: [WordEntry] = []

        let currentDate = Date()

        for index in 0..<24 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: index, to: currentDate)!

            let word = words.isEmpty ? nil : words[index % words.count]

            let entry = WordEntry(
                date: entryDate,
                word: word,
                isEmpty: words.isEmpty
            )

            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .after(Date().addingTimeInterval(60 * 30)))
        completion(timeline)
    }
}

// MARK: - WidgetWord (визначений тут для віджета)
struct WidgetWord: Codable {
    let id: String
    let original: String
    let translation: String
    let transcription: String?
    let example: String?
    let languagePair: String
}
