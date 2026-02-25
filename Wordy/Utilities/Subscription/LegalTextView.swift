//
//  LegalTextView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 25.02.2026.
//

import SwiftUI

enum LegalDocument {
    case termsOfService
    case privacyPolicy
    
    var titleKey: LocalizableKey {
        switch self {
        case .termsOfService: return .termsOfService
        case .privacyPolicy: return .privacyPolicy
        }
    }
}

struct LegalTextView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    let document: LegalDocument
    
    var body: some View {
        ScrollView {
            Text(legalText)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .padding()
        }
        .navigationTitle(localizationManager.string(document.titleKey))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var legalText: String {
        switch (document, localizationManager.currentLanguage) {
        case (.termsOfService, .ukrainian):
            return LegalTexts.ukrainianTerms
        case (.termsOfService, .english):
            return LegalTexts.englishTerms
        case (.termsOfService, .polish):
            return LegalTexts.polishTerms
        case (.privacyPolicy, .ukrainian):
            return LegalTexts.ukrainianPrivacy
        case (.privacyPolicy, .english):
            return LegalTexts.englishPrivacy
        case (.privacyPolicy, .polish):
            return LegalTexts.polishPrivacy
        }
    }
}

// MARK: - Legal Texts
struct LegalTexts {
    static let englishTerms = """
    Terms of Service
    
    Last updated: February 2025
    
    1. Subscription Terms
    Wordy offers auto-renewing subscriptions. Payment will be charged to your Apple ID account at the confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period.
    
    2. Free Trial
    Any unused portion of a free trial period will be forfeited when you purchase a subscription.
    
    3. Cancellation
    You can manage and cancel your subscriptions by going to your account settings on the App Store after purchase.
    
    4. Refunds
    Refunds are handled by Apple. Please contact Apple Support for refund requests.
    """
    
    static let ukrainianTerms = """
    Умови використання
    
    Останнє оновлення: Лютий 2025
    
    1. Умови підписки
    Wordy пропонує автоматично поновлювані підписки. Платіж буде стягнуто з вашого облікового запису Apple ID під час підтвердження покупки. Підписка автоматично поновлюється, якщо її не скасовано щонайменше за 24 години до закінчення поточного періоду. З вашого облікового запису буде стягнуто плату за поновлення протягом 24 годин до закінчення поточного періоду.
    
    2. Безкоштовний пробний період
    Невикористана частина безкоштовного пробного періоду буде анульована при покупці підписки.
    
    3. Скасування
    Ви можете керувати підписками та скасовувати їх у налаштуваннях облікового запису App Store після покупки.
    
    4. Повернення коштів
    Повернення коштів обробляє Apple. Будь ласка, зверніться до підтримки Apple для запиту на повернення коштів.
    """
    
    static let polishTerms = """
    Warunki użytkowania
    
    Ostatnia aktualizacja: Luty 2025
    
    1. Warunki subskrypcji
    Wordy oferuje subskrypcje automatycznie odnawiane. Płatność zostanie pobrana z konta Apple ID przy potwierdzeniu zakupu. Subskrypcja automatycznie odnawia się, chyba że zostanie anulowana co najmniej 24 godziny przed końcem bieżącego okresu. Twoje konto zostanie obciążone za odnowienie w ciągu 24 godzin przed końcem bieżącego okresu.
    
    2. Bezpłatny okres próbny
    Niewykorzystana część bezpłatnego okresu próbnego przepadnie przy zakupie subskrypcji.
    
    3. Anulowanie
    Możesz zarządzać subskrypcjami i anulować je w ustawieniach konta App Store po zakupie.
    
    4. Zwroty
    Zwroty są obsługiwane przez Apple. Skontaktuj się z pomocą techniczną Apple w sprawie zwrotów.
    """
    
    static let englishPrivacy = """
    Privacy Policy
    
    Last updated: February 2025
    
    1. Data Collection
    We collect minimal data necessary for the app to function: your email (if you sign in), saved words, and app usage statistics.
    
    2. Data Usage
    Your data is used solely to provide the app's features: syncing across devices, personalizing your learning experience, and improving the app.
    
    3. Third Parties
    We use Firebase for data storage and authentication. We do not sell your data to third parties.
    
    4. Your Rights
    You can request deletion of your data at any time by contacting support.
    """
    
    static let ukrainianPrivacy = """
    Політика конфіденційності
    
    Останнє оновлення: Лютий 2025
    
    1. Збір даних
    Ми збираємо мінімальні дані, необхідні для роботи додатка: вашу електронну пошту (якщо ви увійшли), збережені слова та статистику використання.
    
    2. Використання даних
    Ваші дані використовуються виключно для надання функцій додатка: синхронізації між пристроями, персоналізації навчання та покращення додатка.
    
    3. Треті сторони
    Ми використовуємо Firebase для зберігання даних та автентифікації. Ми не продаємо ваші дані третім сторонам.
    
    4. Ваші права
    Ви можете запросити видалення своїх даних у будь-який час, зв'язавшись з підтримкою.
    """
    
    static let polishPrivacy = """
    Polityka prywatności
    
    Ostatnia aktualizacja: Luty 2025
    
    1. Zbieranie danych
    Zbieramy minimalne dane niezbędne do działania aplikacji: Twój e-mail (jeśli się zalogujesz), zapisane słowa i statystyki użytkowania.
    
    2. Wykorzystanie danych
    Twoje dane są wykorzystywane wyłącznie do świadczenia funkcji aplikacji: synchronizacji między urządzeniami, personalizacji nauki i ulepszania aplikacji.
    
    3. Strony trzecie
    Używamy Firebase do przechowywania danych i uwierzytelniania. Nie sprzedajemy Twoich danych stronom trzecim.
    
    4. Twoje prawa
    Możesz zażądać usunięcia swoich danych w dowolnym momencie, kontaktując się z pomocą techniczną.
    """
}
