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
        Color(hex: "#F6F9F7")
    }
    
    var cardBackground: Color {
        Color.white.opacity(0.92)
    }
    
    var textPrimary: Color {
        Color(hex: "#16323F")
    }
    
    var textSecondary: Color {
        Color(hex: "#6F7E86")
    }
    
    var accentColor: Color {
        Color(hex: "#4ECDC4")
    }
    
    var dividerColor: Color {
        Color(hex: "#D9E6E2")
    }
    
    var buttonBackground: Color {
        Color.white.opacity(0.84)
    }

    var gradientTop: Color {
        Color(hex: "#F9FFFD")
    }

    var gradientBottom: Color {
        Color(hex: "#EAF5F1")
    }

    var accentSoft: Color {
        Color(hex: "#DDF7F4")
    }

    var warmAccent: Color {
        Color(hex: "#FFD76A")
    }

    var borderColor: Color {
        Color.white.opacity(0.7)
    }

    var shadowColor: Color {
        Color(hex: "#2AAFA7").opacity(0.12)
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
                LinearGradient(
                    colors: [theme.gradientTop, theme.gradientBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let word = entry.word {
                Text(word.original)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.76)

                Text(word.translation)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.accentColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.76)

                if let transcription = word.transcription, !transcription.isEmpty {
                    Text(transcription)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                }

                Spacer(minLength: 0)
            } else {
                EmptyStateView(theme: theme, isCompact: true)
                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                Spacer()

                PremiumActionCapsule(
                    icon: "camera.viewfinder",
                    color: Color(hex: "#7EC9E7"),
                    url: "wordy://camera"
                )

                PremiumActionCapsule(
                    icon: "mic.fill",
                    color: theme.warmAccent,
                    url: "wordy://voice"
                )

                Spacer()
            }
        }
        .padding(12)
        .background(widgetPanelBackground(theme: theme, cornerRadius: 24))
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: WordEntry
    let theme: WidgetTheme
    private let loc = WidgetLocalization.self
    
    var body: some View {
        HStack(spacing: 10) {
            if let word = entry.word {
                VStack(alignment: .leading, spacing: 10) {
                    premiumHeader(compact: false)

                    Spacer(minLength: 0)

                    Text(word.original)
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.68)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(word.translation)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(theme.accentColor)
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)

                        if let transcription = word.transcription, !transcription.isEmpty {
                            Text(word.transcription ?? "")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(theme.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(theme.accentSoft)
                                )
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }

                        if let example = word.example, !example.isEmpty {
                            Text(example)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(theme.textSecondary)
                                .italic()
                                .lineLimit(2)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.vertical, 2)
            } else {
                EmptyStateView(theme: theme, isCompact: false)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.vertical, 2)
            }

            VStack(spacing: 10) {
                PremiumSideAction(
                    icon: "camera.viewfinder",
                    title: loc.string(.scan),
                    color: Color(hex: "#7EC9E7"),
                    url: "wordy://camera",
                    theme: theme
                )

                PremiumSideAction(
                    icon: "mic.fill",
                    title: loc.string(.voice),
                    color: theme.warmAccent,
                    url: "wordy://voice",
                    theme: theme
                )
            }
            .frame(width: 72)
        }
        .padding(10)
        .background(widgetPanelBackground(theme: theme, cornerRadius: 26))
    }
}

// MARK: - Large Widget
struct LargeWidgetView: View {
    let entry: WordEntry
    let theme: WidgetTheme
    private let loc = WidgetLocalization.self
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(theme.accentColor)

