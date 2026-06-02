# Color — semantic roles, one accent, verified contrast

Color in this system is never a value you pick at a call site; it is a **role** you reference. The
palette is a restrained neutral field — warm-tinted neutrals built on a perceptually-uniform ramp — plus
exactly one accent reserved for emphasis and state. This doc owns the *look*: the role vocabulary, the
ramp construction, the restraint budget, and the contrast bar. The Swift port (the three-tier token enums,
codegen from `foundations.css`) is `ios/docs/engineering/05-design-system.md §3`; don't restate it here.

Examples use the library/book reference slice. The **roles** carry over to any app; swap the accent hue
and the domain state colors.

---

## 1. Map every color to a role, never an RGB

Every color a screen touches is a **semantic role** (`textPrimary`, `surface`, `actionPrimary`), centralized
so one edit re-themes the app — never a raw hex or `Color(red:…)` at a call site (Apple HIG Color /
ColorTokensKit). A literal color in a view is a review failure (J-0.2). This is also what makes a future
dark mode a token swap rather than a rewrite (§7).

Prefer **Apple's dynamic system colors** wherever a role has a faithful system analog — `Color.primary`,
`.secondary`, `Color(.systemBackground)`, `Color.accentColor` — so accessibility settings (Increase
Contrast, Smart Invert) and light/dark adapt for free; hardcoded colors break that (Apple HIG Color / Apple
Color docs). Where the system color doesn't carry the warm tint the system needs, the role points at a
generated warm-tinted primitive instead (§3). The role name is the contract either way; the call site never
knows which.

---

## 2. The role vocabulary

Four role groups: **text**, **background/surface**, **fill** (overlays), and **separator**. Pick by role,
never by "a darker grey" (J-2).

### Text — a four-step label hierarchy

Apple's label hierarchy is semi-transparent so it composites over any background; mirror it rather than
inventing custom greys (Apple UIKit / Sarunw dark-color cheat sheet).

| Role | System analog | Used on | Never on |
|---|---|---|---|
| `textPrimary` | `Color.primary` / `.label` | titles, names, primary numerals | meta, captions, dividers |
| `textSecondary` | `Color.secondary` / `.secondaryLabel` | meta lines, sub copy, captions | titles, active CTAs |
| `textTertiary` | `.tertiaryLabel` | placeholder, disabled, past-state | active body text (fails AA at body size) |
| `textQuaternary` | `.quaternaryLabel` | faintest scaffolding (rare) | anything that must be read |

Body is **binary**: `textPrimary` for the name, `textSecondary` for the rest — there is no third body ink
(J-2.2). Headings are always `textPrimary` (J-2.1).

### Background / surface — by layout, not by taste

Choose the grouped set for inset/grouped lists, the plain set otherwise; reserve the *secondary/elevated*
step for cards and cells (contagious.dev / Apple UIKit).

| Role | Plain analog | Grouped analog | Used on |
|---|---|---|---|
| `surfacePage` | `.systemBackground` | `.systemGroupedBackground` | the page ground |
| `surfaceGrouped` | `.secondarySystemBackground` | `.secondarySystemGroupedBackground` | cards, cells, wells |
| `surfaceElevated` | `.tertiarySystemBackground` | `.tertiarySystemGroupedBackground` | nested surfaces (use sparingly) |

A card lives on the page, never on another card of the same tone (J-8.1) — don't reach past
`surfaceGrouped` to fake depth.

### Fill — translucent overlays sized by shape

Fills are **not** backgrounds: they are translucent overlays that tint the surface beneath, sized by the
shape they fill (Apple UIKit). Use them for UI-element grounds (input wells, segmented controls), not for
page or card surfaces.

| Role | System analog | Sized for |
|---|---|---|
| `fillSecondary` | `.secondarySystemFill` | medium shapes — a switch ground |
| `fillTertiary` | `.tertiarySystemFill` | large shapes — input fields, search bars, plain buttons |
| `fillQuaternary` | `.quaternarySystemFill` | large complex areas — a grouped backing behind controls |

### Separator — semi-transparent vs opaque

Two separator roles, chosen by the surface (Apple UIKit / Sarunw):

