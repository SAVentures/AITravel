# Track B — Accessibility Ownership Remediation (Onboarding)

Contract-level plan. Every Swift file goes through the `swift-*` pipeline; the coordinator dispatches via
the `ios-subagent-development` skill. **All paths are worktree-absolute** under
`/Users/shubh/Workspaces/AITravel-app/.claude/worktrees/onboarding-test-quality/`.

## The principle this plan enforces

> A reusable component owns the **mechanism** of its accessibility — an **identifier passthrough** plus its
> own label / value / trait. The **caller** owns the **values** (the concrete id string, the human label).

- **Reference exemplar (in repo, do this):** `OnboardingActionFloor` — bakes no id, exposes
  `primaryAccessibilityID`/`ghostAccessibilityID`, applies them at the leaf.
  (`…/DesignSystem/Composition/OnboardingActionFloor.swift`)
- **Anti-patterns being removed:** `SearchWell` (bakes `onboarding.search` + `.isSearchField` on a
  `.combine` element → call sites double-stamp), `GlassCircleButton` (no passthrough → 6+ screens
  hand-attach the id as a sibling modifier), and the `?? ""` empty-id foot-gun in three composition
  primitives.

## Confirmed-against-source facts (load-bearing)

| Fact | Confirmed at |
|---|---|
| `SearchWell` bakes `.accessibilityIdentifier("onboarding.search")` on a `.accessibilityElement(children: .combine)` element, line 81/84; also `.isSearchField` + label "Search cities" baked | `SearchWell.swift:81-84` |
| `searchwell.clear` lives on the clear `Button` **inside** the `.combine` subtree → can't resolve as its own element (dead id) | `SearchWell.swift:66`, combined at `:81` |
| Call site 1 double-stamps `destination.search` on the SearchWell | `DestinationStepView.swift:105` |
| Call site 2 double-stamps `addresspicker.search` on the SearchWell | `ManualAddressPickerSheet.swift:97` |
| `GlassCircleButton` has no `accessibilityID` param; screens attach the id as a sibling `.accessibilityIdentifier(...)` | `GlassCircleButton.swift:36-46`; screens below |
| `onboarding.close` / `.back` hand-attached at 6 screen sites | Destination:82, TripShape:50, When:45, BaseLocation:79, GettingAround:56; Generating uses **`onboarding.cancel`** :57 |
| `LeadingGlyph` is **dead** (defined, never read — `findReferences` empty; its only mention is `OnboardingFlowPresenter.leadingGlyph`, itself unused) | `LeadingGlyph.swift`, presenter `:26` |
| `?? ""` empty-id sites | `OnboardingActionFloor.swift:49,55`; `ActionBar.swift:105,113`; `HScrollSection.swift:57` |
| `OnboardingProgressBar` already exposes `.accessibilityValue("Step N of M")` (line 27) but the rendered `NN / 06` counter is `.accessibilityHidden(true)` (line 67) and the bar is `children: .ignore` | `OnboardingProgressBar.swift:25-27, 55-68` |
| The Track-A `.elementDetection` suppression on the progress **counter** node lives in **GettingAround** UITests (empty-id/empty-label decorative node = the `NN / 06` text) | `OnboardingGettingAroundUITests.swift:486-505` |
| BaseLocation's `.elementDetection` extra suppression is the **static-map placeholder**, NOT the progress counter — it STAYS | `OnboardingBaseLocationUITests.swift:457-459, 487-490` |
| `DayStepper` already owns `.accessibilityValue("\(clamped) \(unit)")` via `children: .contain` | `DayStepper.swift:62-63` |
| `SegmentedSelector` stamps per-segment ids/traits but exposes **no group value** | `SegmentedSelector.swift:56-57` |
| `GettingAround` rec card has **no** `gettingaround.rec` id (only `baselocation.rec` exists) | `GettingAroundStepView.swift:77-116` |
| `WhenStepPresenter.selectedMonthLabel` exists (the value to read) | `WhenStepPresenter.swift:33` |
| Component snapshot suite exists; `assertDesignSnapshot(_:named:)` is the pinned seam; no AX5 variants yet | `…/AppTemplateTests/Support/DesignSnapshot.swift`, `Snapshots/Onboarding/*` |
| Glass-bearing screen/`GlassCircleButton`/`OnboardingActionFloor` snapshots render BLANK offscreen and were deleted; the AX5 compensating control was lost (the §7.4 defect this plan closes) | `decisions.md` 2026-06-03 entries (157, 199) |

