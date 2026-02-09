//  LoginView.swift
//  Wordy
//

import SwiftUI
import AuthenticationServices

enum LoginStep {
    case welcome      // Екран з поясненням
    case signIn       // Apple Sign In
}

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var currentStep: LoginStep = .welcome
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        ZStack {
            // Легкий градієнтний фон
            LinearGradient(
                colors: [
                    Color(hex: "#E8F6F3"),
                    Color(hex: "#FFFDF5")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Логотип - завжди видимий
                VStack(spacing: 16) {
                    Text("🫧")
                        .font(.system(size: 80))
                        .opacity(0.9)
                    
                    Text("Wordy")
                        .font(.system(size: 42, weight: .light, design: .rounded))
                        .foregroundColor(Color(hex: "#2C3E50"))
                }
                
                Spacer()
                
                // Контент залежно від кроку
                VStack(spacing: 30) {
                    switch currentStep {
                    case .welcome:
                        welcomeContent
                    case .signIn:
                        signInContent
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                Spacer()
            }
        }
        .alert("Помилка", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Сталася помилка")
        }
    }
    
    // MARK: - Екран привітання
    private var welcomeContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("Ласкаво просимо!")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color(hex: "#2C3E50"))
                
                Text("Щоб зберегти ваш прогрес та\nсинхронізувати слова між пристроями,\nпотрібно увійти в акаунт")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(Color(hex: "#7F8C8D"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Переваги
            HStack(spacing: 20) {
                BenefitItem(icon: "icloud", text: "Збереження\nв хмарі")
                BenefitItem(icon: "iphone", text: "Синхронізація\nпристроїв")
                BenefitItem(icon: "lock.shield", text: "Безпека\nданих")
            }
            
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    currentStep = .signIn
                }
            } label: {
                HStack(spacing: 8) {
                    Text("Продовжити")
                        .font(.system(size: 18, weight: .medium))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#4ECDC4"), Color(hex: "#44A08D")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(27)
                .shadow(color: Color(hex: "#4ECDC4").opacity(0.3), radius: 12, x: 0, y: 6)
            }
        }
    }
    
    // MARK: - Екран входу
    private var signInContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Увійдіть через Apple")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(hex: "#2C3E50"))
                
                Text("Швидко, безпечно та без паролів")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(Color(hex: "#7F8C8D"))
            }
            
            VStack(spacing: 16) {
                SignInWithAppleButton(.signIn) { request in
                    authViewModel.handleAppleSignIn(request: request)
                } onCompletion: { result in
                    handleAppleSignIn(result: result)
                }
                .frame(height: 50)
                .cornerRadius(25)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(Color(hex: "#4ECDC4"))
                }
            }
            
            // Кнопка назад
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    currentStep = .welcome
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 12))
                    Text("Назад")
                        .font(.system(size: 14))
                }
                .foregroundColor(Color(hex: "#7F8C8D"))
            }
            .padding(.top, 10)
        }
    }
    
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        isLoading = true
        
        Task {
            await authViewModel.handleAppleSignInCompletion(result: result)
            
            await MainActor.run {
                isLoading = false
                if !authViewModel.errorMessage.isEmpty {
                    errorMessage = authViewModel.errorMessage
                    showError = true
                }
            }
        }
    }
}

// MARK: - Компонент переваги
struct BenefitItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "#4ECDC4"))
            
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#7F8C8D"))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .frame(width: 70)
    }
}
