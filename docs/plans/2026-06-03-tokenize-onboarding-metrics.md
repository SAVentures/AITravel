# Plan — Tokenize the onboarding `@ScaledMetric` literals

**Topic.** Remove hardcoded literal design values from `Screens/Onboarding/*View.swift`. The wrapper
(`@ScaledMetric(relativeTo:)`) is the accepted pattern (`Spacing.swift` lines 12–16); the **literal seed**
is the non-negotiable violation ("design values from *semantic* tokens only"). Every seed becomes a token
base. The user has decided to **snap off-grid seeds onto the 8pt grid** while tokenizing — a deliberate
pixel change that requires a `docs/decisions.md` entry, re-fidelity-review, and re-recorded baselines
where any exist.

**Worktree.** `/Users/shubh/Workspaces/AITravel-app/.claude/worktrees/tokenize-metrics`
**Plan path.** `docs/plans/tokenize-onboarding-metrics.md` (this file).
**Executed via** the `ios-subagent-development` skill from the main loop. No code bodies below — token
*declarations* (name + value) are the contract, not bodies.

---

## Phase ordering (the foundation-freeze barrier is the one hard gate)

```
PHASE 0 — Foundation (tokens)         ── must be design-reviewed + BUILDING before Phase 2 ──
  0A  foundations.css  (mockups/ — edited directly by the user/mockups-screen-builder, NOT the Swift pipeline)
  0B  regenerate Primitive.generated.swift   (run the codegen script)
  0C  Stroke.swift     — add `hairline`
  0D  Spacing.swift    — add `chromeClearance`
  0E  Sizing.swift     — NEW semantic enum  (dot / cardMin / chipMin)
  0F  mockup coherence — base-location .alt min-width → var(--size-card-min)   (mockups/, flag-not-block)
        │
   ══════════ FOUNDATION FREEZE: design-reviewer PASS on 0C–0E + clean build ═══════════
        │
PHASE 2 — Screen edits (the 5 view files, disjoint, parallelizable)
  2A  GettingAroundStepView.swift     (3 seeds)
  2B  DestinationStepView.swift       (2 seeds)
  2C  BaseLocationStepView.swift      (2 seeds)
  2D  GeneratingStepView.swift        (1 seed)
  2E  TripShapeStepView.swift         (2 seeds)
        │
PHASE 3 — Verify / gate
  3A  build clean (worktree DerivedData)
  3B  re-record render-snapshot baselines IF any cover the changed call-sites  (see §Verification — currently NONE do)
  3C  fidelity-review the affected screens vs named mockups
  3D  design-reviewer on the new tokens + Sizing tier
  3E  docs/decisions.md append-only entry (the snaps + the Sizing tier)
  3F  swift-code-reviewer before commit
```

There is **no Phase 1** (no models/networking touched). Phase 0 is pure foundation; it must build and be
design-reviewed before any view in Phase 2 references the new tokens.

---

## The token-tier changes (Phase 0 — the FOUNDATION)

Tokens are codegen'd: `foundations.css` → `.claude/scripts/generate-tokens.swift` →
`Primitive.generated.swift` (generated, never hand-edited). The generator maps `--kebab-name: 64px;` →
`Primitive.kebabName` (CGFloat). The semantic tier (`Spacing`/`Stroke`/`Sizing`) is hand-authored Swift
aliasing primitives by role.

### Design-doc confirmation: is a `Sizing` tier the right home?

`05-design-system.md §1` defines three tiers — **Primitive** (generated), **Semantic** (intent), and
**Component** ("local decisions for a complex component — `bookRowCoverSize` … *sparingly*"). §5 names the
existing semantic enums: `Spacing` (gap ladder), `Radius`, `Shadow`, `Stroke`, `Motion`. There is **no
prescribed `Sizing` enum** in the doc — but the doc explicitly states the semantic tier holds intent and
the existing enums each own one *kind* of value by role.

