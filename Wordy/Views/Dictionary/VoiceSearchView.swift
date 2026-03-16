//
//  VoiceSearchView.swift
//  Wordy
//

import SwiftUI
import Speech
import AVFoundation

struct VoiceSearchView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var subscriptionManager: SubscriptionManager  // 🆕 Додано
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var speechService = SpeechRecognitionService()
    @State private var showResult = false
    @State private var translationResult: TranslationResult?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPermissionAlert = false
    @State private var showPaywall = false  // 🆕 Додано для показу paywall тут
    
    // Callback returns recognized text only - language is determined by AppState
    var onResult: ((String) -> Void)?
    
    private let voiceColor = Color(hex: "#FFD93D")
    private let maxInputLength = 254
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 🆕 Якщо немає підписки — показуємо тільки фон + paywall
                if subscriptionManager.isSubscriptionExpired || !subscriptionManager.canUseApp {
                    Color(hex: localizationManager.isDarkMode ? "#1C1C1E" : "#FFFDF5")
                        .ignoresSafeArea()
                } else {
                    // Основний контент тільки для активної підписки
                    mainContent
                }
                
                // 🆕 Paywall показується поверх всього
                if showPaywall {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
            }
            .navigationTitle(localizationManager.string(.voice))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizationManager.string(.cancel)) {
                        dismiss()
                    }
                }
            }
            .alert(localizationManager.string(.permissionRequired), isPresented: $showPermissionAlert) {
                Button(localizationManager.string(.openSettings)) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button(localizationManager.string(.cancel), role: .cancel) {}
            } message: {
                Text(localizationManager.string(.permissionMessage))
            }
            .onAppear {
                // 🆕 Перевіряємо підписку одразу
                if subscriptionManager.isSubscriptionExpired || !subscriptionManager.canUseApp {
                    showPaywall = true
                } else {
                    checkPermissions()
                }
            }
            // 🆕 Показуємо paywall як fullScreenCover
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView(
                    isFirstTime: false,
                    onClose: {
                        // При закритті paywall закриваємо і VoiceSearchView
                        showPaywall = false
                        dismiss()
                    },
                    onSubscribe: {
                        // При підписці закриваємо paywall і продовжуємо з VoiceSearchView
                        showPaywall = false
                    }
                )
                .environmentObject(subscriptionManager)
                .environmentObject(localizationManager)
            }
        }
    }
    
    // 🆕 Винесено основний контент окремо
    private var mainContent: some View {
        ZStack {
            Color(hex: localizationManager.isDarkMode ? "#1C1C1E" : "#FFFDF5")
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                if !showResult {
                    Spacer()
                    
                    Text(localizationManager.string(.holdToSpeak))
                        .font(.system(size: 18))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                    
                    // Recording Animation
                    ZStack {
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
                    
                    // Recognized Text
                    if !speechService.recognizedText.isEmpty {
                        Text(speechService.recognizedText)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color(hex: "#4ECDC4"))
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    
                    // Language pair indicator
                    HStack(spacing: 8) {
                        Text(appState.languagePair.source.localizedName(in: localizationManager.currentLanguage))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#4ECDC4"))
                        
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        Text(appState.languagePair.target.localizedName(in: localizationManager.currentLanguage))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#4ECDC4"))
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    LongPressRecordButton(
                        isRecording: $speechService.isRecording,
                        onPressBegan: {
                            print("🎤 Starting recording...")
                            errorMessage = nil
                            
                            // Check permissions
                            let speechStatus = SFSpeechRecognizer.authorizationStatus()
                            let micStatus = AVAudioApplication.shared.recordPermission
                            
                            guard speechStatus == .authorized else {
                                requestSpeechPermission()
                                return
                            }
                            
                            guard micStatus == .granted else {
                                requestMicrophonePermission()
                                return
                            }
                            
                            // Use source language for recognition
                            speechService.startRecording(language: appState.languagePair.source.rawValue) { text in
                                guard let text = text, !text.isEmpty else {
                                    DispatchQueue.main.async {
                                        errorMessage = localizationManager.string(.recognitionError)
                                    }
                                    return
                                }
                                
                                print("🎤 Recognized: '\(text)' (length: \(text.count))")
                                
                                DispatchQueue.main.async {
                                    // Check length limit - обрізаємо до 254 символів
                                    if text.count > maxInputLength {
                                        let truncated = String(text.prefix(maxInputLength))
                                        onResult?(truncated)
                                        ToastManager.shared.show(
                                            message: localizationManager.string(.voiceInputTooLong),
                                            style: .warning
                                        )
                                    } else {
                                        onResult?(text)
                                    }
                                    dismiss()
                                }
                            }
                        },
                        onPressEnded: {
                            speechService.stopRecording()
                        },
                        buttonColor: voiceColor
                    )
                    
                    Spacer()
                } else if let result = translationResult {
                    TranslationResultView(result: result, onClose: {
                        dismiss()
                    })
                }
            }
            .padding()
        }
    }
    
    private func checkPermissions() {
        // Request permissions if not determined
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        let micStatus = AVAudioApplication.shared.recordPermission
        
        if speechStatus == .notDetermined {
            SFSpeechRecognizer.requestAuthorization { _ in }
        }
        
        if micStatus == .undetermined {
            AVAudioApplication.requestRecordPermission { _ in }
        }
    }
    
    private func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                if status != .authorized {
                    showPermissionAlert = true
                }
            }
        }
    }
    
    private func requestMicrophonePermission() {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                if !granted {
                    showPermissionAlert = true
                }
            }
        }
    }
}

struct LongPressRecordButton: View {
    @Binding var isRecording: Bool
    let onPressBegan: () -> Void
    let onPressEnded: () -> Void
    let buttonColor: Color
    
    @State private var isPressed = false
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(buttonColor.opacity(0.3), lineWidth: 4)
                .frame(width: 100, height: 100)
                .scaleEffect(isPressed ? 1.1 : 1.0)
            
            Circle()
                .fill(isRecording ? Color.red : buttonColor)
                .frame(width: 80, height: 80)
                .shadow(color: (isRecording ? Color.red : buttonColor).opacity(0.4), radius: 15, x: 0, y: 8)
                .scaleEffect(isPressed ? 0.95 : 1.0)
            
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
