//
//  FirebaseFunctionsService.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 09.03.2026.
//

import FirebaseFunctions
import FirebaseAuth
import Foundation

class FirebaseFunctionsService {
    static let shared = FirebaseFunctionsService()
    
    private let functions = Functions.functions()
    
    // MARK: - Generate Word Set via Cloud Function
    
    func generateWordSet(
        title: String,
        description: String,
        languagePair: LanguagePair,
        difficulty: DifficultyLevel,
        count: Int,
        userId: String
    ) async throws -> GeneratedWordSet {
        
        let data: [String: Any] = [
            "title": title,
            "description": description,
            "sourceLanguage": languagePair.source.rawValue,
            "targetLanguage": languagePair.target.rawValue,
            "difficulty": difficulty.rawValue,
            "count": min(count, 100),
            "userId": userId,
            "timestamp": Date().iso8601String
        ]
        
        let result = try await functions.httpsCallable("generateWordSet").call(data)
        
        guard let response = result.data as? [String: Any],
              let setData = response["set"] as? [String: Any] else {
            throw GenerationError.invalidResponse
        }
        
        return try parseGeneratedSet(setData)
    }
    
    // MARK: - Rate Word Quality
    
    func rateWord(
        wordId: String,
        setId: String,
        rating: WordRating,
        userId: String
    ) async throws {
        
        let data: [String: Any] = [
            "wordId": wordId,
            "setId": setId,
            "rating": rating.rawValue,
            "userId": userId,
            "timestamp": Date().iso8601String
        ]
        
        _ = try await functions.httpsCallable("rateWord").call(data)
    }
    
    // MARK: - Get Improved Words
    
    func getImprovedWords(
        setId: String,
        languagePair: LanguagePair
    ) async throws -> [PresetWord] {
        
        let data: [String: Any] = [
            "setId": setId,
            "sourceLanguage": languagePair.source.rawValue,
            "targetLanguage": languagePair.target.rawValue
        ]
        
        let result = try await functions.httpsCallable("getImprovedWords").call(data)
        
        guard let response = result.data as? [String: Any],
              let wordsData = response["words"] as? [[String: Any]] else {
            throw GenerationError.invalidResponse
        }
        
        return wordsData.compactMap { parseWord($0) }
    }
    
    // MARK: - Export/Import
    
    func exportSet(setId: String, userId: String) async throws -> ExportedSet {
        let data: [String: Any] = [
            "setId": setId,
            "userId": userId
        ]
        
        let result = try await functions.httpsCallable("exportSet").call(data)
        
        guard let response = result.data as? [String: Any] else {
            throw GenerationError.invalidResponse
        }
        
        return try parseExportedSet(response)
    }
    
    func importSet(
        exportData: ExportedSet,
        userId: String
    ) async throws -> String {
        
        let data: [String: Any] = [
            "exportData": exportData.toDictionary(),
            "userId": userId,
            "importedAt": Date().iso8601String
        ]
        
        let result = try await functions.httpsCallable("importSet").call(data)
        
        guard let response = result.data as? [String: Any],
              let newSetId = response["setId"] as? String else {
            throw GenerationError.invalidResponse
        }
        
        return newSetId
    }
    
    // MARK: - Get Community Sets
    
    func getCommunitySets(
        languagePair: LanguagePair,
        sortBy: CommunitySort = .popular,
        limit: Int = 20
    ) async throws -> [CommunityWordSet] {
        
        let data: [String: Any] = [
            "sourceLanguage": languagePair.source.rawValue,
            "targetLanguage": languagePair.target.rawValue,
            "sortBy": sortBy.rawValue,
            "limit": limit
        ]
        
        let result = try await functions.httpsCallable("getCommunitySets").call(data)
        
        guard let response = result.data as? [String: Any],
              let setsData = response["sets"] as? [[String: Any]] else {
            throw GenerationError.invalidResponse
        }
        
        return setsData.compactMap { parseCommunitySet($0) }
    }
    
    // MARK: - Helpers
    
    private func parseGeneratedSet(_ data: [String: Any]) throws -> GeneratedWordSet {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String,
              let description = data["description"] as? String,
              let wordsData = data["words"] as? [[String: Any]],
              let languagePair = data["languagePair"] as? String,
              let difficultyString = data["difficulty"] as? String,
              let difficulty = DifficultyLevel(rawValue: difficultyString),
              let createdAtString = data["createdAt"] as? String,
              let createdAt = ISO8601DateFormatter().date(from: createdAtString) else {
            throw GenerationError.invalidResponse
        }
        
        let words = wordsData.compactMap { parseWord($0) }
        let cost = data["generationCost"] as? Double ?? 0.0
        let quality = data["estimatedQuality"] as? Double ?? 0.5
        
        return GeneratedWordSet(
            id: id,
            title: title,
            description: description,
            words: words,
            languagePair: languagePair,
            difficulty: difficulty,
            createdAt: createdAt,
            generationCost: cost,
            estimatedQuality: quality
        )
    }
    
    private func parseWord(_ data: [String: Any]) -> PresetWord? {
        guard let id = data["id"] as? String,
              let original = data["original"] as? String,
              let translation = data["translation"] as? String else { return nil }
        
        return PresetWord(
            id: id,
            original: original,
            translation: translation,
            transcription: data["transcription"] as? String,
            exampleSentence: data["exampleSentence"] as? String,
            exampleTranslation: data["exampleTranslation"] as? String,
            synonyms: data["synonyms"] as? [String] ?? [],
            languagePair: data["languagePair"] as? String ?? "en-uk",
            generatedAt: ISO8601DateFormatter().date(from: data["generatedAt"] as? String ?? "") ?? Date(),
            aiModel: data["model"] as? String ?? "gpt-4o"
        )
    }
    
    private func parseExportedSet(_ data: [String: Any]) throws -> ExportedSet {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode(ExportedSet.self, from: jsonData)
    }
    
    private func parseCommunitySet(_ data: [String: Any]) -> CommunityWordSet? {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String,
              let authorName = data["authorName"] as? String else { return nil }
        
        return CommunityWordSet(
            id: id,
            title: title,
            description: data["description"] as? String,
            authorName: authorName,
            authorAvatar: data["authorAvatar"] as? String,
            downloadCount: data["downloadCount"] as? Int ?? 0,
            averageRating: data["averageRating"] as? Double ?? 0,
            ratingCount: data["ratingCount"] as? Int ?? 0,
            languagePair: data["languagePair"] as? String ?? "en-uk",
            difficulty: DifficultyLevel(rawValue: data["difficulty"] as? String ?? "a1") ?? .a1,
            wordCount: data["wordCount"] as? Int ?? 0,
            tags: data["tags"] as? [String] ?? [],
            createdAt: ISO8601DateFormatter().date(from: data["createdAt"] as? String ?? "") ?? Date()
        )
    }
    
    enum GenerationError: Error {
        case invalidResponse
        case rateLimited
        case insufficientCredits
    }
    
    enum CommunitySort: String {
        case popular, recentWord, rated, trending
    }
}
