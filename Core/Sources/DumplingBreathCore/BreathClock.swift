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
        public var velocity: Double        // d(openness)/dt, openness-per-second
        public var completedCycles: Int

        public init(phase: BreathPhase, phaseProgress: Double, openness: Double,
                    velocity: Double, completedCycles: Int) {
            self.phase = phase
            self.phaseProgress = phaseProgress
            self.openness = openness
            self.velocity = velocity
            self.completedCycles = completedCycles
        }
    }

    public func sample(at t: Double) -> Sample {
        let cycle = max(pattern.cycleDuration, 0.001)
        let clamped = max(t, 0)
        let completed = Int(clamped / cycle)
        let within = clamped.truncatingRemainder(dividingBy: cycle)
        let (phase, progress) = resolve(within: within)
        let from = Self.startOpenness(of: phase)
        let to = phase.targetOpenness
        let openness = Self.ease(from: from, to: to, t: progress)
        // Analytic derivative of the smoothstep, so the view/haptics can lead
        // the breath (anticipation, transients at the turn) without differencing
        // frames. Zero during holds (from == to) and at either turn (progress
        // 0 or 1), where 6·x·(1−x) vanishes.
        let d = pattern.duration(of: phase)
        let velocity = d > 0 ? (to - from) * 6 * progress * (1 - progress) / d : 0
        return Sample(phase: phase,
                      phaseProgress: progress,
                      openness: openness,
                      velocity: velocity,
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

    /// A gentle "breathing at rest" oscillation for when no session is running.
    /// Returns a small signed value the idle view adds to a neutral openness so
    /// the dumpling looks alive — not instructional — before it is pressed.
    /// Pure and phase-free; the view owns whether to honour Reduce Motion.
    public static func restWobble(at t: Double,
                                  period: Double = 6,
                                  amplitude: Double = 0.05) -> Double {
        guard period > 0 else { return 0 }
        return amplitude * sin(2 * .pi * t / period)
    }
}
