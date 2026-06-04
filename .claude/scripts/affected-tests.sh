#!/usr/bin/env bash
# affected-tests.sh — map the working-tree diff to the xcodebuild `-only-testing:` selectors
# for just the suites that change could have broken, so the coordinator runs ~1 suite, not all 31.
#
#   Usage:   .claude/scripts/affected-tests.sh [base-ref]      # base-ref defaults to HEAD
#   Output:  one `-only-testing:<TARGET/CLASS>` token per line (de-duped). Empty = nothing to test.
#
#   Compose with parallel UITests:
#     xcodebuild ... test-without-building $(.claude/scripts/affected-tests.sh | tr '\n' ' ') \
#       -parallel-testing-enabled YES -parallel-testing-worker-count 4
#
# Heuristic, not exhaustive — when a change's blast radius is unclear it errs toward INCLUDING a
# suite. Falls back to "run everything" (prints nothing + exit 2) on a structural change it can't map
# (.pbxproj, the shared AppStore, the design-system Primitive/token codegen, or DesignSnapshot.swift).
set -euo pipefail

BASE="${1:-HEAD}"
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

# changed files = committed-vs-base + unstaged + staged + untracked
files=$(
  { git diff --name-only "$BASE"; git diff --name-only; git diff --name-only --cached; \
    git ls-files --others --exclude-standard; } | sort -u
)
[ -z "$files" ] && exit 0

UI="AppTemplateUITests"
FN="AppTemplateTests"
sel=()                                   # collected -only-testing selectors
run_all_functional=0                     # any Models/Store/Networking change → whole fast bundle

# StepView/StepPresenter basename -> Onboarding<Name>UITests + the (single) presenter test file
screen_suite() {  # $1 = <Name> (e.g. When, BaseLocation)
  sel+=("-only-testing:$UI/Onboarding$1UITests")
  sel+=("-only-testing:$FN/OnboardingPresenterTests")
}

# component basename -> its snapshot class + every onboarding screen that composes it
component_fanout() {  # $1 = <Component> (e.g. FilterChip)
  local c="$1"
  sel+=("-only-testing:$FN/${c}SnapshotTests")
  # which screens use it -> their UITests (the component renders inside those flows)
  while IFS= read -r screen; do
    local name
    name=$(basename "$screen" .swift); name=${name%StepView}
    [ -f "ios/AppTemplate/Screens/Onboarding/${name}StepView.swift" ] && screen_suite "$name"
  done < <(grep -rl "\b${c}(" ios/AppTemplate/Screens/Onboarding/ 2>/dev/null || true)
}

while IFS= read -r f; do
  case "$f" in
    # ── escape hatches: blast radius too wide to map → caller should run the full pyramid ──
    *project.pbxproj|*/Store/AppStore.swift|*/DesignSystem/Tokens/Primitive.generated.swift|\
    *foundations.css|*/Support/DesignSnapshot.swift)
      echo "AFFECTED-TESTS: '$f' is a structural/shared change — run the full suite" >&2
      exit 2 ;;

    # ── onboarding screens ──
    ios/AppTemplate/Screens/Onboarding/OnboardingFlow*)
      sel+=("-only-testing:$UI/OnboardingFlowUITests"); run_all_functional=1 ;;
    ios/AppTemplate/Screens/Onboarding/*StepView.swift|ios/AppTemplate/Screens/Onboarding/*StepPresenter.swift)
      n=$(basename "$f"); n=${n%StepView.swift}; n=${n%StepPresenter.swift}; screen_suite "$n" ;;
    ios/AppTemplate/Screens/Onboarding/*Sheet.swift|ios/AppTemplate/Screens/Onboarding/*.swift)
      # other onboarding view (e.g. ManualAddressPickerSheet) — safest is the BaseLocation flow that hosts it
      sel+=("-only-testing:$UI/OnboardingBaseLocationUITests") ;;

    # ── design-system components / composition → snapshot + composing screens ──
    ios/AppTemplate/DesignSystem/Components/*.swift|ios/AppTemplate/DesignSystem/Composition/*.swift)
      component_fanout "$(basename "$f" .swift)" ;;

    # ── model / store / networking → the fast functional bundle (5s; cheap to run whole) ──
    ios/AppTemplate/Models/*.swift|ios/AppTemplate/Store/*.swift|ios/AppTemplate/Networking/*.swift)
      run_all_functional=1 ;;

    # ── a test file changed → run exactly that class ──
    ios/AppTemplateUITests/*UITests.swift)
      sel+=("-only-testing:$UI/$(basename "$f" .swift)") ;;
    ios/AppTemplateTests/*Tests.swift)
      sel+=("-only-testing:$FN/$(basename "$f" .swift)") ;;

    # ── test artifacts (committed snapshot baselines) → owned by their snapshot class, already
    #    triggered if the test file changed; a baseline-only change needs no extra selection ──
    *__Snapshots__/*|*.png) : ;;
    # ── prose / mockups / scripts → no app tests ──
    mockups/*|docs/*|*.md|.claude/*) : ;;
    *) echo "AFFECTED-TESTS: unmapped '$f' — run the full suite to be safe" >&2; exit 2 ;;
  esac
done <<< "$files"

[ "$run_all_functional" = 1 ] && sel+=("-only-testing:$FN")

printf '%s\n' "${sel[@]:-}" | sed '/^$/d' | sort -u
