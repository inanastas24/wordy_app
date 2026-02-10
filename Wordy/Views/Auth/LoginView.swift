//  LoginView.swift (ВИПРАВЛЕНИЙ)
//

import SwiftUI
import AuthenticationServices

enum LoginStep: Equatable {
    case welcome
    case signIn
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
                VStack(spacing: 16) {
                    Text("🫧")
                        .font(.system(size: 80))
                        .opacity(0.9)
                    
                    Text("Wordy")
                        .font(.system(size: 42, weight: .light, design: .rounded))
                        .foregroundColor(Color(hex: "#2C3E50"))
                }
                .padding(.top, 100)
                
                Spacer()
                
                Group {
                    switch currentStep {
                    case .welcome:
                        welcomeView
                    case .signIn:
                        signInView
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: currentStep)
                
                Spacer()
                Spacer()
            }
        }
        .alert("Помилка", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Сталася помилка")
        }
        .onChange(of: authViewModel.errorMessage) { _, newValue in
            if !newValue.isEmpty {
                errorMessage = newValue
                showError = true
                // Скидаємо помилку після показу
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    authViewModel.errorMessage = ""
                }
            }
        }
    }
    
    private var welcomeView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Text("Ласкаво просимо!")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(Color(hex: "#2C3E50"))
                
                Text("Збережіть свій прогрес та\nвивчайте мови ефективно")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#7F8C8D"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            HStack(spacing: 24) {
                BenefitView(
                    icon: "icloud.fill",
                    title: "Хмара",
                    description: "Збереження слів"
                )
                
                BenefitView(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Синхронізація",
                    description: "На всіх пристроях"
                )
                
                BenefitView(
                    icon: "lock.shield.fill",
                    title: "Безпека",
                    description: "Apple ID"
                )
            }
            
            Button(action: goToSignIn) {
                HStack(spacing: 8) {
                    Text("Продовжити")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(hex: "#4ECDC4"))
                .cornerRadius(28)
                .shadow(
                    color: Color(hex: "#4ECDC4").opacity(0.4),
                    radius: 12,
                    x: 0,
                    y: 6
                )
            }
            .padding(.horizontal, 40)
        }
        .padding(.horizontal, 20)
    }
    
    private var signInView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Text("Увійдіть через Apple")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(hex: "#2C3E50"))
                
                Text("Швидко, безпечно та без паролів")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "#7F8C8D"))
            }
            
            VStack(spacing: 20) {
                // 🔥 НОВЕ: Кастомна кнопка Apple Sign In
                AppleSignInButton {
                    authViewModel.signInWithApple()
                }
                .frame(height: 56)
                .disabled(authViewModel.isLoading)
                
                if authViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(Color(hex: "#4ECDC4"))
                }
            }
            .padding(.horizontal, 40)
            
            Button(action: goBack) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    
                    Text("Назад")
                        .font(.system(size: 15))
                }
                .foregroundColor(Color(hex: "#7F8C8D"))
            }
            .padding(.top, 10)
            .disabled(authViewModel.isLoading)
        }
    }
    
    private func goToSignIn() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .signIn
        }
    }
    
    private func goBack() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .welcome
        }
    }
}

// MARK: - Кастомна кнопка Apple Sign In
struct AppleSignInButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 20, weight: .semibold))
                
                Text("Увійти через Apple")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.black)
            .cornerRadius(28)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BenefitView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(Color(hex: "#4ECDC4"))
            
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "#2C3E50"))
            
            Text(description)
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#7F8C8D"))
                .multilineTextAlignment(.center)
        }
        .frame(width: 90)
    }
}
