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

    private var currentLanguage: AppLanguage {
        if let saved = SharedDefaults.store.string(forKey: SharedDefaults.Keys.phonePrimaryLanguage),
           let parsed = AppLanguage(rawValue: saved) {
            return parsed
        }
        return .da
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PlaceholderTimelineProvider()) { _ in
            Text(FitOnyCopy.appName.value(for: currentLanguage))
        }
        .configurationDisplayName(FitOnyCopy.widgetLiveActivityTitle.value(for: currentLanguage))
        .description(FitOnyCopy.widgetLiveActivityDescription.value(for: currentLanguage))
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
