# Track A — Onboarding test-quality refactor (contract-level plan)

**Phase:** 3 (Tests). No foundation-freeze. **TEST-ONLY** — no production view/component/model
source changes, no new screens, no design-system changes. The single allowed production touch is one
string-correctness fix in a test display name plus (optionally) `docs/decisions.md` entries.

**Governing doc:** `ios/docs/engineering/07-testing.md` (all four layers). Also read
`ios/docs/engineering/00-overview.md` and `docs/decisions.md`.

**Worktree root (all paths below are absolute under it):**
`/Users/shubh/Workspaces/AITravel-app/.claude/worktrees/onboarding-test-quality/`

> Executors: `swift-test-writer` (L1/L2), `swift-snapshot-test-writer` (L3 string fix),
> `swift-uitest-writer` (L4), all reviewed by `swift-code-reviewer`. **Never write code bodies that
> aren't sketches** — every sketch below is labeled and must be reconciled against live source.

---

## Verified facts (confirmed against live source — executors must re-confirm, not assume)

- **Onboarding has NO networked write YET (one is coming later).** The only onboarding request today is
  `…/ios/AppTemplate/Networking/Requests/GetOnboardingContextRequest.swift` (a read). All current mutations
  are in-place `TripDraftModel` transitions applied client-side (`AppStore+Onboarding.swift` wraps them).
  → **There is no optimistic-apply / `restore(from:)` rollback to test for onboarding *yet*.** Per the
  user, a write command (optimistic-apply + rollback) is on the roadmap. This is a **DEFERRAL**, not a
  permanent design decision: the rollback/error-path test is pending the future write (Task A-DEC documents
  it as deferred, with a pointer to add it when the write lands — NOT as "onboarding never writes").
- **`UITEST_FAILURE_RATE` is currently an unconsumed seam — KEEP it as a future hook (user decision).**
  `AppTemplateApp.swift` reads only `UITEST_SCENARIO` (→ `.onboardingA/B/C`); it does not yet read
  `UITEST_FAILURE_RATE`. `APIClient.mock`'s signature is `mock(scenario:failure:latency:)` — there is **no
  `failureRate:` parameter** in this repo yet (the doc snippet at `07-testing.md:295` is illustrative
  library-template text). Three UITest helpers forward `UITEST_FAILURE_RATE` into `launchEnvironment` where
  nothing consumes it today. **Because the onboarding write is coming, KEEP this forwarding as deliberate
  scaffolding** for the upcoming failure-injection path → the robot (C0) preserves it, and Task C5 documents
  it as an intentional, currently-unconsumed future hook (NOT dead code to delete).
- **`.mock(failure:)`** is the seam to drive `onboardingLoadState == .failed`: `loadOnboarding()`
  (`AppStore+Onboarding.swift:13-25`) catches and sets `.failed(String(describing: error))`; on failure
  `setOnboarding` is never called so `onboarding` stays `nil`. `.mock(latency:)` drives the `.loading`
  observation. `LoadState` = `.idle/.loading/.loaded/.failed(String)`, `Equatable`.
- **`AppStore.preview(_ context: OnboardingContextDTO, step: OnboardingStep = .destination) -> AppStore`**
  (`AppStore.swift:53`) is the L1 seam.
- **`AppStore(api:).loadOnboarding()`** is the L2 seam; `.mock(scenario:)` takes
  `.onboardingA/.onboardingB/.onboardingC`.
- **Generation arithmetic** lives on the store: `advanceGeneration()` (`AppStore+Onboarding.swift:89-99`,
  sweep + clamp/no-op on last index), `completeGeneration()` (`:101` → `setOnboarding(nil)` →
  `onboarding == nil`), `cancelOnboarding()` (`:107` → `onboarding == nil`). **Zero coverage today.**
- **Hand-written associated-value `Codable`:** `CityMeta` (`Models/City.swift:38-85`; cases
  `.savedCount(Int)`, `.planStarted`, `.neighborhood(String)`, `.medina`) and `DiagramSpec`
  (`Models/TripShapeStrategy.swift:47-95`; cases `.fixedDays(filled:dim:)`, `.coverBucket(dayCounts:)`,
  `.rankedBars(values:pickIndex:dimIndex:)`). **Zero coverage today.** Neither has a separate DTO; both
  are leaf value types used directly on the wire.
- **Snake-case wire path:** `APIJSON.decoder()` (`APIClient.swift:57-61`) =
  `.convertFromSnakeCase` + `.iso8601`. `TripDraftDTO` carries `selectedNeighborhoodID`
  (`TripDraftDTO.swift:20`); `OnboardingContextDTO` carries `savedHere`
  (`OnboardingContextDTO.swift:21`).
- **CTA gating exemplar:** `BaseLocationStepView.swift:29` `primaryEnabled: presenter.canContinue`,
  `:30` `primaryAccessibilityID: "baselocation.cta"`. Manual-picker ids:
  `baselocation.manual.pinned` (`:227`), `baselocation.manual.<option.id>` (`:270`).
- **Back affordance:** every step view stamps `onboarding.back` calling `store.retreatOnboardingStep()`
  (e.g. `GettingAroundStepView.swift:52/56`, `TripShapeStepView.swift:46/50`, `WhenStepView.swift`,
  `BaseLocationStepView.swift:79`). `retreatOnboardingStep()` ships (`AppStore+Onboarding.swift:54`).
- **6 UITest suites** with byte-identical `makeLaunchedApp` / `scrollToElement` / audit handler:
  `OnboardingTripShapeUITests.swift`, `OnboardingWhenUITests.swift`, `OnboardingBaseLocationUITests.swift`,
  `OnboardingGettingAroundUITests.swift`, `OnboardingDestinationUITests.swift`,
  `OnboardingGeneratingUITests.swift`. No `Support/` dir exists yet.
