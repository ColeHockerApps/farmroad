import Combine
import Foundation

final class EconomyEngine: ObservableObject {
    @Published private(set) var economy: PlayerEconomy
    @Published private(set) var lastCoinDelta: Int = 0
    @Published private(set) var lastEnergyDelta: Int = 0

    private var bag = Set<AnyCancellable>()
    private var regenBag = Set<AnyCancellable>()

    init(initial: PlayerEconomy = .initial) {
        self.economy = initial
    }

    func setEconomy(_ value: PlayerEconomy) {
        economy = value
        lastCoinDelta = 0
        lastEnergyDelta = 0
    }

    func canSpendCoins(_ amount: Int) -> Bool {
        amount <= economy.coins
    }

    func canSpendEnergy(_ amount: Int) -> Bool {
        amount <= economy.energy
    }

    @discardableResult
    func spendCoins(_ amount: Int) -> Bool {
        guard amount > 0 else { return true }
        guard economy.coins >= amount else { return false }
        economy.coins -= amount
        lastCoinDelta = -amount
        return true
    }

    func addCoins(_ amount: Int) {
        guard amount != 0 else { return }
        economy.coins += amount
        lastCoinDelta = amount
    }

    @discardableResult
    func spendEnergy(_ amount: Int) -> Bool {
        guard amount > 0 else { return true }
        guard economy.energy >= amount else { return false }
        economy.energy -= amount
        lastEnergyDelta = -amount
        return true
    }

    func addEnergy(_ amount: Int) {
        guard amount != 0 else { return }
        economy.energy = max(0, economy.energy + amount)
        lastEnergyDelta = amount
    }

    func clampEnergy(maxValue: Int) {
        economy.energy = min(economy.energy, max(0, maxValue))
    }

    func buildCost(for kind: FarmTileKind) -> Int {
        switch kind {
        case .soil: return 15
        case .water: return 18
        case .chicken: return 22
        case .fruits: return 20
        case .storage: return 25
        case .market: return 30
        case .empty: return 0
        }
    }

    func energyCost(for kind: FarmTileKind) -> Int {
        switch kind {
        case .soil: return 1
        case .water: return 1
        case .chicken: return 2
        case .fruits: return 2
        case .storage: return 2
        case .market: return 2
        case .empty: return 0
        }
    }

    func upgradeCost(for tile: FarmTile) -> Int {
        tile.upgradeCost
    }

    func sellPricePerUnit(marketLevel: Int) -> Int {
        let base = 2
        let bonus = max(0, marketLevel - 1)
        return base + bonus
    }

    func sellAll(from storageAmount: Int, marketLevel: Int) -> Int {
        guard storageAmount > 0 else { return 0 }
        let gain = storageAmount * sellPricePerUnit(marketLevel: marketLevel)
        addCoins(gain)
        return gain
    }

    func startEnergyRegen(tickSeconds: TimeInterval = 1.0, energyPerTick: Int = 1, maxEnergy: Int = 20) {
        regenBag.removeAll()

        Timer.publish(every: tickSeconds, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.economy.energy < maxEnergy {
                    self.economy.energy = min(maxEnergy, self.economy.energy + energyPerTick)
                    self.lastEnergyDelta = energyPerTick
                } else {
                    self.lastEnergyDelta = 0
                }
            }
            .store(in: &regenBag)
    }

    func stopEnergyRegen() {
        regenBag.removeAll()
    }
}
