//1
//  FirestoreService.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 29.01.2026.
//

import FirebaseFirestore
import FirebaseAuth
import Foundation
import Combine

// MARK: - Notification Names
extension Notification.Name {
    static let wordSaved = Notification.Name("wordSaved")
    static let userProfileUpdated = Notification.Name("userProfileUpdated")
}

// MARK: - User Profile Model
struct UserProfile: Codable {
    var displayName: String?
    var avatarURL: String?
    var appLanguage: String
    var learningLanguage: String
    var isDarkMode: Bool
    var updatedAt: Date
    
    init(displayName: String? = nil,
         avatarURL: String? = nil,
         appLanguage: String = "uk",
         learningLanguage: String = "en",
         isDarkMode: Bool = false) {
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.appLanguage = appLanguage
        self.learningLanguage = learningLanguage
        self.isDarkMode = isDarkMode
        self.updatedAt = Date()
    }
}

// MARK: - Saved Word Model
struct WordDictionaryModel: Identifiable, Codable, Equatable, Hashable {
    var id: String?
    var name: String
    var createdAt: Date
    var userId: String?

    init(
        id: String? = nil,
        name: String,
        createdAt: Date = Date(),
        userId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.userId = userId
    }
    
    // Hashable & Equatable conformance for Navigation and Sets
    static func == (lhs: WordDictionaryModel, rhs: WordDictionaryModel) -> Bool {
        // Prefer stable id if available
        if let lid = lhs.id, let rid = rhs.id { return lid == rid }
        // Fallback to name + createdAt when ids are missing (e.g., prior to persistence)
        return lhs.name == rhs.name && lhs.createdAt == rhs.createdAt && lhs.userId == rhs.userId
    }

    func hash(into hasher: inout Hasher) {
        if let id = id {
            hasher.combine("id:")
            hasher.combine(id)
        } else {
            hasher.combine("fallback:")
            hasher.combine(name)
            hasher.combine(createdAt.timeIntervalSince1970)
            hasher.combine(userId ?? "")
        }
    }
}

struct SavedWordModel: Identifiable, Codable, Equatable {
    var id: String?
    var original: String
    var translation: String
    var transcription: String?
    var exampleSentence: String?
    var languagePair: String
    var dictionaryId: String?
    var isLearned: Bool
    var reviewCount: Int
    var srsInterval: Double
    var srsRepetition: Int
    var srsEasinessFactor: Double
    var nextReviewDate: Date?
    var lastReviewDate: Date?
    var averageQuality: Double
    var createdAt: Date
    var userId: String?
    
    init(id: String? = nil,
         original: String,
         translation: String,
         transcription: String? = nil,
         exampleSentence: String? = nil,
         languagePair: String,
         dictionaryId: String? = nil,
         isLearned: Bool = false,
         reviewCount: Int = 0,
         srsInterval: Double = 0,
         srsRepetition: Int = 0,
         srsEasinessFactor: Double = 2.5,
         nextReviewDate: Date? = nil,
         lastReviewDate: Date? = nil,
         averageQuality: Double = 0,
         createdAt: Date = Date(),
         userId: String? = nil) {
        self.id = id
        self.original = original
        self.translation = translation
        self.transcription = transcription
        self.exampleSentence = exampleSentence
        self.languagePair = languagePair
        self.dictionaryId = dictionaryId
        self.isLearned = isLearned
        self.reviewCount = reviewCount
        self.srsInterval = srsInterval
        self.srsRepetition = srsRepetition
        self.srsEasinessFactor = srsEasinessFactor
        self.nextReviewDate = nextReviewDate
        self.lastReviewDate = lastReviewDate
        self.averageQuality = averageQuality
        self.createdAt = createdAt
        self.userId = userId
    }
    
    // Для зручності - чи потрібно повторювати слово
    var isDueForReview: Bool {
        guard let nextDate = nextReviewDate else { return true }
        return Date() >= nextDate && !isLearned
    }
}

// MARK: - Firestore Service
class FirestoreService {
    static let shared = FirestoreService()
    
    private let db = Firestore.firestore()
    
    private init() {}

    private func userDocument(userId: String) -> DocumentReference {
        db.collection("users").document(userId)
    }

    private func rootWordsCollection(userId: String) -> CollectionReference {
        userDocument(userId: userId).collection("words")
    }

