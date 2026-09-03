import AppIntents
import DumplingBreathCore

/// The breathing patterns a person can pick from Shortcuts, Siri, the Control
/// Center control, or a widget. A thin `AppEnum` mirror of the bundled
/// `BreathingPattern` catalogue — the catalogue stays the single source of
/// truth (Agent 2 owns it); this only exposes it to the intents system.
enum BreathPatternChoice: String, AppEnum, CaseIterable {
    case coherent
    case box
    case fourSevenEight = "478"

    /// "Let the app decide" — resolves to whatever the app's default is.
    /// Chosen so a stressed person never has to answer "which pattern?".
    static var defaultChoice: BreathPatternChoice { .coherent }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Breathing Pattern")
    }

    static var caseDisplayRepresentations: [BreathPatternChoice: DisplayRepresentation] {
        [
            .coherent: DisplayRepresentation(title: "Coherent", subtitle: "5.5 in · 5.5 out"),
            .box: DisplayRepresentation(title: "Box", subtitle: "4 · 4 · 4 · 4"),
            .fourSevenEight: DisplayRepresentation(title: "4·7·8", subtitle: "4 in · 7 hold · 8 out"),
        ]
    }

    /// The `BreathingPattern.id` this choice maps to.
    var patternID: String { rawValue }

    var pattern: BreathingPattern {
        BreathingPattern.bundled.first { $0.id == patternID } ?? .coherent
    }
}
