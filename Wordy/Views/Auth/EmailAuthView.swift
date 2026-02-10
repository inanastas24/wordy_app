//
//  EmailAuthView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 10.02.2026.
//

import SwiftUI

struct EmailAuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    var onComplete: () -> Void
    
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isRegistering = false
    @State private var showResetPassword = false
    @State private var confirmPassword = ""
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Form
                        formSection
                        
                        // Action Button
                        actionButton
                        
                        // Toggle mode
                        toggleModeButton
                        
                        // Forgot password
                        if !isRegistering {
                            forgotPasswordButton
                        }
                        
                        if authViewModel.isLoading {
                            ProgressView()
                                .padding()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(isRegistering ? localizationManager.string(.createAccount) : localizationManager.string(.signIn))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.string(.cancel)) {
                        dismiss()
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
            .sheet(isPresented: $showResetPassword) {
                ResetPasswordView()
                    .environmentObject(authViewModel)
                    .environmentObject(localizationManager)
            }
        }
    }
    
    private func performAction() {
        // Очищаємо email від пробілів та перетворюємо в lowercase
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        print("📝 Email before validation: '\(cleanEmail)'")
        print("📝 Password length: \(password.count)")
        
        // Перевірка email з regex
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: cleanEmail) else {
            authViewModel.errorMessage = localizationManager.currentLanguage == .ukrainian ? "Введіть коректний email адресу" :
                                         localizationManager.currentLanguage == .polish ? "Wprowadź poprawny adres email" :
                                         "Please enter a valid email address"
            return
        }
        
        // Перевірка пароля
        guard password.count >= 6 else {
            authViewModel.errorMessage = localizationManager.currentLanguage == .ukrainian ? "Пароль має бути не менше 6 символів" :
                                         localizationManager.currentLanguage == .polish ? "Hasło musi mieć co najmniej 6 znaków" :
                                         "Password must be at least 6 characters"
            return
        }
        
        // Для реєстрації - додаткові перевірки
        if isRegistering {
            guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else {
                authViewModel.errorMessage = localizationManager.currentLanguage == .ukrainian ? "Введіть ваше ім'я" :
                                             localizationManager.currentLanguage == .polish ? "Wprowadź swoje imię" :
                                             "Please enter your name"
                return
            }
            
            guard password == confirmPassword else {
                authViewModel.errorMessage = localizationManager.currentLanguage == .ukrainian ? "Паролі не співпадають" :
                                             localizationManager.currentLanguage == .polish ? "Hasła nie są identyczne" :
                                             "Passwords do not match"
                return
            }
        }
        
        // Відправка
        Task {
            if isRegistering {
                await authViewModel.signInOrRegisterWithEmail(
                    email: cleanEmail,
                    password: password,
                    displayName: displayName.trimmingCharacters(in: .whitespaces)
                )
            } else {
                await authViewModel.signInOrRegisterWithEmail(
                    email: cleanEmail,
                    password: password
                )
            }
            
            // Перевіряємо результат
            await MainActor.run {
                if authViewModel.isAuthenticated && authViewModel.errorMessage.isEmpty {
                    dismiss()
                    onComplete()
                }
            }
        }
    }
    
    // MARK: - UI Components
    private var backgroundColor: some View {
        Color(UIColor.systemBackground)
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: isRegistering ? "person.badge.plus" : "person.circle")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#4ECDC4"))
            
            Text(isRegistering ? localizationManager.string(.createAccount) : localizationManager.string(.enterAccount))
                .font(.title2.bold())
            
            Text(isRegistering ?
                 localizationManager.string(.enterDetailsForRegistration) :
                 localizationManager.string(.enterEmailAndPassword))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 20)
    }
    
    private var formSection: some View {
        VStack(spacing: 16) {
            // Display Name (тільки для реєстрації)
            if isRegistering {
                CustomTextField(
                    icon: "person",
                    placeholder: localizationManager.string(.yourName),
                    text: $displayName
                )
            }
            
            // Email
            CustomTextField(
                icon: "envelope",
                placeholder: "Email",
                text: $email,
                keyboardType: .emailAddress
            )
            .autocapitalization(.none)
            .textContentType(.emailAddress)
            
            // Password
            CustomTextField(
                icon: "lock",
                placeholder: localizationManager.string(.password),
                text: $password,
                isSecure: true
            )
            .textContentType(isRegistering ? .newPassword : .password)
            
            // Confirm Password (тільки для реєстрації)
            if isRegistering {
                CustomTextField(
                    icon: "lock.shield",
                    placeholder: localizationManager.string(.confirmPassword),
                    text: $confirmPassword,
                    isSecure: true
                )
            }
        }
    }
    
    private var actionButton: some View {
        Button(action: performAction) {
            HStack {
                Text(isRegistering ? localizationManager.string(.register) : localizationManager.string(.signIn))
                    .font(.headline)
                
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.leading, 8)
                }
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
            .shadow(color: Color(hex: "#4ECDC4").opacity(0.4), radius: 10, x: 0, y: 5)
        }
        .disabled(authViewModel.isLoading || !isFormValid)
        .opacity(isFormValid ? 1.0 : 0.6)
    }
    
    private var toggleModeButton: some View {
        Button(action: {
            withAnimation {
                isRegistering.toggle()
                // Clear fields when switching
                password = ""
                confirmPassword = ""
                authViewModel.errorMessage = ""
            }
        }) {
            Text(isRegistering ?
                 localizationManager.string(.alreadyHaveAccount) :
                 localizationManager.string(.noAccountCreate))
                .font(.subheadline)
                .foregroundColor(Color(hex: "#4ECDC4"))
        }
        .padding(.top, 8)
    }
    
    private var forgotPasswordButton: some View {
        Button(action: {
            showResetPassword = true
        }) {
            Text(localizationManager.string(.forgotPassword))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Validation & Actions
    private var isFormValid: Bool {
        if email.isEmpty || password.isEmpty {
            return false
        }
        
        if isRegistering {
            if displayName.isEmpty || confirmPassword.isEmpty {
                return false
            }
            if password != confirmPassword {
                return false
            }
            if password.count < 6 {
                return false
            }
        }
        
        return email.contains("@") && email.contains(".")
    }
}

// MARK: - Custom Text Field
struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Reset Password View
struct ResetPasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(localizationManager.string(.enterYourEmail))) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section {
                    Button(localizationManager.string(.sendResetLink)) {
                        Task {
                            await authViewModel.resetPassword(email: email)
                            dismiss()
                        }
                    }
                    .disabled(email.isEmpty || !email.contains("@"))
                }
            }
            .navigationTitle(localizationManager.string(.resetPassword))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizationManager.string(.cancel)) {
                        dismiss()
                    }
                }
            }
        }
    }
}
