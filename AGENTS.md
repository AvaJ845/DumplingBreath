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

- [ ] Builds clean for iOS + watchOS, no warnings, strict concurrency on.
- [ ] `xcodebuild test` green.
- [ ] Squeeze-to-breathe feels alive on a real iPhone; degrades gracefully (no
      crash, sensible visual/audio) on iPad and no-haptics devices.
- [ ] Watch app: Digital Crown drives the breath, Taptic carries it.
- [ ] Lock Screen widget + App Intent / Control Center control start a session.
- [ ] Full VoiceOver, Dynamic Type, Reduce Motion, dark mode.
- [ ] Localized strings extracted (English + at least the string catalog scaffold).
- [ ] `PrivacyInfo.xcprivacy` accurate: collects nothing, no tracking.
- [ ] `docs/APP_STORE.md` + `docs/FEATURING_NOMINATION.md` drafted.
- [ ] App icon: brief written and 1024 placeholder in place (final art is a
      separate design commission).
