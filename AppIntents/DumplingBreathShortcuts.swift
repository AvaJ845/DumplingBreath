import AppIntents

/// The phrases Siri and Shortcuts offer without any setup. Kept to one — a
/// single, honest verb — so the Shortcuts gallery entry reads as calm as the
/// app. (This provider must live in the app target only.)
struct DumplingBreathShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartDumplingBreathIntent(),
            phrases: [
                "Start \(.applicationName)",
                "Begin a breath with \(.applicationName)",
                "Breathe with \(.applicationName)",
            ],
            shortTitle: "Start a breath",
            systemImageName: "wind"
        )
    }

    static var shortcutTileColor: ShortcutTileColor { .lightBlue }
}
