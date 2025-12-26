import Combine
import SwiftUI

struct GameScreen: View {
    @ObservedObject var router: AppRouter
    @ObservedObject var viewModel: GameViewModel

    @State private var showToast = false
    @State private var toastText = ""
    @State private var toastIsError = false

    var body: some View {
        ZStack {
            AppTheme.screenBackgroundA()
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    topBar
                    economyBar
                    storageBar
                    gridArea

                    if viewModel.selectedTile() == nil {
                        hintBar
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 14)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                if showToast {
                    ToastBanner(text: toastText, isError: toastIsError)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 10) {
                if let tile = viewModel.selectedTile() {
                    selectionPanel(tile: tile)
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            viewModel.startSession()
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .onChange(of: viewModel.statusText) { _, newValue in
            guard newValue.isEmpty == false else { return }
            toastText = newValue
            toastIsError = viewModel.statusIsError
            withAnimation(.easeInOut(duration: 0.2)) { showToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                withAnimation(.easeInOut(duration: 0.2)) { showToast = false }
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button(action: {
                HapticsEngine.shared.tapLight()
                router.goToMenu()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .heavy))
                    Text("Menu")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.85))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(AppTheme.strokeSoft, lineWidth: 1)
                )
            }

            Spacer()

            PhasePill(phase: viewModel.phase)
        }
    }

    private var economyBar: some View {
        HStack(spacing: 10) {
            StatPill(symbol: AssetPalette.Symbols.coin, title: "Coins", value: "\(viewModel.coins)", a: AppTheme.accentGold, b: AppTheme.accentPurple)
            StatPill(symbol: AssetPalette.Symbols.energy, title: "Energy", value: "\(viewModel.energy)", a: AppTheme.accentBlue, b: AppTheme.accentGreen)
        }
    }

