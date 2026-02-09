//1
//  FlashcardsView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 26.01.2026.
//

import SwiftUI
import CoreHaptics

struct FlashcardsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @StateObject private var viewModel = DictionaryViewModel.shared
    
    @State private var cards: [SavedWordModel] = []
    @State private var currentIndex = 0
    @State private var offset: CGSize = .zero
    @State private var isFlipped = false
    @State private var rotation: Double = 0
    @State private var sessionStats = SessionStats()
    @State private var showCompletion = false
    @State private var cardScale: CGFloat = 1.0
    @State private var showAnswerButtons = false
    @State private var showConfetti = false
    
    private let cardWidth: CGFloat = 320
    private let cardHeight: CGFloat = 420
    private let maxCardRepeats = 2
    
    var body: some View {
        ZStack {
            Color(hex: localizationManager.isDarkMode ? "#1C1C1E" : "#FFFDF5").ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                ZStack {
                    if cards.isEmpty {
                        emptyStateView
                    } else if showCompletion || currentIndex >= cards.count {
                        completionView
                    } else {
                        cardStackView
                    }
                }
                .frame(maxHeight: .infinity)
                
                if !cards.isEmpty && !showCompletion && currentIndex < cards.count {
                    if showAnswerButtons {
                        srsButtonsView
                    } else {
                        flipButtonView
                    }
                }
            }
            
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
                    .zIndex(100)
            }
        }
        .onAppear {
            loadCards()
        }
        .onChange(of: showCompletion) { _, completed in
            if completed {
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showConfetti = false
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 15) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                }
                
                Spacer()
                
                Text(localizationManager.string(.reviewing))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                
                Spacer()
                
                if !cards.isEmpty && !showCompletion && currentIndex < cards.count {
                    Text("\(currentIndex + 1)/\(cards.count)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#4ECDC4").opacity(0.15))
                        .cornerRadius(12)
                } else {
                    Color.clear.frame(width: 44, height: 32)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            if !cards.isEmpty && !showCompletion && currentIndex < cards.count {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: localizationManager.isDarkMode ? "#3A3A3C" : "#E0E0E0"))
                            .frame(height: 8)
                        
                        let progress = CGFloat(currentIndex) / CGFloat(max(cards.count, 1))
                        let width = geo.size.width * progress
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#4ECDC4"), Color(hex: "#45B7AA")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: width, height: 8)
                            .animation(.spring(), value: currentIndex)
                    }
                }
                .frame(height: 8)
                .padding(.horizontal, 20)
            }
            
            if !cards.isEmpty && !showCompletion && currentIndex < cards.count {
                HStack(spacing: 20) {
                    StatBadge(icon: "star.fill", count: sessionStats.totalReviewed, color: Color(hex: "#4ECDC4"))
                    StatBadge(icon: "checkmark.circle.fill", count: sessionStats.learned, color: Color(hex: "#95E1D3"))
                    StatBadge(icon: "arrow.clockwise", count: sessionStats.againCount, color: Color(hex: "#F38BA8"))
                }
                .padding(.top, 5)
            }
        }
        .padding(.bottom, 20)
    }
    
    private var cardStackView: some View {
        ZStack {
            backgroundCards
            activeCard
        }
    }
    
    private var backgroundCards: some View {
        ForEach(getBackgroundCardIndices(), id: \.self) { index in
            RoundedRectangle(cornerRadius: 30)
                .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
                .frame(width: cardWidth, height: cardHeight)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                .offset(y: CGFloat(index - currentIndex) * 10)
                .scaleEffect(1.0 - CGFloat(index - currentIndex) * 0.05)
                .opacity(1.0 - Double(index - currentIndex) * 0.3)
        }
    }
    
    private func getBackgroundCardIndices() -> [Int] {
        let startIndex = currentIndex + 1
        let endIndex = min(cards.count, currentIndex + 3)
        guard startIndex < endIndex else { return [] }
        return Array(startIndex..<endIndex)
    }
    
    private var activeCard: some View {
        ZStack {
            // Фон "Не знаю" — червоний зліва
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#F38BA8").opacity(0.9))
                .overlay(
                    HStack {
                        Image(systemName: "xmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.leading, 30)
                        Spacer()
                    }
                )
                .opacity(offset.width < -20 ? min(abs(Double(offset.width)) / 100.0, 1.0) : 0.0)
            
            // Фон "Знаю" — зелений справа
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#2ECC71").opacity(0.9))
                .overlay(
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.trailing, 30)
                    }
                )
                .opacity(offset.width > 20 ? min(Double(offset.width) / 100.0, 1.0) : 0.0)
            
            // Основна картка
            FirestoreFlashcard(
                word: cards[currentIndex],
                isFlipped: $isFlipped,
                rotation: $rotation,
                isDarkMode: localizationManager.isDarkMode
            )
            .frame(width: cardWidth, height: cardHeight)
            .offset(offset)
            .rotationEffect(.degrees(Double(offset.width) * 0.05))
            .scaleEffect(cardScale)
            .gesture(dragGesture)
            .onTapGesture {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isFlipped.toggle()
                    rotation += 180
                    showAnswerButtons = true
                }
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { gesture in
                offset = gesture.translation
                let dragProgress = min(abs(gesture.translation.width) / 1000, 0.2)
                cardScale = 1.0 - dragProgress
            }
            .onEnded { gesture in
                let threshold: CGFloat = 100
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if gesture.translation.width > threshold {
                        handleSwipe(quality: 4) // good
                    } else if gesture.translation.width < -threshold {
                        handleSwipe(quality: 0) // completeFailure
                    } else {
                        offset = .zero
                        cardScale = 1.0
                    }
                }
            }
    }
    
    private var flipButtonView: some View {
        VStack(spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isFlipped = true
                    rotation += 180
                    showAnswerButtons = true
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "eye.fill")
                    Text(localizationManager.string(.showAnswer))
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: 320)
                .frame(height: 56)
                .background(Color(hex: "#4ECDC4"))
                .cornerRadius(25)
                .shadow(color: Color(hex: "#4ECDC4").opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            Text(localizationManager.string(.tapOrSwipe))
                .font(.system(size: 14))
                .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
        }
        .padding(.bottom, 30)
    }
    
    private var srsButtonsView: some View {
        VStack(spacing: 12) {
            Text(localizationManager.string(.howWellKnown))
                .font(.system(size: 14))
                .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
            
            HStack(spacing: 8) {
                SRSButton(
                    quality: .completeFailure,
                    color: Color(hex: "#FF6B6B"),
                    icon: "arrow.clockwise",
                    label: localizationManager.string(.again),
                    interval: "< 1 хв"
                ) { handleSwipe(quality: 0) }
                
                SRSButton(
                    quality: .hard,
                    color: Color(hex: "#FFA07A"),
                    icon: "exclamationmark",
                    label: localizationManager.string(.hard),
                    interval: "1 дн"
                ) { handleSwipe(quality: 1) }
                
                SRSButton(
                    quality: .medium,
                    color: Color(hex: "#FFD93D"),
                    icon: "questionmark",
                    label: localizationManager.string(.medium),
                    interval: "2 дн"
                ) { handleSwipe(quality: 2) }
                
                SRSButton(
                    quality: .good,
                    color: Color(hex: "#4ECDC4"),
                    icon: "checkmark",
                    label: localizationManager.string(.good),
                    interval: getIntervalText(for: 4)
                ) { handleSwipe(quality: 4) }
                
                SRSButton(
                    quality: .perfect,
                    color: Color(hex: "#2ECC71"),
                    icon: "star.fill",
                    label: localizationManager.string(.perfect),
                    interval: getIntervalText(for: 5)
                ) { handleSwipe(quality: 5) }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 30)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "party.popper.fill")
                .font(.system(size: 80))
                .foregroundColor(Color(hex: "#4ECDC4"))
            
            Text(localizationManager.string(.allLearned))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
            
            Text(localizationManager.string(.noWordsForReview))
                .font(.system(size: 16))
                .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            VStack(spacing: 12) {
                Button(action: {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        NotificationCenter.default.post(name: .switchToSearchTab, object: nil)
                    }
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text(localizationManager.string(.learnNewWords))
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 14)
                    .background(Color(hex: "#4ECDC4"))
                    .cornerRadius(25)
                }
                
                Button(action: { dismiss() }) {
                    Text(localizationManager.string(.backToDictionary))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                }
            }
            .padding(.top, 10)
        }
    }
    
    private var completionView: some View {
        VStack(spacing: 25) {
            ZStack {
                ForEach(0..<8) { i in
                    Circle()
                        .fill(Color(hex: "#4ECDC4").opacity(0.3))
                        .frame(width: 20, height: 20)
                        .offset(
                            x: cos(Double(i) * .pi / 4) * 60,
                            y: sin(Double(i) * .pi / 4) * 60
                        )
                }
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color(hex: "#FFD700"))
                    .shadow(color: Color(hex: "#FFD700").opacity(0.5), radius: 20, x: 0, y: 0)
            }
            .padding(.bottom, 20)
            
            Text(localizationManager.string(.allLearned))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
            
            VStack(spacing: 12) {
                ResultRow(
                    title: localizationManager.string(.averageQuality), // Використовуємо переклад
                    value: String(format: "%.1f", sessionStats.averageQuality),
                    color: Color(hex: "#4ECDC4"),
                    icon: "star.fill"
                )
                .foregroundColor(localizationManager.isDarkMode ? .white : .primary)
                
                ResultRow(
                    title: localizationManager.string(.learned),
                    value: "\(sessionStats.learned)",
                    color: Color(hex: "#95E1D3"),
                    icon: "checkmark.circle.fill"
                )
                .foregroundColor(localizationManager.isDarkMode ? .white : .primary)
                
                ResultRow(
                    title: localizationManager.string(.again),
                    value: "\(sessionStats.againCount)",
                    color: Color(hex: "#F38BA8"),
                    icon: "arrow.clockwise"
                )
                .foregroundColor(localizationManager.isDarkMode ? .white : .primary)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
            .background(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 12) {
                Button(action: { resetSession() }) {
                    HStack {
                        Image(systemName: "arrow.2.circlepath")
                        Text(localizationManager.currentLanguage == .ukrainian ? "Наступна сесія" : "Next session")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: 280)
                    .frame(height: 54)
                    .background(Color(hex: "#4ECDC4"))
                    .cornerRadius(27)
                }
                
                Button(action: { dismiss() }) {
                    Text(localizationManager.string(.backToDictionary))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                }
            }
            .padding(.top, 10)
        }
        .padding()
    }
    
    private func loadCards() {
        // Отримуємо слова з ViewModel (вже завантажені з Firestore)
        let dueWords = viewModel.wordsDueForReview
        let newWords = viewModel.newWords
        
        var sessionWords: [SavedWordModel] = []
        sessionWords.append(contentsOf: dueWords.prefix(10))
        sessionWords.append(contentsOf: newWords.prefix(20 - sessionWords.count))
        
        cards = sessionWords.shuffled()
        currentIndex = 0
        isFlipped = false
        rotation = 0
        offset = .zero
        cardScale = 1.0
        showCompletion = false
        showAnswerButtons = false
        sessionStats = SessionStats()
        
        if cards.isEmpty {
            showCompletion = true
        }
    }
    
    private func handleSwipe(quality: Int) {
        guard !cards.isEmpty && currentIndex < cards.count else { return }
        
        let word = cards[currentIndex]
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(quality >= 3 ? .success : .error)
        
        let direction: CGFloat = quality >= 3 ? 500 : -500
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            offset = CGSize(width: direction, height: 0)
            cardScale = 0.8
        }
        
        sessionStats.totalReviewed += 1
        sessionStats.qualityDistribution[quality, default: 0] += 1
        
        // Використовуємо ViewModel для оновлення SRS
        viewModel.processReview(for: word, quality: quality)
        
        if quality >= 3 && word.srsRepetition + 1 >= 3 {
            sessionStats.learned += 1
        }
        
        if quality < 3 {
            sessionStats.againCount += 1
            let repeatCount = cards[0..<currentIndex].filter { $0.id == word.id }.count
            if repeatCount < maxCardRepeats {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    cards.append(word)
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.currentIndex += 1
            self.offset = .zero
            self.cardScale = 1.0
            self.isFlipped = false
            self.rotation = 0
            self.showAnswerButtons = false
            
            if self.currentIndex >= self.cards.count {
                withAnimation(.spring()) {
                    self.showCompletion = true
                }
            }
        }
    }
    
    private func getIntervalText(for quality: Int) -> String {
        guard currentIndex < cards.count else { return "" }
        
        let word = cards[currentIndex]
        let ef = word.srsEasinessFactor
        let rep = word.srsRepetition + (quality >= 3 ? 1 : 0)
        
        var interval: Double
        if rep == 1 {
            interval = 1
        } else if rep == 2 {
            interval = 6
        } else {
            interval = (quality == 5 ? 1.3 : 1.0) * ef * (rep == 3 ? 6 : word.srsInterval)
        }
        
        if interval < 1 {
            return "сьогодні"
        } else if interval < 2 {
            return "1 дн"
        } else if interval < 30 {
            return "\(Int(interval)) дн"
        } else {
            return "\(Int(interval/30)) міс"
        }
    }
    
    private func resetSession() {
        loadCards()
    }
}

