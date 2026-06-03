# Phase 0 — Foundation Freeze (Design System) — Contract Plan

**Date:** 2026-06-02 · **Topic:** AI Travel design-system foundation-freeze
**Worktree:** `/Users/shubh/Workspaces/AITravel-app/.claude/worktrees/foundation`
**Scope:** the **design system only** — semantic tokens → modifiers → screen-agnostic components →
composition primitives → design-review → snapshot-lock. This is the one hard barrier (`engineering/05 §10`)
before any Phase 1/2 work. **Explicitly out of scope:** domain models, networking, `AppStore`, screens,
routes, the catalog. No `SampleData`/domain models are introduced; component previews/snapshots use tiny
**local value-type fixtures** declared next to each component.

All paths in this plan are **relative to the worktree root** above. Every task's owning agent is
`swift-design-system` unless it is a snapshot task (`swift-snapshot-test-writer`) or a review pass
(`design-reviewer`).

---

## The product's point of view (so executors don't drift to generic)

This is **AI Travel**, not the library/book slice the docs use for illustration. The live SSOT is
`mockups/foundations/foundations.css` + `mockups/components/components.html`. The earned identity:

- **Type pairing:** Schibsted Grotesk (display) + Hanken Grotesk (UI) + system mono. Embedded + registered
  already (`App/FontRegistry.swift`). The display face carries names/titles/hero numerals **and the one
  editorial italic moment** (the AI voice line); UI carries body/chrome/labels; mono carries
  measurement (times, counts, distances, prices). (T-1, T-7, J-3.1)
- **One accent:** iMessage blue (`--accent-600` action / `--accent-500` now-state). Budget ≤ twice per
  screen, emphasis/state only, never chrome or a fill. (J-0.4, J-2.4)
- **The one signature idea — "definitive vs fuzzy":** a *definitive* place is solid + lifted (white card,
  rest shadow, roman name, exact mono facts); a *fuzzy* place recedes (flat grey surface, italic name,
  lighter ink, a glyph instead of a photo). This register runs through cards, timeline rows, and map pins.
  Components must expose this as a **value-type state arg**, not invent it ad hoc.
- **No gradient fills/text anywhere** (the old version faked the AI voice with an iridescent gradient — the
  replacement is type + restraint). (02-color §5, 08-slop C-1/C-3/A-5)
- **Warm/cool-tinted neutrals are earned**, not the reflexive "tasteful AI cream" (08-slop C-5).

The design-reviewer enforces these as the J-rules + the slop scan; bake them into every contract below.

---

## Wave ordering (the foundation-freeze barrier)

```
WAVE A  Tokens (semantic tier)            ─ all parallel-safe, disjoint new files
            │  (every later wave references these by NAME, never a Primitive.* directly)
            ▼
WAVE B  Modifiers  ‖  Composition primitives   ─ parallel with each other; both depend on Wave A
            │
            ▼
WAVE C  Components                         ─ depend on Wave A tokens + Wave B modifiers
            │
            ▼
WAVE D  Design-review pass (design-reviewer)   ─ token discipline · J-rules · slop scan · craft bar
            │   (blocking: must pass before Wave E records baselines)
            ▼
WAVE E  Snapshot-lock (swift-snapshot-test-writer)  ─ 1 snapshot per component state + per composition-primitive state
            │
            ▼
        ════════════ FREEZE ════════════   no swift-screen-builder runs until E is green + committed
```

**Parallelism / serialization:**
- Every Wave A/B/C task **creates new disjoint files** under `DesignSystem/` — all parallel-safe (the
  `PBXFileSystemSynchronizedRootGroup` means no `.pbxproj` edit, `01-architecture §11`). Dispatch within a
  wave in parallel.
- **One serial edit exists in Wave E:** the shared snapshot helper file
  `AppTemplateTests/Support/DesignSnapshot.swift` (the `canonicalConfig` + `assertDesignSnapshot` +
  `designSystemEnvironment()` wrapper, `07-testing §6.1`). Create it **once, first**, in Wave E; the
  per-component/per-primitive snapshot tasks then run in parallel against it. Flag to the coordinator: the
  helper file is the only serial node in this phase.
- **Never touch:** `ios/AppTemplate/DesignSystem/Tokens/Primitive.generated.swift` (generated — reference
  only from the semantic tier), `ios/AppTemplate.xcodeproj/project.pbxproj`,
  `mockups/foundations/foundations.css`, `App/FontRegistry.swift`, `App/AppTemplateApp.swift`,
  `App/RootView.swift` (leave the placeholder).

---

# WAVE A — Semantic token tiers

Directory: `ios/AppTemplate/DesignSystem/Tokens/`. All enums are **caseless** (`static` members only).
Each maps `Primitive.*` **by role**; a screen/component/modifier references these names, **never** a
`Primitive.*` and **never** a literal (J-0.2, 05 §1). Exemplar to mirror: the shape sketches in
`05-design-system §1, §3, §5, §7` and the role table in `foundations.css` (`--text-*`, `--surface-*`,
`--action-*`, etc., lines 49–76). Governing rule per task noted inline.

## A1 · `Tokens/ColorRole.swift`  (agent: swift-design-system · parallel-safe)

Governing rule: **02-color §2 role vocabulary + J-2** — pick by role, never by ramp stop.

`enum ColorRole` with these static `Color` members, each pointing at the named primitive that the CSS
semantic alias resolves to (the CSS aliases are listed; map to the matching `Primitive.*`):

