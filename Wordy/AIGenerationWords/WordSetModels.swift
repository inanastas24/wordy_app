// WordSetModels.swift
import SwiftUI
import Combine

// MARK: - Word Set
struct WordSet: Identifiable, Codable, Hashable {
    let id: String
    let titleKey: String
    let titleLocalized: [String: String]
    let emoji: String
    let gradientColors: [String]
    let difficulty: DifficultyLevel
    let category: WordCategory
    let wordCount: Int
    let words: [Word]
    let languagePair: String
    
    func title(for languageCode: String) -> String {
        titleLocalized[languageCode] ?? titleLocalized["en"] ?? titleKey
    }
    
    init(id: String, titleKey: String, titleLocalized: [String: String], emoji: String, gradientColors: [String], difficulty: DifficultyLevel, category: WordCategory, wordCount: Int, words: [Word], languagePair: String = "en-uk") {
        self.id = id
        self.titleKey = titleKey
        self.titleLocalized = titleLocalized
        self.emoji = emoji
        self.gradientColors = gradientColors
        self.difficulty = difficulty
        self.category = category
        self.wordCount = wordCount
        self.words = words
        self.languagePair = languagePair
    }

    enum CodingKeys: String, CodingKey {
        case id, titleKey, titleLocalized, emoji, gradientColors, difficulty, category, wordCount, words, languagePair
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        titleKey = try container.decode(String.self, forKey: .titleKey)
        titleLocalized = try container.decode([String: String].self, forKey: .titleLocalized)
        emoji = try container.decode(String.self, forKey: .emoji)
        gradientColors = try container.decode([String].self, forKey: .gradientColors)
        difficulty = try container.decode(DifficultyLevel.self, forKey: .difficulty)
        category = try container.decode(WordCategory.self, forKey: .category)
        wordCount = try container.decode(Int.self, forKey: .wordCount)
        words = try container.decode([Word].self, forKey: .words)
        languagePair = try container.decodeIfPresent(String.self, forKey: .languagePair) ?? "en-uk"
    }
}

enum DifficultyLevel: String, Codable, CaseIterable {
    case a1, a2, b1, b2, c1, c2
    
    var displayName: String { rawValue.uppercased() }
    var description: String {
        switch self {
        case .a1: return "Beginner"
        case .a2: return "Elementary"
        case .b1: return "Intermediate"
        case .b2: return "Upper-Intermediate"
        case .c1: return "Advanced"
        case .c2: return "Proficiency"
        }
    }
}

enum WordCategory: String, Codable, CaseIterable {
    case basics = "basics"
    case travel = "travel"
    case food = "food"
    case nouns = "nouns"
    case adjectives = "adjectives"
    case work = "work"
    case emotions = "emotions"
    case family = "family"
    case shopping = "shopping"
    case health = "health"
    case technology = "technology"
    case nature = "nature"
    case education = "education"
    case business = "business"
    case hobbies = "hobbies"
    case social = "social"
    case home = "home"
    case verbs = "verbs"
    case irregularVerbs = "irregularVerbs"
    
    var icon: String {
        switch self {
        case .basics: return "book.fill"
        case .travel: return "airplane"
        case .food: return "fork.knife"
        case .nouns: return "text.book.closed.fill"
        case .adjectives: return "paintpalette.fill"
        case .work: return "briefcase.fill"
        case .emotions: return "heart.fill"
        case .family: return "person.2.fill"
        case .shopping: return "bag.fill"
        case .health: return "heart.text.square.fill"
        case .technology: return "cpu.fill"
        case .nature: return "leaf.fill"
        case .education: return "graduationcap.fill"
        case .business: return "building.2.fill"
        case .hobbies: return "paintbrush.fill"
        case .social: return "bubble.left.fill"
        case .home: return "house.fill"
        case .verbs: return "textformat.abc"
        case .irregularVerbs: return "exclamationmark.triangle.fill"
        }
    }
    
