//
//  SubscriptionPaywallModifier.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 24.03.2026.
//

import SwiftUI

struct SubscriptionPaywallModifier: ViewModifier {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showPaywall = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if subscriptionManager.isSubscriptionExpired {
                    showPaywall = true
                }
            }
            .onChange(of: subscriptionManager.status) {
                if subscriptionManager.isSubscriptionExpired {
                    showPaywall = true
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    isFirstTime: false,
                    onClose: { showPaywall = false },
                    onSubscribe: { showPaywall = false }
                )
            }
    }
}