| Member | → Primitive | CSS source role |
|---|---|---|
| `textPrimary` | `Primitive.ink700` | `--text-primary: var(--ink-700)` |
| `textSecondary` | `Primitive.ink400` | `--text-secondary: var(--ink-400)` |
| `textTertiary` | `Primitive.ink400` | `--text-tertiary: var(--ink-400)` |
| `textOnAccent` | `Primitive.onAccent` | `--text-on-accent: var(--on-accent)` |
| `surfacePage` | `Primitive.paper100` | `--surface-page: var(--paper-100)` |
| `surfaceGrouped` | `Primitive.paper0` | `--surface-grouped: var(--paper-0)` |
| `surfaceElevated` | `Primitive.paper0` | `--surface-elevated: var(--paper-0)` |
| `fillSecondary` | `Primitive.fillSecondary` | `--fill-secondary` |
| `fillTertiary` | `Primitive.fillTertiary` | `--fill-tertiary` |
| `fillQuaternary` | `Primitive.fillQuaternary` | `--fill-quaternary` |
| `separator` | `Primitive.separator` | `--separator` |
| `separatorOpaque` | `Primitive.ink200` | `--separator-opaque: var(--ink-200)` |
| `actionPrimary` | `Primitive.accent600` | `--action-primary: var(--accent-600)` |
| `stateNow` | `Primitive.accent500` | `--state-now: var(--accent-500)` |
| `destructive` | `Primitive.destructive` | `--destructive` |
| `scrim` | `Primitive.scrim` | `--scrim` |
| `dayMark1`…`dayMark4` | `Primitive.day1`…`day4` | `--day-1`…`--day-4` (categorical, state-only) |

Notes the executor must honor:
- **Do not** expose any forbidden role (no `buttonBackground`, no `accentFill`, no gradient role) — the
  system enforces restraint by *omission* (02-color §4, 05 §3). `actionPrimary`/`stateNow` are the only
  accent surfaces; `dayMark*` are categorical *marks*, never fills of size.
- `textTertiary` is placeholder/disabled/past-state only (it does not clear AA at body size) — document
  that in a doc-comment (02-color §6, J-2.3).

**Done-when:** `enum ColorRole` compiles; every member above present and pointing at the stated
`Primitive.*`; zero literals/`Color(...)` constructors in the file (only `Primitive.*` references); no
forbidden roles exposed; doc-comment cites 02-color §2.

## A2 · `Tokens/Typography.swift`  (agent: swift-design-system · parallel-safe)

Governing rule: **01-typography T-0/T-2/T-3 + T-6.1 + J-3** — roles not sizes; every role a Dynamic Type
style; custom faces bound with `relativeTo:`, never `fixedSize`.

`enum Typography` exposing 7 `Font` roles. Each binds `Font.custom(<family>, size: Primitive.type*Size,
relativeTo: <DynamicType style>)` for the custom faces, and `Font.system(...)` for mono. **Family family
names are the registered names** `"Schibsted Grotesk"` (display) and `"Hanken Grotesk"` (UI) — verified by
`FontRegistryTests`. Weight is applied via `.weight(...)` using the `Primitive.weight*` rungs mapped to
`Font.Weight` (regular/medium/semibold/bold). Tracking applied via `.tracking(...)` only where the table
says so (mono caps + display), from the `--track-*` values authored as constants in this file (codegen
skips tracking — author them by hand here; see the values in `foundations.css` lines 139–143).

The precise role → family → text style → weight → tracking table (from `foundations.css` 89–101 +
01-typography T-2):

| Role | Family | size primitive | relativeTo | weight | tracking |
|---|---|---|---|---|---|
| `titleLarge` | Schibsted (display) | `typeTitleLargeSize` (34) | `.largeTitle` | bold (`weightBold`) | `trackDisplay` −0.02em |
| `title` | Schibsted (display) | `typeTitleSize` (22) | `.title2` | semibold (`weightSemibold`) | `trackTight` −0.015em |
| `name` | Schibsted (display) | `typeNameSize` (17) | `.headline` | semibold (`weightSemibold`) | none (system) |
| `body` | Hanken (UI) | `typeBodySize` (17) | `.body` | regular (`weightRegular`) | none (system) |
| `callout` | Hanken (UI) | `typeCalloutSize` (16) | `.callout` | regular | none |
| `subhead` | Hanken (UI) | `typeSubheadSize` (15) | `.subheadline` | regular | none |
| `footnote` | mono (system `.monospaced`) | `typeFootnoteSize` (13) | `.footnote` | regular | none (caps tracking applied by the *caller* of a caps eyebrow, not baked into the role) |
| `caption` | mono (system `.monospaced`) | `typeCaptionSize` (11) | `.caption2` | regular | none |

Author these tracking constants as `private static let` in this file (CGFloat, em→pt is not pre-computed —
use SwiftUI `.tracking` in points relative to size, or expose them as a small `Tracking` helper the eyebrow
caller uses): `trackDisplay`, `trackTight`, `trackCaps` (0.06em for mono caption caps), `trackEyebrow`
(0.085em for short mono eyebrow caps). T-5.2: loose tracking only on short mono-caps eyebrows; body/UI stay
at system tracking — so the role itself does NOT apply caps tracking; a caps eyebrow applies it at the call
site. Document this.

Notes:
- **No `Font.system(size:)` literals, no `fixedSize`** (T-0.1, T-6.1). Mono uses
  `Font.system(.footnote, design: .monospaced)` / `(.caption2, design: .monospaced)` so it scales.
- `name` may use display *or* UI; the mockup (`.pcard .nm`, `.lrow .pri`) uses the display face for place
  names — bind `name` to **display** (Schibsted) per the components mockup. Document the choice.
- A `monospacedDigit` convenience is allowed for inline numerals inside proportional text (T-1.2) but is
  not required; if added, expose it as a `Typography` helper, not a new role.

**Done-when:** `enum Typography` compiles; all 7 roles present with the exact family/size-primitive/
relativeTo/weight from the table; uses `Font.custom(_:size:relativeTo:)` for display/UI and
`Font.system(_:design:.monospaced)` for footnote/caption; zero hardcoded sizes; tracking constants present
and documented as call-site-applied for eyebrows; doc-comment cites T-2/T-6.1.

## A3 · `Tokens/Spacing.swift`  (agent: swift-design-system · parallel-safe)

Governing rule: **03-layout-spacing §1–2 + J-1** — the 6-rung named gap ladder; nothing off the 4/8 grid.

`enum Spacing` (CGFloat statics) mapping the gap ladder by role to the generated primitives:

| Member | → Primitive | px |
|---|---|---|
| `hairline` | `Primitive.gapHairline` | 4 |
| `paired` | `Primitive.gapPaired` | 8 |
| `itemGap` | `Primitive.gapSibling` | 12 |
| `cardInset` | `Primitive.gapCard` | 16 |
| `sectionGap` | `Primitive.gapSection` | 24 |
| `hero` | `Primitive.gapBreath` | 32 |
| `screenInset` | `Primitive.s3` (16) | the standard compact horizontal margin (03 §4) |

