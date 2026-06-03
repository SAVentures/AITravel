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

---

## 2026-06-02 — Onboarding W1-09: SOLID action floor — exception to "glass on floating chrome only" (J-0.1)

**Decision.** The immersive onboarding flow gets a new composition primitive,
`OnboardingActionFloor` (`DesignSystem/Composition/OnboardingActionFloor.swift`), that is a **SOLID**
bottom action floor — an opaque `ColorRole.surfacePage` ground with a top hairline `ColorRole.separator`,
holding a full-width `PillButton(.primary)` CTA over an optional `PillButton(.ghost)`. It deliberately
does **not** use the system Liquid Glass material (`glassEffect` / `.buttonStyle(.glass)` /
`GlassEffectContainer`). This is a considered **exception** to the non-negotiable "glass on floating
chrome only" (J-0.1, visual non-negotiable #1): the floating chrome here is opaque, not glass.

**Why.** The visual non-negotiable mandates the Liquid Glass material *when* floating chrome is glass;
the glass `ActionBar` is and remains the default for non-immersive screens. But the onboarding mockup
floor (`screen-shell.css` `.ob-action` — "config floor is solid", 07-nav §8) is explicitly an **opaque
paper floor**, not a frosted bar. An immersive takeover (onboarding, reader, capture) wants a calm,
opaque base under its CTA — a translucency sampling the content scrolling behind it would read as busy and
undercut the takeover. The two primitives also have different button vocabulary (`ActionBar`: prominent +
glass-secondary grouped in a `GlassEffectContainer`; the floor: solid primary + ghost stacked). Forking
`ActionBar` with a `.solid` style would muddy the one glass primitive's contract, so the solid floor is a
**separate primitive** (per onboarding plan OPEN DECISION 1, confirmed). A solid floor also avoids
glass-on-content (forbidden by J-0.1) for the content that scrolls under it. Note: the mockup's
`linear-gradient(transparent → paper-0)` fade is rendered as a **solid** `surfacePage` fill (gradients as
fills are slop, J-2.4 / 08-slop); the accent appears only via the `PillButton(.primary)` role, never a
fill we paint, and there is exactly one primary (J-6.1).

**Scope / supersede when.** This exception is scoped to the immersive onboarding config floor only. Any
new floating chrome that is *not* an immersive config floor uses the glass `ActionBar` (the default). If a
future immersive flow needs the same solid floor, it reuses `OnboardingActionFloor` rather than minting a
second solid bar. Revisit if Liquid Glass gains an opaque/solid variant that reads the same.

---

## 2026-06-03 — Onboarding W1: component-local opacity finish constants (no opacity ramp)

**Decision.** A handful of opacity *finish* values in the new onboarding components — the locked
trip-shape card (`0.55`), the base-map home-ring halo (`0.10`), the generation sweep at-rest bar
(`0.4`), and the handoff-peek card (`0.5`) — are kept as **named, mockup-cited component-local
constants**, NOT as `foundations.css` opacity tokens.

**Why.** Each ports a one-off `opacity:` declaration from its mockup selector, and they don't form a
ladder. A global `--opacity-*` ramp would be a junk-drawer token (08-slop). The selection-ring *width*
is different — it recurs across selectable cards — so that one WAS tokenized (`--stroke-selected: 2px`
→ `Primitive.strokeSelected` → `Stroke.selected`). Opacity finish values stay component-local until a
second component proves a shared ramp is warranted.

---

## 2026-06-03 — Onboarding: action floor is now FLOATING Liquid Glass — SUPERSEDES the W1-09 solid-floor exception

**Decision.** Per user direction, `OnboardingActionFloor`
(`DesignSystem/Composition/OnboardingActionFloor.swift`) is rewritten to be a **FLOATING** action floor
using the **system Liquid Glass material**, not a solid floor. The primary CTA is the system
`.buttonStyle(.glassProminent)` (`.tint(ColorRole.actionPrimary)`, `.controlSize(.large)`,
`.buttonBorderShape(.capsule)`); the optional second action is the lesser `.buttonStyle(.glass)` ghost.
Both are grouped in one `GlassEffectContainer` so they blend as a single piece of chrome (no glass-on-glass,
J-8.3). There is **no** opaque `surfacePage` floor, **no** top hairline, and **no** hand-rolled
translucency — the action floats over the scrolling content. The public init API is unchanged
(`primaryTitle` / `primaryEnabled` / `primaryAccessibilityID` / `ghostTitle` / `ghostAccessibilityID` /
`ghostAction` / `primaryAction`), so the step-view call sites are untouched.

**This SUPERSEDES the earlier decision "2026-06-02 — Onboarding W1-09: SOLID action floor — exception to
'glass on floating chrome only' (J-0.1)".** That exception (an opaque paper floor + hairline holding a
`PillButton(.primary)` / `.ghost`) is no longer in effect. Glass-on-floating-chrome (J-0.1, visual
non-negotiable #1) now applies **normally** to the onboarding CTA — the onboarding action floor is the
default floating-glass pattern, exactly like `ActionBar`, just with a primary-over-ghost vocabulary. No
J-0.1 carve-out remains for the onboarding floor.

**Related.** The sticky GLASS `OnboardingProgressHeader` was split at the same time: the progress
(counter + 5 neutral segments) became the in-content `OnboardingProgressBar` component, and the leading
× / back became a separate floating `GlassCircleButton` the screens overlay (driven by `LeadingGlyph`).
