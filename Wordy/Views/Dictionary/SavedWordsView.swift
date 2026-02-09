//1
//  SavedWordsView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 29.01.2026.
//


import SwiftUI

struct SavedWordsView: View {
    @StateObject private var viewModel = DictionaryViewModel.shared
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showSignOutError = false
    @State private var signOutErrorMessage = ""
    @State private var showRegistration = false
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.savedWords.isEmpty && !viewModel.isLoading {
                    Section {
                        Text("Ще немає збережених слів")
                            .foregroundColor(.gray)
                            .italic()
                    }
                } else {
                    ForEach(viewModel.savedWords) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.original)
                                .font(.headline)
                            
                            Text(item.translation)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                            
                            Text(item.createdAt, style: .date)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteWords)
                }
            }
            .navigationTitle("Мої слова (\(viewModel.savedWords.count))")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if authViewModel.isAnonymous {
                        Button {
                            showRegistration = true
                        } label: {
                            Image(systemName: "icloud.and.arrow.up")
                                .foregroundColor(Color(hex: "#4ECDC4"))
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        signOut()
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .onAppear {
                viewModel.fetchSavedWords()
            }
            .onDisappear {
                viewModel.stopListening()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .alert("Помилка", isPresented: .constant(!viewModel.errorMessage.isEmpty)) {
                Button("OK") { viewModel.errorMessage = "" }
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Помилка виходу", isPresented: $showSignOutError) {
                Button("OK") { }
            } message: {
                Text(signOutErrorMessage)
            }
            .sheet(isPresented: $showRegistration) {
                RegistrationPromptView(
                    onComplete: {
                        showRegistration = false
                    },
                    onSkip: {
                        showRegistration = false
                    }
                )
                .environmentObject(authViewModel)
            }
        }
    }
    
    private func deleteWords(at offsets: IndexSet) {
        for index in offsets {
            guard index < viewModel.savedWords.count else { continue }
            let word = viewModel.savedWords[index]
                viewModel.deleteWord(word.id ?? "")
        }
    }
    
    private func signOut() {
        do {
            try authViewModel.signOut()
        } catch {
            signOutErrorMessage = error.localizedDescription
            showSignOutError = true
        }
    }
}
