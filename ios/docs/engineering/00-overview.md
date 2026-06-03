# 00 — iOS Engineering Overview

The engineering doc tree for the native SwiftUI app under `ios/`. **Read this first**, then
`01-architecture.md`, then the per-layer doc your task needs.

**Authority split.** This tree describes how the app is **built** (architecture, state, networking,
design-system port, testing). `docs/design-docs/` describes how it **looks** (the visual judgment —
typography, color, layout, motion, the craft bar). `mockups/` is the **source of truth** for token
values and component anatomy. When two disagree, the artifact and its prose move together.

**The app.** Single-target SwiftUI (`AppTemplate` scheme, Xcode 26, **minimum iOS 26**, **Swift 6.2 —
MainActor-by-default**). Light-mode only. It ships one reference vertical slice — a **library /
book-management** master-detail with one write flow — that exercises every layer end-to-end and is the
living exemplar. Swap `LibraryModel`/`BookModel` for your domain when you instantiate the template.

---

## The workflow (hard rule) — the phased pipeline

Every change follows this sequence — no exceptions. Never code on `main`; never hand-edit Swift;
never code without a plan.

```
worktree
  → ios-plan-writer           (architect a contract-level plan from these docs)
  → Phase 0: Foundation       design system: tokens (codegen) → modifiers → components →
              ──[FREEZE]──     composition primitives → reviewed → snapshot-locked   (05 §10)
  → Phase 1: Models + Networking
  → Phase 2: Screens          each: scaffold → consistency-review → fidelity-review   (06 §9)
  → Phase 3: Tests
  → four-layer gate           build clean + all four test layers green   (07 §9)
  → finish-branch
```

The **foundation-freeze** is the one new hard barrier vs. a naive pipeline: no screen is scaffolded
until the design system is locked. It exists because the prior app built screens on a half-formed
system and inherited a shaky base everywhere.

---

## The non-negotiables

Violations require a written entry in `docs/decisions.md` (append-only — new entries supersede, never
edit old ones).

1. **Work goes through the phased pipeline.** Worktree → plan → foundation-freeze → feature phases →
   gate. No ad-hoc edits to `main`, no coding without a plan.
2. **`AppStore` is the single source of truth.** One `@Observable` store, **owned at the App root**
   (`@State private var store = AppStore()`) and injected via the environment — no `.shared` singleton,
   no parallel stores. (`03`)
3. **Reference models for mutable list rows; value types for everything else; DTOs at the wire.**
   `@MainActor @Observable` rows own their mutations; leaf data is value types; the network never
   carries a `@MainActor` domain model — only `Sendable` `*DTO`s. (`02`, `04`)
4. **Screens depend on `APIClient`, never a concrete provider.** Mock/live is swapped at the `AppStore`
   init boundary. (`04`)
5. **Logic out of views.** Pure mutations are **model methods**; networked writes are **store commands**
   (optimistic + `restore(from:)` rollback); screen derivation is a **stateless presenter**; only
   *ephemeral UI* state is `@State`. No per-screen view-model; nothing domain-shaped in `@State`. (`06`)
6. **Design values from *semantic* tokens only; layout from *composition primitives* only.** No literal
   colors/spacing/sizes; no hand-wired chrome (`.toolbar`/`.padding`/`ScrollView` for structure); glass
   on floating chrome only; **Dynamic Type always** (no fixed-pt fonts, no fixed frames). (`05`, `06`)
7. **Swift 6.2, MainActor-by-default.** App code is main-actor-isolated by default; only the `Sendable`
   boundary and `@concurrent` off-main work are marked. Zero concurrency diagnostics. (`01 §9`)
8. **The four-layer pyramid stays green — and green build ≠ done.** Every change moves the layer that
   catches its failure mode; the coverage gate enforces it. (`07 §9`)

---

## The four quality gates (why v2 exists)

The prior app was architecturally sound but shipped slop: UI drifted from the mockups, screens were
inconsistent, the foundation was rushed, and gates measured the wrong things. Each failure has a
structural fix:

