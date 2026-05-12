import SwiftUI

struct SpeakButton: View {
    let isActive: Bool
    let action: () -> Void

    var activeSystemName: String = "speaker.wave.2.circle.fill"
    var inactiveSystemName: String = "speaker.wave.2"
    var font: Font = .system(size: 16, weight: .semibold)
    var foregroundColor: Color = .secondary
    var activeForegroundColor: Color? = nil
    var frameSize: CGFloat? = nil
    var backgroundColor: Color? = nil
    var isCircleBackground: Bool = true
    var cornerRadius: CGFloat = 12
    var activeScale: CGFloat = 0.92

    var body: some View {
        Button(action: action) {
            Image(systemName: isActive ? activeSystemName : inactiveSystemName)
                .font(font)
                .foregroundColor(isActive ? (activeForegroundColor ?? foregroundColor) : foregroundColor)
                .modifier(FrameModifier(size: frameSize))
                .modifier(BackgroundModifier(
                    color: backgroundColor,
                    isCircle: isCircleBackground,
                    cornerRadius: cornerRadius
                ))
                .scaleEffect(isActive ? activeScale : 1.0)
                .animation(.spring(response: 0.18, dampingFraction: 0.75), value: isActive)
        }
        .buttonStyle(.plain)
    }
}

private struct FrameModifier: ViewModifier {
    let size: CGFloat?

    func body(content: Content) -> some View {
        if let size {
            content.frame(width: size, height: size)
        } else {
            content
        }
    }
}

private struct BackgroundModifier: ViewModifier {
    let color: Color?
    let isCircle: Bool
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if let color {
            if isCircle {
                content
                    .background(color)
                    .clipShape(Circle())
            } else {
                content
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
        } else {
            content
        }
    }
}
