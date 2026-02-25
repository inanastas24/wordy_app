import SwiftUI

/// Gradient badge for displaying "Premium" or "Trial" status
struct PremiumBadgeView: View {
    enum BadgeType { case premium, trial }
    let type: BadgeType

    var gradient: LinearGradient {
        switch type {
        case .premium:
            return LinearGradient(
                colors: [Color.pink, Color.orange],
                startPoint: .leading, endPoint: .trailing)
        case .trial:
            return LinearGradient(
                colors: [Color.blue, Color.purple],
                startPoint: .leading, endPoint: .trailing)
        }
    }

    var text: String {
        switch type {
        case .premium: return "Premium"
        case .trial: return "Trial"
        }
    }

    var body: some View {
        Text(text)
            .font(.caption.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(gradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.24), radius: 4, y: 2)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 12) {
        PremiumBadgeView(type: .premium)
        PremiumBadgeView(type: .trial)
    }
    .padding(.vertical, 20)
    .background(.ultraThinMaterial)
}

