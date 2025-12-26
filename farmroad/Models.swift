import Combine
import Foundation

enum FarmTileKind: String, Codable, CaseIterable {
    case soil
    case water
    case chicken
    case fruits
    case storage
    case market
    case empty
}

struct FarmTile: Identifiable, Codable, Equatable {
    let id: UUID
    var kind: FarmTileKind
    var level: Int
    var progress: Double
    var storedAmount: Int

    init(kind: FarmTileKind) {
        self.id = UUID()
        self.kind = kind
        self.level = 1
        self.progress = 0
        self.storedAmount = 0
    }

    var productionRate: Double {
        switch kind {
        case .soil:
            return 0.15 * Double(level)
        case .water:
            return 0.10 * Double(level)
        case .chicken:
            return 0.08 * Double(level)
        case .fruits:
            return 0.12 * Double(level)
        case .storage:
            return 0
        case .market:
            return 0
        case .empty:
            return 0
        }
    }

    var capacity: Int {
        switch kind {
        case .storage:
            return 10 * level
        default:
            return 0
        }
    }

    var upgradeCost: Int {
        20 * level * level
    }

    var isUpgradeable: Bool {
        kind != .empty
    }
}

struct PlayerEconomy: Codable, Equatable {
    var coins: Int
    var energy: Int

    static let initial = PlayerEconomy(coins: 50, energy: 10)
}

struct FarmGridState: Codable, Equatable {
    var rows: Int
    var columns: Int
    var tiles: [FarmTile]

    static func initial(rows: Int, columns: Int) -> FarmGridState {
        let count = rows * columns
        var tiles: [FarmTile] = []
        for index in 0..<count {
            if index == count / 2 {
                tiles.append(FarmTile(kind: .soil))
            } else {
                tiles.append(FarmTile(kind: .empty))
            }
        }
        return FarmGridState(rows: rows, columns: columns, tiles: tiles)
    }
}

enum GamePhase: String, Codable {
    case idle
    case running
    case paused
}
