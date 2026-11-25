import SwiftUI
import FitOnyCore

struct ProgramsScreen: View {
    @Environment(LanguageState.self) private var language

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                language.text(FitOnyCopy.programsTitle),
                systemImage: "calendar",
                description: Text(language.text(FitOnyCopy.programsSubtitle))
            )
            .navigationTitle(language.text(FitOnyCopy.tabCycles))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    LanguageQuickSwitchButton()
                }
            }
        }
    }
}
