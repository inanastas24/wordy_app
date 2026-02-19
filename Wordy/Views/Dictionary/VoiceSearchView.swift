//
//  VoiceSearchView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 11.02.2026.
//

import SwiftUI

struct VoiceSearchView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var speechService = SpeechRecognitionService()
    @State private var showResult = false
    @State private var translationResult: TranslationResult?
    @State private var isLoading = false
    
    // Жовтий/золотий колір для голосового пошуку
    private let voiceColor = Color(hex: "#FFD93D")  // Теплий жовтий
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: localizationManager.isDarkMode ? "#1C1C1E" : "#FFFDF5")
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    if !showResult {
                        // Інтерфейс запису
                        Spacer()
                        
                        Text("Тримаєте кнопку і говоріть")
                            .font(.system(size: 18))
                            .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                        
                        // Анімація запису
                        ZStack {
                            // Пульсуючі кола
                            ForEach(0..<3) { i in
                                Circle()
                                    .fill(voiceColor.opacity(0.3 - Double(i) * 0.08))
                                    .frame(width: 200 + CGFloat(i * 40), height: 200 + CGFloat(i * 40))
                                    .scaleEffect(speechService.isRecording ? 1.2 : 1.0)
                                    .opacity(speechService.isRecording ? 0.6 : 0.3)
                                    .animation(
                                        .easeInOut(duration: 1.2)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.2),
                                        value: speechService.isRecording
                                    )
                            }
                            
                            Circle()
                                .fill(voiceColor)
                                .frame(width: 120, height: 120)
                                .shadow(color: voiceColor.opacity(0.4), radius: 20, x: 0, y: 10)
                            
                            Image(systemName: speechService.isRecording ? "waveform" : "mic.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        
                        if speechService.isRecording {
                            Text(speechService.recognizedText)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color(hex: "#4ECDC4"))
                                .padding()
                                .multilineTextAlignment(.center)
                        }
                        
                        // Покращена кнопка запису з long press
                        LongPressRecordButton(
                            isRecording: $speechService.isRecording,
                            onPressBegan: {
                                speechService.startRecording(language: appState.learningLanguage) { _ in }
                            },
                            onPressEnded: {
                                speechService.stopRecording()
                                if !speechService.recognizedText.isEmpty {
                                    performSearch(speechService.recognizedText)
                                }
                            },
                            buttonColor: voiceColor
                        )
                        
                        Spacer()
                    } else if let result = translationResult {
                        // Результат
                        TranslationResultView(result: result, onClose: {
                            dismiss()
                        })
                    }
                }
                .padding()
            }
            .navigationTitle("Голосовий пошук")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func performSearch(_ text: String) {
        isLoading = true
        
        let translationService = TranslationService()
        translationService.translate(
            word: text,
            appLanguage: appState.appLanguage,
            learningLanguage: appState.learningLanguage
        ) { result in
            isLoading = false
            
            switch result {
            case .success(let translation):
                translationResult = translation
                showResult = true
                
                // Зберігаємо в історію
                let item = SearchItem(
                    word: translation.original,
                    translation: translation.translation,
                    date: Date()
                )
                appState.searchHistory.insert(item, at: 0)
                
            case .failure:
                // Скидаємо і пробуємо знову
                speechService.recognizedText = ""
            }
        }
    }
}

// MARK: - Long Press Record Button (покращена версія)
struct LongPressRecordButton: View {
    @Binding var isRecording: Bool
    let onPressBegan: () -> Void
    let onPressEnded: () -> Void
    let buttonColor: Color
    
    @State private var isPressed = false
    
    var body: some View {
        ZStack {
            // Зовнішнє коло (обводка)
            Circle()
                .stroke(buttonColor.opacity(0.3), lineWidth: 4)
                .frame(width: 100, height: 100)
                .scaleEffect(isPressed ? 1.1 : 1.0)
            
            // Основна кнопка
            Circle()
                .fill(isRecording ? Color.red : buttonColor)
                .frame(width: 80, height: 80)
                .shadow(color: (isRecording ? Color.red : buttonColor).opacity(0.4), radius: 15, x: 0, y: 8)
                .scaleEffect(isPressed ? 0.95 : 1.0)
            
            // Іконка
            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(.white)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isRecording && !isPressed {
                        isPressed = true
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        onPressBegan()
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    if isRecording {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        onPressEnded()
                    }
                }
        )
        .animation(.easeInOut(duration: 0.2), value: isPressed)
        .animation(.easeInOut(duration: 0.3), value: isRecording)
    }
}
