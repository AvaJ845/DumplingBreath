import Foundation
import HealthKit

/// Writes a completed breathing session to the Health app: Mindful Minutes,
/// and — if asked — an iOS 18 State of Mind entry. Opt-in only (`HealthConsent`)
/// and entirely local. The app holds no network entitlement, so there is
/// nowhere for this data to go but Health on this device.
@MainActor
public final class MindfulSessionLogger {

    public static let shared = MindfulSessionLogger()

    private let store = HKHealthStore()

    init() {}

    public var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private var shareTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = [HKCategoryType(.mindfulSession)]
        if #available(iOS 18.0, *) {
            types.insert(HKObjectType.stateOfMindType())
        }
        return types
    }

    /// Ask for write access to the types the person has opted into. Safe to
    /// call again; HealthKit shows the sheet only for undetermined types.
    @discardableResult
    public func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: shareTypes, read: [])
            return true
        } catch {
            return false
        }
    }

    /// Log a finished session. Call this once, when a session ends.
    ///
    /// - Parameters:
    ///   - duration: how long the person breathed, in seconds.
    ///   - endingAt: when it ended (defaults to now).
    ///   - logMindful: write the Mindful Minutes sample.
    ///   - logStateOfMind: also write a momentary State of Mind ("calm").
    public func log(
        duration: TimeInterval,
        endingAt end: Date = .now,
        logMindful: Bool,
        logStateOfMind: Bool
    ) async {
        guard isAvailable, duration > 0, logMindful || logStateOfMind else { return }
        let start = end.addingTimeInterval(-duration)
        var samples: [HKObject] = []

        if logMindful {
            samples.append(HKCategorySample(
                type: HKCategoryType(.mindfulSession),
                value: HKCategoryValue.notApplicable.rawValue,
                start: start,
                end: end))
        }

        if logStateOfMind, #available(iOS 18.0, *) {
            samples.append(HKStateOfMind(
                date: end,
                kind: .momentaryEmotion,
                valence: 0.3,               // "a little more pleasant than neutral"
                labels: [.calm],
                associations: []))
        }

        guard !samples.isEmpty else { return }
        try? await store.save(samples)
    }

    /// Convenience: reads `HealthConsent` and does the right thing (or nothing).
    public func logIfPermitted(duration: TimeInterval, endingAt end: Date = .now) async {
        let consent = HealthConsent.shared
        await log(
            duration: duration,
            endingAt: end,
            logMindful: consent.logMindfulMinutes,
            logStateOfMind: consent.logStateOfMind)
    }
}
