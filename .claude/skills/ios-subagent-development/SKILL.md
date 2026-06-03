---
name: ios-subagent-development
description: Use when executing an ios-plan-writer plan or building/changing any screen, component, model, or endpoint in the AppTemplate ios/ app. The main session is the COORDINATOR — it dispatches the swift-* scaffolders, enforces the phased pipeline + the four gates, runs every build, and commits. This is the default iOS execution path (there is no swift-supervisor).
---

# iOS Subagent Development — the coordinator

You (the main session) are the **coordinator**. You execute an `ios-plan-writer` plan by dispatching the
`swift-*` scaffolders, running the gates, building, and committing — all in the main loop, so the
fan-out is parallel and every dispatch + gate result stays visible. There is **no `swift-supervisor`**.

**Required background:** load `superpowers:subagent-driven-development` first — it owns the core loop
(fresh subagent per task, two-stage spec→quality review, status handling); this skill only adds the iOS
overrides. Roster + parallelization: `.claude/agents/README.md`. Conventions: the engineering docs
(`ios/docs/engineering/00-overview.md` first). Governance: root `CLAUDE.md`.

## When this fits vs. when it doesn't

For executing an **implementation plan** (from `ios-plan-writer`, in `docs/plans/`) with mostly-independent
tasks. No plan yet? Architect one first, in a worktree. A single trivial one-file edit may not need the
full fan-out — dispatch one scaffolder and run the gate. The hard rule (root `CLAUDE.md`) holds:
**worktree → `ios-plan-writer` → this skill → finish-branch. Never code on `main`; never hand-edit `ios/`
Swift yourself** — that's the scaffolders' job.

## The phased execution (hard order)

```
Phase 0  Foundation      swift-design-system ×N (tokens via codegen → semantic → modifiers →
                         components → composition primitives)
         ──[FREEZE]──     run the foundation-freeze skill (design-reviewer FREEZE-READY + snapshots green)
Phase 1  Models+Net      swift-model-scaffold ×N · swift-networking-endpoint ×N   (batch — disjoint)
Phase 2  Screens         per screen: swift-screen-builder → swift-code-reviewer (consistency) →
                         fidelity-reviewer (vs named mockup) → fix loop
Phase 3  Tests           swift-test-writer · swift-snapshot-test-writer · swift-uitest-writer
         Gate            build clean + ios-test-coverage-check + design-reviewer (slop) + swift-code-reviewer
         Commit → finish-branch
```

**The foundation-freeze is the one hard barrier:** do **not** dispatch any `swift-screen-builder` until
the freeze passes (`foundation-freeze` skill). It is the structural fix for the prior app's rushed base.
The freeze also checks the token model is **complete** — every value-kind has a home, including component
**dimensions** (`Grid.x(n)` via `Sizing`), not just gaps/color/type (`05-design-system.md §10.1`). A model
that can't size a component without inventing a primitive is not frozen-ready.

## Agent dispatch table

Existing agents in `.claude/agents/` — you orchestrate them; you don't reimplement them. **Each agent
carries its own model tier in frontmatter — don't override it** (design = opus; scaffolding/tests =
sonnet; reviewers = sonnet code / opus design + fidelity).

**Judgment — run individually** (they explore broadly; parallel runs waste context):

| Task type | Agent |
|-----------|-------|
| Architect a **contract-level** plan from the docs — interfaces, signatures, tokens/components by name, a11y ids, exemplars, acceptance criteria; **not code bodies** | `ios-plan-writer` |
| Validate a change before commit — docs/port fidelity, Swift concurrency, four-layer coverage | `swift-code-reviewer` |
| Design-review (semantic-tokens-only, J-rules, slop) · fidelity vs the named mockup | `design-reviewer` · `fidelity-reviewer` |

**Scaffolders — batch freely in parallel ON DISJOINT FILES:**

| Task type | Agent | Reads |
|-----------|-------|-------|
| New model/enum + `SampleData` seed | `swift-model-scaffold` | `02-models.md` |
| One API call (an `APIRequest` file; providers stay generic) | `swift-networking-endpoint` | `04-networking.md` |
| New/changed token, modifier, or component (ported from `mockups/`) | `swift-design-system` | `05-design-system.md` + design-docs |
| New screen (View + Route + catalog reg + `#Preview` + a11y ids) | `swift-screen-builder` | `06-screens.md` + design-docs |
| Functional tests (Swift Testing) | `swift-test-writer` | `07-testing.md` |
| Render-snapshot tests | `swift-snapshot-test-writer` | `07-testing.md §6` + design-docs |
| XCUITest flows vs `MockProvider` scenarios | `swift-uitest-writer` | `07-testing.md §7` + design-docs |

