import SwiftUI
import FitOnyCore

struct ProgramsScreen: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Программы и циклы",
                systemImage: "calendar",
                description: Text("Макроцикл, 6-недельный мезоцикл и модули тренировок")
            )
            .navigationTitle("Циклы")
        }
    }
}
