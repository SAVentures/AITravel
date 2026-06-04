#!/usr/bin/env bash
# a11y-ownership-lint.sh — the Track-B regression gate. Stops the a11y-ownership failure
# modes from recurring. Run from repo root (or anywhere); exits non-zero on a violation.
#
# Designed for ZERO false positives (a noisy gate gets disabled). It deliberately does NOT
# flag a component owning its own stable id (e.g. daystepper.decrement, onboarding.progress) —
# that IS the principle. It flags only the precise foot-guns:
#
#   A  empty-id `?? ""`         a nil id stamped as a blank "" id (the audit then flags it).
#   B  double-mechanism         a component that exposes an accessibilityID/Label PASSTHROUGH
#                               param AND ALSO bakes a CONSTANT literal id (the SearchWell-original
#                               bug: caller can't own the id because the component hard-codes it).
#                               Interpolated ids built from a caller prefix ("\(prefix).\(id)") are
#                               fine; a component's own internal sub-control id marked
#                               `// a11y-lint:own-subcontrol` is allowed.
#   C  blanket audit suppress   an unguarded `return true` in a performAccessibilityAudit handler
#                               (every suppression must be auditType/identifier-scoped, §7.4).
#
# NOT auto-linted (kept as ios-test-coverage-check review items — too dynamic to lint without a parser):
#   • declared-vs-queried id cross-reference (enum/prefix-derived ids defeat a static grep)
#   • value/label assertion requirement (an element with accessibilityValue must be value-asserted)
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"; cd "$ROOT"
APP=ios/AppTemplate; DS="$APP/DesignSystem"; UITESTS=ios/AppTemplateUITests
fail=0

echo "── A  empty-id foot-gun ───────────────────────────────────────"
emptyid=$(grep -rnE '\.accessibilityIdentifier\([^)]*\?\?[[:space:]]*""' "$DS" "$APP/Screens" 2>/dev/null || true)
if [ -n "$emptyid" ]; then
  echo "✘ \`?? \"\"\` stamps a blank id the .elementDetection audit flags:"; echo "$emptyid" | sed 's/^/    /'
  echo "    → use .accessibilityIdentifier(ifPresent:) so a nil id attaches NO modifier"; fail=1
else echo "✔ no \`?? \"\"\` empty-id stamping"; fi

echo "── B  component passthrough + baked-constant double-mechanism ──"
# a component that takes an id/label passthrough must not ALSO bake a CONSTANT literal id.
viol=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  grep -qE '(accessibilityID|accessibilityLabel)[^.]*:[[:space:]]*String' "$f" || continue   # has a passthrough param
  # constant-literal ids (no \( interpolation), not marked as an internal sub-control
  baked=$(grep -nE '\.accessibilityIdentifier\("[^"\\]*"\)' "$f" | grep -v 'a11y-lint:own-subcontrol' || true)
  [ -n "$baked" ] && viol="$viol$f:\n$baked\n"
done < <(find "$DS/Components" "$DS/Composition" -name '*.swift' 2>/dev/null)
if [ -n "$viol" ]; then
  echo "✘ component exposes an id/label passthrough yet bakes a constant id (caller can't own it):"
  printf "$viol" | sed 's/^/    /'
  echo "    → drop the baked constant + apply the passthrough; mark a genuine internal sub-control id"
  echo "      with // a11y-lint:own-subcontrol"; fail=1
else echo "✔ no passthrough+baked-constant double-mechanism"; fi

echo "── C  audit suppression discipline ────────────────────────────"
# unguarded `return true` in a UITest audit handler — strip line comments, ignore guarded/delegated lines.
bare=$(grep -rn 'return true' "$UITESTS" 2>/dev/null | while IFS=: read -r f l rest; do
  code="${rest%%//*}"                                              # drop any trailing // comment
  echo "$code" | grep -q 'return true' || continue                # the `return true` was inside a comment
  echo "$code" | grep -qE 'auditType|identifier|extraSuppressions' && continue   # guarded / delegated
  echo "$f:$l:$(echo "$rest" | sed 's/^[[:space:]]*//')"
done)
if [ -n "$bare" ]; then
  echo "✘ unguarded \`return true\` in a performAccessibilityAudit handler (blanket suppress):"; echo "$bare" | sed 's/^/    /'
  echo "    → guard with \$0.auditType == … (+ element id); whole-type suppressions must name a live"
  echo "      compensating check in-comment (§7.4)"; fail=1
else echo "✔ no unguarded audit suppressions"; fi

echo "───────────────────────────────────────────────────────────────"
[ "$fail" = 0 ] && echo "a11y-ownership-lint: PASS" || echo "a11y-ownership-lint: FAIL"
exit $fail
