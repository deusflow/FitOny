import SwiftUI
import FitOnyCore

struct TodayScreen: View {
    @Environment(LanguageState.self) private var language

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                language.text(FitOnyCopy.todayModuleTitle),
                systemImage: "dumbbell.fill",
                description: Text(language.text(FitOnyCopy.todayModuleSubtitle))
            )
            .navigationTitle(language.text(FitOnyCopy.appName))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    LanguageQuickSwitchButton()
                }
            }
        }
    }
}
