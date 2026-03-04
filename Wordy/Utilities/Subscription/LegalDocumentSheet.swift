//
//  LegalDocumentSheet.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 02.03.2026.
//

import SwiftUI

struct LegalDocumentsSheet: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDocument: LegalDocument?
    @State private var showDocument = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        selectedDocument = .termsOfService
                        showDocument = true
                    } label: {
                        HStack {
                            Text(localizationManager.string(.termsOfService))
                                .foregroundColor(localizationManager.isDarkMode ? .white : .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button {
                        selectedDocument = .privacyPolicy
                        showDocument = true
                    } label: {
                        HStack {
                            Text(localizationManager.string(.privacyPolicy))
                                .foregroundColor(localizationManager.isDarkMode ? .white : .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(localizationManager.currentLanguage == .ukrainian ? "Юридичні документи" : "Legal Documents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.currentLanguage == .ukrainian ? "Готово" : "Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#4ECDC4"))
                }
            }
            .navigationDestination(isPresented: $showDocument) {
                if let doc = selectedDocument {
                    LegalTextView(document: doc)
                }
            }
        }
    }
}