**The components this plan AX5-snapshots are all glass-free** (ContextNote, DayStepper, SegmentedSelector,
GenerationProgressView, OnboardingProgressBar), so they ARE fillable — they sidestep the blank-glass gap.

---

## Phase ordering — foundation-freeze barrier is explicit

```
Wave 1  COMPONENT A11Y OWNERSHIP   (swift-design-system; DS components + composition primitives)
        ──────────────────[ FOUNDATION RE-FREEZE BARRIER ]──────────────────
        Wave 1 changes the a11y MECHANISM of reusable components. No screen rewiring (Wave 2)
        and no test update (Wave 3) is dispatched until Wave 1 lands + swift-code-reviewer +
        design-reviewer pass + the affected component snapshots are confirmed unchanged/re-recorded.
Wave 2  SCREEN / COMPONENT ANNOTATIONS   (swift-design-system + swift-screen-builder)
        ── runs partly in parallel with Wave 3 test authoring, but UITest id updates (3.x) must
           land in the SAME wave as / immediately after the screen rewiring that renames their ids.
Wave 3  ROBUST TESTS   (swift-test-writer · swift-snapshot-test-writer · swift-uitest-writer)
Wave 4  REGRESSION GATES (prose / tooling — `.claude/` + docs)   ← tail wave, may be a follow-up PR
```

**Critical identifier-rename coordination point.** Wave 1 makes `SearchWell` and `GlassCircleButton`
own their ids, which means the *screen-supplied* values now flow through the component's own element
instead of a double-stamped sibling. The **identifier strings do not change** (still `destination.search`,
`addresspicker.search`, `onboarding.back`, `onboarding.close`, `onboarding.cancel`) — but the element they
resolve on, and whether the dead `onboarding.search`/`searchwell.clear` ids exist, DO change. Therefore:
- Tasks 1.1/1.2 (component) and 2.1/2.2 (screen rewiring) and 3.1 (UITest hedge removal) form **one
  serialized chain per component** — they touch the contract together. Dispatch 1.x first; gate 2.x and
  3.x behind it.
- The single highest-risk site is **`SearchWell` dropping `.combine`** (see Task 1.1): that is the one
  change whose VISIBLE structure may shift the a11y tree enough to require re-recording `SearchWell`
  snapshots AND flipping the `searchFields → textFields` hedge in two UITest files at once.

---

# WAVE 1 — Component a11y ownership (land FIRST; collapses ~5 findings)

**Agent for all of Wave 1: `swift-design-system`.** Reviewed by `swift-code-reviewer` + `design-reviewer`.
Files are **disjoint** across the three tasks (different component files) — batchable in parallel — EXCEPT
they each gate downstream screen/test tasks. Exemplar to read first for every task: `OnboardingActionFloor.swift`.

### Task 1.1 — `SearchWell` owns its a11y mechanism (caller owns the id) — DISJOINT
- **File:** `ios/AppTemplate/DesignSystem/Components/SearchWell.swift`
- **Exemplar:** `OnboardingActionFloor.swift` (caller-supplied id, baked none).
- **Signature change — add to `init` and the stored props:**
  - `accessibilityID: String? = nil`
  - `accessibilityLabel: String? = nil` (caller-supplied human label; falls back to a sensible default when nil)
- **Mechanism the component now owns:**
  - STOP baking `.accessibilityIdentifier("onboarding.search")` (remove line 84).
  - Apply the caller's id conditionally — **no `?? ""`** (mirror Task 1.3): apply
    `.accessibilityIdentifier` only when `accessibilityID != nil`.
  - Apply the caller's label when supplied; keep `.isSearchField` trait.
  - **Fix the swallowed `searchwell.clear`:** the clear `Button` is inside the `.combine` subtree so its id
    can never resolve. Resolve this one of two ways (executor picks per live behavior, document the choice
    in the file header):
    - **(preferred) drop `.accessibilityElement(children: .combine)`** so the field and the clear button
      stay independent a11y elements (the field already exposes label + `.isSearchField`; the clear button
      keeps `searchwell.clear` + "Clear search"). This is the **VISIBLE-structure change** flagged for
      snapshot re-record. — OR —
    - keep `.combine` but **remove the dead `searchwell.clear` id and its "Clear search" label** (they are
      unreachable under combine) and rely on the combined label only.
