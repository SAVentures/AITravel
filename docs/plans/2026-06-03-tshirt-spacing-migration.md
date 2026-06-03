# Plan — Migrate `Spacing` to a t-shirt scale (foundation-wide) + fold in component tokenization

**Date:** 2026-06-03 · **Worktree:** `tokenize-components` · **Author:** ios-plan-writer
**Executed via:** `ios-subagent-development` skill (the main-loop coordinator dispatches the `swift-*` agents).

A foundation-wide refactor that **replaces the role-named gap ladder** (`Spacing.hairline / paired /
itemGap / cardInset / sectionGap / hero` + the layout aliases `screenInset` / `chromeClearance`) with a
**conventional t-shirt scale** (`xs / sm / md / lg / xl / 2xl / 3xl / 4xl`), **value-preserving** (no pixel
changes), and **folds the migration into the same per-file pass** that finishes the in-flight
component-literal tokenization (plan `2026-06-03-tokenize-component-library.md`).

This **supersedes the role-ladder framing** chosen in `2026-06-03-token-foundation-design.md` §5 — that
design recommended option (a) "keep role names". The user has since chosen option (b): migrate to t-shirt
as the primary API (conventional, discoverable, first-saas-aligned). This plan executes (b) without
re-litigating it.

> **Two streams, one pass.** The component-tokenization plan's Phase-0 tokens (`Sizing.minTapTarget`, the
> `Sizing.Component` / `Stroke.Component` / `Spacing.Component` bands, the skeleton bars) are **already
> applied** to the in-flight `Sizing.swift` / `Grid.swift` / `Primitive.generated.swift` / `foundations.css`
> in this worktree. What is **not** yet applied is the per-component `@ScaledMetric` *reseed* in the ~16
> component files. This plan's Phase 2 does **both** per file: (1) reseed the component's literal
> `@ScaledMetric` seeds per that plan's audit table, AND (2) migrate its `Spacing.role` call-sites to
> t-shirt. One pass per file, disjoint, parallel.

---

## The t-shirt scale (DECIDED — value-preserving)

```
xs  = 4      sm  = 8      md  = 12     lg  = 16
xl  = 24     2xl = 32     3xl = 48     4xl = 64
```

Value-preserving mapping of today's role members (every px value is identical before/after):

| Today's role | px | → t-shirt |
|---|---|---|
| `hairline` | 4 | `xs` |
| `paired` | 8 | `sm` |
| `itemGap` | 12 | `md` |
| `cardInset` | 16 | `lg` |
| `sectionGap` | 24 | `xl` |
| `hero` | 32 | `2xl` |
| `screenInset` | 16 | `lg` *(kept as a named layout alias → `lg`; see R-A)* |
| `chromeClearance` | 64 | `4xl` *(kept as a named layout alias → `4xl`; see R-A)* |

`3xl = 48` is **new** (no role member mapped to it today; it fills the scale and is available going
forward). All eight rungs are on the 8pt spine except `xs / md` (the legal 4pt sub-steps, 03 §1).

### R-A — KEEP `screenInset` and `chromeClearance` as named layout aliases (RECOMMENDED, ratify at GATE 0)

`screenInset` (the compact horizontal screen margin, 03 §4) and `chromeClearance` (the floating-glyph
clearance band) are **layout roles**, not rhythm rungs — they were *already* exempt from the gap ladder
(see `Spacing.swift` MARK comments + the 2026-06-03 decisions entry). They carry meaning a bare `lg` /
`4xl` would lose at the call-site (`.contentMargins(.horizontal, Spacing.screenInset)` reads as intent;
`Spacing.lg` reads as a number). **Recommendation:** keep both as flat named members that now *alias the
t-shirt rung* (`screenInset = Spacing.lg`, ``chromeClearance = Spacing.`4xl` ``) instead of a primitive. Their
~49 call-sites then **do not change** (only their definition repoints). This keeps churn down and preserves
the layout-role vocabulary the docs justify.

If the design-reviewer instead wants a pure t-shirt API with no layout aliases, the fallback is to migrate
`screenInset → Spacing.lg` (44 sites) and `chromeClearance → Spacing.4xl` (5 sites) too and delete the
aliases. **Recommend the alias-keeping path; ratify at GATE 0** and record the call in the decisions entry.

> Note `2xl / 3xl / 4xl` REQUIRE backtick escaping in Swift (a digit-leading identifier): declare them
> ``static let `2xl` = Primitive.space2xl`` and reference at call-sites as ``Spacing.`2xl` ``. VERIFIED to
> compile and resolve (`swiftc` round-trip: ``Spacing.`2xl` == 32``). The codegen emits the *unescaped*
> `Primitive.space2xl` (that identifier starts with `space`, so no escaping there). The `Spacing.swift`
> sketch below already uses the backtick form. Fallback names if ever desired: `xxl / xxxl / xxxxl` — but
> the backtick t-shirt forms are the spec and are confirmed to compile.

