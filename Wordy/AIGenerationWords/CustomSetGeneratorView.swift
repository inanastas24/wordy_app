//
//  CustomSetGeneratorView.swift
//  Wordy
//

import SwiftUI
import FirebaseAuth
import Combine

struct CustomSetGeneratorView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @StateObject private var viewModel = CustomSetGeneratorViewModel()
    
    @State private var setTitle = ""
    @State private var setDescription = ""
    @State private var selectedDifficulty: DifficultyLevel = .a1
    @State private var wordCount = 50
    @State private var selectedTags: [String] = []
    @State private var customPrompt = ""
    @State private var showAdvancedOptions = false
    
    @State private var isGenerating = false
    @State private var generatedSet: GeneratedWordSet?
    @State private var showResult = false
    @State private var errorMessage: String?
    
    let availableTags = [
        "slang", "formal", "business", "academic", "daily",
        "travel", "food", "tech", "medical", "legal",
        "idioms", "phrasal_verbs", "collocations"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        basicInfoSection
                        difficultySection
                        tagsSection
                        advancedSection
                        generateButton
                        tipsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Create Custom Set")
            .navigationBarTitleDisplayMode(.large)
            .dismissKeyboardOnTap()
            .sheet(isPresented: $showResult) {
                if let set = generatedSet {
                    GeneratedSetPreviewView(
                        set: set,
                        onSave: { saveSet(set) },
                        onRegenerate: { regenerate() },
                        onDismiss: { showResult = false }
                    )
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles.square.filled.on.square")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "#4ECDC4"), Color(hex: "#6C5CE7")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Create Your Own Set")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text("AI will generate words based on your description")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    private var basicInfoSection: some View {
        VStack(spacing: 16) {
            // Title Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Set Title")
                    .font(.system(size: 16, weight: .semibold))
                TextField("Enter title", text: $setTitle)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color(hex: "#F5F5F5"))
                    )
            }
            
            // Description Field
            VStack(alignment: .leading, spacing: 8) {
                Text("What is this set about?")
                    .font(.system(size: 16, weight: .semibold))
                TextEditor(text: $setDescription)
                    .frame(height: 120)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color(hex: "#F5F5F5"))
                    )
            }
        }
    }
    
    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Difficulty Level")
                .font(.system(size: 16, weight: .semibold))
            
            HStack(spacing: 8) {
                ForEach([DifficultyLevel.a1, .a2, .b1, .b2, .c1], id: \.self) { level in
                    DifficultyButton(
                        level: level,
                        isSelected: selectedDifficulty == level
                    ) {
                        withAnimation(.spring(response: 0.35)) {
                            selectedDifficulty = level
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Word Count")
                        .font(.system(size: 14))
                    Spacer()
                    Text("\(wordCount)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#4ECDC4"))
                }
                
                Slider(value: .init(
                    get: { Double(wordCount) },
                    set: { wordCount = Int($0) }
                ), in: 10...100, step: 5)
                .tint(Color(hex: "#4ECDC4"))
            }
            .padding(.top, 8)
        }
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Focus Areas")
                .font(.system(size: 16, weight: .semibold))
            
            FlowLayout(spacing: 8) {
                ForEach(availableTags, id: \.self) { tag in
                    TagButton(
                        tag: tag,
                        isSelected: selectedTags.contains(tag)
                    ) {
                        toggleTag(tag)
                    }
                }
            }
        }
    }
    
    private var advancedSection: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.35)) {
                    showAdvancedOptions.toggle()
                }
            } label: {
                HStack {
                    Text("Advanced Options")
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Image(systemName: showAdvancedOptions ? "chevron.up" : "chevron.down")
                }
                .foregroundColor(.primary)
            }
            
            if showAdvancedOptions {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom Prompt")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    TextEditor(text: $customPrompt)
                        .frame(height: 100)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color(hex: "#F5F5F5"))
                        )
                    
                    Text("Add specific instructions for AI generation")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    private var generateButton: some View {
        Button {
            generateSet()
        } label: {
            HStack(spacing: 12) {
                if isGenerating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 20))
                }
                
                Text(isGenerating ? "Generating..." : "Generate Set")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: canGenerate ? [Color(hex: "#4ECDC4"), Color(hex: "#6C5CE7")] : [.gray],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
        .disabled(!canGenerate || isGenerating)
        .padding(.top, 8)
    }
    
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Generation Tips")
                .font(.system(size: 16, weight: .semibold))
            
            VStack(alignment: .leading, spacing: 8) {
                TipRow(icon: "checkmark.circle", text: "Be specific about the topic")
                TipRow(icon: "checkmark.circle", text: "Include context for better results")
                TipRow(icon: "checkmark.circle", text: "Choose appropriate difficulty level")
            }
        }
        .padding(.top, 8)
    }
    
    private var backgroundColor: Color {
        localizationManager.isDarkMode ? Color(hex: "#1C1C1E") : Color(hex: "#FFFDF5")
    }
    
    private var canGenerate: Bool {
        !setTitle.isEmpty && !setDescription.isEmpty && setTitle.count >= 3
    }
    
    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.removeAll { $0 == tag }
        } else {
            selectedTags.append(tag)
        }
    }
    
    private func generateSet() {
        guard let userId = authViewModel.user?.uid else {
            errorMessage = "Please log in first"
            return
        }
        
        isGenerating = true
        
        Task {
            do {
                let result = try await FirebaseFunctionsService.shared.generateWordSet(
                    title: setTitle,
                    description: setDescription,
                    languagePair: appState.languagePair,
                    difficulty: selectedDifficulty,
                    count: wordCount,
                    userId: userId
                )
                
                await MainActor.run {
                    generatedSet = result
                    isGenerating = false
                    showResult = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isGenerating = false
                }
            }
        }
    }
    
    private func regenerate() {
        showResult = false
        generateSet()
    }
    
    private func saveSet(_ set: GeneratedWordSet) {
        let words = set.words.map { presetWord in
            Word(
                id: presetWord.id,
                original: presetWord.original,
                translation: presetWord.translation,
                transcription: presetWord.transcription,
                exampleSentence: presetWord.exampleSentence,
                exampleTranslation: presetWord.exampleTranslation,
                synonyms: presetWord.synonyms,
                difficulty: set.difficulty,
                languagePair: set.languagePair,
                audioUrl: nil
            )
        }
        _ = UserDictionaryManager.shared.createCustomSet(
            title: set.title,
            emoji: "✨",
            gradientColors: ["#4ECDC4", "#6C5CE7"],
            category: .basics,
            words: words
        )
        
        showResult = false
    }
    
    // MARK: - Supporting Views
    
    struct DifficultyButton: View {
        let level: DifficultyLevel
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Text(level.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isSelected ? Color(hex: "#4ECDC4") : Color.gray.opacity(0.2))
                    )
            }
        }
    }
    
    struct FlowLayout: Layout {
        var spacing: CGFloat = 8
        
        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
            return result.size
        }
        
        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
            for (index, subview) in subviews.enumerated() {
                subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                          y: bounds.minY + result.positions[index].y),
                              proposal: .unspecified)
            }
        }
        
        struct FlowResult {
            var size: CGSize = .zero
            var positions: [CGPoint] = []
            
            init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
                var x: CGFloat = 0
                var y: CGFloat = 0
                var lineHeight: CGFloat = 0
                
                for subview in subviews {
                    let size = subview.sizeThatFits(.unspecified)
                    
                    if x + size.width > maxWidth && x > 0 {
                        x = 0
                        y += lineHeight + spacing
                        lineHeight = 0
                    }
                    
                    positions.append(CGPoint(x: x, y: y))
                    lineHeight = max(lineHeight, size.height)
                    x += size.width + spacing
                    
                    self.size.width = max(self.size.width, x)
                }
                
                self.size.height = y + lineHeight
            }
        }
    }
    
    struct TagButton: View {
        let tag: String
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Text(tag)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color(hex: "#6C5CE7") : Color.gray.opacity(0.2))
                    )
            }
        }
    }
    
    struct TipRow: View {
        let icon: String
        let text: String
        
        var body: some View {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "#4ECDC4"))
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - GeneratedSetPreviewView (Placeholder - implement fully)
    struct GeneratedSetPreviewView: View {
        let set: GeneratedWordSet
        let onSave: () -> Void
        let onRegenerate: () -> Void
        let onDismiss: () -> Void
        
        var body: some View {
            NavigationStack {
                VStack {
                    Text(set.title)
                        .font(.title)
                    Text("\(set.words.count) words")
                    
                    List(set.words) { word in
                        VStack(alignment: .leading) {
                            Text(word.original).font(.headline)
                            Text(word.translation).foregroundColor(.gray)
                        }
                    }
                    
                    HStack {
                        Button("Save", action: onSave)
                        Button("Regenerate", action: onRegenerate)
                        Button("Cancel", action: onDismiss)
                    }
                }
            }
        }
    }
    
    // MARK: - ViewModel
    @MainActor
    class CustomSetGeneratorViewModel: ObservableObject {
        @Published var userCredits: Int = 0
        @Published var generationHistory: [GenerationRecord] = []
        
        func loadUserCredits(userId: String) async {
            // Load from Firebase
        }
        
        func loadHistory(userId: String) async {
            // Load previous generations
        }
    }
    
    struct GenerationRecord: Identifiable, Codable {
        let id: String
        let title: String
        let createdAt: Date
        let wordCount: Int
        let cost: Double
        let quality: Double
    }
}
