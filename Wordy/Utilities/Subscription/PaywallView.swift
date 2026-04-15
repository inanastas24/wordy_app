//
//  PaywallView.swift
//  Wordy
//

import SwiftUI
import StoreKit

private enum PaywallLegalLinks {
    // Replace privacyURL with your real hosted privacy policy before submission.
    static let privacyURL = URL(string: "https://wordy-864b2.web.app/")!
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let manageSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!
}

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    let isFirstTime: Bool
    let onClose: (() -> Void)?
    let onSubscribe: (() -> Void)?

    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var showHowTrialWorks = false

    private let accentColor = Color(hex: "#4ECDC4")

    var body: some View {
        ZStack {
            Color(hex: localizationManager.isDarkMode ? "#1C1C1E" : "#FFFDF5")
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    closeButton
                    heroSection
                        .padding(.top, 8)
                    featuresSection
                        .padding(.top, 28)
                    pricingSection
                        .padding(.top, 28)
                    primaryCTA
                        .padding(.top, 24)
                    secondaryActions
                        .padding(.top, 14)
                    legalAndTrialSection
                        .padding(.top, 22)
                        .padding(.bottom, 36)
                }
            }
        }
        .onAppear {
            selectDefaultProduct()
        }
        .onChange(of: subscriptionManager.products) {
            selectDefaultProduct()
        }
        .sheet(isPresented: $showHowTrialWorks) {
            HowTrialWorksView()
                .environmentObject(localizationManager)
        }
    }

    private var closeButton: some View {
        HStack {
            Spacer()
            Button(action: closePaywall) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(localizationManager.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.28), Color(hex: "#FFD700").opacity(0.16)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 180)

                VStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 56))
                        .foregroundColor(Color(hex: "#FFD700"))

                    Text(heroBadgeText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(accentColor.opacity(0.12)))
                }
            }
            .padding(.horizontal, 20)

            VStack(spacing: 10) {
                Text(titleText)
                    .font(.system(size: 30, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))

                Text(subtitleText)
                    .font(.system(size: 15))
                    .multilineTextAlignment(.center)
                    .foregroundColor(localizationManager.isDarkMode ? Color(hex: "#B0B0B0") : Color(hex: "#6B7A89"))
                    .padding(.horizontal, 28)
            }
        }
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            FeatureRow(icon: "text.magnifyingglass", text: featureSearchText, isDarkMode: localizationManager.isDarkMode)
            FeatureRow(icon: "speaker.wave.2.fill", text: featureVoiceText, isDarkMode: localizationManager.isDarkMode)
            FeatureRow(icon: "rectangle.stack.badge.play", text: featureFlashcardsText, isDarkMode: localizationManager.isDarkMode)
            FeatureRow(icon: "bookmark.fill", text: featureDictionaryText, isDarkMode: localizationManager.isDarkMode)
        }
        .padding(.horizontal, 28)
    }

    private var pricingSection: some View {
        VStack(spacing: 12) {
            ForEach(subscriptionManager.products, id: \.id) { product in
                ModernPricingCard(
                    product: product,
                    isSelected: selectedProduct?.id == product.id,
                    accentColor: accentColor,
                    isDarkMode: localizationManager.isDarkMode,
                    currentLanguage: localizationManager.currentLanguage
                ) {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                        selectedProduct = product
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var primaryCTA: some View {
        VStack(spacing: 10) {
            Button(action: purchaseSelected) {
                HStack(spacing: 10) {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.85)
                    }
                    Text(primaryButtonText)
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(selectedProduct == nil ? Color.gray.opacity(0.45) : accentColor)
                )
                .shadow(color: accentColor.opacity(0.28), radius: 14, x: 0, y: 7)
            }
            .disabled(selectedProduct == nil || isPurchasing || isRestoring)

            Text(autoRenewsText)
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
        }
        .padding(.horizontal, 20)
    }

    private var secondaryActions: some View {
        VStack(spacing: 10) {
            Button(action: restorePurchases) {
                HStack(spacing: 8) {
                    if isRestoring {
                        ProgressView()
                            .tint(accentColor)
                            .scaleEffect(0.8)
                    }
                    Text(restoreButtonText)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(accentColor)
                }
            }
            .disabled(isPurchasing || isRestoring)

            Button(action: openManageSubscriptions) {
                Text(manageSubscriptionsText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(localizationManager.isDarkMode ? Color(hex: "#D0D0D0") : Color(hex: "#586574"))
            }
        }
    }

    private var legalAndTrialSection: some View {
        VStack(spacing: 14) {
            Button {
                showHowTrialWorks = true
            } label: {
                Text(howItWorksText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(accentColor)
                    .underline()
            }

            VStack(spacing: 10) {
                HStack(spacing: 4) {
                    Link(privacyText, destination: PaywallLegalLinks.privacyURL)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(accentColor)

                    Text("•")
                        .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))

                    Link(termsText, destination: PaywallLegalLinks.termsURL)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(accentColor)
                }

                Text(legalCaptionText)
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
                    .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                    .padding(.horizontal, 28)
            }
        }
    }

    private func selectDefaultProduct() {
        guard selectedProduct == nil else { return }
        guard !subscriptionManager.products.isEmpty else { return }

        selectedProduct =
            subscriptionManager.products.first(where: { $0.id.contains("year") })
            ?? subscriptionManager.products.first
    }

    private func purchaseSelected() {
        guard let product = selectedProduct else { return }
        isPurchasing = true

        Task {
            let success = await subscriptionManager.purchase(product: product)

            await MainActor.run {
                isPurchasing = false

                if success {
                    onSubscribe?()
                    dismissIfNeeded()
                }
            }
        }
    }

    private func restorePurchases() {
        isRestoring = true

        Task {
            _ = await subscriptionManager.restorePurchases()

            await MainActor.run {
                isRestoring = false
                if subscriptionManager.canUseApp {
                    onSubscribe?()
                    dismissIfNeeded()
                }
            }
        }
    }

    private func openManageSubscriptions() {
        UIApplication.shared.open(PaywallLegalLinks.manageSubscriptionsURL)
    }

    private func closePaywall() {
        onClose?()
        dismissIfNeeded()
    }

    private func dismissIfNeeded() {
        if !isFirstTime {
            dismiss()
        }
    }

    private var heroBadgeText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "3 дні без списання"
        case .polish: return "3 dni bez opłaty"
        case .english: return "3 days free before charge"
        }
    }

    private var titleText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Оберіть план Wordy Premium"
        case .polish: return "Wybierz plan Wordy Premium"
        case .english: return "Choose your Wordy Premium plan"
        }
    }

    private var subtitleText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Після 3-денного пробного періоду App Store автоматично спише оплату, якщо ви не скасуєте підписку до його завершення."
        case .polish: return "Po 3-dniowym okresie próbnym App Store automatycznie pobierze opłatę, jeśli nie anulujesz subskrypcji przed jego zakończeniem."
        case .english: return "After the 3-day free trial, the App Store will charge automatically unless you cancel before the trial ends."
        }
    }

    private var featureSearchText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Необмежений пошук і переклад слів та фраз"
        case .polish: return "Nielimitowane wyszukiwanie i tłumaczenie słów oraz fraz"
        case .english: return "Unlimited search and translation for words and phrases"
        }
    }

    private var featureVoiceText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Озвучення слів, перекладів і прикладів речень"
        case .polish: return "Odtwarzanie słów, tłumaczeń i przykładów zdań"
        case .english: return "Listen to words, translations, and example sentences"
        }
    }

    private var featureFlashcardsText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Картки для повторення та швидкого запам’ятовування"
        case .polish: return "Fiszki do powtórek i szybkiego zapamiętywania"
        case .english: return "Flashcards for review and faster memorization"
        }
    }

    private var featureDictionaryText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Особистий словник зі збереженими словами"
        case .polish: return "Osobisty słownik z zapisanymi słowami"
        case .english: return "Personal dictionary with saved words"
        }
    }

    private var primaryButtonText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Почати 3 дні безкоштовно"
        case .polish: return "Rozpocznij 3 dni za darmo"
        case .english: return "Start 3-day free trial"
        }
    }

    private var autoRenewsText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Підписка поновлюється автоматично, доки ви її не скасуєте в налаштуваннях App Store."
        case .polish: return "Subskrypcja odnawia się automatycznie, dopóki nie anulujesz jej w ustawieniach App Store."
        case .english: return "Subscription renews automatically until canceled in App Store settings."
        }
    }

    private var restoreButtonText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Відновити покупку"
        case .polish: return "Przywróć zakup"
        case .english: return "Restore Purchase"
        }
    }

    private var manageSubscriptionsText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Керувати підпискою"
        case .polish: return "Zarządzaj subskrypcją"
        case .english: return "Manage Subscription"
        }
    }

    private var howItWorksText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Як це працює"
        case .polish: return "Jak to działa"
        case .english: return "How it works"
        }
    }

    private var privacyText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Privacy Policy"
        case .polish: return "Privacy Policy"
        case .english: return "Privacy Policy"
        }
    }

    private var termsText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Terms of Use"
        case .polish: return "Terms of Use"
        case .english: return "Terms of Use"
        }
    }

    private var legalCaptionText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Натискаючи кнопку ви погоджуєтесь з умовами користування та політикою конфіденційності."
        case .polish: return "Klikając przycisk, akceptujesz warunki korzystania i politykę prywatności."
        case .english: return "By continuing, you agree to the Terms of Use and Privacy Policy."
        }
    }
}

