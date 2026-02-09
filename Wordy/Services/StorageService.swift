//
//  StorageService.swift
//  Wordy
//

import Foundation
import FirebaseStorage
import FirebaseAuth
import UIKit

// ВИДАЛЕНО: @MainActor і ObservableObject - вони не потрібні тут
class StorageService {
    static let shared = StorageService()
    private let storage = Storage.storage().reference()
    
    /// Завантажує аватар в Storage і повертає URL
    func uploadAvatar(_ image: UIImage, userId: String) async throws -> String {
        print("📤 StorageService: Завантаження аватара")
        print("   UserID: \(userId)")
        
        // Стиснемо до прийнятного розміру (максимум 2MB)
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.compressionFailed
        }
        
        print("   Розмір: \(imageData.count) байт")
        
        // Шлях: avatars/{userId}.jpg
        let avatarRef = storage.child("avatars/\(userId).jpg")
        
        // Метадані
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Завантажуємо
        _ = try await avatarRef.putDataAsync(imageData, metadata: metadata)
        
        // Отримуємо URL
        let downloadURL = try await avatarRef.downloadURL()
        let urlString = downloadURL.absoluteString
        
        print("   ✅ Завантажено: \(urlString)")
        
        return urlString
    }
    
    /// Видаляє аватар з Storage
    func deleteAvatar(userId: String) async throws {
        print("🗑️ StorageService: Видалення аватара")
        let avatarRef = storage.child("avatars/\(userId).jpg")
        try await avatarRef.delete()
        print("   ✅ Видалено")
    }
    
    /// Завантажує аватар з URL
    func downloadAvatar(from urlString: String) async throws -> UIImage? {
        print("📥 StorageService: Завантаження аватара з URL")
        
        guard let url = URL(string: urlString) else {
            print("   ❌ Невалідний URL: \(urlString)")
            return nil
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        if let image = UIImage(data: data) {
            print("   ✅ Завантажено: \(data.count) байт")
            return image
        } else {
            print("   ❌ Не вдалося створити UIImage")
            return nil
        }
    }
    
    enum StorageError: Error {
        case compressionFailed
        case invalidURL
        case downloadFailed
        
        var localizedDescription: String {
            switch self {
            case .compressionFailed: return "Failed to compress image"
            case .invalidURL: return "Invalid image URL"
            case .downloadFailed: return "Failed to download image"
            }
        }
    }
}
