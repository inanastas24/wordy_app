//1
//  TranslationResult.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI
import Foundation

struct TranslationResult: Identifiable, Hashable {
    let id: UUID
    let original: String
    let translation: String
    let informalTranslation: String?
    let transcription: String
    let ipaTranscription: String?
    let exampleSentence: String
    let exampleTranslation: String
    let exampleSentence2: String?
    let exampleTranslation2: String?
    let synonyms: [String]
    let languagePair: String
    let fromLanguage: String
    let toLanguage: String
    
    init(
        id: UUID = UUID(),
        original: String,
        translation: String,
        informalTranslation: String? = nil,
        transcription: String = "",
        ipaTranscription: String? = nil,
        exampleSentence: String = "",
        exampleTranslation: String = "",
        exampleSentence2: String? = nil,
        exampleTranslation2: String? = nil,
        synonyms: [String] = [],
        languagePair: String = "en-uk",
        fromLanguage: String? = nil,
        toLanguage: String? = nil
    ) {
        self.id = id
        self.original = original
        self.translation = translation
        self.informalTranslation = informalTranslation
        self.transcription = transcription
        self.ipaTranscription = ipaTranscription
        self.exampleSentence = exampleSentence
        self.exampleTranslation = exampleTranslation
        self.exampleSentence2 = exampleSentence2
        self.exampleTranslation2 = exampleTranslation2
        self.synonyms = synonyms
        self.languagePair = languagePair
        
        let components = languagePair.components(separatedBy: "-")
        self.fromLanguage = fromLanguage ?? components.first ?? "en"
        self.toLanguage = toLanguage ?? (components.count > 1 ? components[1] : "uk")
    }
    
    var originalLanguageCode: String { fromLanguage }
    var translationLanguageCode: String { toLanguage }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TranslationResult, rhs: TranslationResult) -> Bool {
        lhs.id == rhs.id
    }
}
