import Combine
import Foundation

final class AppRouter: ObservableObject {
    enum Phase: Equatable, Codable {
        case loading
        case consent
        case menu
        case game
        case settings
    }

    @Published var phase: Phase = .loading

    @Published var overlayMessage: String = ""
    @Published var overlayIsError: Bool = false
    @Published var overlayShown: Bool = false

    private var bag = Set<AnyCancellable>()

    func setPhase(_ newPhase: Phase) {
        phase = newPhase
    }

    func goToLoading() {
        phase = .loading
    }

    func goToConsent() {
        phase = .consent
    }

    func goToMenu() {
        phase = .menu
    }

    func goToGame() {
        phase = .game
    }

    func goToSettings() {
        phase = .settings
    }

    func showOverlay(_ text: String, isError: Bool) {
        overlayMessage = text
        overlayIsError = isError
        overlayShown = true

        bag.removeAll()
        Just(())
            .delay(for: .seconds(1.6), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.overlayShown = false
            }
            .store(in: &bag)
    }

    func hideOverlay() {
        overlayShown = false
        bag.removeAll()
    }
}
