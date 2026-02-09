//1
//  UserProfileViewModel.swift
//  Wordy
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class UserProfileViewModel: ObservableObject {
    static let shared = UserProfileViewModel()
    
    @Published var displayName: String = ""
    @Published var avatarImage: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    private init() {
        setupAuthListener()
        displayName = UserDefaults.standard.string(forKey: "userName") ?? ""
        loadAvatarFromUserDefaults()
    }
    
    private func setupAuthListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if user != nil {
                    await self?.fetchProfile()
                } else {
                    self?.displayName = ""
                    self?.avatarImage = nil
                }
            }
        }
    }
    
    func fetchProfile() async {
        guard Auth.auth().currentUser?.uid != nil else { return }
        
        do {
            if let profile = try await FirestoreService.shared.fetchUserProfile() {
                if let name = profile.displayName, !name.isEmpty {
                    displayName = name
                    UserDefaults.standard.set(name, forKey: "userName")
                }
                
                if let avatarURL = profile.avatarURL, !avatarURL.isEmpty {
                    await loadAvatar(from: avatarURL)
                }
            }
        } catch {
            print("Error fetching profile: \(error)")
        }
    }
    
    func loadProfile() {
        Task {
            await fetchProfile()
        }
    }
    
    private func loadAvatarFromUserDefaults() {
        if let avatarData = UserDefaults.standard.data(forKey: "userAvatar"),
           let image = UIImage(data: avatarData) {
            avatarImage = image
        }
    }
    
    private func loadAvatar(from base64String: String) async {
        guard let data = Data(base64Encoded: base64String),
              let image = UIImage(data: data) else {
            return
        }
        
        await MainActor.run {
            self.avatarImage = image
            UserDefaults.standard.set(data, forKey: "userAvatar")
        }
    }
    
    func updateDisplayName(_ name: String) async {
        guard !name.isEmpty else { return }
        
        do {
            try await FirestoreService.shared.updateUserProfile(updates: ["displayName": name])
            
            await MainActor.run {
                self.displayName = name
                UserDefaults.standard.set(name, forKey: "userName")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func uploadAvatar(_ image: UIImage) async {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            await MainActor.run {
                self.errorMessage = "Failed to process image"
            }
            return
        }
        
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            let base64String = imageData.base64EncodedString()
            try await FirestoreService.shared.updateUserProfile(updates: ["avatarURL": base64String])
            
            await MainActor.run {
                self.avatarImage = image
                UserDefaults.standard.set(imageData, forKey: "userAvatar")
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func updateAppLanguage(_ language: String) async {
        do {
            try await FirestoreService.shared.updateUserProfile(updates: ["appLanguage": language])
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func updateDarkMode(_ isDarkMode: Bool) async {
        do {
            try await FirestoreService.shared.updateUserProfile(updates: ["isDarkMode": isDarkMode])
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func updateAvatarURL(_ url: String) async {
        do {
            try await FirestoreService.shared.updateUserProfile(updates: ["avatarURL": url])
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func updateLearningLanguage(_ language: String) async {
        do {
            try await FirestoreService.shared.updateUserProfile(updates: ["learningLanguage": language])
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
}