---

## Foundations / codegen structure (the decided shape)

**Constraint:** `Grid.swift` uses `Primitive.s1` (4) — that primitive (and the whole `--s-1…--s-8`
numeric scale, which `Grid.x(n)` conceptually mirrors as `calc(var(--s-1)*n)`) **MUST survive untouched**.
Do **not** renumber `--s-*` — `Grid` depends on `s1`, and the `--s-*` block is the documented dimension
spine.

**Decision — introduce a dedicated t-shirt primitive set; do NOT overload `--s-*`.** The `--s-*` scale has
no `12` rung and no `64` rung (it is `4,8,16,24,32,40,48,56`), so the t-shirt scale cannot be a thin alias
over it without gaps. The clean expression is a **named t-shirt primitive block** that the codegen maps
1:1 to `Primitive.space*`, with `Spacing.swift` aliasing those by t-shirt name:

### foundations.css — the SPACING block, after (exact)

Replace the current gap-ladder + `--space-chrome-clear` lines (keep `--s-1…--s-8` exactly as they are):

```css
  /* ── SPACING ─ 8pt spine · 4pt sub-step ───────────────────────────────────*/
  --s-1: 4px;  --s-2: 8px;  --s-3: 16px; --s-4: 24px;
  --s-5: 32px; --s-6: 40px; --s-7: 48px; --s-8: 56px;
  /* (the --s-* scale is the DIMENSION spine — Grid.x(n) = calc(var(--s-1)*n); do not renumber.) */

  /* t-shirt spacing scale — the named gap/inset API (03 §2; J-1). Pull a rung, never a raw number. */
  --space-xs:   4px;   /* tightest pairing: eyebrow ↔ title              */
  --space-sm:   8px;   /* icon ↔ label; cover ↔ first baseline           */
  --space-md:  12px;   /* sibling: title ↔ subtitle                      */
  --space-lg:  16px;   /* card padding / row inset; the screen margin    */
  --space-xl:  24px;   /* section header ↔ content; the between-group gap */
  --space-2xl: 32px;   /* hero ↔ first control; the widest breath        */
  --space-3xl: 48px;   /* reserved larger breath (no role mapped today)  */
  --space-4xl: 64px;   /* chrome-clearance band below the floating glyph */
```

**REMOVED from foundations.css:** `--gap-hairline`, `--gap-paired`, `--gap-sibling`, `--gap-card`,
`--gap-section`, `--gap-breath`, `--space-chrome-clear` (7 vars). The two `Spacing.Component` ring insets
already route to `--space-*`? — **no**, they currently route to `Primitive.gapPaired` in `Spacing.swift`.
Since `--gap-paired` is being removed, **repoint** `Spacing.Component.timelineNowRing` /
`.baseMapHomeRing` to `Spacing.sm` (= 8, value-preserving) — see Phase 0 (T0-C).

> The two new `--space-timeline-now-ring` / `--space-base-map-home-ring` vars the component-tokenize plan
> proposed were **not** added to this worktree's foundations.css (the in-flight `Spacing.swift` aliases the
> ring insets to `Primitive.gapPaired`). This plan keeps them aliasing the scale (now `Spacing.sm`), so no
> new component-ring vars are introduced — one fewer primitive than that plan assumed.

### Regenerated `Primitive.generated.swift` — the spacing delta

Run the codegen (**never hand-edit**): `swift .claude/scripts/generate-tokens.swift`.

- **ADDED (8):** `spaceXs=4`, `spaceSm=8`, `spaceMd=12`, `spaceLg=16`, `spaceXl=24`, `space2xl=32`,
  `space3xl=48`, `space4xl=64`.
- **REMOVED (7):** `gapHairline`, `gapPaired`, `gapSibling`, `gapCard`, `gapSection`, `gapBreath`,
  `spaceChromeClear`.
- **UNCHANGED:** `s1…s8` (Grid depends on `s1`), every color / type / radius / stroke / motion member.

Net primitive delta in the generated file: **+8 / −7 = +1 length member** (plus member-order shuffle within
the lengths block — expected; the diff must show only spacing-block churn, nothing in colors/type/radius/
stroke/motion).

---

## The Spacing / Sizing boundary (clarified — do NOT blur)

Keep the established split (J-0.2; the in-flight `Sizing.swift` header already states it):

- **`Spacing` = gaps / insets / padding / the screen margin / ring insets** → the **t-shirt** API.
- **`Sizing` = element DIMENSIONS** (width / height / diameter) → `Grid.x(n)` multiples, flat shared roles +
  `Component` band.

So a `dot` *diameter* stays `Sizing.dot` (8) — it is **not** rewritten to `Spacing.sm` even though both are
8. A `VStack(spacing:)` or `.padding()` is `Spacing`. A `.frame(width:height:)` is `Sizing`. The
component-tokenize Phase-2 reseed routes **dimensions → Sizing/Stroke**; the spacing migration routes
**gaps → t-shirt Spacing**. They never cross.

