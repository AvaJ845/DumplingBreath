import SwiftUI
import WidgetKit

/// Everything this extension vends: the "breathe" widgets (Lock Screen + Home
/// Screen) and, on iOS 18+, a Control Center control that starts a session.
@main
struct DumplingBreathWidgetBundle: WidgetBundle {
    var body: some Widget {
        BreatheWidget()
        if #available(iOSApplicationExtension 18.0, *) {
            StartBreathingControl()
        }
    }
}
