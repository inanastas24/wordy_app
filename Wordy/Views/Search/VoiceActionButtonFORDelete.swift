import SwiftUI

struct VoiceActionButton: View {
    @ObservedObject var speechService: SpeechRecognitionService
    let title: String
    let subtitle: String
    let isDarkMode: Bool
    let appLanguage: String
    let learningLanguage: String
    let onResult: (String, String) -> Void  // text, language
    
    @State private var isPressed = false
    @State private var selectedLanguage: String = "uk"
    
    private let voiceColor = Color(hex: "#FFD93D")
    private let voiceColorDark = Color(hex: "#F4C430")
    
    var body: some View {
        VStack(spacing: 8) {
            // 🆕 Міні-селектор мови
            LanguageMiniSelector(
                selectedLanguage: $selectedLanguage,
                appLanguage: appLanguage,
                learningLanguage: learningLanguage
            )
            
            Button(action: {}) {
                VStack(spacing: 6) {
                    Image(systemName: speechService.isRecording ? "waveform" : "mic.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                    
                    Text(speechService.isRecording ? "Listening..." : title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(speechService.isRecording ? selectedLanguage.uppercased() : subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 90)
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
                            
                            speechService.startRecording(language: selectedLanguage) { text in
                                if let text = text, !text.isEmpty {
                                    DispatchQueue.main.async {
                                        onResult(text, selectedLanguage)
                                    }
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
}

// MARK: - Mini Language Selector
struct LanguageMiniSelector: View {
    @Binding var selectedLanguage: String
    let appLanguage: String
    let learningLanguage: String
    
    var body: some View {
        HStack(spacing: 8) {
            LanguageMiniButton(
                code: appLanguage,
                isSelected: selectedLanguage == appLanguage
            ) {
                selectedLanguage = appLanguage
            }
            
            LanguageMiniButton(
                code: learningLanguage,
                isSelected: selectedLanguage == learningLanguage
            ) {
                selectedLanguage = learningLanguage
            }
        }
    }
}

struct LanguageMiniButton: View {
    let code: String
    let isSelected: Bool
    let action: () -> Void
    
    var flag: String {
        switch code {
        case "uk": return "🇺🇦"
        case "en": return "🇬🇧"
        case "pl": return "🇵🇱"
        case "de": return "🇩🇪"
        case "fr": return "🇫🇷"
        case "es": return "🇪🇸"
        case "it": return "🇮🇹"
        default: return "🏳️"
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(flag)
                .font(.system(size: 20))
                .padding(8)
                .background(
                    Circle()
                        .fill(isSelected ? Color(hex: "#4ECDC4") : Color.gray.opacity(0.3))
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color(hex: "#4ECDC4") : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
