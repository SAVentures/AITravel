#!/usr/bin/env bash
#
# ios-worktree-warm.sh — create (or reuse) an iOS dev worktree under
# .claude/worktrees/<name> and warm its sourcekit-lsp index with a background
# build, so the swift-* scaffolders get fast, resolving LSP from their first
# call instead of falling back to grep/read.
#
# WHY A BUILD, NOT AN INDEX COPY: sourcekit-lsp resolves a file's symbols only
# from IndexStore *units* that were built against that file's absolute path. A
# worktree lives at a different absolute path than the main checkout and gets
# its own DerivedData index store, so copying the main checkout's index would
# leave every goToDefinition / findReferences on the worktree's files
# UNRESOLVED — the units all point at the main checkout's paths. The only thing
# that produces resolvable units for a worktree is a build whose SRCROOT is the
# worktree. The Swift/clang module caches are shared globally, so this build is
# far cheaper than a cold-machine build.
#
# Usage: ios-worktree-warm.sh <name> [base-ref]
#   <name>      worktree dir + branch  (.claude/worktrees/<name>, branch wt/<name>)
#   [base-ref]  commit/branch to fork from (default: main checkout's HEAD)
set -euo pipefail

NAME="${1:?usage: ios-worktree-warm.sh <name> [base-ref]}"

# Always operate from the MAIN working tree (the first entry of `worktree list`
# is always the main checkout, even when invoked from a linked worktree).
MAIN="$(git worktree list --porcelain | awk '/^worktree /{print $2; exit}')"
cd "$MAIN"

BASE_REF="${2:-HEAD}"
WT="${MAIN}/.claude/worktrees/${NAME}"
BRANCH="wt/${NAME}"
DEST='platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4.1'

if [ -d "$WT" ]; then
  echo "↻ reusing existing worktree: $WT"
else
  mkdir -p "${MAIN}/.claude/worktrees"
  if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
    git worktree add "$WT" "$BRANCH"
  else
    git worktree add "$WT" -b "$BRANCH" "$BASE_REF"
  fi
  echo "✔ created worktree: $WT  (branch $BRANCH from ${BASE_REF})"
fi

PROJ="${WT}/ios/AppTemplate.xcodeproj"
[ -d "$PROJ" ] || { echo "✘ $PROJ not found — is this the AppTemplate iOS repo?" >&2; exit 1; }

# Point sourcekit-lsp at THIS worktree's index store. Without a build server
# sourcekit-lsp runs in fallback single-file mode: hover + within-file nav work,
# but findReferences / workspaceSymbol / cross-file goToDefinition return nothing
# (it never reads the Xcode index store). buildServer.json is per-checkout — it
# embeds the worktree's absolute workspace path + DerivedData hash — so generate
# it inside the worktree, not by copying the main checkout's.
if command -v xcode-build-server >/dev/null 2>&1; then
  ( cd "$WT" && xcode-build-server config -project ios/AppTemplate.xcodeproj -scheme AppTemplate >/dev/null 2>&1 ) \
    && echo "✔ buildServer.json → worktree index store (cross-file LSP enabled)" \
    || echo "⚠ xcode-build-server config failed — LSP will be fallback-only"
else
  echo "⚠ xcode-build-server not installed (brew install xcode-build-server) — cross-file LSP (findReferences/workspaceSymbol) will not resolve; only hover + within-file nav."
fi

LOG="${WT}/.warm-build.log"
echo "⟳ warming sourcekit-lsp index (background build → ${LOG}) …"
# Default DerivedData on purpose: sourcekit-lsp reads the default index store
# keyed by the worktree's project path. Do NOT pass -derivedDataPath here.
nohup xcodebuild -project "$PROJ" -scheme AppTemplate \
  -destination "$DEST" CODE_SIGNING_ALLOWED=NO build >"$LOG" 2>&1 &
echo "  build pid $! — LSP stays cold until this finishes (first build of this worktree)."
echo
echo "Next:"
echo "  cd \"$WT\""
echo "  tail -f \"$LOG\"      # watch the warm build; 'BUILD SUCCEEDED' = LSP warm"
echo "  # then architect with ios-plan-writer and execute via ios-subagent-development"