    var defaultEmoji: String {
        switch self {
        case .basics: return "📚"
        case .travel: return "✈️"
        case .food: return "🍕"
        case .nouns: return "🧩"
        case .adjectives: return "🎨"
        case .work: return "💼"
        case .emotions: return "❤️"
        case .family: return "👨‍👩‍👧‍👦"
        case .shopping: return "🛍️"
        case .health: return "💊"
        case .technology: return "💻"
        case .nature: return "🌿"
        case .education: return "🎓"
        case .business: return "🏢"
        case .hobbies: return "🎨"
        case .social: return "💬"
        case .home: return "🏠"
        case .verbs: return "🏃"
        case .irregularVerbs: return "⚡"
        }
    }

    var localizationKey: LocalizableKey {
        switch self {
        case .basics: return .categoryBasics
        case .travel: return .categoryTravel
        case .food: return .categoryFood
        case .nouns: return .categoryNouns
        case .adjectives: return .categoryAdjectives
        case .work: return .categoryWork
        case .emotions: return .categoryEmotions
        case .family: return .categoryFamily
        case .shopping: return .categoryShopping
        case .health: return .categoryHealth
        case .technology: return .categoryTechnology
        case .nature: return .categoryNature
        case .education: return .categoryEducation
        case .business: return .categoryBusiness
        case .hobbies: return .categoryHobbies
        case .social: return .categorySocial
        case .home: return .categoryHome
        case .verbs: return .categoryVerbs
        case .irregularVerbs: return .categoryIrregularVerbs
        }
    }
}

// MARK: - Word
struct Word: Identifiable, Codable, Hashable {
    let id: String
    let original: String
    let translation: String
    let transcription: String?
    let exampleSentence: String?
    let exampleTranslation: String?
    let synonyms: [String]
    let difficulty: DifficultyLevel
    let category: WordCategory?
    let languagePair: String
    
    // TTS cache
    var audioUrl: String?
    
    init(id: String, original: String, translation: String, transcription: String? = nil, exampleSentence: String? = nil, exampleTranslation: String? = nil, synonyms: [String] = [], difficulty: DifficultyLevel, category: WordCategory? = nil, languagePair: String = "en-uk", audioUrl: String? = nil) {
        self.id = id
        self.original = original
        self.translation = translation
        self.transcription = transcription
        self.exampleSentence = exampleSentence
        self.exampleTranslation = exampleTranslation
        self.synonyms = synonyms
        self.difficulty = difficulty
        self.category = category
        self.languagePair = languagePair
        self.audioUrl = audioUrl
    }

    enum CodingKeys: String, CodingKey {
        case id, original, translation, transcription, exampleSentence, exampleTranslation, synonyms, difficulty, category, languagePair, audioUrl
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        original = try container.decode(String.self, forKey: .original)
        translation = try container.decode(String.self, forKey: .translation)
        transcription = try container.decodeIfPresent(String.self, forKey: .transcription)
        exampleSentence = try container.decodeIfPresent(String.self, forKey: .exampleSentence)
        exampleTranslation = try container.decodeIfPresent(String.self, forKey: .exampleTranslation)
        synonyms = try container.decodeIfPresent([String].self, forKey: .synonyms) ?? []
        difficulty = try container.decode(DifficultyLevel.self, forKey: .difficulty)
        category = try container.decodeIfPresent(WordCategory.self, forKey: .category)
        languagePair = try container.decodeIfPresent(String.self, forKey: .languagePair) ?? "en-uk"
        audioUrl = try container.decodeIfPresent(String.self, forKey: .audioUrl)
    }
}

struct WordSetCategorySummary: Identifiable, Codable, Hashable {
    let id: String
    let category: WordCategory
    let title: String
    let emoji: String
    let gradientColors: [String]
    let wordCount: Int
    let supportedDifficulties: [DifficultyLevel]
}