**Resolution (an open decision the coordinator should confirm, see end):** these three values are
*component dimensions* (an indicator-dot diameter, a scroll-card min width, an adaptive-grid chip min
column). They are not gaps (Spacing is a gap ladder, §5), not radii, not strokes. Two valid homes exist:

- **(A) A new `Sizing` semantic enum** — mirrors `Stroke`/`Radius`: one file, role-named members, aliasing
  primitives. Matches the user's stated intent and keeps screens referencing the semantic tier only.
- **(B) The Component tier** (`05 §1`) — `bookRowCoverSize`-style per-component constants, but the doc
  says "sparingly" and these are shared-ish across onboarding subviews, so a named semantic home reads
  cleaner than three scattered component constants.

This plan specifies **(A) `Sizing`** per the user's decision, and flags the tier-introduction for the
`docs/decisions.md` entry (§3E) since the doc does not name it. If design-reviewer prefers (B), the three
members move into the relevant `private struct` as component constants seeded from `Primitive.*` instead —
same primitives, different home; the view-edit call-sites change to `<LocalConst>` rather than `Sizing.*`.

---

### Task 0A — `foundations.css` new `:root` vars

- **Agent / ownership:** `mockups/` is edited **directly** (the Swift pipeline does not own it). Per
  `mockups/CLAUDE.md`, the `mockups-screen-builder` agent (or the user) makes this edit. **Not** a `swift-*`
  agent. The PLAN names the vars exactly; the editor transcribes them.
- **File (edit):** `/Users/shubh/Workspaces/AITravel-app/mockups/foundations/foundations.css`
- **Never touch:** `Primitive.generated.swift` by hand (it regenerates in 0B).

**Add, in the existing STROKE section** (after `--stroke-selected`, near line 123):
```css
  --stroke-hairline: 1px;  /* a 1pt rule — separator/divider thickness, NOT a layout dim (03 §1 carve-out) */
```

**Add, in the existing SPACING section** (after the gap-ladder block, near line 113):
```css
  /* named LAYOUT roles — not gap-ladder rungs (03 §4 style: like the screen margin) */
  --space-chrome-clear: 64px;  /* clearance band below the floating ×/back glyph so content clears at rest */
```

**Add a NEW section** "SIZING — component dimensions" (place after RADIUS, before/near STROKE):
```css
  /* ── SIZING ─ component dimensions · not gaps, not radii (semantic Sizing tier) ─────*/
  --size-dot:      8px;    /* status/indicator dot diameter                 */
  --size-card-min: 136px;  /* horizontal-scroll card min width (8×17)        */
  --size-chip-min: 104px;  /* adaptive-grid chip min column (8×13)           */
```

> Naming note: the generator camelCases the kebab name keeping the category prefix —
> `--stroke-hairline → Primitive.strokeHairline`, `--space-chrome-clear → Primitive.spaceChromeClear`,
> `--size-dot → Primitive.sizeDot`, `--size-card-min → Primitive.sizeCardMin`,
> `--size-chip-min → Primitive.sizeChipMin`. These names are the contract; the regen must produce them
> verbatim or 0C–0E won't compile.

**Done-when:** the five vars exist with these exact names + px values; placed in the right sections; the
new SIZING section header present. (`foundations.html` token sheet may be updated for human reference but
is not load-bearing for codegen.)

---

### Task 0B — Regenerate `Primitive.generated.swift`

- **Agent / ownership:** the coordinator (or `swift-design-system`) runs the script; this is a generated
  artifact, **not hand-authored**.
- **Command (from worktree root):**
  `swift .claude/scripts/generate-tokens.swift mockups/foundations/foundations.css ios/AppTemplate/DesignSystem/Tokens/Primitive.generated.swift`
- **File (regenerated):** `/Users/shubh/Workspaces/AITravel-app/ios/AppTemplate/DesignSystem/Tokens/Primitive.generated.swift`
- **Serial-edit flag:** this is a generated single file — regenerate atomically, do not parallelize against
  any other edit to it. Commit it in the **same commit** as 0A (code + spec move together, `05 §2`).

