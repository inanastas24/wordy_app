//
//  WidgetView.swift
//  WordyWidgetExtension
//

import WidgetKit
import SwiftUI

// MARK: - Color Extension (додайте це!)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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

struct WidgetView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let entry: WordEntry
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color.white)
            
            VStack(spacing: 8) {
                if let word = entry.word {
                    VStack(spacing: 4) {
                        Text(word.original)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.black)
                            .lineLimit(1)
                        
                        Text(word.translation)
                            .font(.system(size: 16))
                            .foregroundColor(Color.blue)
                            .lineLimit(1)
                        
                        if let transcription = word.transcription {
                            Text(transcription)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 8)
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                        
                        Text("Додайте слова")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Link(destination: URL(string: "wordy://camera")!) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.7))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Link(destination: URL(string: "wordy://voice")!) {
                        ZStack {
                            Circle()
                                .fill(Color.pink.opacity(0.7))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "mic.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(12)
        }
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: WordEntry
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color.white)
            
            HStack(spacing: 16) {
                if let word = entry.word {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Слово дня")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                        
                        Text(word.original)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                        
                        Text(word.translation)
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                        
                        if let transcription = word.transcription {
                            Text(transcription)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        if let example = word.example {
                            Text(example)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .italic()
                                .lineLimit(2)
                        }
                    }
                } else {
                    EmptyStateView()
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    ActionButton(
                        icon: "camera.fill",
                        title: "Сканувати",
                        color: .blue,
                        url: "wordy://camera"
                    )
                    
                    ActionButton(
                        icon: "mic.fill",
                        title: "Голосом",
                        color: .pink,
                        url: "wordy://voice"
                    )
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Large Widget
struct LargeWidgetView: View {
    let entry: WordEntry
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color.white)
            
            VStack(spacing: 20) {
                HStack {
                    Text("Wordy")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("Слово дня")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                if let word = entry.word {
                    VStack(spacing: 12) {
                        Text(word.original)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.black)
                        
                        if let transcription = word.transcription {
                            Text(transcription)
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        }
                        
                        Divider()
                        
                        Text(word.translation)
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                        
                        if let example = word.example {
                            Text(example)
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .italic()
                                .multilineTextAlignment(.center)
                        }
                    }
                } else {
                    EmptyStateView()
                }
                
                Spacer()
                
                HStack(spacing: 20) {
                    LargeActionButton(
                        icon: "camera.fill",
                        title: "Сканувати текст",
                        subtitle: "Наведіть камеру",
                        color: .blue,
                        url: "wordy://camera"
                    )
                    
                    LargeActionButton(
                        icon: "mic.fill",
                        title: "Голосовий пошук",
                        subtitle: "Скажіть слово",
                        color: .pink,
                        url: "wordy://voice"
                    )
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Supporting Views
struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let url: String
    
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
                    .foregroundColor(.black)
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
                        .foregroundColor(.black)
                    
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding(12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "book.closed")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Ваш словник порожній")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black)
            
            Text("Додайте слова в додатку")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
    }
}