- **Done-when:**
  - `SearchWell` contains **zero** literal `.accessibilityIdentifier("…")` calls (no `onboarding.search`).
  - Passing `accessibilityID: "x"` makes the well resolve as id `x`; passing `nil` attaches no id modifier.
  - If `.combine` is dropped: `searchwell.clear` resolves as its own button. If kept: the dead
    `searchwell.clear` id/label are gone.
  - `swift-code-reviewer` confirms no `?? ""`; `design-reviewer` confirms the fill-well treatment (J-10.2)
    is visually unchanged.
- **Tests touched by THIS task's id-mechanism change (must update in Wave 3, gated behind 1.1):**
  `OnboardingDestinationUITests.swift` (hedge at :176-183, :237-245),
  `OnboardingBaseLocationUITests.swift` (hedge at :406-414, :440).
- **Snapshot impact:** if `.combine` is dropped → **re-record `SearchWellSnapshotTests`** (a11y-tree change
  can alter nothing visible, but the executor must run the suite and re-record ONLY if a diff appears).

### Task 1.2 — `GlassCircleButton` owns an id passthrough; revive `LeadingGlyph` — DISJOINT (2 files)
- **Files:**
  - `ios/AppTemplate/DesignSystem/Components/GlassCircleButton.swift`
  - `ios/AppTemplate/DesignSystem/Components/LeadingGlyph.swift`
- **Exemplar:** `OnboardingActionFloor.swift`.
- **`GlassCircleButton` change:**
  - Add `accessibilityID: String? = nil` to `init` + stored props.
  - Apply `.accessibilityIdentifier` **conditionally** (non-nil only — no `?? ""`).
  - Keep the existing `.accessibilityLabel(accessibilityLabel)` + `.isSelected` trait mechanism unchanged.
- **`LeadingGlyph` revival (confirmed DEAD via `findReferences` → no refs):** keep the enum
  (`close`/`back` → `systemImage` / `accessibilityID` / `accessibilityLabel`) and add a
  **convenience init on `GlassCircleButton`** so a screen can pass a `LeadingGlyph` and an action:
  ```
  // SKETCH — executor reconciles arg order/labels against live GlassCircleButton.init
  init(_ glyph: LeadingGlyph, action: @escaping () -> Void)
  //   → systemImage: glyph.systemImage,
  //     accessibilityLabel: glyph.accessibilityLabel,
  //     accessibilityID: glyph.accessibilityID,
  //     action: action
  ```
  This makes `LeadingGlyph` the single owner of the close/back glyph→label→id mapping.
- **NOTE — `GeneratingStepView` uses `onboarding.cancel`** (an X-style *cancel-generation* glyph, NOT nav).
  It is **not** a `LeadingGlyph` case. It adopts the plain `accessibilityID:` passthrough (Task 2.2), not
  the convenience init. (Open decision OD-1 below: whether to add a `.cancel` case to `LeadingGlyph`.)
- **Done-when:**
  - `GlassCircleButton` contains **zero** literal `.accessibilityIdentifier`; passing `accessibilityID`
    resolves the button by that id; `nil` attaches no modifier.
  - `GlassCircleButton(LeadingGlyph.back, action:)` compiles and yields a button with id `onboarding.back`,
    label "Back", glyph `chevron.left`; `.close` → `onboarding.close` / "Close" / `xmark`.
  - `LeadingGlyph` now has ≥1 real reference (the convenience init / the screens in Task 2.2).
  - `swift-code-reviewer` confirms no `?? ""`.
- **Snapshot impact:** none visible (id is non-rendering). `GlassCircleButtonSnapshotTests` should remain
  byte-identical — confirm, do not re-record. (Recall: glass renders blank offscreen per `decisions.md`;
  that pre-existing gap is unchanged by this task.)
- **Tests touched (Wave 3, gated behind 1.2):** the back/close/cancel queries in
  `OnboardingFlowUITests`, `OnboardingWhenUITests`, `OnboardingGettingAroundUITests`, plus
  `OnboardingRobot.backButton` — all keep the SAME id strings, so they keep working; they only need a
  comment refresh noting the id is now component-owned (no functional edit required unless a query breaks).

