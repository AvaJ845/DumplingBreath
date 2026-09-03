import Foundation
import AVFoundation
import os

/// Fixed engine sample rate; the mixer resamples to the hardware rate.
private let kSampleRate = 44_100.0
/// 146.83 Hz ≈ D3 — low enough to feel unobtrusive, high enough for a phone
/// speaker to reproduce cleanly.
private let kFrequency: Float = 146.83

/// The no-Taptic fallback: one low, warm sine that swells and fades with
/// `openness`, so the breath is still *sensed* on an iPad or an old iPhone.
///
/// Opt-in (`HapticSettings.audioFallbackEnabled`). Routed through `.ambient`, so a
/// phone on silent stays silent and the user's music is never interrupted. Never
/// speech, never a melody — a presence, not a notification.
@MainActor
final class AudioBreathCue {

    /// State touched by the render (audio) thread. Only `Float`s — trivially
    /// `Sendable` — behind an unfair lock the render block holds for O(1) work.
    private struct Signal {
        var targetAmp: Float = 0
        var amp: Float = 0        // one-pole smoothed, advanced on the audio thread
        var phase: Float = 0
        var sampleRate: Float = 44_100
    }

    private let signal = OSAllocatedUnfairLock(initialState: Signal())
    private let engine = AVAudioEngine()
    private var source: AVAudioSourceNode?
    private var running = false

    func start() {
        guard !running else { return }
        configureSession()

        signal.withLock {
            $0 = Signal(targetAmp: 0, amp: 0, phase: 0, sampleRate: Float(kSampleRate))
        }

        guard let format = AVAudioFormat(standardFormatWithSampleRate: kSampleRate,
                                         channels: 1) else { return }

        let node = AVAudioSourceNode(format: format) { [signal] _, _, frameCount, audioBufferList in
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let twoPi = 2 * Float.pi
            signal.withLockUnchecked { s in
                let step = twoPi * kFrequency / s.sampleRate
                for frame in 0..<Int(frameCount) {
                    // Glide amplitude toward target (~50 ms) so nothing zippers.
                    s.amp += (s.targetAmp - s.amp) * 0.0004
                    // Fundamental plus a quiet octave for a little body.
                    var sample = sinf(s.phase) * s.amp
                    sample += sinf(s.phase * 2) * s.amp * 0.18
                    sample = max(-1, min(1, sample))
                    s.phase += step
                    if s.phase > twoPi { s.phase -= twoPi }
                    for buffer in buffers {
                        let out = buffer.mData!.assumingMemoryBound(to: Float.self)
                        out[frame] = sample
                    }
                }
            }
            return noErr
        }

        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.12   // hard ceiling — a whisper, never a tone test
        source = node

        do {
            try engine.start()
            running = true
        } catch {
            engine.detach(node)
            source = nil
            running = false
        }
    }

    /// `openness` 0…1 → target amplitude, attenuated by the user's intensity knob.
    func update(openness: Double, scale: Double) {
        let clamped = Float(max(0, min(1, openness)) * max(0, min(1, scale)))
        signal.withLock { $0.targetAmp = clamped }
    }

    func stop() {
        guard running else { return }
        running = false
        signal.withLock { $0.targetAmp = 0 }
        engine.stop()
        if let source {
            engine.detach(source)
            self.source = nil
        }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        // .ambient: obey the ring/silent switch, mix with other audio, never
        // take over the room. A calm cue that hijacks playback is a bug.
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }
}
