import Combine
import Foundation

final class SettingsViewModel: ObservableObject {
    @Published var hapticsEnabled: Bool
    @Published var reducedMotion: Bool
    @Published var preferredGridSizeIndex: Int
    @Published var privacyUrlString: String

    @Published private(set) var statusText: String = ""
    @Published private(set) var statusIsError: Bool = false

    private let progress: ProgressStore
    private let defaults: UserDefaults
    private let keyPrefix: String

    private var bag = Set<AnyCancellable>()

    init(progress: ProgressStore, defaults: UserDefaults = .standard, keyPrefix: String = "chillrd.farmroad.settings") {
        self.progress = progress
        self.defaults = defaults
        self.keyPrefix = keyPrefix

        let hKey = "\(keyPrefix).hapticsEnabled"
        let mKey = "\(keyPrefix).reducedMotion"
        let gKey = "\(keyPrefix).gridSizeIndex"
        let pKey = "\(keyPrefix).privacyUrl"

        self.hapticsEnabled = defaults.object(forKey: hKey) as? Bool ?? true
        self.reducedMotion = defaults.object(forKey: mKey) as? Bool ?? false
        self.preferredGridSizeIndex = defaults.object(forKey: gKey) as? Int ?? 0
        self.privacyUrlString = defaults.string(forKey: pKey) ?? "https://www.freeprivacypolicy.com/live/124d2bb4-e97a-4e9c-a0c2-744483a58ac9"

        wirePersistence(hKey: hKey, mKey: mKey, gKey: gKey, pKey: pKey)
    }

    func gridSizeOptions() -> [String] {
        ["5×5", "6×6", "7×7"]
    }

    func gridSizeValue() -> (rows: Int, columns: Int) {
        switch preferredGridSizeIndex {
        case 1: return (6, 6)
        case 2: return (7, 7)
        default: return (5, 5)
        }
    }

    func privacyURL() -> URL? {
        URL(string: privacyUrlString.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func resetProgressKeepConsent() {
        let g = gridSizeValue()
        progress.reset(rows: g.rows, columns: g.columns, keepConsent: true)
        setStatus("Progress reset.", isError: false)
    }

    func validatePrivacyUrl() -> Bool {
        guard let url = privacyURL() else {
            setStatus("Privacy URL is invalid.", isError: true)
            return false
        }
        let scheme = (url.scheme ?? "").lowercased()
        if scheme != "https" && scheme != "http" {
            setStatus("Privacy URL must be http/https.", isError: true)
            return false
        }
        setStatus("Privacy URL saved.", isError: false)
        return true
    }

    private func wirePersistence(hKey: String, mKey: String, gKey: String, pKey: String) {
        $hapticsEnabled
            .dropFirst()
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.defaults.set(value, forKey: hKey)
            }
            .store(in: &bag)

        $reducedMotion
            .dropFirst()
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.defaults.set(value, forKey: mKey)
            }
            .store(in: &bag)

        $preferredGridSizeIndex
            .dropFirst()
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.defaults.set(value, forKey: gKey)
            }
            .store(in: &bag)

        $privacyUrlString
            .dropFirst()
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.defaults.set(value, forKey: pKey)
            }
            .store(in: &bag)
    }

    private func setStatus(_ text: String, isError: Bool) {
        statusText = text
        statusIsError = isError
    }
}
