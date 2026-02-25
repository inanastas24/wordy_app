//
//  LoginView.swift
//  Wordy
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth
import LocalAuthentication
import CryptoKit

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    let onComplete: () -> Void
    
    @State private var hasCompleted = false
    @State private var currentNonce: String?
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo
                VStack(spacing: 16) {
                    Text("🫧")
                        .font(.system(size: 80))
                    
                    Text("Wordy")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(accentColor)
                    
                    Text(subtitleText)
                        .font(.system(size: 18))
                        .foregroundColor(secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Authentication Options
                VStack(spacing: 16) {
                    // Biometric Button
                    if authViewModel.biometricManager.isBiometricAvailable &&
                       authViewModel.biometricManager.isEnabled &&
                       Auth.auth().currentUser != nil {
                        biometricButton
                    }
                    
                    // Apple Sign In
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            let nonce = authViewModel.startSignInWithAppleFlow()
                            currentNonce = nonce
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = sha256(nonce)
                        },
                        onCompletion: { result in
                            Task {
                                await handleAppleSignIn(result: result)
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(
                        localizationManager.isDarkMode ? .white : .black
                    )
                    .frame(height: 56)
                    .cornerRadius(28)
                    
                    // Privacy note
                    Text(privacyText)
                        .font(.system(size: 12))
                        .foregroundColor(secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
                
                if authViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(accentColor)
                }
            }
        }
        .alert(localizationManager.string(.error), isPresented: .constant(!authViewModel.errorMessage.isEmpty)) {
            Button("OK") {
                authViewModel.errorMessage = ""
            }
        } message: {
            Text(authViewModel.errorMessage)
        }
        .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated && !hasCompleted {
                hasCompleted = true
                dismiss()
                onComplete()
            }
        }
        .onAppear {
            hasCompleted = false
            Task {
                await tryBiometricAuth()
            }
        }
    }
    
    private var biometricButton: some View {
        Button {
            Task {
                await tryBiometricAuth()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: biometricIconName)
                    .font(.system(size: 24))
                
                Text("Увійти з \(authViewModel.biometricManager.biometricName)")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#4ECDC4"), Color(hex: "#44A08D")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(28)
        }
    }
    
    private var biometricIconName: String {
        switch authViewModel.biometricManager.biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "lock.shield"
        }
    }
    
    private func tryBiometricAuth() async {
        guard authViewModel.biometricManager.isEnabled,
              Auth.auth().currentUser != nil else { return }
        
        let success = await authViewModel.authenticateWithBiometric()
        if success {
            print("✅ Biometric authentication successful")
        }
    }
    
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            await authViewModel.handleAppleAuthorization(authorization)
        case .failure(let error):
            let nsError = error as NSError
            if nsError.code != 1001 { // Не показуємо помилку якщо користувач скасував
                await MainActor.run {
                    authViewModel.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    // MARK: - Helpers
    
    private var backgroundColor: Color {
        localizationManager.isDarkMode ? Color(hex: "#1C1C1E") : Color(hex: "#FFFDF5")
    }
    
    private var accentColor: Color {
        Color(hex: "#4ECDC4")
    }
    
    private var secondaryTextColor: Color {
        localizationManager.isDarkMode ? Color(hex: "#A0A0A0") : Color(hex: "#7F8C8D")
    }
    
    private var subtitleText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Вивчайте англійську легко та ефективно"
        case .polish: return "Ucz się angielskiego łatwo i efektywnie"
        case .english: return "Learn English easily and effectively"
        }
    }
    
    private var privacyText: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Ваші дані захищено. Ми не зберігаємо ваші паролі."
        case .polish: return "Twoje dane są chronione. Nie przechowujemy Twoich haseł."
        case .english: return "Your data is protected. We don't store your passwords."
        }
    }
}
