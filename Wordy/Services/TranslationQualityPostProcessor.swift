import Foundation

struct TranslationQualityPostProcessor {
    func process(_ card: WordCard) -> WordCard {
        if card.inputType == .idiom {
            return card
        }

        let filteredMeanings = selectBestMeanings(
            card.meanings,
            using: card.translations,
            examples: card.examples
        )
        let keptMeaningIds = Set(filteredMeanings.map(\.id))

        let filteredExamples = selectBestExamples(card.examples, keptMeaningIds: keptMeaningIds)

        let improvedMainTranslation = chooseMainTranslation(
            from: card.translations,
            meanings: filteredMeanings,
            examples: filteredExamples,
            fallback: card.mainTranslation
        )

        return WordCard(
            id: card.id,
            originalText: card.originalText,
            normalizedText: card.normalizedText,
            sourceLanguage: card.sourceLanguage,
            targetLanguage: card.targetLanguage,
            inputType: card.inputType,
            mainTranslation: improvedMainTranslation,
            translations: card.translations,
            meanings: filteredMeanings,
            examples: filteredExamples,
            synonyms: card.synonyms,
            antonyms: card.antonyms,
            relatedPhrases: card.relatedPhrases,
            createdAt: card.createdAt,
            updatedAt: card.updatedAt,
            backendEngineVersion: card.backendEngineVersion,
            pronunciation: card.pronunciation,
            ipaTranscription: card.ipaTranscription
        )
    }

    private func chooseMainTranslation(
        from options: [TranslationOption],
        meanings: [MeaningContent],
        examples: [WordExample],
        fallback: String
    ) -> String {
        guard !options.isEmpty else { return fallback }

        let meaningTranslations = Set(
            meanings
                .flatMap(\.translations)
                .map { normalizeToken($0.value) }
                .filter { !$0.isEmpty }
        )

        let exampleTargets = examples.map { normalizeText($0.targetText) }

        // Strong preference: if a translation candidate is explicitly used in target examples,
        // prioritize those candidates first (real contextual usage beats raw rank order).
        let candidatesUsedInExamples = options.filter { option in
            let token = normalizeToken(option.value)
            guard !token.isEmpty else { return false }
            return exampleTargets.contains(where: { $0.contains(token) })
        }
        if let contextWinner = candidatesUsedInExamples.max(by: { lhs, rhs in
            score(option: lhs, meaningTranslations: meaningTranslations, exampleTargets: exampleTargets)
            < score(option: rhs, meaningTranslations: meaningTranslations, exampleTargets: exampleTargets)
        }) {
            return contextWinner.value
        }

        let best = options.max { lhs, rhs in
            score(option: lhs, meaningTranslations: meaningTranslations, exampleTargets: exampleTargets)
            < score(option: rhs, meaningTranslations: meaningTranslations, exampleTargets: exampleTargets)
        }

        return best?.value ?? fallback
    }

    private func score(
        option: TranslationOption,
        meaningTranslations: Set<String>,
        exampleTargets: [String]
    ) -> Double {
        let normalized = normalizeToken(option.value)
        var value = option.confidence ?? 0

        if meaningTranslations.contains(normalized) {
            value += 0.35
        }

        if exampleTargets.contains(where: { $0.contains(normalized) }) {
            value += 0.45
        }

        switch option.sourceType {
        case .dictionary, .meaningDerived, .contextual:
            value += 0.2
        default:
            break
        }

        if option.value.contains(".") || option.value.contains("!") || option.value.contains("?") {
            value -= 0.25
        }

        return value
    }

