//
//  PaywallView.swift
//  Wordy
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    let isFirstTime: Bool
    let onClose: (() -> Void)?
    let onSubscribe: (() -> Void)?
    
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showHowTrialWorks = false
    
    private let accentColor = Color(hex: "#4ECDC4")
    
    var body: some View {
        ZStack {
            Color(hex: localizationManager.isDarkMode ? "#1C1C1E" : "#FFFDF5")
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if !isFirstTime {
                        closeButton
                    } else {
                        Color.clear.frame(height: 54)
                    }
                    
                    headerImage
                    titleSection
                    featuresSection
                    .padding(.top, 30)
                    pricingSection
                    .padding(.top, 30)
                    ctaButton
                    .padding(.top, 30)
                    trialInfoSection
                    .padding(.top, 16)
                    howTrialWorksButton
                    .padding(.top, 12)
                    termsSection
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            print("👁️ Paywall appeared")
            selectDefaultProduct()
            print("   - Available products: \(subscriptionManager.products.map { $0.id })")
            print("   - Selected product: \(selectedProduct?.id ?? "nil")")
        }
        .sheet(isPresented: $showHowTrialWorks) {
            HowTrialWorksView()
                .environmentObject(localizationManager)
        }
    }
    
    private var closeButton: some View {
        HStack {
            Spacer()
            Button {
                onClose?()
                    if !isFirstTime {
                        dismiss()  // ✅ Закриваємо через dismiss
                    }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                    .frame(width: 44, height: 44)
                    .background(localizationManager.isDarkMode ? Color.white.opacity(0.1) : Color(hex: "#2C3E50").opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var headerImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [accentColor.opacity(0.3), accentColor.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 200)
                .padding(.horizontal, 20)
            
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundColor(accentColor)
        }
        .padding(.top, 10)
    }
    
    private var titleSection: some View {
        VStack(spacing: 12) {
            Text(localized(.try3DaysFree))
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 30)
        .padding(.horizontal, 20)
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            FeatureRow(icon: "checkmark", text: localized(.feature1), isDarkMode: localizationManager.isDarkMode)
            FeatureRow(icon: "checkmark", text: localized(.feature2), isDarkMode: localizationManager.isDarkMode)
            FeatureRow(icon: "checkmark", text: localized(.feature3), isDarkMode: localizationManager.isDarkMode)
            FeatureRow(icon: "checkmark", text: localized(.feature4), isDarkMode: localizationManager.isDarkMode)
            FeatureRow(icon: "checkmark", text: localized(.feature5), isDarkMode: localizationManager.isDarkMode)
            FeatureRow(icon: "checkmark", text: localized(.feature6), isDarkMode: localizationManager.isDarkMode)
        }
        .padding(.horizontal, 30)
    }
    
    private var pricingSection: some View {
        VStack(spacing: 12) {
            ForEach(subscriptionManager.products, id: \.id) { product in
                PricingOptionCard(
                    product: product,
                    isSelected: selectedProduct?.id == product.id,
                    isYearly: product.id.contains("year"),
                    accentColor: accentColor,
                    isDarkMode: localizationManager.isDarkMode
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedProduct = product
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var ctaButton: some View {
        Button {
                print("🛒 CTA Button tapped")
                print("   - selectedProduct: \(selectedProduct?.id ?? "nil")")
                print("   - isPurchasing: \(isPurchasing)")
                purchaseSelected()
        } label: {
            HStack(spacing: 8) {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                }
                Text(localized(.startFreeTrial))
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Group {
                    if selectedProduct == nil {
                        Color.gray.opacity(0.5)
                    } else {
                        LinearGradient(
                            colors: [accentColor, Color(hex: "#44A08D")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .cornerRadius(28)
            .shadow(color: accentColor.opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .disabled(selectedProduct == nil || isPurchasing)
        .padding(.horizontal, 20)
    }
    
    private var trialInfoSection: some View {
        VStack(spacing: 8) {
            Text(localized(.trialPriceInfo))
                .font(.system(size: 14))
                .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                .multilineTextAlignment(.center)
            
            HStack(spacing: 4) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(accentColor)
                    .font(.system(size: 12))
                
                Text(localized(.noPaymentNow))
                    .font(.system(size: 13))
                    .foregroundColor(accentColor)
            }
        }
        .padding(.horizontal, 40)
    }
    
    private var howTrialWorksButton: some View {
        Button {
            showHowTrialWorks = true
        } label: {
            Text(localized(.howTrialWorks))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(accentColor)
                .underline()
        }
    }
    
    private var termsSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Text(localized(.byContinuing))
                    .font(.system(size: 12))
                    .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                
                Button {
                    showTerms = true
                } label: {
                    Text(localized(.termsOfService))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(accentColor)
                }
                
                Text("•")
                    .font(.system(size: 12))
                    .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                
                Button {
                    showPrivacy = true
                } label: {
                    Text(localized(.privacyPolicy))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(accentColor)
                }
            }
            .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
        .padding(.bottom, 40)
    }
    
    private func selectDefaultProduct() {
        selectedProduct = subscriptionManager.products.first(where: { $0.id.contains("year") })
            ?? subscriptionManager.products.first
    }
    
    private func purchaseSelected() {
        guard let product = selectedProduct else {
                print("❌ No product selected")
                return
            }
        
        // 🆕 Захист від подвійного натискання
            guard !isPurchasing else {
                print("⚠️ Already purchasing, ignoring")
                return
            }
            
            isPurchasing = true
            print("🛒 Starting purchase task for: \(product.id)")
            
            Task {
                defer {
                    Task { @MainActor in
                        isPurchasing = false
                    }
                }
                
                let success = await subscriptionManager.purchase(product: product)
                print("🛒 Purchase result: \(success)")
                
                if success {
                    await MainActor.run {
                        onSubscribe?()
                        dismiss()
                    }
                }
            }
        }
    
    private func localized(_ key: PaywallKey) -> String {
        PaywallLocalization.shared.string(key, for: localizationManager.currentLanguage)
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

struct PricingOptionCard: View {
    let product: Product
    let isSelected: Bool
    let isYearly: Bool
    let accentColor: Color
    let isDarkMode: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(isYearly ? "Yearly" : "Monthly")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(isDarkMode ? .white : Color(hex: "#2C3E50"))
                        
                        if isYearly {
                            Text("3 days FREE")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(accentColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(accentColor.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    if isYearly {
                        Text("\(monthlyPrice)/month")
                            .font(.system(size: 14))
                            .foregroundColor(isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(isDarkMode ? .white : Color(hex: "#2C3E50"))
                    
                    Text(isYearly ? "/year" : "/month")
                        .font(.system(size: 14))
                        .foregroundColor(isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                }
            }
            .padding()
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? (isDarkMode ? Color.white.opacity(0.1) : Color(hex: "#4ECDC4").opacity(0.1)) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? accentColor : (isDarkMode ? Color.gray.opacity(0.3) : Color(hex: "#BDC3C7")), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var monthlyPrice: String {
        let priceDecimalNumber = NSDecimalNumber(decimal: product.price)
        let monthlyDecimal = priceDecimalNumber.dividing(by: NSDecimalNumber(value: 12))
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceFormatStyle.locale
        return formatter.string(from: monthlyDecimal) ?? ""
    }
}

struct HowTrialWorksView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: localizationManager.isDarkMode ? "#1C1C1E" : "#FFFDF5").ignoresSafeArea()
                
                VStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 0) {
                        timelineItem(
                            icon: "lock.open.fill",
                            title: localized(.today),
                            description: localized(.todayDescription)
                        )
                        
                        timelineLine
                        
                        timelineItem(
                            icon: "bell.fill",
                            title: localized(.in2Days),
                            description: localized(.in2DaysDescription)
                        )
                        
                        timelineLine
                        
                        timelineItem(
                            icon: "star.fill",
                            title: localized(.in3Days),
                            description: localized(.in3DaysDescription)
                        )
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationTitle(localized(.howItWorksTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localized(.done)) {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#4ECDC4"))
                }
            }
        }
    }
    
    private func timelineItem(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#4ECDC4"))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
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
            .fill(Color(hex: "#4ECDC4").opacity(0.3))
            .frame(width: 2, height: 40)
            .padding(.leading, 21)
    }
    
    private func localized(_ key: HowTrialWorksKey) -> String {
        HowTrialWorksLocalization.shared.string(key, for: localizationManager.currentLanguage)
    }
}

enum HowTrialWorksKey {
    case howItWorksTitle, today, todayDescription, in2Days, in2DaysDescription, in3Days, in3DaysDescription, done
}

class HowTrialWorksLocalization {
    static let shared = HowTrialWorksLocalization()
    
    private let translations: [HowTrialWorksKey: [Language: String]] = [
        .howItWorksTitle: [.ukrainian: "Як це працює", .english: "How it works", .polish: "Jak to działa"],
        .today: [.ukrainian: "Сьогодні", .english: "Today", .polish: "Dziś"],
        .todayDescription: [.ukrainian: "Відкрийте всі функції та почніть навчання", .english: "Unlock all features and start learning", .polish: "Odblokuj wszystkie funkcje i zacznij naukę"],
        .in2Days: [.ukrainian: "Через 2 дні", .english: "In 2 days", .polish: "Za 2 dni"],
        .in2DaysDescription: [.ukrainian: "Нагадаємо за 24 години до закінчення пробного періоду", .english: "We'll remind you 24 hours before trial ends", .polish: "Przypomnimy 24 godziny przed końcem okresu próbnego"],
        .in3Days: [.ukrainian: "Через 3 дні", .english: "In 3 days", .polish: "Za 3 dni"],
        .in3DaysDescription: [.ukrainian: "З вас буде списано кошти, якщо не скасуєте", .english: "You'll be charged if you don't cancel", .polish: "Zostaniesz obciążony, jeśli nie anulujesz"],
        .done: [.ukrainian: "Готово", .english: "Done", .polish: "Gotowe"]
    ]
    
    func string(_ key: HowTrialWorksKey, for language: Language) -> String {
        translations[key]?[language] ?? ""
    }
}

enum PaywallKey {
    case try3DaysFree, feature1, feature2, feature3, feature4, feature5, feature6
    case startFreeTrial, trialPriceInfo, noPaymentNow, howTrialWorks
    case byContinuing, termsOfService, privacyPolicy
}

class PaywallLocalization {
    static let shared = PaywallLocalization()
    
    private let translations: [PaywallKey: [Language: String]] = [
        .try3DaysFree: [.ukrainian: "3 дні безкоштовно!", .english: "Try 3 Days Free!", .polish: "3 dni za darmo!"],
        .feature1: [.ukrainian: "Покращуйте англійську з тисячами нових слів", .english: "Improve your English with thousands of new words", .polish: "Ulepszaj angielski z tysiącami nowych słów"],
        .feature2: [.ukrainian: "Використовуйте речення від ChatGPT, колокації та переклади", .english: "Use ChatGPT-generated sentences, collocations and translations", .polish: "Używaj zdań od ChatGPT, kolokacji i tłumaczeń"],
        .feature3: [.ukrainian: "Створюйте власний словник з Oxford Dictionary", .english: "Create your own vocabulary with Oxford Dictionary", .polish: "Twórz własny słownik z Oxford Dictionary"],
       // .feature4: [.ukrainian: "Групуйте слова, створюйте списки та колекції", .english: "Group words, craft lists, and tailor your collections", .polish: "Grupuj słowa, twórz listy i kolekcje"],
        .feature5: [.ukrainian: "Необмежені вправи для запам'ятовування слів", .english: "Do unlimited practice exercises and make words stick", .polish: "Nieograniczone ćwiczenia do zapamiętywania słów"],
       // .feature6: [.ukrainian: "Приєднуйтесь до глобальних викликів та тестів", .english: "Join global challenges: take themed tests", .polish: "Dołącz do globalnych wyzwań i testów"],
        .startFreeTrial: [.ukrainian: "Почати безкоштовно", .english: "Start Free Trial", .polish: "Rozpocznij za darmo"],
        .trialPriceInfo: [.ukrainian: "3 дні безкоштовно, потім обраний тариф", .english: "3 days free, then selected plan", .polish: "3 dni za darmo, potem wybrany plan"],
        .noPaymentNow: [.ukrainian: "Немає оплати зараз. Скасувати можна в будь-який момент.", .english: "No payment due now. Cancel anytime.", .polish: "Brak płatności teraz. Anuluj w każdej chwili."],
        .howTrialWorks: [.ukrainian: "Як працює пробний період", .english: "How your free trial works", .polish: "Jak działa okres próbny"],
        .byContinuing: [.ukrainian: "Продовжуючи, ви погоджуєтесь з", .english: "By continuing, you agree to", .polish: "Kontynuując, zgadzasz się na"],
        .termsOfService: [.ukrainian: "Умовами", .english: "Terms", .polish: "Warunki"],
        .privacyPolicy: [.ukrainian: "Політикою", .english: "Privacy", .polish: "Prywatność"]
    ]
    
    func string(_ key: PaywallKey, for language: Language) -> String {
        translations[key]?[language] ?? ""
    }
}
