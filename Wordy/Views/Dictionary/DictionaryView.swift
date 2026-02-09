//1
//  DictionaryView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 29.01.2026.
//

import FirebaseFirestore
import FirebaseAuth
import SwiftUI

struct DictionaryView: View {
    @StateObject private var viewModel = DictionaryViewModel.shared
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var isButtonPulsing = false
    @State private var showMenu = false
    @State private var selectedTab: Int = 1
    @State private var showSettings = false
    
    @FocusState private var isSearchFocused: Bool
    
    private var studyButtonTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Час повторити!"
        case .polish: return "Czas na powtórkę!"
        case .english: return "Time to review!"
        }
    }
    
    private var studyButtonSubtitle: String {
        let count = viewModel.learningCount
        switch localizationManager.currentLanguage {
        case .ukrainian:
            if count == 1 { return "1 картка чекає" }
            else if count >= 2 && count <= 4 { return "\(count) картки чекають" }
            else { return "\(count) карток чекають" }
        case .polish:
            if count == 1 { return "1 karta czeka" }
            else if count >= 2 && count <= 4 { return "\(count) karty czekają" }
            else { return "\(count) kart czeka" }
        case .english:
            return count == 1 ? "1 card waiting" : "\(count) cards waiting"
        }
    }
    
    private var emptyTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Словник порожній"
        case .polish: return "Słownik jest pusty"
        case .english: return "Dictionary is empty"
        }
    }
    
    private var emptySubtitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Збережіть слова під час перекладу"
        case .polish: return "Zapisz słowa podczas tłumaczenia"
        case .english: return "Save words during translation"
        }
    }
    
    private var reviewingTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "На повторення"
        case .polish: return "Do powtórek"
        case .english: return "For review"
        }
    }
    
    private var deleteTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Видалити"
        case .polish: return "Usuń"
        case .english: return "Delete"
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: localizationManager.isDarkMode ? "#1C1C1E" : "#FFFDF5")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HeaderView(showMenu: $showMenu, title: localizationManager.string(.dictionary))
                        .environmentObject(localizationManager)
                    
                    if viewModel.savedWords.isEmpty && !viewModel.isLoading {
                        emptyStateView
                    } else {
                        listView
                    }
                    
                    Spacer(minLength: 0)
                }
                
                if showMenu {
                    MenuView(isShowing: $showMenu, selectedTab: $selectedTab, showSettings: $showSettings)
                        .transition(.move(edge: .leading))
                        .zIndex(100)
                        .onAppear {
                            isSearchFocused = false
                        }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(localizationManager)
            }
            .safeAreaInset(edge: .bottom) {
                if viewModel.learningCount > 0 && !showMenu {
                    studyButton
                }
            }
            .onAppear {
                viewModel.fetchSavedWords()
            }
            .onDisappear {
                viewModel.stopListening()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 80))
                .foregroundColor(Color(hex: "#A8D8EA"))
            
            Text(emptyTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
            
            Text(emptySubtitle)
                .font(.system(size: 16))
                .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
        }
        .padding(.top, 100)
    }
    
    private var listView: some View {
        List {
            if !viewModel.learningWords.isEmpty {
                Section {
                    ForEach(viewModel.learningWords) { word in
                        FirestoreWordRow(
                            word: word,
                            isDarkMode: localizationManager.isDarkMode
                        )
                        .listRowBackground(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
                        .swipeActions(edge: .leading) {
                            Button(localizationManager.string(.learned)) {
                                viewModel.markAsLearned(wordId: word.id ?? "")
                            }
                            .tint(Color(hex: "#4ECDC4"))
                        }
                        .swipeActions(edge: .trailing) {
                            Button(deleteTitle, role: .destructive) {
                                viewModel.deleteWord(word.id ?? "")
                            }
                        }
                    }
                } header: {
                    Text(localizationManager.string(.learning) + " (\(viewModel.learningCount))")
                }
            }
            
            if !viewModel.learnedWords.isEmpty {
                Section {
                    ForEach(viewModel.learnedWords) { word in
                        FirestoreWordRow(
                            word: word,
                            isDarkMode: localizationManager.isDarkMode
                        )
                        .listRowBackground(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
                        .swipeActions(edge: .trailing) {
                            Button(reviewingTitle) {
                                viewModel.markAsUnlearned(wordId: word.id ?? "")
                            }
                            .tint(Color(hex: "#A8D8EA"))
                            Button(deleteTitle, role: .destructive) {
                                viewModel.deleteWord(word.id ?? "")
                            }
                        }
                    }
                } header: {
                    Text(localizationManager.string(.learned) + " ✅ (\(viewModel.learnedCount))")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(localizationManager.isDarkMode ? Color(hex: "#1C1C1E") : Color(hex: "#FFFDF5"))
    }
    
    private var studyButton: some View {
        NavigationLink(destination:
            FlashcardsView()
                .environmentObject(localizationManager)
                .navigationBarHidden(true)) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#4ECDC4").opacity(0.2))
                        .frame(width: 50, height: 50)
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                        .scaleEffect(isButtonPulsing ? 1.1 : 1.0)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(studyButtonTitle)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(localizationManager.isDarkMode ? .white : .primary)
                    
                    Text(studyButtonSubtitle)
                        .font(.system(size: 14))
                        .foregroundColor(localizationManager.isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: "#4ECDC4"))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isButtonPulsing = true
            }
        }
    }
}

struct FirestoreWordRow: View {
    let word: SavedWordModel
    let isDarkMode: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(word.original)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "#2C3E50"))
                    .lineLimit(2) // Allow 2 lines for long words
                
                Spacer()
                
                if word.isLearned {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(Color(hex: "#4ECDC4"))
                } else if word.isDueForReview {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                }
                
                if word.reviewCount > 0 {
                    Text("\(word.reviewCount)×")
                        .font(.system(size: 14))
                        .foregroundColor(isDarkMode ? .gray : Color(hex: "#7F8C8D"))
                }
            }
            
            Text(word.translation)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#4ECDC4"))
                .lineLimit(2) // Allow 2 lines for long translations
            
            if !word.isLearned && word.reviewCount > 0 {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10))
                    Text(timeUntilReview)
                        .font(.system(size: 12))
                }
                .foregroundColor(isDarkMode ? .gray : Color(hex: "#7F8C8D"))
            }
        }
        .padding(.vertical, 8)
    }
    
    private var timeUntilReview: String {
        guard let nextReview = word.nextReviewDate else { return "зараз" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: nextReview, relativeTo: Date())
    }
}
