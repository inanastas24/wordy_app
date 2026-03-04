//
//  OnboardingManager.swift
//  Wordy
//

import SwiftUI
import Combine

enum OnboardingStep: String, CaseIterable, Equatable {
    case languagePair = "languagePair"
    case scanButton = "scanButton"
    case voiceButton = "voiceButton"
    case addToDictionary = "addToDictionary"
    case flashcards = "flashcards"
    
    var id: String { rawValue }
    
    static var orderedSteps: [OnboardingStep] {
        [.languagePair, .scanButton, .voiceButton, .addToDictionary, .flashcards]
    }
}

class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    @Published var currentStep: OnboardingStep?
    @Published var isShowingOverlay: Bool = false
    @Published var currentTargetFrame: CGRect = .zero
    
    // Контекст для умовних кроків
    @Published var hasTranslationResult: Bool = false
    @Published var hasLearningWords: Bool = false
    @Published var isBlockingInteraction: Bool = false
    
    // Чекаємо поки з'явиться UI елемент
    @Published var isWaitingForUI: Bool = false
    
    private var isStartingStep = false
    private var cancellables = Set<AnyCancellable>()
    
    private let completedKey = "completedOnboardingSteps_v5"
    private let hasStartedKey = "onboardingHasStarted_v5"
    
    var completedSteps: Set<String> {
        get {
            Set(UserDefaults.standard.stringArray(forKey: completedKey) ?? [])
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: completedKey)
        }
    }
    
    var hasStartedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: hasStartedKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasStartedKey) }
    }
    
    init() {
        // Слідкуємо за змінами контексту для умовних кроків
        Publishers.CombineLatest($hasTranslationResult, $hasLearningWords)
            .sink { [weak self] hasTranslation, hasWords in
                self?.checkConditionalSteps(hasTranslation: hasTranslation, hasWords: hasWords)
            }
            .store(in: &cancellables)
    }
    
    func checkConditionalSteps(hasTranslation: Bool, hasWords: Bool) {
        guard let current = currentStep else { return }
        
        print("🔍 checkConditionalSteps: current=\(current.rawValue), isWaiting=\(isWaitingForUI), hasTranslation=\(hasTranslation), hasWords=\(hasWords), frame=\(currentTargetFrame)")
        
        if isWaitingForUI {
            switch current {
            case .addToDictionary:
                // КЛЮЧОВИЙ ФІКС: Якщо ми чекаємо на addToDictionary, перевіряємо чи є frame
                // Не залежимо тільки від hasTranslation, бо картка може вже бути відкрита
                if currentTargetFrame != .zero {
                    print("✅ UI for addToDictionary is ready, showing...")
                    isWaitingForUI = false
                    isShowingOverlay = true
                    isBlockingInteraction = true
                }
            case .flashcards:
                if hasWords && currentTargetFrame != .zero {
                    print("✅ UI for flashcards is ready, showing...")
                    isWaitingForUI = false
                    isShowingOverlay = true
                    isBlockingInteraction = true
                } else {
                    print("⏳ flashcards waiting: hasWords=\(hasWords), frame=\(currentTargetFrame)")
                }
            default:
                break
            }
        }
    }
    
    func shouldShow(_ step: OnboardingStep) -> Bool {
        if currentStep == step && isWaitingForUI {
                return true
            }
            
            guard currentStep == nil, !isStartingStep else {
                print("🔍 shouldShow(\(step.rawValue)): false (busy with \(currentStep?.rawValue ?? "nil"))")
                return false
            }
        if step == .addToDictionary {
                // Показуємо тільки якщо є результат перекладу І ми на сторінці пошуку
                // (перевіряємо що hasTranslationResult true)
                guard hasTranslationResult else {
                    print("🔍 shouldShow(addToDictionary): false (no translation result)")
                    return false
                }
            }
        let ordered = OnboardingStep.orderedSteps
        guard let stepIndex = ordered.firstIndex(of: step) else { return false }
        
        if stepIndex == 0 {
            let should = !completedSteps.contains(step.rawValue)
            print("🔍 shouldShow(\(step.rawValue)): \(should) (first step)")
            return should
        }
        
        let previousSteps = ordered.prefix(stepIndex)
        let allPreviousCompleted = previousSteps.allSatisfy { completedSteps.contains($0.rawValue) }
        
        let contextReady: Bool
        switch step {
        case .addToDictionary:
            contextReady = hasTranslationResult
        case .flashcards:
            contextReady = hasLearningWords
        default:
            contextReady = true
        }
        
        let should = allPreviousCompleted && !completedSteps.contains(step.rawValue) && contextReady
        
        print("🔍 shouldShow(\(step.rawValue)): \(should) (prev completed: \(allPreviousCompleted), context: \(contextReady))")
        return should
    }
    
    func isCurrentStep(_ step: OnboardingStep) -> Bool {
        currentStep == step && isShowingOverlay
    }
    
    func showStep(_ step: OnboardingStep) {
        guard !isStartingStep, shouldShow(step) else {
            print("⚠️ Cannot show \(step.rawValue) - blocked")
            return
        }
        
        isStartingStep = true
        print("✅ Showing step: \(step.rawValue)")
        
        DispatchQueue.main.async {
            self.currentStep = step
            self.hasStartedOnboarding = true
            
            // Для умовних кроків спочатку чекаємо на UI
            switch step {
            case .addToDictionary, .flashcards:
                self.isWaitingForUI = true
                self.isShowingOverlay = false // Поки не показуємо overlay
                self.isBlockingInteraction = false
                print("⏳ Waiting for UI element for \(step.rawValue)...")
            default:
                self.isShowingOverlay = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.isStartingStep = false
            }
        }
    }
    
    func completeCurrentStep() {
        guard let step = currentStep else { return }
        
        print("✅ Completing step: \(step.rawValue)")
        
        completedSteps.insert(step.rawValue)
        isWaitingForUI = false
        
        let ordered = OnboardingStep.orderedSteps
        if let currentIndex = ordered.firstIndex(of: step),
           currentIndex + 1 < ordered.count {
            let nextStep = ordered[currentIndex + 1]
            print("➡️ Moving to next step: \(nextStep.rawValue)")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.currentTargetFrame = .zero
                self.currentStep = nextStep
                
                // Для умовних кроків починаємо чекати на UI
                if nextStep == .addToDictionary || nextStep == .flashcards {
                    self.isWaitingForUI = true
                    self.isShowingOverlay = false
                }
            }
        } else {
            print("🎉 All steps completed!")
            finishOnboarding()
        }
    }
    
    func skipOnboarding() {
        print("⏭️ Skipping onboarding")
        OnboardingStep.allCases.forEach { completedSteps.insert($0.rawValue) }
        finishOnboarding()
    }
    
    private func finishOnboarding() {
        isShowingOverlay = false
        isWaitingForUI = false
        isBlockingInteraction = false
        currentStep = nil
        currentTargetFrame = .zero
        isStartingStep = false
    }
    
    var isOnboardingCompleted: Bool {
        OnboardingStep.orderedSteps.allSatisfy { completedSteps.contains($0.rawValue) }
    }
    
    func resetOnboarding() {
        completedSteps.removeAll()
        hasStartedOnboarding = false
        hasTranslationResult = false
        hasLearningWords = false
        finishOnboarding()
    }
}

