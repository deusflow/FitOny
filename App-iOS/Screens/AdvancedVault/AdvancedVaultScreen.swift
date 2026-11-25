import SwiftUI
import FitOnyCore

struct AdvancedVaultScreen: View {
    @Environment(LanguageState.self) private var language

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                language.text(FitOnyCopy.advancedTitle),
                systemImage: "lock.shield.fill",
                description: Text(language.text(FitOnyCopy.advancedSubtitle))
            )
            .navigationTitle(language.text(FitOnyCopy.tabAdvanced))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    LanguageQuickSwitchButton()
                }
            }
        }
    }
}
