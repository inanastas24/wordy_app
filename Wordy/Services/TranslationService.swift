//  TranslationService.swift
//  Wordy
//

import SwiftUI
import Combine
import SwiftData
import StoreKit
import NaturalLanguage
import AVFoundation

struct EnrichedWordData {
    let ipa: String?
    let examples: [(original: String, translation: String)]
    let synonyms: [String]
    let partOfSpeech: String?
}

class TranslationService {
    private let deepLKey: String
    
    init() {
        self.deepLKey = ConfigService.shared.get("DEEPL_API_KEY") ?? ""
    }
    
    func translate(word: String, appLanguage: String, learningLanguage: String, completion: @escaping (Result<TranslationResult, TranslationError>) -> Void) {
        guard !word.isEmpty else {
            completion(.failure(.noData))
            return
        }
        
        // Перевірка та конвертація мов
        let appLangCode = languageNameToCode(appLanguage)
        let learningLangCode = languageNameToCode(learningLanguage)
        
        // Захист від порожніх значень
        guard !appLangCode.isEmpty, !learningLangCode.isEmpty else {
            print("❌ Помилка: порожній код мови. app: '\(appLanguage)'->'\(appLangCode)', learning: '\(learningLanguage)'->'\(learningLangCode)'")
            completion(.failure(.invalidResponse))
            return
        }
        
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
            sourceLang = appLangCode
            targetLang = learningLangCode
            print("⚠️ Не визначено, припускаємо \(appLangCode) → \(learningLangCode)")
        }
        
