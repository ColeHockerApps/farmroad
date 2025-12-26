import Combine
import SwiftUI

enum AssetPalette {
    enum Symbols {
        static let grid = "square.grid.3x3.fill"
        static let tile = "square.fill"
        static let sprout = "leaf.fill"
        static let water = "drop.fill"
        static let chicken = "bird.fill"
        static let fruits = "apple.logo"
        static let storage = "shippingbox.fill"
        static let market = "cart.fill"
        static let upgrade = "arrow.up.circle.fill"
        static let coin = "circle.hexagongrid.fill"
        static let energy = "bolt.fill"
        static let timer = "clock.fill"
        static let settings = "gearshape.fill"
        static let privacy = "hand.raised.fill"
        static let play = "play.fill"
        static let close = "xmark.circle.fill"
        static let check = "checkmark.seal.fill"
        static let spark = "sparkles"
    }

    enum TileColors {
        static let soil = Color(red: 0.45, green: 0.32, blue: 0.22)
        static let water = Color(red: 0.20, green: 0.55, blue: 0.85)
        static let chicken = Color(red: 0.95, green: 0.55, blue: 0.35)
        static let fruits = Color(red: 0.70, green: 0.45, blue: 0.90)
        static let storage = Color(red: 0.55, green: 0.55, blue: 0.60)
        static let market = Color(red: 0.95, green: 0.75, blue: 0.30)
        static let inactive = Color.black.opacity(0.08)
    }

    enum Production {
        static let growthGradient = LinearGradient(
            colors: [
                Color(red: 0.20, green: 0.75, blue: 0.45),
                Color(red: 0.10, green: 0.60, blue: 0.35)
            ],
            startPoint: .bottom,
            endPoint: .top
        )

        static let waterGradient = LinearGradient(
            colors: [
                Color(red: 0.30, green: 0.70, blue: 1.00),
                Color(red: 0.15, green: 0.45, blue: 0.90)
            ],
            startPoint: .bottom,
            endPoint: .top
        )

        static let chickenGradient = LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.68, blue: 0.32),
                Color(red: 0.92, green: 0.45, blue: 0.30)
            ],
            startPoint: .bottom,
            endPoint: .top
        )

        static let fruitsGradient = LinearGradient(
            colors: [
                Color(red: 0.92, green: 0.55, blue: 0.92),
                Color(red: 0.55, green: 0.42, blue: 0.93)
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    enum Economy {
        static let profit = Color(red: 0.20, green: 0.75, blue: 0.45)
        static let loss = Color(red: 0.90, green: 0.35, blue: 0.35)
        static let neutral = Color(red: 0.55, green: 0.55, blue: 0.60)
    }

    static func tileBackground(for kind: FarmTileKind) -> Color {
        switch kind {
        case .soil:
            return TileColors.soil
        case .water:
            return TileColors.water
        case .chicken:
            return TileColors.chicken
        case .fruits:
            return TileColors.fruits
        case .storage:
            return TileColors.storage
        case .market:
            return TileColors.market
        case .empty:
            return TileColors.inactive
        }
    }

    static func tileSymbol(for kind: FarmTileKind) -> String {
        switch kind {
        case .soil:
            return Symbols.sprout
        case .water:
            return Symbols.water
        case .chicken:
            return Symbols.chicken
        case .fruits:
            return Symbols.fruits
        case .storage:
            return Symbols.storage
        case .market:
            return Symbols.market
        case .empty:
            return Symbols.tile
        }
    }

    static func productionGradient(for kind: FarmTileKind) -> LinearGradient {
        switch kind {
        case .soil:
            return Production.growthGradient
        case .water:
            return Production.waterGradient
        case .chicken:
            return Production.chickenGradient
        case .fruits:
            return Production.fruitsGradient
        default:
            return Production.growthGradient
        }
    }
}
