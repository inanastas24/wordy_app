//
//  TranslationResultView.swift
//  Wordy
//

import SwiftUI
import AVFoundation
import Combine

struct TranslationResultView: View {
    let result: TranslationResult
    var onClose: () -> Void
    var onSave: (() -> Void)? = nil
    
    @StateObject private var ttsManager = FirebaseTTSManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) var colorScheme
    
    // для відстеження жесту закриття
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var isSilentModeEnabled = false
    @State private var isDismissing = false  // прапорець закриття
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button(action: closeView) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: "#7F8C8D"))
                    }
                }
                
                if isSilentModeEnabled {
                    silentModeWarning
                }
                
                if ttsManager.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding()
                }
                
                if let error = ttsManager.error {
                    Text("Помилка: \(error)")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                wordSection(
                    text: result.original,
                    language: result.fromLanguage,
                    isPrimary: true
                )
                
                if let ipa = result.ipaTranscription {
                    Text(ipa)
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "#7F8C8D"))
                }
                
                Divider()
                
                wordSection(
                    text: result.translation,
                    language: result.toLanguage,
                    isPrimary: false
                )
                
                if let informal = result.informalTranslation {
                    HStack {
                        Text("розмовне:")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text(informal)
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#4ECDC4").opacity(0.8))
                            .italic()
                        
                        Button(action: {
                            speakText(text: informal, language: result.toLanguage)
                        }) {
                            Image(systemName: "speaker.wave.2")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#4ECDC4"))
                        }
                    }
                }
                
                Divider()
                
                examplesSection
                
                Spacer(minLength: 40)
                
                actionButtons
            }
            .padding()
        }
        .background(Color(hex: "#FFFDF5"))
        .onAppear {
            print("👀 TranslationResultView з'явився")
            checkSilentMode()
            isDismissing = false  // Скидаємо прапорець
        }
        //зупиняємо при будь-якому зникненні з екрану
        .onDisappear {
            print("👋 TranslationResultView зник")
            stopAudioImmediately()
        }
        // відстежуємо зміну фази — якщо йдемо в бекграунд, зупиняємо
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                stopAudioImmediately()
            }
        }
        // відстежуємо, якщо користувач починає тягнути вниз для закриття
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Якщо тягнемо вниз більше ніж на 50 поінтів — зупиняємо аудіо одразу
                    if value.translation.height > 50 && !isDismissing {
                        isDismissing = true
                        print("👇 Почато закриття жестом — зупиняємо аудіо")
                        stopAudioImmediately()
                    }
                }
        )
        // інтерактивний поп-гест для NavigationStack
        .interactiveDismissDisabled(false)
    }
    
    // централізований метод зупинки аудіо
    private func stopAudioImmediately() {
        ttsManager.stopPlaying()
    }
    
    private var silentModeWarning: some View {
        HStack(spacing: 8) {
            Image(systemName: "speaker.slash.fill")
                .foregroundColor(.orange)
            Text("Вимкніть беззвучний режим для озвучування")
                .font(.system(size: 12))
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func wordSection(text: String, language: String, isPrimary: Bool) -> some View {
        HStack(spacing: 16) {
            Text(text)
                .font(.system(size: isPrimary ? 32 : 28, weight: isPrimary ? .bold : .medium))
                .foregroundColor(isPrimary ? Color(hex: "#2C3E50") : Color(hex: "#4ECDC4"))
            
            Spacer()
            
            Button(action: {
                // Не починаємо нове відтворення, якщо вікно закривається
                guard !isDismissing else { return }
                
                print("🔊 Кнопка слова натиснута: '\(text)' (\(language))")
                checkSilentMode()
                speakText(text: text, language: language)
            }) {
                Image(systemName: iconName(for: language))
                    .font(.system(size: 20))
                    .foregroundColor(isPrimary ? Color(hex: "#4ECDC4") : .white)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(isPrimary ? Color(hex: "#4ECDC4").opacity(0.15) : Color(hex: "#4ECDC4"))
                    )
            }
            .disabled(ttsManager.isLoading || isDismissing)  // ОНОВЛЕНО: блокуємо при закритті
        }
    }
    
    private func speakText(text: String, language: String) {
        // Не починаємо, якщо вікно закривається
        guard !isDismissing else {
            print("⛔️ Вікно закривається — не починаємо відтворення")
            return
        }
        
        print("🔊 TTS: '\(text)' мовою '\(language)'")
        ttsManager.speak(text: text, language: language)
    }
    
    private func iconName(for language: String) -> String {
        let isPlaying = ttsManager.isPlaying && ttsManager.currentLanguage == language
        return isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2"
    }
    
    private var examplesSection: some View {
        VStack(spacing: 20) {
            if !result.exampleSentence.isEmpty {
                exampleCard(
                    original: result.exampleSentence,
                    translation: result.exampleTranslation,
                    originalLang: result.fromLanguage,
                    translationLang: result.toLanguage
                )
            }
            
            if let ex2 = result.exampleSentence2,
               let tr2 = result.exampleTranslation2,
               !ex2.isEmpty {
                exampleCard(
                    original: ex2,
                    translation: tr2,
                    originalLang: result.fromLanguage,
                    translationLang: result.toLanguage
                )
            }
        }
    }
    
    private func exampleCard(original: String, translation: String, originalLang: String, translationLang: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Оригінальне речення
            HStack {
                Text(original)
                    .font(.system(size: 16))
                    .foregroundColor(localizationManager.isDarkMode ? Color.white.opacity(0.95) : Color(hex: "#2C3E50"))
                    .italic()
                Spacer()
                speakButton(text: original, language: originalLang)
            }
            
            // Переклад речення
            HStack {
                Text(translation)
                    .font(.system(size: 14))
                    .foregroundColor(localizationManager.isDarkMode ? Color(hex: "#4ECDC4").opacity(0.95) : Color(hex: "#4ECDC4"))
                Spacer()
                speakButton(text: translation, language: translationLang)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E").opacity(0.9) : Color.white)
        )
    }
    
    private func speakButton(text: String, language: String, color: Color? = nil) -> some View {
        Button(action: {
            guard !isDismissing else { return }
            print("🔊 Кнопка прикладу натиснута: '\(text)' (\(language))")
            checkSilentMode()
            speakText(text: text, language: language)
        }) {
            Image(systemName: "speaker.wave.1")
                .font(.system(size: 14))
                .foregroundColor(color ?? Color(hex: "#4ECDC4"))
        }
        .disabled(isDismissing)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if let onSave = onSave {
                Button(action: {
                    guard !isDismissing else { return }
                    onSave()
                }) {
                    HStack {
                        Image(systemName: "bookmark.fill")
                        Text("Зберегти слово")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isDismissing ? Color.gray : Color(hex: "#4ECDC4"))  // ОНОВЛЕНО
                    .cornerRadius(12)
                }
                .disabled(isDismissing)
            }
            
            Button(action: closeView) {
                Text("Закрити")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isDismissing ? Color.gray : Color(hex: "#7F8C8D"))  // ОНОВЛЕНО
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isDismissing ? Color.gray : Color(hex: "#E0E0E0"), lineWidth: 1)  // ОНОВЛЕНО
                    )
            }
            .disabled(isDismissing)  // запобігаємо повторному натисканню
        }
    }
    
    private func checkSilentMode() {
        isSilentModeEnabled = AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint
    }
    
    private func closeView() {
        guard !isDismissing else { return }
        
        isDismissing = true  // Встановлюємо прапорець
        stopAudioImmediately()  // Зупиняємо аудіо одразу
        
        onClose()
        dismiss()
    }
}

