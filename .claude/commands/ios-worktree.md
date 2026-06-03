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

**Each worktree builds into its own DerivedData** (`AppTemplate-<hash>`, keyed by absolute path), so to
install/screenshot the binary you just built here, resolve the real path — `find … | head -1` returns a
sibling worktree's stale build:

```
BUILT=$(xcodebuild -project ios/AppTemplate.xcodeproj -scheme AppTemplate \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4.1' \
  -showBuildSettings -json 2>/dev/null | /usr/bin/python3 -c 'import json,sys;print(json.load(sys.stdin)[0]["buildSettings"]["BUILT_PRODUCTS_DIR"])')
```

**Then** follow the hard workflow rule: worktree → `ios-plan-writer` (architect) →
`ios-subagent-development` (coordinate execution, with the foundation-freeze barrier) → finish-branch.
Never hand-edit `ios/` Swift in the worktree.
