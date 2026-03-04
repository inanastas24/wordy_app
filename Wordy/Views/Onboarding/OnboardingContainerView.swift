//
//  OnboardingContainerView.swift
//  Wordy
//

import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject var onboardingManager: OnboardingManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        ZStack {
            // НЕ додаємо затемнення тут - воно вже в CoachMarkView
            // Color.black.opacity(0.3)
            //     .ignoresSafeArea()
            
            // CoachMark - показуємо завжди коли є крок
            if let step = onboardingManager.currentStep {
                CoachMarkView(
                    step: step,
                    targetFrame: onboardingManager.currentTargetFrame,
                    onNext: {
                        onboardingManager.completeCurrentStep()
                    }
                )
                .environmentObject(localizationManager)
                .environmentObject(onboardingManager)
                .transition(.opacity)
            }
        }
        .transition(.opacity)
    }
}
