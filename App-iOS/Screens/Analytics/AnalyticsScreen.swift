import SwiftUI
import FitOnyCore

struct AnalyticsScreen: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Объём и прогрессия силы",
                systemImage: "chart.xyaxis.line",
                description: Text("Зоны MEV / MAV / MRV по 14 мышцам и кривые e1RM")
            )
            .navigationTitle("Аналитика")
        }
    }
}
