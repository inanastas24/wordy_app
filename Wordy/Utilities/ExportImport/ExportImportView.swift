//
//  ExportImportView.swift
//  Wordy
//

import SwiftUI
import UniformTypeIdentifiers

struct ExportImportView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @StateObject private var dictionaryViewModel = DictionaryViewModel.shared
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var showingFormatPicker = false
    @State private var selectedFormat: ExportFormat = .json
    @State private var exportURL: URL?
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var importedCount = 0
    @State private var duplicateCount = 0 // НОВЕ

    private var currentLanguage: AppLanguage {
        localizationManager.currentLanguage
    }

    var body: some View {
        NavigationStack {
            List {
                // Експорт секція
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localizedExportTitle)
                            .font(.headline)

                        Text(localizedExportDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    ForEach(ExportFormat.allCases) { format in
                        Button {
                            selectedFormat = format
                            performExport()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(format.localizedName(for: currentLanguage))
                                        .font(.system(size: 16, weight: .medium))

                                    Text(format.localizedDescription(for: currentLanguage))
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }

                                Spacer()

                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(Color(hex: "#4ECDC4"))
                            }
                        }
                        .disabled(dictionaryViewModel.savedWords.isEmpty || isLoading)
                    }
                } header: {
                    Text(localizedExportSection)
                } footer: {
                    if dictionaryViewModel.savedWords.isEmpty {
                        Text(localizedEmptyDictionary)
                            .foregroundColor(.orange)
                    }
                }

                // Імпорт секція
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localizedImportTitle)
                            .font(.headline)

                        Text(localizedImportDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    Button {
                        showingImporter = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(localizedImportButton)
                                    .font(.system(size: 16, weight: .medium))

                                Text("JSON, CSV, TXT")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(Color(hex: "#4ECDC4"))
                        }
                    }
                    .disabled(isLoading)
                } header: {
                    Text(localizedImportSection)
                }

                // Статистика
                if !dictionaryViewModel.savedWords.isEmpty {
                    Section(localizedStatistics) {
                        StatisticRow(title: localizedTotalWords, value: "\(dictionaryViewModel.savedWords.count)")
                        StatisticRow(title: localizedLearnedWords, value: "\(dictionaryViewModel.savedWords.filter { $0.isLearned }.count)")
                        StatisticRow(title: localizedLearningWords, value: "\(dictionaryViewModel.savedWords.filter { !$0.isLearned }.count)")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(localizedTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizedDone) {
                        dismiss()
                    }
                }
            }
            .fileExporter(
                isPresented: $showingExporter,
                document: exportURL != nil ? ExportDocument(url: exportURL!) : nil,
                contentType: selectedFormat.contentType,
                defaultFilename: "wordy_export"
            ) { result in
                handleExportResult(result)
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.json, .commaSeparatedText, .plainText, .data],
                allowsMultipleSelection: false
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
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                        .ignoresSafeArea()
                }
            }
        }
    }

    // MARK: - Methods

    private func performExport() {
        isLoading = true

        Task {
            do {
                let url = try await DictionaryExportService.exportWords(
                    dictionaryViewModel.savedWords,
                    format: selectedFormat,
                    language: currentLanguage
                )

                await MainActor.run {
                    self.exportURL = url
                    self.isLoading = false
                    self.showingExporter = true
                }
            } catch let error as ExportImportError {
                await MainActor.run {
                    self.isLoading = false
                    self.alertTitle = localizedError
                    self.alertMessage = error.localizedDescription(for: currentLanguage)
                    self.showingAlert = true
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.alertTitle = localizedError
                    self.alertMessage = error.localizedDescription
                    self.showingAlert = true
                }
            }
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
            guard let url = urls.first else { return }
            performImport(from: url)
        case .failure(let error):
            alertTitle = localizedError
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    private func performImport(from url: URL) {
        isLoading = true

        Task {
            do {
                // НОВЕ: Передаємо існуючі слова для перевірки дублікатів
                let result = try await DictionaryExportService.importWords(
                    from: url,
                    existingWords: dictionaryViewModel.savedWords,
                    language: currentLanguage
                )

                // НОВЕ: Використовуємо DictionaryViewModel для збереження слів
                await MainActor.run {
                    // Зберігаємо через ViewModel для повної інтеграції з Firebase
                    DictionaryViewModel.shared.saveWords(result.words)
                    DictionaryViewModel.shared.fetchSavedWords()
                    
                    self.importedCount = result.importedCount
                    self.duplicateCount = result.duplicateCount
                    self.isLoading = false
                    self.alertTitle = localizedSuccess
                    
                    // Формуємо повідомлення з інформацією про дублікати
                    if result.duplicateCount > 0 {
                        self.alertMessage = String(format: localizedImportSuccessWithDuplicates, result.importedCount, result.duplicateCount)
                    } else {
                        self.alertMessage = String(format: localizedImportSuccess, result.importedCount)
                    }
                    self.showingAlert = true
                }
                
                // НОВЕ: Постимо сповіщення про імпорт
                NotificationCenter.default.post(name: .wordsImported, object: nil)
                
            } catch let error as ExportImportError {
                await MainActor.run {
                    self.isLoading = false
                    self.alertTitle = localizedError
                    self.alertMessage = error.localizedDescription(for: currentLanguage)
                    self.showingAlert = true
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.alertTitle = localizedError
                    self.alertMessage = error.localizedDescription
                    self.showingAlert = true
                }
            }
        }
    }

    // MARK: - Localization

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
        case .ukrainian: return "Зберегти слова"
        case .polish: return "Zapisz słowa"
        case .english: return "Save words"
        }
    }

    private var localizedExportDescription: String {
        switch currentLanguage {
        case .ukrainian: return "Експортуйте словник для резервного копіювання або перенесення на інший пристрій"
        case .polish: return "Eksportuj słownik do kopii zapasowej lub przeniesienia na inne urządzenie"
        case .english: return "Export dictionary for backup or transfer to another device"
        }
    }

    private var localizedImportTitle: String {
        switch currentLanguage {
        case .ukrainian: return "Завантажити слова"
        case .polish: return "Załaduj słowa"
        case .english: return "Load words"
        }
    }

    private var localizedImportDescription: String {
        switch currentLanguage {
        case .ukrainian: return "Імпортуйте слова з файлу резервної копії"
        case .polish: return "Importuj słowa z pliku kopii zapasowej"
        case .english: return "Import words from backup file"
        }
    }

    private var localizedImportButton: String {
        switch currentLanguage {
        case .ukrainian: return "Вибрати файл"
        case .polish: return "Wybierz plik"
        case .english: return "Select file"
        }
    }

    private var localizedEmptyDictionary: String {
        switch currentLanguage {
        case .ukrainian: return "Словник порожній. Додайте слова для експорту."
        case .polish: return "Słownik jest pusty. Dodaj słowa do eksportu."
        case .english: return "Dictionary is empty. Add words to export."
        }
    }

    private var localizedStatistics: String {
        switch currentLanguage {
        case .ukrainian: return "Статистика"
        case .polish: return "Statystyka"
        case .english: return "Statistics"
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
        case .ukrainian: return "Файл успішно експортовано"
        case .polish: return "Plik pomyślnie wyeksportowany"
        case .english: return "File exported successfully"
        }
    }

    private var localizedImportSuccess: String {
        switch currentLanguage {
        case .ukrainian: return "Імпортовано %d слів"
        case .polish: return "Zaimportowano %d słów"
        case .english: return "Imported %d words"
        }
    }
    
    // НОВЕ: Локалізація для імпорту з дублікатами
    private var localizedImportSuccessWithDuplicates: String {
        switch currentLanguage {
        case .ukrainian: return "Імпортовано %d слів\nПропущено %d дублікатів"
        case .polish: return "Zaimportowano %d słów\nPominięto %d duplikatów"
        case .english: return "Imported %d words\nSkipped %d duplicates"
        }
    }
}

// MARK: - Export Document

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

// MARK: - Statistic Row

struct StatisticRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(hex: "#4ECDC4"))
        }
    }
}
