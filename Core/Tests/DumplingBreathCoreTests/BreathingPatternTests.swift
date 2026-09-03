import XCTest
@testable import DumplingBreathCore

/// The bundled catalogue: ids stay stable (they're persisted as the user's
/// choice), phase durations and cycle math are correct, and each pattern lands
/// in the physiological range its rationale claims.
final class BreathingPatternTests: XCTestCase {

    // MARK: Identity / stability

    func testBundledIdsAreStableAndInThisOrder() {
        // These strings are written to @AppStorage("patternID") — renaming one
        // silently resets a user's choice. Change with care.
        XCTAssertEqual(BreathingPattern.bundled.map(\.id),
                       ["coherent", "rest", "extended-exhale", "box", "478"])
    }

    func testBundledIdsAreUnique() {
        let ids = BreathingPattern.bundled.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testDefaultIsCoherentAndFirst() {
        XCTAssertEqual(BreathingPattern.bundled.first?.id, "coherent")
        XCTAssertEqual(BreathingPattern.coherent.id, "coherent")
    }

    func testCatalogueHasFivePatterns() {
        XCTAssertEqual(BreathingPattern.bundled.count, 5)
    }

    // MARK: Cycle math

    func testCycleDurationIsSumOfPhases() {
        for p in BreathingPattern.bundled {
            XCTAssertEqual(p.cycleDuration,
                           p.inhale + p.holdIn + p.exhale + p.holdOut,
                           accuracy: 1e-9, "\(p.id)")
        }
    }

    func testDurationOfPhaseMatchesInitializer() {
        let p = BreathingPattern.fourSevenEight
        XCTAssertEqual(p.duration(of: .inhale), 4)
        XCTAssertEqual(p.duration(of: .holdIn), 7)
        XCTAssertEqual(p.duration(of: .exhale), 8)
        XCTAssertEqual(p.duration(of: .holdOut), 0)
    }

    func testEveryPatternHasRealInhaleAndExhaleAndSaneCycle() {
        for p in BreathingPattern.bundled {
            XCTAssertGreaterThan(p.inhale, 0, "\(p.id) inhale")
            XCTAssertGreaterThan(p.exhale, 0, "\(p.id) exhale")
            XCTAssertGreaterThanOrEqual(p.holdIn, 0, "\(p.id) holdIn")
            XCTAssertGreaterThanOrEqual(p.holdOut, 0, "\(p.id) holdOut")
            XCTAssertTrue((6.0...20.0).contains(p.cycleDuration),
                          "\(p.id) cycle \(p.cycleDuration)s out of range")
        }
    }

    // MARK: Physiological claims in the rationale comments

    func testCoherentSitsAtCardiacResonance() {
        let bpm = 60 / BreathingPattern.coherent.cycleDuration
        XCTAssertEqual(bpm, 5.45, accuracy: 0.1)
        XCTAssertTrue((4.5...7.0).contains(bpm), "coherent \(bpm) bpm")
    }

    func testCoherentIsSymmetricalWithNoHolds() {
        let p = BreathingPattern.coherent
        XCTAssertEqual(p.inhale, p.exhale)
        XCTAssertEqual(p.holdIn, 0)
        XCTAssertEqual(p.holdOut, 0)
    }

    func testBoxIsAFullyEqualRatio() {
        let p = BreathingPattern.box
        XCTAssertEqual(Set([p.inhale, p.holdIn, p.exhale, p.holdOut]), [4])
    }

    func testFourSevenEightIsExhaleWeightedWithLongHold() {
        let p = BreathingPattern.fourSevenEight
        XCTAssertGreaterThan(p.exhale, p.inhale)
        XCTAssertGreaterThan(p.holdIn, p.inhale)
        XCTAssertEqual(p.holdOut, 0)
    }

    func testExtendedExhaleHasA1To1Point5Ratio() {
        let p = BreathingPattern.extendedExhale
        XCTAssertEqual(p.exhale / p.inhale, 1.5, accuracy: 1e-9)
        XCTAssertGreaterThan(p.exhale, p.inhale)
        XCTAssertEqual(p.holdIn, 0)
        XCTAssertEqual(p.holdOut, 0)
    }

    func testRestIsTheGentlestPaceThatStillCountsAsSlow() {
        let p = BreathingPattern.rest
        let bpm = 60 / p.cycleDuration
        XCTAssertEqual(bpm, 10, accuracy: 1e-9)
        XCTAssertLessThanOrEqual(bpm, 10)               // still "slow breathing"
        XCTAssertLessThan(p.cycleDuration,
                          BreathingPattern.coherent.cycleDuration)   // gentler than the default
        XCTAssertEqual(p.inhale, p.exhale)
    }

    // MARK: Value semantics

    func testCodableRoundTrips() throws {
        let data = try JSONEncoder().encode(BreathingPattern.bundled)
        let restored = try JSONDecoder().decode([BreathingPattern].self, from: data)
        XCTAssertEqual(restored, BreathingPattern.bundled)
    }

    func testEqualityAndHashingByValue() {
        let a = BreathingPattern(id: "x", name: "X", detail: "",
                                 inhale: 1, holdIn: 0, exhale: 1, holdOut: 0)
        let b = BreathingPattern(id: "x", name: "X", detail: "",
                                 inhale: 1, holdIn: 0, exhale: 1, holdOut: 0)
        XCTAssertEqual(a, b)
        XCTAssertEqual(Set([a, b]).count, 1)
    }
}
