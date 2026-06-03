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

---

## 2026-06-03 — Onboarding: accessibility-audit suppressions are per-element + per-audit-type (two, both narrow)

**Decision.** `OnboardingDestinationUITests.testAccessibilityAudit` (and the other onboarding-screen audits
that share the pattern) suppress exactly **two** `performAccessibilityAudit` issues, each scoped to one
element id AND one `auditType` — never a blanket `return true`:

1. `onboarding.close` + `.contrast` — the floating `GlassCircleButton` (× / back) is system Liquid Glass
   over variable scroll content; WCAG-AA contrast can't be guaranteed at all background values (J-0.1).
2. `onboarding.progress` + `.hitRegion` — the `OnboardingProgressBar` is **informational, not interactive**:
   4pt-tall neutral segments + a step counter (mockup `.ob-seg`), exposed as one focusable VoiceOver
   element with the value "Step N of M". The `.hitRegion` audit's 44pt floor is for **interaction**
   targets; a thin informational indicator that is merely VoiceOver-focusable legitimately sits below it.

**Why not "fix" the progress bar.** Padding it to a 44pt hit area would (a) break mockup fidelity (the
indicator is deliberately a thin 4pt bar) and (b) be wrong — it has no action to hit. The audit flags it
only because an informational element that carries an `accessibilityValue` is reported as focusable, and the
size check doesn't distinguish informational-focusable from interactive. Removing the value would silence
the audit but cost VoiceOver users the step readout. So the element stays correct and the audit is
suppressed for that one (element, type) pair.

**Rule for future screens.** An audit suppression is always `id == "<specific>" && auditType == .<specific>`.
A suppression that omits either half — or that returns `true` for a whole audit type across all elements —
is a defect, not an exemption. New exemptions get a line here.

---

## 2026-06-03 — Onboarding: the destination audit is PROVISIONALLY type-scoped (REFINES the entry above; policy deferred to task #10)

