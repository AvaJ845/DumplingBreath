# Dumpling Breath

A pocket object that makes one slow breath feel good enough to take another.
Press a soft dumpling; feel it fill and empty under your thumb; your breathing
follows. No account, no ads, no tracking, no streaks.

iPhone · iPad · Apple Watch.

## Status

Iteration 0 — scaffold. Core breath clock + engine + a placeholder dumpling and
haptic choreographer are in place and unit-tested. Three workstreams are building
out feel, haptics, and the ecosystem/App-Store surface in parallel — see
[AGENTS.md](AGENTS.md).

## North Star

[docs/NORTH_STAR.md](docs/NORTH_STAR.md) — read before contributing.
The Apple Fellows roast that shaped this: [docs/ROAST.md](docs/ROAST.md).

## Build

Requires [XcodeGen](https://github.com/yonyz/XcodeGen) and Xcode 16+.

```sh
xcodegen generate
open DumplingBreath.xcodeproj
```

Or from the command line (no signing team is configured yet, so simulator
builds pass `CODE_SIGNING_ALLOWED=NO`):

```sh
xcodegen generate
xcodebuild -scheme DumplingBreath \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO build

# Breath-math tests (fast, no simulator):
cd Core && swift test
```

## Architecture

- `Sources/Core` — pure breath math (`BreathClock`), the live session
  (`BreathingEngine`), and the pattern catalogue. No UIKit.
- `Sources/Haptics` — `CHHapticEngine` choreography driven by `openness`.
- `Sources/Views` — the one screen: a dumpling you hold to breathe with.
- `App` — app entry, Info.plist, privacy manifest, asset catalog.
- `Tests` — `BreathClock` coverage.

The one contract: `openness` — a single `0…1` signal from `BreathClock`, consumed
by both the visuals and the haptics.

## Privacy

Collects nothing. No network requests. No analytics. No account. See
`App/PrivacyInfo.xcprivacy`.
