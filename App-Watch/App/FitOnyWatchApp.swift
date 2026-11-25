import SwiftUI
import FitOnyCore

@main
struct FitOnyWatchApp: App {
    @State private var languageState = WatchLanguageState()

    var body: some Scene {
        WindowGroup {
            WatchHomeScreen()
                .environment(languageState)
                .environment(\.locale, Locale(identifier: languageState.currentLanguage.localeIdentifier))
        }
    }
}
