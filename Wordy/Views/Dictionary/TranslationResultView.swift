import SwiftUI
import UIKit

struct TranslationResultView: View {
    enum ResultTab: String, CaseIterable, Identifiable {
        case translation
        case meanings
        case examples
        case synonyms
        case related

        var id: String { rawValue }
    }

    let wordCard: WordCard
    var showsCloseButton: Bool = false
    var onClose: (() -> Void)? = nil
    var onSaveWordCard: (() -> Void)? = nil
    var isWordSavedInDictionary: Bool = false
    var onSaveTranslation: ((TranslationOption) -> Void)? = nil
    var onSaveExample: ((WordExample) -> Void)? = nil
    var onSaveSynonym: ((WordSynonym) -> Void)? = nil
    var onSearchSynonym: ((String) -> Void)? = nil
    var showsSourceWordInHeader: Bool = true

    @StateObject private var ttsManager = TextToSpeechService.shared
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var selectedTab: ResultTab = .translation
    @State private var showAllMeanings = false
    @State private var savedSynonymIds: Set<UUID> = []
    @State private var selectedTranslationFilter: String? = nil

    private var isIdiomCard: Bool {
        wordCard.inputType == .idiom
    }

    private var availableTabs: [ResultTab] {
        if isIdiomCard {
            var tabs: [ResultTab] = [.translation]
            if !wordCard.meanings.isEmpty { tabs.append(.meanings) }
            if !wordCard.examples.isEmpty { tabs.append(.examples) }
            if !wordCard.relatedPhrases.isEmpty { tabs.append(.related) }
            return tabs
        }

        var tabs: [ResultTab] = [.translation]
        if !meaningsWithExamplesOnly.isEmpty { tabs.append(.meanings) }
        if !wordCard.synonyms.isEmpty || !wordCard.antonyms.isEmpty || !wordCard.relatedPhrases.isEmpty {
            tabs.append(.synonyms)
        }
        return tabs
    }

    private var groupedTranslations: [(String, [TranslationOption])] {
        let groups = Dictionary(grouping: wordCard.translations) { option in
            let trimmed = option.partOfSpeech?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? localizedUnknownPOS : trimmed.lowercased()
        }

        let order: [String] = ["noun", "verb", "adjective", "adverb", "phrase", "unknown"]
        let sortedKeys = groups.keys.sorted { lhs, rhs in
            let l = order.firstIndex(of: lhs) ?? .max
            let r = order.firstIndex(of: rhs) ?? .max
            if l == r { return lhs < rhs }
            return l < r
        }

        return sortedKeys.map { ($0, groups[$0] ?? []) }
    }

    private var filteredMeanings: [MeaningContent] {
        guard let filter = selectedTranslationFilter?.trimmingCharacters(in: .whitespacesAndNewlines), !filter.isEmpty else {
            return wordCard.meanings
        }
        let normalizedFilter = normalizedDisplayToken(filter).lowercased()
        return wordCard.meanings.filter { meaning in
            meaning.translations.contains { normalizedDisplayToken($0.value).lowercased() == normalizedFilter }
        }
    }

    private var meaningsWithExamplesOnly: [MeaningContent] {
        filteredMeanings.filter { meaning in
            hasExample(for: meaning)
        }
    }

    private var displayedMeanings: [MeaningContent] {
        let source = meaningsWithExamplesOnly
        return showAllMeanings ? source : Array(source.prefix(2))
    }

