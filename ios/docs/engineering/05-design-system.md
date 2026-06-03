# 05 — Design System

The SwiftUI port of the design system. It **owns every style rule**; screens only compose what it
exposes. This is the layer the prior app got wrong — its UI drifted from the mockups and diverged
screen-to-screen — so this doc is also the **foundation-freeze gate** (§10): the design system is built,
reviewed, and snapshot-locked *before any feature screen is scaffolded*.

Two root causes from the prior app, and their fixes (the spine of this doc):
1. **No semantic layer** — screens referenced raw primitives (`Space.s4`, `inkIndigo`) and picked
   values by eye. → A **three-tier token system** where screens reference *semantic* tokens only (§1).
2. **Dynamic Type ignored** — fixed-pt fonts and fixed frames. → **Dynamic Type is a hard rule** (§4).

The directory is `ios/AppTemplate/DesignSystem/` with four subtrees — `Tokens/`, `Modifiers/`,
`Components/`, `Composition/`. Appearance *values* are owned by `mockups/` + `docs/design-docs/`; this
doc owns the *Swift contract* that ports them.

---

## 1. The three-tier token architecture (the core fix)

| Tier | Holds | Authored | Referenced by |
|---|---|---|---|
| **Primitive** | raw values — `ink900`, `space4 = 16`, `radiusLg = 18` | **generated** from `foundations.css` (§2) | semantic tier only |
| **Semantic** | *intent* — `textPrimary → ink900`, `surface → paper0`, `xl → spaceXl` | hand-authored Swift | screens, components, modifiers |
| **Component** | a component's own value — a nested `Component` band of the category matching its property (§1.1) | hand-authored, *sparingly* | that one component |

```swift
// Tokens/Primitive.generated.swift   (generated — do not edit)
enum Primitive {
    static let ink900 = Color(/* oklch(0.23 0.02 265) */)
    static let paper0 = Color(/* oklch(0.99 0.005 80) */)
    static let space4: CGFloat = 16
}

// Tokens/ColorRole.swift   (hand-authored — intent, not value)
enum ColorRole {
    static let textPrimary   = Primitive.ink900
    static let surface       = Primitive.paper0
    static let actionPrimary = Primitive.indigo500   // the CTA / link color
}

// Tokens/Spacing.swift   (t-shirt scale)
enum Spacing { static let md = Primitive.spaceMd; static let xl = Primitive.spaceXl }
```

> **The one rule that prevents inconsistency:** screens, components, and modifiers reference **semantic
> tokens only** — never a primitive, never a literal. A primitive appearing outside the semantic tier is
> a review failure. This is what stops two screens from picking `s3` vs `s4` for "the same gap": the gap
> has a *name* (`xl`), decided once.

Naming is **role, not value**: `textPrimary` not `inkIndigo`; `surface` not `paper0`; `actionPrimary`
not `indigo500`. A rebrand or a future dark mode is then a re-point of the semantic tier, not a
find-and-replace across screens. Token enums are **caseless** (`static` members, no instances).

### 1.1 Where a value goes — property → category, with a `Component` band

A value's home is one question: **what property is it?** → that category file. Within a category:

- **Semantic roles** sit flat at the top (`Radius.card`, `Spacing.xl`, `Stroke.separator`).
- **Component-specific values** nest in an `enum Component` band — added only when a real component
  needs one, never pre-created empty.

```swift
enum Spacing {                          // the t-shirt gap/padding scale (§5)
    static let md = Primitive.spaceMd   // 12 — title ↔ subtitle
    static let xl = Primitive.spaceXl   // 24 — section header ↔ content
    enum Component { static let timelineNowRing = Primitive.spaceSm }  // one component's inset
}

enum Sizing {                           // component DIMENSIONS — Grid multiples, not primitives (§5)
    static let dot = Grid.x(2)          // 8  — shared indicator-dot diameter
    enum Component { static let baseMapHeight = Grid.x(46) }  // 184 — one component's fixed size
}
```

This kills the "do I invent a tier?" question: corner radius → `Radius`, border width → `Stroke`,
inset/gap → `Spacing`, **fixed width/height/diameter → `Sizing`**. A `Sizing` value is a `Grid.x(n)`
multiple of the 4pt unit (bounded, on-grid, never a bespoke primitive — §5), not a foundations token;
shared sizes (`dot`, `minTapTarget`) stay flat, single-component sizes nest in `Sizing.Component`.

### 1.2 The category map

