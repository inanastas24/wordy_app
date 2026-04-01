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

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published var hasPermission = false
    @Published var permissionError: Error?

    // MARK: - Constants
    private enum NotificationIdentifiers {
        static let trialWelcome = "trial_welcome"
        static let trialReminder24h = "trial_reminder_24h"
        static let trialBillingCompleted = "trial_billing_completed"
        static let subscriptionConfirmed = "subscription_confirmed"

        static let allTrialIdentifiers = [
            trialWelcome,
            trialReminder24h,
            trialBillingCompleted
        ]
    }

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        // 🗑️ Прибрано registerNotificationCategories()
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

    // MARK: - Trial Notifications
    func scheduleTrialNotifications(trialStartDate: Date) {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                guard settings.authorizationStatus == .authorized else {
                    print("⚠️ Cannot schedule notifications: permission not granted")
                    return
                }

                self?.performScheduleTrialNotifications(trialStartDate: trialStartDate)
            }
        }
    }

    private func performScheduleTrialNotifications(trialStartDate: Date) {
        removeTrialNotifications()

        let calendar = Calendar.current
        let now = Date()

        // Безпечне обчислення дат
        guard let trialEndDate = calendar.date(byAdding: .day, value: 3, to: trialStartDate) else {
            print("❌ Failed to calculate trialEndDate")
            return
        }

        guard let welcomeDate = calendar.date(byAdding: .minute, value: 5, to: now) else {
            print("❌ Failed to calculate welcomeDate")
            return
        }

        guard let reminderDate = calendar.date(byAdding: .hour, value: -24, to: trialEndDate) else {
            print("❌ Failed to calculate reminderDate")
            return
        }

        guard let billingCompletedDate = calendar.date(byAdding: .minute, value: 1, to: trialEndDate) else {
            print("❌ Failed to calculate billingCompletedDate")
            return
        }

        print("📅 Trial schedule: start=\(trialStartDate), billingDate=\(trialEndDate)")

        // 1. Welcome notification (+5 min)
        if welcomeDate > now {
            scheduleNotification(
                identifier: NotificationIdentifiers.trialWelcome,
                titleKey: "trial_welcome_title",
                bodyKey: "trial_welcome_body",
                date: welcomeDate
            )
        }

        // 2. Reminder (-24h before billing)
        if reminderDate > now {
            scheduleNotification(
                identifier: NotificationIdentifiers.trialReminder24h,
                titleKey: "trial_reminder_title",
                bodyKey: "trial_reminder_body",
                date: reminderDate
            )
        }

        // 3. Billing completed (+1 min after trial ends)
        if billingCompletedDate > now {
            scheduleNotification(
                identifier: NotificationIdentifiers.trialBillingCompleted,
                titleKey: "trial_billing_completed_title",
                bodyKey: "trial_billing_completed_body",
                date: billingCompletedDate
            )
        }

        print("✅ Scheduled: Welcome=\(welcomeDate), Reminder=\(reminderDate), Billing=\(billingCompletedDate)")
    }

    func cancelTrialNotifications() {
        removeTrialNotifications()
        print("✅ Trial notifications cancelled")
    }

    private func removeTrialNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: NotificationIdentifiers.allTrialIdentifiers
        )
    }

    // MARK: - Immediate Notification
    func scheduleSubscriptionConfirmed() {
        let content = UNMutableNotificationContent()
        content.title = localizedString(for: "subscription_confirmed_title")
        content.body = localizedString(for: "subscription_confirmed_body")
        content.sound = .default
        content.badge = 1

        // 🆕 TimeInterval для миттєвої нотифікації
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: NotificationIdentifiers.subscriptionConfirmed,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule: \(error)")
            } else {
                print("✅ Subscription confirmed notification scheduled")
            }
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

    // MARK: - Helper
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
        // 🗑️ Прибрано categoryIdentifier

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
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

    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        clearBadge()
    }

    // MARK: - Localization
    private func localizedString(for key: String) -> String {
        let lang = LocalizationManager.shared.currentLanguage

        switch key {
        case "trial_welcome_title":
            switch lang {
            case .ukrainian: return "🎉 Пробний період активовано!"
            case .polish: return "🎉 Okres próbny aktywowany!"
            case .english: return "🎉 Trial period activated!"
            }
        case "trial_welcome_body":
            switch lang {
            case .ukrainian: return "У вас є 3 дні безкоштовного користування. Насолоджуйтесь всіма функціями! Кошти будуть списані через 3 дні."
            case .polish: return "Masz 3 dni bezpłatnego użytkowania. Korzystaj ze wszystkich funkcji! Opłata zostanie pobrana za 3 dni."
            case .english: return "You have 3 days of free usage. Enjoy all features! You will be charged in 3 days."
            }

        case "trial_reminder_title":
            switch lang {
            case .ukrainian: return "⏰ Завтра буде списано кошти"
            case .polish: return "⏰ Jutro nastąpi obciążenie"
            case .english: return "⏰ Billing tomorrow"
            }
        case "trial_reminder_body":
            switch lang {
            case .ukrainian: return "Завтра Apple спише кошти за підписку Wordy. Якщо не хочете продовжувати — скасуйте в налаштуваннях App Store."
            case .polish: return "Jutro Apple pobierze opłatę za subskrypcję Wordy. Jeśli nie chcesz kontynuować — anuluj w ustawieniach App Store."
            case .english: return "Apple will charge you for Wordy subscription tomorrow. Cancel in App Store settings if you don't want to continue."
            }

        case "trial_billing_completed_title":
            switch lang {
            case .ukrainian: return "💳 Підписку оформлено"
            case .polish: return "💳 Subskrypcja potwierdzona"
            case .english: return "💳 Subscription confirmed"
            }
        case "trial_billing_completed_body":
            switch lang {
            case .ukrainian: return "Кошти успішно списано. Дякуємо за підтримку! Ваша підписка активна."
            case .polish: return "Opłata pobrana pomyślnie. Dziękujemy za wsparcie! Twoja subskrypcja jest aktywna."
            case .english: return "Payment successful. Thank you for your support! Your subscription is active."
            }

        case "subscription_confirmed_title":
            switch lang {
            case .ukrainian: return "✅ Підписку оформлено"
            case .polish: return "✅ Subskrypcja aktywowana"
            case .english: return "✅ Subscribed successfully"
            }
        case "subscription_confirmed_body":
            switch lang {
            case .ukrainian: return "Дякуємо! Тепер у вас повний доступ до всіх функцій Wordy."
            case .polish: return "Dziękujemy! Masz teraz pełny dostęp do wszystkich funkcji Wordy."
            case .english: return "Thank you! You now have full access to all Wordy features."
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
        // 🗑️ Прибрано обробку actionIdentifier (кнопок)
        // Користувач просто тапає на нотифікацію і відкривається додаток

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
