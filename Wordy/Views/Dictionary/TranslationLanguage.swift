//
//  TranslationLanguage.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 28.02.2026.
//

import SwiftUI
import Foundation

/// Мови доступні для перекладу (DeepL API)
enum TranslationLanguage: String, CaseIterable, Identifiable, Codable {
    // MARK: - Основні мови (пріоритетні)
    case ukrainian = "uk"
    case english = "en"
    case polish = "pl"
    case german = "de"
    case french = "fr"
    case spanish = "es"
    case italian = "it"
    
    // MARK: - Всі інші мови (за алфавітом)
    case arabic = "ar"
    case bulgarian = "bg"
    case chinese = "zh"
    case czech = "cs"
    case danish = "da"
    case dutch = "nl"
    case estonian = "et"
    case finnish = "fi"
    case greek = "el"
    case hungarian = "hu"
    case indonesian = "id"
    case japanese = "ja"
    case korean = "ko"
    case latvian = "lv"
    case lithuanian = "lt"
    case norwegian = "nb"
    case portuguese = "pt"
    case romanian = "ro"
    case russian = "ru"
    case slovak = "sk"
    case slovenian = "sl"
    case swedish = "sv"
    case turkish = "tr"
    
    var id: String { rawValue }
    
    /// Код мови для DeepL API
    var deeplCode: String {
        switch self {
        case .ukrainian: return "UK"
        case .english: return "EN"
        case .polish: return "PL"
        case .german: return "DE"
        case .french: return "FR"
        case .spanish: return "ES"
        case .italian: return "IT"
        case .arabic: return "AR"
        case .bulgarian: return "BG"
        case .chinese: return "ZH"
        case .czech: return "CS"
        case .danish: return "DA"
        case .dutch: return "NL"
        case .estonian: return "ET"
        case .finnish: return "FI"
        case .greek: return "EL"
        case .hungarian: return "HU"
        case .indonesian: return "ID"
        case .japanese: return "JA"
        case .korean: return "KO"
        case .latvian: return "LV"
        case .lithuanian: return "LT"
        case .norwegian: return "NB"
        case .portuguese: return "PT"
        case .romanian: return "RO"
        case .russian: return "RU"
        case .slovak: return "SK"
        case .slovenian: return "SL"
        case .swedish: return "SV"
        case .turkish: return "TR"
        }
    }
    
    /// Назва мови англійською (для відображення)
    var displayName: String {
        switch self {
        case .ukrainian: return "Українська"
        case .english: return "English"
        case .polish: return "Polski"
        case .german: return "Deutsch"
        case .french: return "Français"
        case .spanish: return "Español"
        case .italian: return "Italiano"
        case .arabic: return "العربية"
        case .bulgarian: return "Български"
        case .chinese: return "中文"
        case .czech: return "Čeština"
        case .danish: return "Dansk"
        case .dutch: return "Nederlands"
        case .estonian: return "Eesti"
        case .finnish: return "Suomi"
        case .greek: return "Ελληνικά"
        case .hungarian: return "Magyar"
        case .indonesian: return "Bahasa Indonesia"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .latvian: return "Latviešu"
        case .lithuanian: return "Lietuvių"
        case .norwegian: return "Norsk"
        case .portuguese: return "Português"
        case .romanian: return "Română"
        case .russian: return "Русский"
        case .slovak: return "Slovenčina"
        case .slovenian: return "Slovenščina"
        case .swedish: return "Svenska"
        case .turkish: return "Türkçe"
        }
    }
    
