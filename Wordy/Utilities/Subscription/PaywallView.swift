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
                        dismiss()
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
            
            // 🆕 Краща іконка для підписки
            VStack(spacing: 16) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "#FFD700"))
                
                Image(systemName: "star.fill")
                    .font(.system(size: 30))
                    .foregroundColor(accentColor)
            }
        }
        .padding(.top, 10)
    }
    
    private var titleSection: some View {
        VStack(spacing: 12) {
            Text(localizationManager.string(.try3DaysFree))
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                .multilineTextAlignment(.center)
            
            // 🆕 Підзаголовок що пробний період для обох тарифів
            Text(localizationManager.string(.trialAppliesToBoth))
                .font(.system(size: 14))
                .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 30)
        .padding(.horizontal, 20)
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            FeatureRow(icon: "checkmark", text: localizationManager.string(.feature1), isDarkMode: localizationManager.isDarkMode)
            FeatureRow(icon: "checkmark", text: localizationManager.string(.feature2), isDarkMode: localizationManager.isDarkMode)
            FeatureRow(icon: "checkmark", text: localizationManager.string(.feature3), isDarkMode: localizationManager.isDarkMode)
            FeatureRow(icon: "checkmark", text: localizationManager.string(.feature4), isDarkMode: localizationManager.isDarkMode)
            FeatureRow(icon: "checkmark", text: localizationManager.string(.feature5), isDarkMode: localizationManager.isDarkMode)
            FeatureRow(icon: "checkmark", text: localizationManager.string(.feature6), isDarkMode: localizationManager.isDarkMode)
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
                Text(localizationManager.string(.startFreeTrial))
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
            Text(localizationManager.string(.trialPriceInfo))
                .font(.system(size: 14))
                .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                .multilineTextAlignment(.center)
            
            HStack(spacing: 4) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(accentColor)
                    .font(.system(size: 12))
                
                Text(localizationManager.string(.noPaymentNow))
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
            Text(localizationManager.string(.howTrialWorks))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(accentColor)
                .underline()
        }
    }
    
    private var termsSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Text(localizationManager.string(.byContinuing))
                    .font(.system(size: 12))
                    .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                
                Button {
                    showTerms = true
                } label: {
                    Text(localizationManager.string(.termsOfService))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(accentColor)
                }
                
                Text("•")
                    .font(.system(size: 12))
                    .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                
                Button {
                    showPrivacy = true
                } label: {
                    Text(localizationManager.string(.privacyPolicy))
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
                        
                        // ❌ Видалено лейбу "3 days FREE" - тепер вона не потрібна
                        // бо пробний період є для обох тарифів
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

// MARK: - HowTrialWorks Localization (залишаємо окремо бо це тільки для цього екрану)
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
