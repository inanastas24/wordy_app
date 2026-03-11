//
//  WordRatingView.swift
//  Wordy
//

import SwiftUI
import FirebaseAuth

struct WordRatingView: View {
    let word: PresetWord
    let setId: String
    
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var selectedRating: WordRating?
    @State private var feedbackText = ""
    @State private var showFeedbackField = false
    @State private var isSubmitting = false
    @State private var showThankYou = false
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text(word.original)
                    .font(.system(size: 24, weight: .bold))
                
                Text(word.translation)
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#4ECDC4"))
                
                if let example = word.exampleSentence {
                    Text("„\(example)\"")
                        .font(.system(size: 16))
                        .italic()
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.top, 20)
            
            Text("How is this translation?")
                .font(.system(size: 18, weight: .semibold))
                .padding(.top, 20)
            
            VStack(spacing: 12) {
                ForEach([WordRating.excellent, .good, .okay, .poor], id: \.self) { rating in
                    RatingButton(
                        rating: rating,
                        isSelected: selectedRating == rating
                    ) {
                        withAnimation(.spring(response: 0.35)) {
                            selectedRating = rating
                            showFeedbackField = rating == .poor || rating == .okay
                        }
                    }
                }
            }
            
            if showFeedbackField {
                TextEditor(text: $feedbackText)
                    .frame(height: 80)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3))
                    )
                    .overlay(
                        Text("What can be improved?")
                            .foregroundColor(.gray)
                            .opacity(feedbackText.isEmpty ? 1 : 0)
                    )
            }
            
            Spacer()
            
            Button {
                submitRating()
            } label: {
                HStack {
                    if isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text("Submit Rating")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(selectedRating != nil ? Color(hex: "#4ECDC4") : Color.gray)
                .cornerRadius(16)
            }
            .disabled(selectedRating == nil || isSubmitting)
        }
        .padding()
        .overlay {
            if showThankYou {
                ThankYouOverlay {
                    showThankYou = false
                }
            }
        }
    }
    
    private func submitRating() {
        guard let rating = selectedRating,
              let userId = authViewModel.user?.uid else { return }
        
        isSubmitting = true
        
        Task {
            do {
                try await FirebaseFunctionsService.shared.rateWord(
                    wordId: word.id,
                    setId: setId,
                    rating: rating,
                    userId: userId
                )
                
                await MainActor.run {
                    isSubmitting = false
                    showThankYou = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                }
            }
        }
    }
}

struct RatingButton: View {
    let rating: WordRating
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating.rawValue ? "star.fill" : "star")
                            .font(.system(size: 16))
                            .foregroundColor(star <= rating.rawValue ? .yellow : .gray.opacity(0.3))
                    }
                }
                
                Text(rating.label)
                    .font(.system(size: 16, weight: .medium))
                
                Spacer()
                
                Circle()
                    .fill(isSelected ? Color(hex: "#4ECDC4") : Color.clear)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 2)
                    )
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(isSelected ? 1 : 0)
                    )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "#4ECDC4").opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color(hex: "#4ECDC4") : Color.gray.opacity(0.2))
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ThankYouOverlay: View {
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "#4ECDC4"))
                
                Text("Thank you!")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Your feedback helps improve Wordy for everyone.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                Button("Continue", action: onDismiss)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color(hex: "#4ECDC4"))
                    .cornerRadius(25)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.systemBackground))
            )
        }
    }
}
