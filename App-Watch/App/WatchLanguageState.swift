import Foundation
import Observation
import FitOnyCore

/// Мгновенное переключение DA ⇄ RU на Apple Watch с автоматической синхронизацией с iPhone.
@MainActor
@Observable
final class WatchLanguageState {
    var currentLanguage: AppLanguage {
        didSet {
            SharedDefaults.store.set(currentLanguage.rawValue, forKey: SharedDefaults.Keys.watchPrimaryLanguage)
        }
    }

    init() {
        if let saved = SharedDefaults.store.string(forKey: SharedDefaults.Keys.watchPrimaryLanguage),
           let parsed = AppLanguage(rawValue: saved) {
            self.currentLanguage = parsed
        } else {
            self.currentLanguage = .da
        }
    }

    func toggle() {
        currentLanguage = currentLanguage.toggled()
    }

    func text(_ copy: LocalizedCopy) -> String {
        copy.value(for: currentLanguage)
    }
}
