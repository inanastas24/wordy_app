//  EmailRegistrationPromptView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 02.02.2026.
//

import SwiftUI

// Цей файл більше не використовується - перейшли на Apple Sign In
// Залишено для сумісності, але не функціонує

struct EmailRegistrationPromptView: View {
    @Environment(\.dismiss) var dismiss
    
    var onComplete: () -> Void
    
    var body: some View {
        VStack {
            Text("Email реєстрація недоступна")
                .font(.headline)
            
            Text("Використовуйте Sign in with Apple")
                .foregroundColor(.secondary)
            
            Button("Закрити") {
                dismiss()
            }
            .padding()
        }
    }
}