> Tokens are **not** parity-tested — they're codegen'd from `foundations.css` and locked by render
> snapshots (`05 §2`, `07 §6`). There is no `swift-supervisor`; coordinate here, in the main loop.

## Coordinator setup (once per branch)

1. **Worktree + warm LSP.** Run `/ios-worktree <name>` — it creates `.claude/worktrees/<name>` (branch
   `wt/<name>`), wires `buildServer.json`, and starts a background warm build. **Hold dispatch until it
   prints `BUILD SUCCEEDED`** (`tail -f <wt>/.warm-build.log`) — cold LSP is what makes scaffolders fall
   back to grep/read. All work happens in the worktree; never on `main`, never hand-edited.
   - **Why `buildServer.json`:** sourcekit-lsp has **no native `.xcodeproj` understanding**; without it,
     `hover` + within-file `goToDefinition` work but **`findReferences` / `workspaceSymbol` / cross-file
     `goToDefinition` silently return nothing** (`xcode-build-server config`; `brew install xcode-build-server`).
   - **Why a warm build:** cross-file LSP resolves from a **built index store**
     (`DerivedData/<proj>/Index.noindex`), per-worktree.
   - By hand instead of `/ios-worktree`:
     ```
     xcode-build-server config -project ios/AppTemplate.xcodeproj -scheme AppTemplate
     xcodebuild -project ios/AppTemplate.xcodeproj -scheme AppTemplate \
       -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4.1' CODE_SIGNING_ALLOWED=NO build   # background
     ```
2. **Read the plan** (`docs/plans/<…>.md`). Note the phase ordering, which tasks are disjoint (batchable)
   vs serial (shared-file), and each task's owning agent + Done-when.

