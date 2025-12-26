import Combine
import Foundation

final class GameViewModel: ObservableObject {
    enum BuildChoice: String, CaseIterable, Identifiable {
        case soil
        case water
        case chicken
        case fruits
        case storage
        case market

        var id: String { rawValue }

        var tileKind: FarmTileKind {
            switch self {
            case .soil: return .soil
            case .water: return .water
            case .chicken: return .chicken
            case .fruits: return .fruits
            case .storage: return .storage
            case .market: return .market
            }
        }
    }

    @Published private(set) var rows: Int
    @Published private(set) var columns: Int

    @Published private(set) var coins: Int = 0
    @Published private(set) var energy: Int = 0

    @Published private(set) var tiles: [FarmTile] = []
    @Published private(set) var phase: GamePhase = .idle

    @Published var selectedTileId: UUID?
    @Published var selectedBuild: BuildChoice = .soil
    @Published var buildPanelShown: Bool = false

    @Published private(set) var statusText: String = ""
    @Published private(set) var statusIsError: Bool = false

    @Published private(set) var storageAmount: Int = 0
    @Published private(set) var storageCapacity: Int = 0

    private let economy: EconomyEngine
    private let gridEngine: GridEngine
    private let progress: ProgressStore
    private let haptics: HapticsEngine

    private var bag = Set<AnyCancellable>()
    private var saveBag = Set<AnyCancellable>()

    init(rows: Int = 5, columns: Int = 5, economy: EconomyEngine, gridEngine: GridEngine, progress: ProgressStore, haptics: HapticsEngine = .shared) {
        self.rows = rows
        self.columns = columns
        self.economy = economy
        self.gridEngine = gridEngine
        self.progress = progress
        self.haptics = haptics

        bindEngines()
        applySavedStateIfAny()
    }

    func startSession() {
        haptics.prepare()
        economy.startEnergyRegen(tickSeconds: 1.0, energyPerTick: 1, maxEnergy: 20)
        gridEngine.start()
        persistSnapshotSoon()
    }

    func pauseSession() {
        gridEngine.pause()
        persistSnapshotSoon()
    }

    func resumeSession() {
        gridEngine.resume()
        persistSnapshotSoon()
    }

    func stopSession() {
        gridEngine.stop()
        economy.stopEnergyRegen()
        persistSnapshotSoon()
    }

    func onTileTap(index: Int) {
        guard index >= 0, index < tiles.count else { return }
        let t = tiles[index]
        selectedTileId = t.id
        gridEngine.focusTile(id: t.id)
        buildPanelShown = (t.kind == .empty)
        haptics.tick()
        updateDerived()
    }

    func closePanels() {
        buildPanelShown = false
        selectedTileId = nil
        gridEngine.focusTile(id: nil)
        updateDerived()
    }

    func buildSelected() {
        guard let id = selectedTileId, let idx = gridEngine.index(for: id) else { return }
        let kind = selectedBuild.tileKind
        if gridEngine.canBuild(kind: kind, on: idx) == false {
            haptics.warning()
            setStatus("Not enough coins or energy.", isError: true)
            return
        }
        gridEngine.build(kind: kind, on: idx)
        haptics.tapRigid()
        buildPanelShown = false
        updateFromEngines()
        persistSnapshotSoon()
    }

    func upgradeSelected() {
        guard let id = selectedTileId else { return }
        if gridEngine.canUpgrade(tileId: id) == false {
            haptics.warning()
            setStatus("Not enough coins to upgrade.", isError: true)
            return
        }
        gridEngine.upgrade(tileId: id)
        haptics.tapLight()
        updateFromEngines()
        persistSnapshotSoon()
    }

    func harvestSelected() {
        guard let id = selectedTileId else { return }
        gridEngine.harvest(tileId: id)
        if gridEngine.lastActionIsError {
            haptics.warning()
        } else {
            haptics.tapSoft()
        }
        updateFromEngines()
        persistSnapshotSoon()
    }

    func sellAllSelected() {
        guard let id = selectedTileId else { return }
        gridEngine.sellAllAtMarket(tileId: id)
        if gridEngine.lastActionIsError {
            haptics.warning()
        } else {
            haptics.popCelebration()
        }
        updateFromEngines()
        persistSnapshotSoon()
    }

    func resetRun() {
        gridEngine.reset(rows: rows, columns: columns)
        economy.setEconomy(.initial)
        selectedTileId = nil
        buildPanelShown = false
        updateFromEngines()
        persistSnapshotSoon()
    }

    func buildCostText(for choice: BuildChoice) -> String {
        let c = economy.buildCost(for: choice.tileKind)
        let e = economy.energyCost(for: choice.tileKind)
        return "\(c) coins · \(e) energy"
    }

    func canBuildSelectedNow() -> Bool {
        guard let id = selectedTileId, let idx = gridEngine.index(for: id) else { return false }
        return gridEngine.canBuild(kind: selectedBuild.tileKind, on: idx)
    }

    func selectedTile() -> FarmTile? {
        guard let id = selectedTileId else { return nil }
        return tiles.first(where: { $0.id == id })
    }

    func selectedTileIndex() -> Int? {
        guard let id = selectedTileId else { return nil }
        return tiles.firstIndex(where: { $0.id == id })
    }

    private func bindEngines() {
        economy.$economy
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.coins = value.coins
                self?.energy = value.energy
            }
            .store(in: &bag)

        gridEngine.$grid
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.rows = state.rows
                self?.columns = state.columns
                self?.tiles = state.tiles
                self?.updateDerived()
            }
            .store(in: &bag)

        gridEngine.$phase
            .receive(on: RunLoop.main)
            .sink { [weak self] p in
                self?.phase = p
            }
            .store(in: &bag)

        Publishers.CombineLatest(gridEngine.$lastActionMessage, gridEngine.$lastActionIsError)
            .receive(on: RunLoop.main)
            .sink { [weak self] text, isError in
                guard let self else { return }
                if text.isEmpty { return }
                self.setStatus(text, isError: isError)
            }
            .store(in: &bag)

        wireAutoSaveFromEngines()
    }

    private func wireAutoSaveFromEngines() {
        saveBag.removeAll()

        economy.$economy
            .dropFirst()
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.progress.setEconomy(value)
            }
            .store(in: &saveBag)

        gridEngine.$grid
            .dropFirst()
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.progress.setGrid(value)
            }
            .store(in: &saveBag)

        gridEngine.$phase
            .dropFirst()
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.progress.setPhase(value)
            }
            .store(in: &saveBag)
    }

    private func applySavedStateIfAny() {
        let blob = progress.blob
        economy.setEconomy(blob.economy)
        gridEngine.setGrid(blob.grid)

        switch blob.phase {
        case .running:
            gridEngine.start()
        case .paused:
            gridEngine.pause()
        case .idle:
            gridEngine.stop()
        }

        updateFromEngines()
    }

    private func updateFromEngines() {
        coins = economy.economy.coins
        energy = economy.economy.energy
        phase = gridEngine.phase
        tiles = gridEngine.grid.tiles
        updateDerived()
    }

    private func updateDerived() {
        storageAmount = gridEngine.totalStorageAmount()
        storageCapacity = gridEngine.totalStorageCapacity()
    }

    private func persistSnapshotSoon() {
        progress.replaceAll(economy: economy.economy, grid: gridEngine.grid, phase: gridEngine.phase)
    }

    private func setStatus(_ text: String, isError: Bool) {
        statusText = text
        statusIsError = isError
    }
}
