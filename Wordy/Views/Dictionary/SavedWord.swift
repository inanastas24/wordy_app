//1
//  SavedWord.swift (ОНОВЛЕНИЙ)
//

import SwiftData
import Foundation

@Model
class SavedWord {
    var id: UUID
    var original: String
    var translation: String
    var transcription: String
    var exampleSentence: String
    var languagePair: String
    var isLearned: Bool
    var reviewCount: Int
    var dateAdded: Date
    var srsInterval: Double
    var srsRepetition: Int
    var srsEasinessFactor: Double
    var nextReviewDate: Date?
    
    // MARK: - SRS поля (додано)
    var lastReviewDate: Date?
    var averageQuality: Double
    
    init(
        original: String,
        translation: String,
        transcription: String = "",
        exampleSentence: String = "",
        languagePair: String = "",
        isLearned: Bool = false,
        reviewCount: Int = 0,
        dateAdded: Date = Date(),
        srsInterval: Double = 0,
        srsRepetition: Int = 0,
        srsEasinessFactor: Double = 2.5,
        nextReviewDate: Date? = nil,
        lastReviewDate: Date? = nil,
        averageQuality: Double = 0.0
    ) {
        self.id = UUID()
        self.original = original
        self.translation = translation
        self.transcription = transcription
        self.exampleSentence = exampleSentence
        self.languagePair = languagePair
        self.isLearned = isLearned
        self.reviewCount = reviewCount
        self.dateAdded = dateAdded
        self.srsInterval = srsInterval
        self.srsRepetition = srsRepetition
        self.srsEasinessFactor = srsEasinessFactor
        self.nextReviewDate = nextReviewDate
        self.lastReviewDate = lastReviewDate
        self.averageQuality = averageQuality
    }
    
    var isDueForReview: Bool {
        guard let nextReview = nextReviewDate else { return true }
        return Date() >= nextReview
    }
    
    var timeUntilReview: String {
        guard let nextReview = nextReviewDate else { return "зараз" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: nextReview, relativeTo: Date())
    }
}
