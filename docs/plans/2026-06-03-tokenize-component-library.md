# Plan — Tokenize the component library + trim design-system comments

**Date:** 2026-06-03 · **Worktree:** `tokenize-components` · **Author:** ios-plan-writer
**Executed via:** `ios-subagent-development` skill (main-loop coordinator dispatches the `swift-*` agents)

A foundation-wide design-system refactor in two interleaved workstreams:

- **Workstream A — Tokenize the component library.** Remove every literal `@ScaledMetric` seed (and the
  one literal `.frame`) in `DesignSystem/Components/` + `Composition/` + `Modifiers/` and route each
  through a semantic token, applying the property→category + `Component`-band convention
  (`05-design-system.md §1.1–1.3`) and the snap/exception policy already settled in `docs/decisions.md`
  (the two 2026-06-03 "tokenize" + "token organization" entries).
- **Workstream B — Trim verbose comments** across `DesignSystem/**` (NOT the generated file) to concise,
  load-bearing rationale.

Because the pixels of tokenized components shift (≤4px, within fidelity tolerance) the existing render
snapshots **will diff** — Phase 3 **re-records them explicitly** (never silently accepts).

---

## Phase ordering — the foundation-freeze barrier is explicit

```
Phase 0  NEW TOKENS + TOKEN-FILE COMMENT TRIM            ← all serial/shared-file work, one batch
  A0  foundations.css: add the new vars (serial, single file)
  A1  regen Primitive.generated.swift via the codegen script (serial, depends on A0)
  A2  semantic tier: Sizing.minTapTarget (flat) + the Component bands across
      Sizing/Stroke/Spacing/Radius (serial per token file)
  B0  trim the TOKEN-file headers (Spacing/Radius/Stroke/Sizing/Shadows/Typography/Motion/ColorRole)
      — can run in the SAME agent pass as A2 per file (same files), so fold B0 into A2 per token file
  ──────────────────────────────────────────────────────────────────────────────
  GATE 0  build clean + design-reviewer freeze (semantic-only discipline, no orphan/empty bands,
          Sizing.minTapTarget is the one shared tap-target token, every new var round-trips through
          codegen) → FREEZE
  ──────────────────────────────────────────────────────────────────────────────
        ── no Phase 2 component pass is dispatched until GATE 0 passes ──

Phase 2  PER-COMPONENT PASSES (disjoint files → batch freely, fully parallel)
  Each task = one component/composition/modifier file: reseed its @ScaledMetric/literal seeds from the
  Phase-0 tokens AND trim that file's comments. No two tasks touch the same file. No token-tier file is
  edited here (all token work finished in Phase 0).

Phase 3  GATE — build + functional + RE-RECORD snapshots + reviews
  build clean → functional tests green → RE-RECORD the affected render snapshots (explicit, never silent)
  → fidelity-review the re-recorded baselines (confirm ≤4px, within rhythm tolerance) → design-review
  → docs/decisions.md entry → swift-code-reviewer.
```

**Why Phase 0 is fully serial:** every Phase-0 edit lands on a shared/serial file — `foundations.css`,
`Primitive.generated.swift`, and the token-tier files (`Sizing.swift`, `Stroke.swift`, `Spacing.swift`,
`Radius.swift`, plus the comment-only token files). The coordinator runs A0 → A1 → A2/B0 in sequence.
Phase 2 is where parallelism lives: the components are disjoint files.

