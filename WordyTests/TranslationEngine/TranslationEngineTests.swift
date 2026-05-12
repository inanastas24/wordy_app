import Foundation
import Testing
@testable import Wordy

struct TranslationEngineTests {
    @Test
    func normalizerDetectsPhrasalVerb() throws {
        let normalizer = DefaultTranslationInputNormalizer()

        let result = try normalizer.normalize(
            text: "  Give   Up ",
            sourceLanguage: "en",
            targetLanguage: "uk"
        )

        #expect(result.normalizedText == "give up")
        #expect(result.inputType == .phrasalVerb)
        #expect(result.originalText == "Give   Up")
    }

    @Test
    func classifierRejectsSentenceFragments() {
        let classifier = DefaultCandidateClassifier()
        let candidate = EngineTranslationCandidate(
            id: "1",
            rawValue: "в кімнаті світло",
            normalizedValue: "в кімнаті світло",
            partOfSpeech: .noun,
            meaningId: nil,
            sourceType: .contextual,
            origin: .exampleContext,
            sourceHint: "example",
            confidence: 0.4,
            exampleIds: []
        )
        let input = try! DefaultTranslationInputNormalizer().normalize(
            text: "light",
            sourceLanguage: "en",
            targetLanguage: "uk"
        )

        let result = classifier.classify(candidate, input: input, meanings: [])

        #expect(result.type == .exampleFragment)
    }

    @Test
    func classifierRoutesCollocationToRelatedPhrases() {
        let classifier = DefaultCandidateClassifier()
        let candidate = EngineTranslationCandidate(
            id: "2",
            rawValue: "морський порт",
            normalizedValue: "морський порт",
            partOfSpeech: .noun,
            meaningId: nil,
            sourceType: .contextual,
            origin: .exampleContext,
            sourceHint: "example.targetText",
            confidence: 0.4,
            exampleIds: []
        )
        let input = try! DefaultTranslationInputNormalizer().normalize(
            text: "sea",
            sourceLanguage: "en",
            targetLanguage: "uk"
        )

        let result = classifier.classify(candidate, input: input, meanings: [])

        #expect(result.type == .relatedPhrase)
    }

    @Test
    func builderDoesNotCreateTranslationFromExampleOrSynonymCandidates() {
        let builder = DefaultTranslationOptionBuilder()
        let examples = [
            EngineExample(
                id: "e1",
                sourceText: "Turn on the light.",
                targetText: "Увімкни світло.",
                meaningId: "m1",
                translationOptionId: nil,
                difficulty: "A1",
                isSensitive: false
            )
        ]
        let meaning = EngineMeaning(
            id: "m1",
            definition: "visible light",
            definitionTranslation: "світло",
            partOfSpeech: .noun,
            domain: nil,
            examples: examples,
            rank: 0
        )
        let classified: [EngineClassifiedCandidate] = [
            EngineClassifiedCandidate(
                id: "canon",
                candidate: EngineTranslationCandidate(
                    id: "canon",
                    rawValue: "світло",
                    normalizedValue: "світло",
                    partOfSpeech: .noun,
                    meaningId: "m1",
                    sourceType: .meaningDerived,
                    origin: .meaningTranslation,
                    sourceHint: "meaning",
                    confidence: 0.8,
                    exampleIds: ["e1"]
                ),
                type: .canonicalTranslation,
                confidenceAdjustment: 0
            ),
            EngineClassifiedCandidate(
                id: "example",
                candidate: EngineTranslationCandidate(
                    id: "example",
                    rawValue: "у кімнаті світло",
                    normalizedValue: "у кімнаті світло",
                    partOfSpeech: .noun,
                    meaningId: "m1",
                    sourceType: .contextual,
                    origin: .exampleContext,
                    sourceHint: "example",
                    confidence: 0.4,
                    exampleIds: ["e1"]
                ),
                type: .canonicalTranslation,
                confidenceAdjustment: 0
            ),
            EngineClassifiedCandidate(
                id: "syn",
                candidate: EngineTranslationCandidate(
                    id: "syn",
                    rawValue: "освітлення",
                    normalizedValue: "освітлення",
                    partOfSpeech: .noun,
                    meaningId: "m1",
                    sourceType: .contextual,
                    origin: .synonymContext,
                    sourceHint: "synonym",
                    confidence: 0.4,
                    exampleIds: []
                ),
                type: .canonicalTranslation,
                confidenceAdjustment: 0
            )
        ]
        let input = try! DefaultTranslationInputNormalizer().normalize(
            text: "light",
            sourceLanguage: "en",
            targetLanguage: "uk"
        )

        let result = builder.buildOptions(
            from: classified,
            meanings: [meaning],
            examples: examples,
            input: input
        )

        #expect(result.count == 1)
        #expect(result.first?.value == "світло")
    }

