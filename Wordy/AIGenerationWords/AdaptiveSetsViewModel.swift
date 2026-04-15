import Foundation
import Combine

@MainActor
final class AdaptiveSetsViewModel: ObservableObject {
    @Published private(set) var overview: WordSetCatalogOverview?
    @Published private(set) var searchResults: [Word] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSearching = false
    @Published var errorMessage: String?

    var hasRemoteContent: Bool {
        overview?.hasRemoteContent == true
    }

    var availableSets: [WordSet] {
        overview?.difficultySets ?? []
    }

    var availableCategories: [WordSetCategorySummary] {
        overview?.categories ?? []
    }

    func loadOverview(for languagePair: LanguagePair, force: Bool = false) async {
        if !force, overview?.languagePair == languagePair.languagePairString {
            return
        }

        if force {
            WordSetCatalogService.shared.invalidateCache(for: languagePair)
        }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let remoteOverview = try await WordSetCatalogService.shared.fetchOverview(
                languagePair: languagePair,
                forceRefresh: force
            )
            overview = remoteOverview
        } catch {
            errorMessage = error.localizedDescription
            overview = nil
        }
    }

    func loadWords(
        for category: WordCategory,
        difficulty: DifficultyLevel?,
        languagePair: LanguagePair
    ) async -> [Word] {
        do {
            return try await WordSetCatalogService.shared.fetchWords(
                category: category,
                difficulty: difficulty,
                languagePair: languagePair
            )
        } catch {
            errorMessage = error.localizedDescription
            return []
        }
    }

    func loadDifficultyWords(
        _ difficulty: DifficultyLevel,
        languagePair: LanguagePair
    ) async -> [Word] {
        do {
            return try await WordSetCatalogService.shared.fetchWords(
                difficulty: difficulty,
                languagePair: languagePair
            )
        } catch {
            errorMessage = error.localizedDescription
            return []
        }
    }

    func search(query: String, languagePair: LanguagePair) async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        defer { isSearching = false }

        do {
            searchResults = try await WordSetCatalogService.shared.searchWords(
                query: trimmedQuery,
                languagePair: languagePair
            )
        } catch {
            errorMessage = error.localizedDescription
            searchResults = []
        }
    }
}
