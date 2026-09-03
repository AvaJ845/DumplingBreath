import Foundation

/// The pure math of a breathing session: given a `BreathingPattern` and an
/// elapsed time `t`, it produces the current phase, the progress through that
/// phase, and — the important one — a single continuous `openness` signal that
/// the visuals and the haptics both consume.
///
/// No timers, no UIKit, no side effects. Fully unit-tested.
public struct BreathClock: Equatable, Sendable {
    public var pattern: BreathingPattern

    public init(pattern: BreathingPattern) {
        self.pattern = pattern
    }

    public struct Sample: Equatable, Sendable {
        public var phase: BreathPhase
        public var phaseProgress: Double   // 0…1 within the current phase
        public var openness: Double        // 0 = deflated, 1 = inflated, eased
        public var completedCycles: Int
    }

    public func sample(at t: Double) -> Sample {
        let cycle = max(pattern.cycleDuration, 0.001)
        let clamped = max(t, 0)
        let completed = Int(clamped / cycle)
        let within = clamped.truncatingRemainder(dividingBy: cycle)
        let (phase, progress) = resolve(within: within)
        let openness = Self.ease(
            from: Self.startOpenness(of: phase),
            to: phase.targetOpenness,
            t: progress)
        return Sample(phase: phase,
                      phaseProgress: progress,
                      openness: openness,
                      completedCycles: completed)
    }

    /// Which phase are we in, `within` seconds into the cycle, and how far through it.
    public func resolve(within: Double) -> (BreathPhase, Double) {
        var cursor = within
        for phase in [BreathPhase.inhale, .holdIn, .exhale, .holdOut] {
            let d = pattern.duration(of: phase)
            if d <= 0 { continue }
            if cursor < d { return (phase, cursor / d) }
            cursor -= d
        }
        return (.exhale, 1)
    }

    public static func startOpenness(of phase: BreathPhase) -> Double {
        switch phase {
        case .inhale:  return 0
        case .holdIn:  return 1
        case .exhale:  return 1
        case .holdOut: return 0
        }
    }

    /// Smoothstep. No linear ramps — nothing about a breath snaps.
    public static func ease(from a: Double, to b: Double, t: Double) -> Double {
        let x = min(max(t, 0), 1)
        let s = x * x * (3 - 2 * x)
        return a + (b - a) * s
    }
}
