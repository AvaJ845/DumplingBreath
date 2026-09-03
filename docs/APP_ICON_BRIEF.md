# App Icon Brief — Dumpling Breath

The ROAST calls the icon **the single highest-leverage featuring asset.** An
editor scanning the Today tab sees the icon before a single word of copy. It is
also the app on the Home Screen forever. This brief is for a commissioned
designer; final art is a separate design commission, not something to
auto-generate.

---

## The one idea

**A single soft dumpling, caught mid-breath.** Plump, warm, a little bit funny,
unmistakably calm. Not a logo. Not a lockup. Not a lungs/wind/leaf cliché. The
mark *is* the product: the thing you hold.

If someone sees only the icon, they should think: *"...is that a little
dumpling? that's adorable"* — and that reaction is the entire top of the
funnel.

## Must-haves

- **One dumpling, centered**, filling ~62–70% of the safe area. Generous
  breathing room — the calm comes from the space around it.
- **Readable at 40 pt.** Test at Home Screen size, Spotlight size, Settings-list
  size, and in a Today-tab grid *first*; design down, not up. If the pleats
  vanish and it's still clearly a friendly dumpling, it works.
- **Soft, physical form.** Subtle top-lit gradient, a gentle contact shadow,
  faint pleats at the crimp. It should look *squeezable* — like it would give
  under a thumb. Matte, not glossy; no hard specular highlight.
- **Warm off-white / pale-gold body** (the dumpling colour already in the app:
  roughly `#FCF5E8` → `#EEDCC2`), on a calm ground that is NOT pure white and
  NOT a loud gradient. A very soft, low-saturation warm neutral or the app's
  Canvas colour.
- **Grayscale-legible.** Convert to grayscale — the dumpling must still read as a
  distinct plump form against the ground. Contrast of form ≥ 3:1 against
  background in luminance.
- **Full bleed, no border, no text, no rounded-rect drawn in** (the system mask
  handles the shape). Deliver square, art to the edges, key content inside the
  ~80% safe circle.

## Nice-to-haves / options to explore

- A whisper of the "breath": the dumpling rendered at ~65% openness (between
  deflated and full) so it reads as *inhaling*, mid-motion, alive — not a static
  blob.
- The faintest ambient glow behind it, as if it's radiating calm — decoration
  only, never the primary read, must survive grayscale.
- A tiny, restrained face is **high risk**: it can tip charming → cutesy → app
  we can't show a stressed adult. If explored, it must be almost subliminal
  (two dots, no mouth) and A/B judged against the faceless version. Default:
  **no face.**

## Avoid

- Lungs, a person in lotus, a wind swirl, a leaf, a water drop, a mandala, a
  breath-ring — every breathing app on the shelf.
- Gradients that shout. Neon. Purple-to-blue wellness gradient.
- A gradient mesh "3D blob" that looks like every 2023 fintech icon.
- Glassy Big Sur bevels, drop shadows *outside* the icon, inner strokes.
- Any text, wordmark, or monogram.
- Photorealism — this is a *character*, it should feel drawn/rendered with
  intent, in the same procedural-but-warm spirit as the in-app dumpling.

## Deliverables

- **1024×1024** master, PNG, sRGB, no alpha (opaque), no rounded corners.
- Platform renditions Xcode 16 asset catalog "single size" generates from the
  1024 for iOS + iPad.
- **watchOS**: a version that survives the circular crop and small sizes — the
  dumpling likely needs to be slightly larger in frame and the ground simpler.
  Deliver a separate 1024 for the Watch appicon set.
- A dark-appearance and a tinted-appearance variant (iOS 18 icon appearances)
  are optional polish — if provided, the tinted version must be a clean single
  grayscale silhouette of the dumpling form.
- Source file (layered — Sketch / Figma / Illustrator / Photoshop).

## Current placeholder status

- `App/Assets.xcassets/AppIcon.appiconset/` — single 1024 "universal / ios"
  slot, **no image file yet** (Contents.json only). Xcode will warn "unassigned
  child" and archive validation will fail until a real `icon-1024.png` is added
  and referenced.
- `Watch/Assets.xcassets/AppIcon.appiconset/` — single 1024 "universal /
  watchos" slot, **no image file yet.**
- **Action:** commission the art from this brief, drop the two 1024 PNGs in, add
  the `"filename"` keys to both `Contents.json` files. Do not ship a
  auto-generated or AI-generated final icon — for this app the icon is the
  featuring pitch.
