import Foundation
import Observation

/// Whether the person has opted into Health logging. Two switches, both OFF
/// until turned on in the app's Privacy screen. Backed by `UserDefaults` — no
/// server, no analytics, nothing default-on. (North Star §1.)
///
/// Agent 1 owns the Privacy screen UI that binds to this. Suggested copy lives
/// in `docs/PRIVACY.md`.
@Observable
@MainActor
public final class HealthConsent {

    public static let shared = HealthConsent()

    private let defaults: UserDefaults
    private enum Key {
        static let mindful = "health.logMindfulMinutes"
        static let stateOfMind = "health.logStateOfMind"
    }

    /// Log a finished session as Mindful Minutes in the Health app.
    public var logMindfulMinutes: Bool {
        didSet { defaults.set(logMindfulMinutes, forKey: Key.mindful) }
    }

    /// Also write an iOS 18 State of Mind entry ("a moment of calm").
    public var logStateOfMind: Bool {
        didSet { defaults.set(logStateOfMind, forKey: Key.stateOfMind) }
    }

    public var anyEnabled: Bool { logMindfulMinutes || logStateOfMind }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.logMindfulMinutes = defaults.bool(forKey: Key.mindful)   // false unless set
        self.logStateOfMind = defaults.bool(forKey: Key.stateOfMind)
    }
}
