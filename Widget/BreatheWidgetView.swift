import SwiftUI
import WidgetKit

/// The face of the widget, per family. Grayscale-first: the prompt reads with
/// no colour, so it survives tinted Lock Screens and colour-blind users alike.
struct BreatheWidgetView: View {
    var entry: BreatheEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                WidgetDumpling(openness: 0.62)
                    .padding(6)
            }
            .accessibilityLabel("Breathe with Dumpling Breath")

        case .accessoryRectangular:
            HStack(spacing: 10) {
                WidgetDumpling(openness: 0.62)
                    .frame(width: 26, height: 26)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Breathe").font(.headline)
                    Text("one slow one").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Breathe with Dumpling Breath")

        default: // .systemSmall
            VStack(spacing: 10) {
                WidgetDumpling(openness: 0.68)
                    .frame(width: 62, height: 62)
                Text("Breathe")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Breathe with Dumpling Breath")
        }
    }
}

/// A dumpling reduced to a widget glyph: a plump, faintly-pleated blob. Pure
/// geometry so it stays crisp at 20 pt on a Lock Screen and 60 pt on the Home
/// Screen, and weighs nothing.
struct WidgetDumpling: View {
    /// 0 = squat and empty, 1 = round and full.
    var openness: Double

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let o = min(max(openness, 0), 1)
            let squash = 0.78 + 0.22 * o
            RoundedRectangle(cornerRadius: side * 0.5, style: .continuous)
                .fill(.primary.opacity(0.9))
                .frame(width: side, height: side * squash)
                .overlay(alignment: .top) {
                    // crimp
                    Capsule()
                        .fill(.background.opacity(0.35))
                        .frame(width: side * 0.42, height: side * 0.10)
                        .offset(y: side * 0.06)
                }
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

#Preview("Circular", as: .accessoryCircular) {
    BreatheWidget()
} timeline: {
    BreatheEntry(date: .now)
}

#Preview("Small", as: .systemSmall) {
    BreatheWidget()
} timeline: {
    BreatheEntry(date: .now)
}
