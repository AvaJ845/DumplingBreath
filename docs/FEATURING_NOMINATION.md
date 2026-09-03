# App Store Featuring Nomination — Dumpling Breath

Draft of the App Store Connect **Featuring Nomination** submission.

North Star 2: *Apple editorial featuring is the single realistic path from zero
to visible.* This document is the plan for earning it.

---

## Timing

- **Submit the Featuring Nomination form in App Store Connect at least 3 weeks
  before the target release date** (Apple asks for 2–3+ weeks; 4–6 is safer for
  a first-time developer with no track record).
- The build should be in TestFlight and feature-complete when the nomination
  goes in — editors look at a real build.
- Nominate for: **an "App of the Day" / Today-tab story**, plus relevant
  evergreen collections (mindfulness, "apps that respect your privacy",
  "designed for Apple Watch", "great with widgets").
- Re-nominate for moments: a notable OS release (new framework adoption story),
  a seasonal mental-health / mindfulness push, a major feature update.

## The one-line pitch for an editor

> A pocket-sized dumpling you squeeze until your breathing slows down — it works
> with your eyes closed because the Taptic Engine carries the rhythm, it has no
> account and collects nothing, and it's on iPhone, iPad, and Apple Watch from
> day one. Made by two people.

## The Today-tab story angle

Not "another breathing app." The story is **restraint and respect**: an app that
does exactly one thing, asks for nothing, keeps nothing, and never tries to pull
you back — built to a craft standard usually reserved for apps that are trying
to monetize you. The dumpling is the reason it's *charming* instead of clinical.

---

## Mapped to Apple's 7 editorial criteria

### 1. User experience

- **One screen, one gesture, ~2-second loop:** open → press the dumpling →
  breathe. No onboarding, no account wall, no configuration. A stressed person
  is breathing within two seconds of the icon tap.
- **The default is correct** so nobody has to choose: coherent breathing
  (5.5s each way). Box and 4-7-8 are one quiet tap away, never a front door.
- **Two input models** so it fits the moment and the person: press-and-hold to
  breathe *with* the dumpling, or tap-to-toggle for a hands-free / lower-effort
  session.
- **Reachable before you've surfaced:** Lock Screen widget, Home Screen widget,
  Control Center control, and "Hey Siri, start Dumpling Breath" all drop you
  straight into a session without hunting for the app.
- **It respects the exit:** no streaks, no "you haven't breathed today," no
  re-engagement notifications — ever. Leaving is frictionless and guilt-free,
  which is itself the feature.

### 2. UI design

- **Grayscale-first.** The breath is legible with zero colour — carried by
  size, motion, and haptics — so it works for colour-blind users and
  eyes-closed users identically. Colour is decoration, never signal.
- **Procedural everything.** The dumpling is geometry and a Metal
  `distortionEffect`, not baked art — crisp at 20 pt on a Lock Screen and at
  full size on a 13" iPad, from a download under a megabyte.
- **Full dark mode** via proper light/dark colour sets (no hardcoded values).
- **Restraint as the aesthetic:** a near-empty, calm canvas with a single warm
  character. Nothing to get lost in, nothing to misread.

### 3. Innovation

- **Squeeze-to-breathe as a physical metaphor:** the dumpling inflates under
  your thumb and your breath follows the object, not a countdown or an
  instruction. The pressure gesture *is* the interface.
- **A live-simulation squish**, not a video loop — it deforms and springs back
  under touch, driven by the same `openness` signal that drives the haptics, so
  visual and haptic never drift.
- **Digital Crown as a breath-pace instrument** on the Watch: you *tune* the
  rhythm by feel, and the Taptic Engine plays it back.

### 4. Uniqueness

- The category has haptic breathing apps (Haptic Calm, Breathe Easy) and minimal
  breathing apps (iBreathe, One Deep Breath). **None has an ownable character,
  and none combines the squeeze metaphor with a genuine "collects nothing, no
  account, no network" guarantee enforced by the absence of networking code.**
- Character-led wellness is under-exploited (Finch is the proof it works); no
  haptic-breath app has a mascot or a memorable name.
- The refusal to build streaks / history / subscriptions is, in this category, a
  differentiator.

### 5. Accessibility

