import Foundation
import Observation
import DumplingBreathCore

/// The Watch's live session. Same `BreathClock` math as iPhone/iPad — but
/// watchOS has no `CADisplayLink`, so the frame loop here is a plain
/// main-actor async `Task` sampling the clock ~20×/s. That is plenty for a
/// breath (nothing in a breath moves fast) and easy on the battery.
@Observable
@MainActor
final class WatchBreathSession {

    private(set) var openness: Double = 0
    private(set) var phase: BreathPhase = .inhale
    private(set) var isRunning = false

    /// Seconds per half-breath, driven by the Digital Crown. The resonance
    /// band is roughly 3–8 s; 5.5 s is the "just settle me" middle.
    var secondsPerPhase: Double = 5.5 {
        didSet { rebuildPattern() }
    }

    @ObservationIgnored private var clock = BreathClock(pattern: .coherent)
    @ObservationIgnored private var loop: Task<Void, Never>?
    @ObservationIgnored private var startTime = Date.now
    @ObservationIgnored private var lastPhase: BreathPhase = .inhale
    @ObservationIgnored private let haptics = WatchHaptics()

    func toggle() { isRunning ? stop() : start() }

    func start() {
        guard !isRunning else { return }
        rebuildPattern()
        isRunning = true
        startTime = .now
        lastPhase = .inhale
        haptics.prepare()
        haptics.play(for: .inhale)
        loop = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, self.isRunning else { break }
                self.tick()
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }

    func stop() {
        isRunning = false
        loop?.cancel()
        loop = nil
        haptics.stop()
        openness = 0   // the view eases this down via `.animation`
    }

    private func tick() {
        let t = Date.now.timeIntervalSince(startTime)
        let sample = clock.sample(at: t)
        openness = sample.openness
        phase = sample.phase
        if sample.phase != lastPhase {
            lastPhase = sample.phase
            haptics.play(for: sample.phase)
        }
    }

    private func rebuildPattern() {
        let s = min(max(secondsPerPhase, 2), 10)
        clock.pattern = BreathingPattern(
            id: "watch-coherent",
            name: "Coherent",
            detail: "\(fmt(s)) in · \(fmt(s)) out",
            inhale: s, holdIn: 0, exhale: s, holdOut: 0)
    }

    private func fmt(_ v: Double) -> String {
        v.rounded() == v ? String(Int(v)) : String(format: "%.1f", v)
    }
}
