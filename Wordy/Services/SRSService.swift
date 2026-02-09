//1
//  SRSService.swift (ОНОВЛЕНИЙ)
//

import Foundation

class SRSService {
    
    enum ReviewQuality: Int, CaseIterable {
        case completeFailure = 0
        case hard = 1
        case medium = 2
        case easy = 3
        case good = 4
        case perfect = 5
        
        var description: String {
            switch self {
            case .completeFailure: return "Знову"
            case .hard: return "Важко"
            case .medium: return "Середньо"
            case .easy: return "Легко"
            case .good: return "Добре"
            case .perfect: return "Ідеально"
            }
        }
    }
    
    static let shared = SRSService()
    private let minimumEF = 1.3
    
    func processReview(
        for word: SavedWord,
        quality: ReviewQuality,
        on date: Date = Date()
    ) {
        let q = Double(quality.rawValue)
        
        // Оновлюємо статистику
        word.reviewCount += 1
        let oldAvg = word.averageQuality
        let newCount = Double(word.reviewCount)
        word.averageQuality = ((oldAvg * (newCount - 1)) + q) / newCount
        
        word.lastReviewDate = date
        
        if quality.rawValue >= 3 {
            word.srsRepetition += 1
            
            if word.srsRepetition == 1 {
                word.srsInterval = 1
            } else if word.srsRepetition == 2 {
                word.srsInterval = 6
            } else {
                word.srsInterval *= word.srsEasinessFactor
            }
            
            let newEF = word.srsEasinessFactor - 0.8 + (0.28 * q) - (0.02 * q * q)
            word.srsEasinessFactor = max(minimumEF, newEF)
            
            if word.srsRepetition >= 3 {
                word.isLearned = true
            }
        } else {
            word.srsRepetition = 0
            word.srsInterval = 1
            word.isLearned = false
        }
        
        let daysToAdd = word.srsInterval
        word.nextReviewDate = Calendar.current.date(
            byAdding: .day,
            value: Int(daysToAdd),
            to: date
        ) ?? date.addingTimeInterval(86400)
    }
    
    func resetSRS(for word: SavedWord) {
        word.srsInterval = 0
        word.srsRepetition = 0
        word.srsEasinessFactor = 2.5
        word.nextReviewDate = Date()
        word.lastReviewDate = nil
        word.reviewCount = 0
        word.averageQuality = 0.0
        word.isLearned = false
    }
    
    func getWordsDueForReview(
        from words: [SavedWord],
        on date: Date = Date()
    ) -> [SavedWord] {
        return words.filter {
            guard let nextDate = $0.nextReviewDate else { return true }
            return nextDate <= date && !$0.isLearned
        }
        .sorted {
            ($0.nextReviewDate ?? Date.distantPast) < ($1.nextReviewDate ?? Date.distantPast)
        }
    }
    
    func getNewWords(from words: [SavedWord]) -> [SavedWord] {
        return words.filter { $0.srsRepetition == 0 && $0.reviewCount == 0 }
    }
}
