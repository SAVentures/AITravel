# Session retro — problems hit building Phase 0 + the onboarding feature

**Date:** 2026-06-02 → 2026-06-03 · **Scope:** scaffolding the Xcode project, the Phase 0 design-system
foundation-freeze, and the first feature (onboarding: 5 adaptive screens + model/seed/store).

This is a **source document** for updating the `swift-*` agents (`.claude/agents/`) and the engineering
docs (`ios/docs/engineering/`). Each entry: **symptom → root cause → fix → prevention** (the doc/agent
change that would have stopped it). Ordered roughly by how much time each cost and how often it recurred.

---

## 1. Swift 6.2 MainActor-by-default: the wire boundary must be `nonisolated` (RECURRED 4×)

**The single most repeated failure of the session.** The project sets
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so *every* type/protocol/conformance is MainActor-isolated
unless marked otherwise. But the networking layer crosses to a background executor, and the compiler
rejects the mismatch — four distinct times, each a separate build-fix cycle:

| # | Symptom (build error) | Fix |
|---|---|---|
| a | `LiveProvider.send` (`@concurrent`) can't call MainActor-isolated `makeURLRequest` / `APIJSON.decoder()` | mark `LiveProvider` + `APIJSON` `nonisolated` |
| b | `Main actor-isolated property 'path'/'method'/'body' can not be referenced from a nonisolated context` | mark every `APIRequest` protocol **requirement** `nonisolated` |
| c | `main actor-isolated conformance of 'OnboardingContextDTO' to 'Decodable' cannot satisfy ... 'Sendable' type parameter 'Self.Response'` | mark **all** wire value types (DTOs + every leaf `Codable` value type they compose) `nonisolated` |
| d | `conformance of 'GetOnboardingContextRequest' to 'APIRequest' crosses into main actor-isolated code` | mark the request **struct** `nonisolated` |

**Root cause.** `02-models.md §9` / `04-networking.md` say "DTOs + leaf value types + `APIRequest` are
`Sendable` and cross to the background" but **never show the `nonisolated` keyword** that this requires
under default-MainActor isolation. The scaffolders wrote plain `struct Foo: Codable, Sendable {}` (which
is MainActor-isolated) and it only fails at the *use site* (the off-main decode), so each layer broke
independently.

**Prevention (high priority):**
- **`04-networking.md` + `02-models.md`:** add an explicit rule — *"every wire type is `nonisolated`:
  `nonisolated struct XDTO: Codable, Sendable`, `nonisolated protocol APIRequest`, `nonisolated struct
  XRequest: APIRequest`, `nonisolated enum APIJSON`. The `Sendable`/`@MainActor func toDomain()` methods
  stay; only the type opts out of the default actor."* Show it in the skeletons.
- **`swift-model-scaffold` + `swift-networking-endpoint` agents:** bake "mark wire value types / request
  structs / DTOs `nonisolated`" into their checklists. A DTO or `APIRequest` that is NOT `nonisolated` is
  a defect.
- **`01-architecture.md §9`:** state the rule once, prominently: *MainActor is the default; the wire
  boundary (everything that decodes off-main) is the explicit `nonisolated` exception — and it's a
  per-declaration modifier, not just `Sendable`.*

---

## 2. The stale-DerivedData verification trap (cost the most wall-clock to diagnose)

**Symptom.** After building + installing + screenshotting the running app, the screen showed the **old
Phase-0 placeholder** ("Scaffold ready — screens arrive through the pipeline") instead of onboarding —
through *multiple* fix/rebuild/screenshot cycles. I chased non-existent app bugs (presentation, load
path) because the binary on screen never changed.

**Root cause.** A **git worktree builds into its own DerivedData** (`AppTemplate-<worktreeHash>`), but the
verification grabbed `find ~/Library/Developer/Xcode/DerivedData/AppTemplate-* | head -1`, which returned
the **stale main-checkout build** (`AppTemplate-dcokc…`) from Phase 0. I was installing a months-old
binary every time.

**Fix.** Resolve the real path: `xcodebuild … -showBuildSettings | grep BUILT_PRODUCTS_DIR`.

**Prevention:**
- **`ios-subagent-development` skill + `ios-worktree` command:** document that **each worktree has its own
  DerivedData** and that any install/run/screenshot MUST resolve `BUILT_PRODUCTS_DIR` via
  `-showBuildSettings` (or `xcodebuild ... install`/`-derivedDataPath`), never `find | head -1`.
- Add a tiny helper script `run-app.sh <worktree>` that resolves the right `.app` and installs/launches it.

---

## 3. SwiftUI dependency tracking: a read inside a closure is NOT a body dependency

**Symptom.** `loadOnboarding()` set `store.onboarding` (proven by a passing unit test), but the
`.fullScreenCover` never presented — the app sat on the placeholder root.

**Root cause.** `RootView.body` only read `store.onboarding` **inside** the `.task { … }` closure and a
custom `Binding(get:)` closure — both run *after* body evaluation. `@Observable` only registers a
dependency for properties read **during** `body`, so the view never re-rendered when `onboarding` changed.