- **Conditional-assert holes:** `OnboardingTripShapeUITests.swift:295` (`if nightlifeChip.isHittable`),
  `OnboardingGettingAroundUITests.swift:260` and `:296` (`if rideshareChip.isHittable` /
  `if cycleChip.isHittable`).
- **ProgressBar default** is `totalSteps: 6`; PNGs already re-recorded to "/ 06" in commit `a27e121`.
  The display strings/docstrings at `OnboardingProgressBarSnapshotTests.swift:44/57/69` and the stale
  note at `:16-17` still say "/ 05" and "leave as-is" → string-correctness fix only.

---

## Phase ordering (disjoint = batchable in parallel; shared = serialize)

```
WAVE A — model + store functional (DISJOINT files, batch in parallel)
  A1  L1 model: CityMeta + DiagramSpec symmetric round-trips        OnboardingModelTests.swift   [shared-with-A2: same file → serialize A1+A2+A4]
  A2  L2 wire : APIJSON snake_case decode (one test)                OnboardingModelTests.swift   [same file as A1/A4]
  A3  L2 store: generation arithmetic + read-failure + loading      OnboardingCommandTests.swift [disjoint from A1/A2/A4]
  A4  L1 model: table-drive DTO round-trips (arguments:)            OnboardingModelTests.swift   [same file as A1/A2]
  A3b L2 store: table-drive A/B/C hydration (arguments:)            OnboardingCommandTests.swift [same file as A3 → serialize A3+A3b]
  A-DEC decisions.md: "no onboarding write → no rollback"          docs/decisions.md            [shared doc → serialize all decisions edits]

WAVE B — presenter refactor (single file → SERIALIZE within wave)
  B1  L1 presenter: delete tautologies + frozen-literal oracles     OnboardingPresenterTests.swift
  B2  L1 presenter: delete mirror tests                             OnboardingPresenterTests.swift
  B3  L1 presenter: add makePresenter factory helpers + dedup       OnboardingPresenterTests.swift
  B4  L1 presenter: table-drive branch derivation (arguments:)      OnboardingPresenterTests.swift
  (B1–B4 all edit one file → ONE executor, sequential edits)

WAVE C — L4 robot + UITests (SHARED FILE FAMILY → SERIALIZE)
  C0  Support: OnboardingRobot (NEW file) + pbxproj membership      AppTemplateUITests/Support/OnboardingRobot.swift  [+ .pbxproj — SERIAL]
  C1  Refactor 6 suites onto robot (delete copy-pasted helpers)     6× Onboarding*UITests.swift                       [each disjoint AFTER C0]
  C2  Unconditional scroll-then-assert fixes                        TripShape/GettingAround UITests                   [subset of C1 files]
  C3  New: back-navigation test                                     (one suite, e.g. GettingAround)                   [C1 file]
  C4  New: disabled-CTA assertion (BaseLocation manual)             OnboardingBaseLocationUITests.swift               [C1 file]
  C5  KEEP UITEST_FAILURE_RATE as future hook + decisions.md note   3 suites/robot + docs/decisions.md                [C1 files + SERIAL doc]
  C6  New: one end-to-end multi-step flow walk (NEW suite file)     AppTemplateUITests/OnboardingFlowUITests.swift    [+ .pbxproj — SERIAL]

WAVE D — L3 ProgressBar string fix (single file, DISJOINT from all above)
  D1  Correct "/ 05" → "/ 06" display strings + delete stale note   OnboardingProgressBarSnapshotTests.swift          [disjoint]

GATE
  build clean → ios-test-coverage-check → swift-code-reviewer → commit
```

**Serialization flags:**
- `OnboardingModelTests.swift` — A1, A2, A4 touch it → **one executor, sequential** (or batch as one task).
- `OnboardingCommandTests.swift` — A3, A3b → **one executor, sequential** (or batch as one task).
- `OnboardingPresenterTests.swift` — B1–B4 → **one executor, sequential**.
- `docs/decisions.md` — A-DEC + C5 → **serialize all decisions edits** (append-only; one writer at a time).
- `.pbxproj` (`…/ios/AppTemplate.xcodeproj/project.pbxproj`) — C0 (new robot file) + C6 (new suite) →
  **SERIAL, coordinator-owned.** New files must join the `AppTemplateUITests` target.
- Wave A vs Wave D vs Wave C-after-C0 are mutually disjoint → parallelizable across executors.
- Wave B is independent of A/C/D → parallelizable as its own executor stream.

---

## WAVE A — model + store functional tests

### Task A1 — L1: `CityMeta` + `DiagramSpec` symmetric Codable round-trips
- **Agent:** `swift-test-writer`
- **File (edit):** `…/ios/AppTemplateTests/Models/OnboardingModelTests.swift`
- **Exemplar to mirror:** `OnboardingModelTests.swift → codableRoundTrip<T>(_:)` (file-private helper at
  `:45`) and `OnboardingContextDTORoundTripTests` suite. **Reuse the existing `codableRoundTrip` /
  `symmetricEncoder` / `symmetricDecoder` helpers** — do NOT use `APIJSON` (asymmetric on ID/acronym
  keys, per §4.2 and the file header).
- **Add:** a new nested `@Suite("CityMeta + DiagramSpec — associated-value Codable symmetry")`.
  - `CityMeta` — one `@Test(arguments:)` parameterized over all four cases:
    `.savedCount(23)`, `.planStarted`, `.neighborhood("Alfama")`, `.medina`. Assert
    `codableRoundTrip(case) == case`. (Plain `String`/`Int` payloads; no `Date`.)
  - `DiagramSpec` — one `@Test(arguments:)` over all three cases:
    `.fixedDays(filled: [0,1,2], dim: [3])`, `.coverBucket(dayCounts: [2,3,1])`,
    `.rankedBars(values: [0.8, 0.4, 0.2], pickIndex: 0, dimIndex: 2)` **and** a `rankedBars` case with
    `pickIndex: nil, dimIndex: nil` (the `encodeIfPresent`/`decodeIfPresent` path — `:72-73`/`:90-91`).
    Assert `codableRoundTrip(case) == case`.
  - **Sketch (executor reconciles arg-form against the real `@Test(arguments:)` API):**
    `@Test(arguments: [CityMeta.savedCount(23), .planStarted, …]) func cityMetaRoundTrips(_ m: CityMeta) throws { #expect(try codableRoundTrip(m) == m) }`