    private func hasExample(for meaning: MeaningContent) -> Bool {
        if wordCard.examples.contains(where: { $0.meaningId == meaning.id }) {
            return true
        }
        if meaning.examples.contains(where: { !$0.sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            return true
        }
        return false
    }

    private var localizedIdiomMeaningLabel: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Ідіома"
        case .polish: return "Znaczenie idiomu"
        case .english: return "Idiom"
        }
    }

    private var localizedLiteralLabel: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Дослівно"
        case .polish: return "Dosłownie"
        case .english: return "Literal"
        }
    }

    private var idiomSemanticTranslation: String {
        let semantic = wordCard.idiomSemanticTranslation?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !semantic.isEmpty {
            return semantic
        }
        return wordCard.mainTranslation
    }

    private var idiomLiteralTranslation: String? {
        let literal = wordCard.idiomLiteralTranslation?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return literal.isEmpty ? nil : literal
    }

    private var idiomAdditionalTranslations: [TranslationOption] {
        let semantic = idiomSemanticTranslation.lowercased()
        let literal = idiomLiteralTranslation?.lowercased()
        return wordCard.translations.filter { option in
            let value = option.value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !value.isEmpty else { return false }
            if value == semantic { return false }
            if let literal, value == literal { return false }
            return true
        }
    }

    @ViewBuilder
    private func idiomLabeledTranslationRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(normalizedDisplayToken(value))
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(3)
                .truncationMode(.tail)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.secondary.opacity(0.10))
                )
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if showsCloseButton {
                    HStack {
                        Spacer()
                        Button(action: close) {
                            Image(systemName: "xmark")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)
                    }
                }

                WordHeaderView(
                    showsSourceWord: showsSourceWordInHeader,
                    inputType: wordCard.inputType,
                    word: wordCard.originalText,
                    transcription: wordCard.pronunciation ?? wordCard.ipaTranscription,
                    mainTranslation: wordCard.mainTranslation,
                    sourceLanguage: wordCard.sourceLanguage,
                    targetLanguage: wordCard.targetLanguage,
                    onSpeakWord: { ttsManager.speak(text: wordCard.mainTranslation, language: wordCard.targetLanguage) },
                    onSaveWord: onSaveWordCard,
                    isWordSavedInDictionary: isWordSavedInDictionary,
                    onCopyMainTranslation: { UIPasteboard.general.string = wordCard.mainTranslation }
                )

                Picker("Result Tab", selection: $selectedTab) {
                    ForEach(availableTabs) { tab in
                        Text(tabTitle(tab))
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .tint(Color(hex: "#4ECDC4"))
                .padding(.vertical, 2)

                tabContent
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .onAppear {
            print("[TranslationResultView] rendered WordCard id=\(wordCard.id)")
            AnalyticsService.shared.trackTabOpened(selectedTab.rawValue)
        }
        .onChange(of: selectedTab) { _, newTab in
            AnalyticsService.shared.trackTabOpened(newTab.rawValue)
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .translation:
            VStack(alignment: .leading, spacing: 16) {
                if isIdiomCard {
                    VStack(alignment: .leading, spacing: 10) {
                        idiomLabeledTranslationRow(
                            title: localizedIdiomMeaningLabel,
                            value: idiomSemanticTranslation
                        )

                        if let idiomLiteralTranslation,
                           !idiomLiteralTranslation.isEmpty,
                           idiomLiteralTranslation.caseInsensitiveCompare(idiomSemanticTranslation) != .orderedSame {
                            idiomLabeledTranslationRow(
                                title: localizedLiteralLabel,
                                value: idiomLiteralTranslation
                            )
                        }
                    }

                    if !idiomAdditionalTranslations.isEmpty {
                        TranslationChipFlowLayout(spacing: 8) {
                            ForEach(idiomAdditionalTranslations, id: \.id) { option in
                                Text(normalizedDisplayToken(option.value))
                                    .font(.subheadline)
                                    .foregroundStyle(Color.primary)
                                    .lineLimit(3)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: min(UIScreen.main.bounds.width * 0.72, 300), alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.secondary.opacity(0.10))
                                    )
                            }
                        }
                    }
                } else if !groupedTranslations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(groupedTranslations, id: \.0) { group in
                            TranslationGroupView(
                                partOfSpeechTitle: localizedPartOfSpeech(group.0),
                                options: group.1,
                                selectedValue: selectedTranslationFilter,
                                onSelect: { value in
                                    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if selectedTranslationFilter == trimmed {
                                        selectedTranslationFilter = nil
                                    } else {
                                        selectedTranslationFilter = trimmed
                                    }
                                    showAllMeanings = false
                                }
                            )
                        }
                    }
                }
            }

        case .meanings:
            VStack(alignment: .leading, spacing: 12) {
                Text(isIdiomCard ? localizedMeaningTitle : localizedInterpretationTitle)
                    .font(.title3.weight(.semibold))

                if wordCard.meanings.isEmpty {
                    Text(localizedMeaningUnavailable)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    if let selectedTranslationFilter, !selectedTranslationFilter.isEmpty {
                        HStack(spacing: 8) {
                            Text(localizedManagerText(uk: "Фільтр:", pl: "Filtr:", en: "Filter:"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(normalizedDisplayToken(selectedTranslationFilter))
                                .font(.caption.weight(.semibold))
                            Button(localizedManagerText(uk: "Скинути", pl: "Resetuj", en: "Reset")) {
                                self.selectedTranslationFilter = nil
                            }
                            .font(.caption)
                        }
                    }

                    ForEach(Array(displayedMeanings.enumerated()), id: \.element.id) { index, meaning in
                        MeaningView(
                            index: index + 1,
                            meaning: meaning,
                            allExamples: wordCard.examples,
                            localizedPartOfSpeech: localizedPartOfSpeech,
                            sourceLanguage: wordCard.sourceLanguage,
                            targetLanguage: wordCard.targetLanguage,
                            showPartOfSpeech: !isIdiomCard,
                            onSpeak: { text, language in
                                AnalyticsService.shared.trackTTSClicked(section: "meaning_example")
                                ttsManager.speak(text: text, language: language)
                            }
                        )
                    }

                    if !showAllMeanings && meaningsWithExamplesOnly.count > 2 {
                        Button(localizedMoreMeanings) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showAllMeanings = true
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                }
            }

        case .examples:
            VStack(alignment: .leading, spacing: 12) {
                Text(localizedExamplesTitle)
                    .font(.title3.weight(.semibold))
                ForEach(wordCard.examples, id: \.id) { example in
                    ExampleRow(
                        example: example,
                        sourceLanguage: wordCard.sourceLanguage,
                        targetLanguage: wordCard.targetLanguage,
                        onSpeak: { text, language in
                            AnalyticsService.shared.trackTTSClicked(section: "example")
                            ttsManager.speak(text: text, language: language)
                        },
                        onSaveExample: nil
                    )
                }
            }

        case .synonyms:
            VStack(alignment: .leading, spacing: 14) {
                if !wordCard.synonyms.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(localizedSynonymsTitle)
                            .font(.title3.weight(.semibold))

                        ForEach(wordCard.synonyms, id: \.id) { synonym in
                            SynonymRow(
                                synonym: synonym,
                                onTap: { onSearchSynonym?(synonym.word) },
                                onSpeak: {
                                    AnalyticsService.shared.trackTTSClicked(section: "synonym")
                                    ttsManager.speak(text: synonym.word, language: synonym.language)
                                },
                                isSaved: savedSynonymIds.contains(synonym.id),
                                onSave: {
                                    onSaveSynonym?(synonym)
                                    savedSynonymIds.insert(synonym.id)
                                }
                            )
                        }
                    }
                }

                if !wordCard.antonyms.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(localizedAntonymsTitle)
                            .font(.title3.weight(.semibold))

                        ForEach(wordCard.antonyms, id: \.id) { antonym in
                            SynonymRow(
                                synonym: antonym,
                                onTap: { onSearchSynonym?(antonym.word) },
                                onSpeak: {
                                    AnalyticsService.shared.trackTTSClicked(section: "antonym")
                                    ttsManager.speak(text: antonym.word, language: antonym.language)
                                },
                                isSaved: savedSynonymIds.contains(antonym.id),
                                onSave: {
                                    onSaveSynonym?(antonym)
                                    savedSynonymIds.insert(antonym.id)
                                }
                            )
                        }
                    }
                }

                if !wordCard.relatedPhrases.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localizedRelatedPhrasesTitle)
                            .font(.title3.weight(.semibold))

                        ForEach(wordCard.relatedPhrases, id: \.id) { phrase in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(phrase.sourceText)
                                    .font(.body)
                                Text(phrase.targetText)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }

        case .related:
            VStack(alignment: .leading, spacing: 10) {
                Text(localizedRelatedPhrasesTitle)
                    .font(.title3.weight(.semibold))
                ForEach(wordCard.relatedPhrases, id: \.id) { phrase in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(phrase.sourceText)
                            .font(.body)
                        Text(phrase.targetText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func tabTitle(_ tab: ResultTab) -> String {
        switch tab {
        case .translation: return localizedTranslationsTab
        case .meanings: return isIdiomCard ? localizedMeaningTitle : localizedInterpretationTitle
        case .examples: return localizedExamplesTitle
        case .synonyms: return localizedSynonymsTitle
        case .related: return localizedRelatedPhrasesTitle
        }
    }

    private func close() {
        ttsManager.stop()
        onClose?()
        dismiss()
    }

    private var localizedTranslationsTitle: String {
        localizedManagerText(uk: "Переклад", pl: "Tlumaczenie", en: "Translation")
    }

    private var localizedInterpretationTitle: String {
        localizedManagerText(uk: "Тлумачення", pl: "Znaczenia", en: "Interpretation")
    }

    private var localizedMeaningTitle: String {
        localizedManagerText(uk: "Значення", pl: "Znaczenie", en: "Meaning")
    }

    private var localizedExamplesTitle: String {
        localizedManagerText(uk: "Приклади", pl: "Przyklady", en: "Examples")
    }

    private var localizedSynonymsTitle: String {
        localizedManagerText(uk: "Синоніми", pl: "Synonimy", en: "Synonyms")
    }

    private var localizedRelatedPhrasesTitle: String {
        localizedManagerText(uk: "Пов’язані фрази", pl: "Powiazane frazy", en: "Related phrases")
    }

    private var localizedAntonymsTitle: String {
        localizedManagerText(uk: "Антоніми", pl: "Antonimy", en: "Antonyms")
    }

    private var localizedMeaningUnavailable: String {
        localizedManagerText(uk: "Тлумачення поки недоступне для цієї мовної пари.", pl: "Znaczenie jest chwilowo niedostepne dla tej pary jezykowej.", en: "Interpretation is currently unavailable for this language pair.")
    }

    private var localizedMoreMeanings: String {
        localizedManagerText(uk: "Більше тлумачень", pl: "Wiecej znaczen", en: "More interpretations")
    }

    private var localizedTranslationsTab: String {
        localizedManagerText(uk: "Переклад", pl: "Tlumaczenie", en: "Translation")
    }

    private var localizedUnknownPOS: String {
        localizedManagerText(uk: "Інше", pl: "Inne", en: "Other")
    }

    private func localizedManagerText(uk: String, pl: String, en: String) -> String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return uk
        case .polish: return pl
        case .english: return en
        }
    }

    private func localizedPartOfSpeech(_ value: String) -> String {
        switch value.lowercased() {
        case "verb": return localizedManagerText(uk: "Дієслово", pl: "Czasownik", en: "Verb")
        case "noun": return localizedManagerText(uk: "Іменник", pl: "Rzeczownik", en: "Noun")
        case "adjective": return localizedManagerText(uk: "Прикметник", pl: "Przymiotnik", en: "Adjective")
        case "adverb": return localizedManagerText(uk: "Прислівник", pl: "Przyslowek", en: "Adverb")
        case "phrase": return localizedManagerText(uk: "Фраза", pl: "Fraza", en: "Phrase")
        default: return localizedUnknownPOS
        }
    }
}

