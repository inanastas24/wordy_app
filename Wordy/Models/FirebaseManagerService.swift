//
//  FirebaseManagerService.swift
//  Wordy
//

import FirebaseFirestore
import FirebaseStorage
import FirebaseFunctions
import AVFoundation
import Combine

@MainActor
class FirebaseTTSManager: ObservableObject {
    static let shared = FirebaseTTSManager()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let functions = Functions.functions()
    
    @Published var isLoading = false
    @Published var isPlaying = false
    @Published var currentLanguage: String?
    @Published var error: String?
    
    private var audioPlayer: AVPlayer?
    private var playerItemObserver: NSKeyValueObservation?
    
    private init() {
        print("🎤 FirebaseTTSManager ініціалізовано")
    }
    
    func speak(text: String, language: String) {
        print("🎤 FirebaseTTSManager.speak() викликано: '\(text)' (\(language))")
        
        guard !text.isEmpty else {
            print("❌ Порожній текст")
            return
        }
        
        stopPlaying()
        
        isLoading = true
        error = nil
        currentLanguage = language
        
        print("🔍 Перевіряємо кеш для: \(text)_\(language)")
        
        checkCache(for: text, language: language) { [weak self] cachedURL in
            DispatchQueue.main.async {
                if let url = cachedURL {
                    print("✅ Знайдено в кеші: \(url)")
                    self?.isLoading = false
                    self?.playAudio(from: url, language: language)
                } else {
                    print("🌐 Немає в кеші, викликаємо Cloud Function")
                    self?.generateAudioViaCloudFunction(text: text, language: language)
                }
            }
        }
    }
    
    private func checkCache(for text: String, language: String, completion: @escaping (URL?) -> Void) {
        let wordId = "\(text.lowercased().trimmingCharacters(in: .whitespaces))_\(language)"
        let docRef = db.collection("words_collection").document(wordId)
        
        docRef.getDocument { snapshot, error in
            if let error = error {
                print("❌ Firestore error: \(error)")
                completion(nil)
                return
            }
            
            if let data = snapshot?.data(),
               let audio = data["audio"] as? [String: String],
               let urlString = audio[language],
               let url = URL(string: urlString) {
                print("✅ Кеш знайдено: \(urlString)")
                completion(url)
            } else {
                print("ℹ️ Кеш не знайдено для: \(wordId)")
                completion(nil)
            }
        }
    }
    
    private func generateAudioViaCloudFunction(text: String, language: String) {
        let parameters: [String: Any] = [
            "data": [
                "word": text,
                "language": language
            ]
        ]
        
        print("🌐 Викликаємо Cloud Function: generateTTS")
        print("📦 Параметри: \(parameters)")
        
        functions.httpsCallable("generateTTS").call(parameters) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("❌ Cloud Function error: \(error)")
                    self?.error = error.localizedDescription
                    
                    // Fallback: використовуємо локальний AVSpeechSynthesizer
                    print("🔊 Fallback на локальне озвучування")
                    self?.speakLocally(text: text, language: language)
                    return
                }
                
                guard let resultData = result?.data as? [String: Any],
                      let response = resultData["result"] as? [String: Any],
                      let audioURL = response["audioURL"] as? String,
                      let url = URL(string: audioURL.trimmingCharacters(in: .whitespaces)) else {
                    print("❌ Invalid response: \(String(describing: result?.data))")
                    self?.error = "Невірна відповідь сервера"
                    return
                }
                
                print("✅ Отримано аудіо URL: \(audioURL)")
                self?.playAudio(from: url, language: language)
            }
        }
    }
    
    // MARK: - Локальний fallback
    private func speakLocally(text: String, language: String) {
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: text)
        
        let languageCode = mapToAppleLanguageCode(language)
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        
        synthesizer.speak(utterance)
        
        // Імітуємо стан відтворення
        self.isPlaying = true
        self.currentLanguage = language
        
        // Автоматично скидаємо через 2 секунди (приблизний час)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isPlaying = false
        }
    }
    
    private func mapToAppleLanguageCode(_ code: String) -> String {
        let mapping = [
            "uk": "uk-UA",
            "en": "en-US",
            "de": "de-DE",
            "pl": "pl-PL",
            "es": "es-ES",
            "fr": "fr-FR",
            "it": "it-IT",
            "pt": "pt-PT"
        ]
        return mapping[code] ?? "en-US"
    }
    
    private func playAudio(from url: URL, language: String) {
        print("🔊 Відтворюємо аудіо: \(url.lastPathComponent)")
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("⚠️ Audio session error: \(error)")
        }
        
        audioPlayer?.pause()
        
        let playerItem = AVPlayerItem(url: url)
        audioPlayer = AVPlayer(playerItem: playerItem)
        
        playerItemObserver = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    print("▶️ Починаємо відтворення")
                    self?.isPlaying = true
                case .failed:
                    print("❌ Помилка плеєра")
                    self?.isPlaying = false
                    self?.error = "Помилка відтворення"
                default:
                    break
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        audioPlayer?.play()
    }
    
    @objc private func playerDidFinishPlaying() {
        DispatchQueue.main.async {
            print("⏹️ Відтворення завершено")
            self.isPlaying = false
            self.currentLanguage = nil
        }
    }
    
    func stopPlaying() {
        audioPlayer?.pause()
        audioPlayer = nil
        playerItemObserver?.invalidate()
        playerItemObserver = nil
        isPlaying = false
        currentLanguage = nil
        NotificationCenter.default.removeObserver(self)
        
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("⚠️ Deactivation error: \(error)")
        }
    }
}
