//1
//  LoginPromptView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 04.02.2026.
//

import SwiftUI
import FirebaseAuth
import AuthenticationServices

struct LoginPromptView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localizationManager: LocalizationManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @State private var showEmailRegistration = false
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            // Dynamic background based on dark mode
            Group {
                if localizationManager.isDarkMode {
                    Color(hex: "#1C1C1E")
                        .ignoresSafeArea()
                } else {
                    LinearGradient(
                        colors: [Color(hex: "#FFFDF5"), Color(hex: "#E8F6F3")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
            }
            
            VStack(spacing: 0) {
                Spacer()
                
                ZStack {
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(Color(hex: "#4ECDC4").opacity(0.3), lineWidth: 2)
                            .frame(width: 120 + CGFloat(i * 40), height: 120 + CGFloat(i * 40))
                            .scaleEffect(1 + CGFloat(i) * 0.1)
                    }
                    
                    Image(systemName: "icloud.and.arrow.up.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 140, height: 140)
                                .shadow(color: Color(hex: "#4ECDC4").opacity(0.3), radius: 20, x: 0, y: 10)
                        )
                }
                .padding(.bottom, 40)
                
                VStack(spacing: 12) {
                    Text(localizationManager.string(.saveProgress))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                        .multilineTextAlignment(.center)
                    
                    Text("☁️")
                        .font(.system(size: 24))
                    
                    // Підзаголовок з кращим контрастом
                    Text(localizationManager.currentLanguage == .ukrainian ?
                            "Увійдіть, щоб ваші слова не загубилися при зміні телефона або перевстановленні додатка" :
                            localizationManager.currentLanguage == .polish ?
                            "Zaloguj się, aby Twoje słowa nie zginęły przy zmianie telefonu lub reinstalacji aplikacji" :
                            "Sign in to prevent losing your words when changing phones or reinstalling the app")
                        .font(.system(size: 16))
                        .foregroundColor(localizationManager.isDarkMode ? Color.gray.opacity(0.8) : Color(hex: "#7F8C8D"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .padding(.bottom, 50)
                
                VStack(spacing: 16) {
                    // Apple Sign In з перекладом
                    Button {
                        // Apple Sign In через UIKit представлення
                        showAppleSignIn()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 20, weight: .semibold))
                            Text(localizationManager.currentLanguage == .ukrainian ? "Продовжити з Apple" :
                                 localizationManager.currentLanguage == .polish ? "Kontynuuj z Apple" :
                                 "Continue with Apple")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.black)
                        .cornerRadius(28)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    // Email
                    Button {
                        showEmailRegistration = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 18))
                            Text(localizationManager.string(.continue) + " Email")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#2C3E50"), Color(hex: "#34495E")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                        .shadow(color: Color(hex: "#2C3E50").opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    
                    // Skip
                    // Skip
                    Button {
                        skipLogin()
                    } label: {
                        VStack(spacing: 4) {
                            Text(localizationManager.currentLanguage == .ukrainian ? "Продовжити без реєстрації" :
                                 localizationManager.currentLanguage == .polish ? "Kontynuuj bez reєстрації" :
                                 "Continue without registration")
                                .font(.system(size: 15))
                                .foregroundColor(localizationManager.isDarkMode ? Color.gray.opacity(0.8) : Color(hex: "#7F8C8D"))
                            
                            Text("⚠️ " + (localizationManager.currentLanguage == .ukrainian ? "Ваші слова можуть загубитися" :
                                 localizationManager.currentLanguage == .polish ? "Twoje słowa mogą zginąć" :
                                 "Your words may be lost"))
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 30)
                
                Spacer(minLength: 50)
            }
        }
        .sheet(isPresented: $showEmailRegistration) {
            EmailRegistrationPromptView(onComplete: {
                completeOnboarding()
            })
            .environmentObject(authViewModel)
        }
    }
    
    private func skipLogin() {
        Task {
            do {
                try await authViewModel.signInAnonymously()
                completeOnboarding()
            } catch {
                print("Помилка анонімного входу: \(error)")
            }
        }
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }
    
    // MARK: - Apple Sign In
    private func showAppleSignIn() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = AppleSignInDelegate.shared
        controller.presentationContextProvider = AppleSignInDelegate.shared
        controller.performRequests()
    }
    
    // MARK: - Apple Sign In Delegate
    class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        static let shared = AppleSignInDelegate()
        
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            return UIApplication.shared.windows.first!
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            // Обробка успішного входу - тут потрібно викликати ваш AuthViewModel
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Передайте credential в AuthViewModel
                NotificationCenter.default.post(name: .init("AppleSignInSuccess"), object: appleIDCredential)
            }
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            print("Apple Sign In failed: \(error.localizedDescription)")
        }
    }
}