private struct ModernPricingCard: View {
    let product: Product
    let isSelected: Bool
    let accentColor: Color
    let isDarkMode: Bool
    let currentLanguage: Language
    let action: () -> Void

    private var isYearly: Bool {
        product.id.contains("year")
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(isSelected ? accentColor : .gray)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(planTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(isDarkMode ? .white : Color(hex: "#2C3E50"))

                        if isYearly {
                            Text(bestValueText)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color(hex: "#FFD700")))
                        }
                    }

                    Text(durationText)
                        .font(.system(size: 13))
                        .foregroundColor(isDarkMode ? .gray : Color(hex: "#7F8C8D"))

                    Text(trialCaptionText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(accentColor)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(isDarkMode ? .white : Color(hex: "#2C3E50"))

                    Text(billingCaption)
                        .font(.system(size: 12))
                        .foregroundColor(isDarkMode ? .gray : Color(hex: "#7F8C8D"))

                    if isYearly {
                        Text(monthlyEquivalentText)
                            .font(.system(size: 11))
                            .foregroundColor(accentColor)
                    }
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? accentColor : (isDarkMode ? Color.gray.opacity(0.28) : Color(hex: "#D9E1E8")), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var planTitle: String {
        switch currentLanguage {
        case .ukrainian: return isYearly ? "Річна" : "Місячна"
        case .polish: return isYearly ? "Roczna" : "Miesięczna"
        case .english: return isYearly ? "Yearly" : "Monthly"
        }
    }

    private var durationText: String {
        switch currentLanguage {
        case .ukrainian: return isYearly ? "1 рік доступу" : "1 місяць доступу"
        case .polish: return isYearly ? "1 rok dostępu" : "1 miesiąc dostępu"
        case .english: return isYearly ? "1 year access" : "1 month access"
        }
    }

    private var billingCaption: String {
        switch currentLanguage {
        case .ukrainian: return isYearly ? "за рік" : "за місяць"
        case .polish: return isYearly ? "za rok" : "za miesiąc"
        case .english: return isYearly ? "per year" : "per month"
        }
    }

    private var trialCaptionText: String {
        switch currentLanguage {
        case .ukrainian: return "3 дні безкоштовно"
        case .polish: return "3 dni za darmo"
        case .english: return "3 days free"
        }
    }

    private var bestValueText: String {
        switch currentLanguage {
        case .ukrainian: return "Вигідно"
        case .polish: return "Najlepsza oferta"
        case .english: return "Best value"
        }
    }

    private var monthlyEquivalentText: String {
        let priceDecimalNumber = NSDecimalNumber(decimal: product.price)
        let monthlyDecimal = priceDecimalNumber.dividing(by: NSDecimalNumber(value: 12))
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceFormatStyle.locale
        let monthly = formatter.string(from: monthlyDecimal) ?? ""

        switch currentLanguage {
        case .ukrainian: return "≈ \(monthly)/міс"
        case .polish: return "≈ \(monthly)/mies."
        case .english: return "≈ \(monthly)/mo"
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    let isDarkMode: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "#4ECDC4"))
                .frame(width: 24)

            Text(text)
                .font(.system(size: 16))
                .foregroundColor(isDarkMode ? .white : Color(hex: "#2C3E50"))
                .lineSpacing(4)

            Spacer()
        }
    }
}

