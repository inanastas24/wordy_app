//1
//  UserProfileViewModel.swift
//  Wordy
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine
import UIKit

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
        if Auth.auth().currentUser != nil {
            loadProfile()
        }
    }
    
    private func setupAuthListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if user != nil {
                    await self?.fetchProfile()
                } else {
                    self?.displayName = ""
                    self?.avatarImage = nil
                    UserDefaults.standard.removeObject(forKey: "userName")
                    UserDefaults.standard.removeObject(forKey: "userAvatar")
                }
            }
        }
    }
    
    func fetchProfile() async {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        do {
            if let profile = try await FirestoreService.shared.fetchUserProfile() {
                let trimmedName = profile.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let fallbackName = currentUser.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let resolvedName = trimmedName.isEmpty ? fallbackName : trimmedName
                displayName = resolvedName
                UserDefaults.standard.set(resolvedName, forKey: "userName")
                
                if let avatarURL = profile.avatarURL, !avatarURL.isEmpty {
                    await loadAvatar(from: avatarURL)
                } else if let authPhotoURL = currentUser.photoURL?.absoluteString, !authPhotoURL.isEmpty {
                    await loadAvatar(from: authPhotoURL)
                } else {
                    avatarImage = nil
                    UserDefaults.standard.removeObject(forKey: "userAvatar")
                }
            } else {
                let fallbackName = currentUser.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                displayName = fallbackName
                UserDefaults.standard.set(fallbackName, forKey: "userName")
                if let authPhotoURL = currentUser.photoURL?.absoluteString, !authPhotoURL.isEmpty {
                    await loadAvatar(from: authPhotoURL)
                } else {
                    avatarImage = nil
                    UserDefaults.standard.removeObject(forKey: "userAvatar")
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
        if let data = Data(base64Encoded: base64String),
           let image = UIImage(data: data) {
            await MainActor.run {
                self.avatarImage = image
                UserDefaults.standard.set(data, forKey: "userAvatar")
            }
            return
        }

        do {
            if let image = try await StorageService.shared.downloadAvatar(from: base64String),
               let imageData = image.jpegData(compressionQuality: 0.8) {
                await MainActor.run {
                    self.avatarImage = image
                    UserDefaults.standard.set(imageData, forKey: "userAvatar")
                }
            }
        } catch {
            print("Error loading avatar image: \(error)")
        }
    }
    
    func updateDisplayName(_ name: String) async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        do {
            try await FirestoreService.shared.updateUserProfile(updates: ["displayName": trimmedName])
            let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
            changeRequest?.displayName = trimmedName
            try await changeRequest?.commitChanges()
            
            await MainActor.run {
                self.displayName = trimmedName
                UserDefaults.standard.set(trimmedName, forKey: "userName")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func uploadAvatar(_ image: UIImage) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            await MainActor.run {
                self.errorMessage = "User not found"
            }
            return
        }

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
            let avatarURL: String

            do {
                avatarURL = try await StorageService.shared.uploadAvatar(image, userId: userId)
            } catch {
                // Fallback to base64 storage in Firestore when Storage rules or bucket config block upload.
                avatarURL = imageData.base64EncodedString()
                print("Avatar upload fallback to Firestore base64: \(error.localizedDescription)")
            }

            try await FirestoreService.shared.updateUserProfile(updates: ["avatarURL": avatarURL])
            if avatarURL.hasPrefix("http"), let remoteURL = URL(string: avatarURL) {
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.photoURL = remoteURL
                try await changeRequest?.commitChanges()
            }
            
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

    func deleteAvatar() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            await MainActor.run {
                self.errorMessage = "User not found"
            }
            return
        }

        await MainActor.run {
            self.isLoading = true
        }

        do {
            try? await StorageService.shared.deleteAvatar(userId: userId)
            try await FirestoreService.shared.updateUserProfile(updates: ["avatarURL": ""])
            let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
            changeRequest?.photoURL = nil
            try await changeRequest?.commitChanges()

            await MainActor.run {
                self.avatarImage = nil
                UserDefaults.standard.removeObject(forKey: "userAvatar")
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