private struct WordHeaderView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var ttsManager = TextToSpeechService.shared
    let showsSourceWord: Bool
    let inputType: WordInputType
    let word: String
    let transcription: String?
    let mainTranslation: String
    let sourceLanguage: String
    let targetLanguage: String
    let onSpeakWord: () -> Void
    let onSaveWord: (() -> Void)?
    let isWordSavedInDictionary: Bool
    let onCopyMainTranslation: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if inputType == .idiom {
                Text(localizedIdiomLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color(hex: "#4ECDC4"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(hex: "#4ECDC4").opacity(0.14))
                    )
            }

            if showsSourceWord {
                VStack(alignment: .leading, spacing: 4) {
                    if let transcription, !transcription.isEmpty {
                        Text(transcription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }

                    Text(mainTranslation)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                        .truncationMode(.tail)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text(mainTranslation)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text("\(sourceLanguage.uppercased()) → \(targetLanguage.uppercased())")
                .font(.caption)
                .foregroundColor(Color(hex: "#4ECDC4"))

            HStack(spacing: 20) {
                SpeakButton(
                    isActive: isMainTranslationSpeaking,
                    action: {
                        AnalyticsService.shared.trackTTSClicked(section: "header")
                        onSpeakWord()
                    },
                    foregroundColor: .secondary
                )

                Button(action: {
                    AnalyticsService.shared.trackCopyClicked(section: "header")
                    onCopyMainTranslation()
                }) {
                    Image(systemName: "doc.on.doc")
                }

                if let onSaveWord {
                    Button(action: {
                        AnalyticsService.shared.trackSaveClicked(entityType: "word")
                        onSaveWord()
                    }) {
                        HStack(spacing: 6) {
                            if isWordSavedInDictionary {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                            }
                            Text(isWordSavedInDictionary ? localizedSavedTitle : localizedSaveTitle)
                        }
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color(hex: "#4ECDC4"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "#4ECDC4").opacity(0.14))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .font(.body.weight(.semibold))
            .foregroundStyle(.secondary)
        }
    }

    private var localizedSaveTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Зберегти"
        case .polish: return "Zapisz"
        case .english: return "Save"
        }
    }

    private var localizedSavedTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Збережено"
        case .polish: return "Zapisano"
        case .english: return "Saved"
        }
    }

    private var localizedIdiomLabel: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Ідіома"
        case .polish: return "Idiomy"
        case .english: return "Idiom"
        }
    }

    private var isMainTranslationSpeaking: Bool {
        let id = utteranceID(text: mainTranslation, language: targetLanguage)
        return ttsManager.isActive(id)
    }

    private func utteranceID(text: String, language: String) -> String {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .lowercased()
        let lang = TextToSpeechService.appleSpeechLanguageCode(for: language)
        return "\(lang)|\(normalized)"
    }
}

