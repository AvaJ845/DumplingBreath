import Foundation
import QuartzCore
import Observation
import DumplingBreathCore

/// Runs a live breathing session. Wraps `BreathClock` with a `CADisplayLink`
/// and publishes the current sample every frame. Owns no UI and no haptics —
/// consumers subscribe via `onTick` / `onPhaseChange`.
@Observable
@MainActor
final class BreathingEngine {

    // MARK: Output (observed)

    private(set) var phase: BreathPhase = .inhale
    private(set) var phaseProgress: Double = 0
    private(set) var openness: Double = 0
    private(set) var completedCycles: Int = 0
    private(set) var isRunning = false

    // MARK: Input

    var pattern: BreathingPattern = .coherent {
        didSet { clock.pattern = pattern }
    }

    /// Every frame while running: (openness, phase, phaseProgress).
    @ObservationIgnored var onTick: ((Double, BreathPhase, Double) -> Void)?
    /// Once per phase boundary crossed.
    @ObservationIgnored var onPhaseChange: ((BreathPhase) -> Void)?

    // MARK: Private

    @ObservationIgnored private lazy var clock = BreathClock(pattern: pattern)
    @ObservationIgnored private var link: CADisplayLink?
    @ObservationIgnored private var sessionStart: CFTimeInterval = 0
    @ObservationIgnored private var lastPhase: BreathPhase = .inhale

    func start() {
        guard !isRunning else { return }
        isRunning = true
        sessionStart = CACurrentMediaTime()
        lastPhase = .inhale

        let link = CADisplayLink(target: self, selector: #selector(step))
        // Cap at 60 fps: a calm app has no business driving ProMotion to 120.
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    func stop() {
        isRunning = false
        link?.invalidate()
        link = nil
    }

    @objc private func step() {
        let t = CACurrentMediaTime() - sessionStart
        let s = clock.sample(at: t)

        phase = s.phase
        phaseProgress = s.phaseProgress
        openness = s.openness
        completedCycles = s.completedCycles

        if s.phase != lastPhase {
            lastPhase = s.phase
            onPhaseChange?(s.phase)
        }
        onTick?(s.openness, s.phase, s.phaseProgress)
    }
}
