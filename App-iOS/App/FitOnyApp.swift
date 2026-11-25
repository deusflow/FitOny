import SwiftUI
import FitOnyCore

@main
struct FitOnyApp: App {
    @State private var selectedTheme: AppTheme = .fitOnyPink

    var body: some Scene {
        WindowGroup {
            RootTabContainerView(theme: $selectedTheme)
        }
    }
}

struct RootTabContainerView: View {
    @Binding var theme: AppTheme

    var body: some View {
        TabView {
            TodayScreen()
                .tabItem {
                    Label("Сегодня", systemImage: "bolt.heart.fill")
                }

            ProgramsScreen()
                .tabItem {
                    Label("Циклы", systemImage: "calendar.badge.clock")
                }

            AnalyticsScreen()
                .tabItem {
                    Label("Объём", systemImage: "chart.bar.xaxis")
                }

            AdvancedVaultScreen()
                .tabItem {
                    Label("Advanced", systemImage: "faceid")
                }

            SettingsScreen(selectedTheme: $theme)
                .tabItem {
                    Label("Настройки", systemImage: "slider.horizontal.3")
                }
        }
    }
}
