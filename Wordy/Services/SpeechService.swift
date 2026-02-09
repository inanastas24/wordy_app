//1
//  SpeechService.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 26.01.2026.
//

import AVFoundation

class SpeechService {
    static let shared = SpeechService()
    private let synthesizer = AVSpeechSynthesizer()
    
    private init() {}
    
    func speak(_ text: String, language: String) {
        // Зупиняємо попереднє озвучування
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Визначаємо мову для озвучування
        utterance.voice = AVSpeechSynthesisVoice(language: voiceLanguageCode(language))
        utterance.rate = 0.5 // Повільніше для навчання
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
        
        print("🔊 Озвучую: '\(text)' мовою \(voiceLanguageCode(language))")
    }
    
    // Наші коди → коди iOS
    private func voiceLanguageCode(_ code: String) -> String {
        let mapping = [
            "uk": "uk-UA",  // Українська
            "en": "en-US",  // Англійська (USA)
            "es": "es-ES",  // Іспанська
            "de": "de-DE",  // Німецька
            "fr": "fr-FR",  // Французька
            "it": "it-IT",  // Італійська
            "pl": "pl-PL"   // Польська
        ]
        return mapping[code] ?? "en-US"
    }
    
    // Перевіряємо доступні голоси (для дебагу)
    func availableVoices() {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        print("🎙️ Доступні голоси:")
        for voice in voices {
            print("  - \(voice.language): \(voice.name)")
        }
    }
}
