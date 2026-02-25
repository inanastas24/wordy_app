import SwiftUI

struct SettingsSubscriptionSection: View {
    @ObservedObject var manager: SubscriptionManager
    var onManage: (() -> Void)?
    var onRestore: (() -> Void)?
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Статус підписки в одному рядку
            HStack(spacing: 12) {
                // Іконка статусу
                statusIcon
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(statusTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                    
                    if let subtitle = statusSubtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                    }
                }
                
                Spacer()
                
                // Бейдж статусу
                statusBadge
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
            
            // Кнопки дій - різні залежно від статусу
            HStack(spacing: 12) {
                if manager.isSubscriptionExpired || manager.status == .unknown {
                    // 🆕 Кнопка оновлення підписки
                    Button(action: { onManage?() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.system(size: 14))
                            Text(upgradeButtonTitle)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "#FFD700"))
                        )
                    }
                } else {
                    // Стандартні кнопки для активної підписки
                    Button(action: { onRestore?() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14))
                            Text(restoreButtonTitle)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "#4ECDC4"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "#4ECDC4").opacity(0.1))
                        )
                    }
                    
                    Button(action: { onManage?() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "gear")
                                .font(.system(size: 14))
                            Text(manageButtonTitle)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "#4ECDC4"))
                        )
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor.opacity(0.15))
                .frame(width: 44, height: 44)
            
            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
        }
    }

    private var iconName: String {
        switch manager.status {
        case .premium:
            return "crown.fill"
        case .trial:
            return "gift.fill"
        case .trialExpired:
            return "exclamationmark.triangle.fill"
        case .expired:
            return "xmark.circle.fill"  // 🆕 Іконка для expired
        case .billingRetry:
            return "exclamationmark.triangle.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch manager.status {
        case .premium:
            return Color(hex: "#FFD700")
        case .trial:
            return Color(hex: "#4ECDC4")
        case .trialExpired, .expired:
            return Color(hex: "#F38BA8")  // Червоний для expired
        case .billingRetry:
            return Color(hex: "#FFA500")
        case .unknown:
            return Color(hex: "#7F8C8D")
        }
    }

    private var iconBackgroundColor: Color {
        switch manager.status {
        case .premium:
            return Color(hex: "#FFD700")
        case .trial:
            return Color(hex: "#4ECDC4")
        case .trialExpired, .expired:
            return Color(hex: "#F38BA8")
        case .billingRetry:
            return Color(hex: "#FFA500")
        case .unknown:
            return Color(hex: "#7F8C8D")
        }
    }

    private var statusTitle: String {
        switch manager.status {
        case .premium:
            return localizationManager.currentLanguage == .ukrainian ? "Premium активно" :
                   localizationManager.currentLanguage == .polish ? "Premium aktywne" : "Premium Active"
        case .trial(let daysLeft):
            return localizationManager.currentLanguage == .ukrainian ? "Тріал: \(daysLeft) днів" :
                   localizationManager.currentLanguage == .polish ? "Trial: \(daysLeft) dni" : "Trial: \(daysLeft) days"
        case .trialExpired:
            return localizationManager.currentLanguage == .ukrainian ? "Тріал закінчився" :
                   localizationManager.currentLanguage == .polish ? "Trial wygasł" : "Trial Expired"
        case .expired:
            // 🆕 Правильний текст для expired
            return localizationManager.currentLanguage == .ukrainian ? "Підписка закінчилась" :
                   localizationManager.currentLanguage == .polish ? "Subskrypcja wygasła" : "Subscription Expired"
        case .billingRetry:
            return localizationManager.currentLanguage == .ukrainian ? "Проблема з оплатою" :
                   localizationManager.currentLanguage == .polish ? "Problem z płatnością" : "Billing Issue"
        case .unknown:
            return localizationManager.currentLanguage == .ukrainian ? "Немає підписки" :
                   localizationManager.currentLanguage == .polish ? "Brak subskrypcji" : "No Subscription"
        }
    }
    
    private var statusSubtitle: String? {
        switch manager.status {
        case .premium(let expiryDate, _):
            if let expiryDate = expiryDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return localizationManager.currentLanguage == .ukrainian ? "До \(formatter.string(from: expiryDate))" :
                       localizationManager.currentLanguage == .polish ? "Do \(formatter.string(from: expiryDate))" : "Until \(formatter.string(from: expiryDate))"
            }
            return localizationManager.currentLanguage == .ukrainian ? "Назавжди" :
                   localizationManager.currentLanguage == .polish ? "Na zawsze" : "Lifetime"
        case .trial:
            return localizationManager.currentLanguage == .ukrainian ? "Натисніть \"Керувати\" для оновлення" :
                   localizationManager.currentLanguage == .polish ? "Dotknij \"Zarządzaj\" aby ulepszyć" : "Tap \"Manage\" to upgrade"
        case .expired(let expiryDate):
            // 🆕 Показуємо коли закінчилась
            if let date = expiryDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return localizationManager.currentLanguage == .ukrainian ? "Закінчилась \(formatter.string(from: date))" :
                       localizationManager.currentLanguage == .polish ? "Wygasła \(formatter.string(from: date))" : "Expired on \(formatter.string(from: date))"
            }
            return localizationManager.currentLanguage == .ukrainian ? "Оновіть для продовження" :
                   localizationManager.currentLanguage == .polish ? "Odnów aby kontynuować" : "Renew to continue"
        case .trialExpired, .unknown:
            return localizationManager.currentLanguage == .ukrainian ? "Оновіть для продовження" :
                   localizationManager.currentLanguage == .polish ? "Odnów aby kontynuować" : "Renew to continue"
        case .billingRetry:
            return localizationManager.currentLanguage == .ukrainian ? "Оновіть спосіб оплати" :
                   localizationManager.currentLanguage == .polish ? "Zaktualizuj metodę płatności" : "Update payment method"
        }
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        switch manager.status {
        case .trial:
            PremiumBadgeView(type: .trial)
        case .premium:
            PremiumBadgeView(type: .premium)
        default:
            EmptyView()
        }
    }
    
    // 🆕 Локалізовані назви кнопок
    private var restoreButtonTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Відновити"
        case .polish: return "Przywróć"
        case .english: return "Restore"
        }
    }
    
    private var manageButtonTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Керувати"
        case .polish: return "Zarządzaj"
        case .english: return "Manage"
        }
    }
    
    private var upgradeButtonTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Оновити підписку"
        case .polish: return "Odnów subskrypcję"
        case .english: return "Renew Subscription"
        }
    }
}