struct WordSetCatalogOverview: Codable, Hashable {
    let languagePair: String
    let categories: [WordSetCategorySummary]
    let difficultySets: [WordSet]
    let hasRemoteContent: Bool
}

struct PresetWord: Identifiable, Codable, Hashable {
    let id: String
    let original: String
    let translation: String
    let transcription: String?
    let exampleSentence: String?
    let exampleTranslation: String?
    let synonyms: [String]
    let languagePair: String
    let generatedAt: Date
    let aiModel: String
}

struct GeneratedWordSet: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let description: String
    let words: [PresetWord]
    let languagePair: String
    let difficulty: DifficultyLevel
    let createdAt: Date
    let generationCost: Double
    let estimatedQuality: Double
}

enum WordRating: Int, Codable, CaseIterable, Hashable {
    case poor = 2
    case okay = 3
    case good = 4
    case excellent = 5

    var label: String {
        switch self {
        case .poor: return "Poor"
        case .okay: return "Okay"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }
}

struct ExportedSet: Codable, Hashable {
    struct SetData: Codable, Hashable {
        struct ExportedWord: Codable, Hashable {
            let original: String
            let translation: String
        }

        let id: String
        let title: String
        let description: String
        let languagePair: String
        let difficulty: String
        let words: [ExportedWord]
    }

    struct Statistics: Codable, Hashable {
        let createdAt: Date
        let exportedBy: String?
    }

    let setData: SetData
    let statistics: Statistics

    func toDictionary() -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(self),
              let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }

        return jsonObject
    }
}

struct CommunityWordSet: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let description: String?
    let authorName: String
    let authorAvatar: String?
    let downloadCount: Int
    let averageRating: Double
    let ratingCount: Int
    let languagePair: String
    let difficulty: DifficultyLevel
    let wordCount: Int
    let tags: [String]
    let createdAt: Date
}

// MARK: - User Dictionary
class UserDictionaryManager: ObservableObject {
    var objectWillChange: ObservableObjectPublisher = ObservableObjectPublisher()
    
    static let shared = UserDictionaryManager()
    private let userDefaultsKey = "userDictionaryWords"
    private let customSetsKey = "userCustomSets"
    
    @Published private(set) var userWords: [Word]
    @Published var customSets: [WordSet]
    
    private init() {
        // Initialize with persisted values without calling instance methods before self is initialized
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([Word].self, from: data) {
            self.userWords = decoded
        } else {
            self.userWords = []
        }
        
        if let data = UserDefaults.standard.data(forKey: customSetsKey),
           let decoded = try? JSONDecoder().decode([WordSet].self, from: data) {
            self.customSets = decoded
        } else {
            self.customSets = []
        }
    }
    // MARK: - User Words Management
    
    func addWord(_ word: Word) {
        // Generate new ID to avoid conflicts with predefined words
        let newWord = Word(
            id: "user_\(UUID().uuidString)",
            original: word.original,
            translation: word.translation,
            transcription: word.transcription,
            exampleSentence: word.exampleSentence,
            exampleTranslation: word.exampleTranslation,
            synonyms: word.synonyms,
            difficulty: word.difficulty,
            audioUrl: word.audioUrl
        )
        
        userWords.append(newWord)
        saveUserWords()
    }
    
    func removeWord(withId id: String) {
        userWords.removeAll { $0.id == id }
        saveUserWords()
        
        // Also remove from custom sets if present
        for i in customSets.indices {
            if let index = customSets[i].words.firstIndex(where: { $0.id == id }) {
                let updatedSet = customSets[i]
                let updatedWords = updatedSet.words.enumerated().filter { $0.offset != index }.map { $0.element }
                customSets[i] = WordSet(
                    id: updatedSet.id,
                    titleKey: updatedSet.titleKey,
                    titleLocalized: updatedSet.titleLocalized,
                    emoji: updatedSet.emoji,
                    gradientColors: updatedSet.gradientColors,
                    difficulty: updatedSet.difficulty,
                    category: updatedSet.category,
                    wordCount: updatedWords.count,
                    words: updatedWords
                )
            }
        }
        saveCustomSets()
    }
    
