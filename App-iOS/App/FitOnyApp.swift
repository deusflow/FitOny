import SwiftUI
import SwiftData
import FitOnyCore

@main
struct FitOnyApp: App {
    @Environment(\.scenePhase) private var scenePhase

    private let persistence = PersistenceController.shared

    @State private var selectedTheme: AppTheme
    @State private var languageState = LanguageState()
    @State private var vaultService = BiometricVaultService()

    init() {
        let initialTheme = PersistenceController.shared.loadInitialTheme()
        _selectedTheme = State(initialValue: initialTheme)
    }

    var body: some Scene {
        WindowGroup {
            RootTabContainerView(theme: $selectedTheme)
                .environment(languageState)
                .environment(vaultService)
                .environment(\.locale, Locale(identifier: languageState.effectiveLanguage.localeIdentifier))
                .onChange(of: selectedTheme) { _, newValue in
                    persistence.saveSelectedTheme(newValue)
                }
                .onChange(of: languageState.primaryLanguage) { _, newValue in
                    persistence.syncLanguageSettings(
                        primary: newValue,
                        showRussianHint: languageState.showSecondaryRussianHint
                    )
                }
                .onChange(of: languageState.showSecondaryRussianHint) { _, newValue in
                    persistence.syncLanguageSettings(
                        primary: languageState.primaryLanguage,
                        showRussianHint: newValue
                    )
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase != .active {
                        vaultService.lockImmediately()
                    }
                }
        }
        .modelContainer(persistence.container)
    }
}

struct RootTabContainerView: View {
    @Binding var theme: AppTheme
    @Environment(LanguageState.self) private var language

    var body: some View {
        TabView {
            TodayScreen()
                .tabItem {
                    Label(language.text(FitOnyCopy.tabToday), systemImage: "bolt.heart.fill")
                }

            ProgramsScreen()
                .tabItem {
                    Label(language.text(FitOnyCopy.tabCycles), systemImage: "calendar.badge.clock")
                }

            AnalyticsScreen()
                .tabItem {
                    Label(language.text(FitOnyCopy.tabVolume), systemImage: "chart.bar.xaxis")
                }

            AdvancedVaultScreen()
                .tabItem {
                    Label(language.text(FitOnyCopy.tabAdvanced), systemImage: "faceid")
                }

            SettingsScreen(selectedTheme: $theme)
                .tabItem {
                    Label(language.text(FitOnyCopy.tabSettings), systemImage: "slider.horizontal.3")
                }
        }
    }
}
