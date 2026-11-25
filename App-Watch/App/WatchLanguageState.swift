import Foundation
import Observation
import FitOnyCore

/// Мгновенное переключение DA ⇄ RU на Apple Watch с автоматической синхронизацией с iPhone.
@MainActor
@Observable
final class WatchLanguageState {
    private static let key = "fitony.watch.primaryLanguage"

    var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: Self.key)
        }
    }

    init() {
        if let saved = UserDefaults.standard.string(forKey: Self.key),
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