struct HowTrialWorksView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: localizationManager.isDarkMode ? "#1C1C1E" : "#FFFDF5")
                    .ignoresSafeArea()

                VStack(spacing: 34) {
                    VStack(alignment: .leading, spacing: 0) {
                        timelineItem(icon: "play.fill", title: todayTitle, description: todayDescription)
                        timelineLine
                        timelineItem(icon: "bell.fill", title: secondStepTitle, description: secondStepDescription)
                        timelineLine
                        timelineItem(icon: "creditcard.fill", title: thirdStepTitle, description: thirdStepDescription)
                    }
                    .padding(.horizontal, 28)

                    Spacer()
                }
                .padding(.top, 32)
            }
            .navigationTitle(howItWorksNavTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(doneTitle) {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#4ECDC4"))
                }
            }
        }
    }

    private func timelineItem(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#4ECDC4"))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 19))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(localizationManager.isDarkMode ? Color(hex: "#A0A0A0") : Color(hex: "#7F8C8D"))
            }
        }
    }

    private var timelineLine: some View {
        Rectangle()
            .fill(Color(hex: "#4ECDC4").opacity(0.28))
            .frame(width: 2, height: 34)
            .padding(.leading, 21)
    }

    private var howItWorksNavTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Як це працює"
        case .polish: return "Jak to działa"
        case .english: return "How it works"
        }
    }

    private var doneTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Готово"
        case .polish: return "Gotowe"
        case .english: return "Done"
        }
    }

    private var todayTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Сьогодні"
        case .polish: return "Dziś"
        case .english: return "Today"
        }
    }

    private var todayDescription: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Ви відкриваєте всі Premium-функції та починаєте 3-денний пробний період."
        case .polish: return "Odblokowujesz wszystkie funkcje Premium i rozpoczynasz 3-dniowy okres próbny."
        case .english: return "You unlock all Premium features and start your 3-day free trial."
        }
    }

    private var secondStepTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Перед закінченням пробного періоду"
        case .polish: return "Przed końcem okresu próbnego"
        case .english: return "Before the trial ends"
        }
    }

    private var secondStepDescription: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Скасуйте підписку в налаштуваннях App Store, якщо не хочете продовження."
        case .polish: return "Anuluj subskrypcję w ustawieniach App Store, jeśli nie chcesz kontynuować."
        case .english: return "Cancel in App Store settings if you do not want the subscription to continue."
        }
    }

    private var thirdStepTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Через 3 дні"
        case .polish: return "Za 3 dni"
        case .english: return "In 3 days"
        }
    }

    private var thirdStepDescription: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "App Store спише оплату за вибраний план, якщо підписку не скасовано."
        case .polish: return "App Store pobierze opłatę za wybrany plan, jeśli subskrypcja nie zostanie anulowana."
        case .english: return "The App Store charges for the selected plan if the subscription has not been canceled."
        }
    }
}
