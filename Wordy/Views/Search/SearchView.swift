//
//  SearchView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 27.01.2026.
//

import SwiftUI
import VisionKit
import Vision
import AVFoundation

// MARK: - Permission Type
enum PermissionType {
    case camera, microphone, speech
}

// MARK: - Live Text Scanner
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

// MARK: - Search View
struct SearchView: View {
    @Binding var selectedTab: Int
    @Binding var deepLinkAction: DeepLinkAction?
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @AppStorage("learningLanguage") private var learningLanguage: LearningLanguage = .english
    
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
    @State private var showLanguagePicker = false
    
    @FocusState private var isSearchFocused: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    
    private let translationService = TranslationService()
    private let voiceColor = Color(hex: "#FFD93D")
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: localizationManager.isDarkMode ? "#1C1C1E" : "#FFFDF5")
                    .ignoresSafeArea()
                    .onTapGesture {
                        isSearchFocused = false
                    }
                
                VStack(spacing: 0) {
                    HeaderView(showMenu: $showMenu, title: localizationManager.string(.search))
                        .environmentObject(localizationManager)
                    
                    ScrollView {
                        VStack(spacing: 25) {
                            languageSelector
                            
                            SearchBar(text: $searchText, onSubmit: performSearch)
                                .focused($isSearchFocused)
                            
                            if speechService.isRecording {
                                recordingIndicator
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
                                
                                voiceSearchButton
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
                        .onAppear {
                            isSearchFocused = false
                        }
                }
                
                if showLanguagePicker {
                    languagePickerOverlay
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
            .onChange(of: deepLinkAction) { _, newAction in
                handleDeepLinkAction(newAction)
            }
            .onAppear {
                handleDeepLinkAction(deepLinkAction)
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
            .onChange(of: selectedTab) { _, _ in
                isSearchFocused = false
            }
        }
    }
    
    // MARK: - Deep Link Handling
    private func handleDeepLinkAction(_ action: DeepLinkAction?) {
        guard let action = action else { return }
        
        switch action {
        case .camera:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.checkCameraPermission()
                self.deepLinkAction = nil
            }
            
        case .voice(let autoStart):
            if autoStart {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.startVoiceSearch()
                    self.deepLinkAction = nil
                }
            }
        }
    }
    
    // MARK: - Voice Search
    private func startVoiceSearch() {
        guard !speechService.isRecording else { return }
        
        speechService.startRecording(language: appState.learningLanguage) { text in
            if let text = text, !text.isEmpty {
                self.searchText = text
                self.performSearch()
            }
        }
    }
    
    private var voiceSearchButton: some View {
        Button {
            startVoiceSearch()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: speechService.isRecording ? "waveform" : "mic.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                
                Text(localizationManager.string(.voice))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(localizationManager.string(.holdToSpeak))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(speechService.isRecording ? voiceColor.opacity(0.8) : voiceColor)
            .cornerRadius(20)
            .shadow(color: voiceColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var recordingIndicator: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "waveform")
                    .font(.system(size: 32))
                    .foregroundColor(voiceColor)
                
                Text("🎙️ \(speechService.recognizedText)")
                    .font(.system(size: 16))
                    .foregroundColor(voiceColor)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(.top, 10)
    }
    
    // MARK: - Language Selector
    private var languageSelector: some View {
        Button {
            withAnimation(.spring(response: 0.35)) {
                showLanguagePicker = true
            }
        } label: {
            HStack(spacing: 12) {
                Text(learningLanguage.flag)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(localizationManager.string(.selectLearningLanguage))
                        .font(.system(size: 12))
                        .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                    
                    Text(learningLanguage.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#4ECDC4"))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            )
            .padding(.horizontal, 20)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Language Picker Overlay
    private var languagePickerOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.35)) {
                        showLanguagePicker = false
                    }
                }
            
            VStack(spacing: 20) {
                Text(localizationManager.string(.selectLearningLanguage))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(LearningLanguage.allCases) { language in
                        Button {
                            withAnimation(.spring(response: 0.35)) {
                                learningLanguage = language
                                appState.learningLanguage = language.rawValue
                                showLanguagePicker = false
                            }
                        } label: {
                            VStack(spacing: 8) {
                                Text(language.flag)
                                    .font(.system(size: 40))
                                
                                Text(language.displayName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(learningLanguage == language ? .white : (localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50")))
                            }
                            .frame(maxWidth: .infinity, minHeight: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(learningLanguage == language ? Color(hex: "#4ECDC4") : (localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(learningLanguage == language ? Color.clear : Color(hex: "#E0E0E0"), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Button {
                    withAnimation(.spring(response: 0.35)) {
                        showLanguagePicker = false
                    }
                } label: {
                    Text(localizationManager.currentLanguage == .ukrainian ? "Скасувати" :
                         localizationManager.currentLanguage == .polish ? "Anuluj" : "Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#7F8C8D"))
                        .padding(.vertical, 12)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(localizationManager.isDarkMode ? Color(hex: "#1C1C1E") : Color(hex: "#FFFDF5"))
                    .shadow(color: Color.black.opacity(0.2), radius: 40, x: 0, y: 20)
            )
            .padding(.horizontal, 40)
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
