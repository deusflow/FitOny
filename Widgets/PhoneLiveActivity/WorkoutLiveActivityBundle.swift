import SwiftUI
import WidgetKit
import FitOnyCore

@main
struct WorkoutLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        EmptyWorkoutWidget()
    }
}

struct EmptyWorkoutWidget: Widget {
    let kind = "com.deusflow.fitony.liveactivity.placeholder"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PlaceholderTimelineProvider()) { _ in
            Text("FitOny")
        }
        .configurationDisplayName("Активная тренировка")
        .description("Таймер отдыха и следующий подход на заблокированном экране.")
    }
}

struct PlaceholderEntry: TimelineEntry {
    let date: Date
}

struct PlaceholderTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> PlaceholderEntry {
        PlaceholderEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (PlaceholderEntry) -> Void) {
        completion(PlaceholderEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PlaceholderEntry>) -> Void) {
        completion(Timeline(entries: [PlaceholderEntry(date: .now)], policy: .never))
    }
}
