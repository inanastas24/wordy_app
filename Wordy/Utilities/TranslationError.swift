//1
//  TranslationError.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 28.01.2026.
//

import Foundation

enum TranslationError: Error, LocalizedError {
    case emptyAPIKey
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError
    case apiError(String)
    case noData
    
    var errorDescription: String? {
        switch self {
        case .emptyAPIKey:
            return "API ключ не налаштовано"
        case .invalidURL:
            return "Невірний URL запиту"
        case .networkError(let error):
            return "Помилка мережі: \(error.localizedDescription)"
        case .invalidResponse:
            return "Невірна відповідь сервера"
        case .decodingError:
            return "Помилка обробки даних"
        case .apiError(let message):
            return "Помилка API: \(message)"
        case .noData:
            return "Немає даних для перекладу"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .emptyAPIKey:
            return "Перевірте налаштування API ключа в ConfigService"
        case .networkError:
            return "Перевірте підключення до інтернету"
        default:
            return "Спробуйте ще раз пізніше"
        }
    }
}
