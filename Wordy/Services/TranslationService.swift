//1
//  TranslationService.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI
import Combine
import SwiftData
import StoreKit
import NaturalLanguage
import AVFoundation

// MARK: - Дані з Dictionary API
struct EnrichedWordData {
    let ipa: String?
    let examples: [String]
    let synonyms: [String]
    let partOfSpeech: String?
}

// MARK: - СЕРВІС ПЕРЕКЛАДУ
class TranslationService {
    private let deepLKey: String
    
    init() {
        self.deepLKey = ConfigService.shared.get("DEEPL_API_KEY") ?? ""
    }
    
    // MARK: - Головний метод перекладу
    func translate(word: String, appLanguage: String, learningLanguage: String, completion: @escaping (Result<TranslationResult, TranslationError>) -> Void) {
        guard !word.isEmpty else {
            completion(.failure(.noData))
            return
        }
        
        let appLangCode = languageNameToCode(appLanguage)
        let learningLangCode = languageNameToCode(learningLanguage)
        
        print("🔍 === АНАЛІЗ ВВЕДЕННЯ ===")
        print("   Слово: '\(word)'")
        print("   App: \(appLanguage) → \(appLangCode)")
        print("   Learning: \(learningLanguage) → \(learningLangCode)")
        
        let detectedLang = detectLanguage(word)
        print("   Визначена мова: \(detectedLang ?? "невідомо")")
        
        let sourceLang: String
        let targetLang: String
        
        if let detected = detectedLang {
            if detected == appLangCode {
                sourceLang = appLangCode
                targetLang = learningLangCode
                print("✅ Слово мовою додатка (\(appLangCode)) → переклад на \(learningLangCode)")
            } else if detected == learningLangCode {
                sourceLang = learningLangCode
                targetLang = appLangCode
                print("✅ Слово мовою вивчення (\(learningLangCode)) → переклад на \(appLangCode)")
            } else {
                sourceLang = detected
                targetLang = appLangCode
                print("⚠️ Третя мова (\(detected)) → переклад на \(appLangCode)")
            }
        } else {
            if isLikelyEnglish(word) {
                sourceLang = "en"
                targetLang = appLangCode
                print("✅ Слово латиницею (ймовірно EN) → переклад на \(appLangCode)")
            } else {
                sourceLang = appLangCode
                targetLang = learningLangCode
                print("⚠️ Не латиниця, припускаємо \(appLangCode) → \(learningLangCode)")
            }
        }
        
        // Для англійських слів отримуємо IPA, приклади, синоніми
        if sourceLang == "en" || (detectedLang == nil && isLikelyEnglish(word)) {
            fetchEnrichedData(word: word) { [weak self] enrichedData in
                self?.performDeepLTranslation(
                    word: word,
                    sourceLang: sourceLang,
                    targetLang: targetLang,
                    enrichedData: enrichedData,
                    completion: completion
                )
            }
        } else {
            performDeepLTranslation(
                word: word,
                sourceLang: sourceLang,
                targetLang: targetLang,
                enrichedData: nil,
                completion: completion
            )
        }
    }
    
    private func isLikelyEnglish(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        
        let cyrillicChars = CharacterSet(charactersIn: "а-яА-ЯґєіїҐЄІЇ")
        if trimmed.rangeOfCharacter(from: cyrillicChars) != nil {
            return false
        }
        
        let latinChars = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-'")
        
        for char in trimmed {
            let charSet = CharacterSet(charactersIn: String(char))
            if !latinChars.isSuperset(of: charSet) {
                if !CharacterSet.whitespacesAndNewlines.isSuperset(of: charSet) {
                    return false
                }
            }
        }
        
        return true
    }
    