// MARK: - Firestore Flashcard View
struct FirestoreFlashcard: View {
    let word: SavedWordModel
    @Binding var isFlipped: Bool
    @Binding var rotation: Double
    let isDarkMode: Bool
    
    var body: some View {
        ZStack {
            FirestoreCardFace(
                title: word.original,
                subtitle: (word.transcription?.isEmpty ?? true) || word.transcription == "[]" ? nil : word.transcription,
                hint: LocalizationManager.shared.string(.tapToFlip), // Використовуємо переклад
                backgroundColor: isDarkMode ? Color(hex: "#2C2C2E") : Color.white,
                accentColor: Color(hex: "#4ECDC4"),
                textColor: isDarkMode ? .white : Color(hex: "#2C3E50"),
                isReversed: false
            )
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            
            FirestoreCardFace(
                title: word.translation,
                subtitle: nil,
                hint: word.exampleSentence?.isEmpty ?? true ? nil : word.exampleSentence,
                backgroundColor: Color(hex: "#4ECDC4"),
                accentColor: .white,
                textColor: .white,
                isReversed: true
            )
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
    }
}

struct FirestoreCardFace: View {
    let title: String
    let subtitle: String?
    let hint: String?
    let backgroundColor: Color
    let accentColor: Color
    let textColor: Color
    var isReversed: Bool = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(backgroundColor)
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            
            VStack(spacing: 20) {
                Spacer()
                
                if isReversed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(accentColor.opacity(0.3))
                } else {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundColor(accentColor.opacity(0.3))
                }
                
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .lineLimit(nil) // Дозволяємо перенос довгих слів
                    .fixedSize(horizontal: false, vertical: true)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 20))
                        .foregroundColor(accentColor.opacity(0.8))
                }
                
                Spacer()
                
                if let hint = hint {
                    Text(hint)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isReversed ? .white.opacity(0.8) : (textColor == .white ? .white.opacity(0.8) : Color(hex: "#7F8C8D")))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .lineLimit(3)
                }
                
                Spacer()
            }
            .padding(30)
        }
        .scaleEffect(x: isReversed ? -1.0 : 1.0, y: 1.0)
    }
}
