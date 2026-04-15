//
//  ExportImportView.swift
//  Wordy
//

import SwiftUI
import UniformTypeIdentifiers

struct ExportImportView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    @StateObject private var dictionaryViewModel = DictionaryViewModel.shared
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var selectedFormat: ExportFormat = .json
    @State private var exportURL: URL?
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isLoading = false

    private var currentLanguage: AppLanguage {
        localizationManager.currentLanguage
    }

    private var exportScopes: [ExportScopeItem] {
        let allItem = ExportScopeItem.all(totalWords: dictionaryViewModel.savedWords.count)
        let dictionaryItems = dictionaryViewModel.dictionaries.map { dictionary in
            ExportScopeItem.dictionary(
                dictionary,
                wordCount: dictionaryViewModel.wordCount(in: dictionary.id)
            )
        }
        return [allItem] + dictionaryItems
    }

    var body: some View {
        NavigationStack {
            ZStack {
                exportImportBackground

                ScrollView {
                    VStack(spacing: 20) {
                        headerHero
                        exportSection
                        importSection
                        statisticsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 36)
                }
            }
            .navigationTitle(localizedTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizedDone) {
                        dismiss()
                    }
                }
            }
            .fileExporter(
                isPresented: $showingExporter,
                document: exportURL.map { ExportDocument(url: $0) },
                contentType: selectedFormat.contentType,
                defaultFilename: exportURL?.deletingPathExtension().lastPathComponent ?? "wordy_export"
            ) { result in
                handleExportResult(result)
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.json, .commaSeparatedText, .plainText, .data],
                allowsMultipleSelection: true
            ) { result in
                handleImportResult(result)
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.3)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.18))
                        .ignoresSafeArea()
                }
            }
        }
    }

    private var exportImportBackground: some View {
        ZStack {
            Color(hex: localizationManager.isDarkMode ? "#16171B" : "#FBF8F0")
                .ignoresSafeArea()

            Circle()
                .fill(Color(hex: "#4ECDC4").opacity(localizationManager.isDarkMode ? 0.14 : 0.13))
                .frame(width: 280, height: 280)
                .blur(radius: 56)
                .offset(x: -150, y: -240)

            Circle()
                .fill(Color(hex: "#FFD166").opacity(localizationManager.isDarkMode ? 0.10 : 0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 52)
                .offset(x: 170, y: -120)
        }
    }

    private var headerHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(localizedTitle)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#203044"))

                    Text(localizedHeroSubtitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(localizationManager.isDarkMode ? Color.white.opacity(0.62) : Color(hex: "#6E7C89"))
                }

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(hex: "#4ECDC4").opacity(0.14))
                        .frame(width: 56, height: 56)

                    Image(systemName: "arrow.up.arrow.down.square.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                }
            }

            HStack(spacing: 12) {
                heroMetric(title: localizedDictionaryCount, value: "\(dictionaryViewModel.dictionaries.count)", tint: "#4ECDC4")
                heroMetric(title: localizedTotalWords, value: "\(dictionaryViewModel.savedWords.count)", tint: "#A8D8EA")
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: localizationManager.isDarkMode
                        ? [Color(hex: "#23252B"), Color(hex: "#17181D")]
                        : [Color.white, Color(hex: "#F5F3EA")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.white.opacity(localizationManager.isDarkMode ? 0.06 : 0.7), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(localizationManager.isDarkMode ? 0.16 : 0.07), radius: 22, x: 0, y: 14)
        )
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: localizedExportTitle,
                subtitle: localizedExportDescription,
                icon: "square.and.arrow.up.fill",
                tint: "#4ECDC4"
            )

            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(localizedFormatTitle)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(localizationManager.isDarkMode ? Color.white.opacity(0.6) : Color(hex: "#6E7C89"))

                    Picker(localizedFormatTitle, selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.localizedName(for: currentLanguage)).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(16)
                .surfaceCard(isDarkMode: localizationManager.isDarkMode)

                ForEach(exportScopes) { scope in
                    Button {
                        performExport(for: scope)
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(hex: "#4ECDC4").opacity(0.14))
                                    .frame(width: 42, height: 42)

                                Image(systemName: scope.iconName)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(Color(hex: "#4ECDC4"))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(scope.title(language: currentLanguage))
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))

                                Text(scope.subtitle(language: currentLanguage))
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(Color(hex: "#4ECDC4"))
                        }
                        .padding(16)
                        .surfaceCard(isDarkMode: localizationManager.isDarkMode)
                    }
                    .disabled(scope.wordCount == 0 || isLoading)
                }

                if dictionaryViewModel.savedWords.isEmpty {
                    Text(localizedEmptyDictionary)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 4)
                }
            }
        }
    }

    private var importSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: localizedImportTitle,
                subtitle: localizedImportDescription,
                icon: "square.and.arrow.down.fill",
                tint: "#FF8A65"
            )

            Button {
                showingImporter = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(hex: "#FF8A65").opacity(0.14))
                            .frame(width: 42, height: 42)

                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(hex: "#FF8A65"))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizedImportButton)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))

                        Text(localizedImportHint)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(16)
                .surfaceCard(isDarkMode: localizationManager.isDarkMode)
            }
            .disabled(isLoading)
        }
    }

    @ViewBuilder
    private var statisticsSection: some View {
        if !dictionaryViewModel.dictionaries.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(
                    title: localizedStatistics,
                    subtitle: localizedStatisticsSubtitle,
                    icon: "chart.bar.fill",
                    tint: "#9B8CFF"
                )

                VStack(spacing: 12) {
                    StatisticRow(title: localizedDictionaryCount, value: "\(dictionaryViewModel.dictionaries.count)")
                    StatisticRow(title: localizedTotalWords, value: "\(dictionaryViewModel.savedWords.count)")
                    StatisticRow(title: localizedLearnedWords, value: "\(dictionaryViewModel.savedWords.filter { $0.isLearned }.count)")
                    StatisticRow(title: localizedLearningWords, value: "\(dictionaryViewModel.savedWords.filter { !$0.isLearned }.count)")
                }
                .padding(16)
                .surfaceCard(isDarkMode: localizationManager.isDarkMode)
            }
        }
    }

    private func performExport(for scope: ExportScopeItem) {
        let packages = exportPackages(for: scope)
        guard !packages.isEmpty else { return }

        isLoading = true

        Task {
            do {
                let url = try await DictionaryExportService.exportPackages(
                    packages,
                    scopeName: scope.fileNameComponent(language: currentLanguage),
                    format: selectedFormat,
                    language: currentLanguage
                )

                await MainActor.run {
                    exportURL = url
                    isLoading = false
                    showingExporter = true
                }
            } catch let error as ExportImportError {
                await MainActor.run {
                    isLoading = false
                    alertTitle = localizedError
                    alertMessage = error.localizedDescription(for: currentLanguage)
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertTitle = localizedError
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }

    private func exportPackages(for scope: ExportScopeItem) -> [DictionaryTransferPackage] {
        switch scope.kind {
        case .all:
            return dictionaryViewModel.dictionaries.compactMap { dictionary in
                let words = dictionaryViewModel.words(in: dictionary.id)
                guard !words.isEmpty else { return nil }
                return DictionaryTransferPackage(
                    dictionaryName: dictionary.name,
                    createdAt: dictionary.createdAt,
                    sourceDictionaryId: dictionary.id,
                    words: words
                )
            }
        case .dictionary(let dictionary):
            let words = dictionaryViewModel.words(in: dictionary.id)
            guard !words.isEmpty else { return [] }
            return [
                DictionaryTransferPackage(
                    dictionaryName: dictionary.name,
                    createdAt: dictionary.createdAt,
                    sourceDictionaryId: dictionary.id,
                    words: words
                )
            ]
        }
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            alertTitle = localizedSuccess
            alertMessage = localizedExportSuccess
            showingAlert = true
        case .failure(let error):
            alertTitle = localizedError
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard !urls.isEmpty else { return }
            performImport(from: urls)
        case .failure(let error):
            alertTitle = localizedError
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    private func performImport(from urls: [URL]) {
        isLoading = true

        Task {
            do {
                let parsedImports = try await DictionaryExportService.importPackages(
                    from: urls,
                    language: currentLanguage
                )
                let packages = parsedImports.flatMap(\.packages)
                let summary = await dictionaryViewModel.importPackages(packages)

                await MainActor.run {
                    isLoading = false
                    alertTitle = localizedSuccess
                    alertMessage = importSummaryMessage(summary)
                    showingAlert = true
                }

                NotificationCenter.default.post(name: .wordsImported, object: nil)
            } catch let error as ExportImportError {
                await MainActor.run {
                    isLoading = false
                    alertTitle = localizedError
                    alertMessage = error.localizedDescription(for: currentLanguage)
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertTitle = localizedError
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }

    private func importSummaryMessage(_ summary: DictionaryImportSummary) -> String {
        switch currentLanguage {
        case .ukrainian:
            if summary.duplicateCount > 0 {
                return "Імпортовано \(summary.importedWordCount) слів у \(summary.importedDictionaryCount) словників\nПропущено \(summary.duplicateCount) дублікатів"
            }
            return "Імпортовано \(summary.importedWordCount) слів у \(summary.importedDictionaryCount) словників"
        case .polish:
            if summary.duplicateCount > 0 {
                return "Zaimportowano \(summary.importedWordCount) słów do \(summary.importedDictionaryCount) słowników\nPominięto \(summary.duplicateCount) duplikatów"
            }
            return "Zaimportowano \(summary.importedWordCount) słów do \(summary.importedDictionaryCount) słowników"
        case .english:
            if summary.duplicateCount > 0 {
                return "Imported \(summary.importedWordCount) words into \(summary.importedDictionaryCount) dictionaries\nSkipped \(summary.duplicateCount) duplicates"
            }
            return "Imported \(summary.importedWordCount) words into \(summary.importedDictionaryCount) dictionaries"
        }
    }

    private var localizedTitle: String {
        switch currentLanguage {
        case .ukrainian: return "Експорт та імпорт"
        case .polish: return "Eksport i import"
        case .english: return "Export & Import"
        }
    }

    private var localizedDone: String {
        switch currentLanguage {
        case .ukrainian: return "Готово"
        case .polish: return "Gotowe"
        case .english: return "Done"
        }
    }

    private var localizedExportSection: String {
        switch currentLanguage {
        case .ukrainian: return "ЕКСПОРТ"
        case .polish: return "EKSPORT"
        case .english: return "EXPORT"
        }
    }

    private var localizedImportSection: String {
        switch currentLanguage {
        case .ukrainian: return "ІМПОРТ"
        case .polish: return "IMPORT"
        case .english: return "IMPORT"
        }
    }

    private var localizedExportTitle: String {
        switch currentLanguage {
        case .ukrainian: return "Експортувати словники"
        case .polish: return "Eksportuj słowniki"
        case .english: return "Export dictionaries"
        }
    }

    private var localizedExportDescription: String {
        switch currentLanguage {
        case .ukrainian: return "Можна експортувати один словник окремо або всі словники разом"
        case .polish: return "Możesz wyeksportować jeden słownik osobno lub wszystkie razem"
        case .english: return "Export one dictionary separately or all dictionaries together"
        }
    }

    private var localizedFormatTitle: String {
        switch currentLanguage {
        case .ukrainian: return "Формат"
        case .polish: return "Format"
        case .english: return "Format"
        }
    }

    private var localizedImportTitle: String {
        switch currentLanguage {
        case .ukrainian: return "Імпортувати словники"
        case .polish: return "Importuj słowniki"
        case .english: return "Import dictionaries"
        }
    }

    private var localizedImportDescription: String {
        switch currentLanguage {
        case .ukrainian: return "Підтримується імпорт одного або кількох файлів. Слова буде розкладено по відповідних словниках"
        case .polish: return "Obsługiwany jest import jednego lub kilku plików. Słowa zostaną przypisane do odpowiednich słowników"
        case .english: return "Import one or several files. Words will be saved into the corresponding dictionaries"
        }
    }

    private var localizedImportButton: String {
        switch currentLanguage {
        case .ukrainian: return "Вибрати файл або файли"
        case .polish: return "Wybierz plik lub pliki"
        case .english: return "Select file or files"
        }
    }

    private var localizedImportHint: String {
        switch currentLanguage {
        case .ukrainian: return "JSON, CSV, TXT"
        case .polish: return "JSON, CSV, TXT"
        case .english: return "JSON, CSV, TXT"
        }
    }

    private var localizedEmptyDictionary: String {
        switch currentLanguage {
        case .ukrainian: return "У словниках ще немає слів для експорту."
        case .polish: return "W słownikach nie ma jeszcze słów do eksportu."
        case .english: return "There are no words to export yet."
        }
    }

    private var localizedStatistics: String {
        switch currentLanguage {
        case .ukrainian: return "Статистика"
        case .polish: return "Statystyka"
        case .english: return "Statistics"
        }
    }

    private var localizedDictionaryCount: String {
        switch currentLanguage {
        case .ukrainian: return "Словників"
        case .polish: return "Słowników"
        case .english: return "Dictionaries"
        }
    }

    private var localizedTotalWords: String {
        switch currentLanguage {
        case .ukrainian: return "Всього слів"
        case .polish: return "Wszystkich słów"
        case .english: return "Total words"
        }
    }

    private var localizedLearnedWords: String {
        switch currentLanguage {
        case .ukrainian: return "Вивчено"
        case .polish: return "Nauczonych"
        case .english: return "Learned"
        }
    }

    private var localizedLearningWords: String {
        switch currentLanguage {
        case .ukrainian: return "На вивченні"
        case .polish: return "W nauce"
        case .english: return "Learning"
        }
    }

    private var localizedSuccess: String {
        switch currentLanguage {
        case .ukrainian: return "Успіх"
        case .polish: return "Sukces"
        case .english: return "Success"
        }
    }

    private var localizedError: String {
        switch currentLanguage {
        case .ukrainian: return "Помилка"
        case .polish: return "Błąd"
        case .english: return "Error"
        }
    }

    private var localizedExportSuccess: String {
        switch currentLanguage {
        case .ukrainian: return "Файл успішно підготовлено для експорту"
        case .polish: return "Plik został pomyślnie przygotowany do eksportu"
        case .english: return "File is ready for export"
        }
    }

    private var localizedHeroSubtitle: String {
        switch currentLanguage {
        case .ukrainian: return "Безпечне перенесення словників між пристроями та резервне копіювання"
        case .polish: return "Bezpieczne przenoszenie słowników między urządzeniami i kopie zapasowe"
        case .english: return "Safely move dictionaries between devices and keep a clean backup flow"
        }
    }

    private var localizedStatisticsSubtitle: String {
        switch currentLanguage {
        case .ukrainian: return "Швидкий огляд того, що зараз зберігається у словниках"
        case .polish: return "Szybki podgląd tego, co jest obecnie zapisane w słownikach"
        case .english: return "A quick snapshot of what is currently stored in your dictionaries"
        }
    }

    @ViewBuilder
    private func sectionHeader(title: String, subtitle: String, icon: String, tint: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: tint).opacity(0.14))
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: tint))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#203044"))

                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(localizationManager.isDarkMode ? Color.white.opacity(0.56) : Color(hex: "#6E7C89"))
            }

            Spacer()
        }
    }

    private func heroMetric(title: String, value: String, tint: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(localizationManager.isDarkMode ? Color.white.opacity(0.58) : Color(hex: "#6E7C89"))

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#203044"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(hex: tint).opacity(0.12))
        )
    }
}

