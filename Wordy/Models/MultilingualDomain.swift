import Foundation
import CryptoKit

private enum BackendIdentifierDecoder {
    private static func deterministicUUID(from raw: String) -> UUID? {
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }
        let digest = Insecure.MD5.hash(data: Data(normalized.utf8))
        let bytes = Array(digest)
        guard bytes.count >= 16 else { return nil }

        let tuple: uuid_t = (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        )
        return UUID(uuid: tuple)
    }

    static func uuid<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) throws -> UUID? {
        if let uuid = try? container.decodeIfPresent(UUID.self, forKey: key) {
            return uuid
        }

        if let stringValue = try container.decodeIfPresent(String.self, forKey: key) {
            if let parsed = UUID(uuidString: stringValue) {
                return parsed
            }
            return deterministicUUID(from: stringValue)
        }

        return nil
    }
}

enum NormalizedPartOfSpeech: Hashable, Codable {
    case unknown
    case noun
    case verb
    case adjective
    case adverb
    case phrase
    case other(String)

    init(rawValue: String?) {
        let normalized = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        switch normalized {
        case let value where value.contains("noun"):
            self = .noun
        case let value where value.contains("verb"):
            self = .verb
        case let value where value.contains("adjective"):
            self = .adjective
        case let value where value.contains("adverb"):
            self = .adverb
        case let value where value.contains("phrase"):
            self = .phrase
        case "":
            self = .unknown
        default:
            self = normalized == "unknown" ? .unknown : .other(normalized)
        }
    }

