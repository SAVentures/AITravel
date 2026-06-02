# Agent Dispatch Guide — AppTemplate (`ios/`)

Quick reference for the orchestrator. **Read this before dispatching.** Pairs with the engineering docs
(`ios/docs/engineering/`, start at `00-overview.md`) and the visual docs (`docs/design-docs/`, start at
`00-overview.md` → `06-judgment.md`). Governance is the root `CLAUDE.md`.

## The workflow (hard rule) — the phased pipeline

```
worktree → ios-plan-writer → Phase 0: Foundation ──[FREEZE]── → Phase 1: Models+Networking
        → Phase 2: Screens (scaffold → consistency → fidelity) → Phase 3: Tests → four-layer gate → finish-branch
```

Never code on `main`; never hand-edit Swift. **Execution lives in the main loop** via the
`ios-subagent-development` skill — you (the coordinator) dispatch the scaffolders below, batch them on
disjoint files, run the gate, and commit. There is **no `swift-supervisor`**. **The foundation-freeze is
the one hard barrier:** no `swift-screen-builder` runs until the design system is locked + design-reviewed
+ snapshot-locked.

## The roster

### Judgment / orchestration (run individually)

| Agent | Model | Task |
|-------|-------|------|
| `ios-plan-writer` | opus | Architect a **contract-level** plan from the docs — interfaces, signatures, tokens/components by name, the named mockup, a11y ids, acceptance criteria, the phase ordering. Not code bodies. |

### Mechanical scaffolders (sonnet) — batch freely on DISJOINT files

| Agent | Model | Reads | Produces |
|-------|-------|-------|----------|
| `swift-model-scaffold` | sonnet | `02-models` | a model (reference or leaf value) + its `*DTO` + `toDomain()/toDTO()` + `SampleData+<Domain>` seed |
| `swift-networking-endpoint` | sonnet | `04-networking` | one `Requests/<Verb><Name>Request.swift` (`mockResponse(from: seed)`) — no edits to the generic shells |
| `swift-test-writer` | sonnet | `07-testing §3–5` | functional tests (model methods, commands incl. rollback, DTO round-trip, presenter, codec) |
| `swift-snapshot-test-writer` | sonnet | `07-testing §6` | render-snapshot tests (the lock) |
| `swift-uitest-writer` | sonnet | `07-testing §7` | XCUITest flows vs `MockScenario` (launch-env injection, a11y audit) |

### Design scaffolders (opus — they make the visual calls)

| Agent | Model | Reads | Produces |
|-------|-------|-------|----------|
| `swift-design-system` | opus | `05-design-system` + `design-docs/` | a **semantic** token / modifier / component / composition primitive, ported from `mockups/`+`foundations.css` |
| `swift-screen-builder` | opus | `06-screens` + `design-docs/` | a screen: `…View` (ScreenScaffold + primitives) + `…Presenter` + `Route` + catalog + seeded `#Preview` + a11y ids; **names its mockup** |

### Reviewers / gates (validate, don't fix)

| Agent | Model | Validates |
|-------|-------|-----------|
| `swift-code-reviewer` | sonnet | a change vs the **engineering** docs: MainActor-default concurrency, no `.shared`, semantic-tokens-only, provider-swappability, logic-out-of-views, four-layer coverage |
| `design-reviewer` | opus | the **foundation-freeze** + per-component design vs `design-docs/`: token discipline, Dynamic Type, glass-on-chrome, the J-rules, the slop catalog |
| `fidelity-reviewer` | opus | a **screen vs its named mockup** (structure/rhythm/components/non-negotiables) before the snapshot locks it |

### Non-iOS

| Agent | Model | Task |
|-------|-------|------|
| `mockups-screen-builder` | opus | AUTHOR/AUDIT the HTML/CSS `mockups/` (the visual SSOT; `foundations.css` is the token source codegen'd to Swift). Edited directly, not through the Swift pipeline. |

## The four gates → who owns each

| Gate | Owner | When |
|------|-------|------|
| **Foundation-freeze** | `design-reviewer` signs off (design system locked, snapshot-green) | end of Phase 0, before any screen |
| **Composition primitives** | `swift-screen-builder` composes them; `swift-code-reviewer` checks no hand-rolled chrome/layout | every screen |
| **Fidelity** | `fidelity-reviewer` (screen vs named mockup) → then `swift-snapshot-test-writer` locks it | every screen |
| **Coverage / anti-slop** | `swift-code-reviewer` + `design-reviewer` (slop scan) + the `ios-test-coverage-check` skill | the commit gate ("green build ≠ done") |

**Which reviewer when:** `design-reviewer` for the design system + foundation-freeze (visual rules, slop);
`fidelity-reviewer` per screen (matches its mockup); `swift-code-reviewer` for any Swift change
(concurrency, conventions, coverage, doc-conformance).

## Parallelization & shared-file serialization

- **Batch the sonnet scaffolders on DISJOINT files** — models, endpoints, and screen files are new files
  (synchronized-folder rule, `01-architecture §11`), so they don't collide on `.pbxproj`.
- **Serialize edits to shared files:** a new stored `AppStore` property (`AppStore.swift`), a brand-new
  catalog section (`ScreenCatalogView.swift`), and any `.pbxproj` change (new SPM dep / target / bundled
  resource). Plan-writer flags these; dispatch them one at a time.

## Navigating code — SwiftLSP first

Use the **`LSP` tool** for Swift symbols, not `Grep`/`Read`. **Entry point: `documentSymbol <file>`**
(line 1, char 1) returns the file's member tree with line numbers — then `goToDefinition` /
`findReferences` / `hover` from those lines. `Grep` is correct for: checking a name isn't taken yet,
string literals / accessibility identifiers, non-Swift files (`foundations.css`, `.pbxproj`), or one shot
to locate an anchor. **SwiftLSP needs a build server + a warm index, per worktree** — the `ios-worktree`
command sets both up. **Diagnostic:** if `findReferences` / cross-file `goToDefinition` come back empty
but `hover` works, that's a **stale index** — the coordinator rebuilds (a plain `xcodebuild … build`);
scaffolders report it, they don't grep around it.
