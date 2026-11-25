import Foundation
import Observation
import FitOnyCore

/// Реактивное состояние языка приложения на iPhone с мгновенным переключением и режимом «подсмотреть по-русски».
@MainActor
@Observable
final class LanguageState {
    private enum Keys {
        static let primaryLanguage = "fitony.primaryLanguage"
        static let showRussianHint = "fitony.showSecondaryRussianHint"
    }

    var primaryLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(primaryLanguage.rawValue, forKey: Keys.primaryLanguage)
        }
    }

    var showSecondaryRussianHint: Bool {
        didSet {
            UserDefaults.standard.set(showSecondaryRussianHint, forKey: Keys.showRussianHint)
        }
    }

    /// Временный режим удержания кнопки: показывает русский, пока палец на переключателе.
    var isPeekingRussian = false

    var effectiveLanguage: AppLanguage {
        isPeekingRussian ? .ru : primaryLanguage
    }

    init() {
        if let saved = UserDefaults.standard.string(forKey: Keys.primaryLanguage),
           let parsed = AppLanguage(rawValue: saved) {
            self.primaryLanguage = parsed
        } else {
            self.primaryLanguage = .da
        }

        if UserDefaults.standard.object(forKey: Keys.showRussianHint) != nil {
            self.showSecondaryRussianHint = UserDefaults.standard.bool(forKey: Keys.showRussianHint)
        } else {
            self.showSecondaryRussianHint = true
        }
    }

    func toggle() {
        primaryLanguage = primaryLanguage.toggled()
    }

    func text(_ copy: LocalizedCopy) -> String {
        copy.value(for: effectiveLanguage)
    }

    func text(_ bilingual: BilingualText) -> String {
        bilingual.resolved(for: effectiveLanguage)
    }
}
