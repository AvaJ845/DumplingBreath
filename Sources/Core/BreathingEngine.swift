import Foundation
import QuartzCore
import Observation
import DumplingBreathCore

/// Runs a live breathing session. Wraps `BreathClock` with a `CADisplayLink`
/// and publishes the current sample every frame. Owns no UI and no haptics —
/// consumers subscribe via `onTick` / `onPhaseChange`.
///
/// Timing is read from `CACurrentMediaTime()` every frame and fed to the pure
/// clock, so a dropped or late frame never accumulates drift over a long
/// session — openness is always "where the breath actually is now."
///
/// Lifecycle: the owner should call `stop()` (SwiftUI does, from `onDisappear`
/// and `scenePhase`); `deinit` is a backstop that invalidates the link if it
/// didn't. `CADisplayLink` retains its target for life, so it must be
/// invalidated explicitly — the forwarder holds only a `weak` engine so the
/// two never form a permanent cycle.
@Observable
@MainActor
final class BreathingEngine {

    // MARK: Output (observed)

    private(set) var phase: BreathPhase = .inhale
    private(set) var phaseProgress: Double = 0
    private(set) var openness: Double = 0
    /// d(openness)/dt in openness-per-second — lets the view lead the breath
    /// (anticipation, a transient at the turn) without differencing frames.
    private(set) var velocity: Double = 0
    private(set) var completedCycles: Int = 0
    private(set) var isRunning = false

    // MARK: Input

    var pattern: BreathingPattern = .coherent {
        didSet { clock.pattern = pattern }
    }

    /// Every frame while running: (openness, phase, phaseProgress). Invoked on
    /// the main actor.
    @ObservationIgnored var onTick: (@MainActor (Double, BreathPhase, Double) -> Void)?
    /// Once per phase boundary crossed. Invoked on the main actor.
    @ObservationIgnored var onPhaseChange: (@MainActor (BreathPhase) -> Void)?

    // MARK: Private

    @ObservationIgnored private lazy var clock = BreathClock(pattern: pattern)
    @ObservationIgnored private var link: CADisplayLink?
    @ObservationIgnored private var sessionStart: CFTimeInterval = 0
    @ObservationIgnored private var lastPhase: BreathPhase = .inhale

    deinit { link?.invalidate() }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        sessionStart = CACurrentMediaTime()
        lastPhase = .inhale
        phase = .inhale

        link?.invalidate()
        let forwarder = DisplayLinkForwarder(target: self)
        let link = CADisplayLink(target: forwarder, selector: #selector(DisplayLinkForwarder.tick))
        link.preferredFrameRateRange = Self.frameRate(for: .inhale)
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    func stop() {
        isRunning = false
        link?.invalidate()
        link = nil
    }

    // MARK: Frame

    fileprivate func stepFromLink() {
        guard isRunning else { return }
        let t = CACurrentMediaTime() - sessionStart
        let s = clock.sample(at: t)

        phase = s.phase
        phaseProgress = s.phaseProgress
        openness = s.openness
        velocity = s.velocity
        completedCycles = s.completedCycles

        if s.phase != lastPhase {
            lastPhase = s.phase
            link?.preferredFrameRateRange = Self.frameRate(for: s.phase)
            onPhaseChange?(s.phase)
        }
        onTick?(s.openness, s.phase, s.phaseProgress)
    }

    /// Cap at 60 fps while the breath is moving; drop to ~15 fps during a static
    /// hold, where openness does not change and there is nothing to redraw. A
    /// calm app has no business driving ProMotion to 120.
    private static func frameRate(for phase: BreathPhase) -> CAFrameRateRange {
        phase.isHold
            ? CAFrameRateRange(minimum: 8, maximum: 20, preferred: 15)
            : CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
    }
}

/// The `CADisplayLink` target. It holds only a `weak` reference to the engine,
/// so even if a link is somehow never invalidated it can't keep the engine
/// alive — the tick just becomes a no-op.
@MainActor
private final class DisplayLinkForwarder: NSObject {
    private weak var target: BreathingEngine?
    init(target: BreathingEngine) { self.target = target }
    @objc func tick() { target?.stepFromLink() }
}
