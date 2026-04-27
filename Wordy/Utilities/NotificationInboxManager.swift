import Foundation
import Combine
import UserNotifications
import UIKit
import FirebaseAuth

enum AppNotificationKind: String, Codable {
    case wordOfDay
    case subscription
    case general
}

struct AppNotificationInboxItem: Identifiable, Codable, Equatable {
    let id: String
    var requestIdentifier: String
    var title: String
    var body: String
    var kind: AppNotificationKind
    var scheduledAt: Date?
    var deliveredAt: Date?
    var tappedAt: Date?
    var createdAt: Date
    var isRead: Bool

    var sortDate: Date {
        tappedAt ?? deliveredAt ?? scheduledAt ?? createdAt
    }
}

@MainActor
final class NotificationInboxManager: ObservableObject {
    static let shared = NotificationInboxManager()

    @Published private(set) var items: [AppNotificationInboxItem] = []
    @Published private(set) var unreadCount: Int = 0
    @Published var shouldOpenInbox = false

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        load()

        NotificationCenter.default.addObserver(
            forName: .userDidLogout,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.items = []
            self?.recalculateUnreadCount()
        }
    }

    func requestOpenInbox() {
        shouldOpenInbox = true
    }

    func consumeOpenInboxRequest() {
        shouldOpenInbox = false
    }

    var visibleItems: [AppNotificationInboxItem] {
        let now = Date()
        return items.filter { item in
            if item.deliveredAt != nil || item.tappedAt != nil {
                return true
            }

            guard let scheduledAt = item.scheduledAt else {
                return true
            }

            return scheduledAt <= now
        }
    }

    func refreshState() {
        load()
        pruneScheduledOnlyItems()
        syncDeliveredNotifications()
    }

    func recordPresentedNotification(_ notification: UNNotification) {
        update(from: notification, markRead: false, markDelivered: true)
    }

    func recordTappedNotification(_ notification: UNNotification) {
        update(from: notification, markRead: false, markDelivered: true, markTapped: true)
    }

    func markAllAsRead() {
        guard !items.isEmpty else { return }
        let visibleIds = Set(visibleItems.map(\.id))
        for index in items.indices where visibleIds.contains(items[index].id) {
            items[index].isRead = true
        }
        recalculateUnreadCount()
        persist()
        NotificationManager.shared.clearBadge()
    }

    private func update(
        from notification: UNNotification,
        markRead: Bool,
        markDelivered: Bool,
        markTapped: Bool = false
    ) {
        let content = notification.request.content
        let userInfo = content.userInfo

        let inboxId = (userInfo["inboxId"] as? String)
            ?? makeInboxId(
                requestIdentifier: notification.request.identifier,
                scheduledAt: (userInfo["scheduledAt"] as? TimeInterval).map(Date.init(timeIntervalSince1970:)) ?? Date()
            )

        let kind = AppNotificationKind(rawValue: (userInfo["notificationKind"] as? String) ?? "") ?? .general
        let scheduledAt = (userInfo["scheduledAt"] as? TimeInterval).map(Date.init(timeIntervalSince1970:))

        if let index = items.firstIndex(where: { $0.id == inboxId }) {
            items[index].title = content.title
            items[index].body = content.body
            items[index].kind = kind
            items[index].scheduledAt = items[index].scheduledAt ?? scheduledAt
            if markDelivered {
                items[index].deliveredAt = Date()
            }
            if markTapped {
                items[index].tappedAt = Date()
            }
            if markRead {
                items[index].isRead = true
            }
        } else {
            items.append(
                AppNotificationInboxItem(
                    id: inboxId,
                    requestIdentifier: notification.request.identifier,
                    title: content.title,
                    body: content.body,
                    kind: kind,
                    scheduledAt: scheduledAt,
                    deliveredAt: markDelivered ? Date() : nil,
                    tappedAt: markTapped ? Date() : nil,
                    createdAt: Date(),
                    isRead: markRead
                )
            )
        }

        sortAndPersist()
    }

    private func sortAndPersist() {
        items.sort { $0.sortDate > $1.sortDate }
        recalculateUnreadCount()
        persist()
    }

    private func pruneScheduledOnlyItems() {
        let filtered = items.filter { item in
            item.deliveredAt != nil || item.tappedAt != nil
        }

        guard filtered.count != items.count else { return }
        items = filtered
        sortAndPersist()
    }

    private func syncDeliveredNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications { [weak self] notifications in
            guard let self else { return }

            Task { @MainActor in
                for notification in notifications {
                    self.update(from: notification, markRead: false, markDelivered: true)
                }
            }
        }
    }

    private func recalculateUnreadCount() {
        unreadCount = visibleItems.filter { !$0.isRead }.count
        syncAppIconBadge()
    }

    private func syncAppIconBadge() {
        let badgeValue = max(unreadCount, 0)

        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(badgeValue)
        } else {
            UIApplication.shared.applicationIconBadgeNumber = badgeValue
        }
    }

    private func persist() {
        guard let data = try? encoder.encode(items) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? decoder.decode([AppNotificationInboxItem].self, from: data) else {
            items = []
            recalculateUnreadCount()
            return
        }

        items = decoded.sorted { $0.sortDate > $1.sortDate }
        recalculateUnreadCount()
    }

    private var storageKey: String {
        let userId = Auth.auth().currentUser?.uid ?? "guest"
        return "notification_inbox_\(userId)"
    }

    private func makeInboxId(requestIdentifier: String, scheduledAt: Date) -> String {
        "\(requestIdentifier)|\(Int(scheduledAt.timeIntervalSince1970))"
    }
}
