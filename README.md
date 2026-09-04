# Dumpling Breath

A pocket object that makes one slow breath feel good enough to take another.
Press a soft dumpling; feel it fill and empty under your thumb; your breathing
follows. No account, no ads, no tracking, no streaks.

iPhone · iPad · Apple Watch.

## Status

Iteration 1 — integrated. Builds clean for **iPhone, iPad, and Apple Watch**;
30/30 core tests pass; zero Swift warnings.

- Metal squish shader (thumb-tracking dimple), per-phase haptic choreography with
  no-Taptic audio fallback, hardened breath engine
- Apple Watch app (Digital Crown + Taptic), Lock/Home Screen widgets, iOS 18
  Control Center control, App Intents / Siri
- Opt-in HealthKit Mindful Minutes + State of Mind, settings/privacy screen,
  seeded String Catalog
- App Store + Featuring Nomination + Privacy + Icon-brief docs in `docs/`

**Not done:** on-device feel tuning (every squish/haptic constant is a first
guess), the app icon, a signing team. See [AGENTS.md](AGENTS.md) DoD.

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
