# Dumpling Breath — North Star

Two North Stars. Every build decision must serve **both**. If a feature serves
one and violates the other, it does not ship.

## North Star 1 — the product

> A pocket object that makes one slow breath feel good enough to take another.
> You press a soft dumpling, feel it fill and empty under your thumb, and your
> breathing follows — no instructions, no account, no sign-in.
>
> It respects a person in a hard moment: instant, private, collects nothing,
> no streaks, no guilt, no notifications asking you to come back.
>
> **It must never become** a subscription wellness funnel, a
> streak-and-reminder engagement trap, or a data-collecting "mental health"
> product.

## North Star 2 — the only realistic distribution

> We have no audience, no social following, and no ad budget. Apple editorial
> featuring is the single realistic path from zero to visible.
>
> Apple's editors consistently favour: calm, focused, single-purpose
> experiences; privacy-first, no-account design; exceptional icon and
> interaction craft; early adoption of current Apple frameworks; full
> accessibility and localization; and a story worth writing in the Today tab.
>
> Every build decision is measured against: **does this earn a place in that
> story?**

## The shape

What it honestly does: *lets you feel a breath, so you take another.*
Who it respects: *a person having a bad minute, and Apple's editors.*
What it must never become: *a wellness subscription with a streak counter.*

## The one contract in the code

`openness` — a single continuous `0…1` signal produced by `BreathClock`,
consumed by both the visuals and the haptics. Keep phase-specific logic out of
the view and out of the haptics. If that contract stays clean, everything
composes. (See `Sources/Core/BreathClock.swift`.)

## Formats (all three, from v1)

iPhone · iPad · Apple Watch. The Watch is not a port — the Digital Crown drives
the breath and the Taptic Engine carries it. Widget (Lock + Home Screen) and an
App Intent / Control Center control are part of the featuring surface, not
"later."
