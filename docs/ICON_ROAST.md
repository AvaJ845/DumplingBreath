# 🔥 Icon & identity roast — Apple Fellows, 2026-09-03

Roasted two AI-rendered concept sheets ("DumplingBreath", bowl version then
purple squeeze-hands version). Full nine-Fellow write-up is in chat history;
this is the binding record.

## North Star (for the identity)

> The mark has one job on two surfaces: on a stranger's Home Screen it should
> lower their pulse a little just by being there, and in a Today-tab grid it
> should be the one an editor's eye lands on. It must read — instantly, at
> 40 pt, in grayscale — as **one warm soft thing you'd want to hold**, made by
> people who sweat detail. It must never look like a food/recipe app, a kids'
> toy, or a reskin of Calm or Apple's own Breathe.

## Verdict

| Element | Verdict | Why |
|---|---|---|
| A dumpling as the mark | **Ship** | The one differentiated idea — no competitor has a character. |
| Showing the **squeeze** (hands / thumb indent) | **Ship** | The purple concept fixed the biggest gap: nothing in the bowl version said "squeeze". Keep the *idea*, not the two literal hands. |
| Full kawaii face (closed eyes, smile, blush) | **Cut** | NS: "must never look like a kids' toy." `APP_ICON_BRIEF.md:49` rated a face highest-risk; default no face, or two subliminal dots A/B'd. |
| Bowl + broth | **Cut** | Signals a food app; deepens the Dumpling Grocery confusion; no clean silhouette for tinted mode. |
| Breath swirls | **Cut** | Explicit "Avoid" (`APP_ICON_BRIEF.md:57`); invisible at 40 pt and in grayscale; wrong mechanic (wind, not squeeze). |
| Purple / blue wellness gradient ground | **Cut → Reshape** | `APP_ICON_BRIEF.md:58` literally lists "Purple-to-blue wellness gradient" as avoid. Go warm neutral. |
| Two literal hands with fingers | **Reshape** | Too much detail for 40 pt. Reduce to a single soft thumb-indent on the dumpling's cheek — the *give* under a press, not anatomy. |
| Watch bloom-ring (earlier concept) | **Cut** | Clones Apple Mindfulness; not in the code. |
| Name "DumplingBreath" (one word) | **Cut** | Approved name is "Dumpling Breath: Calm Breathing" (`METADATA.md`). |
| Sheet's "North Stars" (Delight & Utility / Trust & Safety / …) | **Cut** | Generic platitudes over the real dual North Star (`NORTH_STAR.md`). |
| 40 pt / grayscale / dark + tinted testing | **Reshape** | Do it first, not last (`APP_ICON_BRIEF.md:25`). |
| AI-generated as the *final* icon | **Cut** | `APP_ICON_BRIEF.md:87`. Concepts are mood reference for a commissioned illustrator (or a deterministic code-drawn mark), not the ship asset. |

**Overall: 🟠 Reshape.** The character idea is right; the executions ignored the
brief on the specifics.

## The one fix

Strip to a **single warm, near-faceless dumpling with one soft thumb-indent, on
a warm neutral ground** — no bowl, no swirl, no purple, no hands — and prove it
reads as a friendly plump form at 40 pt in grayscale. Everything else is
downstream of that silhouette.

## Working icon (this repo)

Until a commissioned illustrator delivers, the app ships a **deterministic
code-drawn icon** generated from `Icon/` (see `Icon/README.md`) — same
procedural-but-warm spirit as the in-app dumpling, brief-compliant, version
controlled. Swap in final art by replacing the two 1024 PNGs and re-running the
slice step.
