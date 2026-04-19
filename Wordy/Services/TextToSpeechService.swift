import AVFoundation
import NaturalLanguage
import Combine
import Foundation

@MainActor
final class TextToSpeechService: NSObject, ObservableObject {
    static let shared = TextToSpeechService()

    private static let appleSpeechLanguageMapping: [String: String] = [
        "ar": "ar-SA",
        "bg": "bg-BG",
        "cs": "cs-CZ",
        "da": "da-DK",
        "de": "de-DE",
        "el": "el-GR",
        "en": "en-US",
        "es": "es-ES",
        "et": "et-EE",
        "fi": "fi-FI",
        "fr": "fr-FR",
        "hu": "hu-HU",
        "id": "id-ID",
        "it": "it-IT",
        "ja": "ja-JP",
        "ko": "ko-KR",
        "lt": "lt-LT",
        "lv": "lv-LV",
        "nb": "nb-NO",
        "nl": "nl-NL",
        "pl": "pl-PL",
        "pt": "pt-PT",
        "ro": "ro-RO",
        "ru": "ru-RU",
        "sk": "sk-SK",
        "sl": "sl-SI",
        "sv": "sv-SE",
        "tr": "tr-TR",
        "uk": "uk-UA",
        "zh": "zh-CN"
    ]

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
            return Self.appleSpeechLanguageCode(for: preferred)
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
        case .arabic: return "ar-SA"
        case .bulgarian: return "bg-BG"
        case .simplifiedChinese, .traditionalChinese: return "zh-CN"
        case .czech: return "cs-CZ"
        case .danish: return "da-DK"
        case .dutch: return "nl-NL"
        case .english: return "en-US"
        case .finnish: return "fi-FI"
        case .greek: return "el-GR"
        case .hungarian: return "hu-HU"
        case .indonesian: return "id-ID"
        case .japanese: return "ja-JP"
        case .korean: return "ko-KR"
        case .norwegian: return "nb-NO"
        case .ukrainian: return "uk-UA"
        case .polish: return "pl-PL"
        case .portuguese: return "pt-PT"
        case .romanian: return "ro-RO"
        case .russian: return "ru-RU"
        case .slovak: return "sk-SK"
        case .swedish: return "sv-SE"
        case .turkish: return "tr-TR"
        case .german: return "de-DE"
        case .french: return "fr-FR"
        case .spanish: return "es-ES"
        case .italian: return "it-IT"
        default: return Self.appleSpeechLanguageCode(for: lang.rawValue)
        }
    }

    static func appleSpeechLanguageCode(for code: String) -> String {
        if code.contains("-") {
            return code
        }

        return appleSpeechLanguageMapping[code.lowercased()] ?? "en-US"
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
        Self.bestAvailableVoice(for: code)
    }

    static func bestAvailableVoice(for code: String) -> AVSpeechSynthesisVoice? {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()

        // 1. exact match
        let exactMatches = allVoices.filter { $0.language == code }
        if let preferred = highestQualityVoice(in: exactMatches) {
            return preferred
        }

        // 2. same language prefix
        let prefix = String(code.prefix(2))
        let prefixMatches = allVoices.filter { $0.language.hasPrefix(prefix) }

        if let preferred = highestQualityVoice(in: prefixMatches) {
            return preferred
        }

        // 3. system fallback
        return AVSpeechSynthesisVoice(language: code)
    }

    private static func highestQualityVoice(in voices: [AVSpeechSynthesisVoice]) -> AVSpeechSynthesisVoice? {
        voices.max { lhs, rhs in
            if lhs.quality.rawValue != rhs.quality.rawValue {
                return lhs.quality.rawValue < rhs.quality.rawValue
            }

            let lhsRegionScore = preferredRegionScore(for: lhs.language)
            let rhsRegionScore = preferredRegionScore(for: rhs.language)
            if lhsRegionScore != rhsRegionScore {
                return lhsRegionScore < rhsRegionScore
            }

            return lhs.identifier < rhs.identifier
        }
    }

    private static func preferredRegionScore(for code: String) -> Int {
        switch code {
        case "en-US", "uk-UA", "pl-PL", "de-DE", "fr-FR", "es-ES", "it-IT",
             "ru-RU", "da-DK", "et-EE", "nl-NL", "sv-SE", "nb-NO", "fi-FI",
             "cs-CZ", "sk-SK", "sl-SI", "ro-RO", "tr-TR", "pt-PT", "el-GR",
             "hu-HU", "lv-LV", "lt-LT", "bg-BG", "ar-SA", "id-ID", "ja-JP",
             "ko-KR", "zh-CN":
            return 2
        default:
            return 1
        }
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
