import Foundation

/// The timing of a single breath, in seconds. A pure value type — the entire
/// "what kind of breathing is this" decision lives here and nowhere else.
///
/// Agent 2 (Haptics & breathing science) owns the bundled catalogue below and
/// its clinical rationale.
public struct BreathingPattern: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let detail: String
    public let inhale: Double
    public let holdIn: Double
    public let exhale: Double
    public let holdOut: Double

    public init(id: String, name: String, detail: String,
                inhale: Double, holdIn: Double, exhale: Double, holdOut: Double) {
        self.id = id
        self.name = name
        self.detail = detail
        self.inhale = inhale
        self.holdIn = holdIn
        self.exhale = exhale
        self.holdOut = holdOut
    }

    public var cycleDuration: Double { inhale + holdIn + exhale + holdOut }

    public func duration(of phase: BreathPhase) -> Double {
        switch phase {
        case .inhale:  return inhale
        case .holdIn:  return holdIn
        case .exhale:  return exhale
        case .holdOut: return holdOut
        }
    }
}

extension BreathingPattern {
    /// ~5.5 s in / 5.5 s out — "resonance" / coherent breathing, the
    /// "just settle me down" default.
    public static let coherent = BreathingPattern(
        id: "coherent", name: "Coherent", detail: "5.5 in · 5.5 out",
        inhale: 5.5, holdIn: 0, exhale: 5.5, holdOut: 0)

    /// 4 · 4 · 4 · 4 — box breathing, steadying / focus.
    public static let box = BreathingPattern(
        id: "box", name: "Box", detail: "4 · 4 · 4 · 4",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4)

    /// 4 in · 7 hold · 8 out — wind-down before sleep.
    public static let fourSevenEight = BreathingPattern(
        id: "478", name: "4·7·8", detail: "4 in · 7 hold · 8 out",
        inhale: 4, holdIn: 7, exhale: 8, holdOut: 0)

    public static let bundled: [BreathingPattern] = [.coherent, .box, .fourSevenEight]
}
