import Foundation
import CoreHaptics
import AVFoundation
import DumplingBreathCore

/// Turns the breathing engine's live `openness` into a texture you can follow
/// with your eyes closed:
///
/// - **inhale** — intensity swells with the fill; sharpness brightens as it tops out
/// - **hold-in** — a faint, near-still shimmer (never silence)
/// - **exhale** — intensity and sharpness soften together, a smooth release
/// - **hold-out** — a barely-there rest floor
/// - **the turn** — a soft transient exactly at each direction change, so the
///   reversal is *felt*, not just seen
///
/// One long continuous `CHHapticPattern` carries the envelope; every frame
/// `update(openness:phase:phaseProgress:)` steers it with dynamic parameters.
/// On hardware with no Taptic Engine (every iPad, older iPhones) it falls back to
/// an optional soft tone (`AudioBreathCue`) or clean silence — never a crash,
/// never a blocked visual.
///
/// The numbers below are **provisional** — they cannot be felt in a headless
/// environment. See the tuning notes in the agent report.
@MainActor
final class HapticChoreographer {

    /// True only on hardware with a Taptic Engine.
    private(set) var supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    private let settings: HapticSettings
    private let audio = AudioBreathCue()

    private var engine: CHHapticEngine?
    private var continuous: CHHapticAdvancedPatternPlayer?

    private var isActive = false               // between begin() and end()
    private var lastPhase: BreathPhase = .inhale
    private var interruptionObserver: NSObjectProtocol?

    init(settings: HapticSettings = .shared) {
        self.settings = settings
    }

    // MARK: - Lifecycle

    /// Call once the view is on screen. Cheap to call again — it no-ops if ready.
    func prepare() {
        observeInterruptions()
        guard settings.isEnabled, supportsHaptics, engine == nil else { return }
        do {
            let engine = try CHHapticEngine()
            engine.isAutoShutdownEnabled = false     // we own start/stop, not the idle timer
            engine.playsHapticsOnly = true           // don't touch the audio session
            engine.stoppedHandler = { [weak self] reason in
                Task { @MainActor in self?.handleEngineStopped(reason) }
            }
            engine.resetHandler = { [weak self] in
                Task { @MainActor in self?.recoverEngine() }
            }
            try engine.start()
            self.engine = engine
        } catch {
            supportsHaptics = false                  // degrade rather than retry forever
        }
    }

    /// The breath started. Begin the continuous texture (or the audio fallback).
    func begin() {
        isActive = true
        lastPhase = .inhale                          // seeded: no transient fires at t = 0

        if settings.isEnabled, supportsHaptics {
            if engine == nil { prepare() }
            startContinuous()
        } else if settings.isEnabled, settings.audioFallbackEnabled {
            audio.start()
        }
    }

    /// Every frame while breathing. `phaseProgress` is 0…1 within the phase.
    func update(openness: Double, phase: BreathPhase, phaseProgress: Double) {
        guard isActive, settings.isEnabled else { return }

        if phase != lastPhase {
            fireTurn(into: phase)
            lastPhase = phase
        }

        let scale = settings.intensityScale

        if supportsHaptics, let player = continuous {
            let env = envelope(openness: openness, phase: phase, phaseProgress: phaseProgress)
            try? player.sendParameters([
                CHHapticDynamicParameter(parameterID: .hapticIntensityControl,
                                         value: Float(env.intensity * scale),
                                         relativeTime: 0),
                CHHapticDynamicParameter(parameterID: .hapticSharpnessControl,
                                         value: Float(env.sharpness),
                                         relativeTime: 0)
            ], atTime: CHHapticTimeImmediate)
        } else if settings.audioFallbackEnabled {
            // Small floor while moving so the direction still reads at the extremes.
            let floor = phase.isMoving ? 0.06 : 0.0
            audio.update(openness: min(1, openness + floor), scale: scale)
        }
    }

    /// The breath stopped. Releases the players; keeps the engine warm for a
    /// quick restart. Full release is `teardown()`.
    func end() {
        isActive = false
        try? continuous?.stop(atTime: CHHapticTimeImmediate)
        continuous = nil
        audio.stop()
    }

