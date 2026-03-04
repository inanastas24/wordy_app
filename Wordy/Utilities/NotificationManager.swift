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
    
    // MARK: - 🆕 Головний метод для планування нотифікацій trial
    func scheduleTrialNotifications(trialStartDate: Date) {
        removeAllNotifications()
        
        let calendar = Calendar.current
        let now = Date()
        let trialEndDate = calendar.date(byAdding: .day, value: 3, to: trialStartDate)!
        
        // 1. Нагадування за 24 години до закінчення trial
        let reminderDate = calendar.date(byAdding: .hour, value: -24, to: trialEndDate)!
        if reminderDate > now {
            scheduleNotification(
                identifier: "trial_reminder_24h",
                titleKey: "trial_reminder_title",
                bodyKey: "trial_reminder_body",
                date: reminderDate
            )
        }
        
        // 2. Нагадування в день закінчення trial
        if trialEndDate > now {
            scheduleNotification(
                identifier: "trial_ended",
                titleKey: "trial_ended_title",
                bodyKey: "trial_ended_body",
                date: trialEndDate
            )
        }
        
        // 3. Привітальна нотифікація про початок trial
        let welcomeDate = calendar.date(byAdding: .minute, value: 5, to: now)!
        scheduleNotification(
            identifier: "trial_welcome",
            titleKey: "trial_welcome_title",
            bodyKey: "trial_welcome_body",
            date: welcomeDate
        )
        
        print("✅ Scheduled trial notifications. Trial ends at: \(trialEndDate)")
    }
    
    func cancelTrialNotifications() {
        removeAllNotifications()
        print("✅ Trial notifications cancelled")
    }
    
    func scheduleSubscriptionConfirmed() {
        scheduleNotification(
            identifier: "subscription_confirmed",
            titleKey: "subscription_confirmed_title",
            bodyKey: "subscription_confirmed_body",
            date: Date() // Одразу
        )
    }
    
    // 🆕 ВИПРАВЛЕНО: Зберігаємо ключі, а не готові рядки
    private func scheduleNotification(identifier: String, titleKey: String, bodyKey: String, date: Date) {
        let content = UNMutableNotificationContent()
        
        // 🆕 Локалізація відбувається тут, при створенні нотифікації
        // Використовуємо поточну мову з LocalizationManager
        content.title = localizedString(for: titleKey)
        content.body = localizedString(for: bodyKey)
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification \(identifier): \(error)")
            } else {
                print("✅ Scheduled: \(identifier) at \(date) with language: \(LocalizationManager.shared.currentLanguage.rawValue)")
            }
        }
    }
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Localization 🆕 ОНОВЛЕНО: Централізований метод
    private func localizedString(for key: String) -> String {
        let lang = LocalizationManager.shared.currentLanguage
        
        switch key {
        // Welcome
        case "trial_welcome_title":
            switch lang {
            case .ukrainian: return "🎉 Пробний період активовано!"
            case .polish: return "🎉 Okres próbny aktywowany!"
            case .english: return "🎉 Trial period activated!"
            }
        case "trial_welcome_body":
            switch lang {
            case .ukrainian: return "У вас є 3 дні безкоштовного користування. Насолоджуйтесь всіма функціями!"
            case .polish: return "Masz 3 dni bezpłatnego użytkowania. Korzystaj ze wszystkich funkcji!"
            case .english: return "You have 3 days of free usage. Enjoy all features!"
            }
            
        // Reminder (24h before)
        case "trial_reminder_title":
            switch lang {
            case .ukrainian: return "⏰ Пробний період скоро закінчиться"
            case .polish: return "⏰ Okres próbny wkrótce się skończy"
            case .english: return "⏰ Trial ending soon"
            }
        case "trial_reminder_body":
            switch lang {
            case .ukrainian: return "Залишився 1 день безкоштовного користування. Підписка почнеться автоматично завтра. Можна скасувати в налаштуваннях."
            case .polish: return "Pozostał 1 dzień bezpłatnego użytkowania. Subskrypcja rozpocznie się automatycznie jutro. Można anulować w ustawieniach."
            case .english: return "1 day left of free trial. Subscription will start automatically tomorrow. You can cancel in settings."
            }
            
        // Trial ended
        case "trial_ended_title":
            switch lang {
            case .ukrainian: return "💳 Пробний період закінчився"
            case .polish: return "💳 Okres próbny zakończony"
            case .english: return "💳 Trial period ended"
            }
        case "trial_ended_body":
            switch lang {
            case .ukrainian: return "Ваша підписка активована! Дякуємо за підтримку. Можна скасувати будь-коли в налаштуваннях."
            case .polish: return "Twoja subskrypcja jest aktywna! Dziękujemy za wsparcie. Można anulować w dowolnym momencie w ustawieniach."
            case .english: return "Your subscription is active! Thank you for your support. You can cancel anytime in settings."
            }
            
        // Subscription confirmed
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

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        switch response.actionIdentifier {
        case "BUY_PREMIUM":
            NotificationCenter.default.post(name: .openPaywallFromNotification, object: nil)
        case "CANCEL_TRIAL":
            NotificationCenter.default.post(name: .cancelTrialRequested, object: nil)
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
    static let cancelTrialRequested = Notification.Name("cancelTrialRequested")
}
