import SwiftUI
import FitOnyCore

struct TodayScreen: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Сегодняшний модуль",
                systemImage: "dumbbell.fill",
                description: Text("Готовность, утренний чек-ин и старт тренировки")
            )
            .navigationTitle("FitOny")
        }
    }
}
