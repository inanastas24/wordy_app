//1
//  AppState.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 27.01.2026.
//

import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var appLanguage: String = "uk"
    @Published var learningLanguage: String = ""
    @Published var searchHistory: [SearchItem] = []
}

struct SearchItem: Identifiable, Codable {
    let id = UUID()
    let word: String
    let translation: String
    let date: Date
}
