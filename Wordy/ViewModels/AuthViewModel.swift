//1
//  AuthViewModel.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 29.01.2026.
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
    @Published var isAnonymous = true
    @Published var showLoginSheet = false
    
    @Published var errorMessage = ""
    @Published var isLoading = false
    @Published var isCheckingAuth = true
    
    private var currentNonce: String?
    
    init() {
        checkAuthStatus()
    }
    
    // MARK: - Check Auth Status
    private func checkAuthStatus() {
        isCheckingAuth = true
        
        if let currentUser = Auth.auth().currentUser {
            self.user = currentUser
            self.isAuthenticated = true
            self.isAnonymous = currentUser.isAnonymous
            print("✅ Користувач залогінений: \(currentUser.uid), anonymous: \(currentUser.isAnonymous)")
            // Завантажуємо профіль з Firestore
                   Task {
                       await loadProfileFromFirestore()
                   }
                   
                   isCheckingAuth = false
               } else {
            print("❌ Користувач не залогінений")
            self.isAuthenticated = false
            self.isAnonymous = true
            isCheckingAuth = false
        }
        
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
                DispatchQueue.main.async {
                    self?.user = user
                    self?.isAuthenticated = user != nil
                    self?.isAnonymous = user?.isAnonymous ?? true
                    self?.isCheckingAuth = false
                    
                    if let user = user {
                        print("📝 Стан змінився: \(user.uid), anonymous: \(user.isAnonymous)")
                        // Завантажуємо профіль при зміні стану
                        Task {
                            await self?.loadProfileFromFirestore()
                        }
                    } else {
                        print("📝 Стан змінився: вилогінений")
                    }
                }
            }
        }
    
    // MARK: - Anonymous
    func signInAnonymously() async throws {
        let result = try await Auth.auth().signInAnonymously()
        self.user = result.user
        self.isAnonymous = true
        self.isAuthenticated = true
        print("✅ Анонімний вхід: \(result.user.uid)")
    }
    
    // MARK: - Email/Password Sign In
    func signIn(email: String, password: String) async throws {
        // Get anonymous words before signing in
        let anonymousWords = await fetchAnonymousWords()
        
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        self.user = result.user
        self.isAnonymous = false
        self.isAuthenticated = true
        
        // Migrate words to the account
        await migrateWords(anonymousWords, to: result.user.uid)
        
        print("✅ Email вхід: \(result.user.uid)")
    }
    
    // MARK: - Email/Password Sign Up
    func signUp(email: String, password: String, displayName: String? = nil, avatarData: Data? = nil) async {
        isLoading = true
        errorMessage = ""
        
        do {
            // Get anonymous words before signing up
            let anonymousWords = await fetchAnonymousWords()
            
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.user = result.user
            self.isAuthenticated = true
            self.isAnonymous = false
            
            // Підготовка даних профілю
            var profileData: [String: Any] = [
                "email": email,
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ]
            
            // Додаємо ім'я якщо вказано
            if let name = displayName, !name.isEmpty {
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = name
                try await changeRequest.commitChanges()
                
                profileData["displayName"] = name
            }
            
            // Додаємо аватар якщо вказано
            if let avatarData = avatarData {
                let base64String = avatarData.base64EncodedString()
                profileData["avatarURL"] = base64String
            }
            
            // Зберігаємо в Firestore
            try await Firestore.firestore()
                .collection("users")
                .document(result.user.uid)
                .collection("profile")
                .document("main")
                .setData(profileData, merge: true)
            
            print("✅ Профіль створено: \(displayName ?? "без імені")")
            
            // Migrate words to the new account
            await migrateWords(anonymousWords, to: result.user.uid)
            
            print("✅ Реєстрація: \(result.user.uid)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Помилка реєстрації: \(error.localizedDescription)")
        }
        
        isLoading = false
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
                  let nonce = currentNonce else { return }
            
            let credential = OAuthProvider.credential(
                providerID: .apple,
                idToken: tokenString,
                rawNonce: nonce
            )
            
            isLoading = true
            
            // Get anonymous words before linking
            let anonymousWords = await fetchAnonymousWords()
            
            if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous {
                do {
                    let linkedUser = try await currentUser.link(with: credential)
                    self.user = linkedUser.user
                    self.isAnonymous = false
                    
                    // Migrate words to new account
                    await migrateWords(anonymousWords, to: linkedUser.user.uid)
                    
                    if let fullName = appleIDCredential.fullName {
                        await updateUserDisplayName(fullName)
                    }
                    
                } catch let error as NSError {
                    if error.code == AuthErrorCode.credentialAlreadyInUse.rawValue {
                        // Sign in with existing account and merge words
                        try? await signInWithCredentialAndMerge(credential, anonymousWords: anonymousWords)
                    } else {
                        errorMessage = error.localizedDescription
                    }
                }
            } else {
                try? await signInWithCredentialAndMerge(credential, anonymousWords: anonymousWords)
            }
            
            isLoading = false
            
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    private func signInWithCredential(_ credential: AuthCredential) async throws {
        let result = try await Auth.auth().signIn(with: credential)
        self.user = result.user
        self.isAnonymous = false
        self.isAuthenticated = true
    }
    
    private func signInWithCredentialAndMerge(_ credential: AuthCredential, anonymousWords: [SavedWordModel]) async throws {
        let result = try await Auth.auth().signIn(with: credential)
        self.user = result.user
        self.isAnonymous = false
        self.isAuthenticated = true
        
        // Migrate words to existing account
        await migrateWords(anonymousWords, to: result.user.uid)
    }
    
    // MARK: - Fetch Anonymous Words
    private func fetchAnonymousWords() async -> [SavedWordModel] {
        guard let userId = Auth.auth().currentUser?.uid else { return [] }
        
        do {
            let snapshot = try await Firestore.firestore()
                .collection("users")
                .document(userId)
                .collection("words")
                .getDocuments()
            
            return snapshot.documents.compactMap { doc in
                try? doc.data(as: SavedWordModel.self)
            }
        } catch {
            print("❌ Помилка отримання анонімних слів: \(error)")
            return []
        }
    }
    
    // MARK: - Migrate Words
    private func migrateWords(_ words: [SavedWordModel], to newUserId: String) async {
        guard !words.isEmpty else { return }
        
        let db = Firestore.firestore()
        
        for word in words {
            do {
                var wordData = try Firestore.Encoder().encode(word)
                wordData["createdAt"] = Timestamp(date: word.createdAt)
                if let nextReview = word.nextReviewDate {
                    wordData["nextReviewDate"] = Timestamp(date: nextReview)
                }
                if let lastReview = word.lastReviewDate {
                    wordData["lastReviewDate"] = Timestamp(date: lastReview)
                }
                
                try await db.collection("users")
                    .document(newUserId)
                    .collection("words")
                    .addDocument(data: wordData)
                
                print("✅ Мігровано слово: \(word.original)")
            } catch {
                print("❌ Помилка міграції слова \(word.original): \(error)")
            }
        }
        
        // Refresh dictionary
        NotificationCenter.default.post(name: .wordSaved, object: nil)
    }
    
    // MARK: - Update User Display Name
    private func updateUserDisplayName(_ fullName: PersonNameComponents) async {
        let displayName = [fullName.givenName, fullName.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        guard !displayName.isEmpty else { return }
        
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = displayName
        
        do {
            try await changeRequest?.commitChanges()
            self.user = Auth.auth().currentUser
            
            // Save to Firestore
            try? await FirestoreService.shared.updateUserProfile(updates: ["displayName": displayName])
        } catch {
            print("Error updating display name: \(error)")
        }
    }
    
    // MARK: - Upgrade Anonymous
    func upgradeAnonymousToEmail(email: String, password: String) async throws {
        guard let currentUser = Auth.auth().currentUser, currentUser.isAnonymous else {
            throw AuthError.notAnonymous
        }
        
        // Get anonymous words before linking
        let anonymousWords = await fetchAnonymousWords()
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        let result = try await currentUser.link(with: credential)
        self.user = result.user
        self.isAnonymous = false
        
        // Migrate words
        await migrateWords(anonymousWords, to: result.user.uid)
    }
    
    // MARK: - Logout
    func signOut() throws {
        // Очищаємо локальні дані перед виходом
        clearLocalUserData()
        
        try Auth.auth().signOut()
        isAuthenticated = false
        user = nil
        print("✅ Вихід")
    }
    private func clearLocalUserData() {
        // Очищаємо UserDefaults для користувача
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userAvatar")
        // Не очищаємо learningLanguage - це налаштування додатку
        
        print("✅ Локальні дані користувача очищено")
    }
    func loadUserData() async {
        guard let userId = user?.uid else { return }
        
        do {
            let document = try await Firestore.firestore()
                .collection("users")
                .document(userId)
                .collection("profile")
                .document("main")
                .getDocument()
            
            if let data = document.data() {
                // Оновлюємо AppStorage через UserDefaults
                if let displayName = data["displayName"] as? String {
                    UserDefaults.standard.set(displayName, forKey: "userName")
                }
                
                if let avatarURL = data["avatarURL"] as? String {
                    // Якщо це base64
                    if let imageData = Data(base64Encoded: avatarURL) {
                        UserDefaults.standard.set(imageData, forKey: "userAvatar")
                    }
                }
                
                print("✅ Дані користувача завантажено з Firestore")
            }
        } catch {
            print("❌ Помилка завантаження даних: \(error)")
        }
    }
    
    // MARK: - Apple Sign In Helpers
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
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
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
        let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
        return hashString
    }
    
    /// Зберігає профіль в Firestore
    func saveProfileToFirestore(displayName: String? = nil, avatarURL: String? = nil) async {
        guard let userId = user?.uid else { return }
        
        var data: [String: Any] = [
            "updatedAt": Timestamp(date: Date())
        ]
        
        if let name = displayName {
            data["displayName"] = name
        }
        
        if let avatar = avatarURL {
            data["avatarURL"] = avatar
        }
        
        do {
            try await Firestore.firestore()
                .collection("users")
                .document(userId)
                .collection("profile")
                .document("main")
                .setData(data, merge: true)
            
            print("✅ Профіль збережено в Firestore")
        } catch {
            print("❌ Помилка збереження профілю: \(error)")
        }
    }

    /// Завантажує профіль з Firestore
    func loadProfileFromFirestore() async {
        guard let userId = user?.uid else { return }
        
        do {
            let document = try await Firestore.firestore()
                .collection("users")
                .document(userId)
                .collection("profile")
                .document("main")
                .getDocument()
            
            if let data = document.data() {
                // Оновлюємо Auth профіль
                if let displayName = data["displayName"] as? String {
                    await updateAuthProfile(displayName: displayName)
                }
                print("✅ Профіль завантажено з Firestore")
            }
        } catch {
            print("❌ Помилка завантаження профілю: \(error)")
        }
    }

    /// Оновлює профіль в Auth
    private func updateAuthProfile(displayName: String? = nil, photoURL: URL? = nil) async {
        let changeRequest = user?.createProfileChangeRequest()
        changeRequest?.displayName = displayName
        changeRequest?.photoURL = photoURL
        
        do {
            try await changeRequest?.commitChanges()
            // Оновлюємо локальну змінну
            self.user = Auth.auth().currentUser
        } catch {
            print("❌ Помилка оновлення Auth профілю: \(error)")
        }
    }

    // MARK: - Avatar Upload

    /// Завантажує аватар в Firestore як base64
    func uploadAvatar(_ imageData: Data) async -> String? {
        let base64String = imageData.base64EncodedString()
        
        await saveProfileToFirestore(avatarURL: base64String)
        
        return base64String
    }
}
