import SwiftUI

struct DictionarySelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager

    let dictionaries: [WordDictionaryModel]
    let selectedDictionaryId: String?
    let title: String
    let onSelect: (WordDictionaryModel) -> Void

    var body: some View {
        NavigationStack {
            List(dictionaries) { dictionary in
                Button {
                    onSelect(dictionary)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dictionary.name)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(primaryTextColor)
                        }

                        Spacer()

                        if dictionary.id == selectedDictionaryId {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "#4ECDC4"))
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .listRowBackground(rowBackgroundColor)
            }
            .scrollContentBackground(.hidden)
            .background(backgroundColor)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizationManager.string(.cancel)) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var backgroundColor: Color {
        Color(hex: localizationManager.isDarkMode ? "#1C1C1E" : "#FFFDF5")
    }

    private var rowBackgroundColor: Color {
        localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : .white
    }

    private var primaryTextColor: Color {
        localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50")
    }
}

struct CreateDictionarySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager

    let onCreate: (String) -> Void
    var initialName: String = ""
    var customTitle: String? = nil
    var customConfirmText: String? = nil

    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: localizationManager.isDarkMode ? "#1C1C1E" : "#FFFDF5")
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    TextField(titleText, text: $name)
                        .textInputAutocapitalization(.words)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : .white)
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(20)
            }
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizationManager.string(.cancel)) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(createText) {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onCreate(trimmed)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if name.isEmpty {
                    name = initialName
                }
            }
        }
    }

    private var titleText: String {
        if let customTitle {
            return customTitle
        }

        switch localizationManager.currentLanguage {
        case .ukrainian: return "Новий словник"
        case .polish: return "Nowy slownik"
        case .english: return "New Dictionary"
        }
    }

    private var createText: String {
        if let customConfirmText {
            return customConfirmText
        }

        switch localizationManager.currentLanguage {
        case .ukrainian: return "Створити"
        case .polish: return "Utworz"
        case .english: return "Create"
        }
    }
}
