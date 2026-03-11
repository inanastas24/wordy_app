//
//  GenerationLoadingView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 09.03.2026.
//

import SwiftUI

struct GenerationLoadingView: View {
    let set: WordSet
    let progress: Double
    
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Animated emoji
            Text(set.emoji)
                .font(.system(size: 80))
                .scaleEffect(1 + CGFloat(sin(progress * 10)) * 0.1)
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            VStack(spacing: 12) {
                Text(localizationManager.string(.generatingWords))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                
                Text(localizationManager.string(.aiGenerating))
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            // Progress bar
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: set.gradientColors.map { Color(hex: $0) },
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(progress), height: 12)
                            .animation(.easeOut(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 12)
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#4ECDC4"))
            }
            .padding(.horizontal, 40)
            
            // Fun facts / tips
            TipCarousel()
                .padding(.top, 20)
            
            Spacer()
            
            // Cancel button
            Button {
                // Cancel generation
            } label: {
                Text(localizationManager.string(.cancel))
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 30)
        }
        .padding()
    }
}

// Замініть TipCarousel:
struct TipCarousel: View {
    let tips = [
        "Learning a little every day adds up!",
        "Examples help you remember better",
        "Repetition is the key to mastery",
        "Context makes words stick"
    ]
    
    @State private var currentTip = 0
    
    var body: some View {
        Text(tips[currentTip])
            .font(.system(size: 14))
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .transition(.opacity)
            .id(currentTip)
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                    withAnimation {
                        currentTip = (currentTip + 1) % tips.count
                    }
                }
            }
    }
}
