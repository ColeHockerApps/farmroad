import Combine
import SwiftUI

@main
struct FarmRoadApp: App {
    @StateObject private var router = AppRouter()
    @StateObject private var progress = ProgressStore(appId: "chillrd.farmroad", rows: 5, columns: 5)
    @StateObject private var economy = EconomyEngine(initial: .initial)
    @StateObject private var loadingVM = LoadingViewModel()
    @StateObject private var menuVM = MenuViewModel(appTitle: "Chill Rd: Farm Road")

    private var gridEngine: GridEngine
    private var gameVM: GameViewModel
    private var settingsVM: SettingsViewModel

    init() {
        let p = ProgressStore(appId: "chillrd.farmroad", rows: 5, columns: 5)
        let e = EconomyEngine(initial: .initial)
        let g = GridEngine(rows: 5, columns: 5, economy: e)
        self.gridEngine = g
        self.gameVM = GameViewModel(rows: 5, columns: 5, economy: e, gridEngine: g, progress: p, haptics: .shared)
        self.settingsVM = SettingsViewModel(progress: p)
        _progress = StateObject(wrappedValue: p)
        _economy = StateObject(wrappedValue: e)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                switch router.phase {
                case .loading:
                    LoadingScreen(viewModel: loadingVM)
                        .onReceive(loadingVM.finishedPublisher) { _ in
                            if progress.hasAcceptedConsent() {
                                router.goToMenu()
                            } else {
                                router.goToConsent()
                            }
                        }

                case .consent:
                    ConsentSheet(
                        appName: "Chill Rd: Farm Road",
                        onContinue: {
                            progress.setConsentAccepted()
                            menuVM.bindEconomy(economy)
                            menuVM.refreshTips(for: true)
                            router.goToMenu()
                        }
                    )

                case .menu:
                    MainMenuScreen(
                        router: router,
                        viewModel: menuVM
                    )
                    .onAppear {
                        menuVM.bindEconomy(economy)
                        menuVM.refreshTips(for: true)
                    }

                case .game:
                    GameScreen(
                        router: router,
                        viewModel: gameVM
                    )

                case .settings:
                    SettingsScreen(
                        router: router,
                        viewModel: settingsVM
                    )
                }
            }
            .preferredColorScheme(.light)
            .onAppear {
                HapticsEngine.shared.prepare()
                if progress.hasAcceptedConsent() {
                    menuVM.bindEconomy(economy)
                    menuVM.refreshTips(for: true)
                }
            }
        }
    }
}
