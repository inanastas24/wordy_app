//1
//  TranslationResult.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI
import Foundation

// === МОДЕЛЬ ВІДПОВІДІ ===
struct TranslationResult: Identifiable, Hashable {
    let id: UUID                       // ← ЗМІНЕНО: без значення за замовчуванням
    let original: String
    let translation: String
    let transcription: String
    let ipaTranscription: String?
    let exampleSentence: String
    let exampleTranslation: String
    let exampleSentence2: String?
    let exampleTranslation2: String?
    let synonyms: [String]
    let languagePair: String
    
    init(
        id: UUID = UUID(),             // ← ДОДАНО: параметр з дефолтним значенням
        original: String,
        translation: String,
        transcription: String = "",
        ipaTranscription: String? = nil,
        exampleSentence: String = "",
        exampleTranslation: String = "",
        exampleSentence2: String? = nil,
        exampleTranslation2: String? = nil,
        synonyms: [String] = [],
        languagePair: String = "en-uk"
    ) {
        self.id = id                   // ← Тепер працює правильно
        self.original = original
        self.translation = translation
        self.transcription = transcription
        self.ipaTranscription = ipaTranscription
        self.exampleSentence = exampleSentence
        self.exampleTranslation = exampleTranslation
        self.exampleSentence2 = exampleSentence2
        self.exampleTranslation2 = exampleTranslation2
        self.synonyms = synonyms
        self.languagePair = languagePair
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TranslationResult, rhs: TranslationResult) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Розширення для визначення мови
extension TranslationResult {
    var originalLanguageCode: String {
        let components = languagePair.components(separatedBy: "-")
        return components.first ?? "en"
    }
    
    var translationLanguageCode: String {
        let components = languagePair.components(separatedBy: "-")
        return components.count > 1 ? components[1] : "uk"
    }
}
