import SwiftUI
import FitOnyCore

struct WatchActiveSetScreen: View {
    @Environment(WatchLanguageState.self) private var language

    var body: some View {
        VStack(spacing: 6) {
            Text(language.text(FitOnyCopy.watchWorkingSet))
                .font(.caption2)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(language.currentLanguage.shortBadge) {
                    language.toggle()
                }
                .font(.caption2.monospaced().bold())
            }
        }
    }
}
