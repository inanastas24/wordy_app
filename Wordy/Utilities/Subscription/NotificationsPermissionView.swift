//
//  NotificationsPermissionView.swift
//  Wordy
//

import SwiftUI
import UserNotifications

struct NotificationsPermissionView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    
    let onComplete: () -> Void
    
    @State private var isRequesting = false
    
    var body: some View {
        ZStack {
            Color(hex: "#1C1C1E")
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "#4ECDC4").opacity(0.15))
                        .frame(width: 140, height: 140)
                    
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                }
                
                // Text
                VStack(spacing: 16) {
                    Text(titleText)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(descriptionText)
                        .font(.system(size: 16))
                        .foregroundColor(Color.gray.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Buttons
                VStack(spacing: 16) {
                    Button {
                        requestNotifications()
                    } label: {
                        Text(allowText)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#4ECDC4"), Color(hex: "#44A08D")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(28)
                            .shadow(color: Color(hex: "#4ECDC4").opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    .disabled(isRequesting)
                    
                    Button {
                        // Пропустити — користувач може включити потім в налаштуваннях
                        onComplete()
                    } label: {
                        Text(skipText)
                            .font(.system(size: 16))
                            .foregroundColor(Color.gray)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
    }
    
    private var titleText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Нагадування про навчання"
        case .polish: return "Przypomnienia o nauce"
        case .english: return "Learning Reminders"
        }
    }
    
    private var descriptionText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Отримуйте нагадування про повторення слів та досягайте своїх цілей швидше"
        case .polish: return "Otrzymuj przypomnienia o powtórkach słów i osiągaj swoje cele szybciej"
        case .english: return "Get reminders for word reviews and reach your goals faster"
        }
    }
    
    private var allowText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Дозволити"
        case .polish: return "Zezwól"
        case .english: return "Allow"
        }
    }
    
    private var skipText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Не зараз"
        case .polish: return "Nie teraz"
        case .english: return "Not Now"
        }
    }
    
    private func requestNotifications() {
        isRequesting = true
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                isRequesting = false
                onComplete()
            }
        }
    }
}
