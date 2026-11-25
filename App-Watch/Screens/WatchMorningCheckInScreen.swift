import SwiftUI
import FitOnyCore

struct WatchMorningCheckInScreen: View {
    @Environment(WatchLanguageState.self) private var language

    var body: some View {
        VStack(spacing: 6) {
            Text(language.text(FitOnyCopy.watchMorningCheckIn))
                .font(.caption)
        }
    }
}
