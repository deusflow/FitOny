import SwiftUI
import FitOnyCore

struct WatchHomeScreen: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                Text("FitOny")
                    .font(.headline)
                Text("Готов к тренировке")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
