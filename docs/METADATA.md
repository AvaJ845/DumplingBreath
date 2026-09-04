# Metadata — Dumpling Breath

Paste-ready App Store Connect fields + the Naming Council record. Sits next to
[APP_STORE.md](APP_STORE.md) (the full three-part ASO plan).

---

## Naming Council — 2026-09-03

Ran the `aso-playbook` three-Fellow council on the name **"Dumpling Breath"**
(stage: name decided, pre-launch). Live App Store searches performed.

| Fellow | Lean | Key finding |
|---|---|---|
| **Discoverability** | Revise | Name `Dumpling Breath: Calm Breathing` is **brand-first**, against playbook §1 ("primary keyword FIRST — an unknown indie can't spend the name slot on brand"). Documented as a deliberate trade-off for the featuring-first strategy, but it does cost search rank vs a keyword-first competitor. Subtitle `Feel each breath. No account.` wastes a slot: "breath" stems to the same token as the Name's "Breathing". Keywords include **`meditation`** — a "Trap" term (enormous volume, owned by Calm/Headspace/Insight Timer), low ROI. Rest of Keywords compliant (99/100, no spaces, singular, no cross-field repeats, no competitor names). |
| **Collision** | Approve | **No exact or near-exact "Dumpling Breath" / "DumplingBreath" on the US App Store** (searched direct, `site:apps.apple.com`, and "dumpling + breathing/calm/meditation"). "Dumpling" as a search term is dominated by **Dumpling Grocery** (`id1410408871`, grocery delivery) and the **squishy-toy cluster** (`Dumpling Squishy Art Designer` `id1622514201`, `Dumpling Squishy Coloring Book`) — different categories, low tap-confusion, and ~zero qualified breathing traffic (confirms keeping `dumpling` out of the Keywords field). Character-led breathing neighbours exist but are **not name collisions**: `Breathling: Breathe & Calm` (`id6781057748`, a firefly you breathe with), `BreathLoop` (`id6788128715`, haptic pacer), `Haptic Calm` (`id6758531681`). "[Word] Breath/Breathe" is a crowded but standard pattern (Breathe, Box Breathe, Breathscape, Breathe Bubble) — "Dumpling Breath" is the most distinctive modifier in it. Trademark: food marks `DUMPLING D'OR` / `DUMPLINGGO` (IC 029/030) don't conflict; `Dumpling, Inc.` (grocery-shopper platform) holds software marks — different goods/channel, low confusion, **but run USPTO TESS on "DUMPLING" IC 009 before brand spend** (same caution as SecondLook). |
| **Portfolio** | Revise | **🚨 Direct overlap with Loomi** (`com.loomi.app`, `~/Documents/Loomi`). Loomi is a one-tap stress-relief app: breathe → ground → reframe, a **standalone Breathe module**, a **Home/Lock-Screen widget**, **Apple Health Mindful Minutes**, an **original mascot + breathing orb**, action-button `loomi://relief`, subtitle **"Calm breathing, private & free."** Dumpling Breath duplicates the core (breathing + widget + HealthKit + mascot + privacy-first) and its proposed Name is literally *"…Calm Breathing."* Cross-portfolio rule: **no two portfolio apps compete for the same primary keyword.** Loomi's last commit is **2026-07-01** (~2 months cold; never launched). Bundle id `com.avaresearch.dumplingbreath` is the correct convention (not a bird name, not `com.toppupgames.*`) ✓. Dumpling Breath needs its **own exclusion list** (cf. Loomi "not medical care", Crossbeat "no health claims"). |

### VERDICT: **Revise**

The mark **"Dumpling Breath" is clear to ship** — no App Store collision, ownable,
on-convention, sayable to Siri. Before the name and metadata lock:

1. **Resolve Loomi (blocking, user decision).** Either:
   - **Supersede** — Dumpling Breath *is* the Loomi concept, done right (haptic
     squeeze, Watch, featuring play). Retire Loomi or fold it in. Simplest, and
     Loomi never shipped.
   - **Split** — keep both, with hard-separated positioning: Loomi = the broad
     calm-tools suite (journal, grounding, reframe, learning); Dumpling Breath =
     a single-purpose haptic breathing *toy*, Watch-first. Then Dumpling Breath
     **cedes "calm breathing"** as a primary keyword and leads on *squeeze /
     haptic / fidget*; Loomi keeps "calm breathing".
2. **Fix the metadata** (below — assumes the *split* case; if *supersede*, the
   Name can go keyword-first and reclaim "calm breathing").
3. **Add the exclusion list** (below).
4. **Run USPTO TESS** on "DUMPLING" in IC 009 before any brand/logo spend.

---

## Paste-ready fields (revised per council — "split" case)

```
App Store Name (30):   Dumpling Breath: Calm Breathing
   Brand-first is a deliberate featuring trade-off (editors favour a clean
   brand). Keyword-first alternative if search rank wins out:
   "Calm Breathing - Dumpling" (25).

Subtitle (30):         Ease stress with a squeeze
   New words vs the Name: ease, stress, squeeze. Indexes "stress", states the
   mechanic, makes no medical claim ("ease", not "treat"). Replaces the old
   "Feel each breath. No account." (which stem-repeated "breath").

Keywords (99/100):     breathwork,anxiety,panic,relax,sleep,fidget,haptic,mindful,grounding,pranayama,box,478,vagal,soothe
   Dropped from the earlier draft: meditation (Trap term), bedtime/focus/
   nervous/unwind (moved to the rotation pool). No spaces, singular, no
   Name/Subtitle repeats, no competitor names.

Promotional text (170, no review needed):
   No sign-up, no ads, no streaks, collects nothing. Just a soft dumpling you
   squeeze until your breathing slows down. Now on Apple Watch, with a Lock
   Screen widget.
```

**Keyword rotation pool** (swap the weakest ranker each monthly update):
`meditation, bedtime, focus, nervous, unwind, resonance, coherent, selfsoothe,
downshift, worry, overwhelm, tension, restless, sigh, exhale`

**Combinations harvested** (what the concatenated index can rank for):
`calm breathing, breathing haptic, haptic breathwork, box breathing, 478
breathing, breathing anxiety, panic breathing, breathing sleep, fidget
breathing, vagal breathing, pranayama app`

---

## Exclusion list (App Review + honesty framing)

Never in the name, subtitle, keywords, description, screenshots, or promo text —
Dumpling Breath is **a calming tool, not medical care** (cf. Loomi):

- `cure`, `treat`, `treatment`, `therapy`, `therapeutic`, `clinically proven`,
  `medically`, `doctor recommended`
- `anxiety disorder`, `panic disorder`, `PTSD`, `depression` (the *conditions* —
  bare `anxiety` / `panic` / `stress` as category keywords are fine)
- `guaranteed`, `instant relief`, `stops panic attacks`
- Any competitor name (`Calm`, `Headspace`, `Balance`, `Oak`, `Othership`,
  `Breathwrk`, `Haptic Calm`) — Apple rejects these in the Keywords field.
- `squishy` / `fidget toy` framed as the product identity (per the ROAST — trend
  keyword, shortest shelf life; `fidget` as one keyword among many is fine).
