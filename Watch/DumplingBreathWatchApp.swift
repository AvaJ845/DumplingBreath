import SwiftUI

/// Standalone watchOS app — no iPhone required. Raise your wrist, tap the
/// dumpling, breathe. The Digital Crown sets the pace; the Taptic Engine marks
/// every turn of the breath so it works with the screen off.
@main
struct DumplingBreathWatchApp: App {
    var body: some Scene {
        WindowGroup {
            CrownBreathView()
        }
    }
}
