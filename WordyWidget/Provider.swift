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

struct WidgetWord: Codable {
    let id: String
    let original: String
    let translation: String
    let transcription: String?
    let example: String?
    let languagePair: String
}

struct Provider: TimelineProvider {
    // ВИПРАВЛЕНО: використовуйте той самий App Group, що й в основному додатку
    private let suiteName = "group.Wordy"
    
    private func loadWords() -> [WidgetWord] {
        guard let data = UserDefaults(suiteName: suiteName)?.data(forKey: "widgetWords") else {
            return []
        }
        return (try? JSONDecoder().decode([WidgetWord].self, from: data)) ?? []
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
        for hourOffset in 0..<24 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            
            let entry: WordEntry
            if let randomWord = words.randomElement() {
                entry = WordEntry(date: entryDate, word: randomWord, isEmpty: false)
            } else {
                entry = WordEntry(date: entryDate, word: nil, isEmpty: true)
            }
            
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}
