import SwiftUI
import FitOnyCore

struct WatchHomeScreen: View {
    @Environment(WatchLanguageState.self) private var language

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                Text(language.text(FitOnyCopy.appName))
                    .font(.headline)
                Text(language.text(FitOnyCopy.watchReady))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
}
