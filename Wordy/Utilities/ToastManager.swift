//
//  ToastManager.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 15.03.2026.
//

import SwiftUI
import Combine
import UIKit

enum ToastStyle {
    case error
    case warning
    case success
    case info
    
    var icon: String {
        switch self {
        case .error: return "exclamationmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .error: return Color(hex: "#FF6B6B")
        case .warning: return Color(hex: "#FFD93D")
        case .success: return Color(hex: "#4ECDC4")
        case .info: return Color(hex: "#A8D8EA")
        }
    }
}

@MainActor
final class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var isShowing = false
    @Published var message = ""
    @Published var style: ToastStyle = .info
    
    private var dismissTask: Task<Void, Never>?
    
    private init() {}
    
    func show(message: String, style: ToastStyle = .info, duration: TimeInterval = 3.0) {
        dismissTask?.cancel()
        
        self.message = message
        self.style = style
        self.isShowing = true
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        switch style {
        case .error: generator.notificationOccurred(.error)
        case .warning: generator.notificationOccurred(.warning)
        case .success: generator.notificationOccurred(.success)
        case .info: let light = UIImpactFeedbackGenerator(style: .light); light.impactOccurred()
        }
        
        dismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if !Task.isCancelled {
                withAnimation(.easeOut(duration: 0.3)) {
                    self.isShowing = false
                }
            }
        }
    }
    
    func hide() {
        dismissTask?.cancel()
        withAnimation(.easeOut(duration: 0.3)) {
            isShowing = false
        }
    }
}

struct ToastView: View {
    @EnvironmentObject var toastManager: ToastManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack {
            if toastManager.isShowing {
                HStack(spacing: 12) {
                    Image(systemName: toastManager.style.icon)
                        .font(.system(size: 20))
                        .foregroundColor(toastManager.style.color)
                    
                    Text(toastManager.message)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Button {
                        toastManager.hide()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E") : Color.white)
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(toastManager.style.color.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.top, 80)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1000)
            }
            
            Spacer()
        }
    }
}

