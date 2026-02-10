//  RegistrationPromptView.swift
//  Wordy
//

import SwiftUI
import AuthenticationServices

struct RegistrationPromptView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    var onComplete: () -> Void
    var onSkip: () -> Void
    
    @State private var showEmailAuth = false
    
    var body: some View {
        ZStack {
            backgroundView
            
            VStack(spacing: 0) {
                Spacer()
                
                iconSection
                textSection
                buttonsSection
                
                Spacer(minLength: 50)
            }
        }
        .sheet(isPresented: $showEmailAuth) {
            EmailAuthView(onComplete: onComplete)
                .environmentObject(authViewModel)
        }
        .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                onComplete()
            }
        }
    }
    
    // MARK: - UI Sections
    private var backgroundView: some View {
        Group {
            if localizationManager.isDarkMode {
                Color(hex: "#1C1C1E").ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [Color(hex: "#FFFDF5"), Color(hex: "#E8F6F3")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
        }
    }
    
    private var iconSection: some View {
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
                        .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
                        .frame(width: 140, height: 140)
                        .shadow(color: Color(hex: "#4ECDC4").opacity(0.3), radius: 20, x: 0, y: 10)
                )
        }
        .padding(.bottom, 40)
    }
    
    private var textSection: some View {
        VStack(spacing: 12) {
            Text(localizationManager.string(.saveProgress))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
            
            Text("☁️")
                .font(.system(size: 24))
            
            Text(localizationManager.string(.saveProgressDescription))
                .font(.system(size: 16))
                .foregroundColor(localizationManager.isDarkMode ? Color.gray.opacity(0.8) : Color(hex: "#7F8C8D"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .padding(.bottom, 50)
    }
    
    private var buttonsSection: some View {
        VStack(spacing: 16) {
            // Apple Sign In
            SignInWithAppleButton(
                .continue,
                onRequest: { request in
                    authViewModel.handleAppleSignIn(request: request)
                },
                onCompletion: { result in
                    Task {
                        await authViewModel.handleAppleSignInCompletion(result: result)
                    }
                }
            )
            .frame(height: 56)
            .cornerRadius(28)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            // Email/Password
            Button {
                showEmailAuth = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 18))
                    Text(localizationManager.string(.emailPassword))
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
           /* Button {
                onSkip()
            } label: {
                VStack(spacing: 4) {
                    Text(localizationManager.string(.continueWithoutRegistration))
                        .font(.system(size: 15))
                        .foregroundColor(localizationManager.isDarkMode ? Color.gray.opacity(0.8) : .secondary)
                    
                    Text("⚠️ " + localizationManager.string(.wordsMayBeLost))
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                }
            }*/
            .padding(.top, 20)
        }
        .padding(.horizontal, 30)
    }
}
