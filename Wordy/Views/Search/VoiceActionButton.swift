//
//  VoiceActionButton.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI

// MARK: - VoiceActionButton (НОВИЙ КОМПОНЕНТ для hold-to-record)
struct VoiceActionButton: View {
    @ObservedObject var speechService: SpeechRecognitionService
    let title: String
    let subtitle: String
    let isDarkMode: Bool
    let language: String
    let onResult: (String) -> Void
    
    @State private var isPressed = false
    
    // Жовтий/золотий колір для голосового пошуку
    private let voiceColor = Color(hex: "#FFD93D")  // Теплий жовтий
    private let voiceColorDark = Color(hex: "#F4C430")  // Темніший жовтий для запису
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                Image(systemName: speechService.isRecording ? "waveform" : "mic.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                
                Text(speechService.isRecording ? "Listening..." : title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(speechService.isRecording ? "speak now" : subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(speechService.isRecording ? voiceColorDark : voiceColor)
            .cornerRadius(20)
            .shadow(color: voiceColor.opacity(0.3), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !speechService.isRecording && !isPressed {
                        isPressed = true
                        speechService.startRecording(language: language) { text in
                            // Пошук виконується тільки якщо є текст
                            if let text = text, !text.isEmpty {
                                onResult(text)
                            }
                        }
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    if speechService.isRecording {
                        speechService.stopRecording()
                    }
                }
        )
        .buttonStyle(PlainButtonStyle())
    }
}