Also expose the raw 8pt spine for layout-internal use *only if needed by composition primitives*
(`s1`…`s8` are already primitives; do **not** re-alias them all — only add a named role when a primitive
plays a role). Note for the executor: **`@ScaledMetric` is not used in token enums** — it requires a
`View`/property wrapper context. The token holds the @Large base value; any component metric that must
scale with text wires `@ScaledMetric(relativeTo:)` in the component (see C-tasks; T-6.4). Document this
boundary in the file header.

**Done-when:** `enum Spacing` compiles; the 6 ladder rungs + `screenInset` present pointing at the stated
primitives; no off-ladder numbers introduced; header documents the `@ScaledMetric` boundary; cites J-1.

## A4 · `Tokens/Radius.swift`  (agent: swift-design-system · parallel-safe)

Governing rule: **03-layout-spacing §6 + J-10** — radius is a ladder of meaning; chrome=pill, content=
rounded-rect; cap content at the card rung.

`enum Radius` (CGFloat statics):

| Member | → Primitive | meaning |
|---|---|---|
| `tag` | `Primitive.rTag` (6) | tags, smallest chips |
| `thumb` | `Primitive.rThumb` (8) | thumbnails |
| `row` | `Primitive.rRow` (12) | rows, wells |
| `card` | `Primitive.rCard` (16) | cards, sheets (the cap) |
| `pill` | `Primitive.rPill` (999) | chrome, buttons, chips |

Document: concentric children use `ConcentricRectangle()` / `.rect(corners: .concentric)` with the
**parent** carrying `.containerShape(.rect(cornerRadius: Radius.card))` (03 §5) — do **not** hand-pick an
inner radius. This is a usage note for component authors, not a member.

**Done-when:** `enum Radius` compiles; 5 members present at the stated primitives; header documents the
concentric-children convention and cites J-10.

## A5 · `Tokens/Shadows.swift`  (agent: swift-design-system · parallel-safe)

Governing rule: **03-layout-spacing §9 + J-8.4** — three-tier elevation, hand-authored (codegen skips
compound shadows). One elevation system; never hairline + wide-shadow; glass shadow is the system's.

These three are **NOT in `Primitive.generated.swift`** (compound values are skipped). Author them here by
hand from `foundations.css` lines 122–129. SwiftUI `Color.shadow`/`.shadow(...)` takes a single
color+radius+offset, so each multi-layer CSS shadow maps to a small struct or a `ViewModifier` applying
*ordered* `.shadow(...)` calls. Recommended shape: `enum Shadows` exposing a `ShadowStyle`-like value or a
`func` per tier that a modifier applies. Exact source values to port:

- `rest` (default card lift): layer 1 `color oklch(0.30 0.02 245 / 0.05)`, x0 y1 blur2; layer 2
  `oklch(0.30 0.02 245 / 0.055)`, x0 y4 blur14.
- `hero` (the one elevated/active surface per screen): layer 1 `/0.07` x0 y2 blur6; layer 2 `/0.10` x0 y14
  blur34.
- `glass` (floating chrome only — generally applied by the system; provided here only for the mockup-frost
  parity used in component snapshots, NOT for content): inset highlight `oklch(1 0 0 / 0.55)` 0/0.5/0,
  layer `/0.04` x0 y1 blur1, layer `/0.12` x0 y10 blur28.

Convert each `oklch(...)` to sRGB for `Color` the same way the generator does (the executor may reuse the
`Primitive` color math by eye-matching the ink-tinted shadow to a low-opacity ink — but **the authored
value here is the contract**; record the chosen sRGB in a doc-comment so it is reviewable). Expose:
`enum Shadows { static func rest()/hero()/glass() -> some ... }` OR a `ShadowStyle` per tier — the executor
picks the SwiftUI-idiomatic form and documents it. The **modifier `cardSurface()` (B1) consumes `rest`**;
`hero` is reserved for a single emphasis; `glass` is consumed only by the glass-frost approximation in
snapshots.

**Done-when:** `Shadows` compiles; all three tiers authored from the exact `foundations.css` values with
the sRGB conversions recorded in doc-comments; multi-layer shadows applied in order; header cites
03 §9 / J-8.4 and notes glass elevation is normally the system's job.

## A6 · `Tokens/Motion.swift`  (agent: swift-design-system · parallel-safe)

Governing rule: **04-motion §1–3 + J-9** — one easing personality (critically-damped ease-out); duration
ladder; spring only for direct manipulation; Reduce-Motion halves.

`enum Motion`:
- Durations (Double seconds, from primitives): `tap = Primitive.durTap` (0.10), `standard =
  Primitive.durStandard` (0.22), `sheet = Primitive.durSheet` (0.32), `slow = Primitive.durSlow` (0.42).
- The two easings authored by hand (codegen skipped the cubic-beziers; source `foundations.css` 132–133):
  `standardCurve` = `Animation.timingCurve(0.32, 0.72, 0, 1, duration:)` helper, and `emphCurve` =
  `timingCurve(0.22, 1, 0.36, 1, duration:)`. Expose as `static func standard(_ duration:)` /
  `static func emph(_ duration:)` returning `Animation`, plus a `static let smooth: Animation` (= `.smooth`,
  bounce 0) for direct-manipulation springs (04 §1, §3).
- A `reduced(_ base: Animation, reduceMotion: Bool) -> Animation?` helper that returns `nil` (or a
  cross-fade) under Reduce Motion and halves duration otherwise (§7, §2.2). Document that continuous motion
  goes *static* and springs flatten to a fade — these are caller responsibilities; the token just supplies
  the curves.

Notes: no per-component curves; spring/overshoot forbidden except a single scoped reward (not built in this
phase — no reward component exists yet). `@Animatable`-macro custom animations and `oneShotPulse` are
**deferred** unless a Wave C component needs one (see B3 / open decision OD-2).

**Done-when:** `enum Motion` compiles; 4 durations from primitives; both easings authored from the exact
cubic-bezier values; `standard`/`emph`/`smooth` + `reduced(_:reduceMotion:)` helpers present; header cites
04 §1/§3/§7 and J-9.

---