| Category | Property | Semantic examples | Component values |
|---|---|---|---|
| `ColorRole` | color | `textPrimary`, `actionPrimary` | rare → `Component` |
| `Typography` | text style | `body`, `title`, `caption` | rare → `Component` |
| `Spacing` | gaps / insets | t-shirt scale `xs…4xl` + `screenInset`, `chromeClearance` | `Component` |
| `Radius` | corner radius | `tag`→`pill` ladder | `Component` |
| `Stroke` | border width | `separator`, `selected` | `Component` |
| `Sizing` | fixed dimension | `Grid.x(n)` multiples — `dot`, `minTapTarget` (shared) | `Component` (single-component) |
| `Shadows` | elevation | `rest` / `hero` / `glass` | `Component` |
| `Motion` | duration / easing | duration ladder + easings | `Component` |

### 1.3 Dark mode is a token swap — the seam

No dark mode today (light-only by decision). The architecture keeps it a clean future swap: because
views reference **semantic tokens only**, `ColorRole` is the single point that changes. Adding dark
later = a `[data-theme]` block in `foundations.css` → codegen emits a theme-keyed primitive set →
`ColorRole` resolves by environment instead of `static let`. No screen, component, or other token tier
moves. Nothing to do now beyond keeping the no-primitives-in-views rule green.

---

## 2. Token codegen — drift-free primitives

`mockups/foundations/foundations.css` is the **single source of truth** for raw values. The prior app
drifted because an engineer re-transcribed those values into Swift *by eye*. v2 removes that step:

- A script (`ios/Tools/generate-tokens.swift`, run at foundation-freeze) parses `foundations.css` and
  emits `Tokens/Primitive.generated.swift` — colors (`oklch()` → `Color`), spacing, radii, shadows,
  motion durations. **The generated file is committed and never hand-edited.**
- When a value changes in `foundations.css`, regenerate and commit in the **same** commit — code and
  spec move together.
- The **semantic and component tiers stay hand-authored** — they are design *intent* (which primitive
  plays which role), not transcription, so codegen would buy nothing there.

This replaces the old token-parity *test* (removed in `07-testing.md`): there is nothing to drift
because nothing is transcribed. The render snapshot still locks the *rendered* result (§10).

---

## 3. Color

- **Primitives (generated):** the neutral ramps, the accent(s), and any gradient stops, ported from the
  CSS `oklch()` values. Never referenced directly.
- **Semantic roles (hand-authored):** `textPrimary` · `textSecondary` · `surface` · `surfaceElevated`
  · `separator` · `actionPrimary` · plus app-specific state roles. A role exists for every *use*, so a
  screen never reaches for a primitive.
