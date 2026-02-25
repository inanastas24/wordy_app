//
//  BiometricAuthManager.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 24.02.2026.
//


import LocalAuthentication
import SwiftUI
import Combine


@MainActor
class BiometricAuthManager: ObservableObject {
    @Published var isBiometricAvailable = false
    @Published var biometricType: LABiometryType = .none
    @Published var isEnabled = false
    
    private let context = LAContext()
    private let userDefaultsKey = "biometricAuthEnabled"
    
    init() {
        checkAvailability()
        isEnabled = UserDefaults.standard.bool(forKey: userDefaultsKey)
    }
    
    func checkAvailability() {
        var error: NSError?
        isBiometricAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        biometricType = context.biometryType
        
        if let error = error {
            print("Biometric error: \(error.localizedDescription)")
        }
    }
    
    var biometricName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "Biometric"
        }
    }
    
    func authenticate() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        
        let reason = "Увійдіть в Wordy"
        
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            return success
        } catch {
            print("Biometric authentication failed: \(error.localizedDescription)")
            return false
        }
    }
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: userDefaultsKey)
    }
}
