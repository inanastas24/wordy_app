//
//  SplashScreenView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 10.02.2026.
//

import SwiftUI

struct SplashScreenView: View {
    @Binding var isActive: Bool
    @EnvironmentObject var localizationManager: LocalizationManager
    
    // Стан бульбашок
    @State private var bubble1Offset: CGFloat = 0
    @State private var bubble2Offset: CGFloat = 0
    @State private var bubble3Offset: CGFloat = 0
    
    @State private var bubble1Scale: CGFloat = 1
    @State private var bubble2Scale: CGFloat = 1
    @State private var bubble3Scale: CGFloat = 1
    
    @State private var bubble1Opacity: Double = 1
    @State private var bubble2Opacity: Double = 1
    @State private var bubble3Opacity: Double = 1
    
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    
    @State private var textOpacity: Double = 0
    
    // Параметри бульбашок
    private let bubbleSizes: [CGFloat] = [120, 100, 80] // Різні розміри
    private let bubbleColors: [String] = ["#4ECDC4", "#95E1D3", "#A8D8EA"] // Кольори з меню
    
    var body: some View {
        ZStack {
            // Фон
            backgroundView
            
            // Бульбашки на задньому плані
            bubblesLayer
            
            // Контент (лого + текст)
            contentLayer
        }
        .onAppear {
            startAnimation()
        }
    }
    
    // MARK: - Background
    private var backgroundView: some View {
        Group {
            if localizationManager.isDarkMode {
                Color(hex: "#1C1C1E")
                    .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [Color(hex: "#FFFDF5"), Color(hex: "#E8F6F3")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
        }
    }
    
    // MARK: - Bubbles Layer
    private var bubblesLayer: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let width = geometry.size.width
            
            ZStack {
                // Бульбашка 1 (найбільша, ліва)
                BubbleView(
                    size: bubbleSizes[0],
                    color: bubbleColors[0],
                    offset: bubble1Offset,
                    scale: bubble1Scale,
                    opacity: bubble1Opacity
                )
                .position(x: width * 0.25, y: height + bubbleSizes[0]/2)
                
                // Бульбашка 2 (середня, центр)
                BubbleView(
                    size: bubbleSizes[1],
                    color: bubbleColors[1],
                    offset: bubble2Offset,
                    scale: bubble2Scale,
                    opacity: bubble2Opacity
                )
                .position(x: width * 0.5, y: height + bubbleSizes[1]/2)
                
                // Бульбашка 3 (менша, права)
                BubbleView(
                    size: bubbleSizes[2],
                    color: bubbleColors[2],
                    offset: bubble3Offset,
                    scale: bubble3Scale,
                    opacity: bubble3Opacity
                )
                .position(x: width * 0.75, y: height + bubbleSizes[2]/2)
            }
        }
    }
    
    // MARK: - Content Layer
    private var contentLayer: some View {
        VStack(spacing: 20) {
            // Лого
            ZStack {
                // Фонова бульбашка для лого
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#4ECDC4"), Color(hex: "#44A08D")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .shadow(color: Color(hex: "#4ECDC4").opacity(0.4), radius: 20, x: 0, y: 10)
                
                // Іконка/текст
                VStack(spacing: 0) {
                    Text("W")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Image(systemName: "textformat.abc")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
            
            // Назва додатку
            Text("Wordy")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                .opacity(textOpacity)
            
            // Підзаголовок
            Text(localizationManager.string(.learnWordsEasily))
                .font(.system(size: 16))
                .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                .opacity(textOpacity)
        }
    }
    
    // MARK: - Animation
    private func startAnimation() {
        let screenHeight = UIScreen.main.bounds.height
        
        // Анімація лого (з'являється одразу)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            logoScale = 1
            logoOpacity = 1
        }
        
        // Текст з'являється після лого
        withAnimation(.easeInOut(duration: 0.5).delay(0.4)) {
            textOpacity = 1
        }
        
        // Бульбашка 1 (найбільша) - швидше піднімається
        withAnimation(.easeOut(duration: 2.0).delay(0.3)) {
            bubble1Offset = -screenHeight * 0.9
        }
        
        // Бульбашка 2 (середня) - середня швидкість
        withAnimation(.easeOut(duration: 2.3).delay(0.5)) {
            bubble2Offset = -screenHeight * 0.85
        }
        
        // Бульбашка 3 (менша) - повільніше
        withAnimation(.easeOut(duration: 2.6).delay(0.7)) {
            bubble3Offset = -screenHeight * 0.8
        }
        
        // Лопання бульбашок з різним таймінгом
        // Бульбашка 1 лопається на 70% шляху
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            popBubble(
                scale: $bubble1Scale,
                opacity: $bubble1Opacity,
                offset: $bubble1Offset,
                finalOffset: -screenHeight * 0.7
            )
        }
        
        // Бульбашка 2 лопається на 75% шляху
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            popBubble(
                scale: $bubble2Scale,
                opacity: $bubble2Opacity,
                offset: $bubble2Offset,
                finalOffset: -screenHeight * 0.75
            )
        }
        
        // Бульбашка 3 лопається на 80% шляху
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
            popBubble(
                scale: $bubble3Scale,
                opacity: $bubble3Opacity,
                offset: $bubble3Offset,
                finalOffset: -screenHeight * 0.8
            )
        }
        
        // Перехід на головний екран після анімації
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                isActive = false
            }
        }
    }
    
    private func popBubble(
        scale: Binding<CGFloat>,
        opacity: Binding<Double>,
        offset: Binding<CGFloat>,
        finalOffset: CGFloat
    ) {
        // Зупиняємо на фінальній позиції
        withAnimation(.easeOut(duration: 0.1)) {
            offset.wrappedValue = finalOffset
        }
        
        // Ефект лопання - збільшення і зникнення
        withAnimation(.easeOut(duration: 0.15)) {
            scale.wrappedValue = 1.3
        }
        
        withAnimation(.easeOut(duration: 0.1).delay(0.1)) {
            scale.wrappedValue = 0
            opacity.wrappedValue = 0
        }
    }
}

// MARK: - Bubble View
struct BubbleView: View {
    let size: CGFloat
    let color: String
    let offset: CGFloat
    let scale: CGFloat
    let opacity: Double
    
    var body: some View {
        ZStack {
            // Основне тіло бульбашки
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(hex: color).opacity(0.8),
                            Color(hex: color).opacity(0.4)
                        ]),
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    // Блік (блиск) на бульбашці
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.6),
                                    .white.opacity(0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size * 0.3, height: size * 0.2)
                        .offset(x: -size * 0.15, y: -size * 0.2)
                )
                .overlay(
                    // Другий блік
                    Circle()
                        .fill(.white.opacity(0.3))
                        .frame(width: size * 0.1, height: size * 0.1)
                        .offset(x: size * 0.2, y: size * 0.1)
                )
            
            // Обводка бульбашки
            Circle()
                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                .frame(width: size, height: size)
        }
        .offset(y: offset)
        .scaleEffect(scale)
        .opacity(opacity)
        .shadow(color: Color(hex: color).opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Preview
struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView(isActive: .constant(true))
            .environmentObject(LocalizationManager())
    }
}
