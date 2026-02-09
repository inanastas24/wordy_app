//1
//  HeaderView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI

// === HEADER ===
struct HeaderView: View {
    @Binding var showMenu: Bool
    let title: String
    var showAvatar: Bool = false
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        HStack {
            Button(action: { withAnimation { showMenu = true } }) {
                Image(systemName: "line.horizontal.3")
                    .font(.system(size: 24))
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
            }
            
            Spacer()
            
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
            
            Spacer()
            
            if showAvatar {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: "#4ECDC4"))
            } else {
                Image(systemName: "line.horizontal.3")
                    .font(.system(size: 24))
                    .opacity(0)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(localizationManager.isDarkMode ? Color(hex: "#1C1C1E") : Color(hex: "#FFFDF5"))
    }
}
