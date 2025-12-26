import Combine
import SwiftUI

struct SoftCard<Content: View>: View {
    let isPrimary: Bool
    let content: Content

    init(isPrimary: Bool = true, @ViewBuilder content: () -> Content) {
        self.isPrimary = isPrimary
        self.content = content()
    }

    var body: some View {
        let sh = AppTheme.cardShadow(isPrimary: isPrimary)
        content
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerXL, style: .continuous)
                    .fill(Color.white.opacity(0.90))
                    .shadow(radius: sh.radius, y: sh.y)
            )
    }
}

struct IconBadge: View {
    let symbol: String
    let a: Color
    let b: Color
    let size: CGFloat

    init(symbol: String, a: Color, b: Color, size: CGFloat = 34) {
        self.symbol = symbol
        self.a = a
        self.b = b
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [a.opacity(0.95), b.opacity(0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Image(systemName: symbol)
                .font(.system(size: size * 0.42, weight: .black))
                .foregroundStyle(Color.white.opacity(0.98))
        }
    }
}

struct PillBadge: View {
    let symbol: String
    let text: String
    let gradient: LinearGradient

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .heavy))
            Text(text)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
        }
        .foregroundStyle(Color.white.opacity(0.96))
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous).fill(gradient)
        )
        .shadow(radius: 10, y: 6)
    }
}

struct GradientBar: View {
    let progress: Double
    let gradient: LinearGradient

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(0.10))
                Capsule(style: .continuous)
                    .fill(gradient)
                    .frame(width: max(10, geo.size.width * min(1.0, max(0.0, progress))))
                    .animation(.easeInOut(duration: 0.15), value: progress)
            }
        }
        .frame(height: 18)
    }
}

struct TinyTag: View {
    let text: String
    let a: Color
    let b: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.96))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [a.opacity(0.95), b.opacity(0.95)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(radius: 10, y: 6)
    }
}

struct PressableScaleModifier: ViewModifier {
    let enabled: Bool
    @State private var isDown = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(enabled ? (isDown ? 0.98 : 1.0) : 1.0)
            .opacity(enabled ? (isDown ? 0.92 : 1.0) : 0.55)
            .animation(.easeInOut(duration: 0.12), value: isDown)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard enabled else { return }
                        if isDown == false { isDown = true }
                    }
                    .onEnded { _ in
                        isDown = false
                    }
            )
    }
}

extension View {
    func pressable(enabled: Bool = true) -> some View {
        modifier(PressableScaleModifier(enabled: enabled))
    }
}

struct SubtleDivider: View {
    var body: some View {
        Rectangle()
            .fill(AppTheme.strokeSoft)
            .frame(height: 1)
            .padding(.horizontal, 6)
    }
}

struct HeaderRow: View {
    let title: String
    let symbol: String
    let a: Color
    let b: Color

    var body: some View {
        HStack(spacing: 10) {
            IconBadge(symbol: symbol, a: a, b: b, size: 34)
            Text(title)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
        }
    }
}

struct InlineNotice: View {
    let text: String
    let isError: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                .font(.system(size: 13, weight: .heavy))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, AppTheme.accentGold)

            Text(text)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.96))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isError
                            ? [Color(red: 0.90, green: 0.35, blue: 0.35), AppTheme.accentPurple]
                            : [AppTheme.accentGreen, AppTheme.accentBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .shadow(radius: 14, y: 10)
    }
}

struct GlowCircle: View {
    let a: Color
    let b: Color
    let size: CGFloat
    @State private var breathe = false

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [a.opacity(breathe ? 0.20 : 0.12), b.opacity(breathe ? 0.18 : 0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .blur(radius: 0.6)
            .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: breathe)
            .onAppear { breathe = true }
    }
}

struct ChipButton: View {
    let title: String
    let symbol: String
    let selected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            HapticsEngine.shared.tick()
            onTap()
        }) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .heavy))
                Text(title)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(selected ? Color.white : AppTheme.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(
                Capsule(style: .continuous)
                    .fill(selected ? AnyShapeStyle(AppTheme.successGradient()) : AnyShapeStyle(Color.black.opacity(0.06)))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(selected ? Color.white.opacity(0.0) : AppTheme.strokeSoft, lineWidth: 1)
            )
        }
        .pressable(enabled: true)
    }
}

struct PrimaryCTAButton: View {
    let title: String
    let symbol: String
    let enabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            guard enabled else { return }
            HapticsEngine.shared.tapRigid()
            onTap()
        }) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .heavy))
                Text(title)
                    .font(AppTheme.buttonFont)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .opacity(0.8)
            }
            .foregroundStyle(Color.white)
            .farmButtonSurface(isPrimary: true)
            .opacity(enabled ? 1.0 : 0.55)
        }
        .disabled(enabled == false)
        .pressable(enabled: enabled)
    }
}

struct SecondaryCTAButton: View {
    let title: String
    let symbol: String
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            HapticsEngine.shared.tapLight()
            onTap()
        }) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .heavy))
                Text(title)
                    .font(AppTheme.buttonFont)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .opacity(0.55)
            }
            .foregroundStyle(AppTheme.textPrimary)
            .farmButtonSurface(isPrimary: false)
        }
        .pressable(enabled: true)
    }
}
