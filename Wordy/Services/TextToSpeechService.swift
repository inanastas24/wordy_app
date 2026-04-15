import AVFoundation
import NaturalLanguage
import Combine
import Foundation

@MainActor
final class TextToSpeechService: NSObject, ObservableObject {
    static let shared = TextToSpeechService()

    @Published private(set) var isPlaying = false
    @Published private(set) var currentLanguage: String?
    @Published private(set) var activeUtteranceID: String?

    private let synthesizer = AVSpeechSynthesizer()
    private let audioSession = AVAudioSession.sharedInstance()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(text: String, language: String, utteranceID: String? = nil) {
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "`", with: "'")

        guard !cleaned.isEmpty else { return }

        let resolvedLang = resolveLanguage(for: cleaned, preferred: language)
        let finalID = utteranceID ?? makeUtteranceID(text: cleaned, language: resolvedLang)

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        configureAudioSessionForPlayback()

        let utterance = AVSpeechUtterance(string: cleaned)
        utterance.voice = bestVoice(for: resolvedLang)
        utterance.rate = preferredRate(for: resolvedLang)

        currentLanguage = resolvedLang
        activeUtteranceID = finalID
        isPlaying = true

        synthesizer.speak(utterance)
    }

    private func preferredRate(for code: String) -> Float {
        switch code {
        case "uk-UA":
            return 0.46
        case "pl-PL":
            return 0.48
        case "de-DE", "fr-FR", "it-IT", "es-ES":
            return 0.49
        default:
            return 0.5
        }
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
        resetPlaybackState()
        deactivateAudioSession()
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
        if code.contains("-") {
            return code
        }

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

    private func configureAudioSessionForPlayback() {
        do {
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("⚠️ Failed to configure playback audio session: \(error)")
        }
    }

    private func deactivateAudioSession() {
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("⚠️ Failed to deactivate playback audio session: \(error)")
        }
    }

    private func resetPlaybackState() {
        isPlaying = false
        currentLanguage = nil
        activeUtteranceID = nil
    }

    private func bestVoice(for code: String) -> AVSpeechSynthesisVoice? {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()

        // 1. exact match
        let exactMatches = allVoices.filter { $0.language == code }
        if let preferred = exactMatches.first {
            return preferred
        }

        // 2. same language prefix
        let prefix = String(code.prefix(2))
        let prefixMatches = allVoices.filter { $0.language.hasPrefix(prefix) }

        if let preferred = prefixMatches.first {
            return preferred
        }

        // 3. system fallback
        return AVSpeechSynthesisVoice(language: code)
    }

}

extension TextToSpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            resetPlaybackState()
            deactivateAudioSession()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            resetPlaybackState()
            deactivateAudioSession()
        }
    }
}
