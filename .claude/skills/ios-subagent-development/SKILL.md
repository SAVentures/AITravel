---
name: ios-subagent-development
description: Use when executing an ios-plan-writer plan or building/changing any screen, component, model, or endpoint in the AppTemplate ios/ app. The main session is the COORDINATOR — it dispatches the swift-* scaffolders, enforces the phased pipeline + the four gates, runs every build, and commits. This is the default iOS execution path (there is no swift-supervisor).
---

# iOS Subagent Development — the coordinator

You (the main session) are the **coordinator**. You execute an `ios-plan-writer` plan by dispatching the
`swift-*` scaffolders, running the gates, building, and committing — all in the main loop, so the
fan-out is parallel and every dispatch + gate result stays visible. There is **no `swift-supervisor`**.
Roster, model tiers, and parallelization rules: `.claude/agents/README.md`. Conventions: the engineering
docs (`ios/docs/engineering/00-overview.md` first). Governance: root `CLAUDE.md`.

## Coordinator setup (once per branch)

1. **Worktree + warm LSP.** Run `/ios-worktree <name>` — it creates `.claude/worktrees/<name>` (branch
   `wt/<name>`), wires `buildServer.json`, and starts a background warm build. **Hold dispatch until it
   prints `BUILD SUCCEEDED`** (`tail -f <wt>/.warm-build.log`) — cold LSP is what makes scaffolders fall
   back to grep/read. All work happens in the worktree; never on `main`, never hand-edited.
2. **Read the plan** (`docs/superpowers/plans/<…>.md` from `ios-plan-writer`). Note the phase ordering,
   which tasks are disjoint (batchable) vs serial (shared-file), and each task's owning agent + Done-when.

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
the freeze passes (`foundation-freeze` skill). It's the structural fix for the prior app's rushed base.

## Dispatching scaffolders

- **Batch the sonnet scaffolders on DISJOINT files** in one message (multiple Agent calls) so they run
  in parallel — models, endpoints, and screen files are all new files (synchronized-folder rule).
- **Serialize edits to shared files** — a new stored `AppStore` property (`AppStore.swift`), a brand-new
  catalog section (`ScreenCatalogView.swift`), and any `.pbxproj` change (new SPM dep / target / bundled
  resource). Dispatch these one at a time; the plan flags them.
- **Agents carry their own model tier** (frontmatter) — don't override it. Design work is opus; mechanical
  scaffolding/tests are sonnet; reviewers are sonnet (code) / opus (design + fidelity).
- **One wave per worktree at a time.** Never double-dispatch two background agents editing the same
  worktree concurrently — interleaved writes corrupt each other. Batch *disjoint* tasks in one wave; let
  the wave finish before the next.
- Give each agent its task's **contract** (from the plan) — the interface, the exemplar to mirror, the
  Done-when. Agents don't invent; if one reports a missing token/symbol/mockup, resolve it and re-dispatch.
- **Worktree-ABSOLUTE paths, and verify every wave.** A `cd <worktree>` in the prompt is **not** enough —
  subagents' Read/Edit can resolve a bare or main-absolute path to the **main checkout** and silently
  leak edits there (this has bitten real waves). Give every file as a full
  `.claude/worktrees/<name>/…` path and tell the agent to confirm each edit landed under the worktree.
  After each wave: grep the **worktree** for the expected change **and** `git status` the **main**
  checkout (it must stay clean). If edits leaked, `cp` them into the worktree and `git checkout --`
  revert main. Re-verify after *any* agent that may run codegen/git — even a read-only reviewer once
  reverted `Primitive.generated.swift`; re-run the generator and rebuild before trusting state.

## You own every build and the index

- **Scaffolders never build.** They write code to compile against live source and report. **You** run
  `xcodebuild … build` and the gates. Keep each task's Done-when build-free so agents don't block on it.
- **Between dispatch waves, refresh the index** so the next wave's cross-file LSP lands fresh:
  `.claude/scripts/refresh-lsp-index.sh .claude/worktrees/<name>` (debounced, coalesced, backgrounded).
- **Diagnostic:** if an agent reports `findReferences`/cross-file `goToDefinition` empty while `hover`
  works, that's a **stale index** — rebuild (a plain `xcodebuild … build`); don't let it grep around it.
- **Trust the build/test gate over a contaminated read.** If an agent's report disagrees with a clean
  build, believe the build.

## The gates (run before commit)

1. **foundation-freeze** — at the Phase 0→2 boundary (above).
2. **Per screen:** `swift-code-reviewer` (concurrency, no `.shared`, semantic-tokens-only, logic-out-of-
   views, no hand-rolled chrome) **and** `fidelity-reviewer` (rendered screen vs its named mockup). Fix
   loop until both ACCEPT, then the snapshot locks it.
3. **Commit gate:** `xcodebuild … test` green across all four layers + the **ios-test-coverage-check**
   skill (every change ships its required test) + a `design-reviewer` slop pass on changed surfaces.
   "Green build ≠ done" — a missing test blocks the commit; dispatch the matching test-writer.

## Commit & finish

- Commit per phase / logical unit with conventional messages (`feat(ds): …`, `feat(screens): …`,
  `test: …`). The foundation lands as one commit; each reviewed screen as its own.
- When the branch is green and complete, use the `superpowers:finishing-a-development-branch` skill to
  choose merge / PR / cleanup.

## Reference-slice exemplars

The library/book reference slice is the worked example of every phase — mirror its shapes when building
new features (`Book`/`Library` models, `GetLibraryRequest`/`BorrowBookRequest`, `BookRow`,
`BookListView`/`BookDetailView`, and one test per layer).
