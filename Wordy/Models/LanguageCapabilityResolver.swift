import Foundation

enum SynonymProviderKind: String {
    case englishDictionary
    case germanOpenThesaurus
}

enum EnrichmentProviderKind: String {
    case englishDictionary
    case germanSynonymsOnly
}

enum LanguageCapabilityResolver {
    static func config(for code: String) -> LanguageConfig {
        LanguageConfig.config(for: code)
    }

    static func supportsSynonyms(_ code: String) -> Bool {
        config(for: code).supportsSynonyms
    }

    static func supportsWordForms(_ code: String) -> Bool {
        config(for: code).supportsWordForms
    }

    static func preferredExplanationLanguage(
        sourceLanguage: String,
        targetLanguage: String
    ) -> String {
        let sourceConfig = config(for: sourceLanguage)
        if sourceConfig.preferredExplanationLanguage == sourceLanguage {
            return sourceLanguage
        }

        let targetConfig = config(for: targetLanguage)
        return targetConfig.preferredExplanationLanguage
    }

    static func preferredSynonymLanguage(
        sourceLanguage: String,
        targetLanguage: String
    ) -> String {
        sourceLanguage
    }

    static func bridgeSynonymLanguage(
        sourceLanguage: String,
        targetLanguage: String
    ) -> String {
        if supportsSynonyms(sourceLanguage) {
            return sourceLanguage
        }
        if supportsSynonyms(targetLanguage) {
            return targetLanguage
        }
        return "en"
    }

    static func synonymSourceLanguage(
        sourceLanguage: String,
        targetLanguage: String
    ) -> String {
        sourceLanguage
    }

    static func synonymDisplayLanguage(
        sourceLanguage: String,
        targetLanguage: String
    ) -> String {
        sourceLanguage
    }

    static func synonymTranslationLanguage(
        sourceLanguage: String,
        targetLanguage: String
    ) -> String {
        targetLanguage
    }

    static func canUseNativeSynonymProvider(
        sourceLanguage: String,
        targetLanguage: String
    ) -> Bool {
        supportsSynonyms(sourceLanguage) || supportsSynonyms(targetLanguage)
    }

    static func synonymProvider(for code: String) -> SynonymProviderKind? {
        switch code {
        case "en":
            return .englishDictionary
        case "de":
            return .germanOpenThesaurus
        default:
            return nil
        }
    }

    static func enrichmentProvider(for code: String) -> EnrichmentProviderKind? {
        switch code {
        case "en":
            return .englishDictionary
        case "de":
            return .germanSynonymsOnly
        default:
            return nil
        }
    }

    static func isRightToLeft(_ code: String) -> Bool {
        config(for: code).isRightToLeft
    }
}
