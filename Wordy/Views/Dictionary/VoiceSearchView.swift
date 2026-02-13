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
                            Circle()
                                .fill(voiceColor.opacity(0.2))
                                .frame(width: 200, height: 200)
                                .scaleEffect(speechService.isRecording ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: speechService.isRecording)
                            
                            Circle()
                                .fill(voiceColor)
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: speechService.isRecording ? "waveform" : "mic.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        
                        if speechService.isRecording {
                            Text(speechService.recognizedText)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color(hex: "#4ECDC4"))
                                .padding()
                        }
                        
                        // Кнопка запису
                        LongPressButton(
                            isRecording: $speechService.isRecording,
                            onPressBegan: {
                                speechService.startRecording(language: appState.learningLanguage) { _ in
                                    // Результат обробляється через @Published в speechService
                                }
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

// MARK: - Long Press Button
struct LongPressButton: View {
    @Binding var isRecording: Bool
    let onPressBegan: () -> Void
    let onPressEnded: () -> Void
    let buttonColor: Color
    
    var body: some View {
        Circle()
            .stroke(buttonColor, lineWidth: 3)
            .frame(width: 80, height: 80)
            .overlay(
                Text(isRecording ? "..." : "Тримайте")
                    .font(.system(size: 12))
                    .foregroundColor(buttonColor)
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isRecording {
                            isRecording = true
                            onPressBegan()
                        }
                    }
                    .onEnded { _ in
                        isRecording = false
                        onPressEnded()
                    }
            )
    }
}
