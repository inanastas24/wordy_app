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

    // MARK: - Main translate method (SIMPLIFIED)
    
    /// Переклад з явно вказаними мовами (без автоматичного визначення)
    func translate(word: String, fromLanguage: String, toLanguage: String, completion: @escaping (Result<TranslationResult, TranslationError>) -> Void) {
        guard !word.isEmpty else {
            completion(.failure(.noData))
            return
        }

        let normalizedWord = QueryNormalizer.normalize(word, language: fromLanguage)
        let query = normalizedWord.isEmpty ? word : normalizedWord
        
        // Конвертуємо коди мов
        let sourceLang = fromLanguage.lowercased()
        let targetLang = toLanguage.lowercased()

        print("🔍 === ПЕРЕКЛАД ===")
        print("   Слово: '\(query)'")
        print("   Напрямок: \(sourceLang) → \(targetLang)")

        fetchEnrichedData(word: query, sourceLang: sourceLang, targetLang: targetLang) { [weak self] enrichedData in
            self?.performDeepLTranslation(
                word: query,
                sourceLang: sourceLang,
                targetLang: targetLang,
                enrichedData: enrichedData,
                completion: completion
            )
        }
    }

    // MARK: - Improved Language Detection (for determining search direction)
    
    /// Визначає мову тексту (використовується тільки для визначення напрямку)
    func detectLanguageSync(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let lowercased = trimmed.lowercased()

        // MARK: - Крок 1: Перевірка специфічних символів (найвищий пріоритет)

        // Українські специфічні символи (є, ї, і, ґ)
        let ukrainianSpecific = CharacterSet(charactersIn: "єїіґЄЇІҐ")
        if trimmed.rangeOfCharacter(from: ukrainianSpecific) != nil {
            print("🔍 Мова визначена як українська (специфічні символи)")
            return "uk"
        }

        // Польські специфічні символи
        let polishSpecific = CharacterSet(charactersIn: "ąćęłńóśźżĄĆĘŁŃÓŚŹŻ")
        if trimmed.rangeOfCharacter(from: polishSpecific) != nil {
            print("🔍 Мова визначена як польська (специфічні символи)")
            return "pl"
        }

        // Німецькі специфічні символи
        let germanSpecific = CharacterSet(charactersIn: "äöüßÄÖÜẞ")
        if trimmed.rangeOfCharacter(from: germanSpecific) != nil {
            return "de"
        }

        // Французькі специфічні символи
        let frenchSpecific = CharacterSet(charactersIn: "àâæçéèêëïîôœùûüÿÀÂÆÇÉÈÊËÏÎÔŒÙÛÜŸ")
        if trimmed.rangeOfCharacter(from: frenchSpecific) != nil {
            return "fr"
        }

        // Іспанські специфічні символи
        let spanishSpecific = CharacterSet(charactersIn: "áéíóúüñÁÉÍÓÚÜÑ¿¡")
        if trimmed.rangeOfCharacter(from: spanishSpecific) != nil {
            return "es"
        }

        // Італійські специфічні символи
        let italianSpecific = CharacterSet(charactersIn: "àèéìòùÀÈÉÌÒÙ")
        if trimmed.rangeOfCharacter(from: italianSpecific) != nil {
            return "it"
        }

        // MARK: - Крок 2: Перевірка загальних слів

        // Українські слова (без специфічних символів, але характерні)
        let ukrainianWords = [
            "воля", "слово", "мова", "дім", "робота", "діти", "життя",
            "любов", "друг", "сонце", "вода", "ніч", "день", "рік",
            "рука", "око", "голова", "серце", "дорога", "місто",
            "країна", "народ", "земля", "небо", "час", "річ",
            "думка", "сила", "правда", "вільність"
        ]
        if ukrainianWords.contains(lowercased) {
            print("🔍 Мова визначена як українська (загальне слово)")
            return "uk"
        }

        // Польські слова (без специфічних символів, але характерні)
        let polishWords = [
            "dzień", "dobry", "cześć", "dziękuję", "proszę", "tak", "nie",
            "miłość", "praca", "dom", "rok", "czas", "życie", "świat",
            "człowiek", "dziecko", "kobieta", "mężczyzna", "miasto", "kraj",
            "woda", "ogień", "ziemia", "powietrze", "serce", "dusza"
        ]
        if polishWords.contains(lowercased) {
            print("🔍 Мова визначена як польська (загальне слово)")
            return "pl"
        }

        // MARK: - Крок 3: Перевірка написання (кирилиця vs латиниця)

        let cyrillicChars = CharacterSet(charactersIn:
            "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ" +
            "абвгдеёжзийклмнопрстуфхцчшщъыьэюя"
        )

        let latinChars = CharacterSet(charactersIn:
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
        )

        let hasCyrillic = trimmed.rangeOfCharacter(from: cyrillicChars) != nil
        let hasLatin = trimmed.rangeOfCharacter(from: latinChars) != nil

        // Якщо тільки кирилиця - це або українська, або російська
        if hasCyrillic && !hasLatin {
            // Перевіряємо на російські специфічні символи
            let russianSpecific = CharacterSet(charactersIn: "ыэъёЫЭЪЁ")
            if trimmed.rangeOfCharacter(from: russianSpecific) != nil {
                print("🔍 Мова визначена як російська (специфічні символи)")
                return nil // Російська не підтримується
            }

            // Якщо немає українських специфічних символів, але є кирилиця
            // і слово коротке - це ймовірно українська (або російська)
            // Для коротких слів без специфічних символів використовуємо NLLanguageRecognizer
            // але з підказкою
            let recognizer = NLLanguageRecognizer()
            recognizer.languageHints = [.ukrainian: 0.6, .russian: 0.3, .polish: 0.1]
            recognizer.processString(trimmed)

            if let dominant = recognizer.dominantLanguage {
                let code = dominant.rawValue
                if code == "uk" || code == "ru" {
                    print("🔍 Кирилиця визначена як: \(code)")
                    return code == "ru" ? nil : "uk"
                }
            }

            // За замовчуванням для кирилиці - українська
            print("🔍 Кирилиця без чіткого визначення -> українська")
            return "uk"
        }

        // MARK: - Крок 4: Використання NLLanguageRecognizer для латиниці

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(trimmed)

        if let dominant = recognizer.dominantLanguage {
            let code = dominant.rawValue
            let supported = ["en", "es", "de", "fr", "it", "pl", "pt"]

            if supported.contains(code) {
                print("🔍 NLLanguageRecognizer визначив: \(code)")
                return code
            }
        }

        // MARK: - Крок 5: За замовчуванням

        // Якщо тільки латиниця - англійська
        if hasLatin && !hasCyrillic {
            print("🔍 Тільки латиниця -> англійська")
            return "en"
        }

        return nil
    }

    // MARK: - Private Methods

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

                        let informalText = informalTranslation ?? "немає"
                        print("✅ DeepL: \(word) → \(mainTranslation) (informal: \(informalText))")
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

    private func deeplLanguageCode(_ code: String) -> String {
        let mapping = ["uk": "UK", "en": "EN", "es": "ES", "de": "DE", "fr": "FR", "it": "IT", "pl": "PL", "pt": "PT", "ar": "AR", "bg": "BG", "zh": "ZH", "cs": "CS", "da": "DA", "nl": "NL", "et": "ET", "fi": "FI", "el": "EL", "hu": "HU", "id": "ID", "ja": "JA", "ko": "KO", "lv": "LV", "lt": "LT", "nb": "NB", "ro": "RO", "ru": "RU", "sk": "SK", "sl": "SL", "sv": "SV", "tr": "TR"]
        return mapping[code] ?? "EN"
    }
}