- **MockProvider scenarios:** none (pure value types; construct cases inline — these are not domain
  graphs, so inline construction is allowed per §3, but use stable literals).
- **Done-when:** every `CityMeta` case (4) and every `DiagramSpec` case (3 + the all-nil `rankedBars`)
  round-trips losslessly; the nil-optional `rankedBars` path is covered; uses the symmetric coder, never
  `APIJSON`; `@MainActor` not required (both are `nonisolated`).

### Task A2 — L2: one snake_case wire-decode test via `APIJSON.decoder()`
- **Agent:** `swift-test-writer`
- **File (edit):** `…/ios/AppTemplateTests/Models/OnboardingModelTests.swift` (its `Group 1` neighborhood,
  but this is a **wire/L2** test — place it in a clearly-named `@Suite("Wire decode — APIJSON snake_case")`).
- **Exemplar to mirror:** `07-testing.md §5.2`/`§5.3` (the snake-case decode pattern) and the production
  coder at `APIClient.swift:57` (`APIJSON.decoder()` = `.convertFromSnakeCase` + `.iso8601`).
- **Add:** ONE test that decodes a hand-authored snake_case JSON payload (string literal) carrying
  `saved_here` and `selected_neighborhood_id` into the matching DTO via `APIJSON.decoder()`, asserting the
  camelCase Swift properties (`savedHere`, `selectedNeighborhoodID`) decode correctly.
  - **Decide which DTO carries which key:** `savedHere` → `OnboardingContextDTO`;
    `selectedNeighborhoodID` → `TripDraftDTO`. Pick the DTO whose JSON the production read actually
    returns and that contains the target key (executor confirms by reading
    `Responses/DTO/OnboardingContextDTO.swift` and `TripDraftDTO.swift` for the full key set before
    authoring the literal). If both keys live on different DTOs, write the test against the DTO whose
    snake↔camel acronym conversion is non-trivial — **`selectedNeighborhoodID`** is the load-bearing case
    (`selected_neighborhood_id` → `selectedNeighborhoodId`/`ID`), so prefer `TripDraftDTO`.
  - **Why this test exists:** the symmetric round-trips (A1/A4) deliberately do NOT exercise the
    production snake-case coder; this is the single test that proves the real wire path decodes.
- **MockProvider scenarios:** none — decode a literal payload directly with `APIJSON.decoder()`.
- **Done-when:** a snake_case literal decodes via `APIJSON.decoder()` and the camelCase property
  (incl. the `…ID` acronym key) holds the expected value; the test is documented as the wire-path analog
  to the symmetric round-trips.

### Task A3 — L2: generation arithmetic + read-path failure + loading transition
- **Agent:** `swift-test-writer`
- **File (edit):** `…/ios/AppTemplateTests/Store/OnboardingCommandTests.swift`
- **Exemplar to mirror:** existing `OnboardingCommandTests.loadHydratesForScenarioA` (the
  `@Test @MainActor … AppStore(api: .mock(scenario:)) … await store.loadOnboarding()` shape) and
  `07-testing.md §5.1`.
- **Rename the file's suite/scope first (see Task A3-RENAME below).**
- **Add — generation arithmetic (the zero-coverage store math):**
  - `advanceGenerationSweepsOneStep` — seed via `.mock(scenario: .onboardingA)`, hydrate, then drive
    onboarding into a state with a `generationPlan` (executor confirms how a plan is seeded — likely
    `loadOnboarding()` then forcing `currentStep = .generating`, or the C-fixture; reconcile against
    `SampleData+Onboarding.swift` and `TripDraftModel.generationPlan`). Capture
    `plan.currentStepIndex` before; call `store.advanceGeneration()`; assert the cursor advanced by 1,
    the prior step is `.done`, the new cursor step is `.current`.
  - `advanceGenerationClampsOnLastStep` — advance until `currentStepIndex` is the last index, then call
    `advanceGeneration()` once more; assert **no-op** (`currentStepIndex` unchanged, no state mutation —
    this is the `guard … indices.contains(next)` clamp at `:93`).
  - `completeGenerationClearsOnboarding` — call `store.completeGeneration()`; assert
    `store.onboarding == nil` (`:101-105`).
  - `cancelOnboardingClearsOnboarding` — call `store.cancelOnboarding()`; assert
    `store.onboarding == nil` (`:107-110`).
  - Note: `advanceGeneration()` mutates a value-type `plan` and writes it back via
    `onboarding?.generationPlan = plan` — assert on the **re-read** `store.onboarding?.generationPlan`,
    not a captured copy.
- **Add — read-path failure analog (the missing `.failed` test):**
  - `loadOnboardingFailsCleanly` — `let store = AppStore(api: .mock(scenario: .onboardingA, failure: .offline))`;
    `await store.loadOnboarding()`; assert `store.onboardingLoadState == .failed("...")` (match the
    `.failed` case, not the exact string — use a pattern match: `if case .failed = store.onboardingLoadState {}`)
    **and** `store.onboarding == nil` (no partial graph leaks — `setOnboarding` is never reached on the
    throw path, `:22-24`).
- **Add — loading transition observation:**
  - `loadOnboardingTransitionsThroughLoading` — use `.mock(scenario: .onboardingA, latency: .milliseconds(50))`;
    kick `loadOnboarding()` in a non-awaited `Task` (or observe synchronously after the `onboardingLoadState = .loading`
    assignment, which is the first synchronous statement before the `await`); assert `.loading` is observed
    before `.loaded`. **Sketch — executor must reconcile the await/observation seam against
    `loadOnboarding()`'s structure (`:13-25`):** the simplest deterministic form is to assert the
    synchronous pre-await assignment by checking `store.onboardingLoadState == .loading` immediately after
    starting the task but before yielding, then `await` completion and assert `.loaded`. If that races,
    fall back to asserting only the terminal `.loaded` and document loading as covered by the latency seam.
