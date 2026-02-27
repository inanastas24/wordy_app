import SwiftUI

struct VoiceSearchView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var speechService = SpeechRecognitionService()
    @State private var showResult = false
    @State private var translationResult: TranslationResult?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedLanguage: String = "uk"
    
    var onResult: ((String, String) -> Void)?
    
    private let voiceColor = Color(hex: "#FFD93D")
    
    // 🆕 Мови для вибору
    private var languageOptions: [(code: String, name: String, flag: String)] {
        let appLang = appState.appLanguage
        let learningLang = appState.learningLanguage
        
        // Показуємо спочатку мову додатка і мову вивчення
        var options: [(code: String, name: String, flag: String)] = []
        
        if let appOption = speechService.availableLanguages.first(where: { $0.code == appLang }) {
            options.append(appOption)
        }
        if let learningOption = speechService.availableLanguages.first(where: { $0.code == learningLang }),
           !options.contains(where: { $0.code == learningOption.code }) {
            options.append(learningOption)
        }
        
        // Додаємо решту мов
        for lang in speechService.availableLanguages {
            if !options.contains(where: { $0.code == lang.code }) {
                options.append(lang)
            }
        }
        
        return options
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: localizationManager.isDarkMode ? "#1C1C1E" : "#FFFDF5")
                    .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    if !showResult {
                        Spacer()
                        
                        // 🆕 Селектор мови
                        languageSelector
                        
                        Text(localizationManager.string(.holdToSpeak))
                            .font(.system(size: 18))
                            .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                        
                        // Анімація запису
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
                        
                        // Розпізнаний текст
                        if !speechService.recognizedText.isEmpty {
                            Text(speechService.recognizedText)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color(hex: "#4ECDC4"))
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                        
                        // 🆕 Показуємо вибрану мову
                        HStack {
                            Text(localizationManager.string(.listeningIn))
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            Text(languageName(selectedLanguage))
                                .font(.system(size: 12, weight: .semibold))
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
                                print("🎤 Starting recording in \(selectedLanguage)")
                                errorMessage = nil
                                
                                speechService.startRecording(language: selectedLanguage) { text in
                                    guard let text = text, !text.isEmpty else {
                                        DispatchQueue.main.async {
                                            errorMessage = localizationManager.string(.recognitionError)
                                        }
                                        return
                                    }
                                    
                                    print("🎤 Recognized: '\(text)' in language: \(selectedLanguage)")
                                    
                                    DispatchQueue.main.async {
                                        performSearch(text: text, language: selectedLanguage)
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
            .navigationTitle(localizationManager.string(.voice))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizationManager.string(.cancel)) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    private var languageSelector: some View {
        VStack(spacing: 12) {
            Text(localizationManager.string(.selectLanguageToSpeak))
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(languageOptions, id: \.code) { lang in
                        VoiceLanguageButton(
                            flag: lang.flag,
                            name: lang.name,
                            isSelected: selectedLanguage == lang.code,
                            action: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedLanguage = lang.code
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func languageName(_ code: String) -> String {
        languageOptions.first(where: { $0.code == code })?.name ?? code.uppercased()
    }
    
    private func performSearch(text: String, language: String) {
            DispatchQueue.main.async {
                self.onResult?(text, language)
                self.dismiss()
            }
        }
    }

// MARK: - Language Button
struct VoiceLanguageButton: View {
    let flag: String
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(flag)
                    .font(.system(size: 32))
                Text(name)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 70, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "#4ECDC4") : Color.gray.opacity(0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "#4ECDC4") : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
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
