import XCTest
@testable import DumplingBreathCore

/// Covers the pure "motion" additions to `BreathClock`: the analytic openness
/// velocity, and the idle rest-wobble helper. Kept separate from
/// `BreathClockTests` so the phase/openness contract tests stay easy to scan.
final class BreathClockMotionTests: XCTestCase {

    // MARK: velocity

    func testVelocityIsPositiveOnInhaleAndNegativeOnExhale() {
        let clock = BreathClock(pattern: .coherent) // 5.5 in / 5.5 out
        XCTAssertGreaterThan(clock.sample(at: 1.0).velocity, 0)   // rising
        XCTAssertLessThan(clock.sample(at: 8.25).velocity, 0)     // falling
    }

    func testVelocityIsZeroDuringHolds() {
        let clock = BreathClock(pattern: .box) // 4·4·4·4
        XCTAssertEqual(clock.sample(at: 6).velocity, 0, accuracy: 1e-9)  // hold-in
        XCTAssertEqual(clock.sample(at: 14).velocity, 0, accuracy: 1e-9) // hold-out
    }

    func testVelocityDecaysToZeroAtEachTurnOfTheBreath() {
        let clock = BreathClock(pattern: .coherent)
        // Start of inhale and end of inhale: smoothstep derivative → 0.
        XCTAssertEqual(clock.sample(at: 0.001).velocity, 0, accuracy: 0.02)
        XCTAssertEqual(clock.sample(at: 5.49).velocity, 0, accuracy: 0.02)
        // Mid-inhale it is clearly moving.
        XCTAssertGreaterThan(clock.sample(at: 2.75).velocity, 0.2)
    }

    func testVelocityMatchesAFiniteDifferenceMidPhase() {
        // Cross-check the analytic derivative against a central difference, well
        // clear of phase boundaries (where openness is only piecewise-smooth).
        let clock = BreathClock(pattern: .fourSevenEight) // 4 / 7 / 8 / 0
        let midPhasePoints = [1.0, 2.0, 3.0,      // inhale
                              6.0, 8.0, 10.0,     // hold-in
                              12.0, 15.0, 18.0]   // exhale
        for t in midPhasePoints {
            let dt = 0.001
            let numeric = (clock.sample(at: t + dt).openness
                           - clock.sample(at: t - dt).openness) / (2 * dt)
            XCTAssertEqual(clock.sample(at: t).velocity, numeric, accuracy: 0.01,
                           "velocity mismatch at t=\(t)")
        }
    }

    // MARK: restWobble

    func testRestWobbleIsZeroAtOriginAndBoundedByAmplitude() {
        XCTAssertEqual(BreathClock.restWobble(at: 0), 0, accuracy: 1e-9)
        for t in stride(from: 0.0, through: 30.0, by: 0.25) {
            XCTAssertLessThanOrEqual(abs(BreathClock.restWobble(at: t)), 0.05 + 1e-9)
        }
    }

    func testRestWobbleIsPeriodic() {
        let period = 6.0
        for t in stride(from: 0.0, through: 12.0, by: 0.5) {
            XCTAssertEqual(BreathClock.restWobble(at: t, period: period),
                           BreathClock.restWobble(at: t + period, period: period),
                           accuracy: 1e-9)
        }
    }

    func testRestWobbleGuardsAgainstNonPositivePeriod() {
        XCTAssertEqual(BreathClock.restWobble(at: 3, period: 0), 0)
        XCTAssertEqual(BreathClock.restWobble(at: 3, period: -1), 0)
    }
}