    private var storageBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.55, green: 0.55, blue: 0.60), Color(red: 0.35, green: 0.36, blue: 0.42)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 34, height: 34)

                    Image(systemName: AssetPalette.Symbols.storage)
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(Color.white.opacity(0.98))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Storage")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)

                    Text("\(viewModel.storageAmount) / \(viewModel.storageCapacity)")
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

    private var gridArea: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: viewModel.columns)
        return LazyVGrid(columns: cols, spacing: 10) {
            ForEach(Array(viewModel.tiles.enumerated()), id: \.element.id) { idx, tile in
                TileCell(
                    tile: tile,
                    isSelected: viewModel.selectedTileId == tile.id
                )
                .onTapGesture {
                    viewModel.onTileTap(index: idx)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerXL, style: .continuous)
                .fill(Color.white.opacity(0.80))
                .shadow(radius: 14, y: 8)
        )
    }

    private var hintBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 14, weight: .heavy))
                .symbolRenderingMode(.palette)
                .foregroundStyle(AppTheme.accentGreen, AppTheme.accentBlue)

            Text("Tap an empty tile to build. Tap buildings to upgrade or use actions.")
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

    private func selectionPanel(tile: FarmTile) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AssetPalette.tileBackground(for: tile.kind).opacity(0.20))
                        .frame(width: 46, height: 46)

                    Image(systemName: AssetPalette.tileSymbol(for: tile.kind))
                        .font(.system(size: 20, weight: .black))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(AppTheme.accentGreen, AppTheme.accentGold)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(tileTitle(tile))
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(tileSubtitle(tile))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                Button(action: {
                    HapticsEngine.shared.tapLight()
                    viewModel.closePanels()
                }) {
                    Image(systemName: AssetPalette.Symbols.close)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            if tile.kind == .empty {
                buildPanel
            } else {
                actionPanel(for: tile)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerXL, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .shadow(radius: 16, y: 10)
        )
    }

    private var buildPanel: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Text("Build")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
            }

            // 2 rows x 3 columns (buttons won't squeeze horizontally)
            let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(GameViewModel.BuildChoice.allCases) { choice in
                    BuildChip(
                        title: chipTitle(choice),
                        symbol: chipSymbol(choice),
                        isSelected: viewModel.selectedBuild == choice
                    )
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        HapticsEngine.shared.tick()
                        viewModel.selectedBuild = choice
                    }
                }

                let remainder = GameViewModel.BuildChoice.allCases.count % 3
                if remainder != 0 {
                    ForEach(0..<(3 - remainder), id: \.self) { _ in
                        Color.clear.frame(height: 1)
                    }
                }
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cost")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                    Text(viewModel.buildCostText(for: viewModel.selectedBuild))
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer()

                Button(action: {
                    viewModel.buildSelected()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "hammer.fill")
                            .font(.system(size: 14, weight: .heavy))
                        Text(viewModel.canBuildSelectedNow() ? "Build" : "Need more")
                            .font(AppTheme.buttonFont)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .opacity(0.8)
                    }
                    .foregroundStyle(Color.white)
                    .farmButtonSurface(isPrimary: true)
                    .opacity(viewModel.canBuildSelectedNow() ? 1.0 : 0.55)
                }
                .disabled(viewModel.canBuildSelectedNow() == false)
            }
        }
    }

    private func actionPanel(for tile: FarmTile) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Text("Actions")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
            }

            HStack(spacing: 10) {
                ActionChip(
                    title: "Upgrade",
                    symbol: AssetPalette.Symbols.upgrade,
                    tintA: AppTheme.accentBlue,
                    tintB: AppTheme.accentPurple
                ) {
                    viewModel.upgradeSelected()
                }

                if tile.kind == .soil || tile.kind == .water || tile.kind == .chicken || tile.kind == .fruits {
                    ActionChip(
                        title: "Harvest",
                        symbol: "basket.fill",
                        tintA: AppTheme.accentGreen,
                        tintB: AppTheme.accentGold
                    ) {
                        viewModel.harvestSelected()
                    }
                } else if tile.kind == .market {
                    ActionChip(
                        title: "Sell All",
                        symbol: AssetPalette.Symbols.market,
                        tintA: AppTheme.accentGold,
                        tintB: AppTheme.accentPurple
                    ) {
                        viewModel.sellAllSelected()
                    }
                } else if tile.kind == .storage {
                    ActionChip(
                        title: "Info",
                        symbol: "info.circle.fill",
                        tintA: Color(red: 0.55, green: 0.55, blue: 0.60),
                        tintB: AppTheme.accentBlue
                    ) {
                        HapticsEngine.shared.tapSoft()
                        toastText = "Storage holds harvested units. Build more to increase capacity."
                        toastIsError = false
                        withAnimation(.easeInOut(duration: 0.2)) { showToast = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                            withAnimation(.easeInOut(duration: 0.2)) { showToast = false }
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                Button(action: {
                    HapticsEngine.shared.tapLight()
                    viewModel.resetRun()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .heavy))
                        Text("Reset")
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
    }

    private func tileTitle(_ tile: FarmTile) -> String {
        switch tile.kind {
        case .soil: return "Soil · Lv \(tile.level)"
        case .water: return "Water · Lv \(tile.level)"
        case .chicken: return "Chicken · Lv \(tile.level)"
        case .fruits: return "Fruits · Lv \(tile.level)"
        case .storage: return "Storage · Lv \(tile.level)"
        case .market: return "Market · Lv \(tile.level)"
        case .empty: return "Empty"
        }
    }

    private func normalizedProgress(_ raw: Double) -> Double {
        if raw > 1.2 {
            return min(3.0, max(0.0, raw)) / 3.0
        }
        return min(1.0, max(0.0, raw))
    }

    private func tileSubtitle(_ tile: FarmTile) -> String {
        switch tile.kind {
        case .soil, .water, .chicken, .fruits:
            let v = normalizedProgress(tile.progress)
            return "Progress \(Int((v * 100).rounded()))%"
        case .storage:
            return "Capacity \(tile.capacity)"
        case .market:
            let price = 2 + max(0, tile.level - 1)
            return "Price \(price)/unit"
        case .empty:
            return "Tap to build"
        }
    }

    private func chipTitle(_ choice: GameViewModel.BuildChoice) -> String {
        switch choice {
        case .soil: return "Soil"
        case .water: return "Water"
        case .chicken: return "Chicken"
        case .fruits: return "Fruits"
        case .storage: return "Storage"
        case .market: return "Market"
        }
    }

    private func chipSymbol(_ choice: GameViewModel.BuildChoice) -> String {
        switch choice {
        case .soil: return AssetPalette.Symbols.sprout
        case .water: return AssetPalette.Symbols.water
        case .chicken: return AssetPalette.Symbols.chicken
        case .fruits: return AssetPalette.Symbols.fruits
        case .storage: return AssetPalette.Symbols.storage
        case .market: return AssetPalette.Symbols.market
        }
    }
}

struct TileCell: View {
    let tile: FarmTile
    let isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cellFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isSelected ? AppTheme.accentBlue.opacity(0.9) : AppTheme.strokeSoft, lineWidth: isSelected ? 2 : 1)
                )

            VStack(spacing: 8) {
                Image(systemName: AssetPalette.tileSymbol(for: tile.kind))
                    .font(.system(size: 18, weight: .black))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(iconA, iconB)
                    .opacity(tile.kind == .empty ? 0.55 : 1.0)

                if tile.kind == .soil || tile.kind == .water || tile.kind == .chicken || tile.kind == .fruits {
                    MiniProgress(
                        value: normalizedProgress(tile.progress),
                        gradient: progressGradient(for: tile.kind)
                    )
                } else if tile.kind == .storage {
                    Text("\(tile.storedAmount)/\(tile.capacity)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.92))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .allowsTightening(true)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.black.opacity(0.18))
                        )
                } else if tile.kind == .market {
                    Text("Sell")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.92))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .allowsTightening(true)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.black.opacity(0.18))
                        )
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.white.opacity(0.80))
                        )
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func normalizedProgress(_ raw: Double) -> Double {
        if raw > 1.2 {
            return min(3.0, max(0.0, raw)) / 3.0
        }
        return min(1.0, max(0.0, raw))
    }

    private func progressGradient(for kind: FarmTileKind) -> LinearGradient {
        switch kind {
        case .water:
            return AssetPalette.Production.waterGradient
        case .soil:
            return AssetPalette.Production.growthGradient
        case .chicken:
            return AssetPalette.Production.chickenGradient
        case .fruits:
            return AssetPalette.Production.fruitsGradient
        default:
            return AssetPalette.Production.growthGradient
        }
    }

    private var cellFill: Color {
        if tile.kind == .empty {
            return Color.black.opacity(0.05)
        }
        return AssetPalette.tileBackground(for: tile.kind).opacity(0.30)
    }

    private var iconA: Color {
        switch tile.kind {
        case .soil: return AppTheme.accentGreen
        case .water: return AppTheme.accentBlue
        case .chicken: return AppTheme.accentGold
        case .fruits: return AppTheme.accentGreen
        case .storage: return Color(red: 0.55, green: 0.55, blue: 0.60)
        case .market: return AppTheme.accentGold
        case .empty: return AppTheme.textSecondary
        }
    }

    private var iconB: Color {
        switch tile.kind {
        case .soil: return AppTheme.accentGold
        case .water: return AppTheme.accentPurple
        case .chicken: return AppTheme.accentPurple
        case .fruits: return AppTheme.accentGold
        case .storage: return AppTheme.accentBlue
        case .market: return AppTheme.accentPurple
        case .empty: return AppTheme.textSecondary
        }
    }
}