### Task 1.3 — Kill the empty-id foot-gun (`?? ""`) in the composition primitives — SHARED-FILE-AWARE
- **Files (three composition primitives, disjoint from Wave-1 components but each is a serial-edit file
  the coordinator already serializes elsewhere — flag each):**
  - `ios/AppTemplate/DesignSystem/Composition/OnboardingActionFloor.swift` (lines 49, 55)
  - `ios/AppTemplate/DesignSystem/Composition/ActionBar.swift` (lines 105, 113)
  - `ios/AppTemplate/DesignSystem/Composition/HScrollSection.swift` (line 57)
- **Change:** replace every `.accessibilityIdentifier(<optional> ?? "")` with a **conditional apply** — the
  modifier is attached only when the value is non-nil. Use a small private `@ViewBuilder` helper or an
  `if let` wrapper; do NOT introduce a new public modifier without design-review (an empty `""` id is a
  silent foot-gun: it stamps a real-but-blank id that the audit's `.elementDetection` then flags as a
  decorative empty-id node — exactly the noise Track A had to suppress).
- **Done-when:** zero `?? ""` on any `.accessibilityIdentifier` in `DesignSystem/`; a `nil` id yields no
  identifier modifier (verify: an unstamped `HScrollSection` exposes no empty-id child in the a11y tree).
- **Snapshot impact:** none (non-rendering).
- **Serial-edit flag:** `ActionBar.swift` and `OnboardingActionFloor.swift` are touched by other waves'
  reviewers; coordinator serializes edits to each.

---

# WAVE 2 — View / component annotations (the under-annotated side)

Gated behind Wave 1 freeze. Mixed agents; files disjoint except where noted.

### Task 2.1 — `SegmentedSelector` exposes a group value — `swift-design-system` — DISJOINT
- **File:** `ios/AppTemplate/DesignSystem/Components/SegmentedSelector.swift`
- **Change (mechanism owned by component, value by caller):**
  - Add `accessibilityLabel: String` param (caller supplies the group label, e.g. "Date precision").
  - Wrap the `track` in `.accessibilityElement(children: .contain)` is wrong for an adjustable summary —
    instead expose the **group** as one element: apply `.accessibilityElement(children: .ignore)` (or
    `.combine`) at the track level with `.accessibilityLabel(accessibilityLabel)` +
    `.accessibilityValue(label(selection))` so VoiceOver reads e.g. "Date precision, Exact dates" as one
    adjustable control. **Keep** the per-segment ids/traits available for the XCUITest tap path — executor
    reconciles `children:` mode against live VoiceOver behavior (SKETCH; do not assume `.ignore` hides the
    tappable segments from XCUITest — confirm both the group value AND `when.precision.*` ids still resolve).
- **Callers supply the label (Task 2.4 rewires them):** `WhenStepView` → "Date precision";
  `BaseLocationStepView` → "Base location mode"; `GettingAroundStepView` "Mostly" tier → "Primary transport".
- **Done-when:** the selector resolves a group `accessibilityValue` equal to the selected option's label;
  per-segment ids (`when.precision.<id>`, `basemode.<id>`, `transport.mostly.<id>`) still resolve for taps.
- **Snapshot impact:** none visible → **do not re-record** `SegmentedSelectorSnapshotTests` (confirm
  byte-identical). AX5 variant added in Wave 3 (Task 3.4).
- **Tests:** new group-value assertion in Wave 3 (Task 3.2); the existing per-segment UITests keep passing.

### Task 2.2 — Screen glyph rewiring to the component-owned id passthrough — `swift-screen-builder`
- **Files (6, disjoint — one screen each, batchable):**
  - `…/Screens/Onboarding/DestinationStepView.swift` (close, :74-83)
  - `…/Screens/Onboarding/WhenStepView.swift` (back, :37-46)
  - `…/Screens/Onboarding/BaseLocationStepView.swift` (back, :71-80)
  - `…/Screens/Onboarding/GettingAroundStepView.swift` (back, :48-57)
  - `…/Screens/Onboarding/TripShapeStepView.swift` (back, :43-50)
  - `…/Screens/Onboarding/GeneratingStepView.swift` (cancel, :50-57)
- **Change:** stop hand-attaching `.accessibilityIdentifier("onboarding.…")` as a sibling. Instead:
  - Nav glyphs (back/close): use the `GlassCircleButton(LeadingGlyph.back/.close, action:)` convenience
    init from Task 1.2. Remove the now-redundant sibling `.accessibilityIdentifier` and the
    `accessibilityLabel:`/`systemImage:` args (LeadingGlyph owns them).
  - GeneratingStepView cancel: keep `GlassCircleButton(systemImage:accessibilityLabel:…)` and pass
    `accessibilityID: "onboarding.cancel"` (the passthrough), removing the sibling modifier.
