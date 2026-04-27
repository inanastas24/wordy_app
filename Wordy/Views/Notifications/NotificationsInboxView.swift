import SwiftUI

struct NotificationsInboxView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var inboxManager = NotificationInboxManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.screenBackground(isDarkMode: localizationManager.isDarkMode)
                    .ignoresSafeArea()

                if inboxManager.visibleItems.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(inboxManager.visibleItems) { item in
                                notificationCard(item)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizationManager.string(.cancel)) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                inboxManager.refreshState()
                inboxManager.markAllAsRead()
                inboxManager.consumeOpenInboxRequest()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "bell.slash")
                .font(.system(size: 34, weight: .semibold))
                .foregroundColor(AppColors.secondaryText(isDarkMode: localizationManager.isDarkMode))

            Text(emptyTitle)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryText(isDarkMode: localizationManager.isDarkMode))

            Text(emptySubtitle)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.secondaryText(isDarkMode: localizationManager.isDarkMode))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
    }

    private func notificationCard(_ item: AppNotificationInboxItem) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(tintColor(for: item).opacity(localizationManager.isDarkMode ? 0.18 : 0.14))
                    .frame(width: 44, height: 44)

                Image(systemName: iconName(for: item))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(tintColor(for: item))
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    Text(item.title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryText(isDarkMode: localizationManager.isDarkMode))
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 8)

                    if !item.isRead {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 9, height: 9)
                    }
                }

                Text(item.body)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.secondaryText(isDarkMode: localizationManager.isDarkMode))
                    .fixedSize(horizontal: false, vertical: true)

                Text(timestampText(for: item))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.tertiaryText(isDarkMode: localizationManager.isDarkMode))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.cardBackground(isDarkMode: localizationManager.isDarkMode))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(AppColors.cardBorder(isDarkMode: localizationManager.isDarkMode), lineWidth: 1)
                )
        )
        .shadow(color: AppColors.shadow(isDarkMode: localizationManager.isDarkMode), radius: 14, x: 0, y: 8)
    }

    private func iconName(for item: AppNotificationInboxItem) -> String {
        switch item.kind {
        case .wordOfDay: return "character.book.closed.fill"
        case .subscription: return "creditcard.fill"
        case .general: return "bell.fill"
        }
    }

    private func tintColor(for item: AppNotificationInboxItem) -> Color {
        switch item.kind {
        case .wordOfDay: return Color(hex: "#4ECDC4")
        case .subscription: return Color(hex: "#FF8A34")
        case .general: return Color(hex: "#7C8CFF")
        }
    }

    private func timestampText(for item: AppNotificationInboxItem) -> String {
        let date = item.tappedAt ?? item.deliveredAt ?? item.scheduledAt ?? item.createdAt
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale.current
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private var titleText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Сповіщення"
        case .polish: return "Powiadomienia"
        case .english: return "Notifications"
        }
    }

    private var emptyTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Поки що тихо"
        case .polish: return "Na razie cisza"
        case .english: return "Nothing here yet"
        }
    }

    private var emptySubtitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Усі ваші push-сповіщення з'являтимуться тут, навіть якщо ви випадково змахнули банер."
        case .polish: return "Wszystkie Twoje powiadomienia push pojawią się tutaj, nawet jeśli przypadkowo usuniesz banner."
        case .english: return "All your push notifications will appear here, even if you accidentally dismiss the banner."
        }
    }
}
