import SwiftUI
import FitOnyCore

@main
struct FitOnyApp: App {
    @State private var selectedTheme: AppTheme = .fitOnyPink
    @State private var languageState = LanguageState()

    var body: some Scene {
        WindowGroup {
            RootTabContainerView(theme: $selectedTheme)
                .environment(languageState)
                .environment(\.locale, Locale(identifier: languageState.effectiveLanguage.localeIdentifier))
        }
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
