//
//  StreakService.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 27.01.2026.
//

import Foundation

class StreakService {
    static let shared = StreakService()
    
    private let defaults = UserDefaults.standard
    private let suiteName = "group.com.inzercreator.wordyapp"
    
    // Keys
    private let streakKey = "currentStreak"
    private let lastOpenDateKey = "lastOpenDate"
    private let bestStreakKey = "bestStreak"
    
    // MARK: - Current Streak
    var currentStreak: Int {
        get { defaults.integer(forKey: streakKey) }
        set { defaults.set(newValue, forKey: streakKey) }
    }
    
    // MARK: - Best Streak
    var bestStreak: Int {
        get { defaults.integer(forKey: bestStreakKey) }
        set { defaults.set(newValue, forKey: bestStreakKey) }
    }
    
    // MARK: - Last Open Date
    var lastOpenDate: Date? {
        get { defaults.object(forKey: lastOpenDateKey) as? Date }
        set { defaults.set(newValue, forKey: lastOpenDateKey) }
    }
    
    // MARK: - Update Streak on App Open
    func updateStreak() {
        let calendar = Calendar.current
        let now = Date()
        
        guard let lastOpen = lastOpenDate else {
            // First time opening app
            currentStreak = 1
            lastOpenDate = now
            return
        }
        
        // Check if it's the same day
        if calendar.isDate(lastOpen, inSameDayAs: now) {
            // Same day, don't update
            return
        }
        
        // Check if yesterday
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(lastOpen, inSameDayAs: yesterday) {
            // Consecutive day - increase streak
            currentStreak += 1
            
            // Update best streak if needed
            if currentStreak > bestStreak {
                bestStreak = currentStreak
            }
        } else {
            // Gap detected - reset streak
            currentStreak = 1
        }
        
        lastOpenDate = now
        
        // Save to shared defaults for widget
        saveToSharedDefaults()
    }
    
    // MARK: - Check if streak is active today
    var isStreakActiveToday: Bool {
        guard let lastOpen = lastOpenDate else { return false }
        return Calendar.current.isDate(lastOpen, inSameDayAs: Date())
    }
    
    // MARK: - Get streak color based on days
    func getStreakColor(for days: Int) -> String {
        switch days {
        case 1...6:
            // Light colors for beginners
            let colors = ["#F38BA8", "#A8D8EA", "#FFD93D", "#95E1D3", "#C9B1FF", "#FFB6B9"]
            return colors.randomElement() ?? "#F38BA8"
            
        case 7...13:
            // Week streak - warm colors
            let colors = ["#FF6B6B", "#FF8E53", "#FF6B9D", "#C44569", "#F8B500", "#FF9F43"]
            return colors.randomElement() ?? "#FF6B6B"
            
        case 14...29:
            // Two weeks - achievement colors
            let colors = ["#2ECC71", "#27AE60", "#1ABC9C", "#16A085", "#3498DB", "#2980B9"]
            return colors.randomElement() ?? "#2ECC71"
            
        case 30...99:
            // Month - premium colors
            let colors = ["#9B59B6", "#8E44AD", "#E74C3C", "#C0392B", "#E67E22", "#D35400"]
            return colors.randomElement() ?? "#9B59B6"
            
        case 100...:
            // 100+ days - legendary gold/platinum
            let colors = ["#FFD700", "#FFA500", "#FF8C00", "#B8860B", "#DAA520", "#F4C430"]
            return colors.randomElement() ?? "#FFD700"
            
        default:
            return "#F38BA8"
        }
    }
    
    // MARK: - Get streak title
    func getStreakTitle(for days: Int) -> String {
        switch days {
        case 1: return "1 day"
        case 2...: return "\(days) days"
        default: return "0 days"
        }
    }
    
    // MARK: - Get achievement unlock status
    func isAchievementUnlocked(_ achievement: StreakAchievement) -> Bool {
        switch achievement {
        case .firstWord: return true // Always unlocked
        case .sevenDays: return currentStreak >= 7 || bestStreak >= 7
        case .thirtyDays: return currentStreak >= 30 || bestStreak >= 30
        case .hundredDays: return currentStreak >= 100 || bestStreak >= 100
        }
    }
    
    // MARK: - Save to shared defaults (for widget)
    private func saveToSharedDefaults() {
        guard let sharedDefaults = UserDefaults(suiteName: suiteName) else { return }
        sharedDefaults.set(currentStreak, forKey: "currentStreak")
        sharedDefaults.set(bestStreak, forKey: "bestStreak")
        sharedDefaults.synchronize()
    }
    
    // MARK: - Reset (for testing)
    func resetStreak() {
        currentStreak = 0
        bestStreak = 0
        lastOpenDate = nil
        saveToSharedDefaults()
    }
}

// MARK: - Streak Achievement Enum
enum StreakAchievement: String, CaseIterable {
    case firstWord = "first_word"
    case sevenDays = "seven_days"
    case thirtyDays = "thirty_days"
    case hundredDays = "hundred_days"
    
    var title: String {
        switch self {
        case .firstWord: return "First word"
        case .sevenDays: return "7 days"
        case .thirtyDays: return "30 days"
        case .hundredDays: return "100 days"
        }
    }
    
    var icon: String {
        switch self {
        case .firstWord: return "star.fill"
        case .sevenDays: return "flame.fill"
        case .thirtyDays: return "calendar.badge.clock"
        case .hundredDays: return "crown.fill"
        }
    }
}