private struct TranslationGroupView: View {
    let partOfSpeechTitle: String
    let options: [TranslationOption]
    let selectedValue: String?
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(partOfSpeechTitle.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TranslationChipFlowLayout(spacing: 8) {
                ForEach(options, id: \.id) { option in
                    let token = normalizedDisplayToken(option.value)
                    Button {
                        onSelect(option.value)
                    } label: {
                        Text(token)
                            .font(.subheadline)
                            .foregroundStyle(Color.primary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: min(UIScreen.main.bounds.width * 0.72, 300), alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.secondary.opacity(0.10))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct TranslationChipFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let fallbackWidth = UIScreen.main.bounds.width - 56
        let availableWidth = max(120, proposal.width ?? fallbackWidth)
        let result = FlowResult(in: availableWidth, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y),
                proposal: .unspecified
            )
        }
    }

    private struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)

                if x + subviewSize.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, subviewSize.height)
                x += subviewSize.width + spacing
                size.width = max(size.width, x)
            }

            size.height = y + lineHeight
        }
    }
}

private struct MeaningView: View {
    let index: Int
    let meaning: MeaningContent
    let allExamples: [WordExample]
    let localizedPartOfSpeech: (String) -> String
    let sourceLanguage: String
    let targetLanguage: String
    let showPartOfSpeech: Bool
    let onSpeak: (String, String) -> Void

