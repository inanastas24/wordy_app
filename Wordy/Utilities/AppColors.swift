//1

import SwiftUI

enum AppColors {
    // MARK: - Основні кольори
    //Бірюзовий - основний акцент (кнопки, активні елементи)
    static let primary = Color(hex: "#4ECDC4")
    
    // Кремовий - фон додатку
    static let background = Color(hex: "#FFFDF5")
    
    // Темно-синій - основний текст заголовків
    static let textPrimary = Color(hex: "#2C3E50")
    
    // Сірий - допоміжний текст, підписи
    static let textSecondary = Color(hex: "#7F8C8D")
    
    // MARK: - Акцентні кольори (для статусів)
    //Світло-блакитний - фон карток, іконки словника
    static let blueLight = Color(hex: "#A8D8EA")
    
    // Рожевий - помилка, кнопка "Не знаю", видалення
    static let pink = Color(hex: "#F38BA8")
    
    // М'ятний/зелений - успіх, кнопка "Вивчено"
    static let mint = Color(hex: "#95E1D3")
    
    // Золотий - досягнення, нагороди
    static let gold = Color(hex: "#FFD700")
    
    // MARK: - Додаткові
    // Світло-сірий - прогрес бари, розділювачі
    static let grayLight = Color(hex: "#E0E0E0")
    
    // Тінь - для тіней карток (чорний з прозорістю)
    static let shadow = Color.black.opacity(0.1)
    
    // Жовтий/золотий - для голосового пошуку
    static let voiceYellow = Color(hex: "#FFD93D")

    // Темніший жовтий - для активного стану запису
    static let voiceYellowDark = Color(hex: "#F4C430")
}

// MARK: - Gradient-и (опціонально, якщо використовуєте)
extension AppColors {
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [primary, Color(hex: "#45B7AA")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
