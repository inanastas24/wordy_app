//1
//  ResultRow.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI

struct ResultRow: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#7F8C8D"))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
        }
    }
}
