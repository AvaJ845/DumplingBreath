import Foundation
import WatchKit
import DumplingBreathCore

/// Carries the rhythm on the wrist. Every turn of the breath gets a distinct
/// Taptic cue, and the two moving phases get one soft mid-phase tap so you
/// feel the swell even with the screen off.
///
/// `WKInterfaceDevice.play` is the reliable, always-available path. A
/// continuous `CHHapticEngine` texture (matching the iPhone choreography) is a
/// future enhancement and belongs with Agent 2's haptic work.
@MainActor
final class WatchHaptics {

    private var midPhaseTap: Task<Void, Never>?

    func prepare() {
        // WKInterfaceDevice needs no setup; kept for symmetry with iOS.
    }

    func play(for phase: BreathPhase) {
        midPhaseTap?.cancel()

        let device = WKInterfaceDevice.current()
        switch phase {
        case .inhale:  device.play(.start)
        case .exhale:  device.play(.stop)
        case .holdIn:  device.play(.click)
        case .holdOut: device.play(.click)
        }

        if phase.isMoving {
            midPhaseTap = Task {
                // roughly the middle of a 3–8 s moving phase
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                WKInterfaceDevice.current().play(.click)
            }
        }
    }

    func stop() {
        midPhaseTap?.cancel()
        midPhaseTap = nil
    }
}
