import Foundation

struct BackendTranslationUseCaseResult {
    enum Source {
        case network
        case cache
    }

    let wordCard: WordCard
    let source: Source
    let debugProvider: String
}

struct BackendTranslationUseCase {
    private let apiClient: WordyTranslationAPIClient
    private let cache: TranslationCache
    private let defaultEngineVersion: String
    private let qualityPostProcessor = TranslationQualityPostProcessor()
    private let providerChainService: ProviderChainTranslationService
    private let enableTranscriptionFallback: Bool

    init(
        apiClient: WordyTranslationAPIClient = WordyTranslationAPIClient(),
        cache: TranslationCache = .shared,
        configService: ConfigService = .shared
    ) {
        self.apiClient = apiClient
        self.cache = cache
        self.defaultEngineVersion = configService.get("WORDY_BACKEND_ENGINE_VERSION") ?? "v1"
        self.providerChainService = ProviderChainTranslationService(configService: configService)
        self.enableTranscriptionFallback = (configService.get("WORDY_ENABLE_TRANSCRIPTION_FALLBACK") ?? "false").lowercased() == "true"
    }

    func cachedWordCard(
        text: String,
        sourceLanguage: String,
        targetLanguage: String
    ) async -> WordCard? {
        let cacheKeyText = TranslationCache.canonicalCacheText(text)
        return await cache.wordCard(
            normalizedText: cacheKeyText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            backendEngineVersion: defaultEngineVersion
        )
    }

    func translate(
        text: String,
        sourceLanguage: String,
        targetLanguage: String
    ) async throws -> BackendTranslationUseCaseResult {
        _ = QueryNormalizer.normalize(
            text,
            language: sourceLanguage,
            trigger: "TranslationUseCase.translate"
        )
        let cacheKeyText = TranslationCache.canonicalCacheText(text)

        do {
            let rawCard = try await apiClient.translate(
                text: text,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage
            )
            var wordCard = rawCard
            if enableTranscriptionFallback,
               isMissingTranscription(wordCard),
               let providerResult = try? await providerChainService.translate(
                text: text,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage
               ) {
                let providerCard = providerResult.wordCard
                if !isMissingTranscription(providerCard) {
                    wordCard = WordCard(
                        id: wordCard.id,
                        originalText: wordCard.originalText,
                        normalizedText: wordCard.normalizedText,
                        sourceLanguage: wordCard.sourceLanguage,
                        targetLanguage: wordCard.targetLanguage,
                        inputType: wordCard.inputType,
                        mainTranslation: wordCard.mainTranslation,
                        translations: wordCard.translations,
                        meanings: wordCard.meanings,
                        examples: wordCard.examples,
                        synonyms: wordCard.synonyms,
                        antonyms: wordCard.antonyms,
                        relatedPhrases: wordCard.relatedPhrases,
                        createdAt: wordCard.createdAt,
                        updatedAt: wordCard.updatedAt,
                        backendEngineVersion: wordCard.backendEngineVersion,
                        pronunciation: providerCard.pronunciation,
                        ipaTranscription: providerCard.ipaTranscription,
                        idiomSemanticTranslation: wordCard.idiomSemanticTranslation,
                        idiomLiteralTranslation: wordCard.idiomLiteralTranslation
                    )
                    print("[TranslationUseCase] transcription-fallback source=provider_chain value='\(providerCard.pronunciation ?? providerCard.ipaTranscription ?? "")'")
                }
            } else if !enableTranscriptionFallback, isMissingTranscription(wordCard) {
                print("[TranslationUseCase] transcription-fallback skipped config=disabled")
            }
            let debugProvider = "backend"

            let translationsPreview = wordCard.translations.prefix(5).map(\.value).joined(separator: " | ")
            let examplePreview = wordCard.examples.first?.sourceText ?? "-"
            let meaningsWithExamples = wordCard.meanings.filter { meaning in
                wordCard.examples.contains(where: { $0.meaningId == meaning.id }) || !meaning.examples.isEmpty
            }.count
            print("[TranslationUseCase] postprocessed main='\(wordCard.mainTranslation)' raw='\(rawCard.mainTranslation)' translations=\(wordCard.translations.count) [\(translationsPreview)] meanings=\(wordCard.meanings.count) examples=\(wordCard.examples.count) mapped=\(meaningsWithExamples)/\(wordCard.meanings.count) firstExample='\(examplePreview)' provider='\(debugProvider)'")
            await cache.save(wordCard)
            return BackendTranslationUseCaseResult(wordCard: wordCard, source: .network, debugProvider: debugProvider)
        } catch let error as TranslationError {
            if shouldUseProviderChain(for: error),
               let providerResult = try? await providerChainService.translate(
                text: text,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage
               ) {
                let providerWordCard = qualityPostProcessor.process(providerResult.wordCard)
                await cache.save(providerWordCard)
                let translationsPreview = providerWordCard.translations.prefix(5).map(\.value).joined(separator: " | ")
                let examplePreview = providerWordCard.examples.first?.sourceText ?? "-"
                let meaningsWithExamples = providerWordCard.meanings.filter { meaning in
                    providerWordCard.examples.contains(where: { $0.meaningId == meaning.id }) || !meaning.examples.isEmpty
                }.count
                print("[TranslationUseCase] provider-chain emergency-fallback main='\(providerWordCard.mainTranslation)' translations=\(providerWordCard.translations.count) [\(translationsPreview)] meanings=\(providerWordCard.meanings.count) examples=\(providerWordCard.examples.count) mapped=\(meaningsWithExamples)/\(providerWordCard.meanings.count) firstExample='\(examplePreview)' reason='\(error.localizedDescription)'")
                return BackendTranslationUseCaseResult(wordCard: providerWordCard, source: .network, debugProvider: "provider_chain_emergency")
            }

            if let cached = await cache.wordCard(
                normalizedText: cacheKeyText,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                backendEngineVersion: defaultEngineVersion
            ), shouldUseCache(for: error) {
                let processed = cached
                print("[TranslationUseCase] cache-hit mainTranslation='\(processed.mainTranslation)'")
                return BackendTranslationUseCaseResult(
                    wordCard: processed,
                    source: .cache,
                    debugProvider: "cache"
                )
            }

            throw error
        } catch {
            if let cached = await cache.wordCard(
                normalizedText: cacheKeyText,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                backendEngineVersion: defaultEngineVersion
            ) {
                let processed = cached
                print("[TranslationUseCase] cache-fallback mainTranslation='\(processed.mainTranslation)'")
                return BackendTranslationUseCaseResult(
                    wordCard: processed,
                    source: .cache,
                    debugProvider: "cache"
                )
            }

            throw TranslationError.networkError(error)
        }
    }

    private func shouldUseCache(for error: TranslationError) -> Bool {
        switch error {
        case .backendUnavailable, .timeout, .networkError:
            return true
        default:
            return false
        }
    }

    private func shouldUseProviderChain(for error: TranslationError) -> Bool {
        switch error {
        case .backendUnavailable, .timeout, .networkError:
            return true
        default:
            return false
        }
    }

    private func isMissingTranscription(_ card: WordCard) -> Bool {
        let pronunciation = card.pronunciation?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let ipa = card.ipaTranscription?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !pronunciation.isEmpty || !ipa.isEmpty { return false }
        return true
    }
}