| Role | System analog | Use when |
|---|---|---|
| `separator` | `.separator` (semi-transparent) | over layered/translucent context; the default hairline |
| `opaqueSeparator` | `.opaqueSeparator` (fully opaque) | over an opaque surface where translucency reads muddy |

Both are 1px, one color, emphasis from space not thickness (J-4.3, J-10.4). Draw a separator only when the
structure is real (J-4.1); space first (J-4.2).

### Accent + state

| Role | Used on | Never on |
|---|---|---|
| `actionPrimary` | the one CTA, links, focus ring | body text, decorative fills |
| state roles (e.g. `stateDue`, `stateReading`) | a status mark, a now/selected dot | chrome, button backgrounds, error fills |

---

## 3. Build the ramps in OKLCH, tint the neutrals low

**Ramps are OKLCH/LCH so equal numeric steps look equal.** OKLCH is perceptually uniform — equal `L` reads
equally bright across hues — and avoids CIELab's blue-to-purple hue drift; it's what CSS Color 4, Tailwind
v4, and ColorTokensKit use (ColorTokensKit / LogRocket OKLCH / color-ramp.com). Generate a multi-stop ramp
per hue (ColorTokensKit emits 20 stops, `_50` near-white → `_1000` near-black, with semantic accessors that
resolve the right stop per mode) rather than hand-picking shades (ColorTokensKit-Swift). These ramps are the
**primitives**, generated from `foundations.css` and never referenced directly (`05-design-system.md §1–2`).

**Tint the neutrals toward the accent hue, but keep the chroma low — `~0.005–0.01` OKLCH** (incluud
color-contrast-checker / Rampa). A pure-neutral grey clashes against a tinted accent; a whisper of the
accent hue in the greys makes the whole field harmonize while the neutrals still read as neutral. Two
ramps:

- **Ink ramp** (text/separators): low chroma `~0.01` at the accent hue, from near-black to mid-grey.
- **Paper ramp** (surfaces): even lower chroma `~0.005`, at a *warmer* hue than the ink, so paper reads warm
  and ink reads cool-neutral against it.

Never pure white or pure black — use the warm-tinted ends of the ramps; `#fff` is clinical against a warm
system (J-2.5). The warmth is **earned, not the reflexive "tasteful AI cream"** default (C-5 in `08-slop.md`)
— it pairs with real type and space craft, logged as intent in `decisions.md`.

### Book-domain palette sketch (illustrative)

The accent is **one deliberate hue chosen for the app**, not system blue and emphatically not the reflex
violet (C-1). For the library slice, a warm brass / aged-ink accent:

```
accent      oklch(0.55 0.12 75)    brass — actionPrimary (CTA, links, focus)
ink ramp    oklch(L 0.01 270)      cool-neutral text/separators  (L: 0.22 → 0.55)
paper ramp  oklch(L 0.005 85)      warm surfaces                 (L: 0.985 → 0.93)
state.due   oklch(0.60 0.14 35)    terracotta — "due soon" mark (state only)
state.read  oklch(0.58 0.09 150)   sage — "currently reading" mark (state only)
```

Roles then point at stops: `textPrimary → ink_900`, `textSecondary → ink_600`, `surfacePage → paper_50`,
`surfaceGrouped → paper_100`, `actionPrimary → accent_500`. Values are illustrative — the SSOT is
`foundations.css`; this sketch shows the *shape* (one accent, low-chroma tinted neutrals, state hues kept
off chrome).

---

## 4. One accent, ≤ 4 colors — the restraint rule

Practice restraint: one accent used **sparingly** to mark key actions, a near-monochromatic field of one
hue's tinted neutrals, and the whole palette capped at **≤ 4 colors** (Altamira / Envato / Apple HIG
accentColor).

- **Set the accent once**, globally, via the asset-catalog `AccentColor` (or `.tint`) so controls inherit
  it app-wide; don't overload it per-screen (Apple "Specifying color scheme" / Apple accentColor).
- **The accent has a budget: at most twice per screen** — e.g. the primary CTA + one selected/now mark
  (J-2.4, J-6.4). A third appearance over-claims; the accent becomes the room instead of a presence in it.
- **The accent is emphasis/state, never chrome or a decorative card fill** (J-0.4, J-2.4). State hues
  (due/reading) are state marks only — never a button background, never an error fill.
