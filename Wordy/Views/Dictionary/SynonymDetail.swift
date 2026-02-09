//1
//  SynonymDetail.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 02.02.2026.
//

import Foundation

struct SynonymDetail: Identifiable {
    let id = UUID()
    let word: String
    let ipaTranscription: String?
    let translation: String
}
