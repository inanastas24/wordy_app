//1
//  TranslationBubbleView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI
import AVFoundation

struct TranslationBubbleView: View {
    let result: TranslationResult
    let onSave: (SavedWord) -> Void
    let onDismiss: () -> Void
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var isSaved = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    @State private var isPlayingOriginal = false
    @State private var isPlayingTranslation = false
    
    @State private var showConfetti = false
    
    var body: some View {
        ZStack { // ← Додано ZStack для шарування
            // Основна картка
            VStack(spacing: 0) {
                // MARK: - Header
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "#7F8C8D"))
                            .padding(8)
                            .background(Color.white.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // MARK: - Content
                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        HStack(spacing: 12) {
                            Text(result.original)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                            
                            AudioBubbleButton(isPlaying: $isPlayingOriginal) {
                                speak(text: result.original, isOriginal: true)
                            }
                        }
                        
                        if let ipa = result.ipaTranscription {
                            Text(ipa)
                                .font(.system(size: 17, design: .serif))
                                .foregroundColor(Color(hex: "#7F8C8D"))
                                .italic()
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Circle().fill(Color(hex: "#4ECDC4").opacity(0.3)).frame(width: 4, height: 4)
                        Circle().fill(Color(hex: "#4ECDC4").opacity(0.6)).frame(width: 4, height: 4)
                        Circle().fill(Color(hex: "#4ECDC4").opacity(0.3)).frame(width: 4, height: 4)
                    }
                    
                    HStack(spacing: 12) {
                        Text(result.translation)
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: "#4ECDC4"))
                        
                        AudioBubbleButton(isPlaying: $isPlayingTranslation) {
                            speak(text: result.translation, isOriginal: false)
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                // MARK: - Save Button
                Button(action: {
                    Task {
                        await saveWord()
                    }
                }) {
                    HStack(spacing: 10) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: isSaved ? "checkmark.circle.fill" : "plus.circle.fill")
                                .font(.system(size: 20))
                                .symbolRenderingMode(.hierarchical)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        
                        Text(buttonText)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(width: 220, height: 52)
                    .background(
                        Capsule()
                            .fill(isSaved ? Color(hex: "#2ECC71") : Color(hex: "#4ECDC4"))
                            .shadow(
                                color: (isSaved ? Color(hex: "#2ECC71") : Color(hex: "#4ECDC4")).opacity(0.4),
                                radius: isSaved ? 20 : 15,
                                x: 0,
                                y: isSaved ? 10 : 8
                            )
                    )
                    .scaleEffect(isSaved ? 1.02 : 1.0)
                    .opacity(isLoading ? 0.7 : 1.0)
                }
                .disabled(isSaved || isLoading)
                .padding(.top, 24)
                .padding(.bottom, 20)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSaved)
                .animation(.easeInOut, value: isLoading)
            }
            .frame(width: min(UIScreen.main.bounds.width - 60, 340))
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(hex: "#FFFDF5").opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .fill(.ultraThinMaterial)
                    )
                    .shadow(
                        color: Color(hex: "#4ECDC4").opacity(0.15),
                        radius: 40,
                        x: 0,
                        y: 20
                    )
                    .shadow(
                        color: Color.black.opacity(0.08),
                        radius: 20,
                        x: 0,
                        y: 10
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(Color.white.opacity(0.9), lineWidth: 1.5)
            )
            .alert("Помилка збереження", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            
            // ← ХЛОПУШКА ЗВЕРХУ КАРТКИ
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
                    .frame(width: min(UIScreen.main.bounds.width - 60, 340))
            }
        }
        .onChange(of: isSaved) { _, newValue in
            if newValue {
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showConfetti = false
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var buttonText: String {
        if isLoading {
            return "Збереження..."
        } else if isSaved {
            return "Збережено"
        } else {
            return "Додати в словник"
        }
    }
    
    // MARK: - Methods
    private func saveWord() async {
        isLoading = true
        
        do {
            let word = SavedWord(
                original: result.original,
                translation: result.translation,
                transcription: result.ipaTranscription ?? "",
                exampleSentence: result.exampleSentence,
                languagePair: "\(appState.learningLanguage)-\(appState.appLanguage)"
            )
            
            let wordModel = SavedWordModel(
                id: nil,
                original: result.original,
                translation: result.translation,
                transcription: result.ipaTranscription,
                exampleSentence: result.exampleSentence,
                languagePair: "\(appState.appLanguage)-\(appState.learningLanguage)",
                isLearned: false,
                reviewCount: 0,
                createdAt: Date()
            )
            
            await MainActor.run {
                onSave(word)
            }
            
            try await FirestoreService.shared.saveWord(wordModel)
            
            await MainActor.run {
                isLoading = false
                isSaved = true
                
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    onDismiss()
                }
            }
            
        } catch {
            await MainActor.run {
                isLoading = false
                isSaved = false
                errorMessage = "Не вдалося зберегти в хмару: \(error.localizedDescription)"
                showError = true
                
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
        }
    }
    
    private func speak(text: String, isOriginal: Bool) {
        let language = isOriginal ? appState.learningLanguage : appState.appLanguage
        
        if isOriginal {
            isPlayingOriginal = true
            let duration = min(Double(text.count) * 0.08, 3.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                isPlayingOriginal = false
            }
        } else {
            isPlayingTranslation = true
            let duration = min(Double(text.count) * 0.08, 3.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                isPlayingTranslation = false
            }
        }
        
        SpeechService.shared.speak(text, language: language)
    }
}

struct AudioBubbleButton: View {
    @Binding var isPlaying: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#4ECDC4").opacity(0.12))
                    .frame(width: 36, height: 36)
                
                if isPlaying {
                    HStack(spacing: 2) {
                        ForEach(0..<3) { i in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color(hex: "#4ECDC4"))
                                .frame(width: 2.5, height: isPlaying ? 12 : 5)
                                .animation(
                                    .easeInOut(duration: 0.4)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.1),
                                    value: isPlaying
                                )
                        }
                    }
                } else {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                }
            }
        }
        .frame(width: 36, height: 36)
        .buttonStyle(BubbleButtonStyle())
        .animation(.spring(response: 0.2), value: isPlaying)
    }
}

struct BubbleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
