//
//  OnboardingModifier.swift
//  Wordy
//

import SwiftUI

struct OnboardingModifier: ViewModifier {
    let step: OnboardingStep
    @EnvironmentObject var onboardingManager: OnboardingManager
    @State private var localFrame: CGRect = .zero
    @State private var hasAttemptedStart = false
    @State private var checkTimer: Timer? = nil
    @State private var appeared = false
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            appeared = true
                            let frame = geometry.frame(in: .global)
                            updateFrame(frame)
                            
                            // КЛЮЧОВИЙ ФІКС: Якщо це поточний крок і ми чекаємо - одразу оновлюємо
                            if onboardingManager.currentStep == step &&
                               onboardingManager.isWaitingForUI {
                                print("📍 Initial frame update for waiting step \(step.rawValue): \(frame)")
                                onboardingManager.currentTargetFrame = frame
                            }
                        }
                        .onChange(of: geometry.frame(in: .global)) { _, newFrame in
                            updateFrame(newFrame)
                        }
                        .onDisappear {
                            appeared = false
                            checkTimer?.invalidate()
                            checkTimer = nil
                        }
                }
            )
            .onChange(of: onboardingManager.currentStep) { _, newStep in
                if newStep == step && localFrame != .zero {
                    print("📍 Step changed to \(step.rawValue), updating frame: \(localFrame)")
                    onboardingManager.currentTargetFrame = localFrame
                }
            }
            .onAppear {
                startChecking()
            }
    }
    
    private func startChecking() {
        if step == .addToDictionary || step == .flashcards {
            tryStartOnboarding()
            
            checkTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                guard self.appeared else { return }
                
                // КЛЮЧОВИЙ ФІКС: Якщо це поточний крок і ми чекаємо на UI
                if self.onboardingManager.currentStep == self.step &&
                   self.onboardingManager.isWaitingForUI &&
                   self.localFrame != .zero &&
                   self.onboardingManager.currentTargetFrame != self.localFrame {
                    print("📍 Timer: Updating frame for \(self.step.rawValue): \(self.localFrame)")
                    self.onboardingManager.currentTargetFrame = self.localFrame
                }
                
                if !self.hasAttemptedStart {
                    self.tryStartOnboarding()
                }
            }
        } else {
            tryStartOnboarding()
        }
    }
    
    private func tryStartOnboarding() {
        guard !hasAttemptedStart || onboardingManager.currentStep == step else { return }
        guard appeared else { return }
        
        if onboardingManager.shouldShow(step) {
            hasAttemptedStart = true
            print("🚀 Starting onboarding for \(step.rawValue)")
            onboardingManager.showStep(step)
        }
    }
    
    private func updateFrame(_ frame: CGRect) {
        guard frame.width > 10, frame.height > 10 else { return }
        
        localFrame = frame
        
        // КЛЮЧОВИЙ ФІКС: Оновлюємо frame навіть якщо це поточний крок і ми чекаємо
        if onboardingManager.currentStep == step {
            if onboardingManager.currentTargetFrame != frame {
                print("📍 Updating global frame for \(step.rawValue): \(frame)")
                onboardingManager.currentTargetFrame = frame
            }
            
            // Якщо чекаємо на UI - перевіряємо чи можна показати
            if onboardingManager.isWaitingForUI {
                onboardingManager.checkConditionalSteps(
                    hasTranslation: onboardingManager.hasTranslationResult,
                    hasWords: onboardingManager.hasLearningWords
                )
            }
        }
    }
}

extension View {
    func onboardingStep(_ step: OnboardingStep) -> some View {
        modifier(OnboardingModifier(step: step))
    }
}