---

## `Spacing.swift` — the full t-shirt definition (Phase 0 contract)

The complete rewritten file (header trimmed per the comment-trim policy; the executor reconciles exact
wording against live source — this is the binding interface, not a code-style mandate):

```swift
// Spacing.swift — the SEMANTIC spacing tier: the t-shirt gap/inset scale (03-layout-spacing §2; J-1).
// Every gap/inset is a named rung (xs…4xl) — never a literal, raw Primitive.*, or off-grid number
// (J-0.2/J-1). The shared scale is what makes two screens land on the same rhythm. `screenInset` /
// `chromeClearance` are named LAYOUT aliases onto the scale (03 §4). `Component` = single-component spacing.
// @ScaledMetric boundary (T-6.4): these are plain CGFloats; a component that must scale wires
// @ScaledMetric(relativeTo:) itself off this @Large base.
import SwiftUI

enum Spacing {

    // MARK: - The t-shirt scale (03-layout-spacing §2, J-1)

    static let xs   = Primitive.spaceXs    // 4  — tightest pairing: eyebrow ↔ title
    static let sm   = Primitive.spaceSm    // 8  — icon ↔ label; cover ↔ first baseline
    static let md   = Primitive.spaceMd    // 12 — sibling: title ↔ subtitle
    static let lg   = Primitive.spaceLg    // 16 — card padding / row inset
    static let xl   = Primitive.spaceXl    // 24 — section header ↔ content (between-group)
    static let `2xl` = Primitive.space2xl  // 32 — hero ↔ first control (widest breath)
    static let `3xl` = Primitive.space3xl  // 48 — reserved larger breath
    static let `4xl` = Primitive.space4xl  // 64

    // MARK: - Named layout aliases onto the scale (03 §4) — kept for call-site intent (R-A)

    /// 16 — standard compact horizontal screen margin. Prefer wiring via .contentMargins/.safeAreaPadding.
    static let screenInset = lg
    /// 64 — clearance band below the floating ×/back glyph so content clears it at rest.
    static let chromeClearance = `4xl`

    // MARK: - Component spacing — single-component ring insets (gaps beyond a mark, not strokes)

    enum Component {
        static let timelineNowRing = Spacing.sm   // 8 — TimelineRow now-ring halo inset beyond the dot
        static let baseMapHomeRing = Spacing.sm   // 8 — BaseMapCard home-marker halo inset beyond the marker
    }
}
```

> SKETCH — the executor reconciles the backtick-escaping and the exact comment wording against live source
> and the first build. Binding facts: the eight scale members + their primitive sources; `screenInset` /
> `chromeClearance` alias `lg` / `4xl`; `Component.*` ring insets repoint to `Spacing.sm` (was
> `Primitive.gapPaired`). All values are preserved.

---

## Phase ordering — foundation-freeze barrier explicit, build green at every gate

```
Phase 0  FOUNDATION (serial — shared/codegen/token files)
  T0-A  foundations.css: add the 8 --space-* t-shirt vars; remove the 7 gap/chrome-clear vars      [serial, 1 file]
  T0-B  regenerate Primitive.generated.swift via the codegen script ONLY                            [serial, depends on T0-A]
  T0-C  Spacing.swift: add t-shirt members + layout aliases + DEPRECATED forwarding role aliases    [serial, 1 file]
        + repoint Spacing.Component ring insets to Spacing.sm
  ───────────────────────────────────────────────────────────────────────────────────────────────
  GATE 0  build clean (ENTIRE app still compiles — role aliases forward) + design-reviewer FREEZE
          (t-shirt scale value-preserving; aliases R-A ratified; no orphan band; codegen round-trips)
  ───────────────────────────────────────────────────────────────────────────────────────────────
        ── no Phase 2 per-file pass is dispatched until GATE 0 passes ──

Phase 2  PER-FILE PASSES (parallel — disjoint files)
  Each task = one component/composition/modifier/screen file. It does BOTH:
    (a) migrate that file's Spacing.role call-sites → t-shirt (value-preserving)
    (b) reseed that file's @ScaledMetric/literal seeds per the component-tokenize audit table
    (c) trim that file's comments per the comment-trim policy
  No two tasks touch the same file. No Tokens/ file is edited here. Test files migrated in T2-TESTS batch.

Phase 2.5  DELETE the deprecated role aliases (serial, Spacing.swift) — grep-confirm ZERO references
  ───────────────────────────────────────────────────────────────────────────────────────────────
  GATE 2.5  build clean WITHOUT the role aliases → the migration is provably complete
  ───────────────────────────────────────────────────────────────────────────────────────────────

Phase 3  GATE — build + functional + re-record snapshots + reviews + docs
```

### Why forwarding aliases (the build-green strategy — RECOMMENDED)

