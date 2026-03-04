//
//  CoachMarkView.swift
//  Wordy
//

import SwiftUI

struct CoachMarkView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var onboardingManager: OnboardingManager

    let step: OnboardingStep
    let targetFrame: CGRect
    let onNext: () -> Void

    @State private var pulseScale: CGFloat = 1.0

    private let overlayOpacity: Double = 0.6
    private let cutoutPadding: CGFloat = 8
    private let tooltipMaxWidth: CGFloat = 280
    private let glowColor: Color = Color(hex: "#4ECDC4")

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Шар 1: Затемнення з вирізом (прозорим)
                OverlayWithCutout(
                    targetFrame: targetFrame,
                    overlayOpacity: overlayOpacity,
                    cornerRadius: 12,
                    cutoutPadding: cutoutPadding
                )

                // Шар 2: Glow навколо елемента (ПІСЛЯ затемнення, щоб був видимий)
                GlowAroundTarget(
                    targetFrame: targetFrame,
                    padding: cutoutPadding,
                    cornerRadius: 12,
                    glowColor: glowColor
                )

                // Шар 3: Тултіп
                BlockerView(targetFrame: targetFrame)
                tooltipView(in: geometry)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.08
            }
        }
    }

    struct BlockerView: View {
        let targetFrame: CGRect
        var body: some View {
            Color.clear
                .frame(width: targetFrame.width + 24, height: targetFrame.height + 24)
                .position(x: targetFrame.midX, y: targetFrame.midY)
                .contentShape(Rectangle())
        }
    }

    // MARK: - Tooltip Positioning

    private func tooltipView(in geometry: GeometryProxy) -> some View {
        let position = calculateTooltipPosition(in: geometry)

        return VStack(spacing: 12) {
            // Іконка
            ZStack {
                Circle()
                    .fill(glowColor.opacity(0.25))
                    .frame(width: 48, height: 48)
                    .scaleEffect(pulseScale)

                Image(systemName: stepIcon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(glowColor)
            }

            // Заголовок
            Text(stepTitle)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Опис
            Text(stepDescription)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)

            // Кнопка Далі
            Button(action: onNext) {
                HStack(spacing: 6) {
                    Text(nextButtonText)
                        .font(.system(size: 14, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11))
                }
                .foregroundColor(glowColor)
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 4)

            // Пропустити
            Button {
                onboardingManager.skipOnboarding()
            } label: {
                Text(skipButtonText)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.vertical, 4)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .frame(maxWidth: tooltipMaxWidth)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.5))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 10)
        .position(x: position.x, y: position.y)
    }

    private func calculateTooltipPosition(in geometry: GeometryProxy) -> CGPoint {
        let screenWidth = geometry.size.width
        let screenHeight = geometry.size.height

        // Реальна приблизна висота тултіпа
        let tooltipHeight: CGFloat = 200
        let tooltipWidth: CGFloat = tooltipMaxWidth

        // Відступ від елемента до тултіпа (від краю елемента до краю тултіпа)
        let edgeSpacing: CGFloat = 30

        // Безпечні зони
        let safeAreaTop: CGFloat = 60
        let safeAreaBottom: CGFloat = screenHeight - 80

        // Центр елемента
        let targetCenterY = targetFrame.midY

        let y: CGFloat

        // Якщо елемент в нижній половині екрану (нижче 60%) - тултіп ЗВЕРХУ від елемента
        if targetCenterY > screenHeight * 0.60 {
            // Центр тултіпа = верхній край елемента - відступ - половина висоти тултіпа
            let desiredY = targetFrame.minY - edgeSpacing - tooltipHeight/2
            // Переконуємось що не виходимо за верхній край
            y = max(safeAreaTop + tooltipHeight/2, desiredY)
        }
        // Якщо елемент в верхній половині (вище 40%) - тултіп ЗНИЗУ
        else if targetCenterY < screenHeight * 0.40 {
            // Центр тултіпа = нижній край елемента + відступ + половина висоти тултіпа
            let desiredY = targetFrame.maxY + edgeSpacing + tooltipHeight/2
            // Переконуємось що не виходимо за нижній край
            y = min(safeAreaBottom - tooltipHeight/2, desiredY)
        }
        // Посередині - обираємо де більше місця
        else {
            let spaceAbove = targetFrame.minY - safeAreaTop
            let spaceBelow = safeAreaBottom - targetFrame.maxY

            if spaceBelow > spaceAbove {
                // Місця більше знизу
                y = min(safeAreaBottom - tooltipHeight/2, targetFrame.maxY + edgeSpacing + tooltipHeight/2)
            } else {
                // Місця більше зверху
                y = max(safeAreaTop + tooltipHeight/2, targetFrame.minY - edgeSpacing - tooltipHeight/2)
            }
        }

        // X координата - центруємо відносно елемента
        let x = max(tooltipWidth/2 + 16, min(screenWidth - tooltipWidth/2 - 16, targetFrame.midX))

        return CGPoint(x: x, y: y)
    }

    // MARK: - Localization

    private var stepIcon: String {
        switch step {
        case .languagePair: return "globe"
        case .scanButton: return "camera.viewfinder"
        case .voiceButton: return "mic.fill"
        case .addToDictionary: return "plus.circle.fill"
        case .flashcards: return "rectangle.stack.fill"
        }
    }

    private var stepTitle: String {
        switch (step, localizationManager.currentLanguage) {
        case (.languagePair, .ukrainian): return "Пара мов"
        case (.languagePair, .polish): return "Para języków"
        case (.languagePair, .english): return "Language Pair"
        case (.scanButton, .ukrainian): return "Сканування"
        case (.scanButton, .polish): return "Skanowanie"
        case (.scanButton, .english): return "Scan Text"
        case (.voiceButton, .ukrainian): return "Голосовий ввід"
        case (.voiceButton, .polish): return "Wyszukiwanie głosowe"
        case (.voiceButton, .english): return "Voice Search"
        case (.addToDictionary, .ukrainian): return "Збереження"
        case (.addToDictionary, .polish): return "Zapisz słowo"
        case (.addToDictionary, .english): return "Save Word"
        case (.flashcards, .ukrainian): return "Флешкартки"
        case (.flashcards, .polish): return "Fiszki"
        case (.flashcards, .english): return "Flashcards"
        }
    }

    private var stepDescription: String {
        switch (step, localizationManager.currentLanguage) {
        case (.languagePair, .ukrainian): return "Торкніться прапорів, щоб змінити напрямок перекладу"
        case (.languagePair, .polish): return "Dotknij flag, aby zmienić kierunek tłumaczenia"
        case (.languagePair, .english): return "Tap flags to change translation direction"
        case (.scanButton, .ukrainian): return "Скануйте текст з книг, меню або документів"
        case (.scanButton, .polish): return "Skanuj tekst z książek, menu lub dokumentów"
        case (.scanButton, .english): return "Scan text from books, menus, or documents"
        case (.voiceButton, .ukrainian): return "Говоріть слова вголос — додаток розпізнає і перекладе"
        case (.voiceButton, .polish): return "Wymawiaj słowa na głos — aplikacja rozpozna i przetłumaczy"
        case (.voiceButton, .english): return "Speak words aloud — the app will recognize and translate"
        case (.addToDictionary, .ukrainian): return "Зберігайте слова, щоб повторювати їх пізніше"
        case (.addToDictionary, .polish): return "Zapisuj słowa, aby powtarzać je później"
        case (.addToDictionary, .english): return "Save words to review them later"
        case (.flashcards, .ukrainian): return "Вивчайте збережені слова за допомогою флешкарток"
        case (.flashcards, .polish): return "Ucz się zapisanych słów za pomocą fiszek"
        case (.flashcards, .english): return "Learn your saved words with flashcards"
        }
    }

    private var nextButtonText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Далі"
        case .polish: return "Dalej"
        case .english: return "Next"
        }
    }

    private var skipButtonText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Пропустити"
        case .polish: return "Pomiń"
        case .english: return "Skip"
        }
    }
}

