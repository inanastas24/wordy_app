//
//  View+IPad.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 12.03.2026.
//

import SwiftUI

struct IPadCenteredModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let maxWidth: CGFloat
    
    var isIPad: Bool {
        horizontalSizeClass == .regular
    }
    
    func body(content: Content) -> some View {
        HStack {
            if isIPad { Spacer() }
            content.frame(maxWidth: isIPad ? maxWidth : .infinity)
            if isIPad { Spacer() }
        }
    }
}

extension View {
    func iPadCentered(maxWidth: CGFloat = 600) -> some View {
        modifier(IPadCenteredModifier(maxWidth: maxWidth))
    }
}
