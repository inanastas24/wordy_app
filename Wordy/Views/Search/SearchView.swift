//1
//  SearchView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 27.01.2026.
//

import SwiftUI
import VisionKit
import Vision
import AVFoundation

enum PermissionType {
    case camera, microphone, speech
}

struct LiveTextScanner: UIViewControllerRepresentable {
    @Binding var scannedText: String
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIViewController {
        if #available(iOS 16.0, *) {
            let scanner = DataScannerViewController(
                recognizedDataTypes: [.text()],
                qualityLevel: .accurate,
                recognizesMultipleItems: false,
                isHighFrameRateTrackingEnabled: false,
                isHighlightingEnabled: true
            )
            scanner.delegate = context.coordinator
            return scanner
        } else {
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = context.coordinator
            return picker
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: LiveTextScanner
        
        init(_ parent: LiveTextScanner) {
            self.parent = parent
        }
    }
}

@available(iOS 16.0, *)
extension LiveTextScanner.Coordinator: DataScannerViewControllerDelegate {
    func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
        switch item {
        case .text(let text):
            parent.scannedText = text.transcript
            parent.dismiss()
        default: break
        }
    }
}

extension LiveTextScanner.Coordinator: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            recognizeText(in: image)
        }
        parent.dismiss()
    }
    
    func recognizeText(in image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
            DispatchQueue.main.async {
                self?.parent.scannedText = text
            }
        }
        try? handler.perform([request])
    }
}