private struct ExportScopeItem: Identifiable {
    enum Kind {
        case all
        case dictionary(WordDictionaryModel)
    }

    let id: String
    let kind: Kind
    let wordCount: Int

    static func all(totalWords: Int) -> ExportScopeItem {
        ExportScopeItem(id: "all", kind: .all, wordCount: totalWords)
    }

    static func dictionary(_ dictionary: WordDictionaryModel, wordCount: Int) -> ExportScopeItem {
        ExportScopeItem(id: dictionary.id ?? UUID().uuidString, kind: .dictionary(dictionary), wordCount: wordCount)
    }

    var iconName: String {
        switch kind {
        case .all: return "books.vertical.fill"
        case .dictionary: return "book.closed.fill"
        }
    }

    func title(language: AppLanguage) -> String {
        switch kind {
        case .all:
            switch language {
            case .ukrainian: return "Усі словники"
            case .polish: return "Wszystkie słowniki"
            case .english: return "All dictionaries"
            }
        case .dictionary(let dictionary):
            return dictionary.name
        }
    }

    func subtitle(language: AppLanguage) -> String {
        switch language {
        case .ukrainian:
            return wordCount == 1 ? "1 слово" : "\(wordCount) слів"
        case .polish:
            return wordCount == 1 ? "1 słowo" : "\(wordCount) słów"
        case .english:
            return wordCount == 1 ? "1 word" : "\(wordCount) words"
        }
    }

    func fileNameComponent(language: AppLanguage) -> String {
        switch kind {
        case .all:
            switch language {
            case .ukrainian: return "all_dictionaries"
            case .polish: return "all_dictionaries"
            case .english: return "all_dictionaries"
            }
        case .dictionary(let dictionary):
            return dictionary.name
        }
    }
}

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.json, .commaSeparatedText, .plainText, .data]

    var url: URL

    init(url: URL) {
        self.url = url
    }

    init(configuration: ReadConfiguration) throws {
        throw ExportImportError.invalidFileFormat
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try FileWrapper(url: url)
    }
}

struct StatisticRow: View {
    let title: String
    let value: String

    @EnvironmentObject var localizationManager: LocalizationManager

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(localizationManager.isDarkMode ? Color.white.opacity(0.62) : .secondary)
            Spacer()
            Text(value)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "#4ECDC4"))
        }
    }
}

private extension View {
    func surfaceCard(isDarkMode: Bool) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(isDarkMode ? Color(hex: "#23252B") : Color.white.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(isDarkMode ? 0.06 : 0.76), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(isDarkMode ? 0.12 : 0.05), radius: 12, x: 0, y: 8)
    }
}