# WAVE B — Modifiers ‖ Composition primitives

Both waves depend on Wave A tokens. **B-modifiers and B-composition are parallel with each other.**

## B-MODIFIERS — `ios/AppTemplate/DesignSystem/Modifiers/`

Exemplar to mirror: the `CardSurface` skeleton in `05-design-system §7` (private struct + `extension View`
func; consumes semantic tokens; never a primitive/literal). Governing rule per task.

### B1 · `Modifiers/CardSurface.swift`  (agent: swift-design-system · parallel-safe)

Governing rule: **05 §7 + 05-components §3 + J-8** — a content card is solid, one elevation, no glass, no
side-border.

`private struct CardSurface: ViewModifier` + `extension View { func cardSurface() -> some View }`. Body:
`.padding(Spacing.cardInset)` → `.background(ColorRole.surfaceGrouped, in: .rect(cornerRadius: Radius.card))`
→ apply `Shadows.rest()`. Set `.containerShape(.rect(cornerRadius: Radius.card))` so children can go
concentric (03 §5). **No border** by default (the mockup `.pcard` has shadow, no hairline; J-8.4 forbids
hairline+wide-shadow). Optional `fuzzy: Bool` parameter is **not** added here — the definitive/fuzzy
register belongs to the *component* (PlaceCard, C-task), which chooses `surfaceGrouped`+`rest` (definitive)
vs `surfacePage`/flat+no-shadow (fuzzy). Document that.

**Done-when:** compiles; `.cardSurface()` applies inset + `surfaceGrouped` + `Radius.card` + `Shadows.rest`
+ `containerShape`; no glass, no literal, no border; private struct / public func split; cites 05 §7.

### B2 · `Modifiers/GlassChrome.swift`  (agent: swift-design-system · parallel-safe)

Governing rule: **05 §6 + J-0.1/J-8.3 + 05-components §1.1/§7** — glass on **floating chrome only**, system
material, grouped, never glass-on-glass.

`private struct GlassChrome: ViewModifier` + `extension View { func glassChrome() -> some View }`. Body
wraps the **system** `glassEffect()` (iOS 26 SDK) with our defaults; the modifier is intended to be applied
to **bar/overlay containers only**. Also expose helpers/notes the composition primitives consume:
- A `GlassEffectContainer`-based grouping helper or documentation showing the `ActionBar`/bar groups multiple
  glass elements in one container so they blend (05 §6, 05-components §1.1). The ActionBar primitive (B-comp
  C4-equivalent below) uses `.buttonStyle(.glassProminent)` for the CTA and `.glass` for secondary.
- `.glassEffect(.regular.interactive())` only on touch-responsive glass (05-components §1.1).
- Document forbidden use: never on a card/row/sheet-at-rest; never stacked. The design system *enforces*
  glass-on-chrome-only by exposing `glassChrome()` only here and applying it only inside the composition
  primitives (05 §6) — content components must NOT call it.

**Done-when:** compiles against the iOS 26 SDK using the system `glassEffect`/`.buttonStyle(.glass[Prominent])`;
private struct / public func split; doc-comment states floating-chrome-only + GlassEffectContainer grouping +
no-glass-on-glass and cites J-0.1/J-8.3; introduces no hand-rolled translucency.

### B3 · (CONDITIONAL) `Modifiers/OneShotPulse.swift`  (agent: swift-design-system · parallel-safe)

Governing rule: **04-motion §4/§7 + 07-testing §6.4** — one continuous motion max; goes static under Reduce
Motion; snapshot-disable seam.

Build **only if** a Wave C component needs an entrance/now-pulse (the mockup's now-state dot uses a pulsing
ring — `.dot.now` / `.pin.now`). If built: `.oneShotPulse(trigger:)` View extension; reads
`@Environment(\.accessibilityReduceMotion)` (static fade under Reduce Motion, §7) and an injected
`disablesOneShotMotion` environment key (default false) so snapshots settle to rest (07-testing §6.4). Uses
`Motion.smooth`/`Motion.standard`; amplitude small and contained (§4.2). Pair with a static cue at the call
site (§4.3). See **OD-2** — decide whether the now-pulse is in-scope for the foundation or deferred to the
screen that first needs it. Default recommendation: build a **static** now-state ring (no animation) in the
component now; defer the *pulse* to the screen phase to avoid an unanchored continuous motion in the frozen
foundation.

**Done-when (if built):** compiles; respects `accessibilityReduceMotion` + `disablesOneShotMotion`; uses
`Motion.*` only; doc-comment cites 04 §4 and the snapshot-disable seam. **If deferred:** record the deferral
in `docs/decisions.md` and skip the file.

## B-COMPOSITION — `ios/AppTemplate/DesignSystem/Composition/`

Exemplar to mirror: `05-design-system §9` + `01-architecture §8.4` + the chrome-intent table in
`mockups/CLAUDE.md`. These own the **outer chrome / scroll / safe-area + vertical rhythm** so every future
screen composes them instead of hand-wiring `.toolbar`/`.padding`. **They do not know about domain or
AppStore** — chrome intent + content closure in, layout out.

### B-COMP1 · `Composition/ScreenChrome.swift`  (agent: swift-design-system · parallel-safe)

Governing rule: **mockups/CLAUDE.md chrome table + 06-screens §2 (deferred there for usage) + 01-arch §8.4**.

A value type expressing chrome intent the scaffold maps to platform chrome. Define
`enum ScreenChrome` with cases carrying their payloads:
- `.root(title: String)` — a tab's home: large title, no back, tab bar visible.
- `.detail(title: String)` — pushed: inline title + back, tab bar persists.
- `.immersive` — takeover: inline/minimal, **tab bar hidden** (reader/capture/onboarding).
- `.custom` — screen draws its own header (must supply its own back).
- `.sheet(title: String?)` — presented: grabber, no nav bar (a sheet is solid at rest; only the grabber is
  glass — 05-components §6.1).

This is the **type** `ScreenScaffold` consumes. Keep it a small `Sendable` value type. Document the table
inline (it is the contract the fidelity-reviewer checks).

**Done-when:** `enum ScreenChrome` compiles with the 5 intents + payloads; `Sendable`; doc-comment reproduces
the chrome-intent table and cites mockups/CLAUDE.md + 06-screens §2.

