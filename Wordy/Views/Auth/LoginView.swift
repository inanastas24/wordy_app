//  LoginView.swift
//  Wordy
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
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
                
                // Логотип - мінімалістичний
                VStack(spacing: 16) {
                    Text("🫧")
                        .font(.system(size: 80))
                        .opacity(0.9)
                    
                    Text("Wordy")
                        .font(.system(size: 42, weight: .light, design: .rounded))
                        .foregroundColor(Color(hex: "#2C3E50"))
                    
                    Text("Вивчай мови з легкістю")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(Color(hex: "#7F8C8D"))
                }
                
                Spacer()
                Spacer()
                
                // Тільки Apple Sign In
                VStack(spacing: 20) {
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
                .padding(.horizontal, 40)
                
                Spacer(minLength: 60)
            }
        }
        .alert("Помилка", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Сталася помилка")
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
