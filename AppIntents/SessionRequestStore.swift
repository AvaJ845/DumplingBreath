import Foundation

/// The one piece of shared state between the app and its extensions: a pending
/// "please start a breathing session" request, written by a widget tap / App
/// Intent / Control Center control and consumed once by the app on launch.
///
/// It is deliberately tiny — a pattern id and a timestamp in the app-group
/// `UserDefaults`. No history, no counters, no analytics. (North Star §1.)
public enum SessionRequestStore {

    public static let appGroupID = "group.com.avaresearch.dumplingbreath"

    private static let patternKey = "pendingSession.patternID"
    private static let stampKey = "pendingSession.requestedAt"

    /// Requests expire fast: a tap you made twenty minutes ago shouldn't
    /// hijack the app the next time you open it for something else.
    private static let staleAfter: TimeInterval = 90

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    /// Called from a widget / intent / control. `patternID` nil ⇒ "use the
    /// app's current default".
    public static func request(patternID: String?) {
        guard let defaults else { return }
        defaults.set(patternID, forKey: patternKey)
        defaults.set(Date().timeIntervalSinceReferenceDate, forKey: stampKey)
    }

    /// Called once by the app when it becomes active. Returns the requested
    /// pattern id (or `""` meaning "default") if a fresh request is pending,
    /// then clears it. `nil` ⇒ nothing to do.
    public static func consumePendingRequest() -> String? {
        guard let defaults else { return nil }
        let stamp = defaults.double(forKey: stampKey)
        guard stamp > 0 else { return nil }
        defer {
            defaults.removeObject(forKey: patternKey)
            defaults.removeObject(forKey: stampKey)
        }
        let age = Date().timeIntervalSinceReferenceDate - stamp
        guard age >= 0, age <= staleAfter else { return nil }
        return defaults.string(forKey: patternKey) ?? ""
    }

    /// The custom-scheme deep link a widget uses for its whole-tile tap.
    /// `dumplingbreath://start?pattern=box`
    public static func deepLink(patternID: String?) -> URL {
        var components = URLComponents()
        components.scheme = "dumplingbreath"
        components.host = "start"
        if let patternID, !patternID.isEmpty {
            components.queryItems = [URLQueryItem(name: "pattern", value: patternID)]
        }
        return components.url ?? URL(string: "dumplingbreath://start")!
    }

    /// Parse a `dumplingbreath://start?pattern=…` URL back to a pattern id
    /// (`""` = default). `nil` ⇒ not one of ours.
    public static func patternID(from url: URL) -> String? {
        guard url.scheme == "dumplingbreath", url.host == "start" else { return nil }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        return items?.first { $0.name == "pattern" }?.value ?? ""
    }
}
