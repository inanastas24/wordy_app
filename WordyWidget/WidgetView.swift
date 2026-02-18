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
        let saved = UserDefaults(suiteName: "group.com.inzercreator.wordyapp")?.string(forKey: "appLanguage") ?? "en"
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

// MARK: - Theme (завжди світла)
struct WidgetTheme {
    var isDarkMode: Bool = false
    
    var backgroundColor: Color {
        Color(hex: "#FFFDF5")
    }
    
    var cardBackground: Color {
        Color.white
    }
    
    var textPrimary: Color {
        Color(hex: "#2C3E50")
    }
    
    var textSecondary: Color {
        Color(hex: "#7F8C8D")
    }
    
    var accentColor: Color {
        Color(hex: "#4ECDC4")
    }
    
    var dividerColor: Color {
        Color(hex: "#E0E0E0")
    }
    
    var buttonBackground: Color {
        Color(hex: "#F8F9FA")
    }
}

// MARK: - Main Widget View
struct WidgetView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    private let theme = WidgetTheme()
    private let loc = WidgetLocalization.self
    
    var body: some View {
        content
            .containerBackground(for: .widget) {
                // Фон для віджета
                theme.backgroundColor
            }
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
        VStack(spacing: 12) {
            if let word = entry.word {
                VStack(spacing: 6) {
                    Text(word.original)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                    
                    Text(word.translation)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.accentColor)
                        .lineLimit(1)
                    
                    if let transcription = word.transcription {
                        Text(transcription)
                            .font(.system(size: 11))
                            .foregroundColor(theme.textSecondary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
            } else {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(theme.accentColor.opacity(0.15))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "book.closed")
                            .font(.system(size: 24))
                            .foregroundColor(theme.accentColor)
                    }
                    
                    Text(loc.string(.addWords))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Link(destination: URL(string: "wordy://camera")!) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#A8D8EA"))
                            .frame(width: 40, height: 40)
                            .shadow(color: Color(hex: "#A8D8EA").opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                }
                
                Link(destination: URL(string: "wordy://voice")!) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#FFD93D"))
                            .frame(width: 40, height: 40)
                            .shadow(color: Color(hex: "#FFD93D").opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        Image(systemName: "mic.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.bottom, 12)
        }
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
                    HStack {
                        Text(loc.string(.wordOfDay))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(theme.textSecondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        Spacer()
                    }
                    
                    Text(word.original)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                    
                    Text(word.translation)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(theme.accentColor)
                    
                    if let transcription = word.transcription {
                        Text(transcription)
                            .font(.system(size: 13))
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
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                ActionButton(
                    icon: "camera.fill",
                    title: loc.string(.scan),
                    color: Color(hex: "#A8D8EA"),
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
    }
}

// MARK: - Large Widget
struct LargeWidgetView: View {
    let entry: WordEntry
    let theme: WidgetTheme
    private let loc = WidgetLocalization.self
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 6) {
                    Text("🫧")
                        .font(.system(size: 20))
                    
                    Text("Wordy")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(theme.accentColor)
                }
                
                Spacer()
                
                Text(loc.string(.wordOfDay))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            if let word = entry.word {
                VStack(spacing: 12) {
                    VStack(spacing: 10) {
                        Text(word.original)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(theme.textPrimary)
                        
                        if let transcription = word.transcription {
                            Text(transcription)
                                .font(.system(size: 16))
                                .foregroundColor(theme.textSecondary)
                        }
                        
                        Divider()
                            .background(theme.dividerColor)
                            .padding(.horizontal, 20)
                        
                        Text(word.translation)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(theme.accentColor)
                        
                        if let example = word.example {
                            Text(example)
                                .font(.system(size: 14))
                                .foregroundColor(theme.textSecondary)
                                .italic()
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                    .padding(16)
                    .background(theme.cardBackground)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                }
            } else {
                EmptyStateView(theme: theme)
                    .frame(maxHeight: .infinity)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                LargeActionButton(
                    icon: "camera.fill",
                    title: loc.string(.scanText),
                    subtitle: loc.string(.scan),
                    color: Color(hex: "#A8D8EA"),
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
        .padding(16)
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
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 48, height: 48)
                        .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
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
                        .frame(width: 44, height: 44)
                        .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
            }
            .padding(12)
            .background(theme.buttonBackground)
            .cornerRadius(14)
        }
    }
}

struct EmptyStateView: View {
    let theme: WidgetTheme
    private let loc = WidgetLocalization.self
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.accentColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "book.closed")
                    .font(.system(size: 30))
                    .foregroundColor(theme.accentColor)
            }
            
            Text(loc.string(.emptyDictionary))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(loc.string(.addWordsInApp))
                .font(.system(size: 13))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}
