import Combine
import Foundation

final class GridEngine: ObservableObject {
    @Published private(set) var grid: FarmGridState
    @Published private(set) var phase: GamePhase = .idle
    @Published var focusedTileId: UUID?
    @Published private(set) var lastActionMessage: String = ""
    @Published private(set) var lastActionIsError: Bool = false

    private let economy: EconomyEngine
    private var bag = Set<AnyCancellable>()
    private var loopBag = Set<AnyCancellable>()

    private let tickHz: Double = 30.0
    private var secondsAccumulator: Double = 0.0

    init(rows: Int = 5, columns: Int = 5, economy: EconomyEngine) {
        self.economy = economy
        self.grid = FarmGridState.initial(rows: rows, columns: columns)
        ensureInitialMarket()
    }

    func setGrid(_ state: FarmGridState) {
        grid = state
        focusedTileId = nil
        ensureInitialMarket()
        setMessage("", isError: false)
    }

    func reset(rows: Int = 5, columns: Int = 5) {
        grid = FarmGridState.initial(rows: rows, columns: columns)
        focusedTileId = nil
        phase = .idle
        secondsAccumulator = 0
        ensureInitialMarket()
        setMessage("", isError: false)
    }

    func start() {
        guard phase != .running else { return }
        phase = .running
        secondsAccumulator = 0
        startLoop()
    }

    func pause() {
        guard phase == .running else { return }
        phase = .paused
        stopLoop()
    }

    func resume() {
        guard phase == .paused else { return }
        phase = .running
        startLoop()
    }

    func stop() {
        phase = .idle
        stopLoop()
    }

    func tile(at index: Int) -> FarmTile? {
        guard index >= 0, index < grid.tiles.count else { return nil }
        return grid.tiles[index]
    }

    func index(for id: UUID) -> Int? {
        grid.tiles.firstIndex(where: { $0.id == id })
    }

    func focusTile(id: UUID?) {
        focusedTileId = id
        setMessage("", isError: false)
    }

    func canBuild(kind: FarmTileKind, on index: Int) -> Bool {
        guard let t = tile(at: index) else { return false }
        guard t.kind == .empty else { return false }
        let coinCost = economy.buildCost(for: kind)
        let energyCost = economy.energyCost(for: kind)
        return economy.canSpendCoins(coinCost) && economy.canSpendEnergy(energyCost)
    }

    func build(kind: FarmTileKind, on index: Int) {
        guard index >= 0, index < grid.tiles.count else { return }
        var current = grid.tiles[index]
        guard current.kind == .empty else {
            setMessage("This spot is already used.", isError: true)
            return
        }

        let coinCost = economy.buildCost(for: kind)
        let energyCost = economy.energyCost(for: kind)

        guard economy.canSpendCoins(coinCost) else {
            setMessage("Not enough coins.", isError: true)
            return
        }
        guard economy.canSpendEnergy(energyCost) else {
            setMessage("Not enough energy.", isError: true)
            return
        }

        guard economy.spendCoins(coinCost), economy.spendEnergy(energyCost) else {
            setMessage("Cannot build right now.", isError: true)
            return
        }

        current.kind = kind
        current.level = 1
        current.progress = 0
        current.storedAmount = 0

        grid.tiles[index] = current
        focusedTileId = current.id
        setMessage("Built \(kind.rawValue).", isError: false)
    }

    func canUpgrade(tileId: UUID) -> Bool {
        guard let idx = index(for: tileId) else { return false }
        let t = grid.tiles[idx]
        guard t.isUpgradeable else { return false }
        let cost = economy.upgradeCost(for: t)
        return economy.canSpendCoins(cost)
    }

    func upgrade(tileId: UUID) {
        guard let idx = index(for: tileId) else { return }
        var t = grid.tiles[idx]
        guard t.isUpgradeable else {
            setMessage("Nothing to upgrade.", isError: true)
            return
        }

        let cost = economy.upgradeCost(for: t)
        guard economy.canSpendCoins(cost) else {
            setMessage("Not enough coins.", isError: true)
            return
        }

        guard economy.spendCoins(cost) else {
            setMessage("Upgrade failed.", isError: true)
            return
        }

        t.level += 1
        if t.kind == .storage {
            t.storedAmount = min(t.storedAmount, t.capacity)
        }
        grid.tiles[idx] = t
        focusedTileId = t.id
        setMessage("Upgraded to level \(t.level).", isError: false)
    }

    func harvest(tileId: UUID) {
        guard let idx = index(for: tileId) else { return }
        let t = grid.tiles[idx]
        guard t.kind == .soil || t.kind == .water || t.kind == .chicken || t.kind == .fruits else {
            setMessage("Nothing to harvest here.", isError: true)
            return
        }

        let producedUnits = flushProduction(at: idx)
        if producedUnits <= 0 {
            setMessage("Not ready yet.", isError: true)
            return
        }

        let stored = storeUnits(producedUnits)
        if stored <= 0 {
            setMessage("No storage available.", isError: true)
            return
        }

        if stored < producedUnits {
            setMessage("Storage is full.", isError: true)
        } else {
            setMessage("Collected +\(stored).", isError: false)
        }
    }