### B-COMP2 · `Composition/ScreenScaffold.swift`  (agent: swift-design-system · parallel-safe)

Governing rule: **05 §9 + 01-arch §8.4 + 03 §4 (safe-area/margins) + 04 (scroll-edge under glass)**.

`struct ScreenScaffold<Content: View>: View`. Signature:
`init(_ chrome: ScreenChrome, @ViewBuilder content: () -> Content)` (an optional `actions:`/ActionBar slot
is included — see B-COMP5). Responsibilities:
- Owns the safe-area + a `ScrollView` (vertical) + the standard horizontal inset (`Spacing.screenInset`, via
  `.contentMargins`/`.safeAreaPadding`, never a hardcoded number — 03 §4).
- Maps `ScreenChrome` → platform chrome: `.root` → large-title nav (`.navigationTitle` +
  `.navigationBarTitleDisplayMode(.large)`); `.detail` → inline title + back; `.immersive` → hide tab bar
  (`.toolbar(.hidden, for: .tabBar)`) + minimal title; `.custom` → no system header; `.sheet` →
  `.presentationDragIndicator(.visible)` context (grabber), no nav bar.
- Applies the iOS 26 `scrollEdgeEffectStyle` so content scrolls **under** the glass bars (06-screens §2.1,
  conorluddy). Lets content scroll under glass; does not add custom bar backgrounds
  (`.scrollContentBackground(.hidden)` / `.containerBackground(.clear, for: .navigation)` per 05-components
  §7.1).
- Background is `ColorRole.surfacePage`. **No glass on the scaffold body itself** — glass is only on the
  bars/ActionBar it hosts (J-0.1).
- **No fixed frames** (J-0.3); content drives height.

Note: at this phase there is no `RootView`/`TabView`/`NavigationStack` wiring (that is screens/App). The
scaffold must be **previewable standalone** (wrap in a `NavigationStack` inside `#Preview` only). Document
that the tab-bar visibility modifiers are no-ops outside a `TabView` and become live in the screen phase.

**Done-when:** compiles; generic over content; maps all 5 `ScreenChrome` intents to the stated chrome;
owns scroll + safe-area + `Spacing.screenInset` inset via the guide (no literal margins); applies
`scrollEdgeEffectStyle`; background `surfacePage`; no glass on body; no fixed frames; `#Preview` renders
`.root` and `.detail` variants with placeholder content; cites 05 §9 / 01-arch §8.4.

### B-COMP3 · `Composition/ScreenSection.swift`  (agent: swift-design-system · parallel-safe)

Governing rule: **05 §9 + 03 §2/§3 + J-1/J-4.2** — one shared vertical rhythm; group with space, not
dividers.

`struct ScreenSection<Content: View>: View` — a grouped content block applying the semantic vertical
rhythm. Optional `header: String?` rendered with `Typography.title` (or a mono eyebrow + title per the
mockup `.sec > .head`). Internal vertical gap between children uses `Spacing.itemGap`; the gap from a
section header to its content uses `Spacing.sectionGap`; sections stack at `Spacing.sectionGap`+. Left-
aligned (J-7.1). **Not** `SwiftUI.Section` — a layout primitive (01-arch §8.2 note). No dividers by default
(J-4.2). `internal ≤ external` padding law (03 §3) — document it.

**Done-when:** compiles; generic over content; optional header in `Typography.title`; uses
`Spacing.sectionGap`/`.itemGap` for rhythm (no literals); left-aligned; no default divider; doc-comment
cites J-1/J-4.2 and the internal≤external law.

### B-COMP4 · `Composition/RhythmSpacer.swift`  (agent: swift-design-system · parallel-safe)

Governing rule: **05 §9 + J-1** — vertical gaps come from named rungs only.

A tiny primitive exposing the gap ladder as spacers so screens never type a number:
`struct RhythmSpacer: View { enum Rung { case hairline, paired, sibling, card, section, hero }; init(_ rung:
Rung) }` mapping each rung to the matching `Spacing.*` as a fixed-height `Spacer`/`Color.clear.frame(height:)`
— but height must still allow Dynamic Type rhythm; prefer `Spacer().frame(height: Spacing.<rung>)` (a fixed
*gap*, not a fixed *content* frame — gaps are legal; J-0.3 forbids fixed frames on **text/content
containers**, not on rhythm spacers — document this distinction). Provide a `.fixedSize`-free implementation.

**Done-when:** compiles; the 6 rungs map to `Spacing.*`; no literal heights; doc-comment distinguishes a
legal rhythm gap from a forbidden fixed content frame and cites J-1.

### B-COMP5 · `Composition/ActionBar.swift`  (agent: swift-design-system · parallel-safe)

Governing rule: **05 §9 + 05-components §2 + J-0.1/J-5.1/J-6.1** — thumb-zone glass CTA; one prominent per
region; chrome-thin; floats over content.

`struct ActionBar<Primary: View, Secondary: View>: View` (or value-arg form: a primary CTA label+action +
optional secondary). Renders a glass bar in the bottom thumb zone holding a `.glassProminent` primary
(+ optional `.glass` secondary), grouped in a `GlassEffectContainer` (05-components §2). Consumes
`glassChrome()` semantics from B2. Chrome-thin density (tight vertical padding — J-5.1). Content scrolls
*under* it (the scaffold supplies the scroll-edge effect). Exactly one primary (J-6.1). This is the **only**
content-area place glass appears, and it is *floating chrome*, not content.

Accessibility ids are the **caller's** job (the screen sets `book.borrowButton` etc.) — the ActionBar takes
the label/action as args and does not bake an id, but exposes an `accessibilityIdentifier` passthrough param
so screens can set e.g. `actionbar.primary`. Document.

**Done-when:** compiles; renders a glass `.glassProminent` primary + optional `.glass` secondary in a
`GlassEffectContainer`; chrome-thin padding from `Spacing.*`; one prominent only; exposes an a11y-id
passthrough; doc-comment cites 05-components §2 / J-0.1 / J-6.1.

---

# WAVE C — Screen-agnostic components

