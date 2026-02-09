//1
//  SpeechRecognitionService.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 26.01.2026.
//

import Speech
import AVFoundation
import Combine

class SpeechRecognitionService: ObservableObject {
    @Published var isRecording = false
    @Published var recognizedText = ""
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    func startRecording(language: String, completion: @escaping (String?) -> Void) {
        // Скидаємо попереднє
        reset()
        
        // Запитуємо дозвіл
        requestAuthorization { [weak self] authorized in
            guard let self = self, authorized else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            self.startListening(language: language, completion: completion)
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        
        // Видаляємо tap!
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        
        // Додаємо таймаут на випадок якщо final result не прийде
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            if self?.isRecording == true {
                self?.recognitionTask?.cancel()
                self?.isRecording = false
            }
        }
    }
    
    private func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            completion(status == .authorized)
        }
    }
    
    private func startListening(language: String, completion: @escaping (String?) -> Void) {
        // Налаштовуємо розпізнавач під мову користувача
        let locale = Locale(identifier: languageCode(language))
        let recognizer = SFSpeechRecognizer(locale: locale)
        
        guard let recognizer = recognizer, recognizer.isAvailable else {
            DispatchQueue.main.async { completion(nil) }
            return
        }
        
        // Зупиняємо попередній запис якщо є
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        do {
            // Аудіо сесія
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Запит розпізнавання
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                completion(nil)
                return
            }
            recognitionRequest.shouldReportPartialResults = true
            
            // Завдання розпізнавання
            recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    let text = result.bestTranscription.formattedString
                    DispatchQueue.main.async {
                        self.recognizedText = text
                    }
                    
                    // Коли закінчили говорити
                    if result.isFinal {
                        DispatchQueue.main.async {
                            self.isRecording = false
                            completion(text)
                        }
                    }
                }
                
                if error != nil {
                    DispatchQueue.main.async {
                        self.isRecording = false
                        completion(nil)
                    }
                }
            }
            
            // Перевіряємо чи немає вже tap
            let inputNode = audioEngine.inputNode
            inputNode.removeTap(onBus: 0)
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            DispatchQueue.main.async {
                self.isRecording = true
            }
            
        } catch {
            print("❌ Помилка запису: \(error)")
            completion(nil)
        }
    }
    
    private func reset() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        recognizedText = ""
        
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
    }
    
    private func languageCode(_ code: String) -> String {
        let mapping = [
            "uk": "uk-UA",
            "en": "en-US",
            "es": "es-ES",
            "de": "de-DE",
            "fr": "fr-FR",
            "it": "it-IT",
            "pl": "pl-PL"
        ]
        return mapping[code] ?? "en-US"
    }
}
