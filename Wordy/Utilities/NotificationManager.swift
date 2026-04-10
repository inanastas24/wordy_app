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

final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published var hasPermission = false
    @Published var permissionError: Error?

    private let defaults = UserDefaults.standard

    // MARK: - Constants
    private enum NotificationIdentifiers {
        static let subscriptionWelcome = "subscription_welcome"
        static let billingReminder24h = "billing_reminder_24h"

        static let allIdentifiers = [
            subscriptionWelcome,
            billingReminder24h
        ]
    }

    private enum DefaultsKeys {
        static let scheduledOriginalTransactionId = "scheduled_original_transaction_id"
        static let scheduledExpiryTimestamp = "scheduled_expiry_timestamp"
    }

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Permission
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.hasPermission = granted

                if let error = error {
                    self?.permissionError = error
                    print("❌ Notification permission error: \(error.localizedDescription)")
                } else {
                    print("✅ Notification permission: \(granted)")
                }
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
        let content = UNMutableNotificationContent()
        content.title = localizedString(for: titleKey)
        content.body = localizedString(for: bodyKey)
        content.sound = .default
        content.badge = 1

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
        clearBadge()
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
