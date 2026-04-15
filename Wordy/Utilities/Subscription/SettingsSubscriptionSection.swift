import SwiftUI

struct SettingsSubscriptionSection: View {
    @ObservedObject var manager: SubscriptionManager
    var onManage: (() -> Void)?
    var onRestore: (() -> Void)?
    @EnvironmentObject var localizationManager: LocalizationManager

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
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

                statusBadge
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(localizationManager.isDarkMode ? Color(hex: "#23252B") : Color.white.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(localizationManager.isDarkMode ? 0.06 : 0.7), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 8)
            )

            HStack(spacing: 12) {
                Button(action: { onRestore?() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                        Text(restoreButtonTitle)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "#4ECDC4"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(hex: "#4ECDC4").opacity(0.12))
                    )
                }

                Button(action: { onManage?() }) {
                    HStack(spacing: 6) {
                        Image(systemName: actionButtonIcon)
                            .font(.system(size: 14))
                        Text(actionButtonTitle)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(actionButtonColor)
                    )
                    .shadow(color: actionButtonColor.opacity(0.22), radius: 10, x: 0, y: 6)
                }
            }
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(iconBackgroundColor.opacity(0.15))
                .frame(width: 48, height: 48)

            Image(systemName: iconName)
                .font(.system(size: 20, weight: .semibold))
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
            return "xmark.circle.fill"
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
            return Color(hex: "#F38BA8")
        case .billingRetry:
            return Color(hex: "#FFA500")
        case .unknown:
            return Color(hex: "#7F8C8D")
        }
    }

    private var iconBackgroundColor: Color { iconColor }

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
        case .premium(let expiryDate, let isInGracePeriod):
            if isInGracePeriod {
                return localizationManager.currentLanguage == .ukrainian ? "Потрібно оновити спосіб оплати" :
                       localizationManager.currentLanguage == .polish ? "Zaktualizuj metodę płatności" : "Update payment method"
            }
            if let expiryDate = expiryDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return localizationManager.currentLanguage == .ukrainian ? "До \(formatter.string(from: expiryDate))" :
                       localizationManager.currentLanguage == .polish ? "Do \(formatter.string(from: expiryDate))" : "Until \(formatter.string(from: expiryDate))"
            }
            return localizationManager.currentLanguage == .ukrainian ? "Назавжди" :
                   localizationManager.currentLanguage == .polish ? "Na zawsze" : "Lifetime"
        case .trial:
            return localizationManager.currentLanguage == .ukrainian ? "Пробний період активний" :
                   localizationManager.currentLanguage == .polish ? "Okres próbny jest aktywny" : "Free trial is active"
        case .expired(let expiryDate):
            if let date = expiryDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return localizationManager.currentLanguage == .ukrainian ? "Закінчилась \(formatter.string(from: date))" :
                       localizationManager.currentLanguage == .polish ? "Wygasła \(formatter.string(from: date))" : "Expired on \(formatter.string(from: date))"
            }
            return localizationManager.currentLanguage == .ukrainian ? "Оформіть або відновіть підписку" :
                   localizationManager.currentLanguage == .polish ? "Kup lub przywróć subskrypcję" : "Buy or restore subscription"
        case .trialExpired, .unknown:
            return localizationManager.currentLanguage == .ukrainian ? "Оформіть або відновіть підписку" :
                   localizationManager.currentLanguage == .polish ? "Kup lub przywróć subskrypcję" : "Buy or restore subscription"
        case .billingRetry:
            return localizationManager.currentLanguage == .ukrainian ? "Пошук заблоковано до оновлення оплати" :
                   localizationManager.currentLanguage == .polish ? "Wyszukiwanie zablokowane do czasu aktualizacji płatności" : "Search is blocked until payment is updated"
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch manager.status {
        case .trial:
            PremiumBadgeView(type: .trial)
        case .premium(_, let isInGracePeriod):
            if !isInGracePeriod {
                PremiumBadgeView(type: .premium)
            }
        default:
            EmptyView()
        }
    }

    private var restoreButtonTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Відновити"
        case .polish: return "Przywróć"
        case .english: return "Restore"
        }
    }

    private var actionButtonTitle: String {
        switch manager.status {
        case .premium, .trial:
            switch localizationManager.currentLanguage {
            case .ukrainian: return "Керувати"
            case .polish: return "Zarządzaj"
            case .english: return "Manage"
            }
        case .unknown, .expired, .trialExpired, .billingRetry:
            switch localizationManager.currentLanguage {
            case .ukrainian: return "Оформити"
            case .polish: return "Kup"
            case .english: return "Subscribe"
            }
        }
    }

    private var actionButtonIcon: String {
        switch manager.status {
        case .premium, .trial:
            return "gear"
        case .unknown, .expired, .trialExpired, .billingRetry:
            return "crown.fill"
        }
    }

    private var actionButtonColor: Color {
        switch manager.status {
        case .premium, .trial:
            return Color(hex: "#4ECDC4")
        case .unknown, .expired, .trialExpired, .billingRetry:
            return Color(hex: "#FFD700")
        }
    }
}