- **Done-when (per screen):** the screen has **zero** sibling `.accessibilityIdentifier("onboarding.…")` on
  the glyph; the button still resolves by the SAME id string; `swift-code-reviewer` confirms the
  logic-out-of-views + the chrome-only glass invariants hold.
- **Snapshot impact:** none visible (glass already blank offscreen per `decisions.md`; ids non-rendering).
- **Tests (MUST update same-wave / immediately after — id strings unchanged so these are comment-only
  unless a query breaks):** `OnboardingFlowUITests`, `OnboardingWhenUITests`, `OnboardingGettingAroundUITests`,
  `OnboardingRobot.backButton`.

### Task 2.3 — `WhenStepView` month `Menu` annotations — `swift-screen-builder` — DISJOINT (shares file with 2.2's When edit → SERIALIZE)
- **File:** `…/Screens/Onboarding/WhenStepView.swift` (the `monthMenu`, :89-114)
- **Change:** on the `Menu` (already id `when.month`, :113) add
  `.accessibilityLabel("Trip month")` + `.accessibilityValue(p.selectedMonthLabel)`; mark the decorative
  `calendar` glyph (:98) and `chevron.up.chevron.down` glyph (:105) `.accessibilityHidden(true)`.
- **Done-when:** `when.month` resolves a label "Trip month" + a value equal to `selectedMonthLabel`; the two
  glyphs are absent from the a11y tree.
- **Serial-edit flag:** same file as Task 2.2's When edit → **coordinator serializes** 2.2-When and 2.3.
- **Tests:** Wave 3 Task 3.2 asserts the value.

### Task 2.4 — Callers supply the `SegmentedSelector` group label — `swift-screen-builder`
- **Files (3, each shares its file with a 2.2/2.3 edit → SERIALIZE within file):**
  - `…/Screens/Onboarding/WhenStepView.swift` (:69-76) → `accessibilityLabel: "Date precision"`
  - `…/Screens/Onboarding/BaseLocationStepView.swift` (:105-116) → `"Base location mode"`
  - `…/Screens/Onboarding/GettingAroundStepView.swift` (:157-165) → `"Primary transport"`
- **Change:** pass the new `accessibilityLabel:` arg from Task 2.1 at each `SegmentedSelector(…)` call.
- **Done-when:** all three call sites compile against the Task 2.1 signature; group values read correctly.
- **Serial-edit flag:** WhenStepView (2.2/2.3/2.4), BaseLocation (2.2/2.4), GettingAround (2.2/2.4) — each
  file serialized.

### Task 2.5 — `ManualAddressPickerSheet` map label + non-spatial action — `swift-screen-builder` — DISJOINT
- **File:** `…/Screens/Onboarding/ManualAddressPickerSheet.swift` (the `map`, :56-74)
- **Change:** add `.accessibilityLabel("Map — search a place above or tap a result to drop a pin")` to the
  `Map`/`MapReader` (id already `addresspicker.map`, :72); add a **non-spatial action path** so VoiceOver
  users aren't forced to tap-on-map: add `.accessibilityAction(named: "Drop pin at map center")` driving
  `dropPin(at: searchRegion.center)` (SKETCH — executor confirms `searchRegion.center` is the right
  coordinate and that `dropPin` is callable from the action).
- **Done-when:** `addresspicker.map` carries a non-empty label and a named action; existing search/result
  flow unchanged.
- **Snapshot impact:** none (no component snapshot; L3 map uses the static placeholder seam).
- **Tests:** covered by existing `OnboardingBaseLocationUITests` picker flow (static map); no new assertion
  required beyond label existence (optional in Task 3.x).

### Task 2.6 — `GettingAroundStepView` rec card container + stable id — `swift-screen-builder` — DISJOINT (shares file with 2.2/2.4 GettingAround → SERIALIZE)
- **File:** `…/Screens/Onboarding/GettingAroundStepView.swift` (the `recCard`, :77-116)
- **Change:** wrap the rec card in `.accessibilityElement(children: .contain)` + add
  `.accessibilityIdentifier("gettingaround.rec")`, **mirroring `baselocation.rec`**
  (`BaseLocationStepView.swift:139-141`).
