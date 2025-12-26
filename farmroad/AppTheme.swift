import Combine
import SwiftUI

enum AppTheme {
    static let cornerXL: CGFloat = 28
    static let cornerL: CGFloat = 20
    static let cornerM: CGFloat = 16
    static let cornerS: CGFloat = 12

    static let shadowRadiusPrimary: CGFloat = 18
    static let shadowRadiusSecondary: CGFloat = 10
    static let shadowYOffsetPrimary: CGFloat = 10
    static let shadowYOffsetSecondary: CGFloat = 6

    static let titleFont: Font = .system(size: 22, weight: .heavy, design: .rounded)
    static let subtitleFont: Font = .system(size: 14, weight: .semibold, design: .rounded)
    static let bodyFont: Font = .system(size: 15, weight: .semibold, design: .rounded)
    static let buttonFont: Font = .system(size: 16, weight: .heavy, design: .rounded)
    static let captionFont: Font = .system(size: 12, weight: .semibold, design: .rounded)

    static let bgA = Color(red: 0.95, green: 0.98, blue: 1.00)
    static let bgB = Color(red: 0.98, green: 0.95, blue: 1.00)
    static let bgC = Color(red: 0.96, green: 0.99, blue: 0.97)
    static let bgD = Color(red: 0.98, green: 0.96, blue: 1.00)

    static let surface = Color.white.opacity(0.90)
    static let surfaceStrong = Color.white.opacity(0.96)

    static let textPrimary = Color(red: 0.12, green: 0.12, blue: 0.16)
    static let textSecondary = Color(red: 0.35, green: 0.36, blue: 0.42)
    static let textTertiary = Color.black.opacity(0.35)

    static let strokeSoft = Color.black.opacity(0.08)
    static let fillSoft = Color.black.opacity(0.06)

    static let accentGreen = Color(red: 0.12, green: 0.62, blue: 0.42)
    static let accentBlue = Color(red: 0.10, green: 0.60, blue: 0.95)
    static let accentPurple = Color(red: 0.52, green: 0.40, blue: 0.92)
    static let accentGold = Color(red: 0.92, green: 0.78, blue: 0.29)

    static func screenBackgroundA() -> LinearGradient {
        LinearGradient(colors: [bgA, bgB], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func screenBackgroundB() -> LinearGradient {
        LinearGradient(colors: [bgC, bgD], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func accentGradient() -> LinearGradient {
        LinearGradient(colors: [accentBlue, accentPurple], startPoint: .leading, endPoint: .trailing)
    }

    static func successGradient() -> LinearGradient {
        LinearGradient(colors: [accentGreen, accentBlue], startPoint: .leading, endPoint: .trailing)
    }

    static func cardBackground() -> some ShapeStyle {
        AnyShapeStyle(surface)
    }

    static func cardShadow(isPrimary: Bool) -> (radius: CGFloat, y: CGFloat) {
        if isPrimary {
            return (shadowRadiusPrimary, shadowYOffsetPrimary)
        } else {
            return (shadowRadiusSecondary, shadowYOffsetSecondary)
        }
    }
}

extension View {
    func farmCard() -> some View {
        let sh = AppTheme.cardShadow(isPrimary: true)
        return self
            .padding(.vertical, 26)
            .padding(.horizontal, 22)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerXL, style: .continuous)
                    .fill(AppTheme.cardBackground())
                    .shadow(radius: sh.radius, y: sh.y)
            )
            .padding(.horizontal, 22)
    }

    func farmButtonSurface(isPrimary: Bool) -> some View {
        self
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerL, style: .continuous)
                    .fill(isPrimary ? AnyShapeStyle(AppTheme.successGradient()) : AnyShapeStyle(AppTheme.fillSoft))
            )
            .shadow(radius: isPrimary ? 12 : 6, y: isPrimary ? 8 : 4)
    }
}