    @Test
    func validatorFlagsCollocationsAndServicePhrases() {
        let validator = TranslationValidationService()
        let card = EngineWordCard(
            originalText: "sea",
            normalizedText: "sea",
            sourceLanguage: "en",
            targetLanguage: "uk",
            mainTranslation: "морський порт",
            translations: [
                EngineTranslationOption(
                    id: "bad-1",
                    value: "морський порт",
                    partOfSpeech: .noun,
                    meaningId: "m1",
                    sourceType: .direct,
                    confidence: 0.8,
                    examples: [
                        EngineExample(
                            id: "e",
                            sourceText: "The port is large.",
                            targetText: "Порт великий.",
                            meaningId: "m1",
                            translationOptionId: "bad-1",
                            difficulty: nil,
                            isSensitive: false
                        )
                    ]
                ),
                EngineTranslationOption(
                    id: "bad-2",
                    value: "до моря",
                    partOfSpeech: .phrase,
                    meaningId: "m2",
                    sourceType: .direct,
                    confidence: 0.8,
                    examples: [
                        EngineExample(
                            id: "e2",
                            sourceText: "We went to the sea.",
                            targetText: "Ми пішли до моря.",
                            meaningId: "m2",
                            translationOptionId: "bad-2",
                            difficulty: nil,
                            isSensitive: false
                        )
                    ]
                )
            ],
            meanings: [],
            examples: [],
            synonyms: [],
            relatedPhrases: []
        )

        let issues = validator.validate(card)

        #expect(issues.contains(.collocationTranslation("морський порт")))
        #expect(issues.contains(.servicePhraseTranslation("до моря")))
    }

    @Test
    func validatorFlagsUnlinkedTranslations() {
        let validator = TranslationValidationService()
        let card = EngineWordCard(
            originalText: "bank",
            normalizedText: "bank",
            sourceLanguage: "en",
            targetLanguage: "uk",
            mainTranslation: "банк",
            translations: [
                EngineTranslationOption(
                    id: "bank-1",
                    value: "банк",
                    partOfSpeech: .noun,
                    meaningId: "m1",
                    sourceType: .direct,
                    confidence: 0.9,
                    examples: []
                )
            ],
            meanings: [],
            examples: [],
            synonyms: [],
            relatedPhrases: []
        )

        let issues = validator.validate(card)

        #expect(issues.contains(.unlinkedTranslation("bank-1")))
    }

    @Test
    func useCaseBuildsPolysemousWordCard() async throws {
        let useCase = TranslationUseCase(
            engine: TranslationEngineCore(
                normalizer: DefaultTranslationInputNormalizer(),
                providers: TranslationProviderRegistry(
                    directProvider: MockDirectProvider(),
                    meaningProvider: MockMeaningProvider(),
                    exampleProvider: MockExampleProvider(),
                    synonymProvider: MockSynonymProvider()
                ),
                candidateGenerator: DefaultCandidateGenerator(),
                classifier: DefaultCandidateClassifier(),
                optionBuilder: DefaultTranslationOptionBuilder(),
                exampleLinker: DefaultExampleLinker(),
                relatedPhraseBuilder: DefaultRelatedPhraseBuilder(),
                deduplicator: DefaultDeduplicationService(),
                validator: TranslationValidationService(),
                wordCardBuilder: DefaultWordCardBuilder()
            ),
            cache: InMemoryTranslationCache()
        )

        let result = try await useCase.translate(
            text: "bank",
            sourceLanguage: "en",
            targetLanguage: "uk"
        )

        #expect(result.translations.count == 2)
        #expect(result.translations.contains(where: { $0.value == "банк" }))
        #expect(result.translations.contains(where: { $0.value == "берег" }))
        #expect(result.translations.allSatisfy { !$0.examples.isEmpty })
    }
}

private struct MockDirectProvider: DirectTranslationProviding {
    func fetchDirectTranslations(for input: EngineNormalizedInput) async throws -> [EngineDirectTranslation] {
        [
            EngineDirectTranslation(
                id: "direct-1",
                value: "банк",
                partOfSpeech: .noun,
                confidence: 0.93,
                source: .direct
            )
        ]
    }
}

private struct MockMeaningProvider: MeaningProviding {
    func fetchMeanings(for input: EngineNormalizedInput) async throws -> [EngineMeaning] {
        [
            EngineMeaning(
                id: "m1",
                definition: "financial institution",
                definitionTranslation: "банк",
                partOfSpeech: .noun,
                domain: "finance",
                examples: [],
                rank: 0
            ),
            EngineMeaning(
                id: "m2",
                definition: "land alongside a river",
                definitionTranslation: "берег",
                partOfSpeech: .noun,
                domain: "geography",
                examples: [],
                rank: 1
            )
        ]
    }
}

private struct MockExampleProvider: ExampleProviding {
    func fetchExamples(for input: EngineNormalizedInput, meanings: [EngineMeaning]) async throws -> [EngineExample] {
        [
            EngineExample(
                id: "e1",
                sourceText: "I went to the bank.",
                targetText: "Я пішов до банку.",
                meaningId: "m1",
                translationOptionId: nil,
                difficulty: "A2",
                isSensitive: false
            ),
            EngineExample(
                id: "e2",
                sourceText: "They sat on the river bank.",
                targetText: "Вони сиділи на березі річки.",
                meaningId: "m2",
                translationOptionId: nil,
                difficulty: "B1",
                isSensitive: false
            )
        ]
    }
}

private struct MockSynonymProvider: SynonymProviding {
    func fetchSynonyms(for input: EngineNormalizedInput, meanings: [EngineMeaning]) async throws -> [EngineSynonym] {
        [
            EngineSynonym(
                id: "s1",
                word: "shore",
                translation: nil,
                meaningId: "m2",
                contextDefinition: "land alongside a river",
                isMeaningValidated: true,
                confidence: 0.6
            )
        ]
    }
}