- **VoiceOver:** the dumpling is a single labelled control with a live phase
  value ("Breathe in", "Hold", "Breathe out", "Rest") and an adjustable action
  on Watch for pace.
- **Eyes-free by design:** the entire session is usable with the screen off —
  the Taptic Engine carries inhale / hold / exhale.
- **Dynamic Type** throughout the (minimal) text.
- **Reduce Motion:** the squish morph is replaced by a calm scale/opacity
  cross-fade — motion is never required to read the breath.
- **Motor:** press-and-hold is not the only input; tap-to-toggle and a timed
  mode cover Switch Control and limited dexterity.
- **No colour-only information** anywhere.
- Graceful degradation: on devices with no Taptic Engine (every iPad, older
  iPhones) the visual and timing carry the session; nothing breaks.

### 6. Localization

- All user-facing strings extracted to a String Catalog (`.xcstrings`) from v1.
- Launch localizations planned: **es, fr, de, ja, zh-Hans, pt-BR** (metadata +
  in-app), with the string count low enough (a dozen strings) that full
  localization is genuinely cheap and complete.
- The core interaction is wordless, so the app is *usable* in any locale on day
  one; localization is polish on top of an already-language-independent design.
- Phase words and haptic patterns are culturally neutral.

### 7. Product page quality

- 5 screenshots that tell a story (see `APP_STORE.md` shot-list): meet the
  dumpling → the squeeze → the breath → "collects nothing" → Watch + widget.
- Optional silent 15–20s App Preview of one unbroken breath.
- Description leads with the craft-and-privacy story, not a feature list.
- "Data Not Collected" privacy label, accurate `PrivacyInfo.xcprivacy`.
- Editor-clean title (brand-forward), no keyword stuffing in the visible name.
- App icon to an exceptional standard (see `APP_ICON_BRIEF.md`) — the single
  highest-leverage featuring asset.

---

## Current-year frameworks we're showcasing

An editor pitching this internally can point to concrete, current adoption:

| Framework / capability | How Dumpling Breath uses it |
|---|---|
| **WidgetKit** — accessory + system families | Lock Screen (circular, rectangular) and Home Screen (small) "breathe" widgets, static timeline, deep-link to a session |
| **App Intents** | "Start Dumpling Breath" intent with a pattern parameter — Shortcuts, Siri, and donated App Shortcuts, zero setup |
| **Control Center controls (iOS 18)** | A `ControlWidget` button that starts a breath from Control Center |
| **HealthKit — Mindful Minutes** | Opt-in write of a completed session as `HKCategoryType(.mindfulSession)` |
| **State of Mind API (iOS 18)** | Opt-in `HKStateOfMind` momentary-emotion entry ("calm") on completion — the same integration Evolve won a 2025 Apple Design Award partly on |
| **watchOS 10 SwiftUI + Digital Crown** | Standalone Watch app: `digitalCrownRotation` drives the pace, `WKInterfaceDevice` haptics carry the rhythm |
| **Core Haptics** — continuous pattern with dynamic parameter curves | The squeeze's living haptic texture on iPhone, frame-synced to the visual via one shared `openness` signal |
| **Metal `distortionEffect` (SwiftUI)** | The procedural squish — kilobytes, not megabytes, identical on Watch and iPad |
| **Swift strict concurrency (`complete`)** | Whole codebase, warning-free |
| **String Catalogs** | All localization |
| **Privacy Manifest (`PrivacyInfo.xcprivacy`)** | Accurate "collects nothing / no tracking" declaration |

## What to have ready when you submit

- [ ] Feature-complete build in TestFlight.
- [ ] Final app icon.
- [ ] All 5 screenshots + (optional) App Preview, for iPhone / iPad / Watch.
- [ ] Description, subtitle, keywords, promo text finalized (`APP_STORE.md`) —
      **after** the Naming Council collision check.
- [ ] Privacy policy hosted at a stable URL (`PRIVACY.md`).
- [ ] Localizations for the launch languages.
- [ ] A short "what's the story" note for the editor — the Today-tab angle above.
- [ ] Accessibility pass signed off (VoiceOver, Dynamic Type, Reduce Motion,
      eyes-free, no-haptics device).
