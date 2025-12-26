import Combine
import SwiftUI

struct ConsentSheet: View {
    let appName: String
    let onContinue: () -> Void

    @State private var bounce = false
    @State private var glow = false

    var body: some View {
        ZStack {
            AppTheme.screenBackgroundB()
                .ignoresSafeArea()

            VStack(spacing: 16) {
                header

                VStack(spacing: 10) {
                    Text("By continuing, you agree to our Privacy Policy and Terms.")
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)

                    badgeRow
                }

                VStack(spacing: 12) {
                    Button(action: {
                        HapticsEngine.shared.tapRigid()
                        onContinue()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .heavy))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, AppTheme.accentGold.opacity(0.95))
                            Text("Continue ✅")
                                .font(AppTheme.buttonFont)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .opacity(0.8)
                        }
                        .foregroundStyle(Color.white)
                        .farmButtonSurface(isPrimary: true)
                    }

                    Text("You can open the full policy anytime in Settings → Privacy.")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .padding(.top, 2)
            }
            .farmCard()
        }
        .onAppear {
            bounce = true
            glow = true
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.92))
                    .frame(width: 96, height: 96)
                    .shadow(radius: 14, y: 9)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.accentBlue.opacity(glow ? 0.20 : 0.10),
                                AppTheme.accentPurple.opacity(glow ? 0.18 : 0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 92, height: 92)
                    .blur(radius: 0.5)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: glow)

                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(AppTheme.accentGreen, AppTheme.accentBlue)
                    .scaleEffect(bounce ? 1.0 : 0.9)
                    .animation(.spring(response: 0.45, dampingFraction: 0.7), value: bounce)
            }

            Text("Quick heads-up")
                .font(AppTheme.titleFont)
                .foregroundStyle(AppTheme.textPrimary)

            Text(appName)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var badgeRow: some View {
        HStack(spacing: 10) {
            pill(symbol: "lock.fill", title: "Privacy")
            pill(symbol: "checkmark.seal.fill", title: "Safe")
            pill(symbol: "sparkles", title: "Casual")
        }
        .padding(.top, 2)
    }

    private func pill(symbol: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .heavy))
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .foregroundStyle(Color.white.opacity(0.96))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(AppTheme.accentGradient())
        )
        .shadow(radius: 10, y: 6)
    }
}
