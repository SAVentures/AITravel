# Layout & Spacing — the grid, the gaps, the shapes

This doc owns the **look** of structure: how far apart things sit, how wide a column reads, what radius a
corner takes, and how surfaces stack into depth. It is the visual-language source for the Swift port in
`ios/docs/engineering/05-design-system.md §5` (which owns the *token names* and the SwiftUI contract) —
authority split: **design-docs decide the numbers and the rules; engineering decides the Swift API.** When
a number here moves, the token regenerates there; neither restates the other.

Spacing is not filler — it is the primary tool for hierarchy and grouping, ahead of borders, boxes, and
color (`J-13.2`). A cramped screen is the first sign of missing craft; an off-grid one is the first sign
of no system. Both are review failures.

Examples use the library/book reference slice (AppTemplate). Replace the domain specifics — the **rules**
carry over to any app.

---

## 1. The grid — 8pt spine, 4pt sub-step

Every spacing value is a multiple of **8pt**; **4pt** is the only legal fine sub-step, reserved for the
tightest pairings (icon-to-label, dense metadata) (Cieden; Apple HIG Layout). The full scale:

```
4 · 8 · 16 · 24 · 32 · 40 · 48 · 56
```

- **8 is the spine.** Aligning to 8 keeps rhythm crisp at @2x/@3x — a value that lands cleanly on the
  pixel grid at both densities (Cieden).
- **4 is the exception, not a habit.** Use it only where 8 would visibly over-separate a unit that should
  read as one thing (a glyph and its label). Two 4pt gaps in a row is usually one 8pt gap mis-divided.
- **Off-grid is a bug.** `10`, `13`, `14`, `18`, `20`*, `22` are tells (`08-slop.md D-3`; `J-1`). The
  sole carve-out is sub-pixel glass edge hairlines.
- **Line height rides the same rhythm.** Keep leading on the 4/8 ladder so baselines snap to the vertical
  grid and paragraphs stack predictably (Cieden) — see `01-typography` for per-style leading.

> \*20pt appears once, legally, as the *larger-width screen margin* (§4). That is a layout-margin guide
> value, not a free spacing rung — don't reach for 20 inside a layout.

---

## 2. The spacing scale — t-shirt rungs, named

There is a fixed scale of gaps/insets; **do not invent a value in between** (`J-1`). Each maps to a
*semantic* t-shirt token — a screen never types the number. (This table is the visual source; the Swift
names live in `engineering/05 §5`.)

| Token | Px | Where it appears | Book example |
|---|---|---|---|
| **xs** | 4 | eyebrow ↔ title; tag ↔ name | the "DUE" mono cap above a book title |
| **sm** | 8 | icon ↔ label in a chip; cover ↔ first text baseline | the shelf glyph and "Reading" in a status chip |
| **md** | 12 | title ↔ subtitle; meta ↔ title within a card | book title ↔ author byline |
| **lg** | 16 | card padding; list-row vertical padding; screen margin | the inset around a book detail card |
| **xl** | 24 | section header ↔ first row; hero ↔ first section | "Due this week" header ↔ first book row |
| **2xl** | 32 | screen hero ↔ first control; sheet inner top | the shelf title ↔ the first section |
| **3xl / 4xl** | 48 / 64 | rare large breaks; floating-chrome clearance | — |

Named **layout roles** sit alongside the scale where a gap is a *role*, not a rung: `screenInset` (the
standard compact horizontal margin) and `chromeClearance` (clearance below floating chrome).
Component-specific insets nest in `Spacing.Component`. Fixed component **dimensions** (widths/heights)
are not spacing — they are `Grid.x(n)` multiples of the 4pt unit (`Sizing`; `engineering/05 §5`).

The scale is what makes two independently-built screens *match*: both pull "the gap after a section
header" from the same token, so both land on 24 (`J-1`). Spacing that **varies by role** is rhythm;
spacing that's the *same value everywhere* is the monotony tell (`08-slop.md D-3`).

---

## 3. Internal ≤ external — the grouping law

The single rule that keeps cards from melting into each other:

> **Padding *inside* an element must be ≤ the gap *separating* it from its siblings.** (Cieden)

A card with **16pt internal padding** needs **≥16pt — commonly 24pt — to the next group.** If the inner
padding ever equals or exceeds the outer gap, two distinct cards read as one block and the hierarchy
collapses. Concretely, on the scale: a `lg` inset (16) surface sits in an `xl` (24) gap. Pull
the inner from a lower rung than the outer and grouping is automatic — no divider, no border needed
(`J-4.2`, `J-13.2`). This is proximity (Gestalt) doing the work that a box would otherwise fake (IxDF).

---

## 4. Screen margins, safe areas, readable measure

**Standard horizontal margin** is **16pt on compact** width, **~20pt on larger** widths (Apple HIG
Layout). Bare `.padding()` applies the 16pt system default; prefer `.padding(.horizontal)` /
`.safeAreaPadding` so the inset tracks the layout-margin guide instead of a hardcoded number (SwiftUI
default padding).