    private func dictionariesCollection(userId: String) -> CollectionReference {
        userDocument(userId: userId).collection("dictionaries")
    }

    private func dictionaryWordsCollection(userId: String, dictionaryId: String) -> CollectionReference {
        dictionariesCollection(userId: userId)
            .document(dictionaryId)
            .collection("words")
    }
    
    // MARK: - User Profile Methods
    
    func saveUserProfile(_ profile: UserProfile) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotFound
        }
        
        try db.collection("users")
            .document(userId)
            .collection("profile")
            .document("main")
            .setData(from: profile)
        
        NotificationCenter.default.post(name: .userProfileUpdated, object: nil)
    }
    
    func fetchUserProfile() async throws -> UserProfile? {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotFound
        }
        
        let document = try await db.collection("users")
            .document(userId)
            .collection("profile")
            .document("main")
            .getDocument()
        
        return try? document.data(as: UserProfile.self)
    }
    
    func updateUserProfile(updates: [String: Any]) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotFound
        }
        
        var updatesWithTimestamp = updates
        updatesWithTimestamp["updatedAt"] = Timestamp(date: Date())
        
        try await db.collection("users")
            .document(userId)
            .collection("profile")
            .document("main")
            .setData(updatesWithTimestamp, merge: true)
        
        NotificationCenter.default.post(name: .userProfileUpdated, object: nil)
    }
    
    // MARK: - Avatar Upload
    func uploadAvatar(imageData: Data) async throws -> String {
        guard Auth.auth().currentUser?.uid != nil else {
            throw AuthError.userNotFound
        }
        
        // Convert to base64
        let base64String = imageData.base64EncodedString()
        
        // Save to user profile
        try await updateUserProfile(updates: ["avatarURL": base64String])
        
        return base64String
    }
    
    // MARK: - Word Methods

    func saveDictionary(_ dictionary: WordDictionaryModel) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotFound
        }

        let dictionaryId = dictionary.id ?? UUID().uuidString
        var dictionaryToSave = dictionary
        dictionaryToSave.id = dictionaryId
        dictionaryToSave.userId = userId

        var dictionaryData = try Firestore.Encoder().encode(dictionaryToSave)
        dictionaryData["createdAt"] = Timestamp(date: dictionaryToSave.createdAt)

        try await dictionariesCollection(userId: userId)
            .document(dictionaryId)
            .setData(dictionaryData, merge: true)

        print("☁️ saveDictionary id='\(dictionaryId)' name='\(dictionaryToSave.name)'")
    }

    func fetchDictionaries() async throws -> [WordDictionaryModel] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotFound
        }

        let snapshot = try await dictionariesCollection(userId: userId)
            .order(by: "createdAt", descending: false)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            do {
                var dictionary = try doc.data(as: WordDictionaryModel.self)
                dictionary.id = doc.documentID
                return dictionary
            } catch {
                print("❌ Failed to decode dictionary: \(error)")
                return nil
            }
        }
    }

    func saveWord(_ word: SavedWordModel) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotFound
        }

        var wordToSave = word
        var wordId = word.id ?? UUID().uuidString
        print("☁️ saveWord start original='\(word.original)' id='\(word.id ?? "nil")' dictionaryId='\(word.dictionaryId ?? "nil")'")

        let existingDocument = try await db.collection("users")
            .document(userId)
            .collection("words")
            .document(wordId)
            .getDocument()

        if existingDocument.exists {
            let existingDictionaryId = existingDocument.data()?["dictionaryId"] as? String
            let normalizedExistingDictionaryId = existingDictionaryId?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedIncomingDictionaryId = wordToSave.dictionaryId?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if let normalizedExistingDictionaryId,
               !normalizedExistingDictionaryId.isEmpty,
               normalizedExistingDictionaryId != normalizedIncomingDictionaryId {
                print("☁️ saveWord id conflict existingDict='\(normalizedExistingDictionaryId)' incomingDict='\(normalizedIncomingDictionaryId ?? "nil")' -> generating new id")
                wordId = UUID().uuidString
            }
        }

        wordToSave.id = wordId
        wordToSave.userId = userId

        var wordData = try Firestore.Encoder().encode(wordToSave)
        wordData["createdAt"] = Timestamp(date: wordToSave.createdAt)

        if let nextReview = wordToSave.nextReviewDate {
            wordData["nextReviewDate"] = Timestamp(date: nextReview)
        }
        if let lastReview = wordToSave.lastReviewDate {
            wordData["lastReviewDate"] = Timestamp(date: lastReview)
        }

        try await rootWordsCollection(userId: userId)
            .document(wordId)
            .setData(wordData, merge: true)

        if let dictionaryId = wordToSave.dictionaryId?.trimmingCharacters(in: .whitespacesAndNewlines),
           !dictionaryId.isEmpty {
            try await dictionaryWordsCollection(userId: userId, dictionaryId: dictionaryId)
                .document(wordId)
                .setData(wordData, merge: true)
        }

        print("☁️ saveWord stored original='\(wordToSave.original)' id='\(wordId)' dictionaryId='\(wordToSave.dictionaryId ?? "nil")'")

        NotificationCenter.default.post(name: .wordSaved, object: nil)
    }
    
    func updateWord(_ word: SavedWordModel) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotFound
        }
        
        guard let wordId = word.id else {
            throw AuthError.wordNotFound
        }
        
        var wordData = try Firestore.Encoder().encode(word)
        wordData["createdAt"] = Timestamp(date: word.createdAt)
        if let nextReview = word.nextReviewDate {
            wordData["nextReviewDate"] = Timestamp(date: nextReview)
        }
        if let lastReview = word.lastReviewDate {
            wordData["lastReviewDate"] = Timestamp(date: lastReview)
        }
        
        try await rootWordsCollection(userId: userId)
            .document(wordId)
            .setData(wordData, merge: true)

        if let dictionaryId = word.dictionaryId?.trimmingCharacters(in: .whitespacesAndNewlines),
           !dictionaryId.isEmpty {
            try await dictionaryWordsCollection(userId: userId, dictionaryId: dictionaryId)
                .document(wordId)
                .setData(wordData, merge: true)
        }
    }
    
    func updateWordStatus(wordId: String, isLearned: Bool) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotFound
        }
        
        try await db.collection("users")
            .document(userId)
            .collection("words")
            .document(wordId)
            .updateData([
                "isLearned": isLearned,
                "updatedAt": Timestamp(date: Date())
            ])
    }
    
    func updateWordSRS(wordId: String, updates: [String: Any]) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotFound
        }
        
        var updatesWithTimestamp = updates
        updatesWithTimestamp["lastReviewDate"] = Timestamp(date: Date())
        
        try await db.collection("users")
            .document(userId)
            .collection("words")
            .document(wordId)
            .updateData(updatesWithTimestamp)
    }
    
    func deleteWord(wordId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotFound
        }
        
        try await rootWordsCollection(userId: userId)
            .document(wordId)
            .delete()
    }

    func deleteWord(_ word: SavedWordModel) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotFound
        }

        guard let wordId = word.id else {
            throw AuthError.wordNotFound
        }

        try await rootWordsCollection(userId: userId)
            .document(wordId)
            .delete()

        if let dictionaryId = word.dictionaryId?.trimmingCharacters(in: .whitespacesAndNewlines),
           !dictionaryId.isEmpty {
            try await dictionaryWordsCollection(userId: userId, dictionaryId: dictionaryId)
                .document(wordId)
                .delete()
        }
    }

    func deleteDictionary(dictionaryId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotFound
        }

        let rootWordsSnapshot = try await rootWordsCollection(userId: userId)
            .whereField("dictionaryId", isEqualTo: dictionaryId)
            .getDocuments()

        for document in rootWordsSnapshot.documents {
            try await rootWordsCollection(userId: userId)
                .document(document.documentID)
                .delete()
        }

        let dictionaryWordsSnapshot = try await dictionaryWordsCollection(userId: userId, dictionaryId: dictionaryId)
            .getDocuments()

        for document in dictionaryWordsSnapshot.documents {
            try await dictionaryWordsCollection(userId: userId, dictionaryId: dictionaryId)
                .document(document.documentID)
                .delete()
        }

        try await dictionariesCollection(userId: userId)
            .document(dictionaryId)
            .delete()
    }
    
    func fetchWords() async throws -> [SavedWordModel] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotFound
        }
        
        let snapshot = try await rootWordsCollection(userId: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            do {
                var word = try doc.data(as: SavedWordModel.self)
                word.id = doc.documentID
                return word
            } catch {
                print("❌ Failed to decode word: \(error)")
                return nil
            }
        }
    }
    
    func getWordsDueForReview() async throws -> [SavedWordModel] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotFound
        }
        
        let now = Timestamp(date: Date())
        
        let snapshot = try await rootWordsCollection(userId: userId)
            .whereField("isLearned", isEqualTo: false)
            .whereField("nextReviewDate", isLessThanOrEqualTo: now)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            do {
                var word = try doc.data(as: SavedWordModel.self)
                word.id = doc.documentID
                return word
            } catch {
                print("❌ Failed to decode due word: \(error)")
                return nil
            }
        }
    }
    
    func getNewWords() async throws -> [SavedWordModel] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotFound
        }
        
        let snapshot = try await rootWordsCollection(userId: userId)
            .whereField("srsRepetition", isEqualTo: 0)
            .whereField("reviewCount", isEqualTo: 0)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            do {
                var word = try doc.data(as: SavedWordModel.self)
                word.id = doc.documentID
                return word
            } catch {
                print("❌ Failed to decode new word: \(error)")
                return nil
            }
        }
    }
    
    // MARK: - Real-time Listeners
    
    func addWordsListener(completion: @escaping ([SavedWordModel]) -> Void) -> ListenerRegistration? {
        guard let userId = Auth.auth().currentUser?.uid else {
            return nil
        }
        
        return rootWordsCollection(userId: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let words = documents.compactMap { doc -> SavedWordModel? in
                    do {
                        var word = try doc.data(as: SavedWordModel.self)
                        word.id = doc.documentID
                        return word
                    } catch {
                        print("❌ Failed to decode listener word: \(error)")
                        return nil
                    }
                }
                
                completion(words)
            }
    }

    func fetchWords(in dictionaryId: String) async throws -> [SavedWordModel] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotFound
        }

        let snapshot = try await dictionaryWordsCollection(userId: userId, dictionaryId: dictionaryId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            do {
                var word = try doc.data(as: SavedWordModel.self)
                word.id = doc.documentID
                word.dictionaryId = dictionaryId
                return word
            } catch {
                print("❌ Failed to decode dictionary word: \(error)")
                return nil
            }
        }
    }
    
    // MARK: - Search History
    
    func logSearch(query: String, result: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let data: [String: Any] = [
            "query": query,
            "result": result,
            "timestamp": Timestamp(date: Date()),
            "userId": userId
        ]
        
        try await db.collection("users")
            .document(userId)
            .collection("searchHistory")
            .addDocument(data: data)
    }
    
    // MARK: - Learning Days (Streak)
    
    func getLearningDays() async throws -> [LearningDayModel] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotFound
        }
        
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("learningDays")
            .order(by: "date", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: LearningDayModel.self)
        }
    }
    
    func saveLearningDay(_ day: LearningDayModel) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotFound
        }
        
        let dayId = ISO8601DateFormatter().string(from: day.date)
        
        try db.collection("users")
            .document(userId)
            .collection("learningDays")
            .document(dayId)
            .setData(from: day)
    }
    
    // MARK: - Save Words Batch (для міграції)
    func saveWordsBatch(_ words: [SavedWordModel]) async throws {
        guard Auth.auth().currentUser?.uid != nil else {
            throw NSError(domain: "FirestoreService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        for word in words {
            try await saveWord(word)
        }
    }
}

// MARK: - Learning Day Model
struct LearningDayModel: Identifiable, Codable {
    @DocumentID var id: String?
    var date: Date
    var wordsLearned: Int
    var timeSpent: Int // секунди
    
    init(date: Date = Date(), wordsLearned: Int = 0, timeSpent: Int = 0) {
        self.date = date
        self.wordsLearned = wordsLearned
        self.timeSpent = timeSpent
    }
}

// MARK: - Auth Error
enum AuthError: Error {
    case notAnonymous
    case invalidCredential
    case userNotFound
    case wordNotFound
    
    var localizedDescription: String {
        switch self {
        case .notAnonymous:
            return "Користувач не анонімний"
        case .invalidCredential:
            return "Невірні облікові дані"
        case .userNotFound:
            return "Користувача не знайдено"
        case .wordNotFound:
            return "Слово не знайдено"
        }
    }
}
