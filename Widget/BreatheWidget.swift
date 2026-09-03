import SwiftUI
import WidgetKit

/// A calm "breathe" prompt for the Lock Screen (circular / rectangular) and the
/// Home Screen (small). It is intentionally static — one entry, reload policy
/// `.never`. No countdown, no animation churn, nothing that costs a wake-up.
/// The whole tile is a tap target that deep-links into a session.
struct BreatheWidget: Widget {
    let kind = "DumplingBreathBreatheWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BreatheProvider()) { entry in
            BreatheWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(SessionRequestStore.deepLink(patternID: nil))
        }
        .configurationDisplayName("Breathe")
        .description("One tap to breathe with the dumpling.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .systemSmall,
        ])
    }
}

struct BreatheEntry: TimelineEntry {
    let date: Date
}

struct BreatheProvider: TimelineProvider {
    func placeholder(in context: Context) -> BreatheEntry {
        BreatheEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (BreatheEntry) -> Void) {
        completion(BreatheEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BreatheEntry>) -> Void) {
        // Nothing changes over time. Hand back one entry and never ask again.
        completion(Timeline(entries: [BreatheEntry(date: .now)], policy: .never))
    }
}