- **Done-when:** `gettingaround.rec` resolves as one container element; the rec eyebrow/line/reasons read as
  its children; structure mirrors `baselocation.rec`.
- **Serial-edit flag:** GettingAround file serialized across 2.2/2.4/2.6.
- **Tests:** Wave 3 may assert `gettingaround.rec` existence (Task 3.2, optional).

### Task 2.7 — `OnboardingProgressBar` exposes a real, non-tiny step value — `swift-design-system` — DISJOINT
- **File:** `…/AppTemplate/DesignSystem/Components/OnboardingProgressBar.swift`
- **Problem:** the bar exposes `.accessibilityValue("Step N of M")` (:27) but the rendered `NN / 06` counter
  text (:55-68) is `.accessibilityHidden(true)`, so `.elementDetection` flags the decorative empty-id text
  node — which Track A SUPPRESSED in `OnboardingGettingAroundUITests` (:486-505).
- **Change (the fix that lets the suppression be removed):** make the counter satisfy `.elementDetection`
  by exposing it as a real, labeled, non-tiny element rather than a hidden decorative node. Concretely:
  - Keep the bar's `.accessibilityValue("Step \(stepIndex+1) of \(totalSteps)")`.
  - On the counter element, replace `.accessibilityHidden(true)` with a real accessible role: give the
    combined counter a non-empty `.accessibilityLabel("Step \(displayStep) of \(totalSteps)")` and ensure it
    is **not** below the elementDetection text-size floor (the digits are `Typography.caption` — confirm the
    rendered size clears the audit's minimum; if it does not, the executor expands the counter's accessible
    element rather than shrinking the visible glyph — VISUAL stays the mockup `.ob-counter`).
  - **Avoid double-readout:** if both the bar value and the counter label announce, prefer ONE — keep the
    bar as the single VoiceOver element (`children: .ignore`, value = step) and make the *counter's* hidden
    state unnecessary by ensuring the bar element itself is what `.elementDetection` sees as labeled. The
    executor reconciles the exact `children:`/hidden combination against a live audit run so that:
    (a) VoiceOver reads "Step N of M" once, and (b) `.elementDetection` no longer flags an empty-id node.
- **Done-when:**
  - VoiceOver announces the step exactly once with value "Step N of M".
  - A `performAccessibilityAudit` over a screen containing the bar **no longer produces** an empty-id
    `.elementDetection` issue for the counter (verified by Task 3.5 removing the suppression and the audit
    staying green).
- **Snapshot impact:** VISIBLE structure unchanged (still the thin bar + `NN / 06`) → confirm
  `OnboardingProgressBarSnapshotTests` byte-identical; **AX5 variant added in Task 3.4**.
- **Hard dependency:** Task 3.5 (remove the GettingAround `.elementDetection` suppression) is gated behind
  this task landing + the audit re-running green.

---

# WAVE 3 — Robust tests

### Task 3.1 — Remove the `searchFields → textFields` hedge — `swift-uitest-writer` — gated behind 1.1
- **Files:**
  - `…/AppTemplateUITests/OnboardingDestinationUITests.swift` (:170-183, :234-245)
  - `…/AppTemplateUITests/OnboardingBaseLocationUITests.swift` (:404-414, :436-440)
- **Change:** now that `SearchWell` owns one clean id (no double-stamp, no swallowed `onboarding.search`),
  replace the `searchFields[id] OR textFields[id]` fallback with a single deterministic query by identifier
  (`destination.search` / `addresspicker.search`). Delete the "known-fragile double-stamp workaround"
  comments (Destination :40, :170-174).
- **Done-when:** each search field is queried exactly once by id; both suites green; no `textFields`
  fallback for the SearchWell id remains.

### Task 3.2 — Assert value/label, not just existence — `swift-uitest-writer` (+ `swift-test-writer` for presenter-level) 
- **Files:**
  - Progress value: a UITest asserting `app.<element>["onboarding.progress"].value == "Step N of M"` on a
    screen where the step is known (e.g. `OnboardingGettingAroundUITests` / `OnboardingFlowUITests`).
  - DayStepper value: assert `daystepper.value`/the contain-element exposes value `"<n> days"` in
    `OnboardingTripShapeUITests` (DayStepper lives on Trip Shape).
  - SegmentedSelector group value: assert the `when.precision` group element's `value` equals the selected
    `DatePrecision.label` in `OnboardingWhenUITests`.
  - (optional) `when.month` value == `selectedMonthLabel`; `gettingaround.rec` existence.
