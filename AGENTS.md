# Build coordination — Dumpling Breath

Read [docs/NORTH_STAR.md](docs/NORTH_STAR.md) and [docs/ROAST.md](docs/ROAST.md)
first. Every change is measured against **both** North Stars.

## Hard rules for all agents

1. **Do not run `git`** anything. This repo lives in an iCloud-synced folder;
   concurrent `.git` access corrupts refs. The integrator (main session) owns
   all commits.
2. **Do not run `xcodegen` or `xcodebuild`.** The integrator regenerates and
   builds. You write source; you may run `swift` on isolated pure files if
   useful, but don't rely on it.
3. **Stay in your lane / your directories.** Do not edit files owned by another
   agent. If you need a change in someone else's file, leave a
   `// TODO(agent-N): …` note and tell the integrator.
4. **No new third-party dependencies.** Zero SDKs. Apple frameworks only.
5. **No analytics, no networking, no tracking, no notifications.** If your work
   needs any of these, stop and flag it.
6. Add SwiftUI `#Preview`s and, for any pure logic, `XCTest` cases in `Tests/`.
7. Match the house style already in `Sources/` — terse doc comments that say
   *why*, value types where possible, `@MainActor` on anything touching UIKit.

## Lane ownership

The pure breath-math now lives in **`Core/`** — a Swift package (`swift test`
runs it) that is *also* compiled as an in-project framework `DumplingBreathCore`.
The live session engine (`BreathingEngine`, needs `CADisplayLink`) stays app-side
in `Sources/Core/`.

| Agent | Owns (write here) | Never touch |
|---|---|---|
| **Agent 1 — Core interaction & feel** | `Core/Sources/DumplingBreathCore/BreathClock.swift` + `BreathPhase.swift`, `Sources/Core/BreathingEngine.swift`, `Sources/Views/**` (incl. new `Sources/Views/Shaders/`), `Core/Tests/**` (clock/engine tests) | `Sources/Haptics/**`, `Core/Sources/DumplingBreathCore/BreathingPattern.swift`, `project.yml`, `Widget/`, `Watch/` |
| **Agent 2 — Haptics & breathing science** | `Sources/Haptics/**`, `Core/Sources/DumplingBreathCore/BreathingPattern.swift` (catalogue + rationale), `Resources/Haptics/**` (AHAP), `Core/Tests/**` (pattern tests) | `Sources/Views/**`, `Core/Sources/DumplingBreathCore/BreathClock.swift`, `project.yml` |
| **Agent 3 — Ecosystem & App Store** | `Widget/**`, `Watch/**`, `AppIntents/**`, `docs/**` (except NORTH_STAR / ROAST), `project.yml` (**sole owner**), promoting `DumplingBreathCore` to a real multi-platform target so watchOS shares it | `Sources/**`, `Core/Sources/**` (read-only reference) |

## Integration points (the shared contract)

- `BreathClock.Sample.openness : Double` (0…1) is the ONE signal everything
  consumes. Don't add phase-specific branching in views or haptics — derive it
  from `openness` + `phase`.
- `BreathingEngine.onTick` / `.onPhaseChange` are how live consumers subscribe.
- Breath math (`BreathClock`, `BreathingPattern`, `BreathPhase`) must end up in a
  shared target so iOS + watchOS use one copy (Agent 3 extracts `SharedKit/`,
  Agents 1 & 2 keep their types moveable — no UIKit imports in those three files).

## Definition of done for the "north star Apple build"

- [x] Builds clean for iOS + watchOS, no warnings, strict concurrency on.
      (iPhone 17, iPad Pro 11", Apple Watch Series 11 — sim, `CODE_SIGNING_ALLOWED=NO`.)
- [x] `cd Core && swift test` green — 30/30.
- [ ] Squeeze-to-breathe feels alive on a real iPhone; degrades gracefully (no
      crash, sensible visual/audio) on iPad and no-haptics devices.
      **← needs on-device tuning; every squish/haptic constant is a first guess.**
- [x] Watch app: Digital Crown drives the breath, Taptic carries it.
      (Continuous CHHapticEngine texture on watch = future enhancement; phase-turn
      + mid-phase `WKInterfaceDevice` taps for now.)
- [x] Lock Screen widget + App Intent / Control Center control start a session.
      (Wired into `RootView` via `SessionRequestStore`.)
- [x] Full VoiceOver, Dynamic Type, Reduce Motion, dark mode.
- [x] Localized strings: `App/Localizable.xcstrings` seeded (English), build
      settings emit strings; full translation is a later task.
- [x] `PrivacyInfo.xcprivacy` accurate: collects nothing, no tracking.
- [x] `docs/APP_STORE.md` + `docs/FEATURING_NOMINATION.md` drafted.
- [x] Settings / Privacy screen: haptic + input + Health opt-in toggles, plain
      "collects nothing" statement. (`Sources/Views/SettingsView.swift`.)
- [ ] App icon: brief written (`docs/APP_ICON_BRIEF.md`); **no art yet** — final
      icon is a separate design commission and the top featuring asset.
- [ ] Real `DEVELOPMENT_TEAM` + App Group / HealthKit capabilities in the portal
      (needed for device / TestFlight; simulator is fine without).
- [ ] Naming Council / live App Store collision check on "Dumpling Breath".
