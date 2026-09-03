import SwiftUI
import WidgetKit
import AppIntents

/// A Control Center control (iOS 18+): one button that starts a breath. The
/// value of putting it here is exactly the ROAST's fix — reach it *before*
/// you've fully surfaced from the bad moment, without hunting for an app icon.
@available(iOSApplicationExtension 18.0, *)
struct StartBreathingControl: ControlWidget {
    let kind = "com.avaresearch.dumplingbreath.control.start"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: kind) {
            ControlWidgetButton(action: StartDumplingBreathIntent()) {
                Label("Breathe", systemImage: "wind")
            }
        }
        .displayName("Start Dumpling Breath")
        .description("Open the dumpling and begin a slow breath.")
    }
}
