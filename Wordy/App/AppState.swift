//
//  AppState.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 27.01.2026.
//

import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var appLanguage: String
    @Published var searchHistory: [SearchItem]
    @Published var savedWords: [SavedWordModel] = []
    
    // MARK: - Language Pair
    @Published var languagePair: LanguagePair {
        didSet {
            // Автоматично зберігаємо при будь-якій зміні
            persistLanguagePair()
        }
    }
    
    init() {
        self.appLanguage = "uk"
        self.searchHistory = []
        
        // Завантажуємо збережену пару мов або встановлюємо дефолт
        if let savedPair = UserDefaults.standard.data(forKey: "languagePair"),
           let decoded = try? JSONDecoder().decode(LanguagePair.self, from: savedPair) {
            self.languagePair = decoded
        } else {
            // Дефолт: англійська ↔ польська
            self.languagePair = LanguagePair(source: .english, target: .polish)
        }
        
        // Синхронізуємо з індивідуальними ключами при старті
        syncToUserDefaults()
        loadSavedWords()
    }
    private func loadSavedWords() {
           self.savedWords = LocalStorageService.shared.fetchLocalWords()
       }
       
       // НОВЕ: Метод для збереження слів з повною інтеграцією
       func saveWords(_ words: [SavedWordModel]) {
           // Використовуємо shared ViewModel для збереження
           DictionaryViewModel.shared.saveWords(words)
           
           // Оновлюємо локальний масив
           DispatchQueue.main.async {
               self.savedWords = LocalStorageService.shared.fetchLocalWords()
           }
       }
    
    // MARK: - Persistence
    
    /// Повне збереження: JSON + індивідуальні ключі + прапорці
    func saveLanguagePair() {
        persistLanguagePair()
    }
    
    private func persistLanguagePair() {
        // 1. Зберігаємо як JSON (основне сховище)
        if let encoded = try? JSONEncoder().encode(languagePair) {
            UserDefaults.standard.set(encoded, forKey: "languagePair")
        }
        
        // 2. Синхронізуємо індивідуальні ключі для RootView (@AppStorage)
        syncToUserDefaults()
        
        print("💾 Saved language pair: \(languagePair.source.rawValue) → \(languagePair.target.rawValue)")
    }
    
    /// Синхронізує languagePair з індивідуальними ключами UserDefaults
    private func syncToUserDefaults() {
        // Ключі для RootView
        UserDefaults.standard.set(languagePair.source.rawValue, forKey: "sourceLanguage")
        UserDefaults.standard.set(languagePair.target.rawValue, forKey: "targetLanguage")
        UserDefaults.standard.set(true, forKey: "hasSelectedLanguagePair")
        
        // Зворотна сумісність зі старим кодом
        UserDefaults.standard.set(languagePair.target.rawValue, forKey: "learningLanguage")
        UserDefaults.standard.set(true, forKey: "hasSelectedLearningLanguage")
    }
    
    // MARK: - Language Pair Methods
    
    func swapLanguages() {
        languagePair.swap()
        // persistLanguagePair() викликається автоматично через didSet
    }
    
    func setSourceLanguage(_ language: TranslationLanguage) {
        // Запобігаємо вибору однакових мов
        if language == languagePair.target {
            languagePair.target = languagePair.source
        }
        languagePair.source = language
        // persistLanguagePair() викликається автоматично через didSet
    }
    
    func setTargetLanguage(_ language: TranslationLanguage) {
        // Запобігаємо вибору однакових мов
        if language == languagePair.source {
            languagePair.source = languagePair.target
        }
        languagePair.target = language
        // persistLanguagePair() викликається автоматично через didSet
    }
    
    // MARK: - Legacy Properties (for compatibility)
    
    /// Повертає мову вивчення (target мова) для сумісності зі старим кодом
    var learningLanguage: String {
        get { languagePair.target.rawValue }
        set {
            if let lang = TranslationLanguage(rawValue: newValue) {
                setTargetLanguage(lang)
            }
        }
    }
}

struct SearchItem: Identifiable, Codable {
    var id = UUID()
    let word: String
    let translation: String
    let date: Date
}