    private var hasLinkedExamplesInCard: Bool {
        allExamples.contains(where: { $0.meaningId != nil })
    }

    private var exampleForMeaning: WordExample? {
        if let byMeaningId = allExamples.first(where: { $0.meaningId == meaning.id }) {
            return byMeaningId
        }
        // If there is no linked example for this meaning, prefer the meaning-local example
        // (decoded from sourceExample/targetExample) before giving up.
        if let exactPair = meaning.examples.first(where: {
            $0.sourceLanguage.caseInsensitiveCompare(sourceLanguage) == .orderedSame
            && $0.targetLanguage.caseInsensitiveCompare(targetLanguage) == .orderedSame
        }) {
            return exactPair
        }
        if let anyMeaningExample = meaning.examples.first {
            return anyMeaningExample
        }
        // If backend provided linked examples, do not reuse unrelated fallback examples.
        // This prevents the same sentence from being shown under multiple meanings.
        if hasLinkedExamplesInCard {
            return nil
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showPartOfSpeech {
                HStack(spacing: 8) {
                    Text(localizedPartOfSpeech(meaning.partOfSpeech.rawValue))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if let domain = meaning.domain, !domain.isEmpty {
                        Text(domain)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Text("\(index). \(meaning.definition)")
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)

            if let example = exampleForMeaning {
                ExampleRow(
                    example: example,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage,
                    onSpeak: onSpeak,
                    onSaveExample: nil
                )
            }

            if !meaning.translations.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(meaning.translations, id: \.id) { option in
                            Text(option.value)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.secondary.opacity(0.12))
                                )
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

}

private struct ExampleRow: View {
    @StateObject private var ttsManager = TextToSpeechService.shared
    let example: WordExample
    let sourceLanguage: String
    let targetLanguage: String
    let onSpeak: (String, String) -> Void
    let onSaveExample: ((WordExample) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Text(example.sourceText)
                    .font(.body)
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                SpeakButton(
                    isActive: isSourceSpeaking,
                    action: { onSpeak(example.sourceText, sourceLanguage) },
                    font: .caption,
                    foregroundColor: .secondary
                )
            }

            if !example.targetText.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Text("→ \(example.targetText)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                    SpeakButton(
                        isActive: isTargetSpeaking,
                        action: { onSpeak(example.targetText, targetLanguage) },
                        font: .caption,
                        foregroundColor: .secondary
                    )
                }
            }

        }
        .padding(.vertical, 2)
    }

    private var isSourceSpeaking: Bool {
        ttsManager.isActive(utteranceID(text: example.sourceText, language: sourceLanguage))
    }

    private var isTargetSpeaking: Bool {
        ttsManager.isActive(utteranceID(text: example.targetText, language: targetLanguage))
    }

    private func utteranceID(text: String, language: String) -> String {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .lowercased()
        let lang = TextToSpeechService.appleSpeechLanguageCode(for: language)
        return "\(lang)|\(normalized)"
    }
}

