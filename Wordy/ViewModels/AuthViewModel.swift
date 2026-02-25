//
//  AuthViewModel.swift
//  Wordy
//

import SwiftUI
import FirebaseAuth
import AuthenticationServices
import CryptoKit
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isCheckingAuth = true
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var user: User?
    @Published var appleEmail = ""
    
    var biometricManager = BiometricAuthManager()
    
    private var currentNonce: String?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        isCheckingAuth = true
        if let currentUser = Auth.auth().currentUser {
            self.user = currentUser
            self.isAuthenticated = true
            self.appleEmail = currentUser.email ?? ""
        }
        isCheckingAuth = false
    }
    
    // MARK: - Apple Sign In
    
    func handleAppleAuthorization(_ authorization: ASAuthorization) async {
        isLoading = true
        defer { isLoading = false }
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            errorMessage = "Unable to retrieve Apple ID credentials"
            return
        }
        
        guard let nonce = currentNonce else {
            errorMessage = "Invalid state: A login callback was received, but no login request was sent."
            return
        }
        
        guard let appleIDToken = appleIDCredential.identityToken else {
            errorMessage = "Unable to fetch identity token"
            return
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            errorMessage = "Unable to serialize token string from data"
            return
        }
        
        // 🆕 ВИПРАВЛЕНО: OAuthProvider.appleCredential для iOS 13+
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )
        
        // Зберігаємо email якщо це перший вхід
        if let email = appleIDCredential.email {
            appleEmail = email
        }
        
        do {
            let authResult = try await Auth.auth().signIn(with: credential)
            self.user = authResult.user
            self.isAuthenticated = true
            
            // Зберігаємо email з Firebase якщо ще немає
            if appleEmail.isEmpty {
                appleEmail = authResult.user.email ?? ""
            }
            
            print("✅ Successfully signed in with Apple: \(authResult.user.uid)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Apple Sign In error: \(error.localizedDescription)")
        }
    }
    
    func authenticateWithBiometric() async -> Bool {
        let success = await biometricManager.authenticate()
        if success {
            isAuthenticated = true
        }
        return success
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        isAuthenticated = false
        user = nil
        appleEmail = ""
    }
    
    // MARK: - Nonce Generation
    
    func startSignInWithAppleFlow() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return nonce
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
}
