//
//  QueryNormalizer.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 03.04.2026.
//

import Foundation

enum QueryNormalizer {

    static func normalize(_ text: String, language: String) -> String {
        var result = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        result = removePunctuation(result)
        result = removeArticles(result, language: language)
        result = normalizePlural(result, language: language)
        result = normalizeVerbs(result, language: language)

        return result
    }

    // MARK: - Helpers

    private static func removePunctuation(_ text: String) -> String {
        text.trimmingCharacters(in: .punctuationCharacters)
    }

    private static func removeArticles(_ text: String, language: String) -> String {
        let articles: [String: Set<String>] = [
            "en": ["a", "an", "the"],
            "es": ["el", "la", "los", "las", "un", "una", "unos", "unas"],
            "fr": ["le", "la", "les", "un", "une", "des"],
            "de": ["der", "die", "das", "den", "dem", "des", "ein", "eine"],
            "it": ["il", "lo", "la", "i", "gli", "le", "un", "una"]
        ]

        guard let set = articles[language] else { return text }

        let words = text.split(separator: " ")
        guard let first = words.first else { return text }

        if set.contains(String(first)) {
            return words.dropFirst().joined(separator: " ")
        }

        return text
    }

    private static func normalizePlural(_ text: String, language: String) -> String {
        guard text.split(separator: " ").count == 1 else { return text }

        switch language {
        case "en":
            if text.hasSuffix("ies") {
                return String(text.dropLast(3)) + "y"
            }
            if text.hasSuffix("s") && !text.hasSuffix("ss") {
                return String(text.dropLast())
            }

            let irregular: [String: String] = [
                "children": "child",
                "men": "man",
                "women": "woman",
                "people": "person"
            ]

            return irregular[text] ?? text

        case "es", "fr", "it":
            if text.hasSuffix("s") {
                return String(text.dropLast())
            }

        case "de":
            if text.hasSuffix("en") {
                return String(text.dropLast(2))
            }

        default:
            break
        }

        return text
    }

    private static func normalizeVerbs(_ text: String, language: String) -> String {
        guard language == "en" else { return text }

        let irregular: [String: String] = [
            "went": "go",
            "gone": "go",
            "did": "do",
            "does": "do",
            "done": "do",
            "has": "have",
            "had": "have"
        ]

        if let base = irregular[text] {
            return base
        }

        if text.hasSuffix("ing") {
            return String(text.dropLast(3))
        }

        if text.hasSuffix("ed") {
            return String(text.dropLast(2))
        }

        return text
    }
}
