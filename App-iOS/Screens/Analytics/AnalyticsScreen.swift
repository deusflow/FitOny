import SwiftUI
import FitOnyCore

struct AnalyticsScreen: View {
    @Environment(LanguageState.self) private var language

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                language.text(FitOnyCopy.analyticsTitle),
                systemImage: "chart.xyaxis.line",
                description: Text(language.text(FitOnyCopy.analyticsSubtitle))
            )
            .navigationTitle(language.text(FitOnyCopy.tabVolume))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    LanguageQuickSwitchButton()
                }
            }
        }
    }
}