**Two LSP-empty failure modes** (cross-file empty while `hover` works): **stale index** (common, after
edits/rebases) → a plain `xcodebuild … build` (sourcekit-lsp absorbs the fresh units, no restart); or
**`buildServer.json` not read** (generated *after* the LSP server started this session) → a fresh session
(don't `pkill sourcekit-lsp` — it wedges the LSP tool for the session).

**Each worktree builds into its own `DerivedData/AppTemplate-<hash>`** (keyed by absolute path). To
install/screenshot the binary you built here, resolve `BUILT_PRODUCTS_DIR` via
`xcodebuild … -showBuildSettings -json` — `find …/DerivedData/AppTemplate-* | head -1` silently returns a
sibling worktree's stale build.

## Context to provide each subagent

Agents read their own doc (and the relevant design-docs) first — don't re-paste it. Pass only the
specific rule that applies, plus:

- the exact task from the plan (type/view name, fields, the behaviour spec);
- **the exemplar to mirror** (`path → symbol`) and the task's **Done-when** — that's how it writes the body and self-checks;
- concrete file paths to **read**, **write**, and **never touch**;
- outputs from prior agents this one depends on (a type name, a token name, an `APIRequest` name, a11y ids);
- which screen/feature/domain this is for, and the one design-doc rule that governs it (e.g. "glass on floating chrome only", "tokens, never literals");
- **worktree-ABSOLUTE paths** for every file (see Dispatching, below).

## Dispatching scaffolders

- **Batch the sonnet scaffolders on DISJOINT files** in one message (multiple Agent calls) so they run
  in parallel — a new model, endpoint, screen, or route is a new file (synchronized-folder rule), so they
  never touch the project file or each other.
- **Serialize edits to shared files** — a new stored `AppStore` property (`AppStore.swift`), a brand-new
  catalog section (`ScreenCatalogView.swift`), and any `.pbxproj` change (new SPM dep / target / bundled
  resource). One at a time; the plan flags them.
- **One wave per worktree at a time.** Never double-dispatch two background agents editing the same
  worktree concurrently — interleaved writes corrupt each other. Let a wave finish before the next.
- Give each agent its task's **contract** (from the plan). Agents don't invent; if one reports a missing
  token/symbol/mockup, resolve it and re-dispatch.
- **Worktree-ABSOLUTE paths, and verify every wave.** A `cd <worktree>` in the prompt is **not** enough —
  subagents' Read/Edit can resolve a bare or main-absolute path to the **main checkout** and silently leak
  edits there (this has bitten real waves). Give every file as a full `.claude/worktrees/<name>/…` path
  and tell the agent to confirm each edit landed under the worktree. **After each wave:** grep the
  **worktree** for the expected change **and** `git status` the **main** checkout (it must stay clean). If
  edits leaked, `cp` them into the worktree and `git checkout --` revert main. Re-verify after *any* agent
  that may run codegen/git — even a read-only reviewer once reverted `Primitive.generated.swift`; re-run
  the generator and rebuild before trusting state.
- Before batching, list every file each agent will write and confirm zero overlap.

## You own every build and the index

- **Scaffolders never build.** They write code to compile against live source and report. **You** run
  `xcodebuild … build` and the gates. Keep each task's Done-when build-free so agents don't block on it.
- **Per task (fast feedback):** build, plus the functional suite if the task changed logic — once after a
  parallel wave lands (not once per agent), reusing the warm index.
- **Between waves, refresh the index** so the next wave's cross-file LSP lands fresh:
  `.claude/scripts/refresh-lsp-index.sh .claude/worktrees/<name>` (debounced, coalesced, backgrounded —
  pass the explicit worktree path).
- **Diagnostic:** an agent reporting `findReferences`/cross-file `goToDefinition` empty while `hover` works
  = a **stale index** → rebuild (a plain `xcodebuild … build`); don't accept a grep-around-it result.
- **Trust the build/test gate over a contaminated read.** If an agent's report disagrees with a clean
  build, believe the build.

## The gates (run in order before commit; stop and fix on first failure)

1. **foundation-freeze** — at the Phase 0→2 boundary (above): design-reviewer FREEZE-READY, snapshots
   green, and the token model **complete** (`05 §10.1`).
2. **Per screen:** `swift-code-reviewer` (concurrency, no `.shared`, semantic-tokens-only, logic-out-of-
   views, no hand-rolled chrome) **and** `fidelity-reviewer` (rendered screen vs its named mockup). Fix
   loop until both ACCEPT; then the render snapshot locks it.
3. **Commit gate:** `xcodebuild … build` → **functional** (Swift Testing, when `Models/`/`Store/`/
   `Networking/` changed) → **render snapshots** (when a `DesignSystem/` component or `Screens/` screen
   changed; an intended visual change is **explicitly** re-recorded, never silently) → **XCUITest +
   `performAccessibilityAudit()`** (when a screen/flow changed, across its `MockProvider` scenarios) →
   the **`ios-test-coverage-check`** skill (refuses the commit if a required test is missing) → a
   `design-reviewer` slop pass on changed surfaces. **"Green build ≠ done."**

**If a layer fails:** re-dispatch the matching test-writer or reviewer with the **exact failure output**
(use SwiftLSP to pin the named symbol + callers). Never retry unchanged; never hand-patch generated code.

## Commit & finish

Commit per logical unit (Conventional Commits — `feat`/`fix`/`refactor`/`test`/`chore`, lowercase
single-word scope, imperative subject < 72 chars). The foundation lands as one commit; each reviewed
screen as its own. When the branch is green and complete, use
`superpowers:finishing-a-development-branch` to choose merge / PR / cleanup.

## Reference-slice exemplars

The library/book reference slice is the worked example of every phase — mirror its shapes when building
new features (`Book`/`Library` models, `GetLibraryRequest`/`BorrowBookRequest`, `BookRow`,
`BookListView`/`BookDetailView`, and one test per layer).

## Common mistakes

| Mistake | Fix |
|---------|-----|
| Delegate everything to a "supervisor" | There is none — coordinate in the main loop; that's the point of this skill |
| Grep/Read to navigate Swift | SwiftLSP first; Grep only for CSS / `.pbxproj` / string literals / a11y ids |
| Run the full XCUITest pyramid after every task | Per task: build (+functional if logic changed). Full pyramid once, pre-commit |
| Two parallel agents on `AppStore.swift` or `ScreenCatalogView.swift` | Serialize shared-file edits |
| Append to a "registry" instead of a new file | A new endpoint/screen/model/route is a NEW file |
| Hand-patch a scaffolder's output when the gate fails | Re-dispatch the agent with the exact failure; don't pollute your context |
| Run tests before build | Build first — test output is noise if it won't compile |
| Skip the `ios-test-coverage-check` skill | It's the commit gate; not optional |
| Edits leak to `main` ("but I `cd`'d") | `cd` isn't enough — give **worktree-absolute** paths + verify each wave (grep the worktree, `git status` main); revert leaks |
| Paste a full engineering doc into a subagent prompt | Agents read their own doc; pass only the one rule that applies |
| `find … DerivedData/AppTemplate-* \| head -1` to grab the build | Each worktree has its OWN DerivedData; resolve `BUILT_PRODUCTS_DIR` via `-showBuildSettings` |
| Treat "build green + snapshot recorded" as "the screen works" | Snapshots prove *appearance*, not *wiring*. Get a **live run + screenshot per screen, early** — dead pills / read-only stubs / grey-vs-white only show on a real tap. XCUITest is the durable version. |
| Freeze a foundation that only has gaps/color/type | The token model must be **complete** — dimensions via `Grid`/`Sizing` too (`05 §10.1`), or a screen hits a wall mid-build |
