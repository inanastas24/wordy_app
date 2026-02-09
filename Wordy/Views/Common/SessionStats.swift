//1
//  SessionStats.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import Foundation

struct SessionStats {
    var totalReviewed: Int = 0
    var learned: Int = 0
    var againCount: Int = 0
    var qualityDistribution: [Int: Int] = [:]
    
    var averageQuality: Double {
        guard !qualityDistribution.isEmpty else { return 0 }
        let total = qualityDistribution.reduce(0) { $0 + ($1.key * $1.value) }
        let count = qualityDistribution.values.reduce(0, +)
        return count > 0 ? Double(total) / Double(count) : 0
    }
}