| Prior failure | Gate | Where |
|---|---|---|
| Foundation built too fast | **Foundation-freeze** — design system locked before any screen | `05 §10` |
| Screens inconsistent with each other | **Composition primitives** — every screen composes `ScreenScaffold`/`ScreenSection`/… | `06 §2`, `05 §9` |
| Mockup → Swift drift | **Fidelity-reviewer** — each screen names its mockup + is reviewed against it, then snapshot-locked | `06 §9` |
| Scaffolder slop | **Coverage gate + design-reviewer + craft criteria** — "green build ≠ done"; beauty is a reviewed bar | `07 §9`, `05 §11` |

---

## Doc index & reading order

Start at `00` → `01` → the doc your task needs. The `ios-plan-writer` reads `01`–`07` before architecting.

| Doc | Owns | Owning scaffolder |
|---|---|---|
| **`01-architecture`** | Seven-layer structure, app entry, the mental model + invariants, the UI shell/navigation shape, Swift 6.2 concurrency, the synchronized-folder + registry-as-files rules that make parallel scaffolding safe | `ios-plan-writer` (reads all) |
| **`02-models`** | Reference-model-vs-value-type rule, logic-on-the-model, enums over boolean soup, the wire/domain DTO split, `SampleData` seeding | `swift-model-scaffold` |
| **`03-store`** | `AppStore` ownership + state shape, the two-tier mutation split, optimistic write + rollback commands, hydration vs. `loadSeed`, `simulatedNow` | (store work) |
| **`04-networking`** | Provider-swappable `APIClient`, the one-file-per-endpoint `APIRequest` contract, DTO boundary, `APIError`, the **stateless** `MockProvider` + scenarios | `swift-networking-endpoint` |
| **`05-design-system`** | Three-tier **semantic** tokens + codegen, Dynamic Type, the Liquid Glass system material, modifiers/components/composition primitives, **foundation-freeze**, and the **craft criteria** | `swift-design-system` |
| **`06-screens`** | View = layout + wiring, the **UI shell** (tab/top/action bars, sheet-vs-push), presenters, routes, the catalog, previews, the **fidelity gate**, accessibility identifiers | `swift-screen-builder` |
| **`07-testing`** | The whole four-layer pyramid (unit · integration · render-snapshot **lock** · XCUITest), determinism, the coverage gate | `swift-test-writer` (+ snapshot/UI writers) |

> **Testing is one doc.** The prior app split it across `07`/`08`/`09`; v2 consolidates all four layers
> into `07-testing.md` — the `08`/`09` numbers are retired.

---

## Build & test

```
# Build only (fast — confirms a new file compiled and joined the target via synchronized folders)
xcodebuild -project ios/AppTemplate.xcodeproj -scheme AppTemplate \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4.1' \
  CODE_SIGNING_ALLOWED=NO build

# Build + test (the gated command before merge)
xcodebuild -project ios/AppTemplate.xcodeproj -scheme AppTemplate \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4.1' \
  CODE_SIGNING_ALLOWED=NO test
```

Filter with `-only-testing:AppTemplateTests/<Suite>` (or the `AppTemplateUITests` target). Unit +
integration run in seconds; render snapshots add seconds per view; UI/E2E takes minutes.

---

## Navigating Swift — SwiftLSP first

Resolve Swift symbols semantically with the **`LSP` tool** (`documentSymbol` to enter a file,
then `goToDefinition` / `findReferences` / `hover`), not `Grep`/`Read`. Reach for `Grep` only for
non-Swift files (`foundations.css`, `.pbxproj`), string literals, accessibility identifiers, or to
check whether a name is already taken. The agent dispatch guide (`.claude/agents/README.md`) and the
`ios-worktree` setup keep a warm LSP index per worktree.

---

## Adding X — where to look

| Adding… | Read | Touches (all new files except where noted) |
|---|---|---|
| a model / enum | `02` | `Models/<Name>.swift` + its `*DTO` + mapping + seed |
| an endpoint | `04` | one `Networking/Requests/<Verb><Name>Request.swift` |
| a store command | `03` | `Store/AppStore+<Feature>.swift` (new stored property edits core `AppStore.swift` — serial) |
| a token / component / composition primitive | `05` | `DesignSystem/{Tokens,Components,Composition}/…` (Foundation phase) |
| a screen | `06` | `Screens/<Name>/<Name>View.swift` (+ `Presenter`), `Routes/<Name>Route.swift`, `Catalog/CatalogSection+<X>.swift` |
| a test | `07` | the matching layer's file in `AppTemplateTests` / `AppTemplateUITests` |