- **Done-when:** each assertion checks `.value`/`.label`, not mere existence; suites green.
- **Note:** combined-container children are not individually L4-queryable (`decisions.md` 2026-06-03) —
  assert the **group/value**, not the hidden children.

### Task 3.3 — *(reserved — folded into 3.1/3.2)*

### Task 3.4 — Restore the AX5 compensating snapshot (closes the §7.4 defect) — `swift-snapshot-test-writer` — DISJOINT (new test methods, may share existing snapshot files)
- **Files (add `_AX5` variants alongside existing methods):**
  - `…/AppTemplateTests/Snapshots/Onboarding/ContextNoteSnapshotTests.swift`
  - `…/AppTemplateTests/Snapshots/Onboarding/DayStepperSnapshotTests.swift`
  - `…/AppTemplateTests/Snapshots/Onboarding/SegmentedSelectorSnapshotTests.swift`
  - `…/AppTemplateTests/Snapshots/Onboarding/GenerationProgressViewSnapshotTests.swift`
  - `…/AppTemplateTests/Snapshots/Onboarding/OnboardingProgressBarSnapshotTests.swift`
- **Mechanism:** reuse the pinned `assertDesignSnapshot(_:named:)` seam (do NOT add a `snapshotDirectory:`
  arg — §6.5). Apply `.environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)` to the view BEFORE
  passing it in, and name the variant `<state>-ax5`. One AX5 variant per component's most type-dense state
  is sufficient (these components are glass-free → they render, sidestepping the blank-glass gap).
  ```
  // SKETCH — executor mirrors the file's existing canvas() + state fixtures
  assertDesignSnapshot(
      canvas { SegmentedSelector(... balanced ...) }
          .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge),
      named: "three-way-selected-ax5"
  )
  ```
- **Done-when:** each of the five suites has ≥1 committed `*-ax5` baseline PNG; first run records + fails
  "recorded", PNGs committed, second run diffs; **no `record: .all` left in code** (§6.3).
- **Doc reconciliation (Wave 4 / inline):** update `decisions.md` entry "the `.dynamicType` audit's AX5
  compensating control is gone" — the control is RESTORED for these glass-free components (the screen-level
  AX5 remains gapped only where glass renders blank). `swift-code-reviewer` confirms against §7.4.

### Task 3.5 — Remove the now-unnecessary `.elementDetection` suppression — `swift-uitest-writer` — gated behind 2.7
- **File:** `…/AppTemplateUITests/OnboardingGettingAroundUITests.swift` (:486-505)
- **Change:** once Task 2.7 makes the progress counter satisfy `.elementDetection`, **remove** the
  screen-specific `extraSuppressions` closure for the empty-id/empty-label progress-counter node; call
  `robot.performOnboardingAudit()` with no extra suppression. Delete the Track-B-follow-up comment.
- **Do NOT touch** BaseLocation's `.elementDetection` extra suppression (:487-490) — that is the
  static-map placeholder, a separate, still-valid exemption.
- **Done-when:** GettingAround audit passes with NO progress-counter suppression; BaseLocation map
  suppression intact.

### Task 3.6 — Tighten suppression discipline in the single audit owner — `swift-uitest-writer` — DISJOINT
- **File:** `…/AppTemplateUITests/Support/OnboardingRobot.swift` (`performOnboardingAudit`, :203-219)
- **Change:** review the common `suppressedTypes` now that AX5 snapshots (3.4) cover `.dynamicType` for the
  type-dense components. **Keep** `.dynamicType`/`.contrast`/`.textClipped` whole-type suppression (still
  systemic FPs on custom fonts / OKLCH-over-glass / minHeight layouts) but **update the doc-comment** so
  each names its NOW-LIVE compensating check (the AX5 snapshots restored in 3.4, not a deleted screen
  snapshot). Confirm `onboarding.progress` + `.hitRegion` stays (informational; `decisions.md`).
- **Done-when:** every whole-type suppression in the owner cites a live compensating check by name (§7.4);
  no new blanket `return true`; the comment no longer says the AX5 control is "gone".

---

# WAVE 4 — Regression gates (prose / tooling) — TAIL WAVE (may be a follow-up PR)

These are `.claude/` + docs edits (direct-edit per the scope rule), **not** Swift pipeline tasks. Lower
priority; land after Waves 1-3 are green.