    private func selectBestMeanings(
        _ meanings: [MeaningContent],
        using options: [TranslationOption],
        examples: [WordExample]
    ) -> [MeaningContent] {
        guard !meanings.isEmpty else { return meanings }

        let dominantPOS = dominantPartOfSpeech(from: options)
        let baseFiltered = meanings.filter { meaning in
            let meaningPOS = normalizePOS(meaning.partOfSpeech.rawValue)

            // Keep if POS matches dominant translation POS.
            if let dominantPOS, !dominantPOS.isEmpty {
                if meaningPOS == dominantPOS || meaningPOS == "unknown" {
                    return true
                }

                // If meaning has a strong translation overlap, still keep it.
                if hasStrongTranslationOverlap(meaning: meaning, options: options) {
                    return true
                }

                return false
            }

            return true
        }

        let scoped = baseFiltered.isEmpty ? meanings : baseFiltered

        // If we have enough quality senses in dominant POS, prefer them to avoid noisy cross-POS leakage.
        let dominantScoped: [MeaningContent]
        if let dominantPOS, !dominantPOS.isEmpty {
            let dominantOnly = scoped.filter { normalizePOS($0.partOfSpeech.rawValue) == dominantPOS }
            dominantScoped = dominantOnly.count >= 2 ? dominantOnly : scoped
        } else {
            dominantScoped = scoped
        }

        let dedupedScoped = dedupeMeanings(dominantScoped)

        let hasAnyLinkedExamples = dedupedScoped.contains { meaning in
            examples.contains(where: { $0.meaningId == meaning.id })
        }

        let ranked = dedupedScoped
            .map { meaning in
                (
                    meaning: meaning,
                    score: meaningQualityScore(
                        meaning,
                        options: options,
                        allExamples: examples
                    )
                )
            }
            .filter { $0.score > 0.15 }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score { return lhs.meaning.definition.count > rhs.meaning.definition.count }
                return lhs.score > rhs.score
            }

