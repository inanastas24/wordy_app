# Translation Engine Architecture

## File Map

```text
Wordy/TranslationEngine/
  TranslationEngineModels.swift
  TranslationEngineProtocols.swift
  TranslationEngineCore.swift
  TranslationEngineComponents.swift
  TranslationEngineAdapters.swift

WordyTests/TranslationEngine/
  TranslationEngineTests.swift
```

## Class Responsibilities

- `TranslationUseCase`
  - Public entrypoint for UI/ViewModel.
  - Normalized cache lookup by `normalizedText + sourceLanguage + targetLanguage + engineVersion`.

- `TranslationEngineCore`
  - Orchestrates the pipeline.
  - Calls providers concurrently.
  - Emits debug logs for each stage.

- `DefaultTranslationInputNormalizer`
  - Trims spaces.
  - Collapses repeated spaces.
  - Preserves original text.
  - Detects `singleWord | phrase | idiom | phrasalVerb | namedEntity`.

- `DefaultCandidateGenerator`
  - Builds candidates from:
    - direct translation
    - meaning.definitionTranslation
    - example.targetText
    - synonym.translation

- `DefaultCandidateClassifier`
  - Routes candidates into:
    - `canonicalTranslation`
    - `relatedPhrase`
    - `exampleFragment`
    - `namedEntity`
    - `invalid`

- `DefaultTranslationOptionBuilder`
  - Creates only canonical translation options.
  - Preserves `meaningId`, `sourceType`, `confidence`.

- `DefaultExampleLinker`
  - Links examples by `meaningId` first, then `translationOptionId`.

- `DefaultRelatedPhraseBuilder`
  - Collects collocations and named examples outside of `translations[]`.

- `DefaultDeduplicationService`
  - Merges by `value + POS + meaningId`.
  - Prioritizes `direct` over `contextual`.

- `TranslationValidationService`
  - Rejects sentence fragments, named entities, and empty options.

- `DefaultWordCardBuilder`
  - Produces final `EngineWordCard`.

- `TranslationEngineAdapters`
  - Bridges `EngineWordCard` into current `TranslationResult` / `SavedWordModel`.

## Pipeline

```text
1. Normalize input
2. Detect input type
3. Fetch direct translation
4. Fetch meanings
5. Fetch examples
6. Fetch synonyms
7. Generate candidates
8. Classify candidates
9. Build translation options
10. Link examples
11. Deduplicate
12. Validate
13. Build WordCard
```

## Candidate Classifier Rules

- `canonicalTranslation`
  - Short canonical output.
  - Usually 1-2 words, or phrase-level for idiom/phrasal verb input.

- `relatedPhrase`
  - 2-4 word collocations for single-word input.
  - Useful for learning, but not a canonical translation.

- `exampleFragment`
  - Sentence-like output.
  - Punctuation-heavy or long contextual fragments.

- `namedEntity`
  - Multi-token title-cased entities like `Caspian Sea`.
  - Move to `relatedPhrases[]` or drop.

- `invalid`
  - Empty / garbage / malformed candidate.

## Validation Rules

- `translations[]` must not contain:
  - empty strings
  - 5+ token fragments
  - title-cased named entities

- Each `TranslationOption` should have:
  - `meaningId` or strong `sourceType`
  - at least one linked example when available

- Final card must contain:
  - source language
  - target language
  - main translation

## Integration Recommendations

1. Add `TranslationSearchViewModel`
   - Move debounce, cancellation, loading/error state out of `SearchView`.
   - Inject `TranslationUseCase`.

2. Keep `SearchView` render-only
   - `SearchView` should receive `TranslationResult` or `WordCard` from ViewModel.
   - No translation side-effects inside the view.

3. Replace direct `TranslationService` calls incrementally
   - First bridge `EngineWordCard.asTranslationResult()`.
   - Then migrate UI from `TranslationResult` to `WordCard`.

4. Store engine result directly
   - Use `EngineWordCard.asSavedWordModel(dictionaryId:)`.
   - This already maps into current `SavedWordModel` storage.

5. Keep provider implementations swappable
   - Wrap current DeepL / dictionary / Tatoeba logic behind:
     - `DirectTranslationProviding`
     - `MeaningProviding`
     - `ExampleProviding`
     - `SynonymProviding`

6. Deprecate `QueryNormalizer` for translation search
   - Current implementation is English-centric.
   - Keep it only for legacy dictionary dedupe until storage is migrated.