    /// Локалізована назва (залежно від мови додатку)
    func localizedName(in language: Language) -> String {
        let names: [TranslationLanguage: [Language: String]] = [
            .english: [.ukrainian: "Англійська", .polish: "Angielski", .english: "English"],
            .polish: [.ukrainian: "Польська", .polish: "Polski", .english: "Polish"],
            .german: [.ukrainian: "Німецька", .polish: "Niemiecki", .english: "German"],
            .french: [.ukrainian: "Французька", .polish: "Francuski", .english: "French"],
            .spanish: [.ukrainian: "Іспанська", .polish: "Hiszpański", .english: "Spanish"],
            .italian: [.ukrainian: "Італійська", .polish: "Włoski", .english: "Italian"],
            .arabic: [.ukrainian: "Арабська", .polish: "Arabski", .english: "Arabic"],
            .bulgarian: [.ukrainian: "Болгарська", .polish: "Bułgarski", .english: "Bulgarian"],
            .chinese: [.ukrainian: "Китайська", .polish: "Chiński", .english: "Chinese"],
            .czech: [.ukrainian: "Чеська", .polish: "Czeski", .english: "Czech"],
            .danish: [.ukrainian: "Данська", .polish: "Duński", .english: "Danish"],
            .dutch: [.ukrainian: "Голландська", .polish: "Holenderski", .english: "Dutch"],
            .estonian: [.ukrainian: "Естонська", .polish: "Estoński", .english: "Estonian"],
            .finnish: [.ukrainian: "Фінська", .polish: "Fiński", .english: "Finnish"],
            .greek: [.ukrainian: "Грецька", .polish: "Grecki", .english: "Greek"],
            .hungarian: [.ukrainian: "Угорська", .polish: "Węgierski", .english: "Hungarian"],
            .indonesian: [.ukrainian: "Індонезійська", .polish: "Indonezyjski", .english: "Indonesian"],
            .japanese: [.ukrainian: "Японська", .polish: "Japoński", .english: "Japanese"],
            .korean: [.ukrainian: "Корейська", .polish: "Koreański", .english: "Korean"],
            .latvian: [.ukrainian: "Латиська", .polish: "Łotewski", .english: "Latvian"],
            .lithuanian: [.ukrainian: "Литовська", .polish: "Litewski", .english: "Lithuanian"],
            .norwegian: [.ukrainian: "Норвезька", .polish: "Norweski", .english: "Norwegian"],
            .portuguese: [.ukrainian: "Португальська", .polish: "Portugalski", .english: "Portuguese"],
            .romanian: [.ukrainian: "Румунська", .polish: "Rumuński", .english: "Romanian"],
            .russian: [.ukrainian: "Російська", .polish: "Rosyjski", .english: "Russian"],
            .slovak: [.ukrainian: "Словацька", .polish: "Słowacki", .english: "Slovak"],
            .slovenian: [.ukrainian: "Словенська", .polish: "Słoweński", .english: "Slovenian"],
            .swedish: [.ukrainian: "Шведська", .polish: "Szwedzki", .english: "Swedish"],
            .turkish: [.ukrainian: "Турецька", .polish: "Turecki", .english: "Turkish"],
            .ukrainian: [.ukrainian: "Українська", .polish: "Ukraiński", .english: "Ukrainian"],
        ]
        return names[self]?[language] ?? displayName
    }
    
    /// Прапор країни
    var flag: String {
        switch self {
        case .english: return "🇬🇧"
        case .polish: return "🇵🇱"
        case .german: return "🇩🇪"
        case .french: return "🇫🇷"
        case .spanish: return "🇪🇸"
        case .italian: return "🇮🇹"
        case .arabic: return "🇸🇦"
        case .bulgarian: return "🇧🇬"
        case .chinese: return "🇨🇳"
        case .czech: return "🇨🇿"
        case .danish: return "🇩🇰"
        case .dutch: return "🇳🇱"
        case .estonian: return "🇪🇪"
        case .finnish: return "🇫🇮"
        case .greek: return "🇬🇷"
        case .hungarian: return "🇭🇺"
        case .indonesian: return "🇮🇩"
        case .japanese: return "🇯🇵"
        case .korean: return "🇰🇷"
        case .latvian: return "🇱🇻"
        case .lithuanian: return "🇱🇹"
        case .norwegian: return "🇳🇴"
        case .portuguese: return "🇵🇹"
        case .romanian: return "🇷🇴"
        case .russian: return "🇷🇺"
        case .slovak: return "🇸🇰"
        case .slovenian: return "🇸🇮"
        case .swedish: return "🇸🇪"
        case .turkish: return "🇹🇷"
        case .ukrainian: return "🇺🇦"
        }
    }
    
    /// Чи підтримує формальність (formality)
    var supportsFormality: Bool {
        [.german, .french, .italian, .spanish, .dutch, .polish, .portuguese, .russian, .japanese].contains(self)
    }
    
    /// 🆕 Чи є основною мовою (ОНОВЛЕНО — додано українську!)
    var isPrimary: Bool {
        [.ukrainian, .english, .polish, .german, .french, .spanish, .italian].contains(self)
    }
    
    // MARK: - Static Properties
    
    /// Основні мови (відсортовані за алфавітом)
    static var primaryLanguages: [TranslationLanguage] {
        allCases.filter { $0.isPrimary }.sorted { $0.displayName < $1.displayName }
    }
    
    /// Всі інші мови (відсортовані за алфавітом)
    static var otherLanguages: [TranslationLanguage] {
        allCases.filter { !$0.isPrimary }.sorted { $0.displayName < $1.displayName }
    }
    
    /// Всі мови з групуванням (основні + інші)
    static var allGrouped: ([TranslationLanguage], [TranslationLanguage]) {
        (primaryLanguages, otherLanguages)
    }
}

// MARK: - Language Pair

/// Пара мов для перекладу
struct LanguagePair: Codable, Equatable {
    var source: TranslationLanguage
    var target: TranslationLanguage
    
    var languagePairString: String {
        "\(source.rawValue)-\(target.rawValue)"
    }
    
    var deeplPairString: String {
        "\(source.deeplCode)-\(target.deeplCode)"
    }
    
    /// Міняє мови місцями
    mutating func swap() {
        let temp = source
        source = target
        target = temp
    }
    
    /// Створює нову пару з поміняними мовами
    func swapped() -> LanguagePair {
        LanguagePair(source: target, target: source)
    }
}