private struct SynonymRow: View {
    @StateObject private var ttsManager = TextToSpeechService.shared
    let synonym: WordSynonym
    let onTap: () -> Void
    let onSpeak: () -> Void
    let isSaved: Bool
    let onSave: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(normalizedDisplayToken(synonym.word))
                    .font(.body)
                    .foregroundStyle(.primary)

                if let translation = synonym.translation, !translation.isEmpty {
                    Text(normalizedDisplayToken(translation))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)

            Spacer(minLength: 8)

            if let pos = synonym.partOfSpeech, !pos.isEmpty {
                Text(pos)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            SpeakButton(
                isActive: isSynonymSpeaking,
                action: onSpeak,
                font: .body,
                foregroundColor: .secondary
            )

            if let onSave {
                Button(action: onSave) {
                    Image(systemName: isSaved ? "checkmark.circle.fill" : "plus.circle")
                        .font(.body)
                }
                .buttonStyle(.plain)
                .foregroundColor(Color(hex: "#4ECDC4"))
            }
        }
    }

    private var isSynonymSpeaking: Bool {
        ttsManager.isActive(utteranceID(text: synonym.word, language: synonym.language))
    }

    private func utteranceID(text: String, language: String) -> String {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .lowercased()
        let lang = TextToSpeechService.appleSpeechLanguageCode(for: language)
        return "\(lang)|\(normalized)"
    }
}

private func normalizedDisplayToken(_ value: String) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return value }

    // Preserve likely proper names/acronyms (e.g. "USA", "McDonald", "iPhone", "New York").
    let words = trimmed.split(separator: " ")
    let hasInnerUppercase = trimmed.dropFirst().contains(where: { $0.isUppercase })
    let isAllUppercase = trimmed.allSatisfy { !$0.isLetter || $0.isUppercase }
    let isTitleCasePhrase = words.count > 1 && words.allSatisfy {
        guard let first = $0.first else { return false }
        return first.isUppercase
    }

    if hasInnerUppercase || isAllUppercase || isTitleCasePhrase {
        return trimmed
    }

    return trimmed.lowercased()
}
