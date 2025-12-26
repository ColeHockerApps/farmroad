import Combine
import Foundation

final class MenuViewModel: ObservableObject {
    @Published private(set) var title: String
    @Published private(set) var subtitle: String
    @Published private(set) var tipLine: String

    @Published private(set) var coins: Int = 0
    @Published private(set) var energy: Int = 0

    private var bag = Set<AnyCancellable>()

    init(appTitle: String = "Chill Rd: Farm Road") {
        self.title = appTitle
        self.subtitle = "A tiny farm you can build in minutes."
        self.tipLine = "Tap a tile to build. Upgrade to grow faster."
    }

    func bindEconomy(_ economy: EconomyEngine) {
        bag.removeAll()
        economy.$economy
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.coins = value.coins
                self?.energy = value.energy
            }
            .store(in: &bag)
    }

    func refreshTips(for hasSave: Bool) {
        if hasSave {
            subtitle = "Your farm is waiting."
            tipLine = "Collect, store, sell, then expand."
        } else {
            subtitle = "Start small, grow smart."
            tipLine = "Build Soil first, then Storage and Market."
        }
    }
}
