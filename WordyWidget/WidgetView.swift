//
//  WidgetView.swift
//  WordyWidgetExtension
//

import WidgetKit
import SwiftUI

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Localization for Widget
enum WidgetLanguage: String, CaseIterable {
    case ukrainian = "uk"
    case english = "en"
    case polish = "pl"
    
    static var current: WidgetLanguage {
        let saved = UserDefaults(suiteName: "group.Wordy")?.string(forKey: "appLanguage") ?? "en"
        return WidgetLanguage(rawValue: saved) ?? .english
    }
}

struct WidgetLocalization {
    static func string(_ key: WidgetKey) -> String {
        let lang = WidgetLanguage.current
        return translations[key]?[lang] ?? key.rawValue
    }
    
    enum WidgetKey: String {
        case wordOfDay, addWords, scan, voice, scanText, voiceSearch, sayWord, emptyDictionary, addWordsInApp
    }
    
    private static let translations: [WidgetKey: [WidgetLanguage: String]] = [
        .wordOfDay: [.ukrainian: "Слово дня", .english: "Word of the day", .polish: "Słowo dnia"],
        .addWords: [.ukrainian: "Додайте слова", .english: "Add words", .polish: "Dodaj słowa"],
        .scan: [.ukrainian: "Сканувати", .english: "Scan", .polish: "Skanuj"],
        .voice: [.ukrainian: "Голосом", .english: "Voice", .polish: "Głos"],
        .scanText: [.ukrainian: "Сканувати текст", .english: "Scan text", .polish: "Skanuj tekst"],
        .voiceSearch: [.ukrainian: "Голосовий пошук", .english: "Voice search", .polish: "Wyszukiwanie głosowe"],
        .sayWord: [.ukrainian: "Скажіть слово", .english: "Say a word", .polish: "Powiedz słowo"],
        .emptyDictionary: [.ukrainian: "Ваш словник порожній", .english: "Your dictionary is empty", .polish: "Twój słownik jest pusty"],
        .addWordsInApp: [.ukrainian: "Додайте слова в додатку", .english: "Add words in the app", .polish: "Dodaj słowa w aplikacji"]
    ]
}

// MARK: - Theme Environment Key
struct WidgetThemeKey: EnvironmentKey {
    static let defaultValue = WidgetTheme()
}

extension EnvironmentValues {
    var widgetTheme: WidgetTheme {
        get { self[WidgetThemeKey.self] }
        set { self[WidgetThemeKey.self] = newValue }
    }
}

// MARK: - Theme Manager
struct WidgetTheme {
    private let suiteName = "group.Wordy"
    
    var isDarkMode: Bool {
        UserDefaults(suiteName: suiteName)?.bool(forKey: "isDarkMode") ?? false
    }
    
    var backgroundColor: Color {
        isDarkMode ? Color(hex: "#1C1C1E") : Color.white
    }
    
    var cardBackground: Color {
        isDarkMode ? Color(hex: "#2C2C2E") : Color.white
    }
    
    var textPrimary: Color {
        isDarkMode ? Color.white : Color.black
    }
    
    var textSecondary: Color {
        isDarkMode ? Color(hex: "#8E8E93") : Color(hex: "#7F8C8D")
    }
    
    var accentColor: Color {
        Color(hex: "#4ECDC4")
    }
    
    var dividerColor: Color {
        isDarkMode ? Color(hex: "#3A3A3C") : Color(hex: "#E0E0E0")
    }
    
    var buttonBackground: Color {
        isDarkMode ? Color(hex: "#2C2C2E") : Color.gray.opacity(0.1)
    }
}

