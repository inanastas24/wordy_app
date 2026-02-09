//1
//  KeyboardResponsiveModifier.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 28.01.2026.
//

import SwiftUI
import Combine

struct KeyboardResponsiveModifier: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onReceive(Publishers.keyboardHeight) { height in
                withAnimation(.easeOut(duration: 0.25)) {
                    self.keyboardHeight = height
                }
            }
    }
}

extension View {
    func keyboardResponsive() -> some View {
        modifier(KeyboardResponsiveModifier())
    }
}

// Допоміжний Publisher
extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default
            .publisher(for: UIApplication.keyboardWillShowNotification)
            .map { $0.keyboardHeight }
        
        let willHide = NotificationCenter.default
            .publisher(for: UIApplication.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
        
        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

extension Notification {
    var keyboardHeight: CGFloat {
        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
    }
}