Directory: `ios/AppTemplate/DesignSystem/Components/`. **Data in as value-type args; no `AppStore`, no
domain objects** (01-arch §3 layer table; 05 §8). Each component declares a **tiny local value-type
fixture/model** (e.g. `PlaceCardModel`) for its args and previews — **no `SampleData`/domain models exist
yet**. Each consumes Wave A tokens + Wave B modifiers. Inventory **derived by auditing
`mockups/components/components.html`** (9 families) — pair structure, don't reinvent.

Exemplar to mirror: the `BookRow` skeleton in `05-design-system §8`; the anatomy/state tables in
`05-components §1–9`; the matching markup block in `components.html`.

Canonical six states where they apply: *default · pressed · disabled · selected · loading · empty*
(05-components intro). Each component covers its **meaningful** states and is snapshot-locked per state in
Wave E.

### Component inventory (audited from components.html · §01–09)

| # | Component | File | Maps mockup | Key states / variants |
|---|---|---|---|---|
| C1 | `PillButton` (tier-driven content button) | `Components/PillButton.swift` | §01 `.btn` primary/secondary/ghost/destructive | tier (primary/secondary/ghost/destructive) × default/pressed/disabled/loading |
| C2 | `GlassCircleButton` (bar glyph button) | `Components/GlassCircleButton.swift` | §01 `.gbtn` | default/selected; 44pt target; tint conveys meaning only |
| C3 | `PlaceCard` (the definitive/fuzzy card) | `Components/PlaceCard.swift` | §03 `.pcard` / `.pcard.fuzzy` | register: definitive / fuzzy; + loading (redacted) / selected (single mark) |
| C4 | `Tag` (read-only status) | `Components/Tag.swift` | §05 `.tag` | default; optional state-mark variant |
| C5 | `FilterChip` (interactive) | `Components/FilterChip.swift` | §05 `.chip` / `.chip.sel` | default/selected/pressed/disabled; one selected per group (caller) |
| C6 | `TimeHint` (time-conditional hint) | `Components/TimeHint.swift` | §05 `.hint` | default |
| C7 | `TimelineRow` + `TransitConnector` | `Components/TimelineRow.swift` | §04 `.tlstop` / `.tlleg` / `.modes` | register: definitive/fuzzy/now; accessory contract (chevron/switch/inline/check); past=fade not strikethrough; connector: single-mode / multi-leg / ways |
| C8 | `AIVoice` (the italic editorial line) | `Components/AIVoice.swift` | §06 `.ai` | default; one blue dot mark; italic display; **never a gradient** |
| C9 | `MapPin` | `Components/MapPin.swift` | §08 `.pin` def/fuzzy/now | definitive/fuzzy/now |
| C10 | `EmptyStateView` | `Components/EmptyStateView.swift` | §09 `.empty` | glyph + one line + one action |
| C11 | `LoadingSkeleton` (redacted rows) | `Components/LoadingSkeleton.swift` | §09 `.skel` | one shimmer at most; static under Reduce Motion / snapshot-disable |

Notes that apply to all C-tasks:
- **Definitive vs fuzzy is a value-type enum arg** (e.g. `enum PlaceCertainty { case definitive, fuzzy }`),
  not a boolean buried in a view — it is the product's one idea (components.html §03 lede).
- **AIVoice** uses `Typography` display *italic* + a single `ColorRole.stateNow`/`actionPrimary` dot. No
  gradient, no glow (08-slop A-5/C-1/C-3; the explicit replacement for the old iridescent gradient).
- **List rows / cards never glass** (J-0.1). Only C2/C5-in-a-bar contexts touch glass — and C2 is a *bar*
  glyph; if it ever migrates into a glass bar it drops its own glass (J-8.3) — document.
- Accent budget ≤ twice per screen is a *screen* rule; components expose accent only via their
  selected/now/CTA state, never as a fill (J-2.4).
- Tap targets ≥ 44pt on every interactive component via padding (05-components intro; HIG).
- `@ScaledMetric(relativeTo:)` for any non-text metric that must scale (thumbnail size, glyph box, pin
  size) — never a fixed CGFloat (T-6.4).
- Accessibility: combine rows for VoiceOver (`.accessibilityElement(children: .combine)`, 05-components
  §4.2); color-coded state always paired with a glyph/label (never color alone, 02-color §6).
- Each component declares its **local fixture value type** in-file for `#Preview` + the Wave E snapshot.

Per-component governing rule (cite in the file header):

- **C1 PillButton** — 05-components §1 (tier→style, never reverse; shape/size via `buttonBorderShape`/
  `controlSize`, never a fixed frame; label leads with a verb). Uses `Radius.pill`, `ColorRole.actionPrimary`/
  `textOnAccent` (primary), `surfaceGrouped`/fill (secondary), `destructive` (role: .destructive). Press
  ≤100ms via `configuration.isPressed` in a `ButtonStyle` (J-9.1). Loading = inline `ProgressView`, footprint
  stable.
- **C2 GlassCircleButton** — 05-components §1.1. One SF Symbol on `.glass`, `buttonBorderShape(.circle)`,
  44pt; `.tint` only to convey meaning; `.interactive()` allowed.
- **C3 PlaceCard** — 05-components §3 + J-8: `.cardSurface()` (definitive) vs flat `surfacePage`+no-shadow
  (fuzzy); never nested, never side-border, never glass, one elevation; selected = single mark; loading =
  `.redacted(.placeholder)` at same footprint. Concentric photo via `containerShape`.
- **C4 Tag** — 05-components §5: capsule (`Radius.pill`/`.tag`), mono only for a measurement; one accent
  mark or neutral fill, never side-border/gradient; pair color with label.
- **C5 FilterChip** — 05-components §5: capsule; **selected is a solid ink pill, not the accent** (the blue
  stays reserved for action/now — components.html §05 cap); selected pairs color + a check glyph.
- **C6 TimeHint** — 05-components §5 hint; `fillQuaternary` ground, mono numerals.
- **C7 TimelineRow/TransitConnector** — 05-components §4 (accessory = behavior contract; binary inks;
  right-align mono; past=fade not strikethrough) + the §04 rail/connector anatomy; now-state dot is the one
  `stateNow` mark (static ring this phase — see OD-2).
- **C8 AIVoice** — 06-judgment J-3.6 (one editorial italic moment) + 02-color §5 (no gradient); display
  italic line + one small `stateNow` dot + a mono eyebrow label.
