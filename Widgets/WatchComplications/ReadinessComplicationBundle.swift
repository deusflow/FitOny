import SwiftUI
import WidgetKit
import FitOnyCore

@main
struct ReadinessComplicationBundle: WidgetBundle {
    var body: some Widget {
        ReadinessComplicationWidget()
    }
}

struct ReadinessComplicationWidget: Widget {
    let kind = "com.deusflow.fitony.watch.readiness"

    private var currentLanguage: AppLanguage {
        if let saved = SharedDefaults.store.string(forKey: SharedDefaults.Keys.watchPrimaryLanguage),
           let parsed = AppLanguage(rawValue: saved) {
            return parsed
        }
        return .da
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchReadinessProvider()) { entry in
            Text("\(entry.score)")
                .font(.system(.headline, design: .rounded).monospacedDigit())
        }
        .configurationDisplayName(FitOnyCopy.widgetReadinessTitle.value(for: currentLanguage))
        .description(FitOnyCopy.widgetReadinessDescription.value(for: currentLanguage))
    }
}

struct WatchReadinessEntry: TimelineEntry {
    let date: Date
    let score: Int
}

struct WatchReadinessProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchReadinessEntry {
        WatchReadinessEntry(date: .now, score: 82)
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchReadinessEntry) -> Void) {
        completion(WatchReadinessEntry(date: .now, score: 82))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchReadinessEntry>) -> Void) {
        completion(Timeline(entries: [WatchReadinessEntry(date: .now, score: 82)], policy: .after(.now.addingTimeInterval(3600))))
    }
}
