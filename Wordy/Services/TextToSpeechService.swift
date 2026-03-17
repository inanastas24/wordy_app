//
//  TextToSpeechService.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 17.03.2026.
//

import AVFoundation
import NaturalLanguage
import Combine
import Foundation

@MainActor
final class TextToSpeechService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {

    static let shared = TextToSpeechService()

    @Published var isPlaying = false
    @Published var currentLanguage: String?

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(text: String, language: String) {
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        guard !cleaned.isEmpty else { return }

        let resolvedLang = resolveLanguage(for: cleaned, preferred: language)

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: cleaned)
        utterance.voice = bestVoice(for: resolvedLang)
        utterance.rate = 0.5

        currentLanguage = resolvedLang
        isPlaying = true

        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        currentLanguage = nil
    }

    // MARK: - Language logic (КЛЮЧОВЕ)

    private func resolveLanguage(for text: String, preferred: String) -> String {
        if !preferred.isEmpty {
            return mapToApple(preferred)
        }

        if let detected = detectLanguage(text) {
            return detected
        }

        return "en-US"
    }

    private func detectLanguage(_ text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        guard let lang = recognizer.dominantLanguage else { return nil }

        switch lang {
        case .english: return "en-US"
        case .ukrainian: return "uk-UA"
        case .polish: return "pl-PL"
        case .german: return "de-DE"
        case .french: return "fr-FR"
        case .spanish: return "es-ES"
        case .italian: return "it-IT"
        default: return nil
        }
    }

    private func mapToApple(_ code: String) -> String {
        switch code {
        case "uk": return "uk-UA"
        case "en": return "en-US"
        case "pl": return "pl-PL"
        case "de": return "de-DE"
        case "fr": return "fr-FR"
        case "es": return "es-ES"
        case "it": return "it-IT"
        default: return "en-US"
        }
    }

    private func bestVoice(for code: String) -> AVSpeechSynthesisVoice? {
        if let exact = AVSpeechSynthesisVoice(language: code) {
            return exact
        }

        let prefix = String(code.prefix(2))
        return AVSpeechSynthesisVoice.speechVoices().first {
            $0.language.hasPrefix(prefix)
        }
    }

    // MARK: - Delegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isPlaying = false
        currentLanguage = nil
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isPlaying = false
        currentLanguage = nil
    }
}
