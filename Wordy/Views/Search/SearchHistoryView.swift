//
//  SearchHistoryView.swift
//  Wordy
//

import SwiftUI

struct SearchHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localizationManager: LocalizationManager

    let onSelectWord: (String) -> Void

    var body: some View {
        ZStack {
            (localizationManager.isDarkMode ? Color(hex: "#111214") : Color(hex: "#F7F8F9"))
                .ignoresSafeArea()

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.primaryText(isDarkMode: localizationManager.isDarkMode))
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(AppColors.controlFill(isDarkMode: localizationManager.isDarkMode))
                            )
                    }
                    .buttonStyle(.plain)

                    Text(localizedTitle)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryText(isDarkMode: localizationManager.isDarkMode))

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)

                if appState.searchHistory.isEmpty {
                    Spacer()
                    Text(localizedEmpty)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.secondaryText(isDarkMode: localizationManager.isDarkMode))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(appState.searchHistory) { item in
                                Button {
                                    onSelectWord(item.word)
                                    dismiss()
                                } label: {
                                    HistoryCard(item: item, isDarkMode: localizationManager.isDarkMode)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var localizedTitle: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Історія пошуку"
        case .polish: return "Historia wyszukiwan"
        case .english: return "Search History"
        }
    }

    private var localizedEmpty: String {
        switch localizationManager.currentLanguage {
        case .ukrainian: return "Історія порожня"
        case .polish: return "Historia jest pusta"
        case .english: return "No searches yet"
        }
    }
}

