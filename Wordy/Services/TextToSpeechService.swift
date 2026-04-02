import AVFoundation
import NaturalLanguage
import Combine
import Foundation

@MainActor
final class TextToSpeechService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = TextToSpeechService()

    @Published private(set) var isPlaying = false
    @Published private(set) var currentLanguage: String?
    @Published private(set) var activeUtteranceID: String?

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(text: String, language: String, utteranceID: String? = nil) {
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        guard !cleaned.isEmpty else { return }

        let resolvedLang = resolveLanguage(for: cleaned, preferred: language)
        let finalID = utteranceID ?? makeUtteranceID(text: cleaned, language: resolvedLang)

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: cleaned)
        utterance.voice = bestVoice(for: resolvedLang)
        utterance.rate = 0.5

        currentLanguage = resolvedLang
        activeUtteranceID = finalID
        isPlaying = true

        synthesizer.speak(utterance)
    }

    func toggle(text: String, language: String, utteranceID: String? = nil) {
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        guard !cleaned.isEmpty else { return }

        let resolvedLang = resolveLanguage(for: cleaned, preferred: language)
        let finalID = utteranceID ?? makeUtteranceID(text: cleaned, language: resolvedLang)

        if isPlaying && activeUtteranceID == finalID {
            stop()
            return
        }

        speak(text: cleaned, language: language, utteranceID: finalID)
    }

    func isActive(_ utteranceID: String) -> Bool {
        isPlaying && activeUtteranceID == utteranceID
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        currentLanguage = nil
        activeUtteranceID = nil
    }

    private func makeUtteranceID(text: String, language: String) -> String {
        "\(language)|\(text.lowercased())"
    }

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

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isPlaying = false
        currentLanguage = nil
        activeUtteranceID = nil
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isPlaying = false
        currentLanguage = nil
        activeUtteranceID = nil
    }
}
