import SwiftUI
import FitOnyCore

struct ActiveWorkoutScreen: View {
    @Environment(LanguageState.self) private var language

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(language.text(FitOnyCopy.activeWorkoutTitle))
                    .font(.headline)
                Spacer()
                LanguageQuickSwitchButton()
            }
            .padding(.horizontal)
            Spacer()
        }
    }
}
