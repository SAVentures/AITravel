---
description: Create (or reuse) an iOS dev worktree under .claude/worktrees/ and warm its sourcekit-lsp index with a background build, so swift-* scaffolders get resolving LSP from their first call.
argument-hint: <name> [base-ref]
allowed-tools: Bash(.claude/scripts/ios-worktree-warm.sh:*), Bash(git worktree:*), Bash(tail:*)
---

Set up an isolated iOS worktree with a pre-warmed sourcekit-lsp index.

1. Run the script: `.claude/scripts/ios-worktree-warm.sh $ARGUMENTS`
   It creates `.claude/worktrees/<name>` on branch `wt/<name>` (forked from the main checkout's HEAD
   unless a base-ref is given) and kicks off a **background** `xcodebuild build` in that worktree. The
   script returns immediately; the build keeps running detached.
2. Report to the user: the worktree path, the branch, and that sourcekit-lsp is cold until the
   background build prints `BUILD SUCCEEDED` in `<worktree>/.warm-build.log`. Hold off dispatching
   `swift-*` scaffolders into the worktree until then (cold LSP is exactly what makes them fall back to
   grep/read).

**Why a build and not an index copy:** sourcekit-lsp resolves a worktree's files only from IndexStore
units built against that worktree's absolute paths. Copying the main checkout's index leaves every
`goToDefinition`/`findReferences` on the worktree unresolved. The background build is what produces
resolvable units; the global Swift/clang module cache keeps it far cheaper than a cold build.

**⚠️ Each worktree builds into its OWN DerivedData — never `find … | head -1`.** A git worktree compiles
to a *distinct* `~/Library/Developer/Xcode/DerivedData/AppTemplate-<hash>` keyed by its absolute path, so
the main checkout and every worktree have separate build products. To install / launch / screenshot the
app you just built **in this worktree**, resolve the real path — never grab "the first AppTemplate-* dir":

```
BUILT=$(xcodebuild -project ios/AppTemplate.xcodeproj -scheme AppTemplate \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4.1' \
  -showBuildSettings 2>/dev/null | awk '/ BUILT_PRODUCTS_DIR =/{print $3; exit}')
# → "$BUILT/AppTemplate.app"  (this worktree's binary, not a stale Phase-0 build)
```

`find … DerivedData/AppTemplate-* | head -1` silently returns the **stale main-checkout build** — you'll
install a months-old binary and chase phantom "it didn't change" bugs through every rebuild cycle. Always
resolve `BUILT_PRODUCTS_DIR` (or pass `-derivedDataPath` to pin it). See `ios-subagent-development`
(coordinator setup) for the same rule in the run/verify step.

**Then** follow the hard workflow rule: worktree → `ios-plan-writer` (architect) →
`ios-subagent-development` (coordinate execution, with the foundation-freeze barrier) → finish-branch.
Never hand-edit `ios/` Swift in the worktree.