                    Text("Wordy")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                }
                
                Spacer()
                
                Text(loc.string(.wordOfDay))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            if let word = entry.word {
                LargeWordCard(word: word, theme: theme, title: nil)
            } else {
                EmptyStateView(theme: theme, isCompact: false)
                    .frame(maxHeight: .infinity)
            }
            
            Spacer(minLength: 4)
            
            HStack(spacing: 10) {
                CompactActionButton(
                    icon: "camera.viewfinder",
                    title: loc.string(.scan),
                    color: Color(hex: "#A8D8EA"),
                    url: "wordy://camera"
                )
                
                CompactActionButton(
                    icon: "mic.fill",
                    title: loc.string(.voice),
                    color: Color(hex: "#FFD93D"),
                    url: "wordy://voice"
                )
            }
        }
        .padding(14)
    }
}
// MARK: - Compact Action Button (для Large widget)
struct CompactActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let url: String
    
    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(color)
                    .clipShape(Circle())
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#2C3E50"))
                
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.76))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
            )
            .cornerRadius(12)
        }
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
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(theme.buttonBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(theme.borderColor, lineWidth: 1)
            )
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
    let isCompact: Bool
    private let loc = WidgetLocalization.self
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.accentColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "book.closed")
                    .font(.system(size: isCompact ? 24 : 30))
                    .foregroundColor(theme.accentColor)
            }
            
            Text(loc.string(.emptyDictionary))
                .font(.system(size: isCompact ? 14 : 16, weight: .semibold))
                .foregroundColor(theme.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(loc.string(.addWordsInApp))
                .font(.system(size: isCompact ? 11 : 13))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isCompact ? 10 : 20)
        .padding(.horizontal, isCompact ? 6 : 0)
    }
}

private struct CompactWordCard: View {
    let word: WidgetWidgetWordModel
    let theme: WidgetTheme
    let alignment: HorizontalAlignment

    var body: some View {
        VStack(alignment: alignment, spacing: 6) {
            Text(word.original)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            Text(word.translation)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(theme.accentColor)
                .lineLimit(2)

            if let transcription = word.transcription, !transcription.isEmpty {
                Text(transcription)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(theme.borderColor, lineWidth: 1)
        )
        .shadow(color: theme.shadowColor, radius: 16, x: 0, y: 10)
    }
}

private struct LargeWordCard: View {
    let word: WidgetWidgetWordModel
    let theme: WidgetTheme
    let title: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.7)
            }

            Text(word.original)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            HStack(alignment: .center, spacing: 10) {
                if let transcription = word.transcription, !transcription.isEmpty {
                    Text(transcription)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(theme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(theme.accentSoft)
                        )
                }

                Spacer()
            }

            Divider()
                .background(theme.dividerColor)

            Text(word.translation)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(theme.accentColor)
                .lineLimit(2)

            if let example = word.example, !example.isEmpty {
                Text(example)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .italic()
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(theme.borderColor, lineWidth: 1)
        )
        .shadow(color: theme.shadowColor, radius: 18, x: 0, y: 10)
    }
}

private struct PillActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let url: String
    let theme: WidgetTheme

    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(color)
                    .clipShape(Circle())

                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(theme.buttonBackground)
            )
            .overlay(
                Capsule()
                    .stroke(theme.borderColor, lineWidth: 1)
            )
        }
    }
}

private struct PremiumActionCapsule: View {
    let icon: String
    let color: Color
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color)
                )
        }
    }
}

private struct PremiumSideAction: View {
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
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }

                Text(title)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(theme.borderColor, lineWidth: 1)
            )
            .shadow(color: theme.shadowColor.opacity(0.7), radius: 8, x: 0, y: 5)
        }
    }
}

private extension View {
    func widgetPanelBackground(theme: WidgetTheme, cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.82))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.58), lineWidth: 0.8)
            )
            .shadow(color: theme.shadowColor.opacity(0.75), radius: 14, x: 0, y: 8)
    }

    func premiumHeader(compact: Bool) -> some View {
        HStack {
            Text("Wordy")
                .font(.system(size: compact ? 11 : 11, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#4ECDC4"))
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Spacer()

            Text(WidgetLocalization.string(.wordOfDay))
                .font(.system(size: compact ? 7 : 8, weight: .bold))
                .foregroundColor(Color(hex: "#6F7E86"))
                .textCase(.uppercase)
                .tracking(compact ? 0.45 : 0.55)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}