- **C9 MapPin** — components.html §08: three registers (definitive ink / fuzzy grey / now blue pulse);
  `@ScaledMetric` size; color + shape (the `~`/`●`/number) so it survives grayscale.
- **C10 EmptyStateView** — 05-components §9 + J-11.6: monochrome glyph + one editorial line
  (`Typography.name`/display) + one action (a `PillButton.secondary`); never a broken-image box; no
  exclamation/alarm copy.
- **C11 LoadingSkeleton** — 05-components §9 + J-9.3: redacted rows at the real footprint, **one** shimmer;
  static under Reduce Motion + `disablesOneShotMotion` (07-testing §6.4).

**Done-when (each C-task):** compiles; takes only value-type args (no AppStore/domain); consumes only Wave
A tokens + Wave B modifiers (zero literals/primitives); covers its listed states/variants; ≥44pt targets on
interactive controls; `@ScaledMetric` for scalable non-text metrics; color-coded state paired with a
glyph/label; declares a local fixture value type; ships a `#Preview` per meaningful state; header cites the
component's governing §; no glass on content components (only C2 touches glass).

---

# WAVE D — Design-review pass (foundation-freeze gate)

Agent: **design-reviewer** (not swift-design-system). **Blocking** — must pass before Wave E records
baselines. Reviews everything in Waves A–C against:

1. **Token discipline (J-0.2):** no literal color/size/spacing and no `Primitive.*` reference anywhere
   outside `Tokens/`; every component/modifier/composition primitive references semantic tokens only.
   `Primitive.generated.swift` untouched.
2. **The J-rules (`06-judgment.md`):** J-0 non-negotiables; J-1 gap ladder; J-2 color roles + accent
   budget; J-3 type discipline (≤ 2 families, role-per-family, display italic only as the one AI-voice
   moment); J-8 surface stacking + glass-on-chrome-only + no glass-on-glass; J-9 one easing, ≤1 continuous
   motion, tap ≤100ms, Reduce Motion; J-10 radius ladder + 1px separators; J-13 craft (hierarchy order,
   whitespace, point of view, finish).
3. **The slop scan (`08-slop.md`):** no side-tab borders (A-1/A-2), no gradient text/fills (A-5/C-1/C-3 —
   especially verify AIVoice is type-not-gradient), no glassmorphism-as-decoration (A-3), no hairline+wide-
   shadow (A-4), no icon-tile-over-heading (B-2), no hero-metric template (D-1), no nested cards (D-4), no
   reflex fonts (B-8 — Schibsted/Hanken are the earned pairing), no cream-default (C-5 — warmth earned), no
   bounce (E-1), no all-caps body (B-10). For each near-tell in *our* system (warm neutrals, expressive
   display face, the blue accent), confirm it is *earned*, not reflexive.
4. **The craft criteria (`05-design-system §11`):** hierarchy size→weight→color→space; whitespace primary;
   typography carries beauty; one accent; concentricity/optical alignment; depth with restraint; disciplined
   motion; rhythm; a point of view; clarity over decoration; finish.
5. **Dynamic Type:** bump to AX5 in previews — no truncation/overlap/clipped containers (T-8.2);
   `@ScaledMetric` present on scalable non-text metrics.

**Done-when:** design-reviewer reports PASS on all five; any flagged item either fixed by the owning
swift-design-system task or logged in `docs/decisions.md` with a written justification. No screen task may be
dispatched until this passes (the FREEZE barrier).

---

# WAVE E — Snapshot-lock

Agent: **swift-snapshot-test-writer**. Directory: `ios/AppTemplateTests/Snapshots/` + the shared support
file. **The lock** (07-testing §6): one render snapshot per component state + per composition-primitive
state, pixel-diffed against a committed baseline. SnapshotTesting 1.19.2 is already linked to
`AppTemplateTests`. Build/test on the **pinned simulator** (iPhone 17 Pro, OS 26.4.1; 07-testing §8).

### E0 · `AppTemplateTests/Support/DesignSnapshot.swift`  (SERIAL — create first)

Mirror the helper in `07-testing §6.1`. Provides:
- `canonicalConfig` — `ViewImageConfig`, iPhone 17 Pro logical frame (393×852, safeArea top 59 / bottom 34,
  light, displayScale 3).
- `assertDesignSnapshot(_:named:…)` — `@MainActor`, hosts the view in `UIHostingController`, forces
  `.light`, asserts `.image(on: canonicalConfig)`.