Migrating the scale in Phase 0 while ~257 call-sites still say `Spacing.cardInset` would break the build
between Phase 0 and Phase 2. To keep **every gate green**, T0-C **adds the t-shirt members and KEEPS the six
role members as `@available(*, deprecated)` forwarding aliases**:

```swift
@available(*, deprecated, renamed: "lg") static let cardInset = lg   // (and the other five)
```

- After Phase 0: app compiles (old call-sites resolve through the deprecated aliases, emitting warnings).
- Phase 2 migrates call-sites file-by-file; each migrated file's warnings clear.
- **Phase 2.5 deletes the six deprecated aliases**; if any reference remains the build fails — that is the
  proof of completeness (belt-and-braces with a grep gate).

`screenInset` / `chromeClearance` are **not** deprecated (R-A keeps them as live layout aliases).

> Alternative (NOT recommended): treat Phase 0+2 as one atomic non-building stretch (no deprecated aliases,
> migrate everything before the first build). Rejected — it forfeits the GATE-0 freeze (you cannot
> design-review a non-compiling foundation) and a per-file build signal. Use the forwarding-alias path.

---

## Phase 0 — task list (serial; coordinator runs T0-A → T0-B → T0-C in order)

| # | Agent | Reads | Writes | Never touch |
|---|---|---|---|---|
| **T0-A** | `swift-design-system` | this plan, `mockups/foundations/foundations.css`, mockups/CLAUDE.md token contract, 03 §1–2 | `mockups/foundations/foundations.css` (add 8 `--space-*`, remove 7 vars) | `Primitive.generated.swift`, any Swift |
| **T0-B** | `swift-design-system` | codegen invocation (mockups/CLAUDE.md) | `ios/AppTemplate/DesignSystem/Tokens/Primitive.generated.swift` (script ONLY) | foundations.css (done), by-hand edits |
| **T0-C** | `swift-design-system` | `05 §1.1–1.3`, the new primitives, `Spacing.swift`, decisions 2026-06-03 | `ios/AppTemplate/DesignSystem/Tokens/Spacing.swift` | components, screens, `Primitive.generated.swift` |

**Exemplar to mirror:** the existing `Spacing.swift` (member-with-citation comment shape) and `Sizing.swift`
(the flat-vs-`Component` convention).

**T0-C Done-when:**
- 8 t-shirt members present (`xs…4xl`), each aliasing the matching `Primitive.space*`, values per the table.
- `screenInset = lg`, `chromeClearance = 4xl` live (not deprecated).
- 6 role members (`hairline/paired/itemGap/cardInset/sectionGap/hero`) present as
  `@available(*, deprecated, renamed:)` forwarding aliases onto the t-shirt member.
- `Spacing.Component.timelineNowRing` / `.baseMapHomeRing` repointed to `Spacing.sm` (no `Primitive.gap*`).
- No reference to `Primitive.gap*` or `Primitive.spaceChromeClear` remains anywhere (they no longer exist).

**GATE 0 Done-when:** full build clean (deprecation **warnings** expected at the un-migrated call-sites — not
errors); diff of `Primitive.generated.swift` shows only the spacing-block delta (+8/−7); design-reviewer
freezes (value-preserving confirmed; R-A ratified; `2xl/3xl/4xl` member names compile).

---

## Phase 2 — per-file migration table (parallel; disjoint files)

Each task migrates the file's `Spacing.role` call-sites with the **value-preserving** swap below, AND (where
the file appears in the component-tokenize audit) reseeds its `@ScaledMetric`/literal dimension seeds per
`2026-06-03-tokenize-component-library.md` (the audit table + coordinator rulings R-1/R-2/R-3), AND trims
comments. Agent: `swift-design-system` (screens: still `swift-design-system` here, as these are
DS-internal spacing edits — no screen logic/route changes).

**The universal swap (apply in every file):**
`hairline→xs · paired→sm · itemGap→md · cardInset→lg · sectionGap→xl · hero→2xl`.
`screenInset` / `chromeClearance` call-sites are **left as-is** (R-A keeps the named aliases).