    func updateWord(_ word: Word) {
        if let index = userWords.firstIndex(where: { $0.id == word.id }) {
            userWords[index] = word
            saveUserWords()
        }
    }
    
    func searchUserWords(query: String) -> [Word] {
        let lowercasedQuery = query.lowercased()
        return userWords.filter { word in
            word.original.lowercased().contains(lowercasedQuery) ||
            word.translation.lowercased().contains(lowercasedQuery) ||
            word.synonyms.contains(where: { $0.lowercased().contains(lowercasedQuery) })
        }
    }
    
    func getWordsByDifficulty(_ difficulty: DifficultyLevel) -> [Word] {
        return userWords.filter { $0.difficulty == difficulty }
    }
    
    // MARK: - Custom Sets Management
    
    func createCustomSet(title: String, emoji: String, gradientColors: [String], category: WordCategory, words: [Word]) -> WordSet {
        let setId = "custom_\(UUID().uuidString)"
        let titleKey = "custom_set_\(setId)"
        
        // Create localized title
        let availableLanguages = ["en", "uk", "de", "fr", "es", "pl"]
        let titleLocalized = Dictionary(uniqueKeysWithValues: availableLanguages.map { ($0, title) })
        
        let newSet = WordSet(
            id: setId,
            titleKey: titleKey,
            titleLocalized: titleLocalized,
            emoji: emoji,
            gradientColors: gradientColors,
            difficulty: .a1, // Default, will be calculated
            category: category,
            wordCount: words.count,
            words: words
        )
        
        customSets.append(newSet)
        saveCustomSets()
        return newSet
    }
    
    func deleteCustomSet(withId id: String) {
        customSets.removeAll { $0.id == id }
        saveCustomSets()
    }
    
    func addWordToSet(wordId: String, setId: String) {
        let availableWords = userWords + customSets.flatMap(\.words)

        guard let word = availableWords.first(where: { $0.id == wordId }),
              let setIndex = customSets.firstIndex(where: { $0.id == setId }) else { return }
        
        // Check if word already in set
        guard !customSets[setIndex].words.contains(where: { $0.id == wordId }) else { return }
        
        let updatedSet = customSets[setIndex]
        let updatedWords = updatedSet.words + [word]
        
        customSets[setIndex] = WordSet(
            id: updatedSet.id,
            titleKey: updatedSet.titleKey,
            titleLocalized: updatedSet.titleLocalized,
            emoji: updatedSet.emoji,
            gradientColors: updatedSet.gradientColors,
            difficulty: updatedSet.difficulty,
            category: updatedSet.category,
            wordCount: updatedWords.count,
            words: updatedWords
        )
        
        saveCustomSets()
    }
    
    func removeWordFromSet(wordId: String, setId: String) {
        guard let setIndex = customSets.firstIndex(where: { $0.id == setId }) else { return }
        
        let updatedSet = customSets[setIndex]
        let updatedWords = updatedSet.words.filter { $0.id != wordId }
        
        customSets[setIndex] = WordSet(
            id: updatedSet.id,
            titleKey: updatedSet.titleKey,
            titleLocalized: updatedSet.titleLocalized,
            emoji: updatedSet.emoji,
            gradientColors: updatedSet.gradientColors,
            difficulty: updatedSet.difficulty,
            category: updatedSet.category,
            wordCount: updatedWords.count,
            words: updatedWords
        )
        
        saveCustomSets()
    }
    
    func updateCustomSet(_ set: WordSet) {
        if let index = customSets.firstIndex(where: { $0.id == set.id }) {
            customSets[index] = set
            saveCustomSets()
        }
    }
    
    // MARK: - Import/Export
    
