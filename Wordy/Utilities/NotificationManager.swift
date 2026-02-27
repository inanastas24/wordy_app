//
//  NotificationManager.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 23.02.2026.
//

import Foundation
import UserNotifications
import Combine

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var hasPermission = false
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.hasPermission = granted
            }
        }
    }
    
    // MARK: - 🆕 Головний метод для планування нотифікацій
    func scheduleTrialNotifications(expirationDate: Date) {
        // Скасовуємо старі
        removeAllNotifications()
        
        let calendar = Calendar.current
        let now = Date()
        
        // 1. Нагадування за 24 години до закінчення
        let reminderDate = calendar.date(byAdding: .hour, value: -24, to: expirationDate)!
        if reminderDate > now {
            scheduleNotification(
                identifier: "trial_reminder_24h",
                title: localizedReminderTitle(),
                body: localizedReminderBody(),
                date: reminderDate
            )
        }
        
        // 2. Нагадування в день закінчення trial
        if expirationDate > now {
            scheduleNotification(
                identifier: "trial_ended",
                title: localizedEndTitle(),
                body: localizedEndBody(),
                date: expirationDate
            )
        }
        
        print("✅ Scheduled trial notifications for: \(expirationDate)")
    }
    
    // 🆕 ДОДАНО: Загальний метод планування нотифікацій
    private func scheduleNotification(identifier: String, title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification \(identifier): \(error)")
            } else {
                print("✅ Scheduled: \(identifier) at \(date)")
            }
        }
    }
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Localization
    private func localizedReminderTitle() -> String {
        let lang = LocalizationManager.shared.currentLanguage
        switch lang {
        case .ukrainian: return "⏰ Пробний період скоро закінчиться"
        case .polish: return "⏰ Okres próbny wkrótce się skończy"
        case .english: return "⏰ Trial ending soon"
        }
    }
    
    private func localizedReminderBody() -> String {
        let lang = LocalizationManager.shared.currentLanguage
        switch lang {
        case .ukrainian: return "Залишився 1 день безкоштовного користування. Оформіть підписку, щоб продовжити!"
        case .polish: return "Pozostał 1 dzień bezpłatnego użytkowania. Kup subskrypcję, aby kontynuować!"
        case .english: return "1 day left of free trial. Subscribe to continue!"
        }
    }
    
    private func localizedEndTitle() -> String {
        let lang = LocalizationManager.shared.currentLanguage
        switch lang {
        case .ukrainian: return "🎁 Пробний період закінчився"
        case .polish: return "🎁 Okres próbny zakończony"
        case .english: return "🎁 Trial ended"
        }
    }
    
    private func localizedEndBody() -> String {
        let lang = LocalizationManager.shared.currentLanguage
        switch lang {
        case .ukrainian: return "Оформіть підписку Premium, щоб продовжити користуватися всіма функціями!"
        case .polish: return "Kup subskrypcję Premium, aby kontynuować korzystanie ze wszystkich funkcji!"
        case .english: return "Subscribe to Premium to continue using all features!"
        }
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        switch response.actionIdentifier {
        case "BUY_PREMIUM":
            NotificationCenter.default.post(name: .openPaywallFromNotification, object: nil)
        case "LATER", "CLOSE":
            break
        default:
            break
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}

extension Notification.Name {
    static let openPaywallFromNotification = Notification.Name("openPaywallFromNotification")
}
