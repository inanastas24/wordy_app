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
class AuthViewModel: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage = ""
    @Published var isLoading = false
    @Published var isCheckingAuth = true
    
    @Published var appleDisplayName: String = ""
    @Published var appleEmail: String = ""
    
    private var currentNonce: String?
    private var pendingAppleCredential: AuthCredential?
    
    // MARK: - Simulator Check
    var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    override init() {
        super.init()
        checkAuthStatus()
    }
    
    // MARK: - Presentation Context
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
    
    private func checkAuthStatus() {
        isCheckingAuth = true
        
        if let currentUser = Auth.auth().currentUser {
            self.user = currentUser
            self.isAuthenticated = true
            self.appleDisplayName = currentUser.displayName ?? ""
            self.appleEmail = currentUser.email ?? ""
            print("✅ User already signed in: \(currentUser.uid)")
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
    
    // MARK: - Email/Password Authentication
    
    /// Реєстрація або вхід через email/password
    /// Якщо email не існує - створює акаунт
    /// Якщо email існує - перевіряє пароль і входить
    func signInOrRegisterWithEmail(email: String, password: String, displayName: String? = nil) async {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        guard !cleanEmail.isEmpty else {
            await MainActor.run {
                isLoading = false
                errorMessage = "Email не може бути порожнім"
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }
        
        // СПОЧАТКУ пробуємо створити користувача (реєстрація)
        do {
            print("📝 Trying to CREATE user...")
            let result = try await Auth.auth().createUser(withEmail: cleanEmail, password: password)
            print("✅ User created: \(result.user.uid)")
            
            // Оновлюємо display name
            if let displayName = displayName, !displayName.isEmpty {
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try? await changeRequest.commitChanges()
            }
            
            await handleSuccessfulAuth(result: result, isNewUser: true)
            await saveUserProfileToFirestore(uid: result.user.uid, email: cleanEmail, displayName: displayName)
            
        } catch let error as NSError {
            print("❌ Create user error: \(error.localizedDescription)")
            print("   Error code: \(error.code)")
            
            // Якщо користувач вже існує — пробуємо увійти
            if error.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                print("📝 User exists, trying to sign in...")
                await signInExistingUser(email: cleanEmail, password: password)
            } else {
                await handleAuthError(error)
            }
        }
    }

    private func signInExistingUser(email: String, password: String) async {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            print("✅ Signed in: \(result.user.uid)")
            await handleSuccessfulAuth(result: result, isNewUser: false)
        } catch let error as NSError {
            print("❌ Sign in error: \(error.localizedDescription)")
            await handleAuthError(error)
        }
    }
    
    /// Чиста реєстрація (використовується коли точно знаємо що користувача немає)
    private func registerWithEmail(email: String, password: String, displayName: String?) async {
        print("📝 === REGISTER DEBUG ===")
        print("   Email for registration: '\(email)'")
        
        do {
            print("   Creating user...")
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            print("   ✅ User created: \(result.user.uid)")
            
            // Оновлюємо display name
            if let displayName = displayName, !displayName.isEmpty {
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try? await changeRequest.commitChanges()
            }
            
            await handleSuccessfulAuth(result: result, isNewUser: true)
            await saveUserProfileToFirestore(uid: result.user.uid, email: email, displayName: displayName)
            
        } catch let error as NSError {
            print("❌ Registration failed: \(error.localizedDescription)")
            print("   Error code: \(error.code)")
            
            // Специфічна обробка помилок реєстрації
            if error.code == AuthErrorCode.invalidEmail.rawValue {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Невірний формат email адреси"
                }
            } else if error.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Цей email вже використовується"
                }
            } else if error.code == AuthErrorCode.weakPassword.rawValue {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Пароль занадто простий (мінімум 6 символів)"
                }
            } else {
                await handleAuthError(error)
            }
        }
    }
    
    /// Скидання пароля
    func resetPassword(email: String) async {
        await MainActor.run { isLoading = true }
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            await MainActor.run {
                isLoading = false
                errorMessage = "Посилання для скидання пароля надіслано на \(email)"
            }
        } catch {
            await handleAuthError(error as NSError)
        }
    }
    
    /// Оновлення пароля (для залогіненого користувача)
    func updatePassword(currentPassword: String, newPassword: String) async {
        guard let user = Auth.auth().currentUser, let email = user.email else {
            errorMessage = "Користувач не авторизований"
            return
        }
        
        await MainActor.run { isLoading = true }
        
        do {
            // Реаутентифікація
            let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
            try await user.reauthenticate(with: credential)
            
            // Оновлення пароля
            try await user.updatePassword(to: newPassword)
            
            await MainActor.run {
                isLoading = false
                errorMessage = "Пароль успішно оновлено"
            }
        } catch {
            await handleAuthError(error as NSError)
        }
    }
    
    // MARK: - Apple Sign In
    
    func signInWithApple() {
        print("🔍 Bundle ID: \(Bundle.main.bundleIdentifier ?? "nil")")
        print("🔍 Is Simulator: \(isSimulator)")
        
        if isSimulator {
            print("⚠️ WARNING: Running on Simulator. Apple Sign In may not work properly.")
        }
        
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        
        print("🍎 Starting Apple Sign In...")
        print("🔐 Nonce generated: \(nonce.prefix(15))...")
        
        authorizationController.performRequests()
    }
    
    func handleAppleSignIn(request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        print("🔐 SignInWithAppleButton nonce generated: \(nonce.prefix(10))...")
    }
    
    func handleAppleSignInCompletion(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            await handleAppleAuthorization(authorization)
        case .failure(let error):
            let nsError = error as NSError
            if nsError.code != 1001 {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
            print("❌ Apple Sign In failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - ASAuthorizationControllerDelegate
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("✅ Apple authorization completed")
        
        Task {
            await handleAppleAuthorization(authorization)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let nsError = error as NSError
        print("❌ Apple Sign In Error: \(error.localizedDescription)")
        print("❌ Error Code: \(nsError.code)")
        
        DispatchQueue.main.async {
            self.isLoading = false
            
            if nsError.code == 1001 {
                print("ℹ️ User cancelled sign in")
                return
            }
            
            if nsError.code == 1000 && self.isSimulator {
                self.errorMessage = "Apple Sign In не працює на симуляторі. Використовуйте email вхід."
            } else {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Account Linking (Об'єднання акаунтів)
    
    /// Обробка Apple авторизації з підтримкою об'єднання акаунтів
    private func handleAppleAuthorization(_ authorization: ASAuthorization) async {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = appleIDCredential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8),
              let nonce = currentNonce else {
            await setError("Invalid Apple credentials")
            return
        }
        
        let credential = OAuthProvider.credential(
            providerID: .apple,
            idToken: tokenString,
            rawNonce: nonce
        )
        
        // Зберігаємо дані з Apple
        let appleEmail = appleIDCredential.email
        let appleName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        await MainActor.run { isLoading = true }
        
        do {
            // Пробуємо увійти через Apple
            let result = try await Auth.auth().signIn(with: credential)
            await handleSuccessfulAuth(result: result, isNewUser: false)
            print("✅ Apple Sign In successful: \(result.user.uid)")
            
        } catch let error as NSError {
            // Якщо акаунт існує з іншим credential - об'єднуємо
            if error.code == AuthErrorCode.accountExistsWithDifferentCredential.rawValue,
               let email = appleEmail {
                await linkAppleToExistingAccount(email: email, appleCredential: credential, displayName: appleName)
            } else {
                await handleAuthError(error)
            }
        }
        
        currentNonce = nil
    }
    
    /// Об'єднання Apple ID з існуючим email акаунтом
    private func linkAppleToExistingAccount(email: String, appleCredential: AuthCredential, displayName: String) async {
        print("🔗 Account exists with different credential. Attempting to link...")
        
        do {
            // Отримуємо методи входу для цього email
            let methods = try await Auth.auth().fetchSignInMethods(forEmail: email)
            print("📋 Existing sign in methods: \(methods ?? [])")
            
            // Якщо є email/password - просимо користувача увійти спочатку через email
            if methods.contains("password") == true {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Акаунт з email \(email) вже існує. Спочатку увійдіть через email та пароль, потім додайте Apple Sign In в налаштуваннях профілю."
                }
                return
            }
            
            // Якщо інший метод - показуємо загальну помилку
            await MainActor.run {
                isLoading = false
                errorMessage = "Акаунт з цим email вже існує з іншим способом входу."
            }
            
        } catch {
            await handleAuthError(error as NSError)
        }
    }
    
    /// Прив'язка Apple ID до поточного залогіненого користувача (для налаштувань)
    func linkAppleIDToCurrentUser() async {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "Спочатку увійдіть в акаунт"
            return
        }
        
        // Це викликається з окремого flow для прив'язки
        // Потрібно реалізувати окремо якщо потрібно
        print("🔗 Linking Apple ID to user: \(user.uid)")
    }
    
    // MARK: - Helper Methods
    
    private func handleSuccessfulAuth(result: AuthDataResult, isNewUser: Bool) async {
        await MainActor.run {
            self.user = result.user
            self.isAuthenticated = true
            self.isLoading = false
        }
        
        // Завантажуємо або створюємо профіль
        await loadOrCreateUserProfile(uid: result.user.uid, email: result.user.email, isNewUser: isNewUser)
    }
    
    private func handleAuthError(_ error: NSError) async {
        await MainActor.run {
            isLoading = false
            
            switch error.code {
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                errorMessage = "Цей email вже використовується"
            case AuthErrorCode.invalidEmail.rawValue:
                errorMessage = "Невірний формат email"
            case AuthErrorCode.weakPassword.rawValue:
                errorMessage = "Пароль занадто простий (мінімум 6 символів)"
            case AuthErrorCode.wrongPassword.rawValue:
                errorMessage = "Невірний пароль"
            case AuthErrorCode.userNotFound.rawValue:
                errorMessage = "Користувача не знайдено"
            case AuthErrorCode.accountExistsWithDifferentCredential.rawValue:
                errorMessage = "Акаунт існує з іншим способом входу"
            default:
                errorMessage = error.localizedDescription
            }
            
            print("❌ Auth Error: \(error.localizedDescription) (Code: \(error.code))")
        }
    }
    
    private func setError(_ message: String) async {
        await MainActor.run {
            errorMessage = message
            isLoading = false
        }
        print("❌ \(message)")
    }
    
    
    
    // MARK: - Firestore Operations
    
    private func saveUserProfileToFirestore(uid: String, email: String?, displayName: String?) async {
        let profileData: [String: Any] = [
            "uid": uid,
            "email": email ?? "",
            "displayName": displayName ?? "",
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date()),
            "appLanguage": LocalizationManager.shared.currentLanguage.rawValue,
            "isDarkMode": LocalizationManager.shared.isDarkMode,
            "authProviders": ["email"]
        ]
        
        do {
            try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .collection("profile")
                .document("main")
                .setData(profileData)
            print("✅ User profile saved to Firestore")
        } catch {
            print("⚠️ Failed to save profile: \(error)")
        }
    }
    
    private func loadOrCreateUserProfile(uid: String, email: String?, isNewUser: Bool) async {
        let docRef = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("profile")
            .document("main")
        
        do {
            let document = try await docRef.getDocument()
            
            if document.exists {
                // Оновлюємо останній вхід
                try await docRef.updateData([
                    "lastLoginAt": Timestamp(date: Date()),
                    "updatedAt": Timestamp(date: Date())
                ])
                print("✅ Updated last login")
            } else if isNewUser {
                // Створюємо новий профіль
                let providerID = Auth.auth().currentUser?.providerData.first?.providerID ?? "unknown"
                
                let profileData: [String: Any] = [
                    "uid": uid,
                    "email": email ?? "",
                    "displayName": user?.displayName ?? "",
                    "createdAt": Timestamp(date: Date()),
                    "updatedAt": Timestamp(date: Date()),
                    "lastLoginAt": Timestamp(date: Date()),
                    "appLanguage": LocalizationManager.shared.currentLanguage.rawValue,
                    "isDarkMode": LocalizationManager.shared.isDarkMode,
                    "authProviders": [providerID]
                ]
                try await docRef.setData(profileData)
                print("✅ Created new user profile")
            }
        } catch {
            print("⚠️ Firestore error: \(error)")
        }
    }
    
    // MARK: - Logout
    func signOut() throws {
        try Auth.auth().signOut()
        user = nil
        isAuthenticated = false
        appleDisplayName = ""
        appleEmail = ""
        currentNonce = nil
        pendingAppleCredential = nil
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
    
    // Додайте цей метод в клас AuthViewModel:

    func signInAnonymouslyForTesting() async {
        await MainActor.run { isLoading = true }
        
        do {
            let result = try await Auth.auth().signInAnonymously()
            await MainActor.run {
                self.user = result.user
                self.isAuthenticated = true
                self.isLoading = false
                print("✅ Anonymous sign in successful (TESTING): \(result.user.uid)")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