**Done-when:** the regenerated file contains, in the lengths block:
`static let strokeHairline: CGFloat = 1`, `static let spaceChromeClear: CGFloat = 64`,
`static let sizeDot: CGFloat = 8`, `static let sizeCardMin: CGFloat = 136`,
`static let sizeChipMin: CGFloat = 104`. No existing primitive changed (the diff is additive only).

---

### Task 0C — `Stroke.swift`: add `hairline`

- **Agent:** `swift-design-system`
- **File (edit):** `/Users/shubh/Workspaces/AITravel-app/ios/AppTemplate/DesignSystem/Tokens/Stroke.swift`
- **Exemplar to read first:** the existing `Stroke.selected` member in the same file (the doc-comment style).
- **Add a member** (declaration contract, not a body):
  `static let hairline: CGFloat = Primitive.strokeHairline`
- **Doc-comment must say:** a 1pt hairline rule — the thickness of a separator/divider line, the design's
  thinnest legal rule; reference `03 §1`'s carve-out that sub-pixel glass hairlines / 1pt rules are the
  sole off-the-8pt-grid exception (a stroke width is not a layout dimension, so it is **not** snapped).

**Done-when:** `Stroke.hairline` exists, aliases `Primitive.strokeHairline`, documented as above; file
references no literal and no raw primitive at a call site (it *is* the semantic tier, so aliasing
`Primitive.*` here is correct).

---

### Task 0D — `Spacing.swift`: add `chromeClearance`

- **Agent:** `swift-design-system`
- **File (edit):** `/Users/shubh/Workspaces/AITravel-app/ios/AppTemplate/DesignSystem/Tokens/Spacing.swift`
- **Serial-edit flag:** `Spacing.swift` is hand-authored and small, but flag it as a shared semantic-tier
  file — serialize against 0C/0E only if an agent batches the three token edits; otherwise these three are
  disjoint files and parallelizable.
- **Exemplar to read first:** the existing `Spacing.screenInset` member + its "Layout margin" MARK — it is
  the precedent for a **named layout role that is not a gap-ladder rung** (lines 41–45).
- **Add a member** under a new (or the existing "Layout margin") MARK:
  `static let chromeClearance: CGFloat = Primitive.spaceChromeClear`
- **Doc-comment must say:** the clearance band below the floating ×/back glyph so scroll content doesn't
  collide with the chrome at rest. It is a **named LAYOUT role** like `screenInset` — **exempt from the gap
  ladder** (it is not a between-group rhythm gap; the ladder doc-comment at lines 9–10 already establishes
  that a named role exists only where a primitive plays a layout role, e.g. `screenInset`). 64 is on the
  8pt spine (8×8); document the snap from the prior 68.

**Done-when:** `Spacing.chromeClearance` exists, aliases `Primitive.spaceChromeClear`, documented as a
layout-role exemption (mirroring `screenInset`), references no literal.

---

### Task 0E — NEW `Sizing.swift` semantic enum

- **Agent:** `swift-design-system`
- **File (CREATE):** `/Users/shubh/Workspaces/AITravel-app/ios/AppTemplate/DesignSystem/Tokens/Sizing.swift`
- **Serial-edit flag:** new file → no serialization needed for the file itself, BUT it must be **added to
  the Xcode project** (`.pbxproj`) — flag the `.pbxproj` edit as serial (the coordinator serializes any
  `project.pbxproj` mutation). Confirm whether the project uses file-system synchronized groups (no
  `.pbxproj` edit needed) before assuming a manual membership edit.
- **Exemplar to read first:** `Stroke.swift` and `Radius.swift` — caseless `enum`, `static let` members
  aliasing `Primitive.*`, a header doc explaining the tier's role and why it is a distinct ladder.
- **Members (declaration contract):**
  - `static let dot: CGFloat = Primitive.sizeDot`        — status/indicator dot diameter
  - `static let cardMin: CGFloat = Primitive.sizeCardMin`  — horizontal-scroll card min width
  - `static let chipMin: CGFloat = Primitive.sizeChipMin`  — adaptive-grid chip min column
