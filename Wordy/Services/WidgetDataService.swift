//
//  WidgetDataService.swift
//  Wordy
//

import Foundation
import WidgetKit

class WidgetDataService {
    static let shared = WidgetDataService()
    // ВИПРАВЛЕНО: той самий App Group
    private let suiteName = "group.Wordy"
    
    func updateWidgetWords(words: [SavedWordModel]) {
        let widgetWords = words.map { word in
            WidgetWord(
                id: word.id ?? UUID().uuidString,
                original: word.original,
                translation: word.translation,
                transcription: word.transcription,
                example: word.exampleSentence,
                languagePair: word.languagePair
            )
        }
        
        if let data = try? JSONEncoder().encode(widgetWords) {
            UserDefaults(suiteName: suiteName)?.set(data, forKey: "widgetWords")
        }
        
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct WidgetWord: Codable {
    let id: String
    let original: String
    let translation: String
    let transcription: String?
    let example: String?
    let languagePair: String
}
