import Foundation

struct ProviderChainTranslationResult {
    let wordCard: WordCard
}

final class ProviderChainTranslationService {
    private let session: URLSession
    private let configService: ConfigService

    init(session: URLSession = .shared, configService: ConfigService = .shared) {
        self.session = session
        self.configService = configService
    }

    func translate(text: String, sourceLanguage: String, targetLanguage: String) async throws -> ProviderChainTranslationResult {
        let normalized = QueryNormalizer.normalize(text, language: sourceLanguage)

        let translationCandidates = try await fetchTranslationCandidates(
            text: text,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )

        let main = translationCandidates.first?.value ?? ""
        guard !main.isEmpty else {
            throw TranslationError.emptyResponse
        }

        let definitionsPayload = try await fetchDefinitions(
            word: normalized,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            preferredTranslation: main,
            translationCandidates: translationCandidates
        )

        let card = WordCard(
            originalText: text,
            normalizedText: normalized,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            inputType: normalized.contains(" ") ? .phrase : .word,
            mainTranslation: main,
            translations: translationCandidates,
            meanings: definitionsPayload.meanings,
            examples: definitionsPayload.examples,
            synonyms: definitionsPayload.synonyms,
            antonyms: definitionsPayload.antonyms,
            relatedPhrases: [],
            backendEngineVersion: "provider-chain-v1",
            pronunciation: definitionsPayload.pronunciation,
            ipaTranscription: definitionsPayload.ipa
        )

        if card.inputType == .word && card.meanings.isEmpty {
            throw TranslationError.noData
        }

        return ProviderChainTranslationResult(wordCard: card)
    }

    private func fetchTranslationCandidates(text: String, sourceLanguage: String, targetLanguage: String) async throws -> [TranslationOption] {
        if let deeplKey = configService.get("DEEPL_API_KEY"), !deeplKey.isEmpty {
            if let deeplOptions = try? await translateWithDeepL(
                text: text,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                apiKey: deeplKey
            ), !deeplOptions.isEmpty {
                return deeplOptions
            }
        }

        return try await translateWithGoogle(
            text: text,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )
    }

