//  SessionStats.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import Foundation

struct SessionStats {
    // MARK: - Лічильники
    
    /// ⭐ Всього переглянуто карток (всі відповіді)
    var totalReviewed: Int = 0
    
    /// ✅ Знаю слово (якість 3-5: Good, Perfect)
    var knownCount: Int = 0
    
    /// 🔄 Не знаю, треба повторити (якість 0-2: Again, Hard, Medium)
    var againCount: Int = 0
    
    /// Сума всіх оцінок для середнього (0-5)
    var qualitySum: Int = 0
    
    // MARK: - Обчислювані властивості
    
    /// Середня якість відповідей (0.0 - 5.0)
    var averageQuality: Double {
        totalReviewed > 0 ? Double(qualitySum) / Double(totalReviewed) : 0.0
    }
    
    /// Відсоток "Знаю" (0.0 - 1.0)
    var knownPercentage: Double {
        totalReviewed > 0 ? Double(knownCount) / Double(totalReviewed) : 0.0
    }
    
    // MARK: - Методи
    
    /// Додає нову відповідь до статистики
    mutating func addReview(quality: Int) {
        totalReviewed += 1
        qualitySum += quality
        
        if quality >= 3 {
            knownCount += 1
        } else {
            againCount += 1
        }
    }
    
    /// Скидає статистику
    mutating func reset() {
        totalReviewed = 0
        knownCount = 0
        againCount = 0
        qualitySum = 0
    }
}
