# 🔥 ROAST — Dumpling Breath, reviewed by the Apple Fellows (concept mode)

Reviewed 2026-09-03, before any polished build existed.

## North Star

See [NORTH_STAR.md](NORTH_STAR.md). Short form: *a pocket object that makes one
slow breath feel good enough to take another — private, account-free, collects
nothing, never a wellness subscription funnel — and crafted well enough that
Apple's editors want to write about it, because featuring is the only way we get
seen.*

## Evidence pass — the space is not empty

| App | Source | What it means for us |
|---|---|---|
| **Haptic Calm** (`id6758531681`) | [App Store](https://apps.apple.com/us/app/haptic-calm/id6758531681) | **Ships our core mechanic already** — "hold your phone, press your thumb on the centre, follow visual + haptic cues to adjust your breathing," 6 haptic modes. Our differentiation is the character + squish craft, nothing else. |
| **Breathe Easy** (`id6759265534`) | [App Store](https://apps.apple.com/app/id6759265534) | Eyes-free haptic inhale/hold/exhale cues. Same eyes-closed promise we were going to make. |
| **Tappy** (`id1492017640`), **Fidgetable** (`id6503308266`), **Sensory Fidgets**, **Fidget Widget** (`id1456233150`) | App Store | Haptic fidget-toy category is populated and partly junky — editors may pattern-match us into it. |
| **Apollo Sessions** | [Fast Company](https://www.fastcompany.com/91269825/apollo-sessions-app-haptic-feedback-calm) | Haptics-to-calm, backed by Apollo Neuro hardware brand. |
| **Evolve** | [ADA 2025](https://developer.apple.com/design/awards/2025/) | 2025 Apple Design Award winner — breathing + affirmations + journaling, integrates **State of Mind API** + Image Playground. Proof breathing apps win ADAs; also proof the bar is a deeply integrated app, not a one-trick toy. |
| **Calm** | [revenue coverage](https://bayelsawatch.com/calm-statistics/) | ~$7.68M/mo, ~4.5M paying subscribers. Meditation-app market → ~$7.41B by 2029. Big money owns "breathing as a feature." |
| **iBreathe**, **One Deep Breath** (`id1529751090`), **RESPIRA**, **Open** | App Store | Indie minimal breathing apps already exist and are liked. "Minimal breathing app" is a crowded shelf. |

**The single most important fact for the Judge:** the exact "squeeze / thumb-press
to feel your breath in haptics" interaction is already shipping (Haptic Calm).
This only works as *"a crafted little dumpling you squeeze,"* and that stands or
falls entirely on execution quality that does not exist yet.

---

## 1. Product Marketing & Management — 4/10
🔥 **Roast**
- Haptic Calm (`id6758531681`) already ships the mechanic. "Dumpling" is a skin
  on an existing interaction, not a wedge.
- No pricing power: the comps (iBreathe, One Deep Breath, Breathe Easy) are free
  or cheap one-time. Calm/Headspace give breathwork away as a loss-leader feature.
- "Squishy dumpling" is a *trend aesthetic* (fidget market ~14.6% CAGR, TikTok-
  driven) — highest-cloned, shortest-half-life space in the store.
- Zero distribution assets (no audience, no budget). If Apple doesn't feature it,
  nobody sees it. That's not a marketing plan, it's a lottery ticket.

✅ **Good**
- Character-led wellness is genuinely under-exploited — Finch built a top-grossing
  app on exactly "a creature you care for." None of the haptic-breath apps have an
  ownable character or a memorable name.
- The underlying need (down-regulate in 30 seconds, privately) is real and permanent.

🔧 **Highest-leverage fix:** Commit the entire identity to *"the breathing app you
can use with your eyes closed, that collects nothing, made by two people"* — a
sentence a parent or an editor forwards. The dumpling is the mascot for that
sentence, not the pitch.

## 2. Systems Architecture & Integration — 7/10
🔥 **Roast**
- The visible feature is trivial; the real plumbing is `CHHapticEngine` lifecycle
  — interruptions (a call mid-session), route changes, `stoppedHandler`,
  `resetHandler`, backgrounding. Users *will* hit engine restart mid-breath.
- Keeping haptics frame-synced to the visual and to the breath clock without
  drift over a 5+ minute session is real work, across iPhone **and** Watch.
- HealthKit "Mindful Minutes" write + iOS 18 **State of Mind** logging is the
  integration that earns featuring (see Evolve) — and it's genuine entitlement,
  permission-prompt, and privacy-copy work, not free.
- Three platforms from v1 (iPhone/iPad/Watch) triples the surface: shared Swift
  package vs. copy-paste is a decision to make now, not later.

✅ **Good**
- Local-only, no backend, no accounts, no sync server — the cleanest possible
  architecture and privacy-by-construction.
- `BreathClock` as a pure value type with one `openness` output is the right
  seam; visuals and haptics compose off it.

🔧 **Highest-leverage fix:** Put `BreathClock` + `BreathingPattern` +
`BreathPhase` in a shared Swift package now, so iOS and watchOS consume one
implementation of the breath math.

## 3. Software Development — 6/10
🔥 **Roast**
- Riskiest unbuilt thing: the haptic choreography engine — a continuous
  `CHHapticPattern` with dynamic parameter curves tracking a real-time breath
  timeline, that must **degrade silently** on every iPad and older iPhone (no
  Taptic Engine) and not drift. Prototype this first, on the oldest supported
  device and on iPad.
- Timer/`CADisplayLink` drift, `CHHapticEngine` auto-shutdown, and lost
  `continuousPlayer` references after `resetHandler` are the bug nests.
- Watch haptics are a *different API* (`WKInterfaceDevice.play` /
  `CHHapticEngine` on watchOS with tighter limits) — the choreography does not
  port for free.

✅ **Good**
- The breath clock is pure and fully unit-testable (`BreathClockTests`) — the
  hard-to-test part (haptics) is cleanly isolated behind one `update(...)` call.
- Tiny dependency surface: no third-party SDKs, nothing to CVE-audit.

🔧 **Highest-leverage fix:** Build a throwaway "haptic bench" — sliders for
intensity/sharpness/phase — and tune the feel on real hardware before wiring it
to the breath engine.

## 4. Model & Data Design — 7/10
🔥 **Roast**
- The vocabulary decides the North Star. If the model grows `Streak`,
  `SessionHistory`, `Journey`, `Achievement`, `DailyGoal` — it has become
  Calm-lite and lost. Watch for these in review.
- `BreathingPattern` should stay a value type with no behaviour; the moment it
  gains `func play()` the layering is wrong.
- No persistence model is needed beyond `@AppStorage` for the chosen pattern and
  settings. A Core Data / SwiftData stack here is a smell.

✅ **Good**
- `openness: Double` as the single shared contract between clock, view and
  haptics is the correct central abstraction — concrete, testable, composable.
- `BreathPhase.targetOpenness` keeps phase semantics in one place.

🔧 **Highest-leverage fix:** Write a one-line rule at the top of the core module —
*"this app stores a pattern id and three booleans; if you're adding a database,
stop"* — and hold the line.

## 5. UX Architecture — 8/10
🔥 **Roast**
- Press-and-hold as the *only* input is an accessibility trap (motor
  impairment, Switch Control, VoiceOver). Needs a tap-to-toggle and a timed mode.
- First run must not feel like a demo: if the good haptic patterns or the calm
  characters are all behind a paywall on launch, the free experience reads as a
  trailer and the review says so.
- "Which pattern?" is a decision a stressed user should not have to make —
  the default must be right (coherent 5.5/5.5) and the picker must be a quiet
  afterthought, not a front door.

✅ **Good**
- The core loop is ~2 seconds — open → press → breathe — with no capture
  friction, no setup, no account. That is the strongest possible shape for a
  calm app, and the reason journaling-style wellness apps die (week-two
  friction) doesn't apply here.
- One screen. Nothing to get lost in.

🔧 **Highest-leverage fix:** Ship a Lock Screen widget / Control Center control
that starts a session in one tap without unlocking — the calm app you can use
*before* you've fully surfaced from the bad moment.

## 6. Rendering, Media & Data Efficiency — 7/10
🔥 **Roast**
- Running `CADisplayLink` + haptic engine + a Metal distortion shader at 120 fps
  ProMotion for 5+ minutes is a measurable drain for an app whose whole job is
  "calm." Cap at 60; pause rendering during static holds.
- If the squish is ever tempted toward a baked PNG/video sequence, that's tens of
  MB for something a shader does in kilobytes — and it kills the "tiny, runs
  beautifully everywhere" featuring line.

✅ **Good**
- Zero assets, zero network, procedural everything — the download can be under a
  megabyte and identical-crisp on a Watch and a 13" iPad.

🔧 **Highest-leverage fix:** Commit to a Metal `distortionEffect` for the squish
now (`Sources/Views/Shaders/`), and set a hard 60 fps cap in `BreathingEngine`
(already scaffolded).

## 7. Visual Fidelity, Color, Contrast, Dark Mode — 6/10
🔥 **Roast**
- The breath state must never be conveyed by colour alone (a red→green cue fails
  colour-blind users and the eyes-free premise). It's currently carried by
  size + motion + haptics — keep it that way, and don't let a designer add a
  colour-shifting glow as the *primary* signal.
- Reduce Motion turns the squish (which *is* motion) into a problem — needs a
  calm scale/opacity cross-fade alternative (scaffolded, needs real design).
- Pastel-on-pastel chrome (the pattern picker, the corner button) will fail 3:1
  contrast if not checked.
- Dynamic Type + full dark mode on a 3-control app is a day of work and two
  scored featuring criteria — do it, don't skip it.

✅ **Good**
- Restraint is the whole aesthetic; a near-empty screen has little room to fail.
- Canvas colour is already defined as a proper light/dark colorset, not a
  hardcoded value.

🔧 **Highest-leverage fix:** Design the entire UI in grayscale first. If the
breath reads with no colour, it passes a colour-blind user and an eyes-closed
user both.

## 8. Performance, Energy & Battery — 7/10
🔥 **Roast**
- Failure modes: `CHHapticEngine` left running between sessions; `CADisplayLink`
  not invalidated on background; 120 Hz during holds; an animating widget.
- The temptation to add "time to breathe" reminder notifications is both an
  energy cost and a **North Star 1 violation** (guilt / re-engagement).

✅ **Good**
- No GPS, no background audio, no background refresh, no push — inherently one of
  the gentlest apps on the device.
- `scenePhase` teardown and explicit `haptics.teardown()` are already wired in
  the scaffold.

🔧 **Highest-leverage fix:** Add an energy test to the checklist: 5-minute
session on an iPhone SE, Instruments Energy Log, must sit in "Low."

## 9. Technology Evangelism — 7/10
🔥 **Roast**
- Growth loop is inherently capped: single-player, private, no social. So
  featuring + word of mouth is the *entire* loop — which means the craft bar
  *is* the business plan, and there's no fallback if the craft isn't
  award-tier.
- Apple's own **Mindfulness** app ships on every Watch and Haptic Calm already
  owns the "Featured" phrasing — there may be no editorial oxygen left.
- No ecosystem hooks exist yet (widget, Watch, App Intent, Control, Double Tap,
  Shortcuts) — every one of them is a featuring multiplier being left on the table.

✅ **Good**
- "The breathing app you can use with your eyes closed, that Apple's haptics make
  feel real, that collects nothing" is a legitimate Today-tab story and a
  WWDC-session-demo shape.
- State of Mind + Mindful Minutes integration is a concrete, citable reason for
  an editor to pick it (Evolve precedent).

🔧 **Highest-leverage fix:** Ship Watch + Lock Screen widget + an App Intent /
Control Center control in v1, and file the Featuring Nomination ≥3 weeks before
launch built around the 7 editorial criteria.

---

## THE JUDGE'S VERDICT

| Feature / Direction | Council lean | Verdict | North-Star rationale |
|---|---|---|---|
| "Haptic breathing app" as the pitch | Negative (PMM, Evangelism) | **Reshape** | NS2: already shipped (Haptic Calm) — un-featurable as "another haptic breathing app." Only "a crafted dumpling you squeeze" is a story. |
| The dumpling character + squeeze-to-breathe squish | Positive (UX, Model, Rendering) | **Ship** | NS1: this *is* "a pocket object that makes one breath feel good enough to take another." The one thing competitors don't have. |
| All-ages positioning (not Kids Category) | Positive | **Ship** | NS1+NS2: sidesteps COPPA / parental-gate / loot-box regimes entirely; mindfulness featuring skews general-audience anyway. |
| iPhone + iPad + Apple Watch from v1 | Positive (Architecture, Evangelism) | **Ship** | NS2: Watch (Crown + Taptic) is a distinct, demoable craft surface; multi-platform is an editorial signal. Requires a shared breath-math package. |
| Lock Screen widget + App Intent / Control Center control | Positive (UX, Evangelism) | **Ship** | NS1: use it *before* you've surfaced from the bad moment. NS2: ecosystem surface = featuring multiplier. |
| HealthKit Mindful Minutes + iOS 18 State of Mind logging | Positive (Architecture, Evangelism) | **Ship** | NS2: concrete, citable featuring hook (Evolve won an ADA partly on this). NS1: opt-in, local, no third party. |
| Metal distortion shader for the squish; 60 fps cap | Positive (Rendering, Power) | **Ship** | NS2: "tiny, runs beautifully on Watch and iPad alike" is craft editors notice. NS1: gentle on battery. |
| Press-and-hold as the *only* input | Negative (UX, Color) | **Reshape** | NS2: accessibility is a scored criterion — add tap-to-toggle + timed mode. |
| Paywalling the core haptic patterns / characters | Negative (UX, PMM) | **Reshape** | NS1+NS2: free must feel *complete*. Monetize with extra characters + advanced patterns as a single one-time unlock. |
| Subscription · streaks · reminder notifications · session-history database · "programs" | Strongly negative (Model, Power, PMM) | **Cut** | NS1: each one is the "wellness funnel / engagement trap" the North Star forbids. NS2: they're exactly what makes editors pass. |
| Trend-keyword branding ("Squishy Dumpling…") | Negative (PMM) | **Reshape** | NS2: editors write about original things. One named, ownable dumpling character — not a trend keyword. |

**Overall direction: 🟠 Reshape** — leaning green *only if* the squeeze-and-squish
feel is genuinely award-tier on real hardware.

The idea is sound and uniquely featurable, but "a haptic breathing app" has
already been built. It only works as "a crafted little dumpling you squeeze," and
that is 100% an execution bet.

### The one thing to fix before anything else

**Build the squeeze-to-breathe haptic + squish prototype on a real iPhone and a
real iPad this week.** If the dumpling doesn't feel alive under your thumb — if a
stranger doesn't smile the first time they squeeze it — there is no product, and
no amount of widgets or App Store copy will save it.