- **MockProvider scenarios:** `.onboardingA` (happy + arithmetic); `.onboardingA, failure: .offline`
  (failure); `.onboardingA, latency: .milliseconds(50)` (loading).
- **Done-when:** `advanceGeneration` sweep AND clamp-on-last both asserted; `completeGeneration` and
  `cancelOnboarding` each assert `onboarding == nil`; the offline failure asserts `.failed` + `nil`
  graph; a `.loading` observation exists or is documented as latency-seam-covered; all `@MainActor`,
  fresh store per test, no `Date()`/`Calendar`.

### Task A3b — L2: table-drive A/B/C hydration
- **Agent:** `swift-test-writer` · **File:** `…/ios/AppTemplateTests/Store/OnboardingCommandTests.swift`
  (same file as A3 → **serialize with A3 under one executor**).
- **Exemplar:** the three near-identical `loadHydratesForScenarioA` / `branchB` / `branchC`
  (`OnboardingCommandTests.swift:15-69`) and `07-testing.md §7.2` table-driven style.
- **Refactor:** collapse the three hydration tests into ONE `@Test(arguments:)` over a row tuple of
  `(scenario: MockScenario, savedHere: Int?, expectedState: OnboardingState)` — e.g.
  `(.onboardingA, 23, .returningWithLocalSaves)`, `(.onboardingB, 0, .savesElsewhere)`,
  `(.onboardingC, nil/0, .firstTrip)`. Each row hydrates and asserts `onboardingLoadState == .loaded`,
  `onboarding != nil`, the branch-specific saved-count expectation, and `onboardingState`.
  - **Sketch (reconcile `@Test(arguments:)` tuple form against the real API):** keep the
    branch-specific assertions that don't fit a uniform tuple (B's `savedAnywhere > 0`, C's
    `savedAnywhere == 0`) as a small per-row closure or a richer tuple — do not lose any existing
    assertion.
- **Done-when:** the three hydration tests are one parameterized test with no lost assertion; A/B/C all
  pass; file still compiles with A3's additions.

### Task A3-RENAME — rename the command test file/suite to match its widened scope
- **Agent:** `swift-test-writer` (fold into the A3 executor).
- **Decision:** the file now covers hydration **and** generation arithmetic **and** read-failure — not
  just "command + branch derivation." **Rename the `@Suite` display name** to
  `@Suite("Onboarding store — hydration, generation, and read-failure")` and update the file header
  comment. **Keep the filename `OnboardingCommandTests.swift`** (renaming the file churns `.pbxproj`
  for no test-discovery benefit; Swift Testing keys off the `@Suite` name, and the coverage gate reads
  symbols, not filenames). If the executor judges a file rename is warranted, that is a **SERIAL
  `.pbxproj` edit** and must be flagged to the coordinator — default is rename the suite only.
- **Done-when:** suite display name + header reflect the three responsibilities; filename unchanged
  (or, if changed, `.pbxproj` membership updated and flagged serial).

### Task A4 — L1: table-drive the model DTO round-trips
- **Agent:** `swift-test-writer` · **File:** `…/ios/AppTemplateTests/Models/OnboardingModelTests.swift`
  (same file as A1/A2 → **serialize under one executor**).
- **Exemplar:** the three `tripDraft{A,B,C}MappingRoundTrip` (`OnboardingModelTests.swift:117-147`) and
  the three `context{A,B,C}JSONRoundTrip` (`:63-88`).
- **Refactor:** collapse each near-identical A/B/C triple into ONE `@Test(arguments:)`:
  - context JSON round-trip → `@Test(arguments: [SampleData.onboardingAContext(), …Context(), …Context()])`.
  - TripDraftDTO mapping round-trip → same arg-set, asserting `dto.toDomain().toDTO() == dto`.
  - **Preserve the C-specific precondition** (`tasteDefaults != nil`, `:84`) — keep it as a guarded
    assertion inside the parameterized body keyed on the C fixture, or as a separate retained test. **Do
    NOT drop the non-nil-`tasteDefaults` precondition.**
  - Keep `tripDraftTripWhenAndNeighborhoodRoundTrip` (`:163`) and the `onboardingState` branch tests
    (`:92-108`) as-is or table-drive the branch trio too (per the task: branch derivation `:92-108` →
    `@Test(arguments:)` over `(context, expectedState)`).
- **Done-when:** the A/B/C DTO/JSON round-trip triples and the branch-derivation trio are parameterized;
  the C `tasteDefaults`-non-nil precondition survives; no assertion lost; `@MainActor` where the mapping
  tests already require it.

### Task A-DEC — document the rollback test as DEFERRED (write coming later), not absent-by-design
- **Agent:** `swift-test-writer` (or coordinator) · **Files:** `…/docs/decisions.md` (append) **and**
  the header comment of `…/ios/AppTemplateTests/Store/OnboardingCommandTests.swift`.
- **Framing (user, this session):** onboarding has **no networked write YET, but one is coming.** Do NOT
  write "onboarding is local-session-only by design / no rollback exists." Frame as a **deferral**.
