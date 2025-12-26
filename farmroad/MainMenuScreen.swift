import Combine
import SwiftUI

struct MainMenuScreen: View {
    @ObservedObject var router: AppRouter
    @ObservedObject var viewModel: MenuViewModel

    @State private var pulse = false

    var body: some View {
        ZStack {
            AppTheme.screenBackgroundB()
                .ignoresSafeArea()

            VStack(spacing: 16) {
                header

                statsRow

                tipCard

                VStack(spacing: 12) {
                    Button(action: {
                        HapticsEngine.shared.tapRigid()
                        router.goToGame()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: AssetPalette.Symbols.play)
                                .font(.system(size: 15, weight: .heavy))
                            Text("Play")
                                .font(AppTheme.buttonFont)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .opacity(0.8)
                        }
                        .foregroundStyle(Color.white)
                        .farmButtonSurface(isPrimary: true)
                    }

                    Button(action: {
                        HapticsEngine.shared.tapLight()
                        router.goToSettings()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: AssetPalette.Symbols.settings)
                                .font(.system(size: 15, weight: .heavy))
                            Text("Settings")
                                .font(AppTheme.buttonFont)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .opacity(0.55)
                        }
                        .foregroundStyle(AppTheme.textPrimary)
                        .farmButtonSurface(isPrimary: false)
                    }
                }
            }
            .farmCard()
        }
        .onAppear {
            pulse = true
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.92))
                        .frame(width: 54, height: 54)
                        .shadow(radius: 12, y: 8)

                    Image(systemName: AssetPalette.Symbols.grid)
                        .font(.system(size: 22, weight: .black))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(AppTheme.accentGreen, AppTheme.accentGold)
                        .scaleEffect(pulse ? 1.03 : 0.97)
                        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.title)
                        .font(AppTheme.titleFont)
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(viewModel.subtitle)
                        .font(AppTheme.subtitleFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statChip(
                symbol: AssetPalette.Symbols.coin,
                title: "Coins",
                value: "\(viewModel.coins)",
                a: AppTheme.accentGold,
                b: AppTheme.accentPurple
            )

            statChip(
                symbol: AssetPalette.Symbols.energy,
                title: "Energy",
                value: "\(viewModel.energy)",
                a: AppTheme.accentBlue,
                b: AppTheme.accentGreen
            )
        }
    }

    private var tipCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14, weight: .heavy))
                .symbolRenderingMode(.palette)
                .foregroundStyle(AppTheme.accentGold, AppTheme.accentPurple)

            Text(viewModel.tipLine)
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textSecondary)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerL, style: .continuous)
                .fill(Color.white.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerL, style: .continuous)
                .stroke(AppTheme.strokeSoft, lineWidth: 1)
        )
    }

    private func statChip(symbol: String, title: String, value: String, a: Color, b: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [a.opacity(0.95), b.opacity(0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 34, height: 34)

                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(Color.white.opacity(0.98))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)

                Text(value)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerL, style: .continuous)
                .fill(Color.white.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerL, style: .continuous)
                .stroke(AppTheme.strokeSoft, lineWidth: 1)
        )
    }
}