**Safe areas are non-negotiable.** Lay all critical content inside the safe area (Apple HIG;
`safeAreaInsets` docs):
- **Top inset** = status (20pt) + nav (44pt).
- **Bottom inset** = **34pt** for the Face-ID home indicator — reserve it; never paint a control under it.
- Reserve `.ignoresSafeArea()` for an *intentional* full-bleed background only (a hero image), never to
  cheat a few extra points.
- Don't hardcode landscape side insets — they differ by device (Dynamic Island ~59–62pt vs notch
  ~44–50pt); design against the guide (`safeAreaInsets`).

**Scroll-content vs chrome insets.** Shift scrollable content with
`.contentMargins(edge, value, for: .scrollContent)` (keeps the glass bars stationary); move only the
scrollbar with `.scrollIndicators`; use `.safeAreaPadding` when content *and* indicators should shift
together (Swift with Majid — Content margins).

**Readable measure: 50–75 characters.** Running prose past ~75 chars fatigues the eye (Apple HIG
Typography). A 390pt iPhone column at body size already satisfies this — the risk is **iPad and
landscape**, where full-width text runs too long. SwiftUI has no direct `readableContentGuide`
equivalent, so **widen the margin / `safeAreaPadding` on `.regular` horizontalSizeClass** rather than
letting text run edge-to-edge (Apple HIG `readableContentGuide`; Swift with Majid). Text spilling
edge-to-edge on a wide canvas is the line-length tell (`08-slop.md D-6`).

---

## 5. The iOS 26 shape system — Fixed · Capsule · Concentric

Every rounded element is exactly one of three types (WWDC25 356). Picking the right one is most of what
makes corners look *resolved* instead of pinched.

| Type | Radius | Use for | Book example |
|---|---|---|---|
| **Fixed** | a constant value | a standalone shape with no host to relate to | a free-floating cover thumbnail |
| **Capsule** | = half the container height | the system default for controls in touch layouts — buttons, switches, sliders, bars, chips | the "Borrow" pill, a status chip |
| **Concentric** | parent radius − padding | a child nested inside a rounded container | a cover image inside a book card |

**Capsule is the control default.** Sliders, switches, bars, and touch-layout buttons take a capsule
(radius = half height) so they read as floating chrome (WWDC25 356; `J-10.2`).

**Concentric is the craft move.** Nest shapes so **inner radius = outer radius − padding** — an outer
24pt card with 12pt padding yields ~12pt inner corners. **Let the system compute it**; hand-picking the
inner radius produces "pinched" (inner too small) or "flared" (inner too large) corners (WWDC25 356;
nilcoalescing). Wire it in SwiftUI:

- `.containerShape(.rect(cornerRadius: 24))` on the **parent**, then
- `ConcentricRectangle()` (or `.rect(corners: .concentric)`) on the **child**;
- `.concentric(minimum:)` sets a floor so a tiny child never collapses to a square corner;
- `isUniform: true` forces equal corners. The container must conform to `RoundedRectangularShape`
  (nilcoalescing — ConcentricRectangle).

**Where the shape lives changes the choice.** Near a **phone screen edge**, set a *capsule* in with extra
margin so it breathes; near a **window edge** (iPad/Mac), align a *concentric* shape to the window's
corner radius so it nests into the hardware (WWDC25 356). Use `.rect(cornerRadius: .containerConcentric)`
for glass so its corners track the host rather than drifting on a hardcoded radius.

---

## 6. The radius ladder — chrome is pill, content is rounded-rect

Radius is a ladder of *meaning*, not a free dial (`J-10.1`):

```
tag (smallest) → thumbnail (small) → row/well (medium) → card/sheet (large) → chrome (pill)
```

- **Chrome = pill; content = rounded-rect** (`J-10.2`). A pill *floats* (the action bar, a chip); a
  rounded-rect is *anchored* (a card, a row). A pill-shaped card reads as a giant chip; a rounded-rect
  tab bar reads as a panel — both wrong.
- **When radii meet, the outer is larger** (`J-10.3`) — which is exactly §5's concentric rule
  (inner = outer − padding). The inner corner looks tighter *on purpose* so the eye reads the container.
- **Cap content radius at the `card` rung.** Extreme radii — **24px+ on a small card** — read as
  AI-generated (`08-slop.md A-6`); full-pill is for tags/buttons only, never a content surface.
- **Borders are 1px `separator`, full stop.** Emphasis comes from shadow or color, never a thicker stroke
  and never a colored side-tab border (`J-10.4`; `08-slop.md A-1/A-2`).

---

## 7. Optical over mathematical — center by eye

Pixel-equal insets are the *start*, not the answer. When a shape's visual mass is asymmetric, trust the
eye over the math (WWDC25 356; `J-7.4`):

- A play triangle in a circular button sits **~1px right** of true-center to *look* centered.
- A leading glyph in a meta row aligns on the lowercase **x-height**, not the geometric box middle
  (`J-7.3`).
- Two-up header rows sit on the **title's baseline**, not box-center.