- **At most three inks in one row** — name, meta, one state mark (J-2.3). More is a chart, not a row.

The design system *enforces* this by **not exposing** a forbidden role: there is no `buttonBackground =
gradient` and no `accentFill = card` token to misuse (`05-design-system.md §3`).

---

## 5. No gradient fills, no gradient text

Gradients are the most recognizable AI color tell — purple/violet gradients, cyan-on-dark, and decorative
gradient *text* (C-1, C-3, A-5 in `08-slop.md`; J-13.6). This system **avoids gradient fills and gradient
text entirely**:

- Surfaces are **solid semantic tones**; no repeating-gradient stripes, no gradient card grounds (J-2, J-8).
- **No `LinearGradient` on a button or card**, and no `background-clip: text` gradient headline — solid
  text colors only, because gradient text kills scannability (`08-slop.md` B/C).
- If a gradient ever appears it is a **tiny intentional mark**, never a fill or a headline, and it is logged
  in `decisions.md` with a written reason — never reflexive (`08-slop.md` final section).

---

## 6. Contrast — WCAG AA with margin, and never color-alone

Every text-on-surface and accent-on-surface pairing meets **WCAG AA**: **4.5:1 for body**, **3:1 for large
text** (≥ 18pt regular or ≥ 14pt bold); **aim for ~5:1** to leave margin against hex/rounding drift (AAA is
7:1) (Ethan Gardner / LogRocket OKLCH / WCAG). System colors (`.primary`/`.secondary`) pass AA in light
mode; **measure every custom ink-on-paper and accent-on-paper pair** before shipping (Apple HIG / David
Auerbach).

- `textTertiary` is for placeholder/disabled/past-state only — it does **not** clear AA at body size, so it
  never carries active text (J-2.3 table).
- A deliberate carve-out that can't meet AA (e.g. a decorative non-text mark) is confined to a non-text role
  and documented (`05-design-system.md §3`).

**Never color-alone.** Color-coded state is always paired with a second cue — a glyph, a label, a shape, or
a position — so it survives color-blindness, Reduce Transparency, and grayscale (Apple HIG Accessibility /
Color; full treatment in `07-accessibility`). "Due soon" is the terracotta mark **plus** a clock glyph and
a "Due Jun 1" label, never the color alone (J-11). Color is information, not the only channel.

**Gray-on-color is banned** (C-4) — washed grey body on a tinted ground fails AA; use a role with verified
contrast (white/near-white or a darker shade of the same hue), never grey on color.

---

## 7. Dark mode is deferred — the semantic layer is the swap

The app is **light-mode only today**. The point of the role vocabulary (§2) and the system-color mappings
(§1) is that dark mode becomes a **token swap, not a rewrite**: re-point each semantic role at the dark
end of its ramp (and let the dynamic system colors flip themselves) and the screens follow untouched
(`05-design-system.md §3`). The elevation rule for later: in dark mode you **elevate by getting lighter**,
not by inverting — iOS uses a darker base and lighter elevated surfaces and swaps automatically below
full-screen size (contagious.dev / Medium Dark Mode). We don't design the dark values now; we keep the
seam clean.

---

## 8. Verify pairings in tests, not by eye

Gate token pairs programmatically rather than eyeballing them. ColorTokensKit's
`contrastRatio(to:method:)` supports both **WCAG 2.x** (1–21) and **APCA** (signed `Lc`); assert that
every text/accent role clears its AA threshold on its intended surface (ColorTokensKit-Swift). In this
system that check lives in the accessibility audit, not a separate color-math test (`05-design-system.md §3`;
`07-accessibility`). When a role's primitive moves in `foundations.css`, the regenerated tokens and the
contrast assertions move in the **same commit** — code and spec together.

---

## See also

- `01-typography` — the families and sizes these inks render
- `03-layout-spacing` — surfaces, radii, and the shapes fills sit in
- `06-judgment` — J-2 (color roles, accent budget), J-13.6 (slop), J-0.4 (one accent)
- `08-slop` — the color tells (C-1 violet, C-3 gradient text, C-4 gray-on-color, C-5 cream)
- `07-accessibility` — contrast specifics, never-color-alone, Increase Contrast
- `ios/docs/engineering/05-design-system.md §3` — the Swift port (three-tier tokens, codegen)
