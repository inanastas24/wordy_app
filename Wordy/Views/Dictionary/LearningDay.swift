//1
//  LearningDay.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 27.01.2026.
//

import Foundation
import SwiftData

@Model
class LearningDay: Identifiable {
    var id: UUID
    var date: Date
    var wordsLearned: Int
    var timeSpent: Int // секунди
    
    init(date: Date, wordsLearned: Int = 0, timeSpent: Int = 0) {
        self.id = UUID()
        self.date = date
        self.wordsLearned = wordsLearned
        self.timeSpent = timeSpent
    }
}