        fetchEnrichedData(word: word, sourceLang: sourceLang, targetLang: targetLang) { [weak self] enrichedData in
            self?.performDeepLTranslation(
                word: word,
                sourceLang: sourceLang,
                targetLang: targetLang,
                enrichedData: enrichedData,
                completion: completion
            )
        }
    }
    
    private func performDeepLTranslation(word: String, sourceLang: String, targetLang: String, enrichedData: EnrichedWordData?, completion: @escaping (Result<TranslationResult, TranslationError>) -> Void) {
        
        let deeplSource = deeplLanguageCode(sourceLang)
        let deeplTarget = deeplLanguageCode(targetLang)
        
        // Перевіряємо, чи підтримує цільова мова formality
        let supportsFormality = ["DE", "FR", "IT", "ES", "NL", "PL", "PT", "RU", "JA"].contains(deeplTarget)
        
        // Якщо не підтримує formality - робимо простий запит без цього параметра
        guard supportsFormality else {
            fetchTranslation(word: word, source: deeplSource, target: deeplTarget, formality: nil) { [weak self] result in
                guard let self = self else { return }
                
                let mainTranslation = result ?? word
                
                self.translateExamples(enrichedData?.examples ?? [], source: deeplSource, target: deeplTarget) { translatedExamples in
                    
                    self.fetchSynonymsForLanguage(word: mainTranslation, language: targetLang) { synonyms in
                        
                        let result = TranslationResult(
                            original: word,
                            translation: mainTranslation,
                            informalTranslation: nil, // Не підтримується для цієї мови
                            transcription: "",
                            ipaTranscription: enrichedData?.ipa,
                            exampleSentence: translatedExamples.first?.original ?? "",
                            exampleTranslation: translatedExamples.first?.translation ?? "",
                            exampleSentence2: translatedExamples.count > 1 ? translatedExamples[1].original : nil,
                            exampleTranslation2: translatedExamples.count > 1 ? translatedExamples[1].translation : nil,
                            synonyms: synonyms.isEmpty ? (enrichedData?.synonyms ?? []) : synonyms,
                            languagePair: "\(sourceLang)-\(targetLang)",
                            fromLanguage: sourceLang,
                            toLanguage: targetLang
                        )
                        
                        print("✅ DeepL: \(word) → \(mainTranslation) (formality не підтримується для \(deeplTarget))")
                        DispatchQueue.main.async { completion(.success(result)) }
                    }
                }
            }
            return
        }
        
        // Якщо підтримує formality - робимо два запити (formal + informal)
        fetchTranslation(word: word, source: deeplSource, target: deeplTarget, formality: "more") { [weak self] formalResult in
            guard let self = self else { return }
            
            let mainTranslation = formalResult ?? word
            
            self.fetchInformalIfSupported(word: word, source: deeplSource, target: deeplTarget) { informalResult in
                
                let informalTranslation = (informalResult != mainTranslation) ? informalResult : nil
                
                self.translateExamples(enrichedData?.examples ?? [], source: deeplSource, target: deeplTarget) { translatedExamples in
                    
                    self.fetchSynonymsForLanguage(word: mainTranslation, language: targetLang) { synonyms in
                        
                        let result = TranslationResult(
                            original: word,
                            translation: mainTranslation,
                            informalTranslation: informalTranslation,
                            transcription: "",
                            ipaTranscription: enrichedData?.ipa,
                            exampleSentence: translatedExamples.first?.original ?? "",
                            exampleTranslation: translatedExamples.first?.translation ?? "",
                            exampleSentence2: translatedExamples.count > 1 ? translatedExamples[1].original : nil,
                            exampleTranslation2: translatedExamples.count > 1 ? translatedExamples[1].translation : nil,
                            synonyms: synonyms.isEmpty ? (enrichedData?.synonyms ?? []) : synonyms,
                            languagePair: "\(sourceLang)-\(targetLang)",
                            fromLanguage: sourceLang,
                            toLanguage: targetLang
                        )
                        
                        print("✅ DeepL: \(word) → \(mainTranslation) (informal: \(informalTranslation ?? "немає"))")
                        DispatchQueue.main.async { completion(.success(result)) }
                    }
                }
            }
        }
    }
    
    // Не всі мови підтримують formality в DeepL
    private func fetchInformalIfSupported(word: String, source: String, target: String, completion: @escaping (String?) -> Void) {
        // DeepL підтримує formality для: DE, FR, IT, ES, NL, PL, PT, RU, JA
        let supportsFormality = ["DE", "FR", "IT", "ES", "NL", "PL", "PT", "RU", "JA"]
        
        guard supportsFormality.contains(target) else {
            completion(nil)
            return
        }
        
        fetchTranslation(word: word, source: source, target: target, formality: "less") { result in
            completion(result)
        }
    }
    
    private func fetchTranslation(word: String, source: String, target: String, formality: String?, completion: @escaping (String?) -> Void) {
        let urlString = "https://api-free.deepl.com/v2/translate"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("DeepL-Auth-Key \(deepLKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var body = "source_lang=\(source)&target_lang=\(target)&text=\(encode(word))"
        if let formality = formality {
            body += "&formality=\(formality)"
        }
        
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ DeepL request error: \(error)")
                completion(nil)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ No HTTP response")
                completion(nil)
                return
            }
            
            print("📡 DeepL status: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode),
                  let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let translations = json["translations"] as? [[String: Any]],
                  let text = translations.first?["text"] as? String else {
                
                if let data = data, let str = String(data: data, encoding: .utf8) {
                    print("❌ DeepL response: \(str)")
                }
                completion(nil)
                return
            }
            
            completion(text)
        }.resume()
    }
    
    private func translateExamples(_ examples: [(original: String, translation: String)], source: String, target: String, completion: @escaping ([(original: String, translation: String)]) -> Void) {
        guard !examples.isEmpty else {
            completion([])
            return
        }
        
        let texts = examples.map { $0.original }
        let urlString = "https://api-free.deepl.com/v2/translate"
        
        guard let url = URL(string: urlString) else {
            completion(examples)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("DeepL-Auth-Key \(deepLKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var body = "source_lang=\(source)&target_lang=\(target)"
        for text in texts {
            body += "&text=\(encode(text))"
        }
        
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let translations = json["translations"] as? [[String: Any]] else {
                completion(examples)
                return
            }
            
            var result: [(original: String, translation: String)] = []
            for (i, trans) in translations.enumerated() {
                if i < examples.count, let text = trans["text"] as? String {
                    result.append((original: examples[i].original, translation: text))
                }
            }
            completion(result.isEmpty ? examples : result)
        }.resume()
    }
    
    private func fetchSynonymsForLanguage(word: String, language: String, completion: @escaping ([String]) -> Void) {
        if language == "en" {
            fetchEnglishSynonyms(word: word, completion: completion)
            return
        }
        completion([])
    }
    
    private func fetchEnglishSynonyms(word: String, completion: @escaping ([String]) -> Void) {
        let encodedWord = word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? word
        let urlString = "https://api.dictionaryapi.dev/api/v2/entries/en/\(encodedWord.lowercased())"
        
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                completion([])
                return
            }
            
            var allSynonyms: [String] = []
            
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    for entry in jsonArray {
                        if let meanings = entry["meanings"] as? [[String: Any]] {
                            for meaning in meanings {
                                if let synonyms = meaning["synonyms"] as? [String] {
                                    allSynonyms.append(contentsOf: synonyms)
                                }
                                if let definitions = meaning["definitions"] as? [[String: Any]] {
                                    for def in definitions {
                                        if let syn = def["synonyms"] as? [String] {
                                            allSynonyms.append(contentsOf: syn)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } catch {
                print("Помилка парсингу синонімів: \(error)")
            }
            
            let uniqueSynonyms = Array(Set(allSynonyms)).prefix(10).map { $0 }
            completion(self.filterSynonyms(uniqueSynonyms))
        }.resume()
    }
    
    private func fetchEnrichedData(word: String, sourceLang: String, targetLang: String, completion: @escaping (EnrichedWordData?) -> Void) {
        if sourceLang == "en" {
            fetchEnglishEnrichedData(word: word, completion: completion)
        } else {
            completion(EnrichedWordData(ipa: nil, examples: [], synonyms: [], partOfSpeech: nil))
        }
    }
    
    private func fetchEnglishEnrichedData(word: String, completion: @escaping (EnrichedWordData?) -> Void) {
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
            
            var ipa: String?
            var examples: [(String, String)] = []
            var synonyms: [String] = []
            
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    for entry in jsonArray {
                        if let phonetics = entry["phonetics"] as? [[String: Any]] {
                            for phonetic in phonetics {
                                if let text = phonetic["text"] as? String, !text.isEmpty {
                                    ipa = text
                                    break
                                }
                            }
                        }
                        
                        if let meanings = entry["meanings"] as? [[String: Any]] {
                            for meaning in meanings.prefix(2) {
                                if let defs = meaning["definitions"] as? [[String: Any]] {
                                    for def in defs.prefix(2) {
                                        if let example = def["example"] as? String {
                                            examples.append((example, ""))
                                        }
                                        if let syn = def["synonyms"] as? [String] {
                                            synonyms.append(contentsOf: syn)
                                        }
                                    }
                                }
                                if let syn = meaning["synonyms"] as? [String] {
                                    synonyms.append(contentsOf: syn)
                                }
                            }
                        }
                    }
                }
            } catch {
                print("Помилка: \(error)")
            }
            
            completion(EnrichedWordData(
                ipa: ipa,
                examples: examples,
                synonyms: Array(Set(synonyms)).prefix(10).map { $0 },
                partOfSpeech: nil
            ))
        }.resume()
    }
    
    func translateSynonyms(synonyms: [String], sourceLang: String, targetLang: String, completion: @escaping ([SynonymDetail]) -> Void) {
        guard !synonyms.isEmpty else {
            completion([])
            return
        }
        
        let deeplSource = deeplLanguageCode(sourceLang)
        let deeplTarget = deeplLanguageCode(targetLang)
        let urlString = "https://api-free.deepl.com/v2/translate"
        
        guard let url = URL(string: urlString) else {
            completion(synonyms.map { SynonymDetail(word: $0, ipaTranscription: nil, translation: $0, language: sourceLang) })
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("DeepL-Auth-Key \(deepLKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var body = "source_lang=\(deeplSource)&target_lang=\(deeplTarget)"
        for synonym in synonyms {
            body += "&text=\(encode(synonym))"
        }
        
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else {
                completion(synonyms.map { SynonymDetail(word: $0, ipaTranscription: nil, translation: $0, language: sourceLang) })
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let translations = json["translations"] as? [[String: Any]] {
                    
                    var details: [SynonymDetail] = []
                    for (i, trans) in translations.enumerated() {
                        guard i < synonyms.count else { break }
                        let original = synonyms[i]
                        let translated = trans["text"] as? String ?? original
                        details.append(SynonymDetail(word: original, ipaTranscription: nil, translation: translated, language: sourceLang))
                    }
                    completion(details)
                } else {
                    completion(synonyms.map { SynonymDetail(word: $0, ipaTranscription: nil, translation: $0, language: sourceLang) })
                }
            } catch {
                completion(synonyms.map { SynonymDetail(word: $0, ipaTranscription: nil, translation: $0, language: sourceLang) })
            }
        }.resume()
    }
    
    private func encode(_ string: String) -> String {
        return string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? string
    }
    
    private func filterSynonyms(_ synonyms: [String]) -> [String] {
        let blocked = ["motherfucker", "fuck", "shit", "damn", "ass", "bitch", "bastard", "crap", "hell"]
        return synonyms.filter { syn in
            let lower = syn.lowercased()
            return !blocked.contains(lower) && !blocked.contains { lower.contains($0) }
        }
    }
    func detectLanguageSync(_ text: String) -> String? {
        let specificChars: [(CharacterSet, String)] = [
            (CharacterSet(charactersIn: "ґєіїҐЄІЇ"), "uk"),
            (CharacterSet(charactersIn: "ąćęłńóśźżĄĆĘŁŃÓŚŹŻ"), "pl"),  // 🆕 Польські символи
            (CharacterSet(charactersIn: "äöüßÄÖÜẞ"), "de"),
            (CharacterSet(charactersIn: "àâæçéèêëïîôœùûüÿÀÂÆÇÉÈÊËÏÎÔŒÙÛÜŸ"), "fr"),
            (CharacterSet(charactersIn: "áéíóúüñÁÉÍÓÚÜÑ¿¡"), "es"),
            (CharacterSet(charactersIn: "àèéìòùÀÈÉÌÒÙ"), "it"),
            (CharacterSet(charactersIn: "ãõçÃÕÇ"), "pt"),
        ]
        
        for (charset, code) in specificChars {
            if text.rangeOfCharacter(from: charset) != nil {
                return code
            }
        }
        
        // 🆕 Додаткова перевірка для польських слів без специфічних символів
        let polishWords = ["dzień", "dobry", "cześć", "dziękuję", "proszę", "tak", "nie"]
        let lowerText = text.lowercased()
        for word in polishWords {
            if lowerText.contains(word) {
                return "pl"
            }
        }
        
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        if let dominant = recognizer.dominantLanguage {
            let code = dominant.rawValue
            let supported = ["uk", "en", "es", "de", "fr", "it", "pl", "pt"]
            if supported.contains(code) {
                return code
            }
        }
        
        let latinOnly = text.allSatisfy { char in
            String(char).rangeOfCharacter(from: .letters) == nil ||
            String(char).rangeOfCharacter(from: CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-' ")) != nil
        }
        
        return latinOnly ? "en" : nil
    }
    private func detectLanguage(_ text: String) -> String? {
        let specificChars: [(CharacterSet, String)] = [
            (CharacterSet(charactersIn: "ґєіїҐЄІЇ"), "uk"),
            (CharacterSet(charactersIn: "ąćęłńóśźżĄĆĘŁŃÓŚŹŻ"), "pl"),
            (CharacterSet(charactersIn: "äöüßÄÖÜẞ"), "de"),
            (CharacterSet(charactersIn: "àâæçéèêëïîôœùûüÿÀÂÆÇÉÈÊËÏÎÔŒÙÛÜŸ"), "fr"),
            (CharacterSet(charactersIn: "áéíóúüñÁÉÍÓÚÜÑ¿¡"), "es"),
            (CharacterSet(charactersIn: "àèéìòùÀÈÉÌÒÙ"), "it"),
            (CharacterSet(charactersIn: "ãõçÃÕÇ"), "pt"),
        ]
        
        for (charset, code) in specificChars {
            if text.rangeOfCharacter(from: charset) != nil {
                return code
            }
        }
        
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        if let dominant = recognizer.dominantLanguage {
            let code = dominant.rawValue
            let supported = ["uk", "en", "es", "de", "fr", "it", "pl", "pt"]
            if supported.contains(code) {
                return code
            }
        }
        
        let latinOnly = text.allSatisfy { char in
            String(char).rangeOfCharacter(from: .letters) == nil ||
            String(char).rangeOfCharacter(from: CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-' ")) != nil
        }
        
        return latinOnly ? "en" : nil
    }
    
    private func deeplLanguageCode(_ code: String) -> String {
        let mapping = ["uk": "UK", "en": "EN", "es": "ES", "de": "DE", "fr": "FR", "it": "IT", "pl": "PL", "pt": "PT"]
        return mapping[code] ?? "EN"
    }
    
    // MARK: - New method with explicit from/to languages

    func translate(word: String, fromLanguage: String, toLanguage: String, completion: @escaping (Result<TranslationResult, TranslationError>) -> Void) {
        guard !word.isEmpty else {
            completion(.failure(.noData))
            return
        }
        
        // Перевірка та конвертація мов
        let sourceLang = languageNameToCode(fromLanguage)
        let targetLang = languageNameToCode(toLanguage)
        
        guard !sourceLang.isEmpty, !targetLang.isEmpty else {
            print("❌ Помилка: порожній код мови. source: '\(fromLanguage)'->'\(sourceLang)', target: '\(toLanguage)'->'\(targetLang)'")
            completion(.failure(.invalidResponse))
            return
        }
        
        print("🔍 === ПЕРЕКЛАД ===")
        print("   Слово: '\(word)'")
        print("   Напрямок: \(sourceLang) → \(targetLang)")
        
        fetchEnrichedData(word: word, sourceLang: sourceLang, targetLang: targetLang) { [weak self] enrichedData in
            self?.performDeepLTranslation(
                word: word,
                sourceLang: sourceLang,
                targetLang: targetLang,
                enrichedData: enrichedData,
                completion: completion
            )
        }
    }
    
    private func languageNameToCode(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        
        let mapping = [
            "uk": "uk", "українська": "uk", "ukrainian": "uk",
            "en": "en", "english": "en", "англійська": "en",
            "de": "de", "deutsch": "de", "німецька": "de", "german": "de",
            "pl": "pl", "polski": "pl", "польська": "pl", "polish": "pl",
            "es": "es", "español": "es", "іспанська": "es", "spanish": "es",
            "fr": "fr", "français": "fr", "французька": "fr", "french": "fr",
            "it": "it", "italiano": "it", "італійська": "it", "italian": "it",
            "pt": "pt", "português": "pt", "португальська": "pt", "portuguese": "pt"
        ]
        
        let lowercased = trimmed.lowercased()
        let result = mapping[lowercased] ?? lowercased
        
        // Додаткова перевірка - якщо результат не в списку підтримуваних, повертаємо порожній
        let supported = ["uk", "en", "es", "de", "fr", "it", "pl", "pt"]
        return supported.contains(result) ? result : ""
    }
}
