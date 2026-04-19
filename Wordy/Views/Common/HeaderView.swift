//1
//  HeaderView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI

// === HEADER ===
struct HeaderView: View {
    @Binding var showMenu: Bool
    let title: String
    var showAvatar: Bool = false
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var notificationInbox = NotificationInboxManager.shared
    
    var body: some View {
        HStack {
            Button(action: { withAnimation { showMenu = true } }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "line.horizontal.3")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryText(isDarkMode: localizationManager.isDarkMode))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(AppColors.controlFill(isDarkMode: localizationManager.isDarkMode))
                        )
                        .overlay(
                            Circle()
                                .stroke(AppColors.cardBorder(isDarkMode: localizationManager.isDarkMode), lineWidth: 1)
                        )
                        .shadow(color: AppColors.shadow(isDarkMode: localizationManager.isDarkMode), radius: 12, x: 0, y: 8)

                    if notificationInbox.unreadCount > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                            .offset(x: -3, y: 3)
                    }
                }
            }
            
            Spacer()
            
            VStack(spacing: 3) {
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryText(isDarkMode: localizationManager.isDarkMode))

                Text(headerSubtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.secondaryText(isDarkMode: localizationManager.isDarkMode))
            }
            
            Spacer()
            
            if showAvatar {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: "#4ECDC4"))
            } else {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#4ECDC4").opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "sparkles")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }

    private var headerSubtitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian:
            return title == localizationManager.string(.dictionary) ? "Ваші слова, словники й повторення" : "Готові добірки та швидкий старт"
        case .polish:
            return title == localizationManager.string(.dictionary) ? "Twoje słowa, słowniki i powtórki" : "Gotowe zestawy i szybki start"
        case .english:
            return title == localizationManager.string(.dictionary) ? "Your words, dictionaries and review flow" : "Curated sets and a fast start"
        }
    }
}