// MARK: - Overlay with Cutout (Прозорий виріз)

struct OverlayWithCutout: View {
    let targetFrame: CGRect
    let overlayOpacity: Double
    let cornerRadius: CGFloat
    let cutoutPadding: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Затемнення на весь екран
                Color.black.opacity(overlayOpacity)

                // Виріз (cutout) - прозорий
                CutoutShape(
                    frame: targetFrame,
                    cornerRadius: cornerRadius,
                    padding: cutoutPadding
                )
                .blendMode(.destinationOut)
            }
            .compositingGroup()
        }
        .ignoresSafeArea()
    }
}

struct CutoutShape: Shape {
    let frame: CGRect
    let cornerRadius: CGFloat
    let padding: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Додаємо весь прямокутник екрану
        path.addRect(rect)

        // Вирізаємо область елемента
        let cutoutRect = frame.insetBy(dx: -padding, dy: -padding)

        // Використовуємо even-odd fill rule для створення отвору
        path.addPath(
            Path(roundedRect: cutoutRect, cornerRadius: cornerRadius)
        )

        return path
    }
}

// MARK: - Glow Around Target

struct GlowAroundTarget: View {
    let targetFrame: CGRect
    let padding: CGFloat
    let cornerRadius: CGFloat
    let glowColor: Color

    @State private var isPulsing = false

    var body: some View {
        let rect = targetFrame.insetBy(dx: -padding, dy: -padding)

        ZStack {
            // Зовнішнє світіння
            RoundedRectangle(cornerRadius: cornerRadius + 6)
                .stroke(glowColor.opacity(0.3), lineWidth: 3)
                .frame(width: rect.width + 12, height: rect.height + 12)
                .position(x: rect.midX, y: rect.midY)
                .blur(radius: 8)
                .scaleEffect(isPulsing ? 1.05 : 1.0)

            // Середнє світіння
            RoundedRectangle(cornerRadius: cornerRadius + 3)
                .stroke(glowColor.opacity(0.6), lineWidth: 2)
                .frame(width: rect.width + 6, height: rect.height + 6)
                .position(x: rect.midX, y: rect.midY)
                .shadow(color: glowColor.opacity(0.8), radius: 15, x: 0, y: 0)

            // Основна обводка
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(glowColor, lineWidth: 2.5)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
                .shadow(color: glowColor, radius: 10, x: 0, y: 0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String, alpha: Double? = nil) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch cleaned.count {
        case 3:
            let r4 = (int >> 8) & 0xF
            let g4 = (int >> 4) & 0xF
            let b4 = int & 0xF
            r = (r4 << 4) | r4
            g = (g4 << 4) | g4
            b = (b4 << 4) | b4
            a = 0xFF
        case 6:
            r = (int >> 16) & 0xFF
            g = (int >> 8) & 0xFF
            b = int & 0xFF
            a = 0xFF
        case 8:
            a = (int >> 24) & 0xFF
            r = (int >> 16) & 0xFF
            g = (int >> 8) & 0xFF
            b = int & 0xFF
        default:
            a = 0xFF; r = 0xFF; g = 0xFF; b = 0xFF
        }
        let finalAlpha = alpha ?? Double(a) / 255.0
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: finalAlpha
        )
    }
}