Counts below are non-comment code call-sites of the six MIGRATED roles (the `screenInset`/`chromeClearance`
columns are shown for context but are NOT changed). The "reseed" column lists the component-tokenize work
folded into the same pass (per that plan's audit; dimensions → Sizing/Stroke).

### Source files — DesignSystem/Components

| # | File | Migrate (role → t-shirt) | Reseed (literal → Sizing/Stroke) |
|---|---|---|---|
| T2-01 | `Components/DayStepper.swift` | hairline×2→xs, itemGap×1→md, cardInset×3→lg | 44 → `Sizing.minTapTarget` |
| T2-02 | `Components/FilterChip.swift` | paired×4→sm, cardInset×2→lg, sectionGap×1→xl | 44 → `Sizing.minTapTarget` |
| T2-03 | `Components/GlassCircleButton.swift` | paired×1→sm, itemGap×1→md, cardInset×1→lg | 44 → `Sizing.minTapTarget` |
| T2-04 | `Components/PillButton.swift` | paired×2→sm, itemGap×1→md, sectionGap×1→xl | 44 → `Sizing.minTapTarget` (keep the 2 token-padding seeds) |
| T2-05 | `Components/SegmentedSelector.swift` | hairline×2→xs, paired×2→sm, itemGap×1→md, cardInset×3→lg | 44 → `Sizing.minTapTarget` |
| T2-06 | `Components/SearchWell.swift` | paired×2→sm, cardInset×3→lg | 50 → `Sizing.minTapTarget` (R-1) |
| T2-07 | `Components/LoadingSkeleton.swift` | paired×1→sm, itemGap×3→md, cardInset×2→lg | squareSide 44 → `Sizing.minTapTarget`; primaryBar 12 → `Sizing.Component.skeletonPrimaryBar`; secondaryBar 9→8 → `.skeletonSecondaryBar` (R-3) |
| T2-08 | `Components/EmptyStateView.swift` | cardInset×2→lg | 44 → `Sizing.Component.emptyStateGlyph` |
| T2-09 | `Components/GenerationProgressView.swift` | hairline×2→xs, itemGap×1→md, cardInset×1→lg, sectionGap×1→xl, hero×1→2xl | trackHeight 3 → `Sizing.Component.progressTrack`; glyphSize 20 → `.stepGlyph`; ringWidth 1.5 → `Stroke.Component.progressRing` |
| T2-10 | `Components/OnboardingProgressBar.swift` | paired×2→sm | segmentHeight 4 → `Sizing.Component.progressSegment` |
| T2-11 | `Components/Tag.swift` | hairline×1→xs, paired×3→sm, cardInset×1→lg | dotSize 6 → `Sizing.dot` |
| T2-12 | `Components/AIVoice.swift` | hairline×1→xs, paired×1→sm, cardInset×1→lg | markSize 7 → `Sizing.dot` |
| T2-13 | `Components/MapPin.swift` | hero×2→2xl | pinSize 26 → `Sizing.Component.mapPin`; ringWidth 6 → `Stroke.Component.mapPinRing` |
| T2-14 | `Components/TimelineRow.swift` | hairline×4→xs, paired×5→sm, itemGap×2→md, cardInset×1→lg | dotSize 13 → `Sizing.Component.timelineDot`; nowRingInset 7→8 → `Spacing.Component.timelineNowRing`; glyphSize 14 → `Sizing.Component.timelineModeGlyph` |
| T2-15 | `Components/TripShapeCard.swift` | hairline×5→xs, paired×10→sm, itemGap×4→md, cardInset×1→lg | diagramColumnWidth 100 → `Sizing.Component.tripShapeDiagram`; dotSize 5/7 + markSize 7 → `Sizing.dot`; barHeight 3 → `Sizing.Component.tripShapeBar`; `.frame(width:1)` → `Stroke.separator` |
| T2-16 | `Components/BaseMapCard.swift` | hairline×1→xs, paired×1→sm, itemGap×3→md | mapHeight 184 → `Sizing.Component.baseMapHeight`; homeSize 30 → `.baseMapHome`; homeRingWidth 5→8 → `Spacing.Component.baseMapHomeRing`; zoneStroke 1 → `Stroke.separator`; zoneW 168 → `.baseMapZoneWidth`; zoneH 124→128 → `.baseMapZoneHeight` |
| T2-17 | `Components/PlaceCard.swift` | hairline×2→xs, paired×4→sm, itemGap×1→md, cardInset×1→lg | wellHeight 116 → `Sizing.Component.placeCardWell` (keep `wellHeight*0.18` derived) |
| T2-18 | `Components/ContextNote.swift` | hairline×1→xs, itemGap×1→md, cardInset×1→lg | none (no literal) — migrate + trim only |
| T2-19 | `Components/TimeHint.swift` | paired×3→sm, cardInset×1→lg | none — migrate + trim only |

### Source files — DesignSystem/Composition + Modifiers

| # | File | Migrate (role → t-shirt) | Reseed |
|---|---|---|---|
| T2-20 | `Composition/ActionBar.swift` | paired×3→sm, itemGap×1→md (+ 1 comment ref) | none — migrate + trim |
| T2-21 | `Composition/OnboardingActionFloor.swift` | paired×3→sm, itemGap×1→md | none — migrate + trim |
| T2-22 | `Composition/HScrollSection.swift` | hairline×1→xs, paired×1→sm, itemGap×2→md, cardInset×2→lg | none — migrate + trim |
| T2-23 | `Composition/ScreenSection.swift` | itemGap×2→md, sectionGap×2→xl | none — migrate + trim |
| T2-24 | `Composition/ScreenScaffold.swift` | none of the six (only `screenInset` — unchanged) | none — trim only |
| T2-25 | `Composition/RhythmSpacer.swift` | the **internal mapping only**: `Spacing.hairline→.xs`, `paired→.sm`, `itemGap→.md`, `cardInset→.lg`, `sectionGap→.xl`, `hero→.2xl` in the `height` switch. **DO NOT rename the `Rung` cases** (`.hairline/.paired/.sibling/.card/.section/.hero` are this primitive's PUBLIC API). Update the doc-comment "→ `Spacing.*`" pointers. | none |
| T2-26 | `Modifiers/CardSurface.swift` | cardInset×1→lg | none — migrate + trim |

### Source files — Screens/Onboarding

| # | File | Migrate (role → t-shirt) | Reseed |
|---|---|---|---|
| T2-27 | `Screens/Onboarding/BaseLocationStepView.swift` | hairline×1→xs, paired×3→sm, cardInset×5→lg, sectionGap×1→xl | (`minCardWidth` already reseeded to `Sizing.Component.cardMinWidth` in-flight — verify only) |
| T2-28 | `Screens/Onboarding/DestinationStepView.swift` | hairline×3→xs, paired×7→sm, itemGap×7→md, cardInset×4→lg, sectionGap×1→xl | none new |
| T2-29 | `Screens/Onboarding/GeneratingStepView.swift` | paired×1→sm, sectionGap×1→xl, hero×1→2xl | none new |
| T2-30 | `Screens/Onboarding/GettingAroundStepView.swift` | paired×9→sm, itemGap×5→md, sectionGap×1→xl | (`dot` site stays `Sizing.dot` — verify) |
| T2-31 | `Screens/Onboarding/TripShapeStepView.swift` | hairline×1→xs, paired×5→sm, itemGap×2→md, sectionGap×5→xl | (`interestChipMinWidth` already reseeded to `Sizing.Component.chipColumn` in-flight — verify only) |

> `screenInset` / `chromeClearance` appear in most of the above (per the breakdown) and are **left
> unchanged** by R-A. The migration counts above are ONLY the six deprecated roles.

### Test files (migrate the six roles; `screenInset`/`chromeClearance` unchanged)

These are not `@ScaledMetric` reseeds — pure call-site migration in test harness/preview code. Batch as one
or a few tasks (disjoint files); agent `swift-test-writer`.

| # | File | Migrate |
|---|---|---|
| T2-T1 | `AppTemplateTests/Snapshots/CompositionSnapshotTests.swift` | itemGap×2→md |
| T2-T2 | `AppTemplateTests/Snapshots/MapPinSnapshotTests.swift` | hero×3→2xl |
| T2-T3 | `AppTemplateTests/Snapshots/GlassCircleButtonSnapshotTests.swift` | paired×1→sm, cardInset×1→lg |
| T2-T4 | `AppTemplateTests/Snapshots/TimelineRowSnapshotTests.swift` | cardInset×1→lg |
| T2-T5 | `AppTemplateTests/Snapshots/AIVoiceSnapshotTests.swift` | cardInset×1→lg |
| T2-T6 | `AppTemplateTests/Snapshots/FilterChipSnapshotTests.swift` | cardInset×1→lg |
| T2-T7 | `AppTemplateTests/Snapshots/Onboarding/{DayStepper,SearchWell,SegmentedSelector}SnapshotTests.swift` | cardInset×1→lg each |
| T2-T8 | `AppTemplateTests/Snapshots/Onboarding/HScrollSectionSnapshotTests.swift` | hairline×1→xs, cardInset×2→lg |

> The remaining test files (`TimeHint`, `ContextNote`, `BaseMapCard`, `GenerationProgressView`,
> `OnboardingProgressBar` snapshot tests) reference ONLY `screenInset` → no migration needed (R-A).

**Phase-2 Done-when (each file):**
- Zero references to the six deprecated roles in the file (grep clean:
  `Spacing\.(hairline|paired|itemGap|cardInset|sectionGap|hero)\b`).
- Every swap is value-preserving (the audit value matches the t-shirt rung — a reviewer can confirm by px).
- For files in the reseed table: zero literal `@ScaledMetric`/`.frame` dimension seeds remain (grep clean
  for `ScaledMetric.*= [0-9]`, `frame(.*[0-9])`, `lineWidth:[0-9]`, `cornerRadius:[0-9]`); each routes to a
  semantic `Sizing`/`Stroke`/`Spacing.Component` token.
- Header ≤ ~5 lines (load-bearing rationale + ≥1 rule citation kept); file builds.
- No deprecation warning originates from this file after the pass.

---

## Phase 2.5 — delete the deprecated role aliases (serial)

| # | Agent | Action |
|---|---|---|
| T2.5-1 | coordinator | `grep -rnE 'Spacing\.(hairline\|paired\|itemGap\|cardInset\|sectionGap\|hero)\b' ios/AppTemplate ios/AppTemplateTests ios/AppTemplateUITests` → must be **zero** (excluding `Spacing.swift`). |
| T2.5-2 | `swift-design-system` | Delete the six `@available(*, deprecated)` forwarding aliases from `Spacing.swift`. Keep the eight t-shirt members + `screenInset`/`chromeClearance` aliases + `Component`. |

**GATE 2.5 Done-when:** full build clean with **zero deprecation warnings**; the grep is empty. The six role
members no longer exist — a stray reference would now be a hard compile error (proof of completeness).

---

## Phase 3 — gate (serial, after Phase 2.5)

| # | Agent | Action |
|---|---|---|
| T3-1 | coordinator | Full build clean (the `xcodebuild` command in CLAUDE.md). |
| T3-2 | `swift-test-writer` | Run functional/unit suites green (no logic changed — confirm no regressions). |
| T3-3 | `swift-snapshot-test-writer` | **Re-record** ONLY the snapshot suites whose pixels shift — which are the **component-dimension reseeds** (the snapped ≤4px deltas). The **spacing migration is value-preserving → produces NO spacing-driven diff.** Affected suites = the component-tokenize plan's list: `Tag`, `AIVoice`, `MapPin`(3), `LoadingSkeleton`, `GlassCircleButton`(2), `EmptyStateView`, `PlaceCard`(4), `FilterChip`(3), `PillButton`(7), `TimelineRow`(12), `TimeHint`(verify), `Onboarding/{DayStepper(2), GenerationProgressView(2), OnboardingProgressBar(3), BaseMapCard(1), TripShapeCard(4), SegmentedSelector(4), SearchWell(2)}`. Inspect every diff; a diff **larger than the snapped delta, or any diff on a spacing-only suite (`CompositionSnapshotTests`, `ContextNote`, `HScrollSection`), is a defect — investigate, do not silently accept.** |
| T3-4 | `fidelity-reviewer` | Confirm re-recorded baselines are ≤4px / within rhythm tolerance vs the named mockups; spacing unchanged. |
| T3-5 | `design-reviewer` | Semantic-only discipline across all touched files; t-shirt scale used (no role refs, no `Primitive.*`/literals in views); `screenInset`/`chromeClearance` aliases honored; Spacing/Sizing boundary intact; comment trims didn't strip load-bearing rationale. |
| T3-6 | coordinator | Append the `docs/decisions.md` entry (below). |
| T3-7 | `swift-code-reviewer` | Final pass — no `.shared`, MainActor clean, zero concurrency diagnostics, no hand-edited generated file, no deprecated alias left. |

**Done-when:** build clean; four layers green; only the component-dimension snapshots re-recorded (committed
with diffs noted); spacing suites show **no** diff; both reviews pass; decisions entry written.

---

## Docs to edit (edit-direct — prose/artifact scope)

### `docs/design-docs/03-layout-spacing.md` §2 "The gap ladder — six rungs, named"

Rewrite §2 as the **t-shirt scale**. Keep the "do not invent a rung in between (J-1)" rule and the
two-screens-match rationale verbatim; replace the table:

| Rung | Px | Where it appears | Book example |
|---|---|---|---|
| **xs** | 4 | eyebrow ↔ title; tag ↔ name | the "DUE" mono cap above a book title |
| **sm** | 8 | icon ↔ label in a chip; cover ↔ first text baseline | the shelf glyph and "Reading" in a status chip |
| **md** | 12 | title ↔ subtitle; meta ↔ title within a card | book title ↔ author byline |
| **lg** | 16 | card padding; list-row vertical padding; the screen margin | the inset around a book detail card |
| **xl** | 24 | section header ↔ first row; hero ↔ first section | "Due this week" header ↔ first book row |
| **2xl** | 32 | screen hero ↔ first control; sheet inner top | the shelf title ↔ the first section |
| **3xl** | 48 | a larger deliberate breath (use sparingly) | — |
| **4xl** | 64 | chrome-clearance band below a floating glyph | clearance under the onboarding ×/back |

Update §3's "concretely, on the gap ladder: a `card`-inset (16) surface sits in a `section` (24) gap" to
"a `lg` (16) inset sits in an `xl` (24) gap". Update any other `hairline/paired/card/section/breath` rung
names in this doc to the t-shirt names (the §1 "hairline" stroke carve-out at line 32 is about a *stroke*
hairline, not the spacing rung — leave it).

### `ios/docs/engineering/05-design-system.md`

- §1 code example (lines 42–43): change `enum Spacing { static let sectionGap = Primitive.space4; … }` to
  the t-shirt form, e.g. `enum Spacing { static let xl = Primitive.spaceXl; static let md = Primitive.spaceMd }`.
- §1 prose (lines 46–52): the "the gap has a *name* (`sectionGap`)" example → reframe as "the gap has a
  *named rung* (`xl`)" — keep the semantic-tokens-only rule intact (the point still holds; t-shirt is the
  shared name).
- §1.1 (line 59): `Spacing.sectionGap` example → `Spacing.xl`.
- §1.2 table (line 87): `Spacing` row "semantic examples" → "t-shirt scale `xs…4xl` + `screenInset`,
  `chromeClearance`".
- §1.x (lines 160, 193, 215) and any other `Spacing.sectionGap/.itemGap/.cardInset` references in examples
  → t-shirt (`Spacing.xl` / `.md` / `.lg`).

### `docs/decisions.md` — new entry (T3-6)

```
## 2026-06-03 — Spacing migrated to a t-shirt scale (xs…4xl), value-preserving — SUPERSEDES the role ladder

Decision. The Spacing tier's role-named gap ladder (hairline/paired/itemGap/cardInset/sectionGap/hero)
is replaced by a conventional t-shirt scale (xs=4, sm=8, md=12, lg=16, xl=24, 2xl=32, 3xl=48, 4xl=64).
Every px value is PRESERVED (hairline→xs, paired→sm, itemGap→md, cardInset→lg, sectionGap→xl, hero→2xl);
no pixel changes from the migration. screenInset (16) and chromeClearance (64) are KEPT as named layout
aliases onto the scale (→ lg / 4xl) for call-site intent (R-A). foundations.css gains --space-xs…4xl
and drops --gap-* + --space-chrome-clear; --s-1…--s-8 (the Grid dimension spine) are untouched.

Why. Conventional, discoverable, first-saas-aligned (token-foundation-design §5 option (b)); the role
ladder's intent is preserved in 03 §2's "where it appears" column. Supersedes the role-ladder framing in
2026-06-03 token-foundation-design.md §5 (which recommended option (a)) and 05 §5's role examples.

Migration was folded into the same per-file pass as the component @ScaledMetric tokenization
(2026-06-03-tokenize-component-library.md). The only re-recorded snapshots are the component-DIMENSION
reseeds (≤4px snapped deltas); the spacing migration produced no snapshot diff (value-preserving).
Forwarding @available(*,deprecated) role aliases kept the build green across Phase 0→2, deleted at 2.5.
```

(If R-A is overturned at GATE 0 — `screenInset`/`chromeClearance` migrated to `lg`/`4xl` and the aliases
deleted — record that variant instead.)

---

## Totals

- **t-shirt rungs:** 8 (`xs/sm/md/lg/xl/2xl/3xl/4xl`); 6 map value-preserving from roles, `3xl` is new.
- **foundations.css delta:** +8 `--space-*` vars, −7 vars (`--gap-*` ×6 + `--space-chrome-clear`).
- **Primitive.generated delta:** +8 / −7 = **+1** length member; `--s-1…--s-8` + all other tiers unchanged.
- **Spacing.role code call-sites to migrate (the six deprecated roles):** ~221
  (hairline 30, paired 76, itemGap 43, cardInset 47, sectionGap 16, hero 9 — minus ~13 comment refs that
  the executor updates in-place; ~208 live code sites). `screenInset` (44) + `chromeClearance` (5) are NOT
  migrated (R-A).
- **Files touched (Phase 2):** **45** — 19 Components + 7 Composition/Modifiers + 5 Onboarding screens + 14
  test files (some batched). Plus Phase 0: `foundations.css`, `Primitive.generated.swift`, `Spacing.swift`.
- **Component-literal reseeds folded in:** 31 call-sites across 15 component files + the 1 `.frame(width:1)`
  (per the component-tokenize audit; R-1/R-2/R-3 rulings apply — `Sizing.swift`/`Grid.swift` Component bands
  are already in-flight, so Phase 2 only reseeds the *component* files, not the token files).

## Parallelization / serialization

- **Serial / shared files (Phase 0 + 2.5):** `foundations.css`, `Primitive.generated.swift`, `Spacing.swift`
  (T0-A→B→C in order; T2.5 after all Phase 2). The coordinator serializes these.
- **Fully parallel (Phase 2):** all 45 per-file tasks — disjoint files, batch freely. None touch a `Tokens/`
  file or `Primitive.generated.swift`.
- **No `.pbxproj` / `AppStore.swift` / `ScreenCatalogView.swift` edits** (no new files, no store/screen
  logic changes) — no project-file serialization needed.

## Open decisions (settle at / before GATE 0)

1. **R-A — keep `screenInset` / `chromeClearance` as named layout aliases?** Recommended yes (preserves
   call-site intent; saves ~49 site edits). Design-reviewer ratifies at GATE 0; the decisions entry records
   the call. If no → add their 49 sites to Phase 2 and delete the aliases at 2.5.
2. **`2xl/3xl/4xl` member naming — RESOLVED (no longer open).** Digit-leading members REQUIRE backtick
   escaping: ``static let `2xl` `` / call as ``Spacing.`2xl` `` (verified compiling via `swiftc`). The codegen
   primitive `Primitive.space2xl` needs no escaping. No fallback needed; the backtick forms are the spec.