    var rawValue: String {
        switch self {
        case .unknown: return "unknown"
        case .noun: return "noun"
        case .verb: return "verb"
        case .adjective: return "adjective"
        case .adverb: return "adverb"
        case .phrase: return "phrase"
        case .other(let value): return value
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = NormalizedPartOfSpeech(rawValue: raw)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

private struct LegacyPartOfSpeechPayload: Decodable {
    let rawValue: String?
    let value: String?
    let name: String?
    let kind: String?
}

enum GrammarComplexityLevel: String, Codable, Hashable {
    case low
    case medium
    case high
    case veryHigh
}

struct LanguageConfig: Codable, Hashable {
    let code: String
    let supportsSynonyms: Bool
    let supportsWordForms: Bool
    let grammarComplexityLevel: GrammarComplexityLevel
    let preferredExplanationLanguage: String
    let isRightToLeft: Bool

    static let all: [String: LanguageConfig] = [
        "en": LanguageConfig(code: "en", supportsSynonyms: true, supportsWordForms: true, grammarComplexityLevel: .medium, preferredExplanationLanguage: "en", isRightToLeft: false),
        "uk": LanguageConfig(code: "uk", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .high, preferredExplanationLanguage: "uk", isRightToLeft: false),
        "pl": LanguageConfig(code: "pl", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .high, preferredExplanationLanguage: "pl", isRightToLeft: false),
        "de": LanguageConfig(code: "de", supportsSynonyms: true, supportsWordForms: true, grammarComplexityLevel: .high, preferredExplanationLanguage: "de", isRightToLeft: false),
        "fr": LanguageConfig(code: "fr", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .high, preferredExplanationLanguage: "fr", isRightToLeft: false),
        "es": LanguageConfig(code: "es", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .medium, preferredExplanationLanguage: "es", isRightToLeft: false),
        "it": LanguageConfig(code: "it", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .medium, preferredExplanationLanguage: "it", isRightToLeft: false),
        "ar": LanguageConfig(code: "ar", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .veryHigh, preferredExplanationLanguage: "ar", isRightToLeft: true),
        "bg": LanguageConfig(code: "bg", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .high, preferredExplanationLanguage: "bg", isRightToLeft: false),
        "zh": LanguageConfig(code: "zh", supportsSynonyms: false, supportsWordForms: false, grammarComplexityLevel: .medium, preferredExplanationLanguage: "zh", isRightToLeft: false),
        "cs": LanguageConfig(code: "cs", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .high, preferredExplanationLanguage: "cs", isRightToLeft: false),
        "da": LanguageConfig(code: "da", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .medium, preferredExplanationLanguage: "da", isRightToLeft: false),
        "nl": LanguageConfig(code: "nl", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .medium, preferredExplanationLanguage: "nl", isRightToLeft: false),
        "et": LanguageConfig(code: "et", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .high, preferredExplanationLanguage: "et", isRightToLeft: false),
        "fi": LanguageConfig(code: "fi", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .veryHigh, preferredExplanationLanguage: "fi", isRightToLeft: false),
        "el": LanguageConfig(code: "el", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .high, preferredExplanationLanguage: "el", isRightToLeft: false),
        "hu": LanguageConfig(code: "hu", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .veryHigh, preferredExplanationLanguage: "hu", isRightToLeft: false),
        "id": LanguageConfig(code: "id", supportsSynonyms: false, supportsWordForms: false, grammarComplexityLevel: .low, preferredExplanationLanguage: "id", isRightToLeft: false),
        "ja": LanguageConfig(code: "ja", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .high, preferredExplanationLanguage: "ja", isRightToLeft: false),
        "ko": LanguageConfig(code: "ko", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .high, preferredExplanationLanguage: "ko", isRightToLeft: false),
        "lv": LanguageConfig(code: "lv", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .high, preferredExplanationLanguage: "lv", isRightToLeft: false),
        "lt": LanguageConfig(code: "lt", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .high, preferredExplanationLanguage: "lt", isRightToLeft: false),
        "nb": LanguageConfig(code: "nb", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .medium, preferredExplanationLanguage: "nb", isRightToLeft: false),
        "pt": LanguageConfig(code: "pt", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .medium, preferredExplanationLanguage: "pt", isRightToLeft: false),
        "ro": LanguageConfig(code: "ro", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .medium, preferredExplanationLanguage: "ro", isRightToLeft: false),
        "ru": LanguageConfig(code: "ru", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .high, preferredExplanationLanguage: "ru", isRightToLeft: false),
        "sk": LanguageConfig(code: "sk", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .high, preferredExplanationLanguage: "sk", isRightToLeft: false),
        "sl": LanguageConfig(code: "sl", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .high, preferredExplanationLanguage: "sl", isRightToLeft: false),
        "sv": LanguageConfig(code: "sv", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .medium, preferredExplanationLanguage: "sv", isRightToLeft: false),
        "tr": LanguageConfig(code: "tr", supportsSynonyms: false, supportsWordForms: true, grammarComplexityLevel: .high, preferredExplanationLanguage: "tr", isRightToLeft: false)
    ]

    static func config(for code: String) -> LanguageConfig {
        all[code] ?? LanguageConfig(
            code: code,
            supportsSynonyms: false,
            supportsWordForms: false,
            grammarComplexityLevel: .medium,
            preferredExplanationLanguage: code,
            isRightToLeft: false
        )
    }
}

struct LanguagePairContext: Codable, Hashable {
    let sourceLanguage: String
    let targetLanguage: String

    var pairCode: String { "\(sourceLanguage)-\(targetLanguage)" }

    func swapped() -> LanguagePairContext {
        LanguagePairContext(sourceLanguage: targetLanguage, targetLanguage: sourceLanguage)
    }
}

enum ExampleSourceType: String, Codable, Hashable {
    case aiGenerated
    case userContext
    case imported
    case curated
}

enum WordDataSource: String, Codable, Hashable {
    case deepl
    case dictionaryAPI
    case ai
    case imported
    case manual
    case mixed
}

struct TextHighlightRange: Codable, Hashable {
    let location: Int
    let length: Int
}

enum TranslationOptionSourceType: String, Codable, Hashable {
    case googleAlternative
    case deeplDirect
    case dictionary
    case wiktionary
    case direct
    case meaningDerived
    case contextual
    case fallback
    case synonym
    case generated

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        switch rawValue {
        case "googleAlternative":
            self = .googleAlternative
        case "deeplDirect":
            self = .deeplDirect
        case "dictionary":
            self = .dictionary
        case "wiktionary":
            self = .wiktionary
        case "direct":
            self = .direct
        case "meaningDerived", "meaningTranslation":
            self = .meaningDerived
        case "contextual", "contextualAlternative":
            self = .contextual
        case "fallback":
            self = .fallback
        case "synonym":
            self = .synonym
        case "generated":
            self = .generated
        default:
            self = .direct
        }
    }
}

struct TranslationOption: Identifiable, Codable, Hashable {
    let id: UUID
    let value: String
    let partOfSpeech: String?
    let gender: String?
    let meaningId: UUID?
    let confidence: Double?
    let shortGrammarLabel: String?
    let sourceType: TranslationOptionSourceType
    let examples: [WordExample]

    init(
        id: UUID = UUID(),
        value: String,
        partOfSpeech: String? = nil,
        gender: String? = nil,
        meaningId: UUID? = nil,
        confidence: Double? = nil,
        shortGrammarLabel: String? = nil,
        sourceType: TranslationOptionSourceType = .direct,
        examples: [WordExample] = []
    ) {
        self.id = id
        self.value = value
        self.partOfSpeech = partOfSpeech
        self.gender = gender
        self.meaningId = meaningId
        self.confidence = confidence
        self.shortGrammarLabel = shortGrammarLabel
        self.sourceType = sourceType
        self.examples = examples
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case value
        case partOfSpeech
        case gender
        case meaningId
        case confidence
        case shortGrammarLabel
        case sourceType
        case examples
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try BackendIdentifierDecoder.uuid(from: container, forKey: .id) ?? UUID()
        value = try container.decodeIfPresent(String.self, forKey: .value) ?? ""
        partOfSpeech = try container.decodeIfPresent(String.self, forKey: .partOfSpeech)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        meaningId = try BackendIdentifierDecoder.uuid(from: container, forKey: .meaningId)
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence)
        shortGrammarLabel = try container.decodeIfPresent(String.self, forKey: .shortGrammarLabel)
        sourceType = try container.decodeIfPresent(TranslationOptionSourceType.self, forKey: .sourceType) ?? .direct
        if let richExamples = (try? container.decodeIfPresent([WordExample].self, forKey: .examples)) ?? nil {
            examples = richExamples
        } else if let textExamples = (try? container.decodeIfPresent([String].self, forKey: .examples)) ?? nil {
            examples = textExamples
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .map {
                    WordExample(
                        sourceText: $0,
                        targetText: "",
                        sourceLanguage: "en",
                        targetLanguage: "uk"
                    )
                }
        } else {
            examples = []
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(value, forKey: .value)
        try container.encodeIfPresent(partOfSpeech, forKey: .partOfSpeech)
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encodeIfPresent(meaningId, forKey: .meaningId)
        try container.encodeIfPresent(confidence, forKey: .confidence)
        try container.encodeIfPresent(shortGrammarLabel, forKey: .shortGrammarLabel)
        try container.encode(sourceType, forKey: .sourceType)
        try container.encode(examples, forKey: .examples)
    }
}

struct WordExample: Identifiable, Codable, Hashable {
    let id: UUID
    let sourceText: String
    let translatedText: String
    let sourceLanguage: String
    let targetLanguage: String
    let highlightedSourceRange: TextHighlightRange?
    let highlightedTargetRange: TextHighlightRange?
    let highlightedSourceText: String?
    let highlightedTargetText: String?
    let meaningId: UUID?
    let translationOptionId: UUID?
    let difficultyLevel: String?
    let sourceType: ExampleSourceType
    let isSensitive: Bool
    let sensitiveReason: String?

    init(
        id: UUID = UUID(),
        sourceText: String,
        targetText: String,
        sourceLanguage: String,
        targetLanguage: String,
        highlightedSourceRange: TextHighlightRange? = nil,
        highlightedTargetRange: TextHighlightRange? = nil,
        highlightedSourceText: String? = nil,
        highlightedTargetText: String? = nil,
        meaningId: UUID? = nil,
        translationOptionId: UUID? = nil,
        difficultyLevel: String? = nil,
        sourceType: ExampleSourceType = .curated,
        isSensitive: Bool = false,
        sensitiveReason: String? = nil
    ) {
        self.id = id
        self.sourceText = sourceText
        self.translatedText = targetText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.highlightedSourceRange = highlightedSourceRange
        self.highlightedTargetRange = highlightedTargetRange
        self.highlightedSourceText = highlightedSourceText
        self.highlightedTargetText = highlightedTargetText
        self.meaningId = meaningId
        self.translationOptionId = translationOptionId
        self.difficultyLevel = difficultyLevel
        self.sourceType = sourceType
        self.isSensitive = isSensitive
        self.sensitiveReason = sensitiveReason
    }

    var targetText: String { translatedText }

    private enum CodingKeys: String, CodingKey {
        case id
        case sourceText
        case translatedText
        case targetText
        case sourceLanguage
        case targetLanguage
        case highlightedSourceRange
        case highlightedTargetRange
        case highlightedSourceText
        case highlightedTargetText
        case meaningId
        case translationOptionId
        case difficultyLevel
        case difficulty
        case sourceType
        case isSensitive
        case sensitiveReason
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try BackendIdentifierDecoder.uuid(from: container, forKey: .id) ?? UUID()
        sourceText = try container.decodeIfPresent(String.self, forKey: .sourceText) ?? ""
        translatedText = try container.decodeIfPresent(String.self, forKey: .translatedText)
            ?? container.decodeIfPresent(String.self, forKey: .targetText)
            ?? ""
        sourceLanguage = try container.decodeIfPresent(String.self, forKey: .sourceLanguage) ?? "en"
        targetLanguage = try container.decodeIfPresent(String.self, forKey: .targetLanguage) ?? "uk"
        highlightedSourceRange = try container.decodeIfPresent(TextHighlightRange.self, forKey: .highlightedSourceRange)
        highlightedTargetRange = try container.decodeIfPresent(TextHighlightRange.self, forKey: .highlightedTargetRange)
        highlightedSourceText = try container.decodeIfPresent(String.self, forKey: .highlightedSourceText)
        highlightedTargetText = try container.decodeIfPresent(String.self, forKey: .highlightedTargetText)
        meaningId = try BackendIdentifierDecoder.uuid(from: container, forKey: .meaningId)
        translationOptionId = try BackendIdentifierDecoder.uuid(from: container, forKey: .translationOptionId)
        difficultyLevel = try container.decodeIfPresent(String.self, forKey: .difficultyLevel)
            ?? container.decodeIfPresent(String.self, forKey: .difficulty)
        sourceType = try container.decodeIfPresent(ExampleSourceType.self, forKey: .sourceType) ?? .curated
        isSensitive = try container.decodeIfPresent(Bool.self, forKey: .isSensitive) ?? false
        sensitiveReason = try container.decodeIfPresent(String.self, forKey: .sensitiveReason)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(sourceText, forKey: .sourceText)
        try container.encode(translatedText, forKey: .translatedText)
        try container.encode(sourceLanguage, forKey: .sourceLanguage)
        try container.encode(targetLanguage, forKey: .targetLanguage)
        try container.encodeIfPresent(highlightedSourceRange, forKey: .highlightedSourceRange)
        try container.encodeIfPresent(highlightedTargetRange, forKey: .highlightedTargetRange)
        try container.encodeIfPresent(highlightedSourceText, forKey: .highlightedSourceText)
        try container.encodeIfPresent(highlightedTargetText, forKey: .highlightedTargetText)
        try container.encodeIfPresent(meaningId, forKey: .meaningId)
        try container.encodeIfPresent(translationOptionId, forKey: .translationOptionId)
        try container.encodeIfPresent(difficultyLevel, forKey: .difficultyLevel)
        try container.encode(sourceType, forKey: .sourceType)
        try container.encode(isSensitive, forKey: .isSensitive)
        try container.encodeIfPresent(sensitiveReason, forKey: .sensitiveReason)
    }
}

struct WordSynonym: Identifiable, Codable, Hashable {
    let id: UUID
    let word: String
    let translation: String?
    let partOfSpeech: String?
    let meaningId: UUID?
    let relevance: Double?
    let example: WordExample?
    let language: String
    let translationLanguage: String?

    init(
        id: UUID = UUID(),
        text: String,
        language: String,
        translation: String? = nil,
        translationLanguage: String? = nil,
        partOfSpeech: String? = nil,
        meaningId: UUID? = nil,
        relevance: Double? = nil,
        example: WordExample? = nil
    ) {
        self.id = id
        self.word = text
        self.translation = translation
        self.partOfSpeech = partOfSpeech
        self.meaningId = meaningId
        self.relevance = relevance
        self.example = example
        self.language = language
        self.translationLanguage = translationLanguage
    }

    var text: String { word }

    private enum CodingKeys: String, CodingKey {
        case id
        case word
        case text
        case sourceText
        case translation
        case targetText
        case partOfSpeech
        case meaningId
        case relevance
        case confidence
        case example
        case language
        case translationLanguage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try BackendIdentifierDecoder.uuid(from: container, forKey: .id) ?? UUID()
        word = try container.decodeIfPresent(String.self, forKey: .word)
            ?? container.decodeIfPresent(String.self, forKey: .text)
            ?? container.decodeIfPresent(String.self, forKey: .sourceText)
            ?? ""
        translation = try container.decodeIfPresent(String.self, forKey: .translation)
            ?? container.decodeIfPresent(String.self, forKey: .targetText)
        partOfSpeech = try container.decodeIfPresent(String.self, forKey: .partOfSpeech)
        meaningId = try BackendIdentifierDecoder.uuid(from: container, forKey: .meaningId)
        relevance = try container.decodeIfPresent(Double.self, forKey: .relevance)
            ?? container.decodeIfPresent(Double.self, forKey: .confidence)
        example = try container.decodeIfPresent(WordExample.self, forKey: .example)
        language = try container.decodeIfPresent(String.self, forKey: .language) ?? "en"
        translationLanguage = try container.decodeIfPresent(String.self, forKey: .translationLanguage)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(word, forKey: .word)
        try container.encodeIfPresent(translation, forKey: .translation)
        try container.encodeIfPresent(partOfSpeech, forKey: .partOfSpeech)
        try container.encodeIfPresent(meaningId, forKey: .meaningId)
        try container.encodeIfPresent(relevance, forKey: .relevance)
        try container.encodeIfPresent(example, forKey: .example)
        try container.encode(language, forKey: .language)
        try container.encodeIfPresent(translationLanguage, forKey: .translationLanguage)
    }
}

struct WordForm: Identifiable, Codable, Hashable {
    let id: UUID
    let form: String
    let label: String
    let person: String?
    let number: String?
    let tense: String?
    let gender: String?
    let caseName: String?
    let mood: String?
    let language: String
    let languageSpecificMetadata: [String: String]

    init(
        id: UUID = UUID(),
        form: String,
        type: String,
        language: String,
        person: String? = nil,
        number: String? = nil,
        tense: String? = nil,
        gender: String? = nil,
        caseName: String? = nil,
        mood: String? = nil,
        languageSpecificMetadata: [String: String] = [:]
    ) {
        self.id = id
        self.form = form
        self.label = type
        self.person = person
        self.number = number
        self.tense = tense
        self.gender = gender
        self.caseName = caseName
        self.mood = mood
        self.language = language
        self.languageSpecificMetadata = languageSpecificMetadata
    }

    var type: String { label }

    private enum CodingKeys: String, CodingKey {
        case id
        case form
        case label
        case type
        case person
        case number
        case tense
        case gender
        case caseName
        case mood
        case language
        case languageSpecificMetadata
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        form = try container.decodeIfPresent(String.self, forKey: .form) ?? ""
        label = try container.decodeIfPresent(String.self, forKey: .label)
            ?? container.decodeIfPresent(String.self, forKey: .type)
            ?? ""
        person = try container.decodeIfPresent(String.self, forKey: .person)
        number = try container.decodeIfPresent(String.self, forKey: .number)
        tense = try container.decodeIfPresent(String.self, forKey: .tense)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        caseName = try container.decodeIfPresent(String.self, forKey: .caseName)
        mood = try container.decodeIfPresent(String.self, forKey: .mood)
        language = try container.decodeIfPresent(String.self, forKey: .language) ?? "en"
        languageSpecificMetadata = try container.decodeIfPresent([String: String].self, forKey: .languageSpecificMetadata) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(form, forKey: .form)
        try container.encode(label, forKey: .label)
        try container.encodeIfPresent(person, forKey: .person)
        try container.encodeIfPresent(number, forKey: .number)
        try container.encodeIfPresent(tense, forKey: .tense)
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encodeIfPresent(caseName, forKey: .caseName)
        try container.encodeIfPresent(mood, forKey: .mood)
        try container.encode(language, forKey: .language)
        try container.encode(languageSpecificMetadata, forKey: .languageSpecificMetadata)
    }
}

struct WordFormGroup: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let language: String
    let forms: [WordForm]

    init(
        id: UUID = UUID(),
        title: String,
        language: String,
        forms: [WordForm]
    ) {
        self.id = id
        self.title = title
        self.language = language
        self.forms = forms
    }
}

struct MeaningContent: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String?
    let definition: String
    let definitionTranslation: String?
    let domain: String?
    let translations: [TranslationOption]
    let explanation: String?
    let explanationLanguage: String?
    let partOfSpeech: NormalizedPartOfSpeech
    let examples: [WordExample]
    let wordForms: [WordForm]
    let wordFormGroups: [WordFormGroup]

