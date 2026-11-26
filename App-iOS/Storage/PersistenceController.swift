import Foundation
import SwiftData
import FitOnyCore
import FitOnyStorage

/// Координатор локального хранения (SwiftData + автоснимки перед миграцией + сидинг каталога PureGym).
@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    let store: FitOnyStore
    let startupErrorDescription: String?

    var container: ModelContainer {
        store.container
    }

    private init() {
        do {
            self.store = try FitOnyStore.makePersistentStore()
            self.startupErrorDescription = nil
        } catch {
            // Защита от падения интерфейса при повреждённом диске: поднимаем изолированный резерв в памяти.
            do {
                self.store = try FitOnyStore.makeInMemoryStore()
                self.startupErrorDescription = error.localizedDescription
            } catch {
                fatalError("Unable to initialize FitOny ModelContainer: \(error)")
            }
        }
    }

    func loadInitialTheme() -> AppTheme {
        guard let prefs = try? store.fetchPreferences(),
              let theme = AppTheme(rawValue: prefs.selectedThemeID) else {
            return .fitOnyPink
        }
        return theme
    }

    func saveSelectedTheme(_ theme: AppTheme) {
        _ = try? store.updatePreferences { prefs in
            prefs.selectedThemeID = theme.rawValue
        }
    }

    func syncLanguageSettings(primary: AppLanguage, showRussianHint: Bool) {
        _ = try? store.updatePreferences { prefs in
            prefs.primaryLanguage = primary
            prefs.showSecondaryRussianHint = showRussianHint
        }
    }
}