Center mathematically, then **nudge optically where the eye demands it.** This is the pro/amateur tell —
it is what makes a layout feel resolved (`J-7.4`; `engineering/05 §11.5`).

---

## 8. Hierarchy & whitespace — the order of power

Establish hierarchy in a fixed order of strength: **size → weight → space → color** (Toptal; Pimp my
Type; `J-13.1`). Reach for **space before color, and color last.** Two corollaries for this doc:

- **Whitespace is the primary tool, not leftover.** Generosity confers importance and calm; **density is
  the default failure mode** (IxDF; NN/g; `J-13.2`). Tune *micro* space (label-to-field, line spacing)
  and *macro* space (between sections) separately. On a small screen, separate groups with **whitespace,
  not dividers** (NN/g; `J-4.2`).
- **Proximity encodes grouping.** A section title's gap to its content must be *smaller* than the gap to
  the next section — adjust spacing before adding a border or a box (IxDF; §3). Run the **squint test**: at
  a blur, the real groups should hold together and one element should dominate; if the intended primary
  disappears, fix size/weight/spacing — don't add color (NN/g; `J-15.1`).
- **Padding is generous but honest.** Over-padding makes content disappear into white as surely as
  cramping crowds it (`J-5.2`). Density is scoped to surface: thin for chrome, generous for content, never
  mixed on one surface (`J-5.3`).

---

## 9. Depth — one restrained elevation system

Surfaces stack additively: **three solid tones, one glass** (`J-8`). Depth expresses *hierarchy*, never
decoration (`J-8.4`).

| Layer | What | Rule |
|---|---|---|
| **Rest shadow** | a card lifted off the page | the default card elevation; subtle, not a glow |
| **Hero shadow** | the one elevated/active surface | reserved for a single emphasis per screen |
| **Glass shadow** | floating chrome (bars, sheet handle, map chip) | the system Liquid Glass material only |

- **A card lives on the page, never on another card of the same tone** — an elevated card on an equal
  surface is invisible; group with space and the section, not a third surface (`J-8.1`; `08-slop.md D-4`).
- **Never the hairline + wide-diffuse-shadow combo.** A surface is *either* a defined 1px edge *or* a soft
  rest shadow — not a glowing floater (`08-slop.md A-4`; `J-8.4`).
- **Emphasis is shadow or color, not a heavy border** (`J-10.4`). Reaching for a heavier shadow means the
  card actually wants to be a sheet.
- **Glass is floating chrome only** — never on a card, row, or sheet-at-rest, and never glass-on-glass
  (`J-0.1`, `J-8.2/8.3`). Tokenized in `engineering/05 §6`.

---

## 10. The quick check (layout slice of `J-15`)

Run on any screen before review:

1. **On grid?** Every gap a multiple of 8 (or a deliberate 4); nothing at 10/13/14/18/22. (§1, `J-1`)
2. **On the ladder?** Each gap pulled from a named rung, not eyeballed. (§2)
3. **Internal ≤ external?** Card padding ≤ the gap to the next group. (§3)
4. **Margins & safe areas?** 16/20pt margin; content clear of the 34pt home indicator; full-bleed only by
   intent. (§4)
5. **Measure?** Body 50–75 chars; widened on iPad/landscape, not edge-to-edge. (§4)
6. **Shapes?** Chrome = capsule/pill, content = concentric rounded-rect (inner = outer − padding); no
   24px+ content radius. (§5, §6)
7. **Optical?** Asymmetric marks nudged by eye; glyphs on x-height, rows on baseline. (§7)
8. **Whitespace doing the work?** Groups read by proximity; nothing cramped; one thing dominates at a
   squint. (§8)
9. **Depth restrained?** One elevation system; no card-on-card, no hairline+wide-shadow, no glass-on-
   glass. (§9)

Any fail → fix before review.

---

## See also

- `06-judgment.md` — the J-rules: `J-1` (gap ladder), `J-4` (dividers vs space), `J-5` (density),
  `J-7` (alignment & concentricity), `J-8` (surface stacking & depth), `J-10` (borders & radii),
  `J-13` (craft).
- `08-slop.md` — the layout tells to steer around: `A-1/A-2` (side-tab/clashing borders), `A-4`
  (hairline + wide shadow), `A-6` (extreme radius), `D-3` (monotonous spacing), `D-4` (nested cards),
  `D-6` (long measure), `D-8` (cramped padding).
- `01-typography` — leading/line-height on the same 4/8 rhythm; readable measure at body size.
- `02-color` — the surface/separator roles this doc stacks; emphasis-by-color is *last* in the order of
  power (§8).
- `05-components` — per-component anatomy (the radii and insets each component takes).
- `ios/docs/engineering/05-design-system.md §5` — the Swift port: semantic `Spacing`/`Radius`/`Shadow`
  tokens, no fixed frames, composition primitives (`ScreenScaffold`/`ScreenSection`/`RhythmSpacer`).
- WWDC25 356 *Get to know the new design system* — the Fixed/Capsule/Concentric shape system (§5).