        let best = Array(ranked.prefix(5)).map(\.meaning)
        let withExamplesFirst = prioritizeMeaningsWithExamples(
            best.isEmpty ? dedupedScoped : best,
            allExamples: examples,
            enabled: hasAnyLinkedExamples
        )
        let selected = withExamplesFirst.isEmpty ? Array(scoped.prefix(3)) : withExamplesFirst
        return selected.map(cleanMeaningExamples)
    }

    private func prioritizeMeaningsWithExamples(
        _ meanings: [MeaningContent],
        allExamples: [WordExample],
        enabled: Bool
    ) -> [MeaningContent] {
        guard enabled else { return meanings }

        let sorted = meanings.sorted { lhs, rhs in
            let leftHasExample = allExamples.contains(where: { $0.meaningId == lhs.id })
            let rightHasExample = allExamples.contains(where: { $0.meaningId == rhs.id })
            if leftHasExample == rightHasExample { return false }
            return leftHasExample && !rightHasExample
        }

        return Array(sorted.prefix(5))
    }

    private func dominantPartOfSpeech(from options: [TranslationOption]) -> String? {
        guard !options.isEmpty else { return nil }

        var scoreByPOS: [String: Double] = [:]

        for (index, option) in options.enumerated() {
            let pos = normalizePOS(option.partOfSpeech ?? "unknown")
            guard pos != "unknown" else { continue }

            let confidence = option.confidence ?? 0.5
            // Earlier options should dominate ranking to avoid noun-heavy noise
            // when top translation is clearly verb/adjective.
            let rankWeight = max(0.2, 1.0 - Double(index) * 0.08)
            scoreByPOS[pos, default: 0] += confidence * rankWeight
        }

        // Strong anchor on the very first option POS.
        if let firstPOS = options.first.map({ normalizePOS($0.partOfSpeech ?? "unknown") }),
           firstPOS != "unknown" {
            scoreByPOS[firstPOS, default: 0] += 1.25
        }

        return scoreByPOS.max(by: { $0.value < $1.value })?.key
    }

    private func hasStrongTranslationOverlap(meaning: MeaningContent, options: [TranslationOption]) -> Bool {
        let optionTokens = Set(options.map { normalizeToken($0.value) })
        let meaningTokens = Set(meaning.translations.map { normalizeToken($0.value) })
        return !optionTokens.intersection(meaningTokens).isEmpty
    }

    private func selectBestExamples(_ examples: [WordExample], keptMeaningIds: Set<UUID>) -> [WordExample] {
        guard !examples.isEmpty else { return examples }

        let linked = examples.filter { example in
            guard let meaningId = example.meaningId else { return false }
            return keptMeaningIds.contains(meaningId)
        }

        let pool = linked.isEmpty ? examples : linked
        let cleaned = pool.filter { !isTemplateLikeExample($0.sourceText) && !$0.sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let effectivePool = cleaned.isEmpty ? pool : cleaned

        var bestByMeaning: [UUID: WordExample] = [:]
        for example in effectivePool {
            guard let meaningId = example.meaningId else { continue }
            let score = exampleQualityScore(example)
            if let current = bestByMeaning[meaningId] {
                if score > exampleQualityScore(current) {
                    bestByMeaning[meaningId] = example
                }
            } else {
                bestByMeaning[meaningId] = example
            }
        }

        let byMeaning = bestByMeaning.values.sorted {
            $0.sourceText.count > $1.sourceText.count
        }

        // Important: keep one example per meaning, even if source text repeats across meanings.
        // UI binds by meaningId; aggressive cross-meaning dedupe causes "missing examples" for later meanings.
        return byMeaning.isEmpty ? Array(effectivePool.prefix(6)) : Array(byMeaning.prefix(6))
    }

    private func meaningQualityScore(
        _ meaning: MeaningContent,
        options: [TranslationOption],
        allExamples: [WordExample]
    ) -> Double {
        var score = 0.0

        let def = meaning.definition.trimmingCharacters(in: .whitespacesAndNewlines)
        if def.count >= 24 { score += 0.45 }
        else if def.count >= 14 { score += 0.25 }

        if hasStrongTranslationOverlap(meaning: meaning, options: options) {
            score += 0.35
        }

        if let ex = meaning.examples.first(where: { !$0.sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            score += max(0, exampleQualityScore(ex))
        }
        if let linked = allExamples.first(where: { $0.meaningId == meaning.id }) {
            score += 0.45 + max(0, exampleQualityScore(linked))
        } else if allExamples.contains(where: { $0.meaningId != nil }) {
            // If card has linked examples, down-rank senses with no link to reduce
            // "meanings without examples" in UI.
            score -= 0.2
        }

        if isLikelyMetaOrLowValueDefinition(def) {
            score -= 0.45
        }

        return score
    }

    private func exampleQualityScore(_ example: WordExample) -> Double {
        let source = example.sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        let target = example.targetText.trimmingCharacters(in: .whitespacesAndNewlines)

        var score = 0.0
        if source.count >= 20 { score += 0.25 }
        if target.count >= 12 { score += 0.25 }
        if !target.isEmpty { score += 0.2 }
        if isTemplateLikeExample(source) { score -= 0.5 }
        return score
    }

    private func isTemplateLikeExample(_ text: String) -> Bool {
        let normalized = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.hasPrefix("in this context,") && normalized.contains("means") {
            return true
        }
        if normalized.hasPrefix("this is a ") || normalized.hasPrefix("this is an ") {
            return true
        }
        if normalized.hasPrefix("they ") && normalized.hasSuffix(" every day.") {
            return true
        }
        if normalized.hasPrefix("they ") && normalized.hasSuffix(" every day") {
            return true
        }
        return false
    }

    private func isLikelyMetaOrLowValueDefinition(_ text: String) -> Bool {
        let normalized = text.lowercased()
        let blockedHints = [
            "offensive", "slang", "vulgar", "drugs", "taboo", "derogatory",
            "образлив", "вульгар", "сленг", "наркот"
        ]
        if blockedHints.contains(where: { normalized.contains($0) }) {
            return true
        }
        if normalized.hasPrefix("to ") && normalized.count < 22 {
            return true
        }
        if normalized.contains("to gender as") || normalized.contains("to feminize") {
            return true
        }
        if normalized.contains("chiefly in the plural") {
            return true
        }
        return false
    }

    private func dedupeMeanings(_ meanings: [MeaningContent]) -> [MeaningContent] {
        var unique: [MeaningContent] = []
        for meaning in meanings {
            let isDuplicate = unique.contains { existing in
                areDefinitionsNearDuplicate(existing.definition, meaning.definition)
            }
            if !isDuplicate {
                unique.append(meaning)
            }
        }
        return unique
    }

    private func areDefinitionsNearDuplicate(_ lhs: String, _ rhs: String) -> Bool {
        let a = lhs.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let b = rhs.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !a.isEmpty, !b.isEmpty else { return false }
        if a == b { return true }
        if a.count > 14 && b.count > 14 {
            if a.contains(b) || b.contains(a) {
                return true
            }
        }
        return false
    }

    private func cleanMeaningExamples(_ meaning: MeaningContent) -> MeaningContent {
        let cleanedExamples = meaning.examples.filter { !isTemplateLikeExample($0.sourceText) }

        return MeaningContent(
            id: meaning.id,
            title: meaning.title,
            meaning: meaning.definition,
            meaningLanguage: meaning.meaningLanguage,
            translation: meaning.definitionTranslation,
            translationLanguage: meaning.translationLanguage,
            explanation: meaning.explanation,
            explanationLanguage: meaning.explanationLanguage,
            partOfSpeech: meaning.partOfSpeech,
            domain: meaning.domain,
            translations: meaning.translations,
            examples: cleanedExamples,
            wordForms: meaning.wordForms,
            wordFormGroups: meaning.wordFormGroups
        )
    }

    private func normalizeToken(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func normalizeText(_ value: String) -> String {
        value.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizePOS(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}
