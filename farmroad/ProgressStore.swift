import Combine
import Foundation

final class ProgressStore: ObservableObject {
    struct SaveBlob: Codable, Equatable {
        var schemaVersion: Int
        var savedAt: TimeInterval
        var hasAcceptedConsent: Bool
        var economy: PlayerEconomy
        var grid: FarmGridState
        var phase: GamePhase

        static func fresh(rows: Int, columns: Int) -> SaveBlob {
            SaveBlob(
                schemaVersion: 1,
                savedAt: Date().timeIntervalSince1970,
                hasAcceptedConsent: false,
                economy: .initial,
                grid: .initial(rows: rows, columns: columns),
                phase: .idle
            )
        }
    }

    @Published private(set) var blob: SaveBlob

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let defaults: UserDefaults
    private let storageKey: String

    private var bag = Set<AnyCancellable>()
    private var pendingSaveBag = Set<AnyCancellable>()

    init(appId: String = "chillrd.farmroad", rows: Int = 5, columns: Int = 5, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.storageKey = "progress.\(appId).v1"
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.outputFormatting = [.sortedKeys]
        self.blob = ProgressStore.loadOrFresh(
            defaults: defaults,
            key: "progress.\(appId).v1",
            decoder: JSONDecoder(),
            rows: rows,
            columns: columns
        )
        wireAutoSave()
    }

    func hasAcceptedConsent() -> Bool {
        blob.hasAcceptedConsent
    }

    func setConsentAccepted() {
        guard blob.hasAcceptedConsent == false else { return }
        blob.hasAcceptedConsent = true
        blob.savedAt = Date().timeIntervalSince1970
        saveNow()
    }

    func setEconomy(_ economy: PlayerEconomy) {
        blob.economy = economy
        blob.savedAt = Date().timeIntervalSince1970
        scheduleSaveSoon()
    }

    func setGrid(_ grid: FarmGridState) {
        blob.grid = grid
        blob.savedAt = Date().timeIntervalSince1970
        scheduleSaveSoon()
    }

    func setPhase(_ phase: GamePhase) {
        blob.phase = phase
        blob.savedAt = Date().timeIntervalSince1970
        scheduleSaveSoon()
    }

    func replaceAll(economy: PlayerEconomy, grid: FarmGridState, phase: GamePhase) {
        blob.economy = economy
        blob.grid = grid
        blob.phase = phase
        blob.savedAt = Date().timeIntervalSince1970
        scheduleSaveSoon()
    }

    func reset(rows: Int = 5, columns: Int = 5, keepConsent: Bool = true) {
        let accepted = keepConsent ? blob.hasAcceptedConsent : false
        var fresh = SaveBlob.fresh(rows: rows, columns: columns)
        fresh.hasAcceptedConsent = accepted
        blob = fresh
        saveNow()
    }

    func saveNow() {
        pendingSaveBag.removeAll()
        do {
            let data = try encoder.encode(blob)
            defaults.set(data, forKey: storageKey)
        } catch {
            defaults.removeObject(forKey: storageKey)
        }
    }

    func reload(rows: Int = 5, columns: Int = 5) {
        let loaded = ProgressStore.loadOrFresh(
            defaults: defaults,
            key: storageKey,
            decoder: decoder,
            rows: rows,
            columns: columns
        )
        blob = loaded
    }

    private func scheduleSaveSoon() {
        pendingSaveBag.removeAll()
        Just(())
            .delay(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveNow()
            }
            .store(in: &pendingSaveBag)
    }

    private func wireAutoSave() {
        $blob
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveNow()
            }
            .store(in: &bag)
    }

    private static func loadOrFresh(
        defaults: UserDefaults,
        key: String,
        decoder: JSONDecoder,
        rows: Int,
        columns: Int
    ) -> SaveBlob {
        guard let data = defaults.data(forKey: key) else {
            return SaveBlob.fresh(rows: rows, columns: columns)
        }
        do {
            let decoded = try decoder.decode(SaveBlob.self, from: data)
            if decoded.schemaVersion != 1 {
                return SaveBlob.fresh(rows: rows, columns: columns)
            }
            if decoded.grid.rows <= 0 || decoded.grid.columns <= 0 || decoded.grid.tiles.count != decoded.grid.rows * decoded.grid.columns {
                return SaveBlob.fresh(rows: rows, columns: columns)
            }
            return decoded
        } catch {
            return SaveBlob.fresh(rows: rows, columns: columns)
        }
    }
}
