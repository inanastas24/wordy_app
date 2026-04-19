//
//  NotificationManager.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 23.02.2026.
//

import Foundation
import UserNotifications
import Combine
import UIKit
import FirebaseAuth

final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published var hasPermission = false
    @Published var permissionError: Error?

    private let defaults = UserDefaults.standard

    // MARK: - Constants
    private enum NotificationIdentifiers {
        static let subscriptionWelcome = "subscription_welcome"
        static let billingReminder24h = "billing_reminder_24h"
        static let wordOfDayPrefix = "word_of_day_"
        static let wordOfDaySlots = (0..<7).map { "\(wordOfDayPrefix)\($0)" }

        static let allIdentifiers = [
            subscriptionWelcome,
            billingReminder24h
        ]
    }

    private enum DefaultsKeys {
        static let scheduledOriginalTransactionId = "scheduled_original_transaction_id"
        static let scheduledExpiryTimestamp = "scheduled_expiry_timestamp"
        static let wordOfDayEnabled = "word_of_day_enabled"
    }

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        refreshPermissionStatus()
    }

    var isWordOfDayEnabled: Bool {
        defaults.bool(forKey: DefaultsKeys.wordOfDayEnabled)
    }

    // MARK: - Permission
    func requestPermission(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.hasPermission = granted

                if let error = error {
                    self?.permissionError = error
                    print("❌ Notification permission error: \(error.localizedDescription)")
                } else {
                    print("✅ Notification permission: \(granted)")
                }

                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                completion?(granted)
            }
        }
    }

    func refreshPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Public API

    /// Планує тільки 2 пуші:
    /// 1) через 5 хв після purchaseDate
    /// 2) за 24 години до expiryDate
    func scheduleSubscriptionNotifications(
        purchaseDate: Date,
        expiryDate: Date,
        originalTransactionId: UInt64
    ) {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                guard settings.authorizationStatus == .authorized else {
                    print("⚠️ Cannot schedule notifications: permission not granted")
                    return
                }

                self?.performScheduleSubscriptionNotifications(
                    purchaseDate: purchaseDate,
                    expiryDate: expiryDate,
                    originalTransactionId: originalTransactionId
                )
            }
        }
    }

    func cancelSubscriptionNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: NotificationIdentifiers.allIdentifiers
        )
        clearScheduleState()
        print("✅ Subscription notifications cancelled")
    }

    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        clearScheduleState()
        clearBadge()
    }

    func setWordOfDayEnabled(_ enabled: Bool, words: [SavedWordModel]) {
        defaults.set(enabled, forKey: DefaultsKeys.wordOfDayEnabled)

        if enabled {
            if hasPermission {
                scheduleWordOfDayNotifications(words: words)
            } else {
                requestPermission { [weak self] granted in
                    guard let self else { return }
                    if granted {
                        self.scheduleWordOfDayNotifications(words: words)
                    }
                }
            }
        } else {
            cancelWordOfDayNotifications()
        }
    }

    func refreshWordOfDayNotifications(words: [SavedWordModel]) {
        guard isWordOfDayEnabled else { return }
        scheduleWordOfDayNotifications(words: words)
    }

    func cancelWordOfDayNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: NotificationIdentifiers.wordOfDaySlots
        )
        print("✅ Word of the day notifications cancelled")
    }

    // MARK: - Private

    private func performScheduleSubscriptionNotifications(
        purchaseDate: Date,
        expiryDate: Date,
        originalTransactionId: UInt64
    ) {
        let now = Date()

        let storedOriginalTransactionId = defaults.object(forKey: DefaultsKeys.scheduledOriginalTransactionId) as? UInt64
        let storedExpiryTimestamp = defaults.object(forKey: DefaultsKeys.scheduledExpiryTimestamp) as? Double

        let alreadyScheduled =
            storedOriginalTransactionId == originalTransactionId &&
            storedExpiryTimestamp == expiryDate.timeIntervalSince1970

        if alreadyScheduled {
            print("ℹ️ Notifications already scheduled for originalTransactionId=\(originalTransactionId)")
            return
        }

        let welcomeDate = purchaseDate.addingTimeInterval(5 * 60)
        let reminderDate = expiryDate.addingTimeInterval(-24 * 60 * 60)

        print("📅 Subscription notifications schedule:")
        print("   purchaseDate = \(purchaseDate)")
        print("   expiryDate   = \(expiryDate)")
        print("   welcomeDate  = \(welcomeDate)")
        print("   reminderDate = \(reminderDate)")

        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: NotificationIdentifiers.allIdentifiers
        )

        // 1. Push через 5 хв після оформлення
        if welcomeDate > now {
            scheduleNotification(
                identifier: NotificationIdentifiers.subscriptionWelcome,
                titleKey: "subscription_welcome_title",
                bodyKey: "subscription_welcome_body",
                date: welcomeDate
            )
        } else {
            print("ℹ️ Welcome notification skipped because date is in the past")
        }

        // 2. Push за 24 години до списання
        if reminderDate > now {
            scheduleNotification(
                identifier: NotificationIdentifiers.billingReminder24h,
                titleKey: "billing_reminder_title",
                bodyKey: "billing_reminder_body",
                date: reminderDate
            )
        } else {
            print("ℹ️ Billing reminder skipped because date is in the past")
        }

        defaults.set(originalTransactionId, forKey: DefaultsKeys.scheduledOriginalTransactionId)
        defaults.set(expiryDate.timeIntervalSince1970, forKey: DefaultsKeys.scheduledExpiryTimestamp)

        print("✅ Subscription notifications scheduled")
    }

    private func scheduleNotification(
        identifier: String,
        titleKey: String,
        bodyKey: String,
        date: Date
    ) {
        let title = localizedString(for: titleKey)
        let body = localizedString(for: bodyKey)
        let inboxId = NotificationInboxManager.shared.upsertScheduledNotification(
            requestIdentifier: identifier,
            title: title,
            body: body,
            scheduledAt: date,
            kind: .subscription
        )

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: max(NotificationInboxManager.shared.unreadCount, 0) + 1)
        content.userInfo = [
            "inboxId": inboxId,
            "notificationKind": AppNotificationKind.subscription.rawValue,
            "scheduledAt": date.timeIntervalSince1970
        ]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule \(identifier): \(error)")
            } else {
                print("✅ Scheduled: \(identifier) at \(date)")
            }
        }
    }

    private func clearScheduleState() {
        defaults.removeObject(forKey: DefaultsKeys.scheduledOriginalTransactionId)
        defaults.removeObject(forKey: DefaultsKeys.scheduledExpiryTimestamp)
    }

    private func scheduleWordOfDayNotifications(words: [SavedWordModel]) {
        refreshPermissionStatus()

        let candidates = uniqueWordOfDayCandidates(from: words)

        guard !candidates.isEmpty else {
            cancelWordOfDayNotifications()
            return
        }

        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self else { return }
            guard settings.authorizationStatus == .authorized else {
                print("⚠️ Cannot schedule word of the day: permission not granted")
                return
            }

            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: NotificationIdentifiers.wordOfDaySlots
            )

            let calendar = Calendar.current
            let now = Date()
            let startDate = nextWordOfDayStartDate(from: now, calendar: calendar)
            let userSeed = Auth.auth().currentUser?.uid ?? "guest"
            let plannedWords = plannedWordSequence(
                from: candidates,
                seed: userSeed,
                startDate: startDate,
                count: NotificationIdentifiers.wordOfDaySlots.count,
                calendar: calendar
            )

            for dayOffset in 0..<NotificationIdentifiers.wordOfDaySlots.count {
                guard let scheduledDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
                let identifier = NotificationIdentifiers.wordOfDaySlots[dayOffset]
                let word = plannedWords[dayOffset]
                let content = makeWordOfDayContent(
                    for: word,
                    identifier: identifier,
                    scheduledDate: scheduledDate,
                    badgeCount: max(NotificationInboxManager.shared.unreadCount, 0) + 1
                )
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("❌ Failed to schedule \(identifier): \(error)")
                    } else {
                        print("✅ Scheduled word of the day: \(identifier) at \(scheduledDate)")
                    }
                }
            }
        }
    }

    private func nextWordOfDayStartDate(from now: Date, calendar: Calendar) -> Date {
        let scheduledHour = 10
        let scheduledMinute = 0

        if let todayAtScheduledTime = calendar.date(bySettingHour: scheduledHour, minute: scheduledMinute, second: 0, of: now),
           todayAtScheduledTime > now {
            return todayAtScheduledTime
        }

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(86400)
        return calendar.date(bySettingHour: scheduledHour, minute: scheduledMinute, second: 0, of: tomorrow) ?? tomorrow
    }

    private func uniqueWordOfDayCandidates(from words: [SavedWordModel]) -> [SavedWordModel] {
        var seen = Set<String>()

        return words
            .filter { !$0.original.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sorted { lhs, rhs in
                wordOfDayCandidateKey(for: lhs) < wordOfDayCandidateKey(for: rhs)
            }
            .filter { word in
                let key = wordOfDayCandidateKey(for: word)
                return seen.insert(key).inserted
            }
    }

    private func plannedWordSequence(
        from words: [SavedWordModel],
        seed: String,
        startDate: Date,
        count: Int,
        calendar: Calendar
    ) -> [SavedWordModel] {
        guard !words.isEmpty else { return [] }

        let windowKey = wordOfDayDateKey(for: startDate, calendar: calendar)
        let offsetSeed = stableHash("\(seed)|\(windowKey)|\(words.count)")
        let startIndex = offsetSeed % words.count

        return (0..<count).map { index in
            let wordIndex = (startIndex + index) % words.count
            return words[wordIndex]
        }
    }

    private func wordOfDayCandidateKey(for word: SavedWordModel) -> String {
        "\(word.original.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())|\(word.translation.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())"
    }

    private func wordOfDayDateKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private func stableHash(_ value: String) -> Int {
        let prime: UInt64 = 1099511628211
        var hash: UInt64 = 1469598103934665603

        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }

        return Int(hash % UInt64(Int.max))
    }

    private func makeWordOfDayContent(
        for word: SavedWordModel,
        identifier: String,
        scheduledDate: Date,
        badgeCount: Int
    ) -> UNMutableNotificationContent {
        let title = localizedWordOfDayTitle()
        let body = localizedWordOfDayBody(for: word)
        let inboxId = NotificationInboxManager.shared.upsertScheduledNotification(
            requestIdentifier: identifier,
            title: title,
            body: body,
            scheduledAt: scheduledDate,
            kind: .wordOfDay
        )

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: max(badgeCount, 1))
        content.userInfo = [
            "inboxId": inboxId,
            "notificationKind": AppNotificationKind.wordOfDay.rawValue,
            "scheduledAt": scheduledDate.timeIntervalSince1970,
            "type": "word_of_day",
            "wordId": word.id ?? "",
            "original": word.original,
            "translation": word.translation
        ]
        return content
    }

    private func localizedWordOfDayTitle() -> String {
        switch LocalizationManager.shared.currentLanguage {
        case .ukrainian: return "Слово дня"
        case .polish: return "Słowo dnia"
        case .english: return "Word of the Day"
        }
    }

    private func localizedWordOfDayBody(for word: SavedWordModel) -> String {
        let pair = "\(word.original) — \(word.translation)"

        switch LocalizationManager.shared.currentLanguage {
        case .ukrainian:
            return "Сьогоднішнє слово: \(pair)"
        case .polish:
            return "Dzisiejsze słowo: \(pair)"
        case .english:
            return "Today's word: \(pair)"
        }
    }


    // MARK: - Badge
    func clearBadge() {
        DispatchQueue.main.async {
            if #available(iOS 16.0, *) {
                UNUserNotificationCenter.current().setBadgeCount(0)
            } else {
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
    }

    // MARK: - Localization
    private func localizedString(for key: String) -> String {
        let lang = LocalizationManager.shared.currentLanguage

        switch key {
        case "subscription_welcome_title":
            switch lang {
            case .ukrainian: return "🎉 Підписку оформлено!"
            case .polish: return "🎉 Subskrypcja aktywowana!"
            case .english: return "🎉 Subscription activated!"
            }

        case "subscription_welcome_body":
            switch lang {
            case .ukrainian: return "Дякуємо! Ви отримали доступ до Premium. Нагадуємо: перше списання буде через 3 дні, якщо не скасуєте підписку."
            case .polish: return "Dziękujemy! Otrzymałeś dostęp do Premium. Przypominamy: pierwsza opłata zostanie pobrana za 3 dni, jeśli nie anulujesz subskrypcji."
            case .english: return "Thank you! You now have Premium access. Reminder: the first charge will happen in 3 days unless you cancel."
            }

        case "billing_reminder_title":
            switch lang {
            case .ukrainian: return "⏰ Завтра буде списано кошти"
            case .polish: return "⏰ Jutro nastąpi obciążenie"
            case .english: return "⏰ Billing tomorrow"
            }

        case "billing_reminder_body":
            switch lang {
            case .ukrainian: return "Завтра Apple спише кошти за підписку Wordy. Якщо не хочете продовжувати — скасуйте в налаштуваннях App Store."
            case .polish: return "Jutro Apple pobierze opłatę za subskrypcję Wordy. Jeśli nie chcesz kontynuować — anuluj w ustawieniach App Store."
            case .english: return "Apple will charge you for Wordy subscription tomorrow. Cancel in App Store settings if you don't want to continue."
            }

        default:
            return key
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("🔔 Notification tapped: \(response.notification.request.identifier)")
        Task { @MainActor in
            NotificationInboxManager.shared.recordTappedNotification(response.notification)
            NotificationInboxManager.shared.requestOpenInbox()
        }
        clearBadge()
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        Task { @MainActor in
            NotificationInboxManager.shared.recordPresentedNotification(notification)
        }
        completionHandler([.banner, .sound, .badge])
    }
}