struct MiniProgress: View {
    let value: Double
    let gradient: LinearGradient

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(0.10))
                Capsule(style: .continuous)
                    .fill(gradient)
                    .frame(width: max(8, geo.size.width * min(1.0, max(0.0, value))))
                    .animation(.easeInOut(duration: 0.15), value: value)
            }
        }
        .frame(height: 10)
    }
}

struct BuildChip: View {
    let title: String
    let symbol: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .heavy))
            Text(title)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .foregroundStyle(isSelected ? Color.white : AppTheme.textPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            Capsule(style: .continuous)
                .fill(isSelected ? AnyShapeStyle(AppTheme.successGradient()) : AnyShapeStyle(Color.black.opacity(0.06)))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(isSelected ? Color.white.opacity(0.0) : AppTheme.strokeSoft, lineWidth: 1)
        )
    }
}

struct ActionChip: View {
    let title: String
    let symbol: String
    let tintA: Color
    let tintB: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [tintA.opacity(0.95), tintB.opacity(0.95)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)
                    Image(systemName: symbol)
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(Color.white.opacity(0.98))
                }
                Text(title)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .allowsTightening(true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.strokeSoft, lineWidth: 1)
            )
        }
    }
}

struct StatPill: View {
    let symbol: String
    let title: String
    let value: String
    let a: Color
    let b: Color

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [a.opacity(0.95), b.opacity(0.95)], startPoint: .topLeading, endPoint: .bottomTrailing)
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
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

struct PhasePill: View {
    let phase: GamePhase

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
            Capsule(style: .continuous)
                .fill(gradient)
        )
        .shadow(radius: 10, y: 6)
    }

    private var text: String {
        switch phase {
        case .idle: return "Idle"
        case .running: return "Running"
        case .paused: return "Paused"
        }
    }

    private var symbol: String {
        switch phase {
        case .idle: return "moon.stars.fill"
        case .running: return "bolt.fill"
        case .paused: return "pause.fill"
        }
    }

    private var gradient: LinearGradient {
        switch phase {
        case .idle:
            return LinearGradient(colors: [AppTheme.accentPurple, AppTheme.accentBlue], startPoint: .leading, endPoint: .trailing)
        case .running:
            return LinearGradient(colors: [AppTheme.accentGreen, AppTheme.accentBlue], startPoint: .leading, endPoint: .trailing)
        case .paused:
            return LinearGradient(colors: [AppTheme.accentGold, AppTheme.accentPurple], startPoint: .leading, endPoint: .trailing)
        }
    }
}

struct ToastBanner: View {
    let text: String
    let isError: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                .font(.system(size: 14, weight: .heavy))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, isError ? Color(red: 0.95, green: 0.75, blue: 0.30) : AppTheme.accentGold)

            Text(text)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.96))
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isError ? [Color(red: 0.90, green: 0.35, blue: 0.35), AppTheme.accentPurple] : [AppTheme.accentGreen, AppTheme.accentBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .shadow(radius: 14, y: 10)
        .padding(.horizontal, 16)
    }
}