    /// The view is gone. Release everything — no engine left running.
    func teardown() {
        end()
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
            self.interruptionObserver = nil
        }
        engine?.stop(completionHandler: nil)
        engine = nil
    }

    // MARK: - The texture

    /// Per-phase (intensity, sharpness), both 0…1. PROVISIONAL — tune on device.
    private func envelope(openness: Double, phase: BreathPhase, phaseProgress: Double)
        -> (intensity: Double, sharpness: Double) {
        switch phase {
        case .inhale:
            // Swell: intensity rides the fill; sharpness climbs as it nears full.
            return (0.16 + 0.78 * openness,
                    0.10 + 0.42 * phaseProgress)
        case .holdIn:
            // Near-still: a slow ~1.2 Hz tremor so the hand knows it's still "on".
            return (0.10 + 0.018 * sin(lfoPhase() * 7.5),
                    0.34)
        case .exhale:
            // Release: soften intensity and sharpness together as it empties.
            return (0.10 + 0.55 * openness,
                    max(0.06, 0.34 - 0.26 * phaseProgress))
        case .holdOut:
            // Rest floor: barely there — but not nothing.
            return (0.035 + 0.010 * sin(lfoPhase() * 5.0),
                    0.05)
        }
    }

    /// A soft tap at the direction change. Distinct feel per turn so you can tell,
    /// eyes closed, which way the breath just went.
    private func fireTurn(into phase: BreathPhase) {
        guard supportsHaptics, let engine else { return }
        let intensity: Float
        let sharpness: Float
        switch phase {
        case .inhale:  (intensity, sharpness) = (0.35, 0.28)   // bottom of the breath — "begin"
        case .exhale:  (intensity, sharpness) = (0.32, 0.42)   // top of the breath — "let go"
        case .holdIn, .holdOut:
            (intensity, sharpness) = (0.14, 0.20)              // a whisper into the hold
        }
        let scale = Float(settings.intensityScale)
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity * scale),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0)
        do {
            let player = try engine.makePlayer(with: CHHapticPattern(events: [event], parameters: []))
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // A missed transient is cosmetic — the envelope still carries the turn.
        }
    }

    private func lfoPhase() -> Double { CFAbsoluteTimeGetCurrent() }

    // MARK: - Engine plumbing

    private func startContinuous() {
        guard supportsHaptics, let engine, continuous == nil else { return }
        do {
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0,
                duration: 60 * 30)                  // long; stopped explicitly in end()
            let player = try engine.makeAdvancedPlayer(
                with: CHHapticPattern(events: [event], parameters: []))
            player.completionHandler = { [weak self] _ in
                Task { @MainActor in self?.continuous = nil }
            }
            try player.start(atTime: CHHapticTimeImmediate)
            continuous = player
        } catch {
            continuous = nil
        }
    }

    /// The engine stopped itself. Recover in place if we're mid-breath.
    private func handleEngineStopped(_ reason: CHHapticEngine.StoppedReason) {
        continuous = nil
        switch reason {
        case .idleTimeout, .systemError:
            // Recoverable: bring the same engine back if we're mid-breath.
            if isActive { recoverEngine() }
        case .audioSessionInterrupt:
            // A call took the stage. Wait for the interruption-ended notification
            // to restart — starting now would race the system.
            break
        default:
            // applicationSuspended / engineDestroyed / gameControllerDisconnect /
            // anything new: release it. begin()/prepare() build a fresh engine.
            engine = nil
        }
    }

    /// The haptic server restarted under us (or an interruption ended, or a
    /// recoverable stop): restart the engine and rebuild the continuous player —
    /// its old reference is dead.
    private func recoverEngine() {
        do {
            try engine?.start()
            continuous = nil
            if isActive { startContinuous() }
        } catch {
            engine = nil
        }
    }

    private func observeInterruptions() {
        guard interruptionObserver == nil else { return }
        // queue: .main → the block runs on the main actor; parse synchronously.
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard
                let self,
                let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                let type = AVAudioSession.InterruptionType(rawValue: raw)
            else { return }
            let optionsRaw = note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            MainActor.assumeIsolated {
                self.handleInterruption(type,
                                        options: .init(rawValue: optionsRaw))
            }
        }
    }

    private func handleInterruption(_ type: AVAudioSession.InterruptionType,
                                    options: AVAudioSession.InterruptionOptions) {
        switch type {
        case .began:
            // The engine has stopped itself; drop the dead player reference.
            continuous = nil
        case .ended:
            guard isActive, options.contains(.shouldResume) else { return }
            if supportsHaptics {
                recoverEngine()
            } else if settings.isEnabled, settings.audioFallbackEnabled {
                audio.start()
            }
        @unknown default:
            break
        }
    }
}