- **Header doc must say:** this is the **component-dimension** semantic tier — fixed component sizes by
  role, aliasing codegen'd `Primitive.size*`. It mirrors the other semantic tiers (`Stroke`/`Radius`) one
  file each. It exists because component dimensions have no home in the existing tiers: `Spacing` is the
  *gap ladder* (between-group rhythm, `03 §2`), `Radius`/`Stroke` hold corner/border widths — a dot
  diameter or a card min-width is none of those. Note each value is on the 8pt spine (8 / 136=8×17 /
  104=8×13) and is a **min/ideal** size, not a fixed frame — `05 §5`'s "no fixed frames" rule is honored
  because these seed `@ScaledMetric` and are applied via `minWidth:` (content still drives the rest).
- **Caseless enum** (`05 §1`: token enums are caseless).

**Done-when:** `Sizing` enum exists with the three members aliasing the three `Primitive.size*`;
documented as the component-dimension tier with the rationale above; compiles; added to the target.

---

### Task 0F — Mockup coherence (flag, do not block)

- **Agent / ownership:** `mockups/` direct edit (`mockups-screen-builder`), **not** a `swift-*` agent.
- **Files (edit):**
  - `/Users/shubh/Workspaces/AITravel-app/mockups/screens/onboarding/state-a-screen-03-base-location.html`
  - `/Users/shubh/Workspaces/AITravel-app/mockups/screens/onboarding/state-b-screen-03-base-location.html`
  - `/Users/shubh/Workspaces/AITravel-app/mockups/screens/onboarding/state-c-screen-03-base-location.html`
- **Change:** the `.alt` rule (line ~53 in each) currently hardcodes `min-width: 134px` (a literal — a
  token-discipline failure under `mockups/CLAUDE.md`). Change to `min-width: var(--size-card-min);`
  (136px). The committed mockup screenshots have a **≤2px delta** from this snap — within the
  fidelity-reviewer's rhythm tolerance. **Flag, don't block:** the screenshots may be re-committed for
  exactness but a 2px card-min delta is not drift.
- **Out of scope (note only):** the `.alt` rule also carries other off-grid literals (`padding: 11px 13px`,
  `font-size: 10/14px`) — these are pre-existing and **not** part of this task; do not touch them.

**Done-when:** the three base-location mockups reference `var(--size-card-min)` for `.alt` min-width; the
≤2px screenshot delta is noted for the fidelity-reviewer.

---

## The 5 view edits (Phase 2 — gated behind the freeze)

**Who owns existing-view edits.** These are EXISTING screens, not new scaffolds, so `swift-screen-builder`
(which scaffolds new screens) is not a clean fit. The coordinator dispatches **`swift-design-system`** for
these mechanical seed-replacements (the change is a design-token reference swap, the design-system agent's
domain) **with the precise per-line edit instructions below**, OR `swift-screen-builder` with the same
instructions if the coordinator prefers the screen-owning agent. Either way the edits are **purely
mechanical**: replace the literal seed with the token reference; keep every `relativeTo:` text-style anchor
exactly as-is; change nothing else. The five files are **disjoint → parallelizable**.

Each call-site line numbers are pre-edit (as of this plan); the agent should locate by the `@ScaledMetric`
property name, not the line number, in case the file drifts.

### Task 2A — `GettingAroundStepView.swift` (3 seeds)
- **File:** `/Users/shubh/Workspaces/AITravel-app/ios/AppTemplate/Screens/Onboarding/GettingAroundStepView.swift`
- **Edits (seed → token, keep the wrapper + anchor):**
  - `:215` `@ScaledMetric(relativeTo: .body) private var separatorThickness: CGFloat = 1`
    → seed `= Stroke.hairline`  (stroke width — NOT snapped; stays 1) — used at `:107`, `:150` as `.frame(height: separatorThickness)`
  - `:216` `@ScaledMetric(relativeTo: .caption2) private var suggestedDotSize: CGFloat = 6`
    → seed `= Sizing.dot`  (snapped 6 → 8) — used at `:175` as `.frame(width: suggestedDotSize, height: suggestedDotSize)`
  - `:217` `@ScaledMetric(relativeTo: .body) private var topChrome: CGFloat = 68`
    → seed `= Spacing.chromeClearance`  (snapped 68 → 64) — used at `:28` as `Color.clear.frame(height: topChrome)`
