//1
//  TranslationResult.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI
import Foundation

// MARK: - Розширення для визначення мови
extension TranslationResult {
    var originalLanguageCode: String {
        // Повертаємо код мови оригіналу (en, de, etc.)
        return "en" // Спрощено, треба визначати з result
    }
    
    var translationLanguageCode: String {
        return "uk" // Спрощено
    }
}

// === МОДЕЛЬ ВІДПОВІДІ ===
struct TranslationResult: Identifiable, Hashable {
    let id = UUID()
    let original: String
    let translation: String
    let transcription: String
    let ipaTranscription: String?
    let exampleSentence: String
    let exampleTranslation: String
    let exampleSentence2: String?    // НОВЕ
    let exampleTranslation2: String? // НОВЕ
    let synonyms: [String]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TranslationResult, rhs: TranslationResult) -> Bool {
        lhs.id == rhs.id
    }
}
