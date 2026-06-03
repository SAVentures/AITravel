# Onboarding — contract-level implementation plan

**Feature:** AI Travel new-trip onboarding — ONE adaptive `OnboardingFlow`, 5 steps, rendered in 3
data-driven states (A/B/C) selected at runtime by saved-places counts.
**Worktree:** `/Users/shubh/Workspaces/AITravel-app/.claude/worktrees/onboarding` (all paths below are
relative to it unless absolute).
**Executed via:** the `ios-subagent-development` skill from the main loop. The coordinator dispatches the
`swift-*` scaffolders per the wave ordering below; this document is the contract each executes.

This is the **first feature** — `Store/`, `Models/`, `Networking/`, `Screens/` are empty. Phase 0
(tokens + modifiers + components + composition primitives) is locked, design-reviewed, snapshot-locked.
Reuse it; do not rebuild it.

---

## Wave ordering (mirror the foundation-freeze discipline)

```
WAVE 1  New DS components / primitives
          → design-review (J-rules · token discipline · slop scan · J-15)
          → snapshot-lock (swift-snapshot-test-writer)
        ════════════════════ BARRIER (foundation-freeze for the onboarding extension) ════════════════════
          No OnboardingFlow / per-step view is scaffolded until every Wave-1 component is reviewed + locked.
WAVE 2  Domain models (reference TripDraft + value types) + DTOs + toDomain/toDTO + SampleData seed (A/B/C)
          + MockProvider scenarios + the request(s)  → functional tests (round-trip, model methods)
WAVE 3  Store: AppStore stored props (TripDraft ownership, savedHere/savedAnywhere, step nav, generation,
          dismiss-to-root command)  [serial edits to AppStore.swift — see SERIAL list]
WAVE 4  The 5 screens — ONE adaptive OnboardingFlow + per-step views + presenters + Route + catalog
          each → consistency-review → fidelity-review vs the NAMED mockup → snapshot-lock
WAVE 5  Tests: presenter derivation (L1) · integration / command (L2) · render snapshots (L3) ·
          XCUITest across A/B/C MockProvider scenarios + performAccessibilityAudit (L4)
```

**Parallel-safe vs serial.** Within a wave, tasks on disjoint *new* files run in parallel. The
coordinator must **serialize** these shared-file edits:

| Serial edit | File | Wave |
|---|---|---|
| New stored `AppStore` properties (TripDraft, generation state) | `Store/AppStore.swift` | 3 |
| New catalog section for onboarding | `Screens/ScreenCatalogView.swift` | 4 |
| Scenario injection at launch (`UITEST_SCENARIO` → A/B/C) | `App/AppTemplateApp.swift` + `App/RootView.swift` | 3–4 |
| Any `.pbxproj` edit | only if a bundled resource / SPM dep is added | — (none expected; synchronized folders auto-include new `.swift`) |

Everything else (each new component file, each request, each value-type model, each per-step view,
each presenter, each test file) is a **new file → parallel-safe**.

---

## OPEN DECISIONS (confirm before / during execution)

1. **Solid `ActionBar` floor.** The immersive onboarding floor in `screen-shell.css` (`.ob-action`) is a
   **solid** paper gradient floor with a solid blue CTA + an optional ghost button — *not* the glass
   `ActionBar`. Existing `ActionBar` is glass-only (`.glassProminent`/`.glass` in a `GlassEffectContainer`)
   and exposes no ghost slot.
   **Recommendation:** add a screen-local `OnboardingActionFloor` composition primitive (Wave 1, task
   W1-09) rather than overloading `ActionBar` with a `.solid` style — the two have different material,
   different button vocabulary (primary + ghost vs primary + glass-secondary), and onboarding is the only
   immersive-floor consumer. Justification: glass-on-content is forbidden (J-0.1) and the mockup floor is
   explicitly solid; a `.solid` `ActionBar` would fork the one glass primitive's contract. **Needs your
   confirmation** — alternative is `ActionBar(style: .solid, ghost:)`.

2. **Step-02 one-view-two-bodies vs two views.** State A/B render three `TripShapeCard`s; state C renders
   a taste form (stepper + interest chips + pace). These are structurally different bodies under the same
   step + same chrome + same CTA.
   **Recommendation:** ONE `TripShapeStepView` that switches on `presenter.step02Mode` (`.shapeCards` vs
   `.tasteForm`) into two private `@ViewBuilder` bodies in the same file — keeps "one adaptive flow", one
   Route, one catalog entry. **Needs confirmation** vs. two sibling files.

3. **Generate timer / cancel — testable model.** Step 05 auto-advances ~8s through 6 generation steps,
   then dismisses to root; Cancel(×) aborts.
   **Recommendation:** model the generation clock as a store-driven sequence, NOT a view `Task`:
   `AppStore.startGeneration()` advances `generationPlan.currentStepIndex` on a cancellable schedule and,
   on completion, sets `onboarding = nil` (dismiss-to-root). The view only renders
   `presenter.generationSteps` + observes completion; tests drive `store.advanceGeneration()` /
   `store.completeGeneration()` deterministically (no wall-clock in tests, per `07 §3`). The real timer
   uses `store.simulatedNow`-independent `Task.sleep(for: Motion.*)` only in the live path, gated so tests
   call the synchronous advance. **Needs confirmation of the exact seam** (store-advance vs a presenter
   step machine).

4. **MapKit snapshot determinism.** Step 03's base map is real `MapKit` (`Map` + annotations). MapKit
   tiles are non-deterministic and network-dependent → a render snapshot of the live map will flake.
   **Recommendation:** the L3 snapshot of `BaseLocationStepView` excludes the live map region (snapshot a
   variant with `BaseMapCard(snapshotMode: true)` that renders the zone + pins + home marker over a
   **solid neutral placeholder** instead of map tiles — the same footprint). The live `Map` is exercised
   only by the L4 XCUITest (presence of the home marker by a11y id), never pixel-diffed. **Needs
   confirmation** that map-tile fidelity is out of scope for the lock.

