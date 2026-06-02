# The Slop Catalog — AI-generated UI tells to avoid

> Adapted from Paul Bakaus's **Impeccable** — [impeccable.style/slop](https://impeccable.style/slop/)
> and [github.com/pbakaus/impeccable](https://github.com/pbakaus/impeccable). Credit to the original;
> this doc maps the catalog onto our native-iOS / SwiftUI context and our J-rules (`06-judgment.md`).

**What "slop" is.** A set of recognizable patterns that mark an interface as *AI-generated* — not
because any one is forbidden, but because they're the **unexamined defaults** everyone converges on. The
convergence shifts over time (2022 purple gradients → 2024 glassmorphism → 2026 cream + italic-serif
heroes), so this list is a snapshot, not scripture.

**The antidote is a point of view (`J-13.3`).** A tell is slop when it's the thoughtless default; the
same element, chosen deliberately and integrated into a coherent system, is fine. *Warm neutrals, an
expressive display face, a single restrained accent* are in our system **on purpose** — the rule is to
*earn* them, not reach for them because they're the current "tasteful" reflex.

**How to use this.** It's a reviewer checklist (run alongside `J-15`). Each item: the tell → what to do
instead. Several map directly to a J-rule; cite both.

---

## A. Visual details

- **A-1 Side-tab accent border** — a thick colored border on one side of a card. *"The most recognizable
  tell of AI-generated UIs."* → Never. Use space, weight, and one accent mark for emphasis (`J-2.4`).
- **A-2 Rounded card + clashing border accent** — a thick colored border fighting the corner radius. →
  1px `separator` borders only; emphasis from shadow/color, not a heavy colored stroke (`J-10.4`).
- **A-3 Glassmorphism as decoration** — blur/glass/glow borders used because they look "cool," not to
  solve a layering problem. → Glass only on floating chrome, only the system material, only when there's
  a real layer to float (`J-0.1`, `J-8`).
- **A-4 Hairline border + wide diffuse shadow** — the 1px-line-plus-big-soft-shadow combo. → One
  restrained elevation system; a card is *either* a subtle border *or* a rest shadow, not a glowing
  floater (`J-8.4`, `J-10.4`).
- **A-5 Repeating-gradient stripes as surface decoration.** → Surfaces are solid semantic tones; no
  decorative gradients on fills (`J-2`, `J-8`).
- **A-6 Extreme border-radius** — 24px+ on a small card; over-rounding everything. → The radius ladder,
  by role; inner < outer; chrome=pill, content=rounded-rect (`J-10.1–10.3`).
- **A-7 Amateurish hand-drawn SVG** — doodle scenes/mascots. → A coherent, single-weight icon set; a
  monochrome glyph placeholder when an image is absent (`J-12.1`, `J-12.4`).

## B. Typography

- **B-1 Flat hierarchy** — sizes too close together, no clear dominant. → Hierarchy by size→weight→
  color→space; squint and one thing must dominate (`J-13.1`, `J-3.2`).
- **B-2 Icon-tile stacked above a heading** — the small rounded-square icon-container-over-title
  feature-card template. *Universal AI tell.* → Don't default to it; if an icon belongs, integrate it
  inline/with intent, not as the stamped template.
- **B-3 Italic-serif display hero** — *"the universal AI-startup landing-page hero."* **Caution: our
  system uses an expressive display face + one editorial italic moment.** → Keep it to *one* earned
  moment with real typographic care (`J-3.6`); never the generic giant-italic-serif-centered hero.
- **B-4 Hero eyebrow/pill chip over an oversized headline** — tiny tracked uppercase label above a
  display headline. → Eyebrows pair a label with data and don't stack on an oversized hero (`J-11`).
- **B-5 Repeated section kicker labels** — tiny uppercase tracked labels above every section. → Use
  sparingly; not as scaffolding on every block.
- **B-6 Oversized hero headline dominating the viewport.** → The scale is small on purpose; nothing
  marketing-sized on a phone (`J-3.3`).
- **B-7 Crushed letter-spacing** — tracking so tight glyphs lose their shapes. → Tracking is token-paired
  to size; never ad-hoc tightening (`J-3.5`).
- **B-8 Overused fonts** — Inter, Geist, Space Grotesk, Instrument Serif. *They signal "AI default."*
  **Caution: pick a deliberate pairing with a point of view; avoid the reflex faces** (`J-0.5`, `J-13.3`).
- **B-9 Single font for everything.** → A deliberate family-per-role system (display / UI / mono), not
  one face doing all jobs (`J-3.1`).
- **B-10 All-caps body text.** → Caps only for short mono eyebrows; never running prose.

## C. Color & contrast

- **C-1 The AI palette** — purple/violet gradients, cyan-on-dark. *Most recognizable color tell.* → A
  restrained neutral field + one deliberate accent; no signature-violet, no gradient fills (`J-2.4`).
- **C-2 Dark mode with glowing accent shadows.** → We're light-only; even so, colored box-shadow "glows"
  are decoration, not hierarchy (`J-8.4`).
- **C-3 Gradient *text*** — decorative, not meaningful. **Caution: the prior app used AI-gradient text.**
  → Avoid gradient text; if a gradient ever appears it's a tiny intentional mark, never a fill or a
  headline (`J-2.4`).
- **C-4 Gray text on a colored background** — washed out. → Use a role with verified contrast; never gray
  on color (`J-2`, `07-accessibility`).
- **C-5 Cream/beige "tasteful AI" background.** **Caution: our neutral is warm-tinted on purpose.** →
  The warmth must be a *considered* part of a coherent palette, not the reflexive "tasteful" default;
  pair it with real type/space craft so it reads as intent, not template (`J-13.3`).

## D. Layout & space

- **D-1 Hero-metric layout** — big number, small label, three supporting stats, gradient accent.
  *"Used everywhere, trusted nowhere."* → Don't reach for the stat-trio template; design the actual data.
- **D-2 Identical card grids** — same-sized icon+heading+text cards repeated endlessly. → Vary by content
  importance; not every item is an equal card (`J-13.1`).
- **D-3 Monotonous spacing** — the *same* value everywhere. → The **gap ladder**: spacing varies by role
  (hairline/paired/sibling/section/breath), which is rhythm — not one value repeated (`J-1`).
- **D-4 Nested cards** — cards inside cards. → A card lives on the page, never on another card of the same
  tone; group with space (`J-8.1`).
- **D-5 Numbered section markers** — big numerals as section labels (the "editorial scaffold"). → Don't
  default to numbered section chrome.
- **D-6 Line length too long** — over ~80 characters (native: text spilling edge-to-edge on iPad/wide).
  → Constrain measure; respect readable line length.
- **D-7 Content overflowing / clipped popovers** *(web origin)* — native analog: a fixed-height container
  truncating Dynamic-Type text, or a clip hiding a menu. → No fixed frames on text (`J-0.3`); let content
  size.
- **D-8 Cramped padding / text touching the edge** — content flush to the container/viewport edge. →
  Generous, token-based insets; whitespace is the primary tool (`J-13.2`, `J-5`).

## E. Motion

- **E-1 Bounce / elastic easing** — *"feels dated and tacky."* → One critically-damped ease-out; spring
  only as a single scoped reward (`J-9.2`).
- **E-2 Animating layout properties** — width/height/padding/margin (native: animating `frame`/`padding`)
  causes jank. → Animate transforms/opacity; use `matchedGeometryEffect`, not layout thrash.
- **E-3 Gratuitous hover/scale-rotate transforms** *(web origin)* — native analog: scaling/rotating a
  thumbnail on tap for no reason. → Motion explains space or gives feedback; never decoration (`J-9.4`).

## F. Copy

- **F-1 Em-dash overuse** — more than a couple in body copy is an AI cadence tell. → Use sparingly.
- **F-2 Marketing buzzwords** — *streamline, empower, supercharge, world-class, enterprise-grade.* →
  Specific, plain, verb-led copy (`J-11.2`, `J-11.3`).
- **F-3 Aphoristic / manufactured-contrast cadence** — sections landing on a pithy rebuttal. → Say the
  thing; no fortune-cookie cadence.
- **F-4 "Theater" framing** — dismissing something as "just theater." → Avoid the tic.
- *(Also `J-11.5`: no exclamation marks, no emoji, no alarm copy.)*

## G. Imagery

- **G-1 Broken / placeholder image** — empty/missing/placeholder `src` (native: a blank or default
  asset). → A deliberate monochrome glyph placeholder; never a broken-image box (`J-12.4`).

## H. General quality (these are also accessibility — see `07-accessibility`)

- **H-1 Low-contrast text** — below WCAG AA. → Roles carry verified contrast (`J-2`).
- **H-2 Skipped heading levels** — h1→h3 (native: VoiceOver heading order). → Don't skip levels.
- **H-3 Tight line height** — below ~1.3×. → Line-height is a token, comfortable for multi-line.
- **H-4 Tiny body text** — below ~12pt. → Honor the body floor + Dynamic Type (`J-3.4`, `J-0.3`).
- **H-5 Wide letter-spacing on body** — above ~0.05em disrupts character groups. → Tracking paired to
  size; body is normal (`J-3.5`).
- **H-6 Justified text** without hyphenation. → Left-align body (`J-7.1`).

---

## The slop-specific cautions for *our* system

Three of our deliberate choices sit close to current tells — so they must be *earned*, never reflexive:
1. **Warm-tinted neutrals** (C-5) — fine as part of a crafted palette; slop if it's the "tasteful AI"
   default with nothing else considered.
2. **An expressive display face + one editorial italic moment** (B-3, B-8) — fine as a deliberate
   pairing with one earned hero moment; slop if it's the giant-centered-italic-serif startup hero.
3. **Any gradient** (A-5, C-1, C-3) — our system avoids gradient fills/text entirely; if one ever
   appears it is a tiny intentional mark, logged in `decisions.md`.

The test for all three: *would a thoughtful human designer make this exact choice for this exact app, or
is it the move because it's the current default?* If the latter, it's slop (`J-13.3`).