- `designSystemEnvironment()` — a `View` extension that **registers embedded fonts** (calls
  `FontRegistry.registerEmbeddedFonts()`) and injects `\.disablesOneShotMotion = true` so any entrance/
  shimmer settles to rest (07-testing §6.4). **No `AppStore`/`SampleData` injection** in this phase
  (those don't exist yet) — that line of the doc's helper is deferred to Phase 2; document the deferral.

**Done-when:** compiles; `canonicalConfig` matches §6.1 exactly; `assertDesignSnapshot` + `designSystemEnvironment`
present; fonts registered; `disablesOneShotMotion` injected; no domain/AppStore references; header cites
07-testing §6.1.

### E1…En · Per-component & per-primitive snapshot tasks  (parallel after E0)

One snapshot test file per component family + one per composition primitive, each asserting **every
meaningful state** of that component via `assertDesignSnapshot(…, named: "<state>")` using the component's
local fixture. Baselines land in `AppTemplateTests/Snapshots/__Snapshots__/<TestClassName>/`, are committed
(never `.gitignore`'d), recorded on first run then diffed (07-testing §6.2–6.3). **Never leave `record:
.all` committed.** Render at rest (no `withAnimation`).

Snapshot matrix (one PNG per cell):
- **PillButton:** primary · primary-pressed · primary-disabled · primary-loading · secondary · ghost ·
  destructive.
- **GlassCircleButton:** default · selected. (Render over a representative frosted stage so glass reads —
  see the mockup `.glass-stage`.)
- **PlaceCard:** definitive · fuzzy · selected · loading.
- **Tag:** default · state-mark.
- **FilterChip:** default · selected · disabled.
- **TimeHint:** default.
- **TimelineRow / TransitConnector:** stop-definitive · stop-now · stop-fuzzy · accessory-chevron ·
  accessory-switch · accessory-inline · accessory-check · connector-single · connector-multileg ·
  connector-ways.
- **AIVoice:** default.
- **MapPin:** definitive · fuzzy · now.
- **EmptyStateView:** default.
- **LoadingSkeleton:** default (settled, motion disabled).
- **Composition primitives:** `ScreenScaffold` `.root` · `.detail` · `.immersive` (with placeholder
  content); `ScreenSection` (header + items); `RhythmSpacer` (a representative rung stack); `ActionBar`
  (primary-only · primary+secondary). Render scaffold variants via the `UIHostingController` path so
  safe-area/traits/@3x apply (07-testing §6.1).

**Done-when:** every cell above has a committed baseline PNG under `__Snapshots__/`; all snapshot tests pass
green on a second run (diff, not record); no `record: .all` left in code; suite runs on the pinned simulator
via `xcodebuild … test`; baselines committed in this branch. **This green suite is the FREEZE.**

---

## Task list summary (agent · files · disjoint-or-serial)

| Task | Agent | File(s) created | Parallel? |
|---|---|---|---|
| A1 ColorRole | swift-design-system | `DesignSystem/Tokens/ColorRole.swift` | ✅ |
| A2 Typography | swift-design-system | `DesignSystem/Tokens/Typography.swift` | ✅ |
| A3 Spacing | swift-design-system | `DesignSystem/Tokens/Spacing.swift` | ✅ |
| A4 Radius | swift-design-system | `DesignSystem/Tokens/Radius.swift` | ✅ |
| A5 Shadows | swift-design-system | `DesignSystem/Tokens/Shadows.swift` | ✅ |
| A6 Motion | swift-design-system | `DesignSystem/Tokens/Motion.swift` | ✅ |
| B1 CardSurface | swift-design-system | `DesignSystem/Modifiers/CardSurface.swift` | ✅ (after A) |
| B2 GlassChrome | swift-design-system | `DesignSystem/Modifiers/GlassChrome.swift` | ✅ (after A) |
| B3 OneShotPulse (conditional) | swift-design-system | `DesignSystem/Modifiers/OneShotPulse.swift` | ✅ (after A) · see OD-2 |
| B-COMP1 ScreenChrome | swift-design-system | `DesignSystem/Composition/ScreenChrome.swift` | ✅ (after A) |
| B-COMP2 ScreenScaffold | swift-design-system | `DesignSystem/Composition/ScreenScaffold.swift` | ✅ (after B-COMP1) |
| B-COMP3 ScreenSection | swift-design-system | `DesignSystem/Composition/ScreenSection.swift` | ✅ (after A) |
| B-COMP4 RhythmSpacer | swift-design-system | `DesignSystem/Composition/RhythmSpacer.swift` | ✅ (after A) |
| B-COMP5 ActionBar | swift-design-system | `DesignSystem/Composition/ActionBar.swift` | ✅ (after A + B2) |
| C1–C11 Components | swift-design-system | `DesignSystem/Components/<Name>.swift` (11 files) | ✅ (after A + B) |
| D Design review | design-reviewer | (review only) | blocking gate |
| E0 Snapshot helper | swift-snapshot-test-writer | `AppTemplateTests/Support/DesignSnapshot.swift` | ⛔ serial · first |
| E1…En Snapshots | swift-snapshot-test-writer | `AppTemplateTests/Snapshots/<Name>SnapshotTests.swift` + `__Snapshots__/` | ✅ (after E0) |

**Files never touched:** `DesignSystem/Tokens/Primitive.generated.swift`, `ios/AppTemplate.xcodeproj/
project.pbxproj`, `mockups/foundations/foundations.css`, `App/FontRegistry.swift`, `App/AppTemplateApp.swift`,
`App/RootView.swift`.

---

## Open decisions for the coordinator to settle before / during execution

- **OD-1 — Domain vs template naming.** The docs (`01-architecture`, `02-color`, `06-judgment`) use the
  **library/book** slice for illustration, but the live SSOT (`foundations.css`, `components.html`) is the
  **AI Travel** instantiation (places/days/timeline; Schibsted/Hanken; iMessage-blue; definitive/fuzzy).
  This plan follows the **live SSOT** for component names (`PlaceCard`, `TimelineRow`, `MapPin`, `AIVoice`)
  and the design identity. Confirm the design system should be authored for AI Travel (not the book slice).
  *Recommendation: yes — the CSS + component mockup are the contract; the book references in prose are
  illustrative.*

- **OD-2 — Now-state pulse (continuous motion) in the foundation?** The mockup shows a pulsing now-state
  ring on the timeline dot / map pin (`.dot.now`, `.pin.now`). A continuous motion in a *frozen* foundation
  with no screen to anchor it risks an unowned loop (J-9.3: ≤1 continuous motion *per screen*).
  *Recommendation: build the now-state as a **static** ring in C7/C9 now; defer the `oneShotPulse`/continuous
  pulse (B3) to the screen that first needs it, logged in `docs/decisions.md`.* Confirm or override.

- **OD-3 — `Shadows` SwiftUI shape.** The three elevation tiers are multi-layer CSS shadows; SwiftUI applies
  shadows one at a time. The executor will pick either a `ShadowStyle`-returning API or a per-tier
  `ViewModifier`. Either is acceptable; flag if you want a specific form so `cardSurface()` and the snapshot
  frost stay consistent. *Recommendation: a per-tier modifier that applies the ordered `.shadow(...)` calls.*

- **OD-4 — `name` role family.** `01-typography T-2` allows `name` on display *or* UI; the components mockup
  (`.pcard .nm`, `.lrow .pri`, `.tlstop .pri`) renders place names in the **display** face. This plan binds
  `Typography.name` to **Schibsted (display)**. Confirm (it affects every row/card title).

- **OD-5 — Snapshot helper scope.** `07-testing §6.1`'s `designSystemEnvironment()` injects a
  `SampleData`-seeded `AppStore`; neither exists in Phase 0. This plan has E0 register fonts + inject
  `disablesOneShotMotion` only, deferring the store-seed line to Phase 2. Confirm that component snapshots
  needing no store is acceptable (it is — all Wave C components take value-type fixtures, no AppStore).
