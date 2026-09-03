import AppIntents

/// "Start Dumpling Breath" — the one verb this app exposes to the system.
///
/// Usable from Shortcuts, "Hey Siri, start Dumpling Breath", the Control Center
/// control, and a widget. It opens the app straight into a held-open session
/// with the chosen pattern; there is no background/headless mode, because the
/// whole point is the thing under your thumb.
struct StartDumplingBreathIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Dumpling Breath"

    static let description = IntentDescription(
        "Open Dumpling Breath and begin a slow breathing session.",
        categoryName: "Breathing",
        searchKeywords: ["breathe", "calm", "dumpling", "relax", "haptic"]
    )

    /// We must open the app: the session lives in your hand, not in a daemon.
    static let openAppWhenRun: Bool = true

    @Parameter(
        title: "Pattern",
        description: "Which breathing rhythm to start with.",
        default: .coherent
    )
    var pattern: BreathPatternChoice

    static var parameterSummary: some ParameterSummary {
        Summary("Start breathing with the \(\.$pattern) pattern")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        SessionRequestStore.request(patternID: pattern.patternID)
        return .result()
    }
}
