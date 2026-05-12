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
    case backendUnavailable
    case timeout
    case emptyResponse
    case invalidWordCard
    case unsupportedLanguagePair
    case rateLimited
    case authError
    case budgetExceeded
    case backendMisconfigured
    
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
        case .backendUnavailable:
            return "Тимчасово недоступно, спробуйте ще раз"
        case .timeout:
            return "Час очікування відповіді вичерпано"
        case .emptyResponse:
            return "Сервер не повернув результат перекладу"
        case .invalidWordCard:
            return "Отримано некоректні дані перекладу"
        case .unsupportedLanguagePair:
            return "Ця мовна пара поки не підтримується"
        case .rateLimited:
            return "Ліміт запитів, спробуйте пізніше"
        case .authError:
            return "Не вдалося авторизувати запит до сервісу перекладу"
        case .budgetExceeded:
            return "Ліміт запитів, спробуйте пізніше"
        case .backendMisconfigured:
            return "Wordy Backend URL не налаштований в iOS конфігурації"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .emptyAPIKey:
            return "Перевірте налаштування API ключа в ConfigService"
        case .networkError, .backendUnavailable, .timeout:
            return "Спробуйте ще раз трохи пізніше"
        case .authError:
            return "Увійдіть у Wordy ще раз і повторіть запит"
        case .rateLimited:
            return "Зачекайте трохи перед наступним запитом"
        case .budgetExceeded:
            return "Спробуйте пізніше"
        case .backendMisconfigured:
            return "Додайте WORDY_BACKEND_URL або WORDY_BACKEND_BASE_URL у Config.plist"
        default:
            return "Спробуйте ще раз пізніше"
        }
    }
}