5. **Manual-base / specific-hotel — in-scope or stub.** Step 03 has a "Pick manually" segment and a
   "Pick a specific hotel or address" ghost button.
   **Recommendation:** STUB both this milestone — the segment toggles `BaseSelectionMode.smart/.manual`
   in the draft (state captured, testable), but `.manual` renders an `EmptyStateView`("Manual base
   picker coming soon") and the ghost button is present but no-ops with a `// TODO: manual base picker`.
   Onboarding ships the Smart path end-to-end. **Needs confirmation.**

6. **`Motion.think` continuous-loop token.** The generate sweep is the one allowed continuous motion
   (~1700ms repeatForever). `Motion` has no `think` rung and `foundations.css` has no `--dur-think`.
   **Recommendation:** add `--dur-think: 1700ms` to `foundations.css` + regenerate `Primitive` +
   add `Motion.think` (Wave 1, task W1-00, a serial token edit) so the sweep reads a token, not a literal
   (J-0.2 / J-1 duration ladder). This is a token change → re-run codegen in the same commit
   (`05-design-system §2`). **Needs confirmation** (alternative: reuse `Motion.slow` and accept it's
   off-ladder for a continuous loop).

7. **Step-04 transport recommendation card** uses an inline editorial italic (`We'd suggest *transit.*`)
   inside a `.cardSurface()` card — this is a *second* italic editorial moment on the screen if the
   eyebrow also reads as AIVoice. **Recommendation:** the card's "We'd suggest …" line is the screen's one
   editorial italic (J-3.6 / J-6.2); the AI eyebrow above it is a plain mono caps label (reuse the AIVoice
   eyebrow row only, or a `ContextNote`-style label), NOT a second AIVoice line. Confirm the screen keeps
   exactly one italic moment.

---

## Exemplars the executors read first (per task, cited again inline)

- **Components:** `PlaceCard.swift` (the definitive/fuzzy register, `@ScaledMetric`, `cardSurface`),
  `FilterChip.swift` (selected = solid-ink-not-accent + check glyph), `AIVoice.swift` (italic editorial
  + one accent dot), `MapPin.swift` (PinRegister value enum), `PillButton.swift` (tier-driven style),
  `TimeHint.swift` (reach/reason rows), `GlassCircleButton.swift` (the one glass glyph),
  `LoadingSkeleton.swift` (`\.disablesOneShotMotion` env key + Reduce-Motion gating — the generate
  sweep mirrors this).
- **Composition:** `ActionBar.swift`, `ScreenScaffold.swift` + `ScreenChrome.swift`, `ScreenSection.swift`,
  `RhythmSpacer.swift`.
- **Tokens:** `ColorRole.swift`, `Typography.swift`, `Spacing.swift`, `Radius.swift`, `Motion.swift`
  (the day-mark roles `dayMark1…4` already exist for the cover-bucket diagram).
- **Engineering authority:** `ios/docs/engineering/02-models.md` (reference-vs-value, DTO split, seed),
  `03-store.md` (ownership, commands, optimistic+rollback, navigation), `04-networking.md`
  (`APIRequest`, stateless `MockProvider`, `MockScenario`), `06-screens.md` (presenters, routes,
  chrome, fidelity gate, a11y ids), `07-testing.md` (four layers, snapshot determinism §6.4, scenario
  injection §7.1).
- **Visual authority:** `docs/design-docs/06-judgment.md` (J-rules), `04-motion.md` (continuous-motion +
  Reduce-Motion), `05-components.md`, `08-slop.md` (run before each review).

---

# WAVE 1 — New design-system components / primitives

All under `ios/AppTemplate/DesignSystem/`. Owning agent **`swift-design-system`**; snapshots by
**`swift-snapshot-test-writer`**; review by **`design-reviewer`** (J-15 + slop scan) THEN snapshot-lock.
Every component: data in as **value-type args**, no `AppStore`, no domain object (`05 §8`); **semantic
tokens only** (zero literals / `Primitive.*`); **content is never glass** (J-0.1) except where noted;
`@ScaledMetric` for every non-text metric; covers its meaningful states with a `#Preview` per state.

> **Reuse, don't rebuild:** `PlaceCard` (city tiles + their definitive/fuzzy register), `FilterChip`
> (interest chips + Also-OK chips), `AIVoice` (every AI editorial line), `TimeHint` (reach rows + reason
> rows), `MapPin` (map markers), `Tag` (badges), `PillButton` (any non-floor button),
> `GlassCircleButton` (the header close/back glyph), `LoadingSkeleton` (the sweep's motion-gating
> pattern). New components below exist only where the mockups need a vocabulary that doesn't yet exist.

### W1-00 · `Motion.think` token (SERIAL — token + codegen) — *gated on OPEN DECISION 6*
- **Files:** `mockups/foundations/foundations.css` (add `--dur-think: 1700ms;`), regenerate
  `ios/AppTemplate/DesignSystem/Tokens/Primitive.generated.swift` (codegen, never hand-edit),
  add `static let think: Double = Primitive.durThink` to `Tokens/Motion.swift`.
- **Governing rule:** J-1 duration ladder · `04-motion §2/§4`; `05-design-system §2` (codegen same commit).
- **Done-when:** `Motion.think` resolves to 1.7s; `Primitive.durThink` is generated (not transcribed);
  no literal `1700`/`1.7` anywhere in Swift.

### W1-01 · `OnboardingProgressHeader` (composition primitive)
- **File:** `DesignSystem/Composition/OnboardingProgressHeader.swift`
- **Exemplar:** `screen-shell.css` `.ob-header` / `.ob-topbar` / `.ob-progress` / `.ob-counter`;
  reuse `GlassCircleButton` for the leading glyph.
- **Contract:** a sticky frosted (glass — this IS floating chrome, J-0.1) header: a 3-column top row
  `[leading glyph] [spacer] [NN / 05 mono counter]`, a 5-segment neutral progress bar below
  (segments: `todo` = `ColorRole.separatorOpaque`-ish neutral, `done` = a darker neutral, `cur` =
  `textPrimary`). **No accent** in the header (blue is reserved for CTA + the one AI/now mark — shell css
  comment). Args: `stepIndex: Int` (0–4), `totalSteps: Int = 5`, `leadingGlyph: LeadingGlyph`
  (`.close` → "xmark" / `.back` → "chevron.left"), `leadingAction: () -> Void`.
- **Tokens:** `ColorRole.textPrimary` (cur seg + counter bold), `textTertiary`/`separatorOpaque`
  (todo/done segs + counter), `Typography.caption` (mono counter, caps tracking via
  `trackEyebrowCaption`), `Spacing.paired` (segment gap), `glassChrome()` for the frost. `@ScaledMetric`
  for segment height (~4pt base).
- **A11y ids:** `onboarding.progress` (container, with `.accessibilityValue("Step \(n) of 5")`),
  `onboarding.close` / `onboarding.back` (the leading glyph, by case).
- **Governing rule:** `06-screens §2.3` (top bar = back/close only), J-2.4 (no accent in chrome).
- **Done-when:** 5 neutral segments; mono `NN / 05` counter; leading glyph switches close↔back by arg;
  glass frost; no accent; ids present; snapshot per `{close, back} × {step 1, step 3}`.

### W1-02 · `SegmentedSelector<Option>` (component)
- **File:** `DesignSystem/Components/SegmentedSelector.swift`
- **Exemplar:** base-mode `.seg` (2-way), pace `.pace` (3-way), transport `.mostly` (4-way) — all share
  the ink-pill-on-selected pattern (`background: var(--ink-900); color: var(--paper-0)`). Mirror
  `FilterChip`'s "selected = solid ink, NOT the accent" decision and its check-glyph-not-color-alone rule.
- **Contract:** single-select segmented control on a `fillTertiary` pill track; the selected segment is a
  solid-ink (`textPrimary`) pill with `textOnAccent` label; optional leading SF Symbol per segment.
  Generic over an `Identifiable & Hashable` option; args: `options: [Option]`, `selection: Option`,
  `label: (Option) -> String`, `systemImage: (Option) -> String?` (nil = text-only), `onSelect:
  (Option) -> Void`. Selection is conveyed by **fill + weight**, never color alone; pair the selected
  segment with `.accessibilityAddTraits(.isSelected)` (02-color §6).
- **Tokens:** `ColorRole.fillTertiary` (track), `textPrimary` (selected fill), `textOnAccent`
  (selected label), `textSecondary` (unselected label), `Radius.pill`, `Spacing.paired`,
  `Motion.standard(Motion.tap)` press. `@ScaledMetric` 44pt min tap per segment.
- **A11y ids:** caller-supplied namespace via a `accessibilityIDPrefix: String` arg → each segment
  `\(prefix).\(optionID)` (e.g. `basemode.smart`, `pace.balanced`, `transport.mostly.transit`).
- **Governing rule:** J-0.4 / J-2.4 (accent budget — selected ≠ accent), `05-components §5`.
- **Done-when:** 2/3/4-way layouts all from one component; ink-pill selected; icons optional; ids
  parameterized; snapshot per `{2-way, 3-way, 4-way-with-icons}`.

### W1-03 · `DayStepper` (component)
- **File:** `DesignSystem/Components/DayStepper.swift`
- **Exemplar:** `.stepper` in state-a-02 (inline, compact) and state-c-02 (standalone, larger);
  `[− btn] [mono value + display number] [+ btn]` on a `paper-200`/`fillSecondary` pill.
- **Contract:** `−`/value/`+` stepper. The number is the **display face** (`Typography.title`-ish,
  semibold), the unit ("days") is **mono** (`Typography.footnote`). Args: `value: Int`,
  `range: ClosedRange<Int>` (clamp; disable `−` at min, `+` at max), `unit: String = "days"`,
  `onChange: (Int) -> Void`. Buttons are circular plain glyph buttons (NOT glass — content).
- **Tokens:** `ColorRole.fillSecondary` (track), `textPrimary` (number + glyphs), `textSecondary`
  (unit), `Radius.pill`, `Spacing.paired`. `@ScaledMetric` 44pt min for each ± button; number scales
  with Dynamic Type.
- **A11y ids:** `daystepper.decrement` · `daystepper.value` (with `.accessibilityValue("\(n) days")`) ·
  `daystepper.increment`. Combine as a single adjustable element where feasible.
- **Governing rule:** J-0.3 (no fixed frames), J-7.2 (mono numerals tabular).
- **Done-when:** clamps to range; display number + mono unit; ± disable at bounds; ids present;
  snapshot per `{mid-range, at-min, at-max}`.

### W1-04 · `TripShapeCard` (component) — the selectable shape choice w/ embedded diagrams
- **File:** `DesignSystem/Components/TripShapeCard.swift`
- **Exemplar:** `.scard` (state-a-02 selected/definitive, state-b-02 `.off` locked), `PlaceCard` for the
  definitive/fuzzy register + selected-mark pattern.
- **Contract:** a selectable card: `[eyebrow "A · Fixed days"] [display title] [metric strip mono] [+
  embedded diagram]`, with an ink check when selected. Three registers via a value enum
  `TripShapeRegister`: `.selectable` (fuzzy-ish flat paper ground when unselected, definitive
  `cardSurface` + 2pt ink ring + ink check when selected) and `.locked(reason: String)` (the `.off`
  state — `opacity` reduced, a lockline with a lock glyph + reason, NOT tappable). Args: `eyebrow:
  String`, `title: String`, `metricStrip: [MetricToken]` (mono fragments, some `.struck` for
  "skips 9"), `diagram: TripShapeDiagram` (an enum: `.fixedDays(filled:dim:)`, `.coverBucket(dayCounts:)`,
  `.rankedBars(values:[Double], dim:pick:)`), `register`, `isSelected`, `embeddedControl: AnyView?`
  (the inline `DayStepper` for card A), `onSelect`.
- **Sub-views (3 diagrams):** `FixedDaysDiagram` (4 columns of dots, dim trailing), `CoverBucketDiagram`
  (5-col grid of day-colored dots using `ColorRole.dayMark1…4` + a neutral 5th — these roles exist),
  `RankedBarsDiagram` (rows of a rotated-square mark + a bar with `i width %`). Each is a private
  `@ViewBuilder` in the same file, semantic tokens only.
- **Tokens:** `cardSurface()` (definitive), `surfacePage` flat (unselected), `ColorRole.textPrimary`
  (selected title + ink ring + check), `textSecondary` (unselected title / metric), `dayMark1…4`
  (cover-bucket only — categorical marks, never fills of size, J-2), `Typography.title`/`name` (title),
  `caption` (eyebrow + metric mono), `Radius.card`/`thumb`, `Spacing.itemGap`/`cardInset`.
- **A11y ids:** caller prefix `tripshape.<id>` (`.a/.b/.c`), `tripshape.<id>.check` when selected,
  `tripshape.<id>.locked` when locked. `.accessibilityAddTraits(.isSelected)`; locked →
  `.accessibilityHint(reason)` + not an actionable element.
- **Governing rule:** J-8 (elevation = certainty, never a side-border), J-2.4 (selected = ink ring +
  check, no accent fill), J-2 (day marks categorical).
- **Done-when:** selectable + locked registers; all 3 diagrams render from value args; ink-ring/check
  on selected; embedded stepper slot works; ids present; snapshot per
  `{A selected w/ stepper + fixed diagram, B locked + cover diagram, C unselected + ranked diagram}`.

### W1-05 · `SearchWell` (component)
- **File:** `DesignSystem/Components/SearchWell.swift`
- **Exemplar:** `.search` in state-a-01 (a fill pill, magnifier glyph, value text, mono `return ↵` kbd
  hint) — a control well, NOT a card, NOT glass.
- **Contract:** a non-glass `fillTertiary` pill: `[magnifier] [value text bold] [optional mono kbd hint]`.
  Args: `text: Binding<String>` (or `value: String` + `onTap` for the read-only mockup state),
  `placeholder: String`, `kbdHint: String? = "return ↵"`. For this milestone the well is **display +
  tap-to-focus** (the city is chosen from the tiles below); confirm whether live text entry is in scope
  (defaults to read-only display, no `TextField`, to match the static mockup).
- **Tokens:** `ColorRole.fillTertiary`, `textPrimary` (value), `textTertiary` (glyph + kbd),
  `Radius.pill`, `Spacing.paired`, `Typography.body`/`caption`.
- **A11y ids:** `searchwell` (`.accessibilityValue(text)`).
- **Governing rule:** J-0.1 (content well, never glass), J-10.2 (pill = control).
- **Done-when:** fill pill, magnifier + value + kbd hint; never glass; id present; snapshot `{default}`.

### W1-06 · `BaseMapCard` (component, MapKit) — *gated on OPEN DECISION 4*
- **File:** `DesignSystem/Components/BaseMapCard.swift`
- **Exemplar:** `.rec .map` in state-a-03 (zone ellipse, pins in/out, home marker, neighborhood label),
  reuse `MapPin` for marker registers.
- **Contract:** a real `MapKit` `Map` capped at `Radius.card` (the card the map sits in is white,
  `cardSurface`, NO colored edge). Renders: a neighborhood **zone** overlay (a soft `fillQuaternary`
  region), `MapPin`-style annotations (`.definitive` for in-neighborhood places, `.fuzzy` for out, a
  `.now`-style **home** marker), and a floating mono **zone label** chip. Args: `region:
  MKCoordinateRegion`, `homeCoordinate: CLLocationCoordinate2D`, `places: [(coord, MapPin.PinRegister)]`,
  `zoneLabel: String`, `snapshotMode: Bool = false` (→ renders pins + zone + label over a **solid
  neutral placeholder** instead of live tiles, for the L3 lock — OPEN DECISION 4).
- **Tokens:** `cardSurface()` wraps the whole rec card at the screen level; the map fills it. Markers via
  `MapPin`; zone label = `Typography.caption` mono on a `surfaceGrouped` pill w/ `Shadow.card`.
  `@ScaledMetric` not needed for the map frame, but no fixed *content* frames around it.
- **A11y ids:** `basemap` (container), `basemap.home` (home marker), `basemap.zonelabel`.
- **Governing rule:** J-0.1 (the map card is content — no glass on it), J-12.4 (no broken-image box in
  snapshotMode — use the neutral placeholder).
- **Done-when:** live `Map` with home + place markers + zone + label; `snapshotMode` deterministic
  placeholder variant; ids present; snapshot uses `snapshotMode: true` only.

### W1-07 · `GenerationProgressView` + `HandoffPeekCard` (component) — the generate animation
- **File:** `DesignSystem/Components/GenerationProgressView.swift` (contains the sweep + checklist;
  `HandoffPeekCard` as a sibling `View` in the same file or `DesignSystem/Components/HandoffPeekCard.swift`)
- **Exemplar:** state-a-05 `.think` (the sweep), `.steps .s` (`.done/.cur/.todo`), `.handoff`, `.eta`;
  **mirror `LoadingSkeleton.swift`'s `\.disablesOneShotMotion` env key + `@Environment(\.accessibilityReduceMotion)`
  gating** — this is the model for the one continuous motion.
- **Contract — sweep:** a 3pt neutral track with a single neutral gradient sweep that
  `repeatForever` at `Motion.think` (W1-00) — **the one allowed continuous motion** (J-9.3 / J-6.5).
  Reduce-Motion AND `disablesOneShotMotion` both collapse it to a static 40%-opacity full bar (mirror the
  mockup's `@media reduced` rule + the snapshot seam in `07 §6.4`). Pair the loop with the static
  checklist (never the only signal, `04-motion §4.3`).
- **Contract — checklist:** rows of `GenerationStepView`, each `.done` (solid-ink circle + check, roman
  body), `.current` (ONE blue `stateNow` ring — the 2nd/last accent use — + **italic display** body),
  `.pending` (hollow `ink-200` ring, receded `textTertiary` body). Optional mono sub-line ("5 clusters
  found"). Args: `steps: [GenerationStepModel]` (label, optional mono detail, state), `headline:
  String`, `sub: String`, `eta: String`.
- **Contract — `HandoffPeekCard`:** a faint (`opacity ~0.5`) non-interactive card: mono eyebrow
  ("Up next · Trip overview") + italic display line ("Lisbon · 4 days, your shape.").
- **Tokens:** `ColorRole.stateNow` (the ONE current-ring accent — the screen's 2nd accent appearance,
  CTA being absent here so this is the only accent), `textPrimary`/`textTertiary` (done/pending bodies),
  `Typography.name.italic()` (current step), `caption` (mono detail + eta), `Motion.think`,
  `Spacing.sectionGap` (step gaps). `@ScaledMetric` for the step glyph (~20pt).
- **A11y ids:** `generation.progress`, `generation.step.<index>` (with
  `.accessibilityValue("done"/"in progress"/"pending")`), `generation.handoff`, `generation.eta`.
- **Governing rule:** J-9.3 / J-6.5 (≤1 continuous motion), J-9.5 (Reduce Motion → static), J-2.4
  (one accent = the current ring), `07 §6.4` (snapshot determinism via `disablesOneShotMotion`).
- **Done-when:** sweep loops at `Motion.think`; goes static under both Reduce-Motion and
  `disablesOneShotMotion`; checklist 3 states w/ one blue current ring + italic; handoff peek faint;
  ids present; snapshot (with `disablesOneShotMotion: true`) per `{mid-generation, near-complete}`.

### W1-08 · `ContextNote` (component) + `RailSection` / `HScrollSection` (composition)
- **Files:** `DesignSystem/Components/ContextNote.swift`,
  `DesignSystem/Composition/HScrollSection.swift`
- **Exemplar:** `.note` in screen-04 (a quiet `paper-100` rounded-row: leading glyph + mono caps label +
  body, **no alarm color**); `.rail` (state-a-01 recent cities) / `.alts` (state-a-03 alt neighborhoods)
  — a horizontal scroll rail with an eyebrow head.
- **Contract — `ContextNote`:** `[glyph] [mono caps eyebrow] [body w/ bold spans]` on `surfacePage`/
  `fillQuaternary` ground, `Radius.row`. Quiet — `textSecondary` body, `textTertiary` eyebrow, NEVER
  `destructive`/accent (J-11.5 no alarm copy/color). Args: `systemImage`, `eyebrow`, `body: AttributedString`
  or `(text:, emphasis:[ranges])`.
- **Contract — `HScrollSection<Item>`:** an eyebrow head (`title` + optional mono `meta`) over a
  horizontal `ScrollView` of caller-built item views, gaps at `Spacing.paired`. Generic + `@ViewBuilder`
  item slot. Reused by: destination Recent rail, More-cities note context, alt-neighborhoods rail.
- **Tokens:** `ColorRole.fillQuaternary`/`surfacePage`, `textSecondary`/`textTertiary`,
  `Typography.subhead`/`caption`, `Radius.row`, `Spacing.paired`/`itemGap`.
- **A11y ids:** `contextnote` ; rails get a caller prefix (`rail.recent`, `rail.alts`).
- **Governing rule:** J-11.5 (no alarm), J-4.2 (group by space), J-7.1 (left-aligned).
- **Done-when:** ContextNote quiet w/ bold spans, no alarm color; HScrollSection scrolls horizontally
  with an eyebrow head; ids present; snapshot `{ContextNote, HScrollSection sample}`.

### W1-09 · `OnboardingActionFloor` (composition primitive, SOLID) — *gated on OPEN DECISION 1*
- **File:** `DesignSystem/Composition/OnboardingActionFloor.swift`
- **Exemplar:** `screen-shell.css` `.ob-action` (solid paper gradient floor) + `.ob-cta` (solid blue
  primary, full-width, optional trailing arrow) + `.ob-ghost` (full-width ghost). Contrast with
  `ActionBar.swift` (glass) — this is the SOLID immersive-floor sibling.
- **Contract:** a bottom floor on a `surfacePage` gradient (transparent→solid), holding a full-width
  solid primary CTA (`ColorRole.actionPrimary` fill + `textOnAccent` + optional trailing
  "arrow.right") and an optional full-width ghost button below. **Not glass** (J-0.1 — the floor is
  solid by design, the mockup floor is solid). Args: `primaryTitle`, `primaryIsDisabled`,
  `primaryAction`, `ghostTitle: String?`, `ghostAction`, `primaryAccessibilityID`, `ghostAccessibilityID`.
  Reuse `PillButton(.primary)` for the CTA, `PillButton(.ghost)` for the ghost.
- **Tokens:** `ColorRole.actionPrimary`/`textOnAccent`/`surfacePage`, `Spacing.cardInset`/`paired`,
  `Radius.pill`. `@ScaledMetric` 44pt min via the buttons.
- **A11y ids:** caller-supplied (`onboarding.cta`, `onboarding.ghost`).
- **Governing rule:** J-6.1 (one primary), J-0.1 (solid floor — the deliberate carve-out for the
  immersive config floor; **log this in `docs/decisions.md`** since "glass on floating chrome" is the
  default and a solid floor is the considered exception per the mockup).
- **Done-when:** solid floor (not glass); full-width primary + optional ghost; trailing arrow option;
  ids parameterized; snapshot per `{primary-only, primary+ghost, primary-disabled}`; decision logged.

**Wave-1 BARRIER:** `design-reviewer` passes J-15 + slop scan on every component above; the
snapshot suite is green and committed. Only then does Wave 4 dispatch.

---

# WAVE 2 — Models, DTOs, seed, networking

`ios/AppTemplate/Models/` + `Networking/`. Owning agents **`swift-model-scaffold`** (models + DTOs +
seed) and **`swift-networking-endpoint`** (request). Per `02-models.md`: **reference model iff a mutable
row in a list**; everything else value type; DTOs at the wire; leaf value types reused by both sides.
All files new → **parallel-safe** (except `MockScenario` cases — see W2-09).

### Reference model

#### W2-01 · `TripDraft` (the one reference model)
- **File:** `Models/TripDraft.swift`
- **Why reference:** it is the single mutable graph the flow accumulates across steps and the UI observes
  per-field; it is owned by `AppStore` and mutated in place (not a list row, but the container the whole
  flow mutates — modeled as `@MainActor @Observable final class` so step edits invalidate only readers).
- **Fields:**

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | stable seed id `"draft-<scenario>"` |
| `destination` | `City?` | chosen city (value) |
| `shapeStrategy` | `TripShapeStrategy?` | A/B/C selection (value enum) |
| `tripDays` | `Int` | stepper value (default 4) |
| `tasteProfile` | `TasteProfile?` | populated in state C (value) |
| `baseSelection` | `BaseLocation?` | chosen base (value) |
| `baseMode` | `BaseSelectionMode` | `.smart`/`.manual` |
| `transport` | `TransportSelection` | primary + alsoOK set (value) |
| `currentStep` | `OnboardingStep` | step nav cursor (value enum) |
| `generationPlan` | `GenerationPlan?` | the 6-step plan (value) |
| `onboardingState` | `OnboardingState` | derived A/B/C (set by store) |

- **Model methods (pure in-place, no network — `02 §2`):** `select(city:)`, `select(strategy:)`,
  `setDays(_:)`, `toggleInterest(_:)`, `setPace(_:)`, `select(base:)`, `setBaseMode(_:)`,
  `setPrimaryMode(_:)`, `toggleAlsoOK(_:)`, `advanceStep()`, `retreatStep()`. NO `Date()`,
  no SwiftUI import.
- **DTO:** `TripDraftDTO` (Wave 2 networking) only insofar as the seed flows through the provider — see
  W2-08; the draft itself is built client-side, so `toDTO()`/`toDomain()` exist for snapshot/seed parity
  and the round-trip test.
- **Governing rule:** `02 §1` (reference iff mutable graph the UI observes), `02 §2` (logic on model),
  `02 §3` (enums over boolean soup).
- **Done-when:** `@MainActor @Observable final class`, not `Codable`, identity equality; every field +
  method present; `restore(from: TripDraftDTO)` for store parity; compiles clean.

### Leaf value types (each its own file; `Codable, Equatable, Hashable, Sendable`; `Identifiable` where
collection-stored, `let id: String`, cross-refs as `City.ID` etc.)

#### W2-02 · `City` + `CityMeta`
- **File:** `Models/City.swift`
- **Fields:** `id`, `name`, `country`, `savedHere: Int`, `meta: CityMeta` (`.savedCount(Int)` /
  `.planStarted` / `.neighborhood(String)` / `.medina` — the per-state tile metas: "23 saved",
  "plan started", "Roma Norte", "medina"). Catalog: Lisbon/Tokyo/Kyoto/Mexico City/Marrakech/Osaka/
  Seoul/Reykjavík.

#### W2-03 · `Neighborhood` + `ReachRow`
- **File:** `Models/Neighborhood.swift`
- **Fields (Neighborhood):** `id`, `name`, `placeCount: Int`, `blurb: String` ("central", "quieter",
  "west"), `reachRows: [ReachRow]`, `isRecommended: Bool`.
- **Fields (ReachRow):** `id`, `systemImage`, `label`, `detail: String?` (the secondary span),
  `measurement: String` (mono — "≤ 25 min", "12 min"). Renders via `TimeHint`.

#### W2-04 · `BaseLocation` + `BaseSelectionMode`
- **File:** `Models/BaseLocation.swift`
- **Fields (BaseLocation):** `id`, `neighborhoodName: String`, `latitude: Double`, `longitude: Double`,
  `homeLatitude`, `homeLongitude`, `pins: [BasePin]` (coord + `PinKind` `.definitive/.fuzzy`),
  `zoneLabel: String`. `BaseSelectionMode`: enum `.smart`/`.manual`.
- **Note:** store CL coords as flat `Double`s (`02 §3.2` — never force `CLLocationCoordinate2D` through
  a coder); the view maps to `CLLocationCoordinate2D`.

#### W2-05 · `TripShapeOption` + `TripShapeStrategy`
- **File:** `Models/TripShapeStrategy.swift`
- **`TripShapeStrategy`:** enum `.fixedDays` / `.coverBucket` / `.highlights`.
- **`TripShapeOption`:** `id`, `strategy`, `eyebrow` ("A · Fixed days"), `title`, `tagline: String?`,
  `metricStrip: [MetricFragment]` (`text` + `emphasis: Bool` + `struck: Bool`), `diagram: DiagramSpec`
  (`.fixedDays(filled:[Int], dim:[Int])` / `.coverBucket(dayCounts:[Int])` /
  `.rankedBars([Double], pickIndex:Int?, dimIndex:Int?)`), `lockable: Bool`, `lockReason: String?`
  ("Save places in Kyoto to unlock"). `coverBucket.lockable == true`.

#### W2-06 · `TasteProfile` + `Interest` + `Pace`
- **File:** `Models/TasteProfile.swift`
- **`TasteProfile`:** `days: Int`, `interests: Set<Interest>`, `pace: Pace`.
- **`Interest`:** enum `.food`/`.history`/`.coffee`/`.architecture`/`.views`/`.nightlife`/`.markets`/
  `.nature`/`.art` (display label per case). **`Pace`:** enum `.easy`/`.balanced`/`.packed`.

#### W2-07 · `TransportSelection` + `TransportMode` + `TransportRec` (+`ReasonRow`, `ContextNote`)
- **File:** `Models/TransportSelection.swift`
- **`TransportMode`:** enum `.walk`/`.transit`/`.drive`/`.cycle` (+ alsoOK extras `.rideshare`/`.bus`)
  with `systemImage` + `label`. **`TransportSelection`:** `primary: TransportMode`,
  `alsoOK: Set<TransportMode>`, `suggested: TransportMode`.
- **`TransportRec`:** `suggestedMode`, `cityContext: String` ("Lisbon\n4 days"), `reasons: [ReasonRow]`
  (systemImage, body w/ bold span, mono measurement "€1.65" / "≤ 25 min" / "€18+/day"),
  `contextNote: ContextNoteModel` (eyebrow "For your dates", body w/ bold span).

#### W2-08 · `GenerationStep` + `GenerationPlan` + onboarding enums
- **File:** `Models/GenerationPlan.swift`
- **`GenerationStep`:** `id`, `label: String` (w/ bold span markers), `detail: String?` (mono sub),
  `state: StepState` (`.done`/`.current`/`.pending`). **`GenerationPlan`:** `steps: [GenerationStep]`
  (6), `etaSeconds: Int = 8`, `handoffEyebrow: String`, `handoffLine: String`, `headline`, `sub`,
  `currentStepIndex: Int`.
- **`OnboardingState`:** enum `.returningWithLocalSaves` (A) / `.savesElsewhere` (B) / `.firstTrip` (C).
- **`OnboardingStep`:** enum `.destination`/`.tripShape`/`.baseLocation`/`.gettingAround`/`.generating`
  with `index: Int` (0–4) + `progressCount` helpers.

#### W2-09 · DTOs + mapping (where the seed flows through the provider)
- **Files:** `Networking/Responses/DTO/OnboardingContextDTO.swift` (+ `TripDraftDTO.swift`).
- **Contract:** `OnboardingContextDTO` (Codable, Sendable) carries the seed the provider serves: the
  city catalog, neighborhoods, trip-shape options, transport rec, generation plan, and the saved-places
  counts (`savedHere`/`savedAnywhere`) — field-for-field, reusing the leaf value types directly (no
  per-leaf DTO; they're already wire-safe). `toDomain()` builds the value graph + the seed `TripDraft`
  on `@MainActor`; `toDTO()` snapshots back. Round-trip `dto.toDomain().toDTO() == dto` is unit-tested
  with a **plain symmetric coder** (`07 §4.2`).
- **Governing rule:** `02 §4` / `04 §3` (DTO boundary, total mapping).
- **Done-when:** round-trip total; only DTOs + leaf types are `Codable`; `TripDraft` is not.

#### W2-10 · `GetOnboardingContextRequest` (endpoint) + `MockScenario` cases (SERIAL on the enum)
- **Files:** `Networking/Requests/GetOnboardingContextRequest.swift`; the `MockScenario` enum edit
  (wherever it lives — `04 §7`) to add `.onboardingA` / `.onboardingB` / `.onboardingC`.
- **Contract:**
  - `path` `"/onboarding/context"`, `method` `.get`, `Response = OnboardingContextDTO`,
    `mockLatency .zero` (the generate-step latency is the store's clock, not the request).
    `mockResponse(from seed)` returns `seed.onboardingContext` for the active scenario.
  - `MockScenario` gains 3 cases mapping to `SampleData.onboardingA/B/C().toDTO()` seeds.
- **Governing rule:** `04 §2` (one-file endpoint, `mockResponse` pure), `04 §7` (scenarios).
- **Done-when:** request is one file, doesn't edit `MockProvider`; 3 scenarios resolve to the 3 seeds.

### Seed

#### W2-11 · `SampleData+Onboarding` (the 3 contexts + shared catalogs)
- **File:** `Models/SampleData+Onboarding.swift` (+ extend `SampleSeed` / core `SampleData.swift` only
  to add the `onboardingContext` field — that core edit is SERIAL).
- **Contract — three contexts (stable literal ids, fixed `simulatedNow`):**
  - **A** (`onboardingA`): Lisbon chosen, `savedHere = 23`, `savedAnywhere = 23 + Tokyo`. Full bucket
    available; base = Alfama (18/23 within 25-min walk); transport rec = transit (Lisbon €, rain note);
    generation plan = the 6 Lisbon steps + clusters (Alfama·Belém·Bairro Alto·Parque) + eta 8s + handoff
    "Lisbon · 4 days, your shape."
  - **B** (`onboardingB`): Kyoto chosen, `savedHere = 0`, `savedAnywhere > 0` (Tokyo + Lisbon saves).
    "Cover the bucket" **locked** (reason "Save places in Kyoto to unlock"); copy pivots to taste +
    city's-best; base = Gion; neighborhoods (Gion/Downtown/S.Higashiyama/Pontochō/Arashiyama); transport
    rec = transit (Kyoto ¥, blossom-crowd note); generation plan = Kyoto steps + "12 picks shortlisted"
    + handoff "Kyoto · 4 days, a strong first draft."
  - **C** (`onboardingC`): Lisbon chosen, `savedHere = 0`, `savedAnywhere = 0`. Step 02 = taste form
    (days=4, interests {food, history, coffee}, pace balanced); base = Baixa; generation plan = Lisbon
    "best for food and history" + handoff "Lisbon · 4 days, your shape." (sub "A first draft to react
    to.").
  - **Shared catalogs:** city options (the 8 cities + per-state metas), neighborhoods (Lisbon:
    Alfama/Bairro Alto/Chiado/Príncipe Real/Belém/Baixa w/ place counts; Kyoto set), trip-shape options,
    transport recs (Lisbon €/Kyoto ¥ + context notes), per-city generation plans.
- **Governing rule:** `02 §5` (SampleData is the one mock source; the `MockScenario` cases build their
  `MockSeed` from these; ids are literals).
- **Done-when:** `SampleData.onboardingA/B/C()` each return a `SampleSeed` with `onboardingContext` +
  `simulatedNow`; `savedHere`/`savedAnywhere` recoverable; the three drive A/B/C branch selection.

### Wave-2 tests (L1 — `swift-test-writer`)
- `TripDraftTests` (each model method flips its field; `advanceStep`/`retreatStep` clamp).
- `OnboardingDTORoundTripTests` (`toDomain().toDTO() == dto`, plain symmetric coder).
- `OnboardingBranchTests` (A/B/C seeds map to the right `OnboardingState`).

---

# WAVE 3 — Store

`ios/AppTemplate/Store/`. Per `03-store.md`. **SERIAL** on core `AppStore.swift` (new stored props);
the command/derivation extension is a **new file** (parallel-safe relative to other features, but this
is the only feature).

### W3-01 · `AppStore` stored state (SERIAL — core `AppStore.swift`)
- **Edit:** add to `AppStore`:
  - `private(set) var onboarding: TripDraft?` — the active draft (nil = onboarding dismissed/root).
  - `var onboardingLoadState: LoadState = .idle` (reuse the existing `LoadState`).
  - The injection seam: `init` reads the scenario; previews/tests seed directly.
- **Governing rule:** `03 §2` (state shape), `03 §7` (adding state checklist — this is the one serial
  core edit).

### W3-02 · `AppStore+Onboarding` (new file — commands + derivation)
- **File:** `Store/AppStore+Onboarding.swift`
- **Contract:**
  - **Hydration:** `func loadOnboarding() async` → `api.send(GetOnboardingContextRequest())` →
    `onboarding = dto.toDomain()` (builds the seed `TripDraft` + sets `onboardingState`),
    `onboardingLoadState = .loaded` (the read path, `03 §4`).
  - **Derivation on the store (NOT the view — per the task):** `var savedHere: Int` and
    `var savedAnywhere: Int` computed from `onboarding`'s context; `var onboardingState:
    OnboardingState` derived (`savedHere>0 → A`; `savedHere==0 && savedAnywhere>0 → B`;
    `savedAnywhere==0 → C`). These feed the presenters; the branch driver lives here.
  - **Step nav:** `func advanceOnboardingStep()` / `func retreatOnboardingStep()` wrap the model
    methods + drive the immersive flow's step cursor (these are pure transitions → could be model
    methods, but step nav is store-level flow control; keep thin wrappers).
  - **Generation (OPEN DECISION 3):** `func startGeneration()` kicks the cancellable advance;
    `func advanceGeneration()` (sets next step `.current`, prior `.done`) — the **synchronous, test-drivable
    seam**; `func completeGeneration()` → `onboarding = nil` (the **dismiss-to-root command**).
    `func cancelOnboarding()` → `onboarding = nil` (Cancel/Close). The live timer path schedules
    `advanceGeneration()` calls via `Task.sleep`; tests call the synchronous advances directly.
  - **Dismiss-to-root seam:** completing or cancelling sets `onboarding = nil`; `RootView` shows the
    placeholder root. Mark `// TODO: navigate to Trip Overview when built` exactly where the real push
    would go (in `completeGeneration()` and/or where `RootView` reacts).
- **Governing rule:** `03 §3` (commands on the store), `06 §3` (store-shared derivation lives on store,
  screen-specific on presenters), the task's "savedHere/anywhere derive on the store, not the view".
- **Done-when:** branch derivation matches A/B/C; step nav clamps; generation advances + completes
  set `onboarding = nil`; the TODO seam is present and labeled; no view reads counts directly.

### W3-03 · Scenario injection (SERIAL — `App/AppTemplateApp.swift` + `App/RootView.swift`)
- **Edit:** `AppTemplateApp.init()` constructs `AppStore(api: .mock(scenario:))` from
  `UITEST_SCENARIO` (`onboardingA/B/C`), per `07 §7.1`. `RootView` owns the `@State private var store =
  AppStore()`, injects `.environment(store)`, and presents `OnboardingFlowView` as a
  `.fullScreenCover(isPresented: store.onboarding != nil)` (immersive takeover) — or hosts it directly
  while `onboarding != nil`, falling back to the placeholder root when nil (the dismiss target).
- **Governing rule:** `01 §4` (App root owns the one store; no `.shared`), `06 §2.5` (cover for a
  takeover), `07 §7.1` (launch-env injection seam).
- **Done-when:** A/B/C selectable at launch; onboarding presents as a cover over the placeholder root;
  dismissing returns to root.

### Wave-3 tests (L2 — `swift-test-writer`)
- `OnboardingCommandTests` (`@MainActor`, fresh `.mock()` store per test): `loadOnboarding` hydrates;
  `savedHere`/`savedAnywhere`/`onboardingState` derive correctly per scenario; `advanceGeneration`
  walks the plan; `completeGeneration`/`cancelOnboarding` set `onboarding = nil`.

---

# WAVE 4 — Screens

`ios/AppTemplate/Screens/Onboarding/`. Owning agent **`swift-screen-builder`**; each screen →
consistency-review → **fidelity-review vs its NAMED mockup** → snapshot-lock. Every screen: composes
`ScreenScaffold(.immersive)` + the `OnboardingProgressHeader` (sticky) + `OnboardingActionFloor`
(`ScreenScaffold(actions:)`), reads a **stateless presenter**, mutates via store commands / model
methods, NO domain state in `@State`. **Tab bar hidden** (immersive). Dot-namespaced a11y ids on every
state-bearing element. **Each screen NAMES its mockup.**

### W4-00 · `OnboardingRoute` + `OnboardingFlowView` (the one adaptive container)
- **Files:** `Screens/Routes/OnboardingRoute.swift`, `Screens/Onboarding/OnboardingFlowView.swift`,
  `Screens/Onboarding/OnboardingFlowPresenter.swift`
- **Contract:** `OnboardingRoute: Hashable {}` (no payload — the draft lives on the store).
  `OnboardingFlowView` reads `store.onboarding`, builds `OnboardingFlowPresenter`, and switches on
  `draft.currentStep` to render the matching step view — ONE flow, 5 steps, A/B/C selected by
  `presenter.onboardingState` (from the store derivation). Back/close map to
  `store.retreatOnboardingStep()` / `store.cancelOnboarding()`. The flow owns the
  `.fullScreenCover`-level presentation (per W3-03) or is hosted by `RootView`.
- **Presenter:** `OnboardingFlowPresenter { store }` → `currentStep`, `onboardingState`, `progressIndex`,
  `leadingGlyph` (close on step 0, back otherwise).
- **A11y ids:** `onboarding.flow`.
- **Named mockup:** n/a (container) — the per-step views name theirs.
- **Done-when:** one container drives all 5 steps; branch state from store; no per-step domain `@State`.

### W4-01 · Step 01 — `DestinationStepView` (+ presenter)
- **Files:** `Screens/Onboarding/DestinationStepView.swift` + `DestinationStepPresenter.swift`
- **Named mockup (fidelity target):** `mockups/screens/onboarding/state-a-screen-01-destination.html`
  (A), `state-b-screen-01-destination.html` (B), `state-c-screen-01-destination.html` (C).
- **Composition:** `ScreenScaffold(.immersive)` → `OnboardingProgressHeader(step 0, .close)` (sticky) +
  hero (eyebrow "Destination" mono + display question + sub) + `SearchWell` (W1-05, value "Lisbon") +
  `AIVoice` ("Reading your saved places" + the 23-places line; in C: "no saved places yet" copy) +
  `HScrollSection` Recent rail (city `PlaceCard`-mini or `.rcc`-style chips) + a 2×2
  `LazyVGrid` of `PlaceCard` city tiles (selected = definitive, others = fuzzy; `Tag` "plan started").
  Floor: `OnboardingActionFloor(primary "Continue with {City}")`.
- **Presenter derived:** `eyebrow`, `question`, `sub` (per state), `searchValue`, `aiVoice`,
  `recentCities: [CityTileModel]`, `gridCities: [CityTileModel]` (w/ certainty + selection + meta tag),
  `ctaTitle` ("Continue with Lisbon").
- **Wiring:** tile tap → `store.onboarding?.select(city:)`; CTA → `store.advanceOnboardingStep()`;
  close → `store.cancelOnboarding()`.
- **A11y ids:** `destination.search`, `destination.city.<id>` (each tile), `destination.cta`,
  `onboarding.close`.
- **Governing rule:** J-8 (city certainty via elevation), J-2.4 (selected tile = ink ring/check, not
  accent), `06 §2` (immersive chrome).
- **Done-when:** names mockup; 2×2 tiles w/ one selected definitive; CTA reads chosen city; ids present;
  `#Preview` per A/B/C seed; snapshot per state.

### W4-02 · Step 02 — `TripShapeStepView` (+ presenter) — *OPEN DECISION 2*
- **Files:** `Screens/Onboarding/TripShapeStepView.swift` + `TripShapeStepPresenter.swift`
- **Named mockup:** `state-a-screen-02-trip-shape.html` (A, 3 cards), `state-b-screen-02-trip-shape.html`
  (B, "Cover the bucket" **locked**), `state-c-screen-02-trip-shape.html` (C, **taste form**).
- **Composition (one view, two bodies):** switch on `presenter.step02Mode`:
  - `.shapeCards` (A/B): hero + a column of three `TripShapeCard` (W1-04) — card A embeds `DayStepper`,
    card B is `.locked` in state B; + a foot `AIVoice` ("Which to pick").
  - `.tasteForm` (C): hero + `DayStepper` ("How long") + interest `FilterChip` grid ("What you're into")
    + pace `SegmentedSelector` (3-way "Easy/Balanced/Packed") + foot `AIVoice` ("How we'll use this").
  - Floor: `OnboardingActionFloor(primary "Continue · {N} days")`.
- **Presenter derived:** `step02Mode`, `shapeOptions: [TripShapeCardModel]` (eyebrow/title/metric/diagram/
  register/locked), `selectedStrategy`, `tasteDays`, `interests`/`selectedInterests`, `pace`, `ctaTitle`.
- **Wiring:** card tap → `select(strategy:)` (no-op when locked); stepper → `setDays`; chip →
  `toggleInterest`; pace → `setPace`; CTA → advance.
- **A11y ids:** `tripshape.<a/b/c>` (cards), `tripshape.<id>.locked`, `daystepper.*`,
  `interest.<id>`, `pace.<id>`, `tripshape.cta`, `onboarding.back`.
- **Governing rule:** J-8 / J-2.4 (selected card), J-2 (cover-bucket day marks), J-6.2 (one foot AIVoice).
- **Done-when:** A/B render 3 cards w/ B locked; C renders taste form; CTA reads day count; ids present;
  `#Preview` per A/B/C; snapshot per state.

### W4-03 · Step 03 — `BaseLocationStepView` (+ presenter) — *OPEN DECISIONS 4, 5*
- **Files:** `Screens/Onboarding/BaseLocationStepView.swift` + `BaseLocationStepPresenter.swift`
- **Named mockup:** `state-a-screen-03-base-location.html` (Alfama), `state-b-screen-03-base-location.html`
  (Gion), `state-c-screen-03-base-location.html` (Baixa).
- **Composition:** hero + `SegmentedSelector` (2-way "Smart from saved" / "Pick manually") +
  `BaseMapCard` (W1-06, MapKit) inside a `cardSurface` rec card with an `AIVoice` "What we noticed" +
  reach rows (`TimeHint`) + a "Tentative · change it any time" divider + `HScrollSection` alt
  neighborhoods rail. Floor: `OnboardingActionFloor(primary "Use {Neighborhood} as base", ghost "Pick a
  specific hotel or address")`. `.manual` mode → `EmptyStateView` stub (OPEN DECISION 5); ghost no-ops
  with `// TODO: manual base picker`.
- **Presenter derived:** `region`/`homeCoordinate`/`placePins`/`zoneLabel` (for `BaseMapCard`),
  `whyVoice`, `reachRows: [TimeHint.Model]`, `altNeighborhoods: [AltModel]`, `ctaTitle`, `baseMode`.
- **Wiring:** segment → `setBaseMode`; CTA → `select(base:)` then advance.
- **A11y ids:** `basemode.smart`/`basemode.manual`, `basemap.home`, `basemap.zonelabel`,
  `rail.alts.<id>`, `baselocation.cta`, `baselocation.ghost`.
- **Governing rule:** J-0.1 (map card is content, no glass), `06 §2.4` (CTA in floor + ghost secondary).
- **Done-when:** names mockup; real `Map` w/ home marker + zone + alt rail; CTA reads neighborhood;
  manual stub present; ids present; `#Preview` per A/B/C; snapshot uses `BaseMapCard(snapshotMode: true)`.

### W4-04 · Step 04 — `GettingAroundStepView` (+ presenter)
- **Files:** `Screens/Onboarding/GettingAroundStepView.swift` + `GettingAroundStepPresenter.swift`
- **Named mockup:** `mockups/screens/onboarding/screen-04-getting-around.html` (shared, used by A & C),
  `state-b-screen-04-getting-around.html` (B — Kyoto ¥ + blossom note).
- **Composition:** hero + a `cardSurface` rec card (AI eyebrow row + the **one italic editorial** "We'd
  suggest *transit.*" + a mono city/days context chip (`Tag`) + reason rows (`TimeHint` w/ €/¥
  measurements)) + a quiet `ContextNote` ("For your dates" + rain/crowd note, NO alarm color) + a "Your
  call" divider + the two-tier control: `SegmentedSelector` 4-way "Mostly" (icons Walk/Transit/Drive/
  Cycle) + a mono "Transit is what we suggested" hint (one `stateNow` dot) + multi-select Also-OK
  `FilterChip`s. Floor: `OnboardingActionFloor(primary "Continue · Mostly {mode}")`.
- **Presenter derived:** `recVoice`, `cityContext`, `reasonRows`, `contextNote`, `mostlyOptions` +
  `primaryMode`, `suggestedMode`, `alsoOKChips` + `selectedAlsoOK`, `ctaTitle`.
- **Wiring:** Mostly → `setPrimaryMode`; Also-OK chip → `toggleAlsoOK`; CTA → advance/start-generation.
- **A11y ids:** `transport.mostly.<mode>`, `transport.alsook.<mode>`, `gettingaround.cta`,
  `contextnote`, `onboarding.back`.
- **Governing rule:** J-3.6/J-6.2 (one italic editorial — the rec line, NOT a 2nd AIVoice line — OPEN
  DECISION 7), J-11.5 (context note no alarm), J-2.4 (one suggested dot).
- **Done-when:** names mockup; 4-way Mostly (one selected, ink pill) + Also-OK multi-select; reason rows
  w/ currency; quiet context note; CTA reads mode; ids present; `#Preview` per A/B/C; snapshot per state.

### W4-05 · Step 05 — `GeneratingStepView` (+ presenter) — *OPEN DECISIONS 3, 6, 2(motion)*
- **Files:** `Screens/Onboarding/GeneratingStepView.swift` + `GeneratingStepPresenter.swift`
- **Named mockup:** `state-a-screen-05-generate.html`, `state-b-screen-05-generate.html`,
  `state-c-screen-05-generate.html`.
- **Composition:** `OnboardingProgressHeader(step 4, .close)` (leading = Cancel/×) + the sweep +
  gen-hero (`AIVoice` "Drawing up your trip" + italic line + sub) + `GenerationProgressView` (W1-07,
  the 6-step checklist) + `HandoffPeekCard` (faint, "Up next · Trip overview") + mono `eta` ("Usually
  ready in about 8 seconds"). **No `OnboardingActionFloor`** (passive screen — Cancel is the header
  glyph). On appear → `store.startGeneration()`; on completion → store sets `onboarding = nil`
  (dismiss-to-root); Cancel → `store.cancelOnboarding()`.
- **Presenter derived:** `headline`, `sub`, `generationSteps: [GenerationStepModel]`, `handoffEyebrow`,
  `handoffLine`, `eta`.
- **Wiring:** `.task { store.startGeneration() }` (the store owns the clock — OPEN DECISION 3);
  the view observes `store.onboarding == nil` for dismissal. `// TODO: navigate to Trip Overview when
  built` at the completion seam (store side, W3-02).
- **A11y ids:** `generation.progress`, `generation.step.<index>`, `generation.handoff`, `generation.eta`,
  `onboarding.cancel`.
- **Governing rule:** J-9.3/J-6.5 (the sweep is the one continuous motion), J-9.5 (Reduce Motion static),
  J-2.4 (one accent = the current step ring), `06 §2.5` (cover/immersive, auto-dismiss).
- **Done-when:** names mockup; sweep loops (static under Reduce-Motion + `disablesOneShotMotion`);
  6-step checklist w/ one blue current ring + italic; handoff peek faint; auto-dismisses to root on
  completion; Cancel dismisses; TODO seam present; `#Preview` per A/B/C; snapshot (with
  `disablesOneShotMotion: true`) per `{mid, near-complete}`.

### W4-06 · Catalog (SERIAL — `Screens/ScreenCatalogView.swift`)
- **File:** `Screens/Catalog/CatalogSection+Onboarding.swift` (new) + the one serial edit to register a
  new "Onboarding" section in core `ScreenCatalogView.swift`.
- **Contract:** entries that reach each step view in each A/B/C seed (15 entries) via
  `AppStore.preview(SampleData.onboardingA/B/C())`.
- **Done-when:** every step reachable in every state from the catalog; only the section-registration
  edit touches core (serial).

---

# WAVE 5 — Tests

Per `07-testing.md`. Owning agents: **`swift-test-writer`** (L1/L2 — many already specified in Waves
2–3), **`swift-snapshot-test-writer`** (L3 — component snapshots in Wave 1 + screen snapshots here),
**`swift-uitest-writer`** (L4). All `AppTemplateTests` / `AppTemplateUITests` files are new →
parallel-safe.

### W5-01 · Presenter derivation (L1)
- **Files:** `AppTemplateTests/Screens/Onboarding*PresenterTests.swift` (one per step presenter).
- **Contract:** seed an `AppStore` per A/B/C; build each presenter; assert derived values (CTA title
  reads city/day-count/mode; `step02Mode` is `.shapeCards` for A/B and `.tasteForm` for C; B's
  "Cover the bucket" option is `.locked`; reach/reason rows + counts; progress index). `07 §4.3`.

### W5-02 · Render snapshots (L3 — the lock)
- **Files:** `AppTemplateTests/Snapshots/Onboarding*SnapshotTests.swift` + committed
  `__Snapshots__/`.
- **Contract:** one snapshot per step **per state** (A/B/C) at `simulatedNow`, through
  `assertDesignSnapshot` (the pinned helper, `07 §6.1`). Step 03 uses `BaseMapCard(snapshotMode: true)`
  (OPEN DECISION 4). Step 05 injects `.environment(\.disablesOneShotMotion, true)` so the sweep settles
  (`07 §6.4`). Plus the Wave-1 component snapshots (already specified per component).

### W5-03 · XCUITest across A/B/C (L4) + accessibility audit
- **Files:** `AppTemplateUITests/OnboardingFlowUITests.swift`.
- **Contract:** table-driven over `UITEST_SCENARIO ∈ {onboardingA, onboardingB, onboardingC}` (`07 §7.2`):
  - drive the flow end-to-end (select city → shape/taste → base → transport → generate → assert
    dismissal to root) querying by a11y id, never text (`07 §7.3`), `waitForExistence` never `sleep`.
  - assert branch-specific elements: A shows 23-saves AIVoice + bucket available; B shows
    `tripshape.b.locked`; C shows the taste form (`interest.*`, `pace.*`).
  - `performAccessibilityAudit()` once per step under `onboardingA` (`07 §7.4`), suppressing only
    documented exemptions narrowly.
- **Done-when:** all three scenarios green; audit passes; dismissal-to-root asserted (placeholder root
  visible after generation completes).

### Coverage gate (`07 §9`)
- Every model method / command (incl. generation advance + dismiss) ships an L1/L2 test (Waves 2–3, 5).
- Every new component + screen ships an L3 lock (Waves 1, 5).
- The flow ships an L4 XCUITest across its 3 scenarios + an audit (W5-03).
- No token-parity test (tokens are codegen'd, `Motion.think` included).

---

## Mockup → component map (quick reference for fidelity review)

| Mockup region | Component | Reuse / New |
|---|---|---|
| `.ob-header` + `.ob-progress` + `.ob-counter` | `OnboardingProgressHeader` | **NEW** (W1-01) + reuse `GlassCircleButton` |
| `.ob-action` / `.ob-cta` / `.ob-ghost` | `OnboardingActionFloor` | **NEW** (W1-09) + reuse `PillButton` |
| `.search` | `SearchWell` | **NEW** (W1-05) |
| `.pcard` city tiles | `PlaceCard` | reuse |
| `.rail` / `.alts` | `HScrollSection` | **NEW** (W1-08) |
| `.ai` voice line | `AIVoice` | reuse |
| `.scard` + `.stepper` + diagrams | `TripShapeCard` (+ `DayStepper`) | **NEW** (W1-04, W1-03) |
| taste-form chips / pace | `FilterChip` / `SegmentedSelector` | reuse / **NEW** (W1-02) |
| `.seg` / `.mostly` / `.pace` | `SegmentedSelector` | **NEW** (W1-02) |
| `.map` + pins + home | `BaseMapCard` (+ `MapPin`) | **NEW** (W1-06) reuse `MapPin` |
| `.reach` / `.reasons` rows | `TimeHint` | reuse |
| `.note` | `ContextNote` | **NEW** (W1-08) |
| `.alsook` chips | `FilterChip` | reuse |
| `.think` sweep + `.steps` + `.handoff` + `.eta` | `GenerationProgressView` + `HandoffPeekCard` | **NEW** (W1-07) |
| city/days context chip, badges | `Tag` | reuse |
| any non-floor button | `PillButton` | reuse |