// MARK: - Main Widget View
struct WidgetView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    private let theme = WidgetTheme()
    
    var body: some View {
        ZStack {
            // Фон залежить від теми
            theme.backgroundColor
                .ignoresSafeArea()
            
            content
        }
        .environment(\.widgetTheme, theme)
    }
    
    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry, theme: theme)
        case .systemMedium:
            MediumWidgetView(entry: entry, theme: theme)
        case .systemLarge:
            LargeWidgetView(entry: entry, theme: theme)
        default:
            SmallWidgetView(entry: entry, theme: theme)
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let entry: WordEntry
    let theme: WidgetTheme
    private let loc = WidgetLocalization.self
    
    var body: some View {
        VStack(spacing: 8) {
            if let word = entry.word {
                VStack(spacing: 4) {
                    Text(word.original)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                    
                    Text(word.translation)
                        .font(.system(size: 16))
                        .foregroundColor(theme.accentColor)
                        .lineLimit(1)
                    
                    if let transcription = word.transcription {
                        Text(transcription)
                            .font(.system(size: 12))
                            .foregroundColor(theme.textSecondary)
                    }
                }
                .padding(.horizontal, 8)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 30))
                        .foregroundColor(theme.accentColor)
                    
                    Text(loc.string(.addWords))
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Link(destination: URL(string: "wordy://camera")!) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.8))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
                
                Link(destination: URL(string: "wordy://voice")!) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#FFD93D"))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "mic.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(12)
        .background(theme.backgroundColor)
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: WordEntry
    let theme: WidgetTheme
    private let loc = WidgetLocalization.self
    
    var body: some View {
        HStack(spacing: 16) {
            if let word = entry.word {
                VStack(alignment: .leading, spacing: 6) {
                    Text(loc.string(.wordOfDay))
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                        .textCase(.uppercase)
                    
                    Text(word.original)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                    
                    Text(word.translation)
                        .font(.system(size: 18))
                        .foregroundColor(theme.accentColor)
                    
                    if let transcription = word.transcription {
                        Text(transcription)
                            .font(.system(size: 14))
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    if let example = word.example {
                        Text(example)
                            .font(.system(size: 12))
                            .foregroundColor(theme.textSecondary)
                            .italic()
                            .lineLimit(2)
                    }
                }
            } else {
                EmptyStateView(theme: theme)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                ActionButton(
                    icon: "camera.fill",
                    title: loc.string(.scan),
                    color: .blue,
                    url: "wordy://camera",
                    theme: theme
                )
                
                ActionButton(
                    icon: "mic.fill",
                    title: loc.string(.voice),
                    color: Color(hex: "#FFD93D"),
                    url: "wordy://voice",
                    theme: theme
                )
            }
        }
        .padding(16)
        .background(theme.backgroundColor)
    }
}

// MARK: - Large Widget
struct LargeWidgetView: View {
    let entry: WordEntry
    let theme: WidgetTheme
    private let loc = WidgetLocalization.self
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Wordy")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.accentColor)
                
                Spacer()
                
                Text(loc.string(.wordOfDay))
                    .font(.system(size: 14))
                    .foregroundColor(theme.textSecondary)
            }
            
            if let word = entry.word {
                VStack(spacing: 12) {
                    Text(word.original)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                    
                    if let transcription = word.transcription {
                        Text(transcription)
                            .font(.system(size: 18))
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Divider()
                        .background(theme.dividerColor)
                    
                    Text(word.translation)
                        .font(.system(size: 28))
                        .foregroundColor(theme.accentColor)
                    
                    if let example = word.example {
                        Text(example)
                            .font(.system(size: 16))
                            .foregroundColor(theme.textSecondary)
                            .italic()
                            .multilineTextAlignment(.center)
                    }
                }
            } else {
                EmptyStateView(theme: theme)
            }
            
            Spacer()
            
            HStack(spacing: 20) {
                LargeActionButton(
                    icon: "camera.fill",
                    title: loc.string(.scanText),
                    subtitle: loc.string(.scan),
                    color: .blue,
                    url: "wordy://camera",
                    theme: theme
                )
                
                LargeActionButton(
                    icon: "mic.fill",
                    title: loc.string(.voiceSearch),
                    subtitle: loc.string(.sayWord),
                    color: Color(hex: "#FFD93D"),
                    url: "wordy://voice",
                    theme: theme
                )
            }
        }
        .padding(20)
        .background(theme.backgroundColor)
    }
}

// MARK: - Supporting Views
struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let url: String
    let theme: WidgetTheme
    
    var body: some View {
        Link(destination: URL(string: url)!) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(theme.textPrimary)
            }
        }
    }
}

struct LargeActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let url: String
    let theme: WidgetTheme
    
    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
            }
            .padding(12)
            .background(theme.buttonBackground)
            .cornerRadius(12)
        }
    }
}

struct EmptyStateView: View {
    let theme: WidgetTheme
    private let loc = WidgetLocalization.self
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "book.closed")
                .font(.system(size: 40))
                .foregroundColor(theme.accentColor)
            
            Text(loc.string(.emptyDictionary))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.textPrimary)
            
            Text(loc.string(.addWordsInApp))
                .font(.system(size: 12))
                .foregroundColor(theme.textSecondary)
        }
    }
}