- **4.1 Component a11y-ownership lint** — add a check (extend the relevant `.claude/scripts/` or the
  `swift-code-reviewer` checklist): a file under `DesignSystem/Components/` or `DesignSystem/Composition/`
  must not contain a **literal** `.accessibilityIdentifier("…")` (string literal) and must not contain
  `.accessibilityIdentifier(<x> ?? "")`. Passthroughs (`.accessibilityIdentifier(someOptionalParam)` applied
  conditionally) are allowed.
- **4.2 Declared-vs-queried id cross-reference** — extend `ios-test-coverage-check` (the coverage-gate
  skill) to cross-reference accessibility ids declared in screens/components against ids queried in
  UITests, flagging an id queried but never declared (the class of bug Track B's double-stamp caused).
- **4.3 Suppression-discipline lint** — flag any `performAccessibilityAudit` whole-type suppression whose
  doc-comment does not name a compensating check; flag any bare `return true`.
- **4.4 Value/label assertion requirement** — add to the coverage gate: a UITest that asserts only
  `.exists`/`waitForExistence` on an element that carries an `accessibilityValue` (progress, stepper,
  segmented group) should also assert that value.
- **Done-when:** the lints run in the commit gate; running them against this branch post-Wave-3 is green.

---

## Open decisions (settle before / during execution)

- **OD-1 — `GeneratingStepView` cancel glyph:** it uses `onboarding.cancel` (cancel-generation), which is
  not a nav back/close. Plan adopts the plain `accessibilityID:` passthrough (Task 2.2). **Decide:** add a
  `.cancel` case to `LeadingGlyph` for symmetry, or keep cancel off the LeadingGlyph enum (it's a different
  semantic — a destructive-ish abort, not navigation). Recommendation: keep it off the enum; LeadingGlyph
  stays the *navigation* glyph owner. No doc blocker either way.
- **OD-2 — `SearchWell` `.combine` drop:** Task 1.1 offers two resolutions for the swallowed
  `searchwell.clear`. Dropping `.combine` is preferred (revives the clear-button id) but is the one change
  that can alter the a11y tree / require a snapshot re-record and the UITest hedge flip in the same wave.
  **Decide** at execution from a live VoiceOver/audit run; default to dropping `.combine`.
- **OD-3 — Double-readout on `OnboardingProgressBar` (Task 2.7):** the exact `children:`/hidden combination
  that satisfies `.elementDetection` without VoiceOver reading the step twice must be confirmed against a
  live audit; the plan fixes the contract (one announcement, no empty-id node) but leaves the precise
  modifier mix to the executor + a live run.

---

## Commit-gate checklist (run before finish-branch)

1. **Build clean** (zero concurrency diagnostics, Swift 6.2 MainActor-by-default):
   `xcodebuild -project ios/AppTemplate.xcodeproj -scheme AppTemplate -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4.1' CODE_SIGNING_ALLOWED=NO build`
2. **Affected-tests selection first** (fast loop): `-only-testing` the touched suites —
   `SegmentedSelectorSnapshotTests`, `DayStepperSnapshotTests`, `ContextNoteSnapshotTests`,
   `GenerationProgressViewSnapshotTests`, `OnboardingProgressBarSnapshotTests`,
   `OnboardingDestinationUITests`, `OnboardingBaseLocationUITests`, `OnboardingWhenUITests`,
   `OnboardingGettingAroundUITests`, `OnboardingFlowUITests`, `OnboardingTripShapeUITests`.
3. **Re-record only where flagged:** `SearchWellSnapshotTests` IF `.combine` was dropped and a diff
   appears; the five new `*-ax5` baselines (first-run record → commit). Review every diff; never commit
   `record: .all`.
4. **Full four-layer pyramid pre-commit** (whole `xcodebuild … test`) green.
5. **`swift-code-reviewer`** pass: no literal/`?? ""` a11y ids in DS components; logic-out-of-views,
   chrome-only-glass, single-AppStore invariants intact.
6. **`design-reviewer` slop pass** (`docs/design-docs/08-slop.md`): SearchWell well treatment, glyph
   chrome, segmented ink-pill, progress bar visual all unchanged vs their named mockups.
7. **Coverage gate** (`ios-test-coverage-check`): every changed component ships its snapshot lock; every
   a11y value added ships a value-asserting test; the Wave-4 lints (if landed) green.
