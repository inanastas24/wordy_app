//
//  SubscriptionModifier.swift
//  Wordy
//

import SwiftUI

struct SubscriptionRequired: ViewModifier {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showPaywall = false
    
    let feature: PremiumFeature
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                // 🆕 Показуємо paywall якщо немає активної підписки
                if !subscriptionManager.canUseApp {
                    showPaywall = true
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    isFirstTime: false,  // Можна закрити
                    onClose: {
                        showPaywall = false
                    },
                    onSubscribe: {
                        showPaywall = false
                    }
                )
            }
    }
}

enum PremiumFeature {
    case unlimitedTranslations
    case voiceInput
    case camera
    case saveWords
    
    var limitForFree: Int {
        switch self {
        case .unlimitedTranslations: return 5
        case .saveWords: return 10
        default: return 0
        }
    }
}

extension View {
    func requiresSubscription(_ feature: PremiumFeature) -> some View {
        modifier(SubscriptionRequired(feature: feature))
    }
}
