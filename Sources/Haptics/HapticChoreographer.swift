import Foundation
import CoreHaptics
import DumplingBreathCore

/// Turns the breathing engine's `openness` into a living haptic texture:
/// the inhale swells, the holds shimmer faintly, the exhale releases.
///
/// SCAFFOLD ONLY — Agent 2 (Haptics & breathing science) owns making this feel
/// real: per-phase signatures, soft transients at the turn of the breath,
/// interruption/reset recovery, and a silent fallback on devices with no
/// Taptic Engine (every iPad, older iPhones).
@MainActor
final class HapticChoreographer {

    private(set) var isSupported = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    var isEnabled = true

    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?

    func prepare() {
        guard isSupported, isEnabled, engine == nil else { return }
        do {
            let engine = try CHHapticEngine()
            engine.isAutoShutdownEnabled = false
            engine.stoppedHandler = { [weak self] _ in
                self?.engine = nil
                self?.player = nil
            }
            engine.resetHandler = { [weak self] in
                guard let self else { return }
                try? self.engine?.start()
                self.player = nil
            }
            try engine.start()
            self.engine = engine
        } catch {
            isSupported = false
        }
    }

    func begin() {
        guard isSupported, isEnabled, let engine else { return }
        do {
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0,
                duration: 60 * 20)                 // long; stopped explicitly
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makeAdvancedPlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            self.player = player
        } catch {
            player = nil
        }
    }

    /// Call every frame with the engine's current state.
    func update(openness: Double, phase: BreathPhase, phaseProgress: Double) {
        guard let player else { return }
        let motionFloor = phase.isMoving ? 0.14 : 0.0
        let intensity = Float(min(1, openness * 0.82 + motionFloor))
        let sharpness = Float(0.12 + openness * 0.33)
        try? player.sendParameters([
            CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: intensity, relativeTime: 0),
            CHHapticDynamicParameter(parameterID: .hapticSharpnessControl, value: sharpness, relativeTime: 0)
        ], atTime: CHHapticTimeImmediate)
    }

    func end() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
        player = nil
    }

    func teardown() {
        end()
        engine?.stop(completionHandler: nil)
        engine = nil
    }
}