- **Contrast is a role property:** text-on-surface roles clear **WCAG AA (≥ 4.5:1)**; any deliberate
  carve-out (e.g. a decorative gradient mark that can't meet AA) is documented in
  `docs/design-docs/` and confined to a non-text role. Contrast is verified by the accessibility audit
  (`07-testing.md §7.4`), not a color-math test.
- **App-specific accent rules** (e.g. "accent X is for state, not chrome"; "the gradient is
  edges-and-marks only") are declared per-app in `CLAUDE.md`'s non-negotiables and `docs/design-docs/`;
  the design system *enforces* them by simply **not exposing** a forbidden role (there is no
  `buttonBackground = gradient` token to misuse).
- **Light-mode only** today; the semantic layer is what would make dark mode a token-set swap later.

---

## 4. Typography — Dynamic Type first

The prior app used fixed-pt sizes, which break Dynamic Type. **Every text style scales.**

- **Three families**, each mapped to a *semantic role*, never a raw size: a display family (titles,
  hero numerals), a UI family (body, chrome), a mono family (numbers, timestamps, code-ish captions).
- **Semantic type roles** — `Typography.titleLarge`, `.title`, `.body`, `.callout`, `.caption`,
  `.mono` — each backed by a **Dynamic Type text style** (`Font.system(_:design:)` relative styles, or a
  custom font registered to a `UIFont.TextStyle` so it scales). No `\.font(.system(size: 17))` literals.
- For custom one-off metrics that must scale with text, use **`@ScaledMetric`**, never a fixed `CGFloat`.
- `FontRegistry.registerEmbeddedFonts()` registers the variable fonts at launch (`01-architecture.md
  §4`); a missing font falls back to the system equivalent of the same role.

---

## 5. Spacing, radius, shadow, motion

- **Primitives (generated):** a `4pt` spacing grid, the radius set, the shadow set, motion durations +
  easing curves — straight from `foundations.css`.
- **Semantic:** `Spacing.xl` / `.md` / `.screenInset` (a **t-shirt** scale `xs…4xl` + named layout
  roles); `Radius.card` / `.control`; `Shadow.card`; `Motion.fast` / `.base` / `.long` with a shared
  **critically-damped** easing.
- **Dimensions via `Grid`, not literals.** Sizing comes from content + Dynamic Type + semantic spacing;
  a hardcoded `.frame(width:220,height:48)` is a review failure (it breaks at large text sizes). Prefer
  min/ideal sizing and let content drive height. When a component genuinely needs a *fixed* dimension it
  is a **`Grid.x(n)`** multiple of the 4pt unit (`Sizing` / `Sizing.Component`) — bounded + on-grid,
  never a bespoke primitive or literal.
- Custom animations use the **`@Animatable` macro** (iOS 26) to synthesize `animatableData`; motion
  reads `Motion.*` tokens and respects **Reduce Motion**.

---

## 6. The glass layer — Liquid Glass (system material)

Glass is the **iOS 26 system material** — we build *on* it, never reinvent it.

- One modifier, **`.glassChrome()`**, wraps the system `glassEffect()` (and `.buttonStyle(.glass)` /
  `.glassProminent` for buttons) with our rules; related glass surfaces are grouped in a
  **`GlassEffectContainer`** so they blend and morph correctly (glass can't sample glass). Native
  controls get Liquid Glass for free by building against the iOS 26 SDK.
- **Glass on floating chrome only** — tab bar, top bar, the `ActionBar`, a sheet handle, a map overlay
  chip. **Never on content** (cards, list rows, sheets-at-rest, anything holding primary input). This is
  a non-negotiable; the design system enforces it by exposing `.glassChrome()` only on the composition
  primitives, not on content components.
- **Restraint:** glass is an accent for the navigation layer, not a texture for the whole UI.

---

## 7. Modifiers

Reusable `ViewModifier`s exposed via a `View` extension, consuming **semantic tokens**:

```swift
private struct CardSurface: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(Spacing.lg)
            .background(ColorRole.surfaceElevated, in: .rect(cornerRadius: Radius.card))
            .shadow(Shadow.card)
    }
}
extension View { func cardSurface() -> some View { modifier(CardSurface()) } }
```

Call sites read `.cardSurface()`, `.glassChrome()`, `.oneShotPulse(trigger:)`. The struct is private;
the `func` is the API. A modifier never reaches a primitive or a literal.

---

## 8. Components

Screen-agnostic `View`s in `Components/` — **data in as arguments, no `AppStore` access**, consuming
semantic tokens + modifiers. They are the vocabulary screens compose:

```swift
struct BookRow: View {
    let model: BookRowModel                    // a value type; no domain object, no store
    var body: some View {
        HStack(spacing: Spacing.md) {
            CoverThumbnail(model.cover)
            VStack(alignment: .leading) {
                Text(model.title).font(Typography.body).foregroundStyle(ColorRole.textPrimary)
                Text(model.byline).font(Typography.caption).foregroundStyle(ColorRole.textSecondary)
            }
            if model.isBorrowed { BorrowedBadge() }
        }
    }
}
```

A component covers its key states (`.available` / `.borrowed` / `.reading`) and ships a render snapshot
per state (§10, `07-testing.md §6`). The component inventory pairs with `mockups/components/` — copy the
markup's structure, don't reinvent. Promote a screen subview to a component only when a *second* screen
needs it (`06-screens.md §1`).

---

## 9. Composition primitives (the shell)

`Composition/` holds the primitives that carry the chrome and the macro-rhythm — **`ScreenScaffold`,
`ScreenSection`, `RhythmSpacer`, `ActionBar`**. They are *defined here*; their *usage rules* (chrome
intent, tab-bar/top-bar behavior, sheet-vs-push) are `06-screens.md §2`.

- `ScreenScaffold(_ chrome:actions:)` maps the `ScreenChrome` intent (`.root`/`.detail`/`.immersive`/
  `.custom`) to platform chrome, owns the safe-area + `ScrollView` + standard inset + the iOS 26
  `scrollEdgeEffectStyle` under the glass bars, and renders the optional `ActionBar` in the thumb zone.
- `ScreenSection` / `RhythmSpacer` apply the semantic spacing so every screen shares one rhythm.
- `ActionBar` uses `.glassChrome()` + `.buttonStyle(.glassProminent)` for the reachable CTA.

These primitives are *the* anti-divergence mechanism: a screen composes them and gets correct chrome,
spacing, and glass for free, instead of hand-wiring `.toolbar`/`.padding`.

---

## 10. The foundation-freeze gate — build it right, then lock

The design system is **Phase 0**: authored, reviewed, and snapshot-locked **before any feature screen is
allowed to scaffold**. The `foundation-freeze` skill is the hard barrier — no `swift-screen-builder`
runs until it passes. Order:

```
codegen primitives (from foundations.css)
  → hand-author semantic + component tokens
  → modifiers
  → components (each with its state render snapshots)
  → composition primitives (ScreenScaffold/ScreenSection/RhythmSpacer/ActionBar)
  → review (design-reviewer: semantic-only discipline, Dynamic Type, glass-on-chrome-only)
  → snapshot suite green
  → FREEZE ─────────────────────────────────  then, and only then, feature screens
```

This is gate #1 of the four quality gates (with the fidelity-reviewer for screens, `06-screens.md §9`).
It exists because the prior app built screens on a half-formed system and inherited a shaky base
everywhere. Freezing the foundation first means every screen ports onto something solid and consistent —
"build it right the first time, and it's locked."

---

## 11. Beauty is craft, not tokens — the criteria the gate enforces

Everything above buys **consistency**. None of it buys **beauty** — a perfectly tokenized app is still
generic. The prior app's UI read as slop partly because it had no craft bar beyond "uses the tokens."
These are the craft criteria the **design-reviewer** checks at foundation-freeze and the
**fidelity-reviewer** checks per screen (`06-screens.md §9`). The prescriptive, example-rich version is
the job of `docs/design-docs/` (the visual-judgment docs); this is the engineering-side checklist.

1. **Hierarchy in order of power: size → weight → color → whitespace.** Reach for type scale before
   color or decoration. If two things look equally important, the design hasn't decided.
2. **Whitespace is the primary tool, not leftover space.** Be generous; emptiness confers importance and
   calm. **Density is the default failure** — a cramped screen is the first sign of missing craft.
3. **Typography carries the beauty.** A tight, role-based type scale (§4), deliberate line-height and
   tracking, and *few* styles per screen. Most "beautiful iOS app" praise is really praise of type.
4. **One accent, used sparingly.** Color is emphasis; spread thin across a screen it's noise. A
   restrained neutral field + a signature accent.
5. **Concentricity & optical alignment.** Nested shapes share a center; a control's corner radius
   relates to its container's (`Radius.control` < `Radius.card`). Center mathematically, then **nudge
   optically** where the eye demands (a leading glyph, a play triangle). This is the pro/amateur tell.
6. **Depth with restraint.** Shadow/blur/glass express hierarchy, never decoration; glass on the
   floating nav layer only (§6). One elevation system, used consistently.
7. **Motion: alive but disciplined.** ≤100ms tap feedback (the press commits before any animation),
   critically-damped easing (never bouncy unless deliberate), transitions that explain spatial
   relationships, **at most one continuous motion** on screen. Respect Reduce Motion.
8. **Rhythm as punctuation.** Consistent semantic spacing groups what belongs together and paces the
   scroll; a screen should feel calm and predictable as it moves.
9. **A point of view (the anti-slop rule).** The app must *say something* — a deliberate type pairing, a
   signature color, a signature motion — not generic system-font + system-blue + defaults. In 2026,
   beauty is "decisions only a human would make"; templated sameness is the failure mode. The reference
   slice ships with an opinionated identity precisely so screens inherit one rather than defaulting.
10. **Clarity over decoration.** Ask "does this reduce effort?", not "how do we make it exciting?" Don't
    decorate data; honest, legible structure beats ornament.
11. **Finish.** The last 10% — icon weight, corner concentricity, a considered empty state, one
    delightful interaction — is what separates "fine" from "beautiful." Budget for it; it is not optional
    polish, it is the bar (the Apple Design Award standard).

12. **No AI-slop tells.** Run the slop catalog (`docs/design-docs/08-slop.md`) — no side-tab borders,
    gradient text/fills, glassmorphism-as-decoration, icon-tile-over-heading, hero-metric templates,
    reflex fonts, or em-dash/buzzword copy. A flagged element is only allowed if a *thoughtful human
    would pick it for this app* — not because it's the current default. Our warm neutrals, expressive
    display face, and any gradient sit near tells and must be **earned**.

> **Why this is in the engineering doc:** the four quality gates can verify token discipline and mockup
> fidelity mechanically, but beauty needs *judgment*. These criteria make that judgment explicit and
> reviewable so "make it beautiful" isn't left to chance — it's the foundation-freeze's pass/fail bar,
> the same way the snapshot is the lock. The full prescriptive rules are `docs/design-docs/06-judgment.md`
> (the J-rules) and `08-slop.md` (the anti-slop catalog).

---

## See also

- `mockups/foundations/foundations.css` — the SSOT for primitive values (codegen input)
- `mockups/components/` — the component inventory this layer ports
- `docs/design-docs/` — the prescriptive visual language + app-specific color/accent rules
- `06-screens.md` §2 — usage rules for the composition primitives defined here
- `07-testing.md` §6 — render snapshots (the lock); §7.4 — the accessibility/contrast audit
- `01-architecture.md` §3 — the DesignSystem layer's place; §6 — view-modifier/component conventions
