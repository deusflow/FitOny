import Foundation
import Observation
import FitOnyCore

/// Реактивное состояние языка приложения на iPhone с мгновенным переключением и режимом «подсмотреть по-русски».
@MainActor
@Observable
final class LanguageState {
    var primaryLanguage: AppLanguage {
        didSet {
            SharedDefaults.store.set(primaryLanguage.rawValue, forKey: SharedDefaults.Keys.phonePrimaryLanguage)
        }
    }

    var showSecondaryRussianHint: Bool {
        didSet {
            SharedDefaults.store.set(showSecondaryRussianHint, forKey: SharedDefaults.Keys.showSecondaryRussianHint)
        }
    }

    /// Временный режим удержания кнопки: показывает русский, пока палец на переключателе.
    var isPeekingRussian = false

    var effectiveLanguage: AppLanguage {
        isPeekingRussian ? .ru : primaryLanguage
    }

    init() {
        let store = SharedDefaults.store
        if let saved = store.string(forKey: SharedDefaults.Keys.phonePrimaryLanguage),
           let parsed = AppLanguage(rawValue: saved) {
            self.primaryLanguage = parsed
        } else {
            self.primaryLanguage = .da
        }

        if store.object(forKey: SharedDefaults.Keys.showSecondaryRussianHint) != nil {
            self.showSecondaryRussianHint = store.bool(forKey: SharedDefaults.Keys.showSecondaryRussianHint)
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
