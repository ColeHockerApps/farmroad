import Combine
import SwiftUI

struct LoadingScreen: View {
    @ObservedObject var viewModel: LoadingViewModel

    @State private var pulse = false
    @State private var spin = false
    @State private var shimmer = false

    var body: some View {
        ZStack {
            AppTheme.screenBackgroundA()
                .ignoresSafeArea()

            FloatingBubblesLayer()
                .opacity(0.22)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(Color.white.opacity(0.85))
                            .frame(width: 118, height: 118)
                            .shadow(radius: 16, y: 10)

                        ZStack {
                            Circle()
                                .strokeBorder(Color.black.opacity(0.06), lineWidth: 10)
                                .frame(width: 86, height: 86)

                            Circle()
                                .trim(from: 0, to: max(0.08, viewModel.progress))
                                .stroke(
                                    LinearGradient(
                                        colors: [AppTheme.accentBlue, AppTheme.accentPurple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                )
                                .frame(width: 86, height: 86)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.15), value: viewModel.progress)

                            Image(systemName: AssetPalette.Symbols.sprout)
                                .font(.system(size: 34, weight: .heavy, design: .rounded))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(AppTheme.accentGreen, AppTheme.accentGold)
                                .rotationEffect(.degrees(spin ? 10 : -10))
                                .scaleEffect(pulse ? 1.06 : 0.94)
                                .opacity(pulse ? 1.0 : 0.85)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
                                .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: spin)
                        }
                    }

                    VStack(spacing: 6) {
                        Text("Chill Rd: Farm Road")
                            .font(AppTheme.titleFont)
                            .foregroundStyle(AppTheme.textPrimary)

                        Text(shimmer ? "Preparing your farm…" : "Warming up…")
                            .font(AppTheme.subtitleFont)
                            .foregroundStyle(AppTheme.textSecondary)
                            .contentTransition(.opacity)
                            .animation(.easeInOut(duration: 0.35), value: shimmer)
                    }
                }

                VStack(spacing: 10) {
                    ProgressCapsuleBar(progress: viewModel.progress)
                        .frame(height: 18)

                    HStack(spacing: 10) {
                        Text("\(Int((viewModel.progress * 100).rounded()))%")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)

                        Spacer()

                        HStack(spacing: 6) {
                            Image(systemName: AssetPalette.Symbols.spark)
                                .font(.system(size: 13, weight: .bold))
                            Text(viewModel.progress < 0.85 ? "Loading" : "Almost there")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(Color.white.opacity(0.95))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            Capsule(style: .continuous)
                                .fill(AppTheme.accentGradient())
                        )
                        .shadow(radius: 10, y: 6)
                        .opacity(viewModel.progress > 0.14 ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.progress)
                    }
                }
                .padding(.horizontal, 26)
            }
            .padding(.vertical, 28)
            .padding(.horizontal, 22)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerXL, style: .continuous)
                    .fill(AppTheme.surface)
                    .shadow(radius: AppTheme.shadowRadiusPrimary, y: AppTheme.shadowYOffsetPrimary)
            )
            .padding(.horizontal, 22)
        }
        .onAppear {
            pulse = true
            spin = true
            shimmer = false

            viewModel.start(duration: 2.0)

            Timer.publish(every: 0.55, on: .main, in: .common)
                .autoconnect()
                .prefix(4)
                .sink { _ in
                    shimmer.toggle()
                }
                .cancel()
        }
    }
}

struct ProgressCapsuleBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(AppTheme.strokeSoft)

                Capsule(style: .continuous)
                    .fill(AppTheme.accentGradient())
                    .frame(width: max(10, geo.size.width * progress))
                    .animation(.easeInOut(duration: 0.15), value: progress)

                HStack(spacing: 8) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                    Text(progress < 0.6 ? "Starting" : (progress < 0.9 ? "Building" : "Finishing"))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundStyle(Color.white.opacity(0.95))
                .padding(.horizontal, 12)
                .frame(height: geo.size.height)
                .opacity(progress > 0.12 ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: progress)
            }
        }
    }
}

struct FloatingBubblesLayer: View {
    @State private var t: CGFloat = 0
    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let w = size.width
                let h = size.height

                func bubble(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ a: CGFloat) {
                    var path = Path()
                    path.addEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
                    ctx.fill(path, with: .color(Color.white.opacity(a)))
                }

                let s1 = sin(t * 0.9)
                let s2 = sin(t * 1.2 + 1.3)
                let s3 = sin(t * 0.7 + 2.1)

                bubble(w * 0.22 + s1 * 18, h * 0.25 + s2 * 14, 34, 0.20)
                bubble(w * 0.78 + s2 * 16, h * 0.18 + s3 * 12, 26, 0.16)
                bubble(w * 0.18 + s3 * 14, h * 0.72 + s1 * 12, 28, 0.14)
                bubble(w * 0.84 + s1 * 12, h * 0.72 + s2 * 10, 40, 0.12)
                bubble(w * 0.52 + s2 * 10, h * 0.86 + s3 * 10, 22, 0.10)
                bubble(w * 0.50 + s1 * 12, h * 0.40 + s2 * 12, 54, 0.08)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onReceive(timer) { _ in
            t += 0.035
        }
    }
}