**There is no token-parity test** (tokens are codegen'd, `05 §2`); the lock is the re-recorded render
snapshot (Phase 3).

---

## The audit table (the deliverable)

Complete sweep of `Components/` + `Composition/` + `Modifiers/` via grep for `@ScaledMetric`, `.frame(…
[0-9])`, `.padding([0-9])`, `cornerRadius:[0-9]`, `lineWidth:[0-9]`, `system(size:[0-9])`.

**Findings:** every literal design value is a `@ScaledMetric` seed plus **one** literal `.frame(width: 1)`
(a separator hairline). There are **no** literal `.padding`, `cornerRadius`, or `font(.system(size:))`
anywhere — those already use tokens. All `@ScaledMetric` seeds sit **above** their file's `#Preview`, so
**none are preview data** (preview args like `rowCount`/`stepIndex` are excluded by construction). Two
seeds already use tokens (`PillButton.verticalPadding = Spacing.itemGap`, `.horizontalPadding =
Spacing.sectionGap`) and stay as-is.

Legend: SNAP = snapped onto the 8pt spine; KEEP = already on grid or a named off-grid exception.

| File:line | Symbol | Literal | Snapped | Target token | Routing rationale |
|---|---|---|---|---|---|
| **Components/DayStepper.swift:22** | `buttonHitTarget` | 44 | 44 KEEP | `Sizing.minTapTarget` | HIG tap floor — shared, off-grid by design |
| **Components/FilterChip.swift:94** | `minTapTarget` | 44 | 44 KEEP | `Sizing.minTapTarget` | HIG tap floor (shared) |
| **Components/GlassCircleButton.swift:56** | `hitTarget` | 44 | 44 KEEP | `Sizing.minTapTarget` | HIG tap floor (shared) |
| **Components/PillButton.swift:161** | `minTapTarget` | 44 | 44 KEEP | `Sizing.minTapTarget` | HIG tap floor (shared) |
| **Components/SegmentedSelector.swift:71** | `minTapTarget` | 44 | 44 KEEP | `Sizing.minTapTarget` | HIG tap floor (shared) |
| **Components/SearchWell.swift:22** | `minTapTarget` | 50 | 48 SNAP | `Sizing.minTapTarget` | a tap floor; 50 is off-grid → use the shared 44 tap token (a well grows from `minHeight`; 44 floor is correct, 50 was an eyeballed bump). **See open decision 1.** |
| **Components/LoadingSkeleton.swift:94** | `squareSide` | 44 | 44 KEEP | `Sizing.minTapTarget` | the skeleton's square placeholder mirrors a 44 tap-target cell; reuse the shared token (decorative, but the same 44 dimension — one source) |
| **Components/EmptyStateView.swift:41** | `glyphSize` | 44 | 48 SNAP | `Sizing.Component.emptyStateGlyph` | a **decorative glyph box**, not a tap target → its own band member; 44 off-grid → snap to 48 (8×6) |
| **Components/GenerationProgressView.swift:84** | `trackHeight` | 3 | 4 SNAP | `Sizing.Component.progressTrack` | a progress-bar track height; 3 off-grid → 4 (s-1) |
| **Components/GenerationProgressView.swift:136** | `glyphSize` | 20 | 24 SNAP | `Sizing.Component.stepGlyph` | step status glyph box; 20 off-grid → 24 (s-4) |
| **Components/GenerationProgressView.swift:208** | `ringWidth` | 1.5 | 1.5 KEEP | `Stroke.Component.progressRing` | a `lineWidth` (border) → `Stroke`; sub-pixel stroke is the §1/§6 off-grid carve-out, not snapped |
| **Components/OnboardingProgressBar.swift:17** | `segmentHeight` | 4 | 4 KEEP | `Sizing.Component.progressSegment` | 4 on grid (s-1); a segment height (dimension) → `Sizing` band |
| **Components/Tag.swift:49** | `dotSize` | 6 | 8 SNAP | `Sizing.dot` | a status/indicator dot → the existing flat `Sizing.dot` (8); 6 off-grid → 8 (matches the established onboarding decision) |
| **Components/AIVoice.swift:61** | `markSize` | 7 | 8 SNAP | `Sizing.dot` | an accent mark dot → `Sizing.dot` (8); 7 off-grid → 8 |
| **Components/MapPin.swift:136** | `pinSize` | 26 | 24 SNAP | `Sizing.Component.mapPin` | a map-pin diameter; 26 off-grid → 24 (s-4) |
| **Components/MapPin.swift:138** | `ringWidth` | 6 | 6 KEEP | `Stroke.Component.mapPinRing` | a halo **stroke** (`lineWidth`) → `Stroke`; a ring width, off-grid carve-out, not snapped |
| **Components/TimelineRow.swift:114** | `dotSize` | 13 | 12 SNAP | `Sizing.Component.timelineDot` | the timeline stop dot; distinct role from the 8 status dot (a larger rail mark) → its own band member; 13 off-grid → 12 (s-3) |
| **Components/TimelineRow.swift:116** | `nowRingInset` | 7 | 8 SNAP | `Spacing.Component.timelineNowRing` | a halo **inset/offset** (a gap beyond the dot) → `Spacing` band; 7 off-grid → 8 (paired) |
| **Components/TimelineRow.swift:332** | `glyphSize` | 14 | 16 SNAP | `Sizing.Component.timelineModeGlyph` | the transit mode glyph box; 14 off-grid → 16 (s-3) |
| **Components/TripShapeCard.swift:63** | `diagramColumnWidth` | 100 | 104 SNAP | `Sizing.Component.tripShapeDiagram` | a fixed diagram column width; 100 off-grid → 104 (8×13). (NB: `Sizing.chipMin` is also 104 but a different role — keep a distinct band member, do not alias by value.) |
| **Components/TripShapeCard.swift:283** | `dotSize` | 5 | 8 SNAP | `Sizing.dot` | a small route dot → `Sizing.dot` (8); 5 off-grid → 8 |
| **Components/TripShapeCard.swift:318** | `dotSize` | 7 | 8 SNAP | `Sizing.dot` | a small route dot → `Sizing.dot` (8); 7 off-grid → 8 |
| **Components/TripShapeCard.swift:362** | `markSize` | 7 | 8 SNAP | `Sizing.dot` | a route mark dot → `Sizing.dot` (8); 7 off-grid → 8 |
| **Components/TripShapeCard.swift:363** | `barHeight` | 3 | 4 SNAP | `Sizing.Component.tripShapeBar` | a mini-bar height; 3 off-grid → 4 (s-1) |
| **Components/TripShapeCard.swift:186** | `.frame(width: 1)` | 1 | 1 KEEP | `Stroke.separator` | a 1pt structural hairline `Rectangle` → the existing `Stroke.separator` (off-grid carve-out, already a token) |
| **Components/BaseMapCard.swift:56** | `mapHeight` | 184 | 184 KEEP | `Sizing.Component.baseMapHeight` | a map well height; 184 on grid (8×23) → its own band member |
| **Components/BaseMapCard.swift:179** | `homeSize` | 30 | 32 SNAP | `Sizing.Component.baseMapHome` | home marker diameter; 30 off-grid → 32 (s-5) |
| **Components/BaseMapCard.swift:180** | `homeRingWidth` | 5 | 8 SNAP | `Spacing.Component.baseMapHomeRing` | a halo **inset/offset** (`homeSize + homeRingWidth*2` sizes the surrounding circle) → `Spacing` band; 5 off-grid → 8 (paired). **See open decision 2.** |
| **Components/BaseMapCard.swift:181** | `zoneStroke` | 1 | 1 KEEP | `Stroke.separator` | a zone outline `lineWidth` = 1pt → the existing `Stroke.separator` |
| **Components/BaseMapCard.swift:182** | `zonePlaceholderWidth` | 168 | 168 KEEP | `Sizing.Component.baseMapZoneWidth` | a placeholder rect width; 168 on grid (8×21) → its own band member |
| **Components/BaseMapCard.swift:183** | `zonePlaceholderHeight` | 124 | 128 SNAP | `Sizing.Component.baseMapZoneHeight` | a placeholder rect height; 124 off-grid → 128 (8×16) |
| **Components/PlaceCard.swift:92** | `wellHeight` | 116 | 120 SNAP | `Sizing.Component.placeCardWell` | a media-well height; 116 off-grid → 120 (8×15). (PlaceCard:139 `wellHeight * 0.18` is a derived inner mark — stays derived, no literal.) | 

**Excluded (not design literals):** derived expressions (`homeSize + homeRingWidth*2`,
`pinSize + ringWidth*2`, `wellHeight * 0.18`, `max(0,min(1,value)) * proxy.size.width`); fractions in
prose comments; `bandFraction = 0.35` (a layout *ratio*, not a px dimension — leave as a named local
constant, like the opacity-finish constants in the 2026-06-03 decision); all preview args.

### Audit totals

- **Literal seeds tokenized:** 31 call-sites across **15 component files** + the 1 `.frame(width:1)`.
- **New shared flat semantic token:** 1 (`Sizing.minTapTarget`).
- **Reused existing flat tokens:** `Sizing.dot` (Tag, AIVoice, TripShape ×3), `Stroke.separator`
  (TripShapeCard hairline, BaseMapCard zoneStroke ×2).
- **New `Component`-band members:** 16 (`Sizing.Component` ×11, `Stroke.Component` ×2,
  `Spacing.Component` ×2 — note `timelineNowRing` + `baseMapHomeRing` are insets → `Spacing`).
- **New foundations.css vars:** 18 (1 shared tap target + 16 component bands + note `Sizing.dot` already
  exists; the two new `Spacing` insets reuse no existing var).

---

## New tokens — exact declarations (Phase 0 contract)

### A0 — `mockups/foundations/foundations.css` (serial; single file)

Add to `:root`, grouped under the existing section comments. Names follow the codegen contract
(kebab→camel, category prefix kept). px values are the **snapped** values from the audit.

**Shared tap target** (new, under the SIZING block):
```
--size-min-tap-target: 44px;  /* HIG minimum interactive target — sacred, off-grid by design (J-0.3) */
```

**Sizing component band** (new vars, SIZING block):
```
--size-empty-state-glyph:   48px;   /* 8×6  — EmptyStateView decorative glyph box */
--size-progress-track:        4px;   /* s-1  — GenerationProgressView track height */
--size-step-glyph:           24px;   /* s-4  — GenerationProgressView step status glyph */
--size-progress-segment:      4px;   /* s-1  — OnboardingProgressBar segment height */
--size-map-pin:              24px;   /* s-4  — MapPin diameter */
--size-timeline-dot:         12px;   /* s-3  — TimelineRow stop dot */
--size-timeline-mode-glyph:  16px;   /* s-3  — TransitConnector mode glyph box */
--size-trip-shape-diagram:  104px;   /* 8×13 — TripShapeCard diagram column width */
--size-trip-shape-bar:        4px;   /* s-1  — TripShapeCard mini-bar height */
--size-base-map-height:     184px;   /* 8×23 — BaseMapCard map well height */
--size-base-map-home:        32px;   /* s-5  — BaseMapCard home marker diameter */
--size-base-map-zone-width: 168px;   /* 8×21 — BaseMapCard zone placeholder width */
--size-base-map-zone-height:128px;   /* 8×16 — BaseMapCard zone placeholder height */
--size-place-card-well:     120px;   /* 8×15 — PlaceCard media-well height */
```

**Stroke component band** (new vars, STROKE block; off-grid carve-out — sub-pixel/ring widths):
```
--stroke-progress-ring: 1.5px;  /* GenerationProgressView ring border — off-grid stroke carve-out (03 §1/§6) */
--stroke-map-pin-ring:    6px;  /* MapPin now-halo ring width — a stroke, not a layout dimension */
```

**Spacing component band** (new vars, SPACING block; ring insets/offsets — gaps, not strokes):
```
--space-timeline-now-ring: 8px;  /* s-2 — TimelineRow now-ring halo inset beyond the dot */
--space-base-map-home-ring:8px;  /* s-2 — BaseMapCard home-marker halo inset beyond the marker */
```

`Sizing.dot` (8) already exists (`--size-dot`) — Tag/AIVoice/TripShape route to it, no new var.
`Stroke.separator` (1, `--stroke-separator`) already exists — TripShape hairline + BaseMapCard
`zoneStroke` route to it, no new var.

> **Codegen contract check:** every new var is a single-value length → emits a `Primitive.size*` /
> `Primitive.stroke*` / `Primitive.space*` `CGFloat`. No compound values (those are skipped). The mockup
> already references `--size-card-min`; the new component vars are Swift-internal dimensions (no mockup
> selector references them yet — that's fine, foundations.css is the value home regardless).

### A1 — regenerate `ios/AppTemplate/DesignSystem/Tokens/Primitive.generated.swift` (serial; codegen)

Run the generator — **never hand-edit**:
```
swift .claude/scripts/generate-tokens.swift   # (or the documented invocation in mockups/CLAUDE.md)
```
Expected new members (camelCased, `CGFloat`):
`sizeMinTapTarget = 44`, `sizeEmptyStateGlyph = 48`, `sizeProgressTrack = 4`, `sizeStepGlyph = 24`,
`sizeProgressSegment = 4`, `sizeMapPin = 24`, `sizeTimelineDot = 12`, `sizeTimelineModeGlyph = 16`,
`sizeTripShapeDiagram = 104`, `sizeTripShapeBar = 4`, `sizeBaseMapHeight = 184`, `sizeBaseMapHome = 32`,
`sizeBaseMapZoneWidth = 168`, `sizeBaseMapZoneHeight = 128`, `sizePlaceCardWell = 120`,
`strokeProgressRing = 1.5`, `strokeMapPinRing = 6`, `spaceTimelineNowRing = 8`,
`spaceBaseMapHomeRing = 8`.

### A2 — semantic tier hand-authored aliases (serial; per token file)

**`Tokens/Sizing.swift`** — add the flat shared token + the `Component` band (Sizing's members stay flat
per §1.1, but the per-component dimensions nest in a `Component` enum to keep the broad-use `dot`/`cardMin`
/`chipMin` distinct from one-component values):
```swift
// flat, shared (broad use):
static let minTapTarget: CGFloat = Primitive.sizeMinTapTarget   // 44 — HIG min interactive target

enum Component {
    static let emptyStateGlyph   = Primitive.sizeEmptyStateGlyph    // 48 — EmptyStateView glyph box
    static let progressTrack     = Primitive.sizeProgressTrack      // 4  — GenerationProgressView track
    static let stepGlyph         = Primitive.sizeStepGlyph          // 24 — gen step status glyph
    static let progressSegment   = Primitive.sizeProgressSegment    // 4  — OnboardingProgressBar segment
    static let mapPin            = Primitive.sizeMapPin             // 24 — MapPin diameter
    static let timelineDot       = Primitive.sizeTimelineDot        // 12 — TimelineRow stop dot
    static let timelineModeGlyph = Primitive.sizeTimelineModeGlyph  // 16 — TransitConnector mode glyph
    static let tripShapeDiagram  = Primitive.sizeTripShapeDiagram   // 104 — TripShapeCard diagram column
    static let tripShapeBar      = Primitive.sizeTripShapeBar       // 4  — TripShapeCard mini-bar
    static let baseMapHeight     = Primitive.sizeBaseMapHeight      // 184 — BaseMapCard map well
    static let baseMapHome       = Primitive.sizeBaseMapHome        // 32 — BaseMapCard home marker
    static let baseMapZoneWidth  = Primitive.sizeBaseMapZoneWidth   // 168 — BaseMapCard zone placeholder W
    static let baseMapZoneHeight = Primitive.sizeBaseMapZoneHeight  // 128 — BaseMapCard zone placeholder H
    static let placeCardWell     = Primitive.sizePlaceCardWell      // 120 — PlaceCard media well
}
```
> NOTE the apparent tension: §1.1 says "Sizing's members stay flat." The flat `dot`/`cardMin`/`chipMin`/
> `minTapTarget` are the broad-use roles. A `Sizing.Component` band for one-component dimensions is the
> consistent application of the band rule and keeps the flat tier uncluttered. **The design-reviewer
> confirms this reading at GATE 0** — if rejected, the band members move to flat `Sizing` (decision
> recorded). Flagged for the coordinator.

**`Tokens/Stroke.swift`** — add a `Component` band:
```swift
enum Component {
    static let progressRing = Primitive.strokeProgressRing   // 1.5 — GenerationProgressView ring border
    static let mapPinRing    = Primitive.strokeMapPinRing     // 6 — MapPin now-halo ring width
}
```

**`Tokens/Spacing.swift`** — add a `Component` band (ring insets are gaps, not strokes):
```swift
enum Component {
    static let timelineNowRing = Primitive.spaceTimelineNowRing   // 8 — TimelineRow now-ring halo inset
    static let baseMapHomeRing = Primitive.spaceBaseMapHomeRing   // 8 — BaseMapCard home-ring halo inset
}
```

`Tokens/Radius.swift` — **no new members** (no radius literals found); B0 trims its header only.

---

## Workstream B — comment-trim guideline (applied per file)

**Policy (judgment, not line-by-line):**
- **Header comment ≤ ~5 lines** unless genuinely load-bearing. Keep: the one-line "what this is", the
  mockup/ports reference, and rule citations (J-rules, `0X §Y`) compressed to one line where possible.
  Cut: restated design-doc prose, multi-paragraph anatomy that the code already shows, redundant
  re-explanations of the same rule.
- **Inline comments only where non-obvious** — keep a "why" the code can't show (an optical nudge, an
  off-grid carve-out rationale, an OD-2/J-9.3 deferral); cut comments that narrate what the next line
  plainly does.
- **Token-file headers** (`Spacing`/`Radius`/`Stroke`/`Sizing` + `Shadows`/`Typography`/`Motion`/
  `ColorRole`): compress to **one-line role + the doc ref**. Exception: `Shadows.swift`'s oklch→sRGB and
  CSS-blur→radius conversion notes are **load-bearing** (they document the hand-authored values that
  codegen skips) — keep those compressed but intact.
- **Preserve every rule citation** at least once per file (the repo deliberately encodes rationale —
  concise, not stripped).

**Heaviest files (comment-line counts, for targeting):** TimelineRow 126, LoadingSkeleton 82, Shadows 78,
PillButton 70, PlaceCard 70, Typography 64, GlassCircleButton 58, ActionBar 57, FilterChip 55,
ScreenChrome 53, MapPin 51, GlassChrome 48, EmptyStateView 43.

B0 (token files) runs in Phase 0 folded into the A2 edits (same files). All other component/composition/
modifier files are trimmed **inside their Phase 2 task** (same agent, same file, one pass).

---

## Snapshots — what Phase 3 re-records

Components currently under render snapshot (`AppTemplateTests/Snapshots/**/__Snapshots__/`):

**Tokenized → pixels shift → MUST re-record:**
`TagSnapshotTests`, `AIVoiceSnapshotTests`, `MapPinSnapshotTests` (3 states), `LoadingSkeletonSnapshotTests`,
`GlassCircleButtonSnapshotTests` (2), `EmptyStateViewSnapshotTests`, `PlaceCardSnapshotTests` (4),
`FilterChipSnapshotTests` (3), `PillButtonSnapshotTests` (7), `TimelineRowSnapshotTests` (12),
`TimeHintSnapshotTests` (uses TimelineRow/Tag visuals — verify diff),
`Onboarding/DayStepperSnapshotTests` (2), `Onboarding/GenerationProgressViewSnapshotTests` (2),
`Onboarding/OnboardingProgressBarSnapshotTests` (3), `Onboarding/BaseMapCardSnapshotTests` (1),
`Onboarding/TripShapeCardSnapshotTests` (4), `Onboarding/SegmentedSelectorSnapshotTests` (4),
`Onboarding/SearchWellSnapshotTests` (2).

**No literal seed → re-record only IF a diff appears (no change expected):**
`Onboarding/ContextNoteSnapshotTests`, `Onboarding/HScrollSectionSnapshotTests`,
`CompositionSnapshotTests` (ActionBar/Scaffold/Section/Rhythm — comment-trim only, no metric change).

**Re-record protocol (Phase 3, explicit — never silent):** set the recording flag, run the affected
suites, inspect each diff (confirm the shift is the expected snapped delta, ≤4px), commit the new
baselines with the diff noted. A diff larger than the snapped delta is a defect, not a re-record.

---

## Task list

### Phase 0 (serial — one agent, sequential sub-steps; or coordinator runs in order)

| # | Agent | Reads | Writes | Never touch |
|---|---|---|---|---|
| **T0-A0** | `swift-design-system` | this plan, foundations.css, `05 §1–2`, decisions 2026-06-03 | `mockups/foundations/foundations.css` (add 18 vars) | Primitive.generated.swift, components |
| **T0-A1** | `swift-design-system` | codegen invocation (mockups/CLAUDE.md) | `Tokens/Primitive.generated.swift` (via script ONLY) | foundations.css (done), by-hand edits |
| **T0-A2/B0** | `swift-design-system` | `05 §1.1–1.3`, the new primitives | `Tokens/Sizing.swift`, `Tokens/Stroke.swift`, `Tokens/Spacing.swift` (add aliases) + trim headers of all 8 token files | components, Primitive.generated.swift |

**Exemplar to mirror:** the existing `Sizing.swift` flat members + the decisions-log "Sizing tier" entry;
`Stroke.swift` for the alias-with-citation comment shape.
**Done-when:**
- `foundations.css` has all 18 new vars, each single-value, category-prefixed, with a one-line comment.
- `Primitive.generated.swift` regenerated (diff shows only the 19 new `CGFloat` members; nothing else moved).
- `Sizing.minTapTarget` flat; `Sizing.Component` (14), `Stroke.Component` (2), `Spacing.Component` (2)
  bands present, each member with a role-doc one-liner; no empty/orphan band.
- Every token-file header ≤ ~5 lines (Shadows conversion notes kept, compressed).
- Build clean. **GATE 0 design-reviewer freeze passes** (semantic-only, band-rule reading confirmed).

### Phase 2 (parallel — disjoint files, batch freely)

One task **per file**. Each: reseed that file's `@ScaledMetric`/literal from the Phase-0 token AND trim
its comments. Agent: `swift-design-system`. **Never touch** any `Tokens/` file (Phase 0 owns them),
`Primitive.generated.swift`, or any other component file.

| # | File | Reseed (literal → token) | Trim target |
|---|---|---|---|
| T2-01 | `Components/DayStepper.swift` | 44 → `Sizing.minTapTarget` | header ≤5 |
| T2-02 | `Components/FilterChip.swift` | 44 → `Sizing.minTapTarget` | 55 → concise |
| T2-03 | `Components/GlassCircleButton.swift` | 44 → `Sizing.minTapTarget` | 58 → concise |
| T2-04 | `Components/PillButton.swift` | 44 → `Sizing.minTapTarget` (keep the 2 token padding seeds) | 70 → concise |
| T2-05 | `Components/SegmentedSelector.swift` | 44 → `Sizing.minTapTarget` | header ≤5 |
| T2-06 | `Components/SearchWell.swift` | 50 → `Sizing.minTapTarget` (44) | header ≤5 |
| T2-07 | `Components/LoadingSkeleton.swift` | squareSide 44 → `Sizing.minTapTarget`; primaryBarHeight 12 / secondaryBarHeight 9 → **see open decision 3** | 82 → concise |
| T2-08 | `Components/EmptyStateView.swift` | 44 → `Sizing.Component.emptyStateGlyph` | 43 → concise |
| T2-09 | `Components/GenerationProgressView.swift` | trackHeight 3 → `Sizing.Component.progressTrack`; glyphSize 20 → `.stepGlyph`; ringWidth 1.5 → `Stroke.Component.progressRing` | header ≤5 |
| T2-10 | `Components/OnboardingProgressBar.swift` | segmentHeight 4 → `Sizing.Component.progressSegment` | header ≤5 |
| T2-11 | `Components/Tag.swift` | dotSize 6 → `Sizing.dot` | header ≤5 |
| T2-12 | `Components/AIVoice.swift` | markSize 7 → `Sizing.dot` | header ≤5 |
| T2-13 | `Components/MapPin.swift` | pinSize 26 → `Sizing.Component.mapPin`; ringWidth 6 → `Stroke.Component.mapPinRing` | 51 → concise |
| T2-14 | `Components/TimelineRow.swift` | dotSize 13 → `Sizing.Component.timelineDot`; nowRingInset 7 → `Spacing.Component.timelineNowRing`; glyphSize 14 → `Sizing.Component.timelineModeGlyph` | 126 → concise |
| T2-15 | `Components/TripShapeCard.swift` | diagramColumnWidth 100 → `Sizing.Component.tripShapeDiagram`; dotSize 5/7 + markSize 7 → `Sizing.dot`; barHeight 3 → `Sizing.Component.tripShapeBar`; `.frame(width:1)` → `Stroke.separator` | header ≤5 |
| T2-16 | `Components/BaseMapCard.swift` | mapHeight 184 → `Sizing.Component.baseMapHeight`; homeSize 30 → `.baseMapHome`; homeRingWidth 5 → `Spacing.Component.baseMapHomeRing`; zoneStroke 1 → `Stroke.separator`; zonePlaceholderWidth 168 → `.baseMapZoneWidth`; zonePlaceholderHeight 124 → `.baseMapZoneHeight` | header ≤5 |
| T2-17 | `Components/PlaceCard.swift` | wellHeight 116 → `Sizing.Component.placeCardWell` (keep `wellHeight*0.18` derived) | 70 → concise |
| T2-18 | `Composition/ActionBar.swift` | none (no literal) | 57 → concise (comment-trim only) |
| T2-19 | `Composition/ScreenChrome.swift` | none | 53 → concise |
| T2-20 | `Modifiers/GlassChrome.swift` | none | 48 → concise |
| T2-21 | Remaining DS files w/ heavy comments but no literal | none | trim only: `Components/TimeHint`, `Components/ContextNote`, `Components/SearchWell` chrome, `Composition/HScrollSection`, `Composition/OnboardingActionFloor`, `Composition/ScreenScaffold`, `Composition/ScreenSection`, `Composition/RhythmSpacer`, `Modifiers/CardSurface`, `Components/GenerationProgressView` (if not covered), `Components/LeadingGlyph` — one task per file, batch |

**Exemplar to mirror (all Phase 2):** a clean already-tokenized seed — `PillButton.verticalPadding =
Spacing.itemGap` (the seed pattern) — and the snapped-token decisions-log entry for the snap rationale.
Each agent reads the audit row for its file from this plan.
**Done-when (each):** zero literals/`Primitive.*` in the file (grep clean for `ScaledMetric.*= [0-9]`,
`frame(.*[0-9])`, `cornerRadius:[0-9]`, `lineWidth:[0-9]`); every seed references a semantic token; header
≤ ~5 lines (or load-bearing kept); at least one rule citation retained; file builds.

### Phase 3 (gate — serial reviews after all Phase 2 merged)

| # | Agent | Action |
|---|---|---|
| T3-1 | coordinator | Full build clean (xcodebuild command in CLAUDE.md). |
| T3-2 | `swift-test-writer` | Run functional/unit suites green (no logic changed; confirm no regressions). |
| T3-3 | `swift-snapshot-test-writer` | **Re-record** the affected snapshot suites (list above), explicit recording flag; inspect every diff = expected snapped delta. |
| T3-4 | `fidelity-reviewer` | Confirm re-recorded baselines are ≤4px / within rhythm tolerance vs the named mockups; flag any larger shift. |
| T3-5 | `design-reviewer` | Semantic-only discipline across all touched files; band rule honored; comment trims didn't strip load-bearing rationale. |
| T3-6 | coordinator | Append `docs/decisions.md` entry (tokenized the component library; the `Sizing.Component` band reading; the snaps applied; snapshots re-recorded). |
| T3-7 | `swift-code-reviewer` | Final pass — no `.shared`, MainActor clean, no concurrency diagnostics, no hand-edited generated file. |

**Done-when:** build clean; all four test layers green; snapshot baselines re-recorded + committed with
diffs noted; both reviews pass; decisions entry written.

---

## Open decisions (settle before / at GATE 0)

1. **SearchWell `minTapTarget` 50 → 44 vs 48.** The plan routes it to the shared `Sizing.minTapTarget`
   (44), treating the 50 as an eyeballed bump over the HIG floor (the well grows from `minHeight`, so 44
   is a correct floor). If the design intends a deliberately taller search well, it needs its own
   `Sizing.Component.searchWell = 48` (snapped) instead. **Recommend:** shared 44. Confirm.
2. **`Sizing.Component` band vs flat Sizing.** `05 §1.1` says "Sizing's members stay flat." This plan
   adds a `Sizing.Component` band for one-component dimensions, keeping the broad-use roles flat. This is
   a reading of the convention, not a contradiction — but it should be **ratified by the design-reviewer
   at GATE 0** (or the doc amended). If rejected, all band members move to flat `Sizing` (more members,
   no band). **Recommend:** the band, ratify in the decisions entry.
3. **LoadingSkeleton bar heights (12, 9).** Not in the requested literal list but found in the audit:
   `primaryBarHeight = 12` (on grid, s-3) and `secondaryBarHeight = 9` (off-grid → 8). These are
   skeleton placeholder bar heights. **Recommend:** route to `Sizing.Component.skeletonPrimaryBar = 12`
   and `.skeletonSecondaryBar = 8` (snap 9→8) — i.e. add 2 more component vars + members in Phase 0. If
   the coordinator wants to scope-limit to the explicitly-listed literals, leave them as a follow-up.
   **Flagged because they are the same violation class** (literal seed) and a complete audit must surface
   them.

---

## Coordinator rulings (AUTHORITATIVE — override the plan above on any conflict)

Settled at GATE-0 prep. The open decisions are closed as follows; executors follow THESE.

**R-1 — SearchWell `50` → `Sizing.minTapTarget` (44).** Accept the plan's recommendation (open decision 1):
it is a `minHeight` tap floor like the other five `minTapTarget` symbols → route all six to the one shared
token. (Re-snapshot will confirm no content shrink.)

**R-2 — `Sizing.Component` band ratified, applied CONSISTENTLY (open decision 2).** The rule, now uniform
across every category: **flat = a shared semantic role used by ≥2 components; `Component` band = a
single-component dimension.** Consequences:
- `dot` stays **flat** (`Sizing.dot`) — it becomes broad-use (Tag, AIVoice, TripShape×3, onboarding).
- **MOVE** the two existing single-use members into the band: `cardMin → Sizing.Component.cardMinWidth`,
  `chipMin → Sizing.Component.chipColumn` (keep their snapped values 136 / 104). **Reseed their two
  onboarding call-sites** (NOT in the original plan): `Screens/Onboarding/BaseLocationStepView.swift`
  (`minCardWidth = Sizing.Component.cardMinWidth`) and `Screens/Onboarding/TripShapeStepView.swift`
  (`interestChipMinWidth = Sizing.Component.chipColumn`). Add these as two extra Phase-2 tasks (disjoint
  files, parallel-safe). `dot`'s onboarding site (`GettingAroundStepView`) is unchanged (still `Sizing.dot`).
- This supersedes `05-design-system.md §1.1`'s "Sizing's members stay flat" framing. **Phase 0 adds a doc
  task** (coordinator, edit-direct): amend §1.1 (drop the Sizing-flat exception; state the uniform
  flat-vs-`Component` rule; update the code example to show `Sizing.dot`/`minTapTarget` flat +
  `Sizing.Component.cardMinWidth`) and the §1.2 Sizing row. The `docs/decisions.md` Phase-3 entry records
  the supersede.

**R-3 — LoadingSkeleton `12`/`9` tokenized (open decision 3).** Add two foundations vars
`--size-skeleton-primary-bar: 12px` (s-… 12 on grid) and `--size-skeleton-secondary-bar: 8px` (snap 9→8),
→ `Sizing.Component.skeletonPrimaryBar` / `.skeletonSecondaryBar`. T2-07 reseeds both (in addition to the
`squareSide 44 → Sizing.minTapTarget`).

**Net token delta vs the plan's "New tokens" section:** foundations vars 18 → **20** (+2 skeleton);
`Sizing.Component` gains `cardMinWidth`, `chipColumn` (moved, not new vars — reuse `--size-card-min`,
`--size-chip-min`), `skeletonPrimaryBar`, `skeletonSecondaryBar`; flat `Sizing` loses `cardMin`,`chipMin`,
keeps `dot` + new `minTapTarget`. Two extra Phase-2 reseed tasks (BaseLocation, TripShape onboarding).

---

## Parallelization / serialization summary

- **Serial / shared files (Phase 0 only):** `foundations.css`, `Primitive.generated.swift`,
  `Tokens/Sizing.swift`, `Tokens/Stroke.swift`, `Tokens/Spacing.swift` (+ comment-only token files).
  The coordinator runs A0 → A1 → A2 in order; no parallelism in Phase 0.
- **Fully parallel (Phase 2):** all 21+ component/composition/modifier tasks — disjoint files, batch
  freely. None touch a `Tokens/` file or `Primitive.generated.swift`.
- **No `.pbxproj` / `AppStore.swift` / `ScreenCatalogView.swift` edits** in this refactor (no new files,
  no store/screen changes) — no project-file serialization needed.
