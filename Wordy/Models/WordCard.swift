import Foundation

private enum WordCardDateParser {
    static let iso8601WithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func parse(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return iso8601WithFractional.date(from: trimmed) ?? iso8601.date(from: trimmed)
    }
}

enum WordInputType: String, Codable, Hashable {
    case word
    case phrase
    case phrasalVerb
    case idiom
    case sentence
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = (try? container.decode(String.self))?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""

        switch raw {
        case "word", "singleword", "single_word":
            self = .word
        case "phrase":
            self = .phrase
        case "phrasalverb", "phrasal_verb":
            self = .phrasalVerb
        case "idiom":
            self = .idiom
        case "sentence":
            self = .sentence
        default:
            self = .unknown
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

struct RelatedPhrase: Identifiable, Codable, Hashable {
    let id: String
    let sourceText: String
    let targetText: String
    let meaningId: String?
    let type: String?

    init(
        id: String = UUID().uuidString,
        sourceText: String,
        targetText: String,
        meaningId: String? = nil,
        type: String? = nil
    ) {
        self.id = id
        self.sourceText = sourceText
        self.targetText = targetText
        self.meaningId = meaningId
        self.type = type
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case sourceText
        case targetText
        case meaningId
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        sourceText = try container.decodeIfPresent(String.self, forKey: .sourceText) ?? ""
        targetText = try container.decodeIfPresent(String.self, forKey: .targetText) ?? ""
        meaningId = try container.decodeIfPresent(String.self, forKey: .meaningId)
        type = try container.decodeIfPresent(String.self, forKey: .type)
    }
}

struct WordCard: Identifiable, Codable, Hashable {
    let id: String
    let originalText: String
    let normalizedText: String
    let sourceLanguage: String
    let targetLanguage: String
    let inputType: WordInputType
    let mainTranslation: String
    let translations: [TranslationOption]
    let meanings: [MeaningContent]
    let examples: [WordExample]
    let synonyms: [WordSynonym]
    let antonyms: [WordSynonym]
    let relatedPhrases: [RelatedPhrase]
    let createdAt: Date
    let updatedAt: Date
    let backendEngineVersion: String
    let pronunciation: String?
    let ipaTranscription: String?
    let idiomSemanticTranslation: String?
    let idiomLiteralTranslation: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case originalText
        case normalizedText
        case sourceLanguage
        case targetLanguage
        case inputType
        case mainTranslation
        case translations
        case meanings
        case examples
        case synonyms
        case antonyms
        case relatedPhrases
        case createdAt
        case updatedAt
        case backendEngineVersion
        case pronunciation
        case ipaTranscription
        case transcription
        case idiomSemanticTranslation
        case idiomLiteralTranslation
    }

    init(
        id: String = UUID().uuidString,
        originalText: String,
        normalizedText: String? = nil,
        sourceLanguage: String,
        targetLanguage: String,
        inputType: WordInputType = .unknown,
        mainTranslation: String,
        translations: [TranslationOption] = [],
        meanings: [MeaningContent] = [],
        examples: [WordExample] = [],
        synonyms: [WordSynonym] = [],
        antonyms: [WordSynonym] = [],
        relatedPhrases: [RelatedPhrase] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        backendEngineVersion: String = "v1",
        pronunciation: String? = nil,
        ipaTranscription: String? = nil,
        idiomSemanticTranslation: String? = nil,
        idiomLiteralTranslation: String? = nil
    ) {
        self.id = id
        self.originalText = originalText
        self.normalizedText = normalizedText ?? QueryNormalizer.normalize(originalText, language: sourceLanguage)
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.inputType = inputType
        self.mainTranslation = mainTranslation
        self.translations = translations
        self.meanings = meanings
        self.examples = examples
        self.synonyms = synonyms
        self.antonyms = antonyms
        self.relatedPhrases = relatedPhrases
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.backendEngineVersion = backendEngineVersion
        self.pronunciation = pronunciation
        self.ipaTranscription = ipaTranscription
        self.idiomSemanticTranslation = idiomSemanticTranslation
        self.idiomLiteralTranslation = idiomLiteralTranslation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        originalText = try container.decodeIfPresent(String.self, forKey: .originalText) ?? ""
        sourceLanguage = try container.decodeIfPresent(String.self, forKey: .sourceLanguage) ?? "en"
        targetLanguage = try container.decodeIfPresent(String.self, forKey: .targetLanguage) ?? "uk"
        normalizedText = try container.decodeIfPresent(String.self, forKey: .normalizedText)
            ?? QueryNormalizer.normalize(originalText, language: sourceLanguage)
        inputType = try container.decodeIfPresent(WordInputType.self, forKey: .inputType) ?? .unknown
        mainTranslation = try container.decodeIfPresent(String.self, forKey: .mainTranslation) ?? ""
        translations = try container.decodeIfPresent([TranslationOption].self, forKey: .translations) ?? []
        meanings = try container.decodeIfPresent([MeaningContent].self, forKey: .meanings) ?? []
        examples = try container.decodeIfPresent([WordExample].self, forKey: .examples) ?? []
        synonyms = try container.decodeIfPresent([WordSynonym].self, forKey: .synonyms) ?? []
        antonyms = try container.decodeIfPresent([WordSynonym].self, forKey: .antonyms) ?? []
        relatedPhrases = try container.decodeIfPresent([RelatedPhrase].self, forKey: .relatedPhrases) ?? []
        createdAt = WordCard.decodeFlexibleDate(from: container, key: .createdAt) ?? Date()
        updatedAt = WordCard.decodeFlexibleDate(from: container, key: .updatedAt) ?? createdAt
        backendEngineVersion = try container.decodeIfPresent(String.self, forKey: .backendEngineVersion) ?? "v1"
        pronunciation = try container.decodeIfPresent(String.self, forKey: .pronunciation)
        ipaTranscription = try container.decodeIfPresent(String.self, forKey: .ipaTranscription)
            ?? container.decodeIfPresent(String.self, forKey: .transcription)
        idiomSemanticTranslation = try container.decodeIfPresent(String.self, forKey: .idiomSemanticTranslation)
        idiomLiteralTranslation = try container.decodeIfPresent(String.self, forKey: .idiomLiteralTranslation)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(originalText, forKey: .originalText)
        try container.encode(normalizedText, forKey: .normalizedText)
        try container.encode(sourceLanguage, forKey: .sourceLanguage)
        try container.encode(targetLanguage, forKey: .targetLanguage)
        try container.encode(inputType, forKey: .inputType)
        try container.encode(mainTranslation, forKey: .mainTranslation)
        try container.encode(translations, forKey: .translations)
        try container.encode(meanings, forKey: .meanings)
        try container.encode(examples, forKey: .examples)
        try container.encode(synonyms, forKey: .synonyms)
        try container.encode(antonyms, forKey: .antonyms)
        try container.encode(relatedPhrases, forKey: .relatedPhrases)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(backendEngineVersion, forKey: .backendEngineVersion)
        try container.encodeIfPresent(pronunciation, forKey: .pronunciation)
        try container.encodeIfPresent(ipaTranscription, forKey: .ipaTranscription)
        try container.encodeIfPresent(idiomSemanticTranslation, forKey: .idiomSemanticTranslation)
        try container.encodeIfPresent(idiomLiteralTranslation, forKey: .idiomLiteralTranslation)
    }

    var languagePair: String {
        "\(sourceLanguage)-\(targetLanguage)"
    }

    var primaryExample: WordExample? {
        examples.first(where: { !$0.sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
    }

    private static func decodeFlexibleDate(
        from container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> Date? {
        if let date = try? container.decodeIfPresent(Date.self, forKey: key) {
            return date
        }

        if let stringValue = (try? container.decodeIfPresent(String.self, forKey: key)) ?? nil,
           let parsed = WordCardDateParser.parse(stringValue) {
            return parsed
        }

        if let seconds = (try? container.decodeIfPresent(Double.self, forKey: key)) ?? nil {
            if seconds > 10_000_000_000 {
                return Date(timeIntervalSince1970: seconds / 1000.0)
            }
            return Date(timeIntervalSince1970: seconds)
        }

        if let milliseconds = (try? container.decodeIfPresent(Int64.self, forKey: key)) ?? nil {
            if milliseconds > 10_000_000_000 {
                return Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000.0)
            }
            return Date(timeIntervalSince1970: TimeInterval(milliseconds))
        }

        return nil
    }
}

extension WordCard {
    func asSavedWordModel(
        dictionaryId: String,
        selectedTranslationOptionIds: [String] = [],
        selectedExampleIds: [String] = [],
        selectedSynonymIds: [String] = [],
        note: String? = nil,
        tags: [String] = [],
        setIds: [String] = [],
        reviewState: ReviewState = ReviewState()
    ) -> SavedWordModel {
        SavedWordModel(
            original: originalText,
            translation: mainTranslation,
            normalizedText: normalizedText,
            mainTranslation: mainTranslation,
            translations: translations,
            transcription: ipaTranscription,
            pronunciation: pronunciation,
            exampleSentence: primaryExample?.sourceText,
            languagePair: languagePair,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            examples: examples,
            synonyms: synonyms,
            meanings: meanings,
            relatedPhrases: relatedPhrases,
            tags: tags,
            setIds: setIds,
            note: note,
            source: .dictionaryAPI,
            dictionaryId: dictionaryId,
            isLearned: reviewState.isLearned,
            reviewCount: reviewState.reviewCount,
            srsInterval: reviewState.srsInterval,
            srsRepetition: reviewState.srsRepetition,
            srsEasinessFactor: reviewState.srsEasinessFactor,
            nextReviewDate: reviewState.nextReviewDate,
            lastReviewDate: reviewState.lastReviewDate,
            averageQuality: reviewState.averageQuality,
            createdAt: createdAt,
            updatedAt: updatedAt,
            wordCard: self,
            selectedTranslationOptionIds: selectedTranslationOptionIds,
            selectedExampleIds: selectedExampleIds,
            selectedSynonymIds: selectedSynonymIds
        )
    }
}
