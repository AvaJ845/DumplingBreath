import Foundation

/// One segment of a breathing cycle.
public enum BreathPhase: String, CaseIterable, Sendable {
    case inhale
    case holdIn
    case exhale
    case holdOut

    /// Short instruction, shown sparingly and read by VoiceOver.
    public var label: String {
        switch self {
        case .inhale:  return "Breathe in"
        case .holdIn:  return "Hold"
        case .exhale:  return "Breathe out"
        case .holdOut: return "Rest"
        }
    }

    /// The "openness" the dumpling settles toward during this phase.
    /// 0 = fully deflated, 1 = fully inflated.
    public var targetOpenness: Double {
        switch self {
        case .inhale, .holdIn:  return 1
        case .exhale, .holdOut: return 0
        }
    }

    public var isMoving: Bool { self == .inhale || self == .exhale }
}
