# Decisions log

Append-only. New entries supersede; never edit old ones. Each records a non-obvious call and why.

---

## 2026-06-02 — Phase 0 foundation: defer the continuous now-state pulse (OD-2)

**Decision.** The design-system foundation builds the now-state indicator (timeline dot `TimelineRow`,
`MapPin`) as a **static** ring/mark. The continuous pulse animation (`OneShotPulse` modifier, plan task
B3) is **deferred** to the screen that first presents a live now-state.

**Why.** A continuous motion needs a screen to own it — J-9.3 budgets ≤ 1 continuous motion *per
screen*, and 04-motion §4 wants continuous motion anchored to context. A frozen design-system foundation
has no screen to anchor a loop, so baking a pulse into a component would create an unowned continuous
animation that every future screen inherits whether it wants it or not. Building the now-state as a
static cue now keeps the foundation honest; the pulse is added (and budgeted) at the screen that needs
it. `OneShotPulse.swift` is intentionally not created in Phase 0.

**Supersede when.** The first screen presenting a live "now" state adds `OneShotPulse` (respecting
`accessibilityReduceMotion` + the `disablesOneShotMotion` snapshot seam, 07-testing §6.4) and wires the
timeline/pin now-state to it.