- **Content (prose, executor writes — concise per project convention):** a dated append-only entry:
  onboarding currently has no networked write — its single request `GetOnboardingContextRequest` is a read;
  today's mutations are in-place `TripDraftModel` transitions applied client-side. **A write command
  (optimistic-apply + rollback) is on the roadmap; the rollback/error-path test is therefore DEFERRED until
  that write lands** (at which point it mirrors the Library borrow flow's rollback test — `07-testing.md
  §5.1`). Until then the L2 onboarding suite covers read-path failure (`.failed` + no partial graph) and the
  store's generation arithmetic. Cross-reference the `UITEST_FAILURE_RATE` future-hook entry (Task C5).
- Mirror a one-line **TODO/deferred** note in the `OnboardingCommandTests.swift` header so the pending
  rollback coverage is visible at the test site (e.g. "// TODO(write): add optimistic-apply + rollback
  tests when the onboarding write command lands — deferred per decisions.md").
- **Done-when:** `decisions.md` has the dated **deferral** entry (not a permanent-absence decision); the
  command-test header carries the TODO/deferred note; **serialize this decisions.md edit with C5's**.

---

## WAVE B — presenter refactor (single file, serialize B1–B4 under one executor)

**File for all of B:** `…/ios/AppTemplateTests/Screens/OnboardingPresenterTests.swift`

### Task B1 — delete tautologies, replace with frozen-literal oracles
- **Agent:** `swift-test-writer`.
- **Delete (each re-evaluates the presenter's own expression → cannot fail):**
  - `:957-962` `suggestedHint` (`#expect(p.suggestedHint == "\(p.suggestedMode.label) is what we suggested")`).
  - `:992-998` `ctaTitleContainsPrimaryMode` (`expected = "Continue · Mostly \(p.primaryMode.label.lowercased())"`).
  - `:1385-1390` `exactRangeFloorHint` (`#expect(p.exactRangeFloorHint == "At least \(p.fixedDays) days")`).
  - `:430-435` `ctaTitleContainsDays` (`#expect(p.ctaTitle == "Continue · \(p.tasteDays) days")`).
- **Replace each** with a frozen-literal oracle over a concrete seeded state — assert the **literal
  string**, not the re-derived expression. Executor must read the presenter source to confirm the exact
  frozen output for the chosen fixture (do NOT invent copy):
  - `suggestedHint` (stateA, `.gettingAround`): determine `suggestedMode` for `onboardingAContext()`,
    then assert the literal, e.g. `#expect(p.suggestedHint == "Transit is what we suggested")` — **confirm
    the actual suggested mode + label against `GettingAroundStepPresenter.suggestedMode` / `Mode.label`**.
  - `ctaTitle` (gettingAround, stateA, default `primaryMode`): assert the literal
    `"Continue · Mostly transit"` (or whatever the seeded default lowercased label is) — **confirm**.
  - `exactRangeFloorHint` (stateA, `.when`): assert `"At least <N> days"` with the literal `fixedDays`
    from `onboardingAContext()` — **confirm N from the fixture**.
  - `ctaTitle` (tasteForm, stateC, `.tripShape`): assert `"Continue · <N> days"` with the literal
    `tasteDays` from `onboardingCContext()` (seed default days = 4 per the file's own comment at `:218`)
    — assert `"Continue · 4 days"`, **confirming 4 against the C fixture**.
- **Sketch label:** every literal above is a SKETCH — executor reads `…/ios/AppTemplate/Screens/Onboarding/`
  presenters + `SampleData+Onboarding.swift` and writes the true frozen literal.
- **Done-when:** all four tautologies are gone; each replaced by an assertion on a hardcoded literal
  string for a named fixture+step; a presenter copy change would now fail the test (the whole point).

### Task B2 — delete mirror tests
- **Agent:** `swift-test-writer`.
- **Delete (assert the literal that IS the body / `count == count` over the same array):**
  - `:386-391` `interestsIsAllCases` (`p.interests == Interest.allCases`).
  - `:393-398` `paceOptionsIsAllCases` (`p.paceOptions == Pace.allCases`).
  - `:379-384` `interestChipsCount` (`p.interestChips.count == Interest.allCases.count`).
  - `:966-971` `alsoOKChipsCount` (`p.alsoOKChips.count == p.alsoOKModes.count`) — same `count==count`
    mirror class; delete it too (the real selection contract is covered by `alsoOKChipsAfterToggle`/
    `alsoOKChipsAllUnselectedInitially`).
- **Confirm before deleting:** the real chip-selection contract stays covered by
  `interestChipsSelectionStateC` (`:418-426`) for interests and `alsoOKChipsAfterToggle` (`:981-988`) +
  `alsoOKChipsAllUnselectedInitially` (`:973-979`) for alsoOK. **Do not delete those.**
- **Done-when:** the four mirror tests are gone; `interestChipsSelectionStateC` and the alsoOK
  selection/initial tests remain; the suite still compiles.

### Task B3 — add per-suite `makePresenter` factory helpers; remove repeated store+presenter pairs
- **Agent:** `swift-test-writer`.
- **Problem:** ~149 repeated `AppStore.preview(SampleData.onboarding?Context(), step: .?)` +
  `SomePresenter(store: store)` pairs across the file.
- **Add — one factory per presenter suite** (file-private), signature shape:
  `@MainActor func makePresenter(_ ctx: OnboardingContextDTO, step: OnboardingStep, mutate: (TripDraftModel) -> Void = { _ in }) -> TripShapeStepPresenter`
  (and analogues for `GettingAroundStepPresenter`, `WhenStepPresenter`, `BaseLocationStepPresenter`,
  `GeneratingStepPresenter`). The `mutate` closure replaces the inline
  `store.onboarding?.select(strategy:)` / `setPrimaryMode` / `toggleAlsoOK` calls so a test reads as one
  line: `let p = makePresenter(.onboardingAContext(), step: .gettingAround) { $0.setPrimaryMode(.walk) }`.
  - **Sketch label:** the exact factory return type + whether one generic helper vs per-suite helpers is
    cleaner is the executor's call — reconcile against the real presenter initializers
    (`<Presenter>(store:)`) and `AppStore.preview` signature. Each presenter suite already pins one
    context/step pattern; mirror that.
- **Constraint:** purely mechanical dedup — **no assertion may change**. The factory wraps
  `AppStore.preview(ctx, step:)` + the presenter init + the optional mutate, exactly as the inline code
  did (note: inline code mutates *before* constructing the presenter — preserve that ordering, since the
  presenter is a stateless value over the store).
- **Done-when:** each presenter suite has a `makePresenter` factory; the inline `AppStore.preview(…)` +
  `…Presenter(store:)` pairs are replaced by factory calls; assertion bodies unchanged; file compiles;
  reviewer confirms no behavioral drift.

### Task B4 — table-drive branch-derivation triples
- **Agent:** `swift-test-writer`.
- **Convert** the near-identical A/B/C derivation triples (e.g. `canContinueFalseNoPick_stateA/_stateB`
  at `:439-451`, and any other A/B/C trio that asserts the same derived value across fixtures) to
  `@Test(arguments:)` over the context fixtures, using the B3 `makePresenter` factory in the body.
  - Keep state-specific tests (e.g. `paceDefaultStateC`, `selectedInterestsSeedStateC`) standalone —
    only collapse trios that assert the *same* property across A/B/C.
- **Done-when:** symmetric A/B/C derivation trios are parameterized via `makePresenter`; state-unique
  tests remain standalone; no assertion lost.

---

## WAVE C — L4 robot + UITests (shared family — C0 first, then parallel-disjoint, doc/pbxproj serial)

### Task C0 — introduce `OnboardingRobot` (NEW Support file)
- **Agent:** `swift-uitest-writer`.
- **File (create):** `…/ios/AppTemplateUITests/Support/OnboardingRobot.swift`
- **Also (SERIAL):** add the file to the `AppTemplateUITests` target in
  `…/ios/AppTemplate.xcodeproj/project.pbxproj` (synchronized-folder project — confirm whether the new
  `Support/` dir auto-joins or needs an explicit membership entry; if it auto-joins, no pbxproj edit —
  **flag to coordinator either way**).
- **Exemplar to mirror — VERBATIM:** the byte-identical helpers in `OnboardingTripShapeUITests.swift`:
  `makeLaunchedApp(scenario:)` (`:63-74`), `scrollToElement(_:in:maxSwipes:)` (`:79-82`), and the audit
  handler block from `testAccessibilityAudit` (`:359-379`) — the suppression set
  `[.dynamicType, .contrast, .textClipped]` + the `onboarding.progress` `.hitRegion` exemption.
- **Robot API (struct or final class wrapping `XCUIApplication`; `swift-uitest-writer` picks the idiom):**
  - `launch(scenario: String = "onboardingA", startStep: String? = nil, now: String = "2026-06-03T12:00:00Z", failureRate: Double? = nil) -> XCUIApplication`
    — owns `UITEST_SCENARIO`, `UITEST_START_STEP`, `UITEST_NOW`, `-UIAnimationDragCoefficient 10`, **and
    forwards `UITEST_FAILURE_RATE` when `failureRate` is non-nil** (preserving the future-hook seam — see
    C5; nothing consumes it yet, but the onboarding write is coming, so the robot keeps the plumbing).
  - `scrollToElement(_ element: XCUIElement, maxSwipes: Int = 6)`.
  - `performOnboardingAudit() throws` — runs the **broad** `performAccessibilityAudit { … }` with the
    EXISTING suppression list **verbatim** (no narrowing of `for:`). This centralizes the suppression in
    ONE place so Track B can refine it later here.
  - Minimal a11y-id query surface only as needed (e.g. `cta(_ id:)`, `backButton`). **Keep queries
    minimal; do NOT touch / depend on the known-fragile double-stamped `searchwell` id** (Track B owns
    the a11y-contract fixes). Robot must not encode the searchwell workaround.
- **Constraint:** the robot is a pure extraction — it must reproduce the existing helpers' behavior
  exactly (same env keys, same drag coefficient, same suppression set). **No a11y-contract changes, no
  suppression refinement** (Track B).
- **Done-when:** `OnboardingRobot.swift` exists in `Support/`, joins the UITest target, and owns
  launch/scroll/audit with the verbatim existing suppression list; it compiles standalone; it **forwards
  `UITEST_FAILURE_RATE` via the optional `failureRate` param** (future hook, unconsumed today); no
  searchwell dependency.

### Task C1 — migrate the 6 suites onto the robot (delete copy-pasted helpers)
- **Agent:** `swift-uitest-writer` (after C0 lands).
- **Files (each disjoint once C0 exists — batchable across executors, one per suite):**
  `OnboardingTripShapeUITests.swift`, `OnboardingWhenUITests.swift`, `OnboardingBaseLocationUITests.swift`,
  `OnboardingGettingAroundUITests.swift`, `OnboardingDestinationUITests.swift`,
  `OnboardingGeneratingUITests.swift` — all under `…/ios/AppTemplateUITests/`.
- **Per file:** delete the file-local `makeLaunchedApp`, `scrollToElement`, and the inline audit handler;
  route those through `OnboardingRobot`. Keep each suite's screen-specific assertions intact.
- **Done-when:** no suite defines its own `makeLaunchedApp`/`scrollToElement`/audit handler; all use the
  robot; each suite still tests its screen; the full UITest target compiles; behavior unchanged.

### Task C2 — make conditional scroll-then-assert UNCONDITIONAL
- **Agent:** `swift-uitest-writer` (fold into the relevant C1 file tasks).
- **Sites (a green test that verified nothing):**
  - `OnboardingTripShapeUITests.swift:295` `if nightlifeChip.isHittable { … tap + assert isSelected }`.
  - `OnboardingGettingAroundUITests.swift:260` `if rideshareChip.isHittable { … }`.
  - `OnboardingGettingAroundUITests.swift:296` `if cycleChip.isHittable { … }`.
- **Fix:** `robot.scrollToElement(chip)` to realize it, then **unconditionally**
  `XCTAssertTrue(chip.waitForExistence(timeout: …))`, `XCTAssertTrue(chip.isHittable)`, tap, and assert
  the post-tap `isSelected` (the existing `NSPredicate(format: "isSelected == true")` expectation). The
  element must be scrolled into the realized tree first, then asserted — no `if isHittable` escape hatch.
- **Done-when:** the three `if …isHittable` guards are gone; each is scroll-to-realize then
  unconditional existence + hittable + post-tap selection assertion.

### Task C3 — new back-navigation test (taps `onboarding.back`, asserts prior step)
- **Agent:** `swift-uitest-writer`.
- **File:** one existing suite that launches mid-flow — recommend `OnboardingGettingAroundUITests.swift`
  (launches at `.gettingAround`; back should land on `.when` or `.baseLocation` — executor confirms the
  step order from `OnboardingFlowView` / the `OnboardingStep` enum order before asserting the target).
- **Exemplar:** existing `testBackButtonExists` (`OnboardingGettingAroundUITests.swift:355`) — which only
  asserts the button is hittable. The new test goes further.
- **Add `testBackNavigatesToPriorStep`:** launch via robot at `.gettingAround`, wait for the step's CTA
  sentinel, `app.buttons["onboarding.back"].tap()`, then assert a **prior-step-unique** a11y id appears
  (e.g. the prior step's CTA/sentinel id) and the current step's sentinel disappears. `onboarding.back`
  drives `store.retreatOnboardingStep()` which ships.
  - **Sketch:** the exact prior-step sentinel id depends on the step order — executor reads the step
    sequence + the prior step view's ids (`baselocation.cta` / `when` step sentinel) and asserts the real id.
- **Done-when:** a test taps `onboarding.back` and asserts the **prior step** rendered (not just that the
  button is hittable); uses the robot; a regression that no-ops back would fail it.

### Task C4 — new disabled-CTA assertion (BaseLocation manual mode before a pick)
- **Agent:** `swift-uitest-writer` · **File:** `…/ios/AppTemplateUITests/OnboardingBaseLocationUITests.swift`
- **Exemplar:** `BaseLocationStepView.swift:29-30` (`primaryEnabled: presenter.canContinue`,
  `primaryAccessibilityID: "baselocation.cta"`) and the manual-picker ids `baselocation.manual.pinned`
  (`:227`) / `baselocation.manual.<id>` (`:270`).
- **Add `testManualBaseCTADisabledBeforePick`:** launch via robot at `.baseLocation`, enter manual mode
  (executor confirms how manual mode is reached — there's a smart/manual segment; find its a11y id by
  reading `BaseLocationStepView.swift` around the segment control, **not** by guessing), then before any
  `baselocation.manual.<id>` row is tapped assert:
  `let cta = app.buttons["baselocation.cta"]; XCTAssertTrue(cta.exists); XCTAssertFalse(cta.isEnabled)`.
  Optionally then tap a manual row and assert `cta.isEnabled` becomes true (proves the gate, not just the
  disabled state).
  - **Sketch:** the manual-mode entry affordance id is unconfirmed — executor must read
    `BaseLocationStepView.swift` for the segment/toggle id (the view sets `setBaseMode(.manual)`); if no
    stable a11y id exists for the segment, the test should use whatever existing manual-picker id realizes
    the manual body, or this becomes an **open decision** (see Open Decisions). Do NOT add a new
    production a11y id (Track A is test-only).
- **Done-when:** a test asserts `baselocation.cta` exists but is **disabled** in manual mode pre-pick (and
  ideally enabled post-pick); a regression making the CTA always-enabled fails it; **no production change**.

### Task C5 — KEEP `UITEST_FAILURE_RATE` as an intentional future hook + document
- **Agent:** `swift-uitest-writer` · **Files:** the robot (C0) which now owns the forwarding, the 3 suites
  currently forwarding it — `OnboardingGettingAroundUITests.swift:61/68`, `OnboardingWhenUITests.swift:57/62/70`,
  `OnboardingBaseLocationUITests.swift:75/81` (their forwarding migrates into the robot via C1) — **and**
  `…/docs/decisions.md` (SERIAL append).
- **Decision (user, this session):** **KEEP the seam** as deliberate scaffolding for the upcoming
  onboarding write. The write (optimistic-apply + rollback) is on the roadmap; when it lands it will wire
  `UITEST_FAILURE_RATE` → app init → `.mock(failure:)` and add the error-path/rollback tests. Until then the
  env var is forwarded but unconsumed — that is intentional, NOT dead code.
- **Action:** do NOT delete the forwarding. When C1 migrates the suites onto the robot, the robot's optional
  `failureRate` param (C0) carries `UITEST_FAILURE_RATE` so the plumbing survives in ONE place. Append a
  dated `decisions.md` entry: the seam is an intentional, currently-unconsumed future hook for the planned
  onboarding write — reviewers/coverage-gate must NOT flag it as dead, and whoever adds the write wires it
  through to `AppTemplateApp.init` + `.mock(failure:)` and adds the rollback/error tests then.
- **Done-when:** the `UITEST_FAILURE_RATE` forwarding survives (now centralized in the robot's `failureRate`
  param); `decisions.md` has the dated future-hook entry; serialize the doc edit with A-DEC.

### Task C6 — one end-to-end multi-step flow walk (NEW suite)
- **Agent:** `swift-uitest-writer`.
- **File (create):** `…/ios/AppTemplateUITests/OnboardingFlowUITests.swift`
- **Also (SERIAL):** add the new file to the `AppTemplateUITests` target in `project.pbxproj` (flag to
  coordinator; confirm synchronized-folder auto-membership first).
- **Why:** every existing suite shortcuts in via `UITEST_START_STEP`, so `OnboardingFlowView`'s
  step-to-step orchestration is never exercised as a sequence.
- **Add `testFlowAdvancesAcrossStepBoundaries`:** launch via robot **without** `UITEST_START_STEP`
  (defaults to the first step / scenario A). Then walk forward across at least **two** inter-step
  boundaries by satisfying each step's continue gate and tapping its CTA, asserting at each boundary that
  the next step's sentinel id appears and the previous one disappears. Executor reads the
  `OnboardingStep` order + each step view's CTA id and minimal "satisfy the gate" interaction (e.g. pick
  a shape card / select a base) from the step views; keep the walk to the shortest deterministic path
  that crosses ≥2 boundaries (e.g. step1 → step2 → step3).
  - **Sketch:** the exact CTA ids and per-step gate interactions are step-specific — executor reconciles
    against the real step views; reuse robot helpers; do not depend on the fragile `searchwell` id.
- **Done-when:** one test launches at the flow start (no `UITEST_START_STEP`) and advances across ≥2
  real inter-step boundaries, asserting each transition by a11y id; it uses the robot; it joins the
  UITest target.

---

## WAVE D — L3 ProgressBar string correctness fix (disjoint)

### Task D1 — correct "/ 05" → "/ 06" display strings + delete the stale note
- **Agent:** `swift-snapshot-test-writer`.
- **File:** `…/ios/AppTemplateTests/Snapshots/Onboarding/OnboardingProgressBarSnapshotTests.swift`
- **This is a TEST-NAME/STRING fix, NOT a re-record.** The PNGs were already re-recorded to "/ 06" in
  commit `a27e121`; only the `@Test("…")` display strings and docstrings still lie.
- **Edits:**
  - `:44` display name "01 / 05" → "01 / 06"; update the `:42-43` docstring "counter reads 01 / 05" → "01 / 06"
    and the segment-count prose ("four todo segments" is for a 5-step bar → for `stepIndex 0` of 6 it's
    **five** todo segments; correct the count prose to match the 6-segment default).
  - `:57` "03 / 05" → "03 / 06"; `:54-56` docstring counts updated for `totalSteps: 6` (segments 3,4,**5**
    todo).
  - `:69` "05 / 05" → "05 / 06"; `:67-68` docstring "the final step"/"05 / 05" is wrong — at `stepIndex 4`
    of 6 it is **not** the final step; correct to "a late step … counter 05 / 06" with the right segment
    breakdown (segments 0–3 done, 4 cur, 5 todo).
  - Delete the stale header note `:15-17` ("existing step-0/2/4 baselines reference a prior 5-step
    default… Leave those cases as-is") — it is no longer true (PNGs already re-recorded).
  - Leave `step5()` (`:77-89`) as-is (already correct "/ 06").
- **Constraint:** **do NOT** set `record: .all`, do NOT re-record, do NOT add the AX5 compensating
  snapshot (Track B). String/docstring edits only — the committed PNGs are the contract and already match.
- **Done-when:** all three display strings read "/ 06"; docstrings' counter + segment-count prose match
  the `totalSteps: 6` default; the stale "leave as-is" note is gone; no `record:` flag introduced; the
  three existing snapshots still pass against the committed "/ 06" PNGs (no diff).

---

## Gate (commit step — coordinator)

1. **Build clean** (zero concurrency diagnostics):
   `xcodebuild -project ios/AppTemplate.xcodeproj -scheme AppTemplate -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4.1' CODE_SIGNING_ALLOWED=NO build`
   then `test` (or `-only-testing:AppTemplateTests` then the UITest bundle) — all four layers green.
2. **`ios-test-coverage-check`** — confirms: generation arithmetic now covered (L2); read-failure
   covered (L2); `CityMeta`/`DiagramSpec` Codable covered (L1); snake-case wire path covered (L2); back-nav
   + disabled-CTA + flow-walk covered (L4). The "no onboarding write" decision is documented (so the gate
   doesn't flag a missing rollback test).
3. **`swift-code-reviewer`** — confirms: no production view/component/model source changed (test-only);
   no tautology/mirror tests reintroduced; the robot centralizes launch/scroll/audit with the verbatim
   suppression list; `UITEST_FAILURE_RATE` is **preserved as the documented future hook** (robot's
   `failureRate` param) — not flagged as dead; no `searchwell` dependency; D1 changed strings only.
4. **Serial-edit confirmation:** `OnboardingModelTests.swift`, `OnboardingCommandTests.swift`,
   `OnboardingPresenterTests.swift`, `docs/decisions.md`, and `project.pbxproj` (C0/C6 new files) were
   each edited by a single serialized writer — no concurrent writes.
5. Commit (Track A only) on the worktree branch; do not touch `main`.

---

## Open decisions (settle before/at execution)

1. **C4 manual-mode entry id** — `BaseLocationStepView` has a smart/manual segment but the plan did not
   confirm a stable a11y id on the segment control itself (it sets `setBaseMode(.manual)`). If no id
   exists to deterministically enter manual mode, the disabled-CTA test must either (a) drive manual mode
   through an existing realized `baselocation.manual.*` affordance, or (b) be deferred — **Track A is
   test-only and must not add a production a11y id.** Executor confirms; if neither path works without a
   production change, flag back rather than inventing one.
2. **A3 loading-transition determinism** — whether `.loading` can be observed deterministically without a
   race depends on `loadOnboarding()`'s await structure. The plan permits falling back to "latency-seam
   covered, `.loaded` asserted" if the synchronous pre-await observation races. Executor decides against
   live source and documents the choice in the test comment.
3. **A3-RENAME file rename** — default is rename the `@Suite` only (no `.pbxproj` churn). If a file rename
   is judged worthwhile, it becomes a SERIAL `.pbxproj` edit — flag to coordinator.

---

## Track B follows (do NOT plan here)

A separate later track owns: AX5 compensating snapshots (incl. the ProgressBar AX5 lock);
component a11y-id passthrough (`SearchWell`/`GlassCircleButton`/`LeadingGlyph`); view a11y annotations
(labels/values/grouping); value/label test assertions; audit suppression-discipline refinement (in the
ONE place Track A centralizes it — `OnboardingRobot.performOnboardingAudit`); and the a11y coverage-gate
additions. The `searchwell` double-stamped-id fix lives in Track B.
