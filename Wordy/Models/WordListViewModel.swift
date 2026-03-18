//
//  WordListViewModel.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 07.02.2026.
//

import Foundation
import Combine

@MainActor
final class WordListViewModel: ObservableObject {
    static let shared = WordListViewModel()

    @Published var words: [SavedWordModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let dictionaryVM = DictionaryViewModel.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
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

    func addWords(_ words: [SavedWordModel]) {
        dictionaryVM.saveWords(words)
    }

    func deleteWord(_ word: SavedWordModel) {
        dictionaryVM.deleteWord(word)
    }

    func deleteWord(id: String) {
        guard let word = dictionaryVM.savedWords.first(where: { $0.id == id }) else { return }
        dictionaryVM.deleteWord(word)
    }

    func updateWord(_ word: SavedWordModel) {
        dictionaryVM.saveWord(word)
    }

    func markAsLearned(wordId: String) {
        dictionaryVM.markAsLearned(wordId: wordId)
    }

    func markAsUnlearned(wordId: String) {
        dictionaryVM.markAsUnlearned(wordId: wordId)
    }

    func stopListening() {
        dictionaryVM.stopListening()
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
        dictionaryVM.savedWords.count
    }

    var wordsDueForReview: [SavedWordModel] {
        dictionaryVM.learningWords.filter { $0.isDueForReview }
    }

    var newWords: [SavedWordModel] {
        dictionaryVM.learningWords.filter { $0.reviewCount == 0 }
    }
}
