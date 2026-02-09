//1
//  EmailRegistrationPromptView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 02.02.2026.
//

import SwiftUI
import FirebaseAuth

struct EmailRegistrationPromptView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var onComplete: () -> Void
    
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var isLoginMode = false
    
    private var localization: LocalizationManager { LocalizationManager.shared }
    
    // Валідація email
    private var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: trimmed)
    }
    
    private var isPasswordValid: Bool {
        password.count >= 6
    }
    
    var body: some View {
        ZStack {
            Color(hex: "#FFFDF5").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Скасувати") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#4ECDC4"))
                    
                    Spacer()
                    
                    Text(isLoginMode ? localization.string(.login) : localization.string(.register))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "#2C3E50")) // Темний колір для заголовка
                    
                    Spacer()
                    
                    Text("Скасувати")
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Іконка
                        Image(systemName: isLoginMode ? "person.circle.fill" : "envelope.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Color(hex: "#4ECDC4"))
                            .padding(.top, 20)
                        
                        // Заголовок
                        VStack(spacing: 8) {
                            Text(isLoginMode ? localization.string(.welcomeBack) : localization.string(.createAccount))
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#2C3E50")) // Темний колір
                            
                            Text(isLoginMode ? localization.string(.signInToContinue) : "Збережіть свій прогрес")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "#7F8C8D")) // Сірий колір для підзаголовка
                        }
                        
                        // Форма
                        VStack(spacing: 20) {
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "#2C3E50")) // Темний колір для лейбла
                                    .padding(.leading, 4)
                                
                                TextField("your@email.com", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .foregroundColor(Color(hex: "#2C3E50")) // ТЕМНИЙ колір для тексту інпуту
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white)
                                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(email.isEmpty ? Color.clear : (isEmailValid ? Color(hex: "#4ECDC4") : Color.red), lineWidth: 2)
                                    )
                                    .onChange(of: email) { _ in
                                        errorMessage = ""
                                    }
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text(localization.string(.password))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "#2C3E50")) // Темний колір для лейбла
                                    .padding(.leading, 4)
                                
                                SecureField(localization.string(.password), text: $password)
                                    .textContentType(.newPassword)
                                    .foregroundColor(Color(hex: "#2C3E50")) // ТЕМНИЙ колір для тексту інпуту
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white)
                                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(password.isEmpty ? Color.clear : (isPasswordValid ? Color(hex: "#4ECDC4") : Color.orange), lineWidth: 2)
                                    )
                            }
                            
                            // Error message
                            if !errorMessage.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text(errorMessage)
                                        .font(.system(size: 14))
                                        .foregroundColor(.red)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red.opacity(0.1))
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 30)
                        
                        // Кнопка дії
                        Button(action: authenticate) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(isLoginMode ? localization.string(.login) : localization.string(.register))
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(isEmailValid && isPasswordValid ? Color(hex: "#4ECDC4") : Color.gray)
                            )
                            .shadow(color: isEmailValid && isPasswordValid ? Color(hex: "#4ECDC4").opacity(0.3) : Color.clear, radius: 10, x: 0, y: 5)
                        }
                        .disabled(!isEmailValid || !isPasswordValid || isLoading)
                        .padding(.horizontal, 20)
                        
                        // Перемикач між режимами
                        Button {
                            isLoginMode.toggle()
                            errorMessage = ""
                        } label: {
                            Text(isLoginMode ? localization.string(.createAccount) : localization.string(.alreadyHaveAccount))
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "#4ECDC4"))
                        }
                        .padding(.top, 10)
                        
                        // Підказка
                        Text("Натискаючи, ви погоджуєтесь з умовами використання")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#7F8C8D")) // Сірий колір
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.top, 20)
                    }
                }
            }
        }
    }
    
    private func authenticate() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Введіть email"
            return
        }
        
        guard isEmailValid else {
            errorMessage = "Неправильний формат email"
            return
        }
        
        guard isPasswordValid else {
            errorMessage = "Пароль має бути мінімум 6 символів"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                if isLoginMode {
                    try await authViewModel.signIn(email: trimmedEmail, password: password)
                } else {
                    try await authViewModel.upgradeAnonymousToEmail(email: trimmedEmail, password: password)
                }
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                    onComplete()
                }
            } catch let error as NSError {
                await MainActor.run {
                    isLoading = false
                    handleError(error)
                }
            }
        }
    }
    
    private func handleError(_ error: NSError) {
        switch error.code {
        case AuthErrorCode.invalidEmail.rawValue:
            errorMessage = "Неправильний формат email"
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            errorMessage = "Цей email вже використовується"
            isLoginMode = true
        case AuthErrorCode.weakPassword.rawValue:
            errorMessage = "Пароль занадто слабкий"
        case AuthErrorCode.userNotFound.rawValue:
            errorMessage = "Користувача не знайдено"
            isLoginMode = false
        case AuthErrorCode.wrongPassword.rawValue:
            errorMessage = "Неправильний пароль"
        case AuthErrorCode.invalidCredential.rawValue:
            errorMessage = "Неправильні облікові дані"
        default:
            errorMessage = error.localizedDescription
        }
    }
}
