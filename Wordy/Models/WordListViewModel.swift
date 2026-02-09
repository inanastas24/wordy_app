//1
//  WordListViewModel.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 07.02.2026.
//

import Foundation
import Combine

/// ViewModel для списку слів - делегує роботу DictionaryViewModel
/// Цей клас можна використовувати для специфічної логіки списку слів
@MainActor
class WordListViewModel: ObservableObject {
    static let shared = WordListViewModel()
    
    @Published var words: [SavedWordModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Делегуємо роботу DictionaryViewModel
    private let dictionaryVM = DictionaryViewModel.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Слухаємо зміни в DictionaryViewModel
        dictionaryVM.$savedWords
            .receive(on: DispatchQueue.main)
            .sink { [weak self] words in
                self?.words = words
            }
            .store(in: &cancellables)
        
        dictionaryVM.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.isLoading = isLoading
            }
            .store(in: &cancellables)
        
        dictionaryVM.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.errorMessage = error
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func fetchWords() {
        dictionaryVM.fetchSavedWords()
    }
    
    func addWord(_ word: SavedWordModel) {
        dictionaryVM.saveWord(word)
    }
    
    func deleteWord(id: String) {
        dictionaryVM.deleteWord(id)
    }
    
    func updateWord(_ word: SavedWordModel) {
        dictionaryVM.updateWord(word)
    }
    
    func markAsLearned(wordId: String) {
        dictionaryVM.markAsLearned(wordId: wordId)
    }
    
    func markAsUnlearned(wordId: String) {
        dictionaryVM.markAsUnlearned(wordId: wordId)
    }
    
    // MARK: - Computed Properties
    
    var learningWords: [SavedWordModel] {
        dictionaryVM.learningWords
    }
    
    var learnedWords: [SavedWordModel] {
        dictionaryVM.learnedWords
    }
    
    var learningCount: Int {
        dictionaryVM.learningCount
    }
    
    var learnedCount: Int {
        dictionaryVM.learnedCount
    }
    
    var totalWords: Int {
        dictionaryVM.totalWords
    }
    
    var wordsDueForReview: [SavedWordModel] {
        dictionaryVM.wordsDueForReview
    }
    
    var newWords: [SavedWordModel] {
        dictionaryVM.newWords
    }
    
    // MARK: - Cleanup
    
    func stopListening() {
        dictionaryVM.stopListening()
    }
}