    // MARK: - DeepL Translation
    private func performDeepLTranslation(word: String, sourceLang: String, targetLang: String, enrichedData: EnrichedWordData?, completion: @escaping (Result<TranslationResult, TranslationError>) -> Void) {
        
        let deeplSource = deeplLanguageCode(sourceLang)
        let deeplTarget = deeplLanguageCode(targetLang)
        let urlString = "https://api-free.deepl.com/v2/translate"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        let realExamples = enrichedData?.examples ?? []
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("DeepL-Auth-Key \(deepLKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var params: [(key: String, value: String)] = [
            ("source_lang", deeplSource),
            ("target_lang", deeplTarget),
            ("text", word)
        ]
        
        for example in realExamples.prefix(2) {
            params.append(("text", example))
        }
        
        let bodyString = params.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ DeepL error: \(error)")
                DispatchQueue.main.async { completion(.failure(.apiError(error.localizedDescription))) }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = data else {
                DispatchQueue.main.async { completion(.failure(.noData)) }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let translations = json["translations"] as? [[String: Any]] {
                    
                    let wordTranslation = translations.first?["text"] as? String ?? word
                    
                    var exampleTranslations: [String] = []
                    for i in 1..<translations.count {
                        if let text = translations[i]["text"] as? String {
                            exampleTranslations.append(text)
                        }
                    }
                    
                    let result = TranslationResult(
                        original: word,
                        translation: wordTranslation,
                        transcription: "",
                        ipaTranscription: enrichedData?.ipa,
                        exampleSentence: realExamples.first ?? "",
                        exampleTranslation: exampleTranslations.first ?? "",
                        exampleSentence2: realExamples.count > 1 ? realExamples[1] : nil,
                        exampleTranslation2: exampleTranslations.count > 1 ? exampleTranslations[1] : nil,
                        synonyms: enrichedData?.synonyms ?? [],
                        languagePair: "\(sourceLang)-\(targetLang)"
                    )
                    
                    print("✅ DeepL: \(word) → \(wordTranslation)")
                    DispatchQueue.main.async { completion(.success(result)) }
                    
                } else {
                    DispatchQueue.main.async { completion(.failure(.decodingError)) }
                }
            } catch {
                DispatchQueue.main.async { completion(.failure(.decodingError)) }
            }
        }.resume()
    }
    
    // MARK: - Dictionary API (IPA, приклади, синоніми)
    private func fetchEnrichedData(word: String, completion: @escaping (EnrichedWordData?) -> Void) {
        let encodedWord = word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? word
        let urlString = "https://api.dictionaryapi.dev/api/v2/entries/en/\(encodedWord.lowercased())"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                completion(nil)
                return
            }
            
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    var ipa: String?
                    var allExamples: [String] = []
                    var allSynonyms: [String] = []
                    var firstPartOfSpeech: String?
                    
                    for entry in jsonArray {
                        if let phonetics = entry["phonetics"] as? [[String: Any]] {
                            for phonetic in phonetics {
                                if let text = phonetic["text"] as? String, !text.isEmpty {
                                    ipa = text
                                    break
                                }
                            }
                        }
                        
                        if let meanings = entry["meanings"] as? [[String: Any]], !meanings.isEmpty {
                            let firstMeaning = meanings[0]
                            
                            if firstPartOfSpeech == nil {
                                firstPartOfSpeech = firstMeaning["partOfSpeech"] as? String
                            }
                            
                            if let synonyms = firstMeaning["synonyms"] as? [String] {
                                allSynonyms.append(contentsOf: synonyms)
                            }
                            
                            if let definitions = firstMeaning["definitions"] as? [[String: Any]] {
                                for def in definitions.prefix(2) {
                                    if let example = def["example"] as? String {
                                        allExamples.append(example)
                                    }
                                    if let syn = def["synonyms"] as? [String] {
                                        allSynonyms.append(contentsOf: syn)
                                    }
                                }
                            }
                        }
                    }
                    
                    let filteredSynonyms = self.filterSynonyms(allSynonyms)
                    
                    let uniqueExamples = Array(Set(allExamples)).prefix(2).map { $0 }
                    let uniqueSynonyms = Array(Set(filteredSynonyms)).prefix(10).map { $0 }
                    
                    print("📚 DictionaryAPI: IPA=\(ipa ?? "немає"), прикладів=\(uniqueExamples.count), синонімів=\(uniqueSynonyms.count)")
                    
                    completion(EnrichedWordData(
                        ipa: ipa,
                        examples: uniqueExamples,
                        synonyms: uniqueSynonyms,
                        partOfSpeech: firstPartOfSpeech
                    ))
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }.resume()
    }
    
    private func filterSynonyms(_ synonyms: [String]) -> [String] {
        let blockedWords = ["motherfucker", "fuck", "shit", "damn", "ass", "bitch", "bastard", "crap", "hell", "piss", "dick", "cock", "pussy", "whore", "slut"]
        let blockedPatterns = ["fuck", "shit", "damn", "ass", "bitch", "bastard", "hell", "crap"]
        
        return synonyms.filter { synonym in
            let lowercased = synonym.lowercased()
            
            if blockedWords.contains(lowercased) {
                return false
            }
            
            for pattern in blockedPatterns {
                if lowercased.contains(pattern) {
                    return false
                }
            }
            
            if synonym.contains("-") && synonym.count > 15 {
                return false
            }
            
            return true
        }
    }
    
    // MARK: - Переклад синонімів через DeepL
    func translateSynonyms(synonyms: [String], sourceLang: String, targetLang: String, completion: @escaping ([SynonymDetail]) -> Void) {
        guard !synonyms.isEmpty else {
            completion([])
            return
        }
        
        print("🌐 Переклад синонімів через DeepL: \(synonyms.count) шт. \(sourceLang) → \(targetLang)")
        
        let deeplSource = deeplLanguageCode(sourceLang)
        let deeplTarget = deeplLanguageCode(targetLang)
        let urlString = "https://api-free.deepl.com/v2/translate"
        
        guard let url = URL(string: urlString) else {
            // Якщо URL не валідний, повертаємо оригінали
            let details = synonyms.map { SynonymDetail(word: $0, ipaTranscription: nil, translation: $0) }
            completion(details)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("DeepL-Auth-Key \(deepLKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var params: [(key: String, value: String)] = [
            ("source_lang", deeplSource),
            ("target_lang", deeplTarget)
        ]
        
        for synonym in synonyms {
            params.append(("text", synonym))
        }
        
        let bodyString = params.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else {
                // Якщо немає даних, повертаємо оригінали
                let details = synonyms.map { SynonymDetail(word: $0, ipaTranscription: nil, translation: $0) }
                DispatchQueue.main.async { completion(details) }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let translations = json["translations"] as? [[String: Any]] {
                    
                    var details: [SynonymDetail] = []
                    
                    for (index, translation) in translations.enumerated() {
                        guard index < synonyms.count else { break }
                        let originalWord = synonyms[index]
                        let translatedText = translation["text"] as? String ?? originalWord
                        details.append(SynonymDetail(word: originalWord, ipaTranscription: nil, translation: translatedText))
                    }
                    
                    print("✅ DeepL синоніми: \(details.count)")
                    DispatchQueue.main.async { completion(details) }
                } else {
                    let details = synonyms.map { SynonymDetail(word: $0, ipaTranscription: nil, translation: $0) }
                    DispatchQueue.main.async { completion(details) }
                }
            } catch {
                let details = synonyms.map { SynonymDetail(word: $0, ipaTranscription: nil, translation: $0) }
                DispatchQueue.main.async { completion(details) }
            }
        }.resume()
    }
    
    // MARK: - Допоміжні методи
    private func detectLanguage(_ text: String) -> String? {
        let ukrainianChars = CharacterSet(charactersIn: "ґєіїҐЄІЇ")
        let polishChars = CharacterSet(charactersIn: "ąćęłńóśźżĄĆĘŁŃÓŚŹŻ")
        let germanChars = CharacterSet(charactersIn: "äöüßÄÖÜẞ")
        let frenchChars = CharacterSet(charactersIn: "àâäæçéèêëïîôœùûüÿÀÂÄÆÇÉÈÊËÏÎÔŒÙÛÜŸ")
        let spanishChars = CharacterSet(charactersIn: "áéíóúüñÁÉÍÓÚÜÑ¿¡")
        let italianChars = CharacterSet(charactersIn: "àèéìòùÀÈÉÌÒÙ")
        
        if text.rangeOfCharacter(from: ukrainianChars) != nil { return "uk" }
        if text.rangeOfCharacter(from: polishChars) != nil { return "pl" }
        if text.rangeOfCharacter(from: germanChars) != nil { return "de" }
        if text.rangeOfCharacter(from: frenchChars) != nil { return "fr" }
        if text.rangeOfCharacter(from: spanishChars) != nil { return "es" }
        if text.rangeOfCharacter(from: italianChars) != nil { return "it" }
        
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let dominantLanguage = recognizer.dominantLanguage else { return nil }
        
        let detectedCode = dominantLanguage.rawValue
        let supportedLanguages = ["uk", "en", "es", "de", "fr", "it", "pl"]
        return supportedLanguages.contains(detectedCode) ? detectedCode : nil
    }
    
    private func deeplLanguageCode(_ code: String) -> String {
        let mapping = ["uk": "UK", "en": "EN", "es": "ES", "de": "DE", "fr": "FR", "it": "IT", "pl": "PL"]
        return mapping[code] ?? "EN"
    }
    
    private func languageNameToCode(_ name: String) -> String {
        let mapping = [
            "uk": "uk", "українська": "uk", "ukrainian": "uk",
            "en": "en", "english": "en", "англійська": "en",
            "de": "de", "deutsch": "de", "німецька": "de", "german": "de",
            "pl": "pl", "polski": "pl", "польська": "pl", "polish": "pl",
            "es": "es", "español": "es", "іспанська": "es", "spanish": "es",
            "fr": "fr", "français": "fr", "французька": "fr", "french": "fr",
            "it": "it", "italiano": "it", "італійська": "it", "italian": "it"
        ]
        let lowercased = name.lowercased()
        return mapping[lowercased] ?? lowercased
    }
}