    private func translateWithDeepL(text: String, sourceLanguage: String, targetLanguage: String, apiKey: String) async throws -> [TranslationOption] {
        guard let url = URL(string: "https://api-free.deepl.com/v2/translate") else {
            throw TranslationError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        let source = deeplCode(sourceLanguage)
        let target = deeplCode(targetLanguage)
        let payload = "text=\(urlEncode(text))&source_lang=\(source)&target_lang=\(target)"
        request.httpBody = payload.data(using: .utf8)
        request.setValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw TranslationError.backendUnavailable
        }

        struct DeepLResponse: Decodable {
            struct Item: Decodable { let text: String }
            let translations: [Item]
        }

        let decoded = try JSONDecoder().decode(DeepLResponse.self, from: data)
        let unique = Array(Set(decoded.translations.map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) })).filter { !$0.isEmpty }
        return unique.enumerated().map { index, value in
            TranslationOption(
                value: value,
                partOfSpeech: "unknown",
                confidence: index == 0 ? 0.9 : 0.75,
                sourceType: .deeplDirect,
                examples: []
            )
        }
    }

    private func translateWithGoogle(text: String, sourceLanguage: String, targetLanguage: String) async throws -> [TranslationOption] {
        var components = URLComponents(string: "https://translate.googleapis.com/translate_a/single")
        components?.queryItems = [
            URLQueryItem(name: "client", value: "gtx"),
            URLQueryItem(name: "sl", value: sourceLanguage),
            URLQueryItem(name: "tl", value: targetLanguage),
            URLQueryItem(name: "dt", value: "t"),
            URLQueryItem(name: "dt", value: "bd"),
            URLQueryItem(name: "dt", value: "at"),
            URLQueryItem(name: "q", value: text)
        ]
        guard let url = components?.url else { throw TranslationError.invalidURL }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw TranslationError.backendUnavailable
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [Any],
              let sentences = json.first as? [Any] else {
            throw TranslationError.decodingError
        }

        var results: [String] = []
        for item in sentences {
            guard let arr = item as? [Any], let translated = arr.first as? String else { continue }
            let trimmed = translated.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { results.append(trimmed) }
        }

        let merged = results.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !merged.isEmpty else { throw TranslationError.emptyResponse }

        var alternatives: [(value: String, pos: String)] = []
        var primaryPOS: String = "unknown"
        if json.count > 1, let dictEntries = json[1] as? [Any] {
            for entry in dictEntries {
                guard let row = entry as? [Any] else { continue }
                let pos = (row.first as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "unknown"
                if primaryPOS == "unknown", !pos.isEmpty {
                    primaryPOS = pos
                }
                if row.count > 1, let terms = row[1] as? [String] {
                    alternatives.append(contentsOf: terms.map { ($0, pos) })
                }
            }
        }

        struct Candidate {
            let value: String
            let pos: String
            let confidence: Double
            let sourceType: TranslationOptionSourceType
        }

        var rawCandidates: [Candidate] = []
        rawCandidates.append(
            Candidate(
                value: merged,
                pos: primaryPOS,
                confidence: 0.84,
                sourceType: .googleAlternative
            )
        )

        for (index, alt) in alternatives.enumerated() {
            let confidence = max(0.45, 0.8 - Double(index) * 0.04)
            rawCandidates.append(
                Candidate(
                    value: alt.value,
                    pos: alt.pos,
                    confidence: confidence,
                    sourceType: .googleAlternative
                )
            )
        }

        var uniqueOrdered: [Candidate] = []
        for candidate in rawCandidates {
            let trimmed = candidate.value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            if let existingIndex = uniqueOrdered.firstIndex(where: { $0.value.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                let existing = uniqueOrdered[existingIndex]
                let betterPOS = existing.pos == "unknown" && candidate.pos != "unknown"
                if candidate.confidence > existing.confidence || betterPOS {
                    uniqueOrdered[existingIndex] = Candidate(
                        value: trimmed,
                        pos: betterPOS ? candidate.pos : existing.pos,
                        confidence: max(existing.confidence, candidate.confidence),
                        sourceType: existing.sourceType
                    )
                }
            } else {
                uniqueOrdered.append(
                    Candidate(
                        value: trimmed,
                        pos: candidate.pos,
                        confidence: candidate.confidence,
                        sourceType: candidate.sourceType
                    )
                )
            }
        }

        return uniqueOrdered.prefix(10).map { candidate in
            TranslationOption(
                value: candidate.value,
                partOfSpeech: candidate.pos,
                confidence: candidate.confidence,
                sourceType: candidate.sourceType,
                examples: []
            )
        }
    }

    private struct DefinitionsPayload {
        let meanings: [MeaningContent]
        let examples: [WordExample]
        let synonyms: [WordSynonym]
        let antonyms: [WordSynonym]
        let pronunciation: String?
        let ipa: String?
    }

    private func fetchDefinitions(
        word: String,
        sourceLanguage: String,
        targetLanguage: String,
        preferredTranslation: String,
        translationCandidates: [TranslationOption]
    ) async throws -> DefinitionsPayload {
        if let wordnik = try? await fetchFromWordnik(
            word: word,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            preferredTranslation: preferredTranslation,
            translationCandidates: translationCandidates
        ), !wordnik.meanings.isEmpty {
            print("[ProviderChain] definitions source=wordnik meanings=\(wordnik.meanings.count) examples=\(wordnik.examples.count)")
            return wordnik
        }

        if let free = try? await fetchFromFreeDictionary(
            word: word,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            preferredTranslation: preferredTranslation,
            translationCandidates: translationCandidates
        ) {
            print("[ProviderChain] definitions source=freedictionary meanings=\(free.meanings.count) examples=\(free.examples.count)")
            return free
        }

        print("[ProviderChain] definitions source=wiktionary (fallback)")
        return try await fetchFromWiktionary(
            word: word,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            preferredTranslation: preferredTranslation,
            translationCandidates: translationCandidates
        )
    }

    private func fetchFromWordnik(
        word: String,
        sourceLanguage: String,
        targetLanguage: String,
        preferredTranslation: String,
        translationCandidates: [TranslationOption]
    ) async throws -> DefinitionsPayload {
        guard let apiKey = configService.get("WORDNIK_API_KEY"), !apiKey.isEmpty else {
            throw TranslationError.emptyAPIKey
        }

        let lookupWord: String
        if sourceLanguage.lowercased() == "en" {
            lookupWord = word
        } else if targetLanguage.lowercased() == "en" {
            lookupWord = preferredTranslation
        } else {
            throw TranslationError.unsupportedLanguagePair
        }

        let cleanedLookup = lookupWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedLookup.isEmpty else { throw TranslationError.emptyResponse }

        guard let encodedWord = cleanedLookup.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw TranslationError.invalidURL
        }

        var definitionsComponents = URLComponents(string: "https://api.wordnik.com/v4/word.json/\(encodedWord)/definitions")
        definitionsComponents?.queryItems = [
            URLQueryItem(name: "limit", value: "8"),
            URLQueryItem(name: "includeRelated", value: "false"),
            URLQueryItem(name: "useCanonical", value: "true"),
            URLQueryItem(name: "includeTags", value: "true"),
            URLQueryItem(name: "api_key", value: apiKey)
        ]
        guard let definitionsURL = definitionsComponents?.url else {
            throw TranslationError.invalidURL
        }

        var examplesComponents = URLComponents(string: "https://api.wordnik.com/v4/word.json/\(encodedWord)/examples")
        examplesComponents?.queryItems = [
            URLQueryItem(name: "limit", value: "8"),
            URLQueryItem(name: "includeDuplicates", value: "false"),
            URLQueryItem(name: "useCanonical", value: "true"),
            URLQueryItem(name: "skip", value: "0"),
            URLQueryItem(name: "api_key", value: apiKey)
        ]
        guard let examplesURL = examplesComponents?.url else {
            throw TranslationError.invalidURL
        }

        struct WordnikDefinitionItem: Decodable {
            let text: String?
            let partOfSpeech: String?
        }
        struct WordnikExampleItem: Decodable {
            let text: String?
        }
        struct WordnikExamplesResponse: Decodable {
            let examples: [WordnikExampleItem]?
        }

        let (definitionsData, definitionsResponse) = try await session.data(from: definitionsURL)
        guard let definitionsHTTP = definitionsResponse as? HTTPURLResponse else {
            throw TranslationError.invalidResponse
        }
        if definitionsHTTP.statusCode == 404 {
            throw TranslationError.noData
        }
        guard (200...299).contains(definitionsHTTP.statusCode) else {
            throw TranslationError.backendUnavailable
        }

        let definitionItems = try JSONDecoder().decode([WordnikDefinitionItem].self, from: definitionsData)
        guard !definitionItems.isEmpty else {
            throw TranslationError.noData
        }

        let (examplesData, examplesResponse) = try await session.data(from: examplesURL)
        let exampleItems: [WordnikExampleItem]
        if let examplesHTTP = examplesResponse as? HTTPURLResponse, (200...299).contains(examplesHTTP.statusCode) {
            let decodedExamples = try? JSONDecoder().decode(WordnikExamplesResponse.self, from: examplesData)
            exampleItems = decodedExamples?.examples ?? []
        } else {
            exampleItems = []
        }

        let sourceLangForMeaning = "en"
        let targetLangForMeaning = targetLanguage

        var meanings: [MeaningContent] = []
        var examples: [WordExample] = []
        var usedExampleTexts = Set<String>()

        let usableDefinitions = definitionItems
            .compactMap { item -> (text: String, pos: String)? in
                let text = (item.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return nil }
                return (text, item.partOfSpeech ?? "unknown")
            }
            .prefix(6)

        for definition in usableDefinitions {
            let meaningId = UUID()
            let translatedDefinition = (try? await quickTranslate(definition.text, from: sourceLangForMeaning, to: targetLangForMeaning))

            var chosenExample: String?
            for example in exampleItems {
                let text = (example.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { continue }
                if usedExampleTexts.contains(text.lowercased()) { continue }
                if text.lowercased().contains(cleanedLookup.lowercased()) {
                    chosenExample = text
                    break
                }
            }

            var meaningExamples: [WordExample] = []
            if let sourceExample = chosenExample {
                usedExampleTexts.insert(sourceExample.lowercased())
                let translatedExample = (try? await quickTranslate(sourceExample, from: sourceLangForMeaning, to: targetLangForMeaning)) ?? ""
                let ex = WordExample(
                    sourceText: sourceExample,
                    targetText: translatedExample,
                    sourceLanguage: sourceLangForMeaning,
                    targetLanguage: targetLangForMeaning,
                    meaningId: meaningId,
                    translationOptionId: translationCandidates.first?.id
                )
                meaningExamples = [ex]
                examples.append(ex)
            }

            meanings.append(
                MeaningContent(
                    id: meaningId,
                    title: nil,
                    meaning: definition.text,
                    meaningLanguage: sourceLangForMeaning,
                    translation: translatedDefinition,
                    translationLanguage: targetLangForMeaning,
                    explanation: nil,
                    explanationLanguage: sourceLangForMeaning,
                    partOfSpeech: NormalizedPartOfSpeech(rawValue: definition.pos),
                    domain: "general",
                    translations: translationCandidates,
                    examples: meaningExamples,
                    wordForms: [],
                    wordFormGroups: []
                )
            )
        }

        if meanings.isEmpty {
            throw TranslationError.noData
        }

        return DefinitionsPayload(
            meanings: meanings,
            examples: examples,
            synonyms: [],
            antonyms: [],
            pronunciation: nil,
            ipa: nil
        )
    }

    private func fetchFromFreeDictionary(
        word: String,
        sourceLanguage: String,
        targetLanguage: String,
        preferredTranslation: String,
        translationCandidates: [TranslationOption]
    ) async throws -> DefinitionsPayload {
        // dictionaryapi supports limited languages; if unsupported, throw and fallback to Wiktionary.
        let languageCode = dictionaryApiLanguage(sourceLanguage)
        guard !languageCode.isEmpty else { throw TranslationError.unsupportedLanguagePair }

        let details = try await DictionaryAPIService.shared.fetchWordDetails(word: word, language: languageCode)
        let normalizedPOS = details.partOfSpeech ?? "unknown"
        let posAdjustedCandidates = translationCandidates.map { option in
            TranslationOption(
                id: option.id,
                value: option.value,
                partOfSpeech: (option.partOfSpeech == nil || option.partOfSpeech == "unknown") ? normalizedPOS : option.partOfSpeech,
                gender: option.gender,
                meaningId: option.meaningId,
                confidence: option.confidence,
                shortGrammarLabel: option.shortGrammarLabel,
                sourceType: option.sourceType,
                examples: option.examples
            )
        }

        var meanings: [MeaningContent] = []
        var examples: [WordExample] = []

        for (index, definition) in details.definitions.prefix(4).enumerated() {
            let meaningId = UUID()
            let maybeExample = details.examples.indices.contains(index) ? details.examples[index] : details.examples.first

            var meaningExamples: [WordExample] = []
            if let sourceExample = maybeExample, !sourceExample.isEmpty {
                let translatedExample = (try? await quickTranslate(sourceExample, from: sourceLanguage, to: targetLanguage)) ?? ""
                let ex = WordExample(
                    sourceText: sourceExample,
                    targetText: translatedExample,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage,
                    meaningId: meaningId,
                    translationOptionId: posAdjustedCandidates.first?.id
                )
                meaningExamples = [ex]
                examples.append(ex)
            }

            let translatedDefinition = (try? await quickTranslate(definition, from: sourceLanguage, to: targetLanguage))

            meanings.append(
                MeaningContent(
                    id: meaningId,
                    title: nil,
                    meaning: definition,
                    meaningLanguage: sourceLanguage,
                    translation: translatedDefinition,
                    translationLanguage: targetLanguage,
                    explanation: nil,
                    explanationLanguage: sourceLanguage,
                    partOfSpeech: NormalizedPartOfSpeech(rawValue: details.partOfSpeech ?? "unknown"),
                    domain: "general",
                    translations: posAdjustedCandidates,
                    examples: meaningExamples,
                    wordForms: [],
                    wordFormGroups: []
                )
            )
        }

        var synonyms: [WordSynonym] = []
        for synonym in details.synonyms.prefix(8) {
            let translated = (try? await quickTranslate(synonym, from: sourceLanguage, to: targetLanguage)) ?? ""
            synonyms.append(
                WordSynonym(
                    text: synonym,
                    language: sourceLanguage,
                    translation: translated,
                    translationLanguage: targetLanguage,
                    partOfSpeech: details.partOfSpeech,
                    relevance: 0.64
                )
            )
        }

        var antonyms: [WordSynonym] = []
        for antonym in details.antonyms.prefix(6) {
            let translated = (try? await quickTranslate(antonym, from: sourceLanguage, to: targetLanguage)) ?? ""
            antonyms.append(
                WordSynonym(
                    text: antonym,
                    language: sourceLanguage,
                    translation: translated,
                    translationLanguage: targetLanguage,
                    partOfSpeech: details.partOfSpeech,
                    relevance: 0.64
                )
            )
        }

        return DefinitionsPayload(
            meanings: meanings,
            examples: examples,
            synonyms: synonyms,
            antonyms: antonyms,
            pronunciation: details.transcription,
            ipa: details.transcription
        )
    }

    private func fetchFromWiktionary(
        word: String,
        sourceLanguage: String,
        targetLanguage: String,
        preferredTranslation: String,
        translationCandidates: [TranslationOption]
    ) async throws -> DefinitionsPayload {
        let encoded = word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? word
        guard let url = URL(string: "https://en.wiktionary.org/api/rest_v1/page/definition/\(encoded)") else {
            throw TranslationError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw TranslationError.backendUnavailable
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw TranslationError.decodingError
        }

        let sourceBucket = wiktionaryLanguageKey(sourceLanguage)
        let entries = json[sourceBucket] as? [[String: Any]] ?? []

        var meanings: [MeaningContent] = []
        var examples: [WordExample] = []

        for entry in entries.prefix(4) {
            let definitionText = (entry["definition"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !definitionText.isEmpty else { continue }
            let meaningId = UUID()

            let translatedDefinition = (try? await quickTranslate(definitionText, from: sourceLanguage, to: targetLanguage))

            var meaningExamples: [WordExample] = []
            if let rawExamples = entry["examples"] as? [String], let first = rawExamples.first, !first.isEmpty {
                let translatedExample = (try? await quickTranslate(first, from: sourceLanguage, to: targetLanguage)) ?? ""
                let ex = WordExample(
                    sourceText: first,
                    targetText: translatedExample,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage,
                    meaningId: meaningId,
                    translationOptionId: translationCandidates.first?.id
                )
                meaningExamples = [ex]
                examples.append(ex)
            }

            let pos = (entry["partOfSpeech"] as? String) ?? "unknown"
            meanings.append(
                MeaningContent(
                    id: meaningId,
                    title: nil,
                    meaning: definitionText,
                    meaningLanguage: sourceLanguage,
                    translation: translatedDefinition,
                    translationLanguage: targetLanguage,
                    explanation: nil,
                    explanationLanguage: sourceLanguage,
                    partOfSpeech: NormalizedPartOfSpeech(rawValue: pos),
                    domain: "general",
                    translations: translationCandidates,
                    examples: meaningExamples,
                    wordForms: [],
                    wordFormGroups: []
                )
            )
        }

        if meanings.isEmpty {
            // Soft fallback: keep at least translation card if definitions unavailable.
            return DefinitionsPayload(
                meanings: [],
                examples: [],
                synonyms: [],
                antonyms: [],
                pronunciation: nil,
                ipa: nil
            )
        }

        return DefinitionsPayload(
            meanings: meanings,
            examples: examples,
            synonyms: [],
            antonyms: [],
            pronunciation: nil,
            ipa: nil
        )
    }

    private func quickTranslate(_ text: String, from sourceLanguage: String, to targetLanguage: String) async throws -> String {
        let result = try await translateWithGoogle(text: text, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
        return result.first?.value ?? ""
    }

    private func deeplCode(_ language: String) -> String {
        switch language.lowercased() {
        case "en": return "EN"
        case "uk": return "UK"
        case "es": return "ES"
        case "pl": return "PL"
        case "de": return "DE"
        case "fr": return "FR"
        case "it": return "IT"
        case "pt": return "PT"
        case "ru": return "RU"
        case "ja": return "JA"
        case "zh": return "ZH"
        default: return language.uppercased()
        }
    }

    private func dictionaryApiLanguage(_ language: String) -> String {
        switch language.lowercased() {
        case "en": return "en"
        case "es": return "es"
        case "fr": return "fr"
        case "de": return "de"
        case "it": return "it"
        case "pt": return "pt"
        case "ru": return "ru"
        default: return ""
        }
    }

    private func wiktionaryLanguageKey(_ language: String) -> String {
        switch language.lowercased() {
        case "en": return "en"
        case "uk": return "uk"
        case "es": return "es"
        case "pl": return "pl"
        case "de": return "de"
        case "fr": return "fr"
        case "it": return "it"
        case "pt": return "pt"
        case "ru": return "ru"
        default: return "en"
        }
    }

    private func urlEncode(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
    }
}
