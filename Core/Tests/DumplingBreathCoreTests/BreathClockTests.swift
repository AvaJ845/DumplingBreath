import XCTest
@testable import DumplingBreathCore

final class BreathClockTests: XCTestCase {

    func testCoherentHasNoHolds() {
        let clock = BreathClock(pattern: .coherent)
        XCTAssertEqual(clock.sample(at: 0).phase, .inhale)
        XCTAssertEqual(clock.sample(at: 2).phase, .inhale)
        XCTAssertEqual(clock.sample(at: 5.6).phase, .exhale)
    }

    func testOpennessRisesOnInhaleAndFallsOnExhale() {
        let clock = BreathClock(pattern: .coherent)
        let earlyInhale = clock.sample(at: 1.0).openness
        let topInhale = clock.sample(at: 5.4).openness
        let midExhale = clock.sample(at: 8.25).openness

        XCTAssertLessThan(earlyInhale, topInhale)
        XCTAssertGreaterThan(topInhale, midExhale)
        XCTAssertGreaterThan(topInhale, 0.9)
        XCTAssertLessThan(earlyInhale, 0.5)
    }

    func testBoxBreathingHoldsAtFull() {
        let clock = BreathClock(pattern: .box) // 4·4·4·4
        let sample = clock.sample(at: 6)       // 2s into the hold-in
        XCTAssertEqual(sample.phase, .holdIn)
        XCTAssertEqual(sample.openness, 1, accuracy: 0.0001)
    }

    func testBoxBreathingRestsAtEmpty() {
        let clock = BreathClock(pattern: .box)
        let sample = clock.sample(at: 14)      // 2s into the hold-out
        XCTAssertEqual(sample.phase, .holdOut)
        XCTAssertEqual(sample.openness, 0, accuracy: 0.0001)
    }

    func testCycleCounting() {
        let clock = BreathClock(pattern: .box) // 16s cycle
        XCTAssertEqual(clock.sample(at: 0).completedCycles, 0)
        XCTAssertEqual(clock.sample(at: 33).completedCycles, 2)
    }

    func testNegativeTimeIsClamped() {
        let clock = BreathClock(pattern: .coherent)
        XCTAssertEqual(clock.sample(at: -5).phase, .inhale)
        XCTAssertEqual(clock.sample(at: -5).openness, 0, accuracy: 0.0001)
    }

    func testFourSevenEightPhaseBoundaries() {
        let clock = BreathClock(pattern: .fourSevenEight) // 4 / 7 / 8 / 0
        XCTAssertEqual(clock.sample(at: 2).phase, .inhale)
        XCTAssertEqual(clock.sample(at: 8).phase, .holdIn)
        XCTAssertEqual(clock.sample(at: 15).phase, .exhale)
        XCTAssertEqual(clock.sample(at: 18.9).phase, .exhale)
    }

    func testEaseIsBoundedAndHitsEndpoints() {
        for i in 0...20 {
            let t = Double(i) / 20
            let v = BreathClock.ease(from: 0, to: 1, t: t)
            XCTAssertGreaterThanOrEqual(v, 0)
            XCTAssertLessThanOrEqual(v, 1)
        }
        XCTAssertEqual(BreathClock.ease(from: 0, to: 1, t: 0), 0, accuracy: 0.0001)
        XCTAssertEqual(BreathClock.ease(from: 0, to: 1, t: 1), 1, accuracy: 0.0001)
    }
}
