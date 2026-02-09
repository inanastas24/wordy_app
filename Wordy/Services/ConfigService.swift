//1
//  ConfigService.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 26.01.2026.
//

import Foundation

enum ConfigError: Error {
    case missingPlist
    case missingKey(String)
    case invalidBase64
}

class ConfigService {
    static let shared = ConfigService()
    
    private let config: [String: Any]
    
    private init() {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            print("⚠️ Config.plist не знайдено! Використовуємо порожній конфіг.")
            self.config = [:]
            return
        }
        self.config = plist
    }
    
    func get(_ key: String) -> String? {
        return config[key] as? String
    }
    
    // Для обов'язкових ключів
    func require(_ key: String) throws -> String {
        guard let value = config[key] as? String, !value.isEmpty else {
            throw ConfigError.missingKey(key)
        }
        return value
    }
    
    // MARK: - Telegram Configuration
    
    /// Отримує токен бота з декодуванням Base64
    var telegramBotToken: String? {
        guard let encoded = get("TelegramBotToken"),
              let data = Data(base64Encoded: encoded),
              let decoded = String(data: data, encoding: .utf8) else { return nil }
        return decoded
    }
    
    /// Отримує Chat ID з декодуванням Base64
    var telegramChatID: String? {
        guard let encoded = get("TelegramChatID"),
              let data = Data(base64Encoded: encoded),
              let decoded = String(data: data, encoding: .utf8) else { return nil }
        return decoded
    }
    
    /// Перевіряє чи налаштований Telegram
    var isTelegramConfigured: Bool {
        telegramBotToken != nil && telegramChatID != nil
    }
    
    // MARK: - Base64 Decoding
    
    private func decodeBase64(_ string: String) -> String? {
        guard let data = Data(base64Encoded: string),
              let decoded = String(data: data, encoding: .utf8) else {
            print("⚠️ Помилка декодування Base64 для ключа")
            return nil
        }
        return decoded
    }
    
    // MARK: - Helper для розробки (кодування)
    
    /// Використовуйте це в Playground для отримання Base64 значень
    static func encodeBase64(_ string: String) -> String {
        return Data(string.utf8).base64EncodedString()
    }
}
