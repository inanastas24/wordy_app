import Foundation
import Combine
import SwiftUI

@MainActor
final class TranslationViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case success(WordCard)
        case error(TranslationError)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var resultSource: BackendTranslationUseCaseResult.Source = .network
    @Published private(set) var debugProvider: String = "unknown"
    @Published private(set) var latestQuery: String = ""

    private let useCase: BackendTranslationUseCase
    private var debounceTask: Task<Void, Never>?
    private var translationTask: Task<Void, Never>?
    private var searchToken: UUID?
    private var inFlightRequestKey: String?
    private var lastLanguages: (source: String, target: String)?

    init(useCase: BackendTranslationUseCase? = nil) {
        self.useCase = useCase ?? BackendTranslationUseCase()
    }

    func updateSearchText(_ text: String, sourceLanguage: String, targetLanguage: String) {
        latestQuery = text
        lastLanguages = (sourceLanguage, targetLanguage)
        debounceTask?.cancel()

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            translationTask?.cancel()
            state = .idle
            return
        }
    }

    func retry() {
        guard let lastLanguages else { return }
        searchNow(query: latestQuery, sourceLanguage: lastLanguages.source, targetLanguage: lastLanguages.target, inputMethod: "retry")
    }

    func searchNow(query: String, sourceLanguage: String, targetLanguage: String, inputMethod: String = "typed") {
        latestQuery = query
        lastLanguages = (sourceLanguage, targetLanguage)
        debounceTask?.cancel()
        Task { [weak self] in
            await self?.performSearch(query: query, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage, inputMethod: inputMethod)
        }
    }

    private func performSearch(query: String, sourceLanguage: String, targetLanguage: String, inputMethod: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            translationTask?.cancel()
            inFlightRequestKey = nil
            state = .idle
            return
        }

        let requestKey = makeRequestKey(
            query: trimmed,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )

        if inFlightRequestKey == requestKey {
            return
        }

        translationTask?.cancel()

        let token = UUID()
        searchToken = token
        inFlightRequestKey = requestKey
        if let cached = await useCase.cachedWordCard(
            text: trimmed,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        ) {
            resultSource = .cache
            debugProvider = "cache_preload"
            state = .success(cached)
        } else {
            state = .loading
        }
        print("[TranslationViewModel] search started text=\(trimmed)")
        let startedAt = Date()
        AnalyticsService.shared.trackSearchSubmitted(
            queryLength: trimmed.count,
            sourceLang: sourceLanguage,
            targetLang: targetLanguage,
            inputMethod: inputMethod
        )

        translationTask = Task { [weak self] in
            guard let self else { return }

            do {
                let result = try await useCase.translate(
                    text: trimmed,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage
                )
                guard !Task.isCancelled, self.searchToken == token else { return }
                self.inFlightRequestKey = nil
                self.resultSource = result.source
                self.debugProvider = result.debugProvider
                self.state = .success(result.wordCard)
                AnalyticsService.shared.trackTranslationSuccess(
                    sourceLang: sourceLanguage,
                    targetLang: targetLanguage,
                    inputType: result.wordCard.inputType.rawValue,
                    latencyMs: Int(Date().timeIntervalSince(startedAt) * 1000),
                    hasMeanings: !result.wordCard.meanings.isEmpty,
                    hasExamples: !result.wordCard.examples.isEmpty,
                    hasSynonyms: !result.wordCard.synonyms.isEmpty,
                    hasAntonyms: !result.wordCard.antonyms.isEmpty
                )
            } catch is CancellationError {
                if self.searchToken == token {
                    self.inFlightRequestKey = nil
                }
                return
            } catch let error as TranslationError {
                guard !Task.isCancelled, self.searchToken == token else { return }
                self.inFlightRequestKey = nil
                if case .success = self.state, self.resultSource == .cache {
                    return
                }
                self.state = .error(error)
                AnalyticsService.shared.trackTranslationError(
                    sourceLang: sourceLanguage,
                    targetLang: targetLanguage,
                    errorType: "translation_error"
                )
            } catch {
                guard !Task.isCancelled, self.searchToken == token else { return }
                self.inFlightRequestKey = nil
                if case .success = self.state, self.resultSource == .cache {
                    return
                }
                self.state = .error(.networkError(error))
                AnalyticsService.shared.trackTranslationError(
                    sourceLang: sourceLanguage,
                    targetLang: targetLanguage,
                    errorType: "network_error"
                )
            }
        }
    }

    private func makeRequestKey(query: String, sourceLanguage: String, targetLanguage: String) -> String {
        "\(query.lowercased())|\(sourceLanguage.lowercased())|\(targetLanguage.lowercased())"
    }
}
