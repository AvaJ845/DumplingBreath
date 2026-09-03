# Ecosystem integration — wiring the surface into the app

Agent 3 built the widget / App Intent / Control Center / Watch / HealthKit
surface. A few small hooks have to land in **app-side code owned by Agent 1**
(`App/`, `Sources/`) to connect it. None is more than a few lines. Each is
marked here and left as a `// TODO(agent-3)` note for the integrator.

## 1. Consume a "start a session" request on launch / foreground

`SessionRequestStore` (in `AppIntents/SessionRequestStore.swift`) is the shared
hand-off. The widget's whole-tile tap uses a `dumplingbreath://start?pattern=…`
deep link; the App Intent and Control Center control write into the app-group
container.

In `App/DumplingBreathApp.swift` (or `RootView`):

```swift
import DumplingBreathCore   // BreathingPattern
// SessionRequestStore is compiled into the app target (AppIntents/ path)

@main
struct DumplingBreathApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .onOpenURL { url in
                    if let id = SessionRequestStore.patternID(from: url) {
                        RootView.handleStartRequest(patternID: id)   // "" = keep current default
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active,
                       let id = SessionRequestStore.consumePendingRequest() {
                        RootView.handleStartRequest(patternID: id)
                    }
                }
        }
    }
}
```

`handleStartRequest(patternID:)` should: set `patternID` (`@AppStorage`) if the
string is non-empty and matches a bundled pattern, then trigger the session to
auto-start (e.g. a `@State` flag `SqueezeView` observes, or route straight into
a "breathing" state). An empty string means "just open into a session with
whatever pattern is already selected."

## 2. App group entitlement

`project.yml` already adds `group.com.avaresearch.dumplingbreath` to the app and
the widget entitlements. When a real `DEVELOPMENT_TEAM` is set, the **App
Groups** capability must be enabled for the App ID and the widget App ID in the
developer portal / automatic signing. Simulator builds work without it.

## 3. HealthKit logging call site

`Health/MindfulSessionLogger.swift` + `Health/HealthConsent.swift` are compiled
into the app. Two hooks:

- **Privacy screen (Agent 1 UI):** bind two toggles to
  `HealthConsent.shared.logMindfulMinutes` and `.logStateOfMind`. When a person
  turns one ON, call `await MindfulSessionLogger.shared.requestAuthorization()`.
  Both default OFF; never flip them programmatically.
- **Session end:** when a session completes, call
  `await MindfulSessionLogger.shared.logIfPermitted(duration: elapsedSeconds)`.
  It is a no-op if nothing is opted in. Recommend a minimum duration gate
  (e.g. ≥ 30s) before logging, decided in the session code.

## 4. Review prompt (ASO momentum)

Per `APP_STORE.md` §4: fire `requestReview` (SwiftUI `\.requestReview`
environment value) **only** after the person completes their **3rd full
breathing session** — a real happy peak — once per app version, never at
onboarding or after an interruption. The "3rd completed session" counter is the
*one* place a small counter is acceptable; keep it a single `@AppStorage` Int
and nothing more (no history, no dates). This lives in Agent 1's session code.

## 5. String Catalog

`FEATURING_NOMINATION.md` (localization criterion) and `AGENTS.md` DoD both call
for a `Localizable.xcstrings` String Catalog. The user-facing strings are almost
all in `Sources/` and `App/` (phase labels are in
`Core/Sources/DumplingBreathCore/BreathPhase.swift`). Agent 1/2 own extracting
them; Agent 3's widget/watch/intent strings are already written as plain
`String` / `LocalizedStringResource` literals ready for catalog extraction.

## 6. Watch app embedding

`project.yml` embeds `DumplingBreathWatch` into the iOS app
(`dependencies: … embed: true`). Verify in Xcode that the "Embed Watch Content"
build phase copies it to `$(CONTENTS_FOLDER_PATH)/Watch/` — XcodeGen 2.44.1
should handle this for a `platform: watchOS` app dependency, but it's worth a
one-time check on the first archive. The Watch app is otherwise fully standalone
(no `WatchConnectivity`, no shared state with the phone).