struct SearchView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var searchText = ""
    @State private var showMenu = false
    @State private var translationResult: TranslationResult?
    @State private var isLoading = false
    @StateObject private var speechService = SpeechRecognitionService()
    @State private var showScanner = false
    @State private var scannedText = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var errorTitle = ""
    @State private var showSettings = false
    @State private var showTranslationCard = false
    
    @FocusState private var isSearchFocused: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    
    private let translationService = TranslationService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: localizationManager.isDarkMode ? "#1C1C1E" : "#FFFDF5")
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Dismiss keyboard when tapping background
                        isSearchFocused = false
                    }
                
                VStack(spacing: 0) {
                    HeaderView(showMenu: $showMenu, title: localizationManager.string(.search))
                        .environmentObject(localizationManager)
                    
                    ScrollView {
                        VStack(spacing: 25) {
                            SearchBar(text: $searchText, onSubmit: performSearch)
                                .focused($isSearchFocused)
                            
                            if speechService.isRecording {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        Image(systemName: "waveform")
                                            .font(.system(size: 32))
                                            .foregroundColor(Color(hex: "#4ECDC4"))
                                        
                                        Text("🎙️ \(speechService.recognizedText)")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color(hex: "#4ECDC4"))
                                            .multilineTextAlignment(.center)
                                    }
                                    Spacer()
                                }
                                .padding(.top, 10)
                            }
                            
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .padding()
                            }
                            
                            HStack(spacing: 15) {
                                ActionButton(
                                    icon: "camera.fill",
                                    title: localizationManager.string(.scan),
                                    subtitle: localizationManager.string(.scanText),
                                    color: Color(hex: "#A8D8EA"),
                                    isDarkMode: localizationManager.isDarkMode
                                ) {
                                    isSearchFocused = false
                                    checkCameraPermission()
                                }
                                
                                VoiceActionButton(
                                    speechService: speechService,
                                    title: localizationManager.string(.voice),
                                    subtitle: localizationManager.string(.holdToSpeak),
                                    color: Color(hex: "#F38BA8"),
                                    isDarkMode: localizationManager.isDarkMode,
                                    language: appState.learningLanguage
                                ) { text in
                                    if !text.isEmpty {
                                        searchText = text
                                        performSearch()
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            historySection
                            
                            Spacer(minLength: 50)
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
                
                if let result = translationResult, showTranslationCard {
                    TranslationBubbleOverlay(
                        result: result,
                        showTranslationCard: $showTranslationCard,
                        translationResult: $translationResult
                    )
                    .environmentObject(localizationManager)
                    .environmentObject(appState)
                    .environmentObject(authViewModel)
                }
                
                if showMenu {
                    MenuView(isShowing: $showMenu, selectedTab: $selectedTab, showSettings: $showSettings)
                        .transition(.move(edge: .leading))
                        .zIndex(100)
                    // Dismiss keyboard when menu opens
                        .onAppear {
                            isSearchFocused = false
                        }
                }
            }
            .sheet(isPresented: $showScanner) {
                LiveTextScanner(scannedText: $scannedText)
            }
            .onChange(of: scannedText) { _, newText in
                if !newText.isEmpty {
                    searchText = newText
                    isSearchFocused = true
                    performSearch()
                    scannedText = ""
                }
            }
            .alert(errorTitle, isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .fullScreenCover(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(localizationManager)
                    .environmentObject(appState)
            }
            // Close keyboard when tab changes
            .onChange(of: selectedTab) { _, _ in
                isSearchFocused = false
            }
        }
    }
    
    private var historySection: some View {
        Group {
            if !appState.searchHistory.isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text(localizationManager.string(.recent))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                        
                        Spacer()
                        
                        Button(localizationManager.string(.clear)) {
                            appState.searchHistory.removeAll()
                        }
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                    }
                    .padding(.horizontal, 20)
                    
                    ForEach(appState.searchHistory.prefix(5)) { item in
                        HistoryCard(item: item, isDarkMode: localizationManager.isDarkMode)
                            .onTapGesture {
                                searchText = item.word
                                isSearchFocused = true
                            }
                    }
                }
            } else {
                VStack(spacing: 15) {
                    Image(systemName: "text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(Color(hex: "#A8D8EA"))
                    
                    Text(localizationManager.string(.search))
                        .font(.system(size: 18))
                        .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                    
                    Text(localizationManager.string(.searchPlaceholder))
                        .font(.system(size: 14))
                        .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
            }
        }
    }
    
    // MARK: - Permission Handling
    
    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.showScanner = true
                    }
                }
            }
        case .authorized:
            showScanner = true
        case .denied, .restricted:
            showPermissionAlert(for: .camera)
        @unknown default:
            break
        }
    }
    
    private func showPermissionAlert(for type: PermissionType) {
        let title: String
        let message: String
        
        switch type {
        case .camera:
            title = localizationManager.string(.cameraPermission)
            message = localizationManager.string(.permissionMessage)
        case .microphone:
            title = localizationManager.string(.microphonePermission)
            message = localizationManager.string(.permissionMessage)
        case .speech:
            title = localizationManager.string(.speechPermission)
            message = localizationManager.string(.permissionMessage)
        }
        
        errorTitle = title
        errorMessage = message
        showErrorAlert = true
    }
    
    func performSearch() {
        guard !searchText.isEmpty else { return }
        isSearchFocused = false
        isLoading = true
        
        Task {
            do {
                try await FirestoreService.shared.logSearch(query: searchText, result: "searching")
            } catch {
                print("Помилка логування: \(error)")
            }
        }
        
        translationService.translate(
            word: searchText,
            appLanguage: appState.appLanguage,
            learningLanguage: appState.learningLanguage
        ) { result in
            isLoading = false
            
            switch result {
            case .success(let translation):
                Task {
                    do {
                        try await FirestoreService.shared.logSearch(query: searchText, result: translation.translation)
                    } catch {
                        print("Помилка логування: \(error)")
                    }
                }
                
                translationResult = translation
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showTranslationCard = true
                }
                let item = SearchItem(word: translation.original, translation: translation.translation, date: Date())
                appState.searchHistory.insert(item, at: 0)
                searchText = ""
                
            case .failure(let error):
                Task {
                    do {
                        try await FirestoreService.shared.logSearch(query: searchText, result: "error: \(error.localizedDescription)")
                    } catch {
                        print("Помилка логування: \(error)")
                    }
                }
                
                errorTitle = localizationManager.string(.error)
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}