**Fix.** Drive presentation from a tracked read: `@State private var showsOnboarding` synced via
`.onChange(of: store.onboarding != nil, initial: true) { … }` (the `of:` expression is evaluated during
`body`).

**Prevention:**
- **`06-screens.md` (navigation/presentation):** add a rule + example — *"to present a sheet/cover from
  an `@Observable` store value, the trigger must be read in `body` (an `.onChange(of:)` value or a `let`),
  not only inside `.task`/`Binding` closures, or the view won't re-render. Prefer `.onChange(of:
  store.x != nil, initial: true)` driving a local `@State`, or `.fullScreenCover(item:)`."*
- **`swift-screen-builder`:** flag "presentation bound to a store optional via a custom `Binding(get:)`
  with no in-body read" as a smell.

---

## 4. SwiftUI: a focusable `TextField` duplicated across a conditional → focus loop / FREEZE

**Symptom.** Tapping the search bar **froze the screen** (hard hang).

**Root cause.** `searchWell()` (containing the `TextField`) was rendered in **both** arms of
`if isSearching { searchWell(); results } else { hero; searchWell(); … }`. Focusing the field flipped
`isSearching`, which moved the `TextField` to a different structural slot → SwiftUI tore it down and
rebuilt it → focus lost → `searchFocused` went false → `isSearching` flipped back → rebuild → **infinite
loop**.

**Fix.** Render the field **once at a stable slot** with a stable `.id("…")`, outside the conditional;
only the content *around* it switches.

**Prevention:**
- **`06-screens.md`:** add the rule — *"a focused/stateful control (`TextField`, `@FocusState`) must keep
  one stable position + `.id` across view-state changes; never place the same focusable view in both arms
  of an `if`. Toggle the content around it, not the control itself."*
- **`swift-screen-builder`:** treat "same `TextField`/focusable view in both branches of a state
  conditional" as a defect.

---

## 5. SwiftUI: a container `.accessibilityIdentifier` clobbers child button ids

**Symptom.** `app.buttons["destination.cta"]` did not exist for XCUITest even though the CTA rendered.
The a11y tree showed the CTA **and** the Close button both reporting `identifier: 'onboarding.flow'`.

**Root cause.** `OnboardingFlowView` applied `.accessibilityIdentifier("onboarding.flow")` to the whole
flow `Group`. It propagated to the scaffold's `actions:` CTA and the `.overlay` Close button, **overriding
their own ids** (`destination.cta`, `onboarding.close`). Scroll-content buttons (rail pills, grid tiles)
kept theirs.

**Fix.** Remove the container-level `.accessibilityIdentifier` (a flow container doesn't need a queryable
id; its buttons carry the contract ids).

**Prevention:**
- **`06-screens.md` (a11y ids §):** *"don't put `.accessibilityIdentifier` on a multi-element container —
  it overrides descendant ids. Put ids on the leaf state-bearing elements only."*
- The diagnosis tool that settled it: a `testDumpTree()` printing `app.debugDescription`. Worth documenting
  as the go-to XCUITest debugging step in `07-testing.md §7`.

---

## 6. Snapshot-test infrastructure (Phase 0): four separate gotchas

`07-testing.md §6` described the snapshot helper but each of these bit on first real use:

| Symptom | Root cause | Fix | Prevention (doc) |
|---|---|---|---|
| `XCTestCase` subclasses won't compile | `XCTestCase.init` is `nonisolated`, clashes with the target's MainActor default | use **Swift Testing** (`@Suite`/`@Test @MainActor`) for snapshots, not `XCTestCase` | §6 already says "Swift Testing default" — make it explicit that `XCTestCase` is **incompatible** under default-MainActor; only `XCUITest` (its own target) uses `XCTestCase` |
| `You can't save the file … the volume is read only` on record | the helper passed `#file` (a remapped/non-writable path under `xcodebuild`) | use **`#filePath`** for the baseline dir | §6.1: the helper MUST use `#filePath`, not `#file` |
| `extra argument 'snapshotDirectory'` | that param doesn't exist in swift-snapshot-testing 1.19 | derive the dir from `#filePath`, don't pass `snapshotDirectory:` | pin the library version's actual `assertSnapshot` signature in §6.1 |
| `Multiple commands produce …/X.png` | synchronized folders bundle the committed baseline PNGs; same-named PNGs across suites collide when flattened | **`EXCLUDED_SOURCE_FILE_NAMES = *.png`** on the test target | §6.3: document that committed baselines must be excluded from the bundle via this build setting; note hand-authored `membershipExceptions` in the `.pbxproj` were **silently ignored** (objectVersion 77) |

---

## 7. The plan assumed a foundation that didn't exist (first-feature bootstrap)

**Symptom.** `ios-plan-writer`'s onboarding plan referenced `APIClient`, `AppStore`, `MockScenario`,
`SampleData`, `LoadState` as if they existed; none did (onboarding is the first feature on a fresh app).

**Root cause.** The plan-writer didn't check that the networking/store/sample-data **skeleton** existed
before writing tasks on top of it.

