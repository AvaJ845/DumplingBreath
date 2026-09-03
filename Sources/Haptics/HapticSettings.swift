import Foundation
import Observation

/// User-facing haptic preferences: three values, nothing else. No behaviour —
/// `HapticChoreographer` reads this every frame; a settings screen binds to it.
///
/// Persisted to `UserDefaults` (`@AppStorage` reads the same keys). Stable keys —
/// do not rename:
///
///   `haptics.enabled`              `Bool`   master switch                 (default `true`)
///   `haptics.intensityScale`       `Double` 0…1 multiplier on every cue  (default `1`)
///   `haptics.audioFallbackEnabled` `Bool`   soft tone on devices with no
///                                           Taptic Engine                (default `false` — clean silence)
@MainActor
@Observable
public final class HapticSettings {

    /// The instance the app and (later) the settings screen share.
    public static let shared = HapticSettings()

    /// Master switch. Off = no haptics, no audio, nothing.
    public var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Keys.enabled) }
    }

    /// 0 = off, 1 = full strength. A single knob for people who find the default
    /// too strong or too faint. Clamped to 0…1 on write.
    public var intensityScale: Double {
        didSet {
            let clamped = min(max(intensityScale, 0), 1)
            if clamped != intensityScale { intensityScale = clamped }
            else { defaults.set(clamped, forKey: Keys.intensityScale) }
        }
    }

    /// On devices with no Taptic Engine (every iPad, older iPhones), optionally
    /// carry the breath with a soft synthesised tone instead of silence.
    /// Default off: sound is intrusive in the exact moments this app is for, and
    /// silence is never a bug. A settings screen should surface this prominently
    /// when `CHHapticEngine…supportsHaptics` is false.
    public var audioFallbackEnabled: Bool {
        didSet { defaults.set(audioFallbackEnabled, forKey: Keys.audioFallback) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isEnabled = defaults.object(forKey: Keys.enabled) as? Bool ?? true
        self.intensityScale = defaults.object(forKey: Keys.intensityScale) as? Double ?? 1
        self.audioFallbackEnabled = defaults.object(forKey: Keys.audioFallback) as? Bool ?? false
    }

    private enum Keys {
        static let enabled = "haptics.enabled"
        static let intensityScale = "haptics.intensityScale"
        static let audioFallback = "haptics.audioFallbackEnabled"
    }
}