    func exportUserWords() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(userWords),
              let jsonString = String(data: data, encoding: .utf8) else { return nil }
        return jsonString
    }
    
    func importUserWords(from jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8),
              let words = try? JSONDecoder().decode([Word].self, from: data) else { return false }
        
        // Merge with existing, avoiding duplicates by original word
        let existingOriginals = Set(userWords.map { $0.original.lowercased() })
        let newWords = words.filter { !existingOriginals.contains($0.original.lowercased()) }
        
        // Regenerate IDs to ensure uniqueness
        let importedWords = newWords.map { word in
            Word(
                id: "user_imported_\(UUID().uuidString)",
                original: word.original,
                translation: word.translation,
                transcription: word.transcription,
                exampleSentence: word.exampleSentence,
                exampleTranslation: word.exampleTranslation,
                synonyms: word.synonyms,
                difficulty: word.difficulty,
                audioUrl: word.audioUrl
            )
        }
        
        userWords.append(contentsOf: importedWords)
        saveUserWords()
        return true
    }
    
    // MARK: - Statistics
    
    func getStatistics() -> UserDictionaryStats {
        let totalWords = userWords.count
        let byDifficulty = Dictionary(grouping: userWords, by: { $0.difficulty })
            .mapValues { $0.count }
        
        let totalCustomSets = customSets.count
        let totalWordsInSets = customSets.reduce(0) { $0 + $1.wordCount }
        
        return UserDictionaryStats(
            totalWords: totalWords,
            wordsByDifficulty: byDifficulty,
            totalCustomSets: totalCustomSets,
            totalWordsInCustomSets: totalWordsInSets,
            lastAddedDate: getLastAddedDate()
        )
    }
    
    // MARK: - Private Persistence Methods
    
    private func saveUserWords() {
        if let encoded = try? JSONEncoder().encode(userWords) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadUserWords() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([Word].self, from: data) else { return }
        userWords = decoded
    }
    
    func saveCustomSets() {
        if let encoded = try? JSONEncoder().encode(customSets) {
            UserDefaults.standard.set(encoded, forKey: customSetsKey)
        }
    }
    
    func loadCustomSets() {
        guard let data = UserDefaults.standard.data(forKey: customSetsKey),
              let decoded = try? JSONDecoder().decode([WordSet].self, from: data) else { return }
        customSets = decoded
    }
    
    private func getLastAddedDate() -> Date? {
        // Implementation would track last added date if needed
        return nil
    }
    
    // MARK: - Reset
    
    func resetAllUserData() {
        userWords.removeAll()
        customSets.removeAll()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: customSetsKey)
    }
}

// MARK: - Statistics Model
struct UserDictionaryStats {
    let totalWords: Int
    let wordsByDifficulty: [DifficultyLevel: Int]
    let totalCustomSets: Int
    let totalWordsInCustomSets: Int
    let lastAddedDate: Date?
    
    var totalItems: Int {
        totalWords + totalWordsInCustomSets
    }
}

// MARK: - Word Extension for User Management
extension Word {
    func withUpdatedTranslation(_ newTranslation: String) -> Word {
        Word(
            id: id,
            original: original,
            translation: newTranslation,
            transcription: transcription,
            exampleSentence: exampleSentence,
            exampleTranslation: exampleTranslation,
            synonyms: synonyms,
            difficulty: difficulty,
            audioUrl: audioUrl
        )
    }
    
    func withUpdatedFields(newTranslation: String? = nil,
                           sentence: String? = nil,
                           exampleTranslation: String? = nil) -> Word {
        Word(
            id: id,
            original: original,
            translation: newTranslation ?? translation,
            transcription: transcription,
            exampleSentence: sentence,
            exampleTranslation: exampleTranslation,
            synonyms: synonyms,
            difficulty: difficulty,
            audioUrl: audioUrl
        )
    }
}

extension Date {
    var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }
}
