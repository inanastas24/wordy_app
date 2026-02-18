//
//  WidgetDataService.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 27.01.2026.
//

import Foundation
import WidgetKit

class WidgetDataService {
    static let shared = WidgetDataService()
    private let suiteName = "group.com.inzercreator.wordyapp"
    
    // MARK: - Helper Struct
    struct WidgetWordItem {
        let id: String?
        let original: String
        let translation: String
        let transcription: String?
        let exampleSentence: String?
        let languagePair: String
    }
    
    func updateWidgetWords(words: [WidgetWordItem]) {
        // Конвертуємо в словник для кодування
        let dictArray: [[String: Any?]] = words.map { word in
            [
                "id": word.id ?? UUID().uuidString,
                "original": word.original,
                "translation": word.translation,
                "transcription": word.transcription,
                "example": word.exampleSentence,
                "languagePair": word.languagePair
            ]
        }
        
        // Кодуємо через JSON
        do {
            let data = try JSONSerialization.data(withJSONObject: dictArray, options: [])
            
            guard let defaults = UserDefaults(suiteName: suiteName) else {
                print("❌ WidgetDataService: Не вдалося отримати UserDefaults")
                return
            }
            
            defaults.set(data, forKey: "widgetWords")
            defaults.synchronize()
            
            print("✅ WidgetDataService: Збережено \(words.count) слів")
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("❌ WidgetDataService: Помилка кодування: \(error)")
        }
    }
    
    func clearWidgetWords() {
        UserDefaults(suiteName: suiteName)?.removeObject(forKey: "widgetWords")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