- **Done-when:** all three seeds reference the token; no literal remains in any `@ScaledMetric`; the three
  `relativeTo:` anchors (`.body`, `.caption2`, `.body`) unchanged.

### Task 2B — `DestinationStepView.swift` (2 seeds)
- **File:** `/Users/shubh/Workspaces/AITravel-app/ios/AppTemplate/Screens/Onboarding/DestinationStepView.swift`
- **Edits:**
  - `:277` `selectionRingWidth: CGFloat = 2` → seed `= Stroke.selected`  (EXISTS; 2, not snapped) — used at `:254` `.strokeBorder(..., lineWidth: selectionRingWidth)`
  - `:279` `topChrome = 68` → seed `= Spacing.chromeClearance`  (68 → 64) — used at `:61` `.padding(.top, topChrome)`
- **Done-when:** both seeds tokenized; `relativeTo: .body` unchanged on both.

### Task 2C — `BaseLocationStepView.swift` (2 seeds)
- **File:** `/Users/shubh/Workspaces/AITravel-app/ios/AppTemplate/Screens/Onboarding/BaseLocationStepView.swift`
- **Edits:**
  - `:20` `topChrome = 68` → seed `= Spacing.chromeClearance`  (68 → 64) — used at `:54` (top clearance)
  - `:211` (inside `private struct AltNeighborhoodCard`) `minCardWidth: CGFloat = 134` → seed `= Sizing.cardMin`  (snapped 134 → 136) — used at `:223` `.frame(minWidth: minCardWidth, alignment: .leading)`
- **Done-when:** both seeds tokenized; both `relativeTo: .body` unchanged.

### Task 2D — `GeneratingStepView.swift` (1 seed)
- **File:** `/Users/shubh/Workspaces/AITravel-app/ios/AppTemplate/Screens/Onboarding/GeneratingStepView.swift`
- **Edit:** `:18` `topChrome = 68` → seed `= Spacing.chromeClearance`  (68 → 64) — used at `:46` (top clearance)
- **Done-when:** seed tokenized; `relativeTo: .body` unchanged.

### Task 2E — `TripShapeStepView.swift` (2 seeds)
- **File:** `/Users/shubh/Workspaces/AITravel-app/ios/AppTemplate/Screens/Onboarding/TripShapeStepView.swift`
- **Edits:**
  - `:196` `interestChipMinWidth: CGFloat = 104` → seed `= Sizing.chipMin`  (104, already on grid 8×13) — used at `:165` `GridItem(.adaptive(minimum: interestChipMinWidth))`
  - `:198` `topChrome = 68` → seed `= Spacing.chromeClearance`  (68 → 64) — used at `:27` (top clearance)
- **Done-when:** both seeds tokenized; anchors (`.subheadline`, `.body`) unchanged.

> **Slop / drift guard for all of Phase 2:** the *only* permitted diff is the seed expression. No spacing,
> color, frame, or structure change. No `relativeTo:` anchor change. A view must reference the semantic
> tier (`Stroke`/`Spacing`/`Sizing`), never `Primitive.*` and never a literal (`05 §1` rule).

---

## Verification / the gate (Phase 3)