    init(
        id: UUID = UUID(),
        title: String? = nil,
        meaning: String,
        meaningLanguage: String,
        translation: String? = nil,
        translationLanguage: String? = nil,
        explanation: String? = nil,
        explanationLanguage: String? = nil,
        partOfSpeech: NormalizedPartOfSpeech = .other("unknown"),
        domain: String? = nil,
        translations: [TranslationOption] = [],
        examples: [WordExample] = [],
        wordForms: [WordForm] = [],
        wordFormGroups: [WordFormGroup] = []
    ) {
        self.id = id
        self.title = title
        self.definition = meaning
        self.definitionTranslation = translation
        self.domain = domain
        self.translations = translations
        self.explanation = explanation
        self.explanationLanguage = explanationLanguage ?? translationLanguage ?? meaningLanguage
        self.partOfSpeech = partOfSpeech
        self.examples = examples
        self.wordForms = wordForms
        self.wordFormGroups = wordFormGroups
    }

    var meaning: String { definition }
    var meaningLanguage: String { explanationLanguage ?? "en" }
    var translation: String? { definitionTranslation }
    var translationLanguage: String? { explanationLanguage }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case definition
        case definitionTranslation
        case domain
        case translations
        case explanation
        case explanationLanguage
        case partOfSpeech
        case examples
        case wordForms
        case wordFormGroups
        case sourceExample
        case targetExample
        case order
        case meaning
        case meaningLanguage
        case translation
        case translationLanguage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try BackendIdentifierDecoder.uuid(from: container, forKey: .id) ?? UUID()
        title = try container.decodeIfPresent(String.self, forKey: .title)
        definition = try container.decodeIfPresent(String.self, forKey: .definition)
            ?? container.decodeIfPresent(String.self, forKey: .meaning)
            ?? ""
        definitionTranslation = try container.decodeIfPresent(String.self, forKey: .definitionTranslation)
            ?? container.decodeIfPresent(String.self, forKey: .translation)
        domain = try container.decodeIfPresent(String.self, forKey: .domain)
        translations = try container.decodeIfPresent([TranslationOption].self, forKey: .translations) ?? []
        explanation = try container.decodeIfPresent(String.self, forKey: .explanation)
        explanationLanguage = try container.decodeIfPresent(String.self, forKey: .explanationLanguage)
            ?? container.decodeIfPresent(String.self, forKey: .translationLanguage)
            ?? container.decodeIfPresent(String.self, forKey: .meaningLanguage)
        if let normalizedPos = try? container.decodeIfPresent(NormalizedPartOfSpeech.self, forKey: .partOfSpeech) {
            partOfSpeech = normalizedPos ?? .unknown
        } else if let posString = try? container.decodeIfPresent(String.self, forKey: .partOfSpeech) {
            partOfSpeech = NormalizedPartOfSpeech(rawValue: posString)
        } else if let legacyPos = try? container.decodeIfPresent(LegacyPartOfSpeechPayload.self, forKey: .partOfSpeech) {
            let raw = legacyPos.rawValue ?? legacyPos.value ?? legacyPos.name ?? legacyPos.kind
            partOfSpeech = NormalizedPartOfSpeech(rawValue: raw)
        } else {
            partOfSpeech = .unknown
        }
        let decodedExamples = try container.decodeIfPresent([WordExample].self, forKey: .examples) ?? []
        if decodedExamples.isEmpty {
            let sourceExample = try container.decodeIfPresent(String.self, forKey: .sourceExample)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let targetExample = try container.decodeIfPresent(String.self, forKey: .targetExample)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !sourceExample.isEmpty || !targetExample.isEmpty {
                examples = [
                    WordExample(
                        sourceText: sourceExample,
                        targetText: targetExample,
                        sourceLanguage: "en",
                        targetLanguage: "uk"
                    )
                ]
            } else {
                examples = []
            }
        } else {
            examples = decodedExamples
        }
        wordForms = try container.decodeIfPresent([WordForm].self, forKey: .wordForms) ?? []
        wordFormGroups = try container.decodeIfPresent([WordFormGroup].self, forKey: .wordFormGroups) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encode(definition, forKey: .definition)
        try container.encodeIfPresent(definitionTranslation, forKey: .definitionTranslation)
        try container.encodeIfPresent(domain, forKey: .domain)
        try container.encode(translations, forKey: .translations)
        try container.encodeIfPresent(explanation, forKey: .explanation)
        try container.encodeIfPresent(explanationLanguage, forKey: .explanationLanguage)
        try container.encode(partOfSpeech, forKey: .partOfSpeech)
        try container.encode(examples, forKey: .examples)
        try container.encode(wordForms, forKey: .wordForms)
        try container.encode(wordFormGroups, forKey: .wordFormGroups)
    }
}

struct RelatedTopic: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let icon: String?
    let relatedWords: [String]

    init(
        id: UUID = UUID(),
        title: String,
        icon: String? = nil,
        relatedWords: [String] = []
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.relatedWords = relatedWords
    }
}

struct ReviewState: Codable, Hashable {
    let isLearned: Bool
    let reviewCount: Int
    let srsInterval: Double
    let srsRepetition: Int
    let srsEasinessFactor: Double
    let nextReviewDate: Date?
    let lastReviewDate: Date?
    let averageQuality: Double

    init(
        isLearned: Bool = false,
        reviewCount: Int = 0,
        srsInterval: Double = 0,
        srsRepetition: Int = 0,
        srsEasinessFactor: Double = 2.5,
        nextReviewDate: Date? = nil,
        lastReviewDate: Date? = nil,
        averageQuality: Double = 0
    ) {
        self.isLearned = isLearned
        self.reviewCount = reviewCount
        self.srsInterval = srsInterval
        self.srsRepetition = srsRepetition
        self.srsEasinessFactor = srsEasinessFactor
        self.nextReviewDate = nextReviewDate
        self.lastReviewDate = lastReviewDate
        self.averageQuality = averageQuality
    }
}
