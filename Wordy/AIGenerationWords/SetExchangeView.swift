//
//  SetExchangeView.swift
//  Wordy
//

import SwiftUI
import UniformTypeIdentifiers
import FirebaseAuth

struct SetExchangeView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var selectedTab: ExchangeTab = .export
    @State private var selectedSet: WordSet?
    @State private var showShareSheet = false
    @State private var shareURL: URL?
    @State private var showImportPicker = false
    @State private var importedSet: ImportedSetPreview?
    @State private var showImportPreview = false
    @State private var errorMessage: String?
    
    enum ExchangeTab {
        case export, importSet, community
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    tabSelector
                    
                    switch selectedTab {
                    case .export:
                        ExportView(
                            onExport: { set in exportSet(set) },
                            onShare: { set in prepareShare(set) }
                        )
                    case .importSet:
                        ImportView(
                            onFilePick: { showImportPicker = true },
                            onQRScan: { }
                        )
                    case .community:
                        CommunitySetsView()
                    }
                }
            }
            .navigationTitle("Exchange Sets")
            .sheet(isPresented: $showShareSheet) {
                if let url = shareURL {
                    ShareSheetView(activityItems: [url])
                }
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.json, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .sheet(isPresented: $showImportPreview) {
                if let preview = importedSet {
                    ImportPreviewView(
                        preview: preview,
                        onImport: { confirmImport(preview) },
                        onCancel: { importedSet = nil }
                    )
                }
            }
        }
    }
    
    private var backgroundColor: Color {
        localizationManager.isDarkMode ? Color(hex: "#1C1C1E") : Color(hex: "#FFFDF5")
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach([ExchangeTab.export, .importSet, .community], id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.35)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: tabIcon(for: tab))
                            .font(.system(size: 20))
                        Text(tabTitle(for: tab))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(selectedTab == tab ? Color(hex: "#4ECDC4") : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedTab == tab ?
                        Color(hex: "#4ECDC4").opacity(0.1) :
                        Color.clear
                    )
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
        )
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    private func tabIcon(for tab: ExchangeTab) -> String {
        switch tab {
        case .export: return "square.and.arrow.up"
        case .importSet: return "square.and.arrow.down"
        case .community: return "globe"
        }
    }
    
    private func tabTitle(for tab: ExchangeTab) -> String {
        switch tab {
        case .export: return "Export"
        case .importSet: return "Import"
        case .community: return "Community"
        }
    }
    
    private func exportSet(_ set: WordSet) {
        guard let userId = authViewModel.user?.uid else {
            errorMessage = "Please log in first"
            return
        }
        
        Task {
            do {
                let exported = try await FirebaseFunctionsService.shared.exportSet(
                    setId: set.id,
                    userId: userId
                )
                
                let url = try saveToTempFile(exported)
                
                await MainActor.run {
                    shareURL = url
                    showShareSheet = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func prepareShare(_ set: WordSet) {
        // Generate shareable link or QR code
    }
    
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            Task {
                do {
                    let data = try Data(contentsOf: url)
                    let preview = try parseImportPreview(data)
                    
                    await MainActor.run {
                        importedSet = preview
                        showImportPreview = true
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = "Invalid file format"
                    }
                }
            }
            
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    private func parseImportPreview(_ data: Data) throws -> ImportedSetPreview {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        if let exported = try? decoder.decode(ExportedSet.self, from: data) {
            return ImportedSetPreview(
                title: exported.setData.title,
                description: exported.setData.description,
                wordCount: exported.setData.words.count,
                languagePair: exported.setData.languagePair,
                difficulty: DifficultyLevel(rawValue: exported.setData.difficulty) ?? .a1,
                source: .wordyExport,
                rawData: data
            )
        }
        
        if let generic = try? decoder.decode(GenericWordList.self, from: data) {
            return ImportedSetPreview(
                title: generic.title ?? "Imported Set",
                description: generic.description ?? "",
                wordCount: generic.words.count,
                languagePair: generic.languagePair ?? "en-uk",
                difficulty: .a1,
                source: .generic,
                rawData: data
            )
        }
        
        throw ImportError.unsupportedFormat
    }
    
    private func confirmImport(_ preview: ImportedSetPreview) {
        guard let userId = authViewModel.user?.uid else {
            errorMessage = "Please log in first"
            return
        }
        
        Task {
            do {
                let newId = try await FirebaseFunctionsService.shared.importSet(
                    exportData: preview.toExportedSet(),
                    userId: userId
                )
                
                await MainActor.run {
                    NotificationCenter.default.post(name: .wordSaved, object: nil)
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func saveToTempFile(_ exported: ExportedSet) throws -> URL {
        let data = try JSONEncoder().encode(exported)
        let filename = "\(exported.setData.title.sanitizedForFilename)_wordy.json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url)
        return url
    }
}

// MARK: - Supporting Views

struct ExportView: View {
    let onExport: (WordSet) -> Void
    let onShare: (WordSet) -> Void
    
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Select Set to Export")
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.top)
                
                LazyVStack(spacing: 12) {
                    ForEach(UserDictionaryManager.shared.customSets) { set in
                        ExportSetRow(set: set) {
                            onExport(set)
                        } onShare: {
                            onShare(set)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct ExportSetRow: View {
    let set: WordSet
    let onExport: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        HStack {
            Text(set.emoji)
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text(set.title(for: "en"))
                    .font(.system(size: 16, weight: .semibold))
                Text("\(set.wordCount) words")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(Color(hex: "#4ECDC4"))
            }
            
            Button(action: onExport) {
                Image(systemName: "arrow.down.circle")
                    .foregroundColor(Color(hex: "#6C5CE7"))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

struct ImportView: View {
    let onFilePick: () -> Void
    let onQRScan: () -> Void
    
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            ImportMethodCard(
                icon: "doc.text",
                title: "Import from File",
                description: "Import JSON or text file",
                color: Color(hex: "#4ECDC4")
            ) {
                onFilePick()
            }
            
            ImportMethodCard(
                icon: "qrcode",
                title: "Scan QR Code",
                description: "Scan shared QR code",
                color: Color(hex: "#6C5CE7")
            ) {
                onQRScan()
            }
            
            ImportMethodCard(
                icon: "doc.on.clipboard",
                title: "Paste from Clipboard",
                description: "Paste JSON data",
                color: Color(hex: "#FFD93D")
            ) {
                pasteFromClipboard()
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    private func pasteFromClipboard() {
        // Handle clipboard import
    }
}

struct ImportMethodCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(color.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.05))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CommunitySetsView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var appState: AppState
    
    @State private var sets: [CommunityWordSet] = []
    @State private var isLoading = false
    @State private var selectedFilter: CommunityFilter = .popular
    
    enum CommunityFilter: String, CaseIterable {
        case popular, recentWord, trending, following
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(CommunityFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filterTitle(filter),
                                isSelected: selectedFilter == filter,
                                color: Color(hex: "#4ECDC4")
                            ) {
                                selectedFilter = filter
                                loadSets()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                LazyVStack(spacing: 12) {
                    ForEach(sets) { set in
                        CommunitySetCard(set: set)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear(perform: loadSets)
    }
    
    private func filterTitle(_ filter: CommunityFilter) -> String {
        switch filter {
        case .popular: return "Popular"
        case .recentWord: return "Recent"
        case .trending: return "Trending"
        case .following: return "Following"
        }
    }
    
    private func loadSets() {
        isLoading = true
        
        Task {
            do {
                let result = try await FirebaseFunctionsService.shared.getCommunitySets(
                    languagePair: appState.languagePair,
                    sortBy: .init(rawValue: selectedFilter.rawValue) ?? .popular
                )
                
                await MainActor.run {
                    sets = result
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? color : Color.gray.opacity(0.2))
                )
        }
    }
}

struct CommunitySetCard: View {
    let set: CommunityWordSet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(set.title)
                        .font(.system(size: 18, weight: .semibold))
                    Text(set.description ?? "")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                        Text(String(format: "%.1f", set.averageRating))
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text("\(set.downloadCount) downloads")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            HStack {
                Label("\(set.wordCount) words", systemImage: "text.word.spacing")
                Label(set.difficulty.displayName, systemImage: "chart.bar")
                Spacer()
            }
            .font(.system(size: 12))
            .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

struct ImportPreviewView: View {
    let preview: ImportedSetPreview
    let onImport: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 60))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                    
                    Text(preview.title)
                        .font(.title2.bold())
                    
                    Text(preview.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                VStack(alignment: .leading, spacing: 16) {
                    InfoRow(icon: "number", label: "Words", value: "\(preview.wordCount)")
                    InfoRow(icon: "globe", label: "Language", value: preview.languagePair)
                    InfoRow(icon: "chart.bar", label: "Difficulty", value: preview.difficulty.displayName)
                    InfoRow(icon: "doc.badge", label: "Source", value: "\(preview.source)")
                }
                .padding()
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Cancel", action: onCancel)
                        .buttonStyle(.bordered)
                    
                    Button("Import", action: onImport)
                        .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("Import Preview")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "#4ECDC4"))
                .frame(width: 24)
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct ShareSheetView: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct GenericWordList: Codable {
    let title: String?
    let description: String?
    let words: [GenericWord]
    let languagePair: String?
}

struct GenericWord: Codable {
    let original: String
    let translation: String
}

enum ImportError: Error {
    case unsupportedFormat
    case invalidData
}
// MARK: - Import Preview Model

enum ImportSource: String, Codable, CustomStringConvertible {
    case wordyExport
    case generic
    
    var description: String {
        switch self {
        case .wordyExport: return "Wordy Export"
        case .generic: return "Generic"
        }
    }
}

struct ImportedSetPreview: Codable {
    let title: String
    let description: String
    let wordCount: Int
    let languagePair: String
    let difficulty: DifficultyLevel
    let source: ImportSource
    /// Raw data of the imported payload so we can pass it to import APIs or reconstruct an ExportedSet
    let rawData: Data
    
    /// Convert a preview back into an `ExportedSet` that can be sent to backend import API.
    /// If the original data was already a Wordy export, prefer decoding it directly to preserve fidelity.
    func toExportedSet() -> ExportedSet {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let exported = try? decoder.decode(ExportedSet.self, from: rawData) {
            return exported
        }
        // Fallback: construct a minimal ExportedSet from the preview when the source was generic.
        // We don't have individual words in the preview, so provide an empty array; backend can handle accordingly or client may enrich before sending.
        let setData = MinimalWordSetExport(
            id: UUID().uuidString,
            title: title,
            description: description,
            languagePair: languagePair,
            difficulty: difficulty.rawValue,
            words: [] as [MinimalWordSetExport.MinimalWord]
        )
        let stats = MinimalSetStatistics(createdAt: Date(), exportedBy: nil)
        let tempEncoder = JSONEncoder()
        tempEncoder.dateEncodingStrategy = JSONEncoder.DateEncodingStrategy.iso8601
        let tempDecoder = JSONDecoder()
        tempDecoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.iso8601
        // Build a temporary container that mirrors ExportedSet's expected keys
        struct TempExportedSet: Codable { let setData: MinimalWordSetExport; let statistics: MinimalSetStatistics }
        if let containerJSON = try? tempEncoder.encode(TempExportedSet(setData: setData, statistics: stats)),
           let exported = try? tempDecoder.decode(ExportedSet.self, from: containerJSON) {
            return exported
        }
        // As a last resort, return an empty ExportedSet-like object if available, or fatalError to surface schema mismatch in development.
        fatalError("Unable to construct ExportedSet from minimal data. Ensure ExportedSet(setData:statistics:) matches schema.")
    }
}

// MARK: - Minimal export scaffolding used by ImportedSetPreview.toExportedSet()

/// Minimal representation of a word set export payload used only to reconstruct an ExportedSet
/// in cases where we imported a generic format and don't have full fidelity.
private struct MinimalWordSetExport: Codable {
    let id: String
    let title: String
    let description: String
    let languagePair: String
    let difficulty: String
    let words: [MinimalWord]

    struct MinimalWord: Codable {
        let original: String
        let translation: String
    }
}

/// Minimal statistics container to satisfy ExportedSet decoding when building a fallback payload.
private struct MinimalSetStatistics: Codable {
    let createdAt: Date
    let exportedBy: String?
}

// MARK: - Extensions

extension WordSet {
    var isSystemSet: Bool {
        !id.contains("custom_") && !id.contains("user_")
    }
}

extension String {
    var sanitizedForFilename: String {
        self.components(separatedBy: .alphanumerics.inverted).joined(separator: "_")
    }
}

