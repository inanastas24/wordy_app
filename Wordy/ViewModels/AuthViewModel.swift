//  AuthViewModel.swift
//  Wordy
//

import FirebaseFirestore
import Combine
import SwiftUI
import FirebaseAuth
import AuthenticationServices
import CryptoKit

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage = ""
    @Published var isLoading = false
    @Published var isCheckingAuth = true
    
    // Дані з Apple
    @Published var appleDisplayName: String = ""
    @Published var appleEmail: String = ""
    
    private var currentNonce: String?
    
    init() {
        checkAuthStatus()
    }
    
    private func checkAuthStatus() {
        isCheckingAuth = true
        
        if let currentUser = Auth.auth().currentUser {
            self.user = currentUser
            self.isAuthenticated = true
            self.appleDisplayName = currentUser.displayName ?? ""
            self.appleEmail = currentUser.email ?? ""
        }
        
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isAuthenticated = user != nil
                self?.isCheckingAuth = false
                
                if let user = user {
                    self?.appleDisplayName = user.displayName ?? ""
                    self?.appleEmail = user.email ?? ""
                }
            }
        }
    }
    
    // MARK: - Apple Sign In
    func handleAppleSignIn(request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }
    
    func handleAppleSignInCompletion(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = appleIDCredential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8),
                  let nonce = currentNonce else {
                errorMessage = "Invalid credentials"
                return
            }
            
            // Зберігаємо дані з Apple (тільки при першій реєстрації)
            if let fullName = appleIDCredential.fullName {
                let displayName = [fullName.givenName, fullName.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                appleDisplayName = displayName
            }
            if let email = appleIDCredential.email {
                appleEmail = email
            }
            
            let credential = OAuthProvider.credential(
                providerID: .apple,
                idToken: tokenString,
                rawNonce: nonce
            )
            
            isLoading = true
            
            do {
                let result = try await Auth.auth().signIn(with: credential)
                self.user = result.user
                self.isAuthenticated = true
                
                // Оновлюємо профіль в Firebase якщо є дані з Apple
                await updateUserProfile(fullName: appleIDCredential.fullName, email: appleIDCredential.email)
                
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isLoading = false
            
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    private func updateUserProfile(fullName: PersonNameComponents?, email: String?) async {
        guard let user = Auth.auth().currentUser else { return }
        
        let displayName = [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        // Оновлюємо тільки якщо ще не встановлено
        if user.displayName?.isEmpty ?? true, !displayName.isEmpty {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try? await changeRequest.commitChanges()
            self.appleDisplayName = displayName
        }
        
        // Зберігаємо в Firestore
        var profileData: [String: Any] = [
            "updatedAt": Timestamp(date: Date())
        ]
        
        if !displayName.isEmpty {
            profileData["displayName"] = displayName
        }
        if let email = email {
            profileData["email"] = email
        }
        
        do {
            try await Firestore.firestore()
                .collection("users")
                .document(user.uid)
                .collection("profile")
                .document("main")
                .setData(profileData, merge: true)
        } catch {
            print("Помилка збереження профілю: \(error)")
        }
    }
    
    // MARK: - Logout
    func signOut() throws {
        try Auth.auth().signOut()
        user = nil
        isAuthenticated = false
        appleDisplayName = ""
        appleEmail = ""
    }
    
    // MARK: - Helpers
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
