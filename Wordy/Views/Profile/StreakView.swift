//1
//  StreakView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 27.01.2026.
//

import SwiftUI

struct StreakView: View {
    @State private var currentStreak = 5
    @State private var longestStreak = 12
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                // Поточний streak
                VStack {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    Text("\(currentStreak)")
                        .font(.system(size: 36, weight: .bold))
                    Text("Днів поспіль")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(radius: 5)
                
                // Рекорд
                VStack {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.yellow)
                    Text("\(longestStreak)")
                        .font(.system(size: 36, weight: .bold))
                    Text("Рекорд")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(radius: 5)
            }
            
            // Досягнення (спрощено)
            VStack(alignment: .leading) {
                Text("Досягнення")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        AchievementBadge(icon: "star.fill", title: "Перше слово", isUnlocked: true)
                        AchievementBadge(icon: "book.fill", title: "10 слів", isUnlocked: true)
                        AchievementBadge(icon: "flame.fill", title: "7 днів", isUnlocked: false)
                        AchievementBadge(icon: "crown.fill", title: "100 слів", isUnlocked: false)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct AchievementBadge: View {
    let icon: String
    let title: String
    let isUnlocked: Bool
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(isUnlocked ? Color(hex: "#4ECDC4") : .gray)
                .opacity(isUnlocked ? 1 : 0.3)
            Text(title)
                .font(.caption)
                .foregroundColor(isUnlocked ? .primary : .gray)
        }
        .frame(width: 80, height: 80)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: isUnlocked ? 3 : 0)
    }
}