**Decision.** `OnboardingDestinationUITests.testAccessibilityAudit` runs
`performAccessibilityAudit(for: [.elementDetection, .sufficientElementDescription, .trait, .hitRegion])`
— it **excludes** `.contrast`, `.dynamicType`, and `.textClipped` — rather than running the full audit and
suppressing per element. This **refines** the same-date entry above ("per-element + per-type, never
whole-type") for the specific case where a whole audit *type* produces only false positives on a custom
design system.

**Why.** The full audit surfaced **26 issues on the destination screen, all false positives** (diagnosed by
logging every issue):
- `.contrast` (×16) fires on elements that definitionally pass — the system `.glassProminent` CTA (white on
  system blue) and dark-ink city names (ink-700 on white ≈ 4.8:1). The contrast audit pixel-samples and
  mis-resolves backgrounds over glass / scroll content / the OKLCH ramp.
- `.dynamicType` (×9) fires on the custom (`Font.custom(size:relativeTo:)`) and system-mono text. That text
  **does** scale to AX5 — every `Typography` role binds a Dynamic Type style (verified, zero `fixedSize`).
  The audit reads UIKit's `adjustsFontForContentSizeCategory`, which SwiftUI custom/system fonts don't
  surface. Real Dynamic Type coverage comes from the **layer-3 render snapshot at AX5**, not this audit.
- `.textClipped` (×1) fires on the editable search `UITextField` (a known FP; the well uses `minHeight`).

Per-element suppression of 26 issues would be the "blanket suppression spelled out" anti-pattern — 26 lines
of noise per screen, re-asserting FPs as if real. Scoping to the four types that give trustworthy signal is
the honest gate.

**Provisional — open for task #10.** Whether `07-testing.md §7.4`'s "never whole-type" rule should be
amended for custom design systems (and whether the receded inks `textSecondary`/`textTertiary` genuinely
fail WCAG-AA and should be re-toned, vs. accepted as matching iOS's own `.secondary`/`.tertiary` labels) is
**deferred to the onboarding four-layer gate (task #10)**. Until then this screen's audit is type-scoped as
above; the other onboarding screens follow the same provisional scope. The user opted to commit the passing
suite now and settle the policy at the gate.

---

## 2026-06-03 — Onboarding audit: BROAD audit + issueHandler suppression (SUPERSEDES the two entries above)

**Decision.** `testAccessibilityAudit` runs the **broad** `performAccessibilityAudit { … }` (no `for:`
set — so a new SDK audit type is never silently dropped, per Apple WWDC23) and suppresses in the
`issueHandler`. Three audit types are not reliable on this custom design and are suppressed **with the
real check that covers each named**, not declared blind false-positives:

- `.dynamicType` — the audit reads UIKit `adjustsFontForContentSizeCategory`, which SwiftUI's
  `Font.custom(relativeTo:)` / `Font.system(.style)` don't surface; the text DOES scale (Typography.swift,
  zero `fixedSize`). Durable lock = an **AX5 render snapshot** (task #10), not this audit.
- `.contrast` — pixel-samples and mis-reads backgrounds over glass / scroll / the OKLCH ramp (flags the
  system `.glassProminent` CTA and ink-700-on-white, which pass). Receded-ink contrast is a **design-doc**
  call, not an XCUITest assertion.
- `.textClipped` — the search field grows from `minHeight`; known FP on editable fields.
- plus `onboarding.progress` + `.hitRegion` (informational, not an interaction target).

Everything else hard-fails. **Supersedes** the two prior same-date audit entries (per-element-only, and the
`for:` type-scoping): the `for:`-exclude was Apple's anti-pattern; whole-type suppression here is deliberate
and compensated, not blanket. Open at task #10: add the AX5 snapshot; decide if `textSecondary`/`textTertiary`
need re-toning vs. accepting the iOS `.secondary`/`.tertiary` convention.

---

## 2026-06-03 — L4 UITests: static map on map screens; combined-container content is covered at L1/L3, not L4

**Decision.** Two rules for XCUITesting onboarding screens, learned building the four-layer gate:

1. **Map screens run UITests with the static map** (`UITEST_STATIC_MAP=1` → `\.mapSnapshotMode`, injected at
   the app root). The live MapKit `Map` adds its own `Legal` attribution link, `VKPointFeature` pins, and
   rendered place-name text to the a11y tree — none of which we own — tripping the audit (`.hitRegion` on
   "Legal", "potentially inaccessible text" on map labels) and cluttering element queries. L4 tests *our*
   screen, not Apple's MapKit, so the static placeholder is the correct surface.
2. **Content inside a combined-accessibility container is not individually L4-queryable, and that's fine.**
   `baselocation.reach.*` rows live inside the `baselocation.rec` card whose subtree collapses to one
   accessibility element, so the row ids never reach the XCUITest tree (scrolling can't help). The same
   applies to deep `generation.step.*` rows. That *data* is already locked by **L1 presenter tests** (it
   derives correctly) + **L3 render snapshots** (it renders). L4's contract is "screen reachable per
   scenario + one real interaction + audit passes" — so these UITests assert the CTA + a top-level
   container + the primary above-fold interaction, and do NOT assert combined-child ids.

---

## 2026-06-03 — L3 glass snapshots + L4 onTapGesture: known gaps (the four-layer gate, accepted)

**Decision (option B).** Closing the onboarding four-layer gate with two documented framework gaps rather
than blocking on them:

1. **iOS 26 Liquid Glass renders BLANK in swift-snapshot-testing's offscreen host.** Any glass-bearing
   snapshot recorded blank (the `OnboardingActionFloor`, `LeadingGlyph`, and — because the glass action
   floor in `safeAreaInset` mis-sizes there — all 5 full-screen snapshots, incl. the AX5 control). Blank
   "passing" baselines are false confidence, so those suites were **deleted**. Kept: the 9 NON-glass
   component snapshots (verified rendering: SegmentedSelector, DayStepper, etc.). **Screen-level L3 is
   covered instead by L1 (193 presenter/model tests) + L4 (XCUITest across A/B/C).** Fix-forward: rewrite
   `assertDesignSnapshot` to a key-window `drawHierarchy(afterScreenUpdates:)` path where glass renders,
   then restore the screen + AX5 snapshots.

2. **The `.dynamicType` audit's AX5 compensating control is gone** (it was a screen snapshot). DT scaling
   is instead assured at the foundation: every `Typography` role is `Font.custom(size:relativeTo:)` /
   `Font.system(.style)` bound to a Dynamic Type style with zero `fixedSize` (codegen-locked). Restore the
   AX5 snapshot lock once #1 is fixed.

3. **XCUITest coordinate `.tap()` doesn't reliably drive SwiftUI `.onTapGesture`** (non-`Button`
   affordances like `TripShapeCard`). L4 exercises the tap (exists + hittable + tap + CTA persists) but
   does NOT assert the post-tap selection trait; the `select(strategy:)` result is proven at L1, and the
   card's VoiceOver activatability is fixed via `.accessibilityAction` on `SelectAction`.

4. **Map screens:** L4 runs with `UITEST_STATIC_MAP=1`; a decorative static-placeholder element (no id,
   no label) trips `.elementDetection` and is suppressed narrowly. The map is one labeled a11y element.
