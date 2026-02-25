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
    
    func scheduleTrialReminder(daysLeft: Int) {
        guard daysLeft > 0 else { return }
        
        // Скасовуємо старі сповіщення
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["trial_reminder"])
        
        let content = UNMutableNotificationContent()
        content.title = localizedTitle()
        content.body = localizedBody(daysLeft: daysLeft)
        content.sound = .default
        content.categoryIdentifier = "TRIAL_REMINDER"
        
        // Час сповіщення - за 24 години до закінчення (тобто через daysLeft-1 днів)
        let triggerDays = max(daysLeft - 1, 0)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(triggerDays * 24 * 60 * 60), repeats: false)
        
        let request = UNNotificationRequest(identifier: "trial_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleTrialEndNotification() {
        let content = UNMutableNotificationContent()
        content.title = localizedEndTitle()
        content.body = localizedEndBody()
        content.sound = .default
        content.categoryIdentifier = "TRIAL_ENDED"
        
        // Через 3 дні (коли trial закінчується)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3 * 24 * 60 * 60, repeats: false)
        
        let request = UNNotificationRequest(identifier: "trial_ended", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Localization
    private func localizedTitle() -> String {
        let lang = LocalizationManager.shared.currentLanguage
        switch lang {
        case .ukrainian: return "⏰ Пробний період скоро закінчиться"
        case .polish: return "⏰ Okres próbny wkrótce się skończy"
        case .english: return "⏰ Trial ending soon"
        }
    }
    
    private func localizedBody(daysLeft: Int) -> String {
        let lang = LocalizationManager.shared.currentLanguage
        switch lang {
        case .ukrainian:
            return daysLeft == 1 ? "Залишився 1 день безкоштовного користування. Оформіть підписку, щоб продовжити!" : "Залишилось \(daysLeft) дні безкоштовного користування. Оформіть підписку!"
        case .polish:
            return daysLeft == 1 ? "Pozostał 1 dzień bezpłatnego użytkowania. Kup subskrypcję, aby kontynuować!" : "Pozostało \(daysLeft) dni bezpłatnego użytkowania. Kup subskrypcję!"
        case .english:
            return daysLeft == 1 ? "1 day left of free trial. Subscribe to continue!" : "\(daysLeft) days left of free trial. Subscribe now!"
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