### 3A — Build clean
```
xcodebuild -project ios/AppTemplate.xcodeproj -scheme AppTemplate \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4.1' \
  CODE_SIGNING_ALLOWED=NO build
```
Zero errors, zero concurrency diagnostics (`05`/`00` non-negotiable #6). Worktree DerivedData.

### 3B — Re-record render-snapshot baselines (IFF any cover the changed call-sites)
**Critical finding — read before re-recording.** The pixel snaps (68→64, 6→8, 134→136) only matter to a
baseline that actually *renders the changed call-site*. Investigation of
`ios/AppTemplateTests/Snapshots/Onboarding/` shows:
- The **full-screen onboarding render snapshots were deleted** (`docs/decisions.md`, 2026-06-02 option-B:
  iOS 26 Liquid Glass renders blank in the offscreen snapshot host). So no screen-level baseline captures
  `topChrome`, `suggestedDotSize`, `separatorThickness`, or `AltNeighborhoodCard.minCardWidth`.
- The **9 surviving component snapshots** (`SegmentedSelector`, `DayStepper`, `Tag`, `SearchWell`,
  `BaseMapCard`, `ContextNote`, `HScrollSection`, `OnboardingProgressBar`, `TripShapeCard`,
  `GenerationProgressView`) are standalone components — **none** instantiate the screen-local subviews that
  hold the changed metrics (the dot/separator/topChrome live in the `*StepView` bodies; `minCardWidth`
  lives in `BaseLocationStepView`'s private `AltNeighborhoodCard`; `interestChipMinWidth` in
  `TripShapeStepView`). Verified: no snapshot test references those symbols.
- **Therefore: no existing render-snapshot baseline needs re-recording for this change.** Confirm by
  running the snapshot suite (it must stay green with no diff):
  ```
  xcodebuild test -project ios/AppTemplate.xcodeproj -scheme AppTemplate \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4.1' \
    -only-testing:AppTemplateTests CODE_SIGNING_ALLOWED=NO
  ```
- **If green with no diff → no re-record.** If any onboarding component snapshot *does* diff (it shouldn't),
  re-record it **explicitly** via the project's record flag (`swift-snapshot-test-writer`, never a silent
  overwrite), review the new image, and commit it.
- **Forward note for the coordinator:** when the Liquid-Glass blank-render gap is fixed and the 5
  full-screen onboarding baselines are restored (per the decisions log), *those* must be recorded against
  the **post-snap** geometry (64 clearance, 8 dot, 136 card-min) — not the pre-snap values.

### 3C — Fidelity-review the affected screens
- **Reviewer:** `fidelity-reviewer`. Screens vs their named mockups in
  `mockups/screens/onboarding/`: `*-screen-01-destination`, `*-screen-02-trip-shape`,
  `*-screen-03-base-location`, `screen-04-getting-around`, `*-screen-05-generate` (across states a/b/c).
- **Tolerance:** the snaps are ≤4px (68→64=4, 134→136=2, 6→8=2) — within layout-rhythm tolerance. The
  base-location card-min snap (134→136) must match the 0F mockup change (`var(--size-card-min)` = 136). The
  ≤2px screenshot delta is a substrate/tolerance note, **not** drift.

### 3D — Design-reviewer on the new tokens + the Sizing tier
- **Reviewer:** `design-reviewer`. Checks: semantic-token-only discipline (the new members alias
  `Primitive.*`, screens reference the semantic tier only); the `Sizing` tier is the right home (or routes
  to the Component tier per the open decision §1); `chromeClearance`/`hairline` documented as layout-role /
  stroke-carve-out exemptions to the gap ladder; J-1 (on-grid), J-10.4 (1px border discipline for
  `hairline`); slop scan (`08-slop.md`) on the new tier (no invented values, all on the 8pt spine).

### 3E — `docs/decisions.md` append-only entry
- **File (edit):** `/Users/shubh/Workspaces/AITravel-app/docs/decisions.md` (append; never edit prior).
- **Record:** (1) the off-grid→on-grid **snap** (chrome clearance 68→64, alt-card min 134→136, suggested
  dot 6→8) — rationale: 68/134/6 were off the 8pt spine (`03 §1`: off-grid is a bug); the literals were
  also a token-discipline violation, so tokenizing was the moment to snap. (2) the introduction of the
  **`Sizing` semantic tier** — rationale: component dimensions (dot diameter, card-min, chip-min) had no
  home in `Spacing`/`Radius`/`Stroke`; `05 §1` names only three tiers and no `Sizing` enum, so this is a
  non-obvious call worth logging (and the alternative — Component-tier constants — was considered). (3)
  note 104 and the 1pt hairline were **not** snapped (already on-grid; a stroke width is the `03 §1`
  carve-out). Header format mirrors existing entries: `## 2026-06-03 — <title>` + **Decision** / **Why** /
  **Supersede when**.
- **Serial-edit flag:** append-only shared file — serialize.

### 3F — `swift-code-reviewer` before commit
- Confirms: no literal/raw-primitive at any view call-site; only seed expressions changed in Phase 2;
  `relativeTo:` anchors intact; new tokens caseless + documented; generated file regenerated (not
  hand-edited) and committed with the CSS; zero concurrency diagnostics.

---

## Task summary (agent · files · disjoint-or-serial)

| # | Phase | Agent | File(s) | Disjoint/Serial |
|---|---|---|---|---|
| 0A | 0 | mockups-screen-builder (direct) | `mockups/foundations/foundations.css` | disjoint (mockups tree) |
| 0B | 0 | coordinator / codegen script | `Primitive.generated.swift` (regen) | **serial** (generated, same commit as 0A) |
| 0C | 0 | swift-design-system | `Tokens/Stroke.swift` | disjoint |
| 0D | 0 | swift-design-system | `Tokens/Spacing.swift` | semantic-tier; disjoint file (serialize only if batched w/ 0C/0E) |
| 0E | 0 | swift-design-system | `Tokens/Sizing.swift` (NEW) + `.pbxproj` membership | file disjoint; **`.pbxproj` serial** |
| 0F | 0 | mockups-screen-builder (direct) | 3× `screens/onboarding/*-screen-03-base-location.html` | disjoint (mockups tree) |
| 2A | 2 | swift-design-system (or screen-builder) | `Screens/Onboarding/GettingAroundStepView.swift` | disjoint |
| 2B | 2 | swift-design-system | `Screens/Onboarding/DestinationStepView.swift` | disjoint |
| 2C | 2 | swift-design-system | `Screens/Onboarding/BaseLocationStepView.swift` | disjoint |
| 2D | 2 | swift-design-system | `Screens/Onboarding/GeneratingStepView.swift` | disjoint |
| 2E | 2 | swift-design-system | `Screens/Onboarding/TripShapeStepView.swift` | disjoint |
| 3A | 3 | coordinator | build | — |
| 3B | 3 | swift-snapshot-test-writer | `AppTemplateTests/Snapshots/Onboarding/` (likely no-op) | serial if re-record needed |
| 3C | 3 | fidelity-reviewer | review only | — |
| 3D | 3 | design-reviewer | review only | — |
| 3E | 3 | coordinator | `docs/decisions.md` | **serial** (append-only) |
| 3F | 3 | swift-code-reviewer | review only | — |

---

## Open decisions for the coordinator

1. **`Sizing` tier home (§1).** `05-design-system.md §1` names only Primitive/Semantic/Component tiers and
   does not prescribe a `Sizing` enum. This plan implements the user's decision — a new `Sizing` semantic
   enum. If `design-reviewer` (§3D) rules the **Component tier** is the correct home, the three members move
   into the relevant `private struct`s as component constants (still seeded from `Primitive.size*`), and the
   Phase 2 call-sites reference the local constant instead of `Sizing.*`. Settle before dispatching 0E/2*.
2. **`.pbxproj` vs synchronized groups.** Confirm whether `AppTemplate.xcodeproj` uses file-system
   synchronized groups (a new `Sizing.swift` is auto-included, no `.pbxproj` edit) or needs an explicit
   membership edit (serial `.pbxproj` mutation). Determines whether 0E carries a serial sub-task.
3. **Restored full-screen snapshots.** This change does not re-record any baseline (none cover the
   call-sites — §3B). When the Liquid-Glass blank-render gap is fixed and the 5 onboarding screen snapshots
   are restored, they must be recorded against post-snap geometry. Out of scope here; flagged for the gap's
   fix-forward.
