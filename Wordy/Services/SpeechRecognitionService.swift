import Speech
import AVFoundation
import Combine
import NaturalLanguage

class SpeechRecognitionService: ObservableObject {
    @Published var isRecording = false
    @Published var recognizedText = ""
    @Published var selectedLanguage: String = "uk"  // 🆕 Явно вибрана мова
    @Published var error: Error?
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var completion: ((String?) -> Void)?
    
    // 🆕 Доступні мови для розпізнавання
    let availableLanguages: [(code: String, name: String, flag: String)] = [
        ("uk", "Українська", "🇺🇦"),
        ("en", "English", "🇬🇧"),
        ("pl", "Polski", "🇵🇱"),
        ("de", "Deutsch", "🇩🇪"),
        ("fr", "Français", "🇫🇷"),
        ("es", "Español", "🇪🇸"),
        ("it", "Italiano", "🇮🇹")
    ]
    
    // MARK: - Public Methods
    
    /// 🆕 Запис з явно вибраною мовою
    func startRecording(language: String, completion: @escaping (String?) -> Void) {
        self.selectedLanguage = language
        self.completion = completion
        
        reset()
        
        requestAuthorization { [weak self] authorized in
            guard let self = self, authorized else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            self.startListening(language: language)
        }
    }
    
    /// 🆕 Автоматичне визначення (як fallback)
    func startRecordingWithAutoDetection(appLanguage: String, learningLanguage: String, completion: @escaping (String?, String?) -> Void) {
        // Спочатку пробуємо мову додатка
        startRecording(language: appLanguage) { [weak self] text in
            guard let self = self, let recognizedText = text, !recognizedText.isEmpty else {
                completion(nil, nil)
                return
            }
            
            // Перевіряємо чи схоже на мову додатка
            let confidence = self.estimateLanguageConfidence(text: recognizedText, expectedLanguage: appLanguage)
            
            if confidence > 0.5 {
                completion(recognizedText, appLanguage)
            } else {
                // Спробуємо мову вивчення
                self.switchRecognizer(to: learningLanguage)
                completion(recognizedText, learningLanguage)
            }
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            if self.isRecording {
                self.recognitionTask?.cancel()
                self.isRecording = false
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func startListening(language: String) {
        let locale = localeForLanguage(language)
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        
        // 🆕 Перевіряємо чи розпізнавач доступний
        if let recognizer = speechRecognizer, recognizer.isAvailable {
            // Все добре, використовуємо поточний
        } else {
            // Fallback на англійську
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
            guard let fallbackRecognizer = speechRecognizer, fallbackRecognizer.isAvailable else {
                DispatchQueue.main.async { self.completion?(nil) }
                return  // 🆕 Виходимо з методу
            }
            // Продовжуємо з fallback розпізнавачем
        }
        
        setupAudioSession()
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            DispatchQueue.main.async { self.completion?(nil) }
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let text = result.bestTranscription.formattedString
                
                DispatchQueue.main.async {
                    self.recognizedText = text
                }
                
                if result.isFinal {
                    DispatchQueue.main.async {
                        self.isRecording = false
                        self.completion?(text)
                    }
                }
            }
            
            if error != nil {
                DispatchQueue.main.async {
                    self.isRecording = false
                    self.completion?(self.recognizedText)
                }
            }
        }
        
        setupAudioTap()
        
        do {
            audioEngine.prepare()
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isRecording = true
            }
        } catch {
            print("❌ Audio engine error: \(error)")
            DispatchQueue.main.async {
                self.completion?(nil)
            }
        }
    }
    
    private func switchRecognizer(to language: String) {
        // Перезапускаємо розпізнавач з новою мовою
        reset()
        startListening(language: language)
    }
    
    /// 🆕 Проста оцінка чи текст відповідає очікуваній мові
    private func estimateLanguageConfidence(text: String, expectedLanguage: String) -> Double {
        let lower = text.lowercased()
        
        // Специфічні символи = 100% впевненість
        let specificChars: [String: CharacterSet] = [
            "uk": CharacterSet(charactersIn: "ґєіїҐЄІЇ"),
            "pl": CharacterSet(charactersIn: "ąćęłńóśźżĄĆĘŁŃÓŚŹŻ"),
            "de": CharacterSet(charactersIn: "äöüßÄÖÜẞ"),
            "fr": CharacterSet(charactersIn: "àâæçéèêëïîôœùûüÿÀÂÆÇÉÈÊËÏÎÔŒÙÛÜŸ"),
            "es": CharacterSet(charactersIn: "áéíóúüñÁÉÍÓÚÜÑ¿¡"),
            "it": CharacterSet(charactersIn: "àèéìòùÀÈÉÌÒÙ")
        ]
        
        if let chars = specificChars[expectedLanguage], lower.rangeOfCharacter(from: chars) != nil {
            return 1.0
        }
        
        // Використовуємо NLLanguageRecognizer як підтвердження
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        if let dominant = recognizer.dominantLanguage {
            let mapped = mapNLLanguage(dominant)
            if mapped == expectedLanguage {
                return 0.8
            }
        }
        
        return 0.3
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ Audio session error: \(error)")
        }
    }
    
    private func setupAudioTap() {
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
    }
    
    private func reset() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
    }
    
    private func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            completion(status == .authorized)
        }
    }
    
    // MARK: - Helper Methods
    
    private func mapNLLanguage(_ language: NLLanguage) -> String {
        switch language {
        case .ukrainian: return "uk"
        case .english: return "en"
        case .polish: return "pl"
        case .german: return "de"
        case .french: return "fr"
        case .spanish: return "es"
        case .italian: return "it"
        default: return language.rawValue
        }
    }
    
    private func localeForLanguage(_ code: String) -> Locale {
        let mapping: [String: String] = [
            "uk": "uk-UA",
            "en": "en-US",
            "pl": "pl-PL",
            "de": "de-DE",
            "fr": "fr-FR",
            "es": "es-ES",
            "it": "it-IT"
        ]
        return Locale(identifier: mapping[code] ?? "en-US")
    }
}
