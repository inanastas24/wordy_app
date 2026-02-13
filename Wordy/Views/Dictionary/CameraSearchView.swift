//
//  CameraSearchView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 11.02.2026.
//


import SwiftUI
import VisionKit

struct CameraSearchView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var scannedText = ""
    @State private var showResult = false
    @State private var translationResult: TranslationResult?
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: localizationManager.isDarkMode ? "#1C1C1E" : "#FFFDF5")
                    .ignoresSafeArea()
                
                VStack {
                    if !showResult {
                        // Сканер
                        LiveTextScanner(scannedText: $scannedText)
                            .onChange(of: scannedText) { _, newValue in
                                if !newValue.isEmpty {
                                    performSearch(newValue)
                                }
                            }
                    } else if let result = translationResult {
                        // Результат
                        TranslationResultView(result: result, onClose: {
                            dismiss()
                        })
                    }
                }
            }
            .navigationTitle("Сканування")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func performSearch(_ text: String) {
        isLoading = true
        
        let translationService = TranslationService()
        translationService.translate(
            word: text,
            appLanguage: appState.appLanguage,
            learningLanguage: appState.learningLanguage
        ) { result in
            isLoading = false
            
            switch result {
            case .success(let translation):
                translationResult = translation
                showResult = true
                
                // Зберігаємо в історію
                let item = SearchItem(
                    word: translation.original,
                    translation: translation.translation,
                    date: Date()
                )
                appState.searchHistory.insert(item, at: 0)
                
            case .failure(let error):
                // Показуємо помилку і повертаємось до сканування
                scannedText = ""
            }
        }
    }
}