    func sellAllAtMarket(tileId: UUID) {
        guard let idx = index(for: tileId) else { return }
        let t = grid.tiles[idx]
        guard t.kind == .market else {
            setMessage("No market selected.", isError: true)
            return
        }

        let totalStored = totalStorageAmount()
        guard totalStored > 0 else {
            setMessage("Nothing to sell.", isError: true)
            return
        }

        let gained = economy.sellAll(from: totalStored, marketLevel: t.level)
        clearAllStorage()
        setMessage("Sold for +\(gained) coins.", isError: false)
    }

    func totalStorageAmount() -> Int {
        grid.tiles.reduce(0) { partial, tile in
            if tile.kind == .storage { return partial + tile.storedAmount }
            return partial
        }
    }

    func totalStorageCapacity() -> Int {
        grid.tiles.reduce(0) { partial, tile in
            if tile.kind == .storage { return partial + tile.capacity }
            return partial
        }
    }

    func startLoopIfRunning() {
        if phase == .running {
            startLoop()
        }
    }

    private func startLoop() {
        loopBag.removeAll()
        Timer.publish(every: 1.0 / tickHz, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick(dt: 1.0 / self!.tickHz)
            }
            .store(in: &loopBag)
    }

    private func stopLoop() {
        loopBag.removeAll()
    }

    private func tick(dt: Double) {
        guard phase == .running else { return }

        secondsAccumulator += dt
        if secondsAccumulator > 60 {
            secondsAccumulator = 0
        }

        var newTiles = grid.tiles
        for i in newTiles.indices {
            let kind = newTiles[i].kind
            if kind == .soil || kind == .water || kind == .chicken || kind == .fruits {
                let base = newTiles[i].productionRate
                let mult = productionMultiplierForTile(at: i, tiles: newTiles)
                let rate = base * mult
                if rate > 0 {
                    newTiles[i].progress = min(3.0, newTiles[i].progress + rate * dt)
                }
            }
        }
        grid.tiles = newTiles

        setMessage("", isError: false)
    }

    private func productionMultiplierForTile(at index: Int, tiles: [FarmTile]) -> Double {
        let neighbors = neighborIndices(of: index, rows: grid.rows, columns: grid.columns)
        var boost = 0.0
        for n in neighbors {
            let t = tiles[n]
            if t.kind == .water {
                boost += 0.12 * Double(t.level)
            }
            if t.kind == .soil {
                boost += 0.06 * Double(t.level)
            }
        }
        return 1.0 + boost
    }

    private func flushProduction(at index: Int) -> Int {
        guard index >= 0, index < grid.tiles.count else { return 0 }
        var t = grid.tiles[index]
        guard t.kind == .soil || t.kind == .water || t.kind == .chicken || t.kind == .fruits else { return 0 }

        let units = Int(floor(t.progress))
        guard units > 0 else { return 0 }

        t.progress = max(0, t.progress - Double(units))
        grid.tiles[index] = t
        return units
    }

    private func storeUnits(_ units: Int) -> Int {
        guard units > 0 else { return 0 }

        var remaining = units
        var newTiles = grid.tiles

        let storageIndices = newTiles.indices.filter { newTiles[$0].kind == .storage }
        guard !storageIndices.isEmpty else { return 0 }

        for idx in storageIndices {
            if remaining <= 0 { break }
            let cap = newTiles[idx].capacity
            let current = newTiles[idx].storedAmount
            let free = max(0, cap - current)
            if free <= 0 { continue }
            let add = min(free, remaining)
            newTiles[idx].storedAmount = current + add
            remaining -= add
        }

        grid.tiles = newTiles
        return units - remaining
    }

    private func clearAllStorage() {
        var newTiles = grid.tiles
        for i in newTiles.indices where newTiles[i].kind == .storage {
            newTiles[i].storedAmount = 0
        }
        grid.tiles = newTiles
    }

    private func ensureInitialMarket() {
        if grid.tiles.contains(where: { $0.kind == .market }) { return }
        let rows = grid.rows
        let cols = grid.columns
        guard rows > 0, cols > 0 else { return }

        let targetIndex = (rows / 2) * cols + (cols / 2)
        guard targetIndex >= 0, targetIndex < grid.tiles.count else { return }

        var t = grid.tiles[targetIndex]
        t.kind = .market
        t.level = 1
        t.progress = 0
        t.storedAmount = 0
        grid.tiles[targetIndex] = t
    }

    private func neighborIndices(of index: Int, rows: Int, columns: Int) -> [Int] {
        let r = index / columns
        let c = index % columns

        var out: [Int] = []

        let up = r - 1
        let down = r + 1
        let left = c - 1
        let right = c + 1

        if up >= 0 { out.append(up * columns + c) }
        if down < rows { out.append(down * columns + c) }
        if left >= 0 { out.append(r * columns + left) }
        if right < columns { out.append(r * columns + right) }

        return out
    }

    private func setMessage(_ text: String, isError: Bool) {
        lastActionMessage = text
        lastActionIsError = isError
    }
}