**Prevention:**
- **`ios-plan-writer`:** when the target layer (Networking/Store/Models-core) is empty, **emit an explicit
  "Wave 0: bootstrap the provider-swappable skeleton" set of tasks** (APIRequest/APIClient/MockProvider/
  LiveProvider/MockSeed/MockScenario/APIError/HTTPMethod, AppStore+LoadState, SampleData+AppDate) before
  the feature waves. Detect "first feature" = `ios/AppTemplate/{Networking,Store}` absent.

---

## 8. `ScreenScaffold` call-site signature mismatch (all 5 screens)

**Symptom.** `incorrect argument label in call (have '_:_:actions:', expected '_:actions:content:')` in
every step view.

**Root cause.** The scaffolders called `ScreenScaffold(.immersive, { content }, actions: { … })` —
content positional, actions trailing — but the real init is
`init(_ chrome:, actions: () -> … = …, content: () -> …)` (actions is the named middle closure, content is
the trailing closure).

**Prevention:**
- **`05-design-system.md` / the `ScreenScaffold` doc-comment:** show the canonical call form
  `ScreenScaffold(.immersive, actions: { … }) { content }` prominently.
- **`swift-screen-builder`:** read the actual `ScreenScaffold` `documentSymbol` signature before composing
  (it did, but mis-ordered) — emphasize the trailing-closure-is-content convention.

---

## 9. Generic component + a model enum that isn't `Identifiable`

**Symptom.** `Generic struct 'SegmentedSelector' requires that 'TransportMode' conform to 'Identifiable'`
(and the same for `Pace`).

**Root cause.** `SegmentedSelector<Option: Identifiable & Hashable>` was fed model enums that are
`Codable/Hashable` but not `Identifiable` (models stay `Identifiable`-free per `02-models`).

**Fix.** A screen-layer `extension TransportMode: Identifiable { var id: String { rawValue } }`.

**Prevention:** document the pattern (a same-module screen-layer `Identifiable` conformance for a model
enum used by a generic component) in `06-screens.md`, so it isn't re-discovered per screen.

---

## 10. Feature-wiring defects the design pass didn't catch (only live use / user did)

These compiled + rendered fine but were behaviorally wrong — caught by the user, not the gates:

- **Recent-rail pills were plain display chips** with no tap handler → tapping didn't select the city
  (the grid tiles were `Button`s; the rail chips were not).
- **`SearchWell` shipped as a read-only stub** (`onTap: {}`) per a deliberate W1-05 scope note — but the
  user expected a working search.
- **Solid action floor vs. floating glass CTA / grey vs. white page** — the built result diverged from the
  user's mental model of the mockup until shown live.

**Prevention:**
- **`fidelity-reviewer`:** assert **interactive affordances** — "every tappable-looking element in the
  mockup maps to a real action; read-only stubs are called out explicitly." A row that looks tappable but
  isn't is a fidelity defect.
- **Process:** get a **live run + screenshot in front of the user early** (per screen), not only at the
  end — most of these were one-line fixes once seen. The render-snapshot lock proves *consistency*, not
  *correctness of wiring*; only a run (or an XCUITest) does.

---

## 11. Smaller / one-off

- **`Shadows.swift`:** `private static` helpers (`slate`, `highlight`) referenced from sibling file-scope
  modifier structs → needed `fileprivate` (cross-type, same-file). *Prevention:* note the
  `private`-is-type-scoped vs `fileprivate` distinction in the design-system shadow pattern.
- **`Primitive.*` leak in components** (caps-tracking call passed `Primitive.typeCaptionSize`) → caught by
  `design-reviewer`; fixed by baking `Typography.trackCapsCaption` in the token tier. *Worked as intended*
  — the gate caught it. Keep.
- **iOS 26 `Text` `+` concatenation deprecation** warning recurs in several views (use string
  interpolation). *Prevention:* add to the slop/lint checklist.
- **`SwiftLSP` cross-file ops (`findReferences`/`workspaceSymbol`) returned empty** for freshly-written
  symbols several times (stale index) → agents fell back to `Grep`/`Read`. *Prevention:* the
  `refresh-lsp-index.sh` between waves helps; document that newly-authored symbols aren't indexed until a
  build.

---

## Top 5 to action first

1. **`nonisolated` wire-boundary rule** in `04-networking.md` / `02-models.md` / `01-architecture.md §9`
   + the model/networking agent checklists (§1) — recurred 4× and will recur on every new feature.
2. **Worktree DerivedData / `BUILT_PRODUCTS_DIR`** in the `ios-worktree` + `ios-subagent-development` docs
   (§2) — silent, costly, will mislead every "run it and look" verification.
3. **`#filePath` + `EXCLUDED_SOURCE_FILE_NAMES=*.png` + Swift-Testing-only snapshots** in `07-testing.md
   §6` (§6) — blocks the snapshot lock on first use.
4. **`ios-plan-writer` Wave-0 skeleton detection** for the first feature (§7).
5. **`fidelity-reviewer` checks interactive affordances**, and **run-in-front-of-user-early** as process
   (§10) — the wiring bugs the visual gates can't see.
</content>
