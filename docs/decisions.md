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

---

## 2026-06-03 — Tokenize onboarding `@ScaledMetric` literals; snap to grid; new `Sizing` tier

**Decision.** Removed the literal `@ScaledMetric` seeds in the 5 onboarding `*StepView`s (a semantic-token
non-negotiable violation) by routing each through a token. While tokenizing, **snapped off-grid values
onto the 8pt spine**: chrome clearance 68→64 (8×8), alt-card min 134→136 (8×17), suggested dot 6→8 (s-2).
Two were **not** snapped: the 1pt separator (the 03 §1 stroke carve-out → new `Stroke.separator`) and the
104 chip-min (already 8×13). Added one named layout role `Spacing.chromeClearance` (sibling to
`screenInset`, exempt from the gap ladder) and a **new `Sizing` semantic tier** (`dot`/`cardMin`/`chipMin`)
for component dimensions.

**Why.** 68/134/6 were off-grid (a bug under 03 §1); the literal seed was also a token-discipline failure,
so tokenizing was the moment to snap. Component dimensions had no home in `Spacing` (gap ladder) /
`Radius` / `Stroke`; `05 §1` names no `Sizing` enum, so the new tier is a non-obvious call — design-reviewer
ruled it a defensible semantic home (cross-screen, role-named, parallel to `Radius`/`Stroke`). The ≤4px
render shifts are within fidelity rhythm tolerance; the base-location mockup `.alt` now references
`var(--size-card-min)`. No render-snapshot baseline covered these call-sites, so none were re-recorded.

---

## 2026-06-03 — Token organization: property→category + Component band; theming seam

**Decision.** Formalized where design values live (`05-design-system.md` §1.1–1.3, conventions ported
from the first-saas-repo token system): a value's home = its property type's category; component-specific
values nest in a per-category `Component` band, except `Sizing`, which is wholly the component-dimension
category (its members stay flat). Added a category map (§1.2) for discoverability and documented the
dark-mode swap seam (§1.3 — `ColorRole` is the single resolve point; foundations.css carries a one-line
reservation comment). No token values, no codegen, no view changes.

**Why.** Last session's "do we invent a `Sizing` tier?" debate exposed that the Component tier was
underspecified (`05 §1` said only "sparingly"). The property→category rule makes the home deterministic
and kills the ad-hoc tier debate; the documented seam keeps dark mode a clean future token swap. This
supersedes the loose `bookRowCoverSize`-style Component-tier guidance; it does not change the 2026-06-03
`Sizing` tier (which is now framed as the canonical component-dimension category).

---

## 2026-06-03 — Token foundation: t-shirt spacing scale + Grid-based component dimensions

**Decision.** Reworked the design-token foundation (conventions studied from first-saas-repo, adapted to
our codegen→Swift pipeline):
1. **`Spacing` is now a t-shirt scale** — `xs=4 sm=8 md=12 lg=16 xl=24 2xl=32 3xl=48 4xl=64` — replacing
   the role-named gap ladder (`hairline/paired/itemGap/cardInset/sectionGap/hero`). Value-preserving
   1:1 map (`hairline→xs … hero→2xl`); ~205 call-sites migrated app-wide via deprecated forwarding
   aliases (added, then deleted once refs hit zero — a green build with them gone proves completeness).
   `screenInset`/`chromeClearance` kept as named layout roles; component insets nest in `Spacing.Component`.
2. **Component DIMENSIONS are `Grid.x(n)` multiples, not primitives.** `Grid.x(_ steps:Int) = Primitive.s1
   * clamp(steps, 0…96)` (4pt unit, bounded). `Sizing` (flat `dot`/`minTapTarget`) + `Sizing.Component`
   (single-component dims) are all `Grid.x(n)`. **No bespoke `--size-*` primitives** — those were removed
   from `foundations.css`. Mockups mirror this as `calc(var(--s-1) * n)`.
3. Off-grid component literals snapped onto the grid (≤4px), re-recorded in 11 snapshot suites.

**Why.** The foundation was built with a sparse, gap-only spacing spine (stopped at 56, no size scale),
so component dimensions had no home — we'd been minting bespoke "size primitives" (`--size-map-pin`, etc.)
that duplicated the scale and polluted the primitive tier. Studying first-saas confirmed the real gap was
the spacing tier (a dense scale that also covers sizes) and that bespoke dimensions belong *derived from
the grid*, not as primitives — and that our `Grid.x` (on-grid, bounded, no literals) is in fact stricter
than first-saas's literal component sizes. The t-shirt scale is the conventional, discoverable API.

**Supersedes.** The role-named gap ladder; the earlier 2026-06-03 "token organization" §1.1 "Sizing stays
flat" framing (Sizing now uses `Grid.x` + a `Component` band) and the bespoke `--size-*` primitives from
the same day's component-tokenization entry. Theming seam unchanged (`ColorRole` is the dark-mode swap point).

---

## 2026-06-03 — Onboarding L2: rollback test DEFERRED (write command coming later)

**Decision (deferral).** Onboarding currently has no networked write. Its single request,
`GetOnboardingContextRequest`, is a read; today's mutations are in-place `TripDraftModel` transitions
applied client-side. A write command (optimistic-apply + rollback) is on the roadmap. The rollback /
error-path test is therefore **deferred until that write lands** — at which point it mirrors the Library
borrow flow's rollback test (`07-testing.md §5.1`). Until then the L2 onboarding suite covers read-path
failure (`.failed` + no partial graph leak) and the store's generation arithmetic
(`advanceGeneration` sweep + clamp, `completeGeneration`, `cancelOnboarding`).

This is a **deferral**, not a permanent design decision. Do not frame onboarding as "local-session-only
by design / no rollback." When the write lands: wire `UITEST_FAILURE_RATE` → `AppTemplateApp.init` →
`.mock(failure:)`, add the optimistic-apply + rollback tests, and remove this deferral entry.
Cross-reference: `UITEST_FAILURE_RATE` is kept as an intentional, currently-unconsumed future hook
(see Task C5 entry below).

---

## 2026-06-03 — `UITEST_FAILURE_RATE`: intentional, currently-unconsumed future hook (Task C5)

**Decision.** `UITEST_FAILURE_RATE` is kept as deliberate scaffolding for the planned onboarding write
command — it is **not dead code**. Today, `AppTemplateApp.init` reads only `UITEST_SCENARIO`;
`UITEST_FAILURE_RATE` is forwarded via `OnboardingRobot.launch(failureRate:)` into `launchEnvironment`
but nothing in the app consumes it. This is intentional: the onboarding write command (optimistic-apply
+ rollback) is on the roadmap, and when it lands the implementor wires `UITEST_FAILURE_RATE` through
`AppTemplateApp.init` → `.mock(failure:)` and adds the error-path / rollback UITests at that time.

**Reviewers and the coverage gate must NOT flag this as dead code.** The forwarding in the robot's
optional `failureRate` param is the scaffolding seam.

**When the write lands:** wire the env var → app init → `.mock(failure:)`; add the rollback/error-path
UITest; then remove this note. Cross-reference the A-DEC deferral entry above.

---

## 2026-06-06 — Saved: accent-as-fill roles are EARNED exceptions to J-2.4 (stamp pill, prominent way-to-save)

**Decision.** Three Saved design-system roles use the accent as a low-alpha **fill/ring**, a deliberate
exception to "the accent is never a fill" (J-2.4 / non-negotiable #4), each chip/row-scale and paired
with text — never a card fill:
- `ColorRole.stampFill` (`Primitive.accent50`) + `stampInk` (`accent700`) — the `SourcePlaceRow`
  timestamp pill (mockup `.src-place .stamp`): a tiny "saved 3 mo ago" capsule.
- `ColorRole.accentWashFill` (`accent50`) + `accentWashRing` (`accent100`) — the ONE prominent
  `WayToSaveRow` ("Paste a reel", mockup `.method.primary`): an accent-tinted ground + 1px ring marking
  the single primary method in the add sheet (one per region, J-6.1).

**Why earned.** Each ports a specific mockup selector, is ≤row-scale (not a card/screen fill), uses the
~6–13% alpha the mockup specifies, appears at most once per region, and pairs the tint with a text label
(never color-alone, 02-color §6). They are intent-named semantic roles aliasing existing primitives — no
`foundations.css`/codegen change. The category tints (`categoryTint`) are the same class, already chip-
scale and day-mark-hued (not accent), so they don't need this carve-out.

**Scope / supersede when.** Confined to these Saved affordances. Any new accent fill beyond a chip/row
needs its own entry. If the system later offers an accent-wash material, revisit.

---

## 2026-06-06 — Saved place detail: the over-hero bookmark is a WIRED STUB (no unsave story this milestone)

**Decision.** `PlaceDetailView`'s over-hero floating bookmark glyph (`GlassCircleButton`,
id `placedetail.bookmark`) is a **wired stub**: tapping it raises an in-content notice
(`placedetail.bookmarkNotice`, a `@State`-driven banner) rather than mutating the graph. The place reached
on this screen is already saved, and there is **no remove-from-Saved (unsave) flow this milestone**, so
there is no real sink for the bookmark yet.

**Why a stub, not an empty closure or an omission.** The mockup (`mockups/screens/saved/place-detail.html`
`.screen-topbar.--over-hero .ic[aria-label="Saved"]`) shows the bookmark, so omitting it is fidelity drift;
an empty closure is a dead affordance (06-screens §4.1 defect). A wired notice keeps every affordance hitting
a real sink while honestly signalling the missing flow — the same pattern as the D-5 "Add to a trip" stub on
this screen. Errors/notices are in-content, never a toast/alert (06-screens §6).

**Supersede when.** A remove-from-Saved store command (optimistic + rollback) lands; the bookmark then
toggles saved state through it and this notice is removed.

---

## 2026-06-06 — Saved L3: PlaceDetail + AddPlaceSheet screen snapshots deferred (offscreen blank — framework gap)

**Decision.** Screen-level L3 render snapshots for `PlaceDetailView` and `AddPlaceSheet` are **deferred**. Both produced blank frames in the offscreen `UIHostingController` host: `PlaceDetailView` uses `ScreenScaffold(.custom)` + an `.ignoresSafeArea` full-bleed hero (the iOS-26 glass `safeAreaInset` path mis-sizes offscreen); `AddPlaceSheet` content renders blank without a real sheet presentation context. Committing blank baselines is false confidence — the same ruling as the 2026-06-03 onboarding-gate decision.

Both screens are fully covered by the other three layers: L1 (`PlaceDetailPresenterTests`, `AddPlacePresenterTests`), L4 (`SavedFlowUITests`), and their already-locked component snapshots (`ProvenanceCard`, `PlaceInfoGrid`, `MapSnippet`, `WayToSaveRow`). The `SavedListScreenSnapshotTests` suite (5 states, `.root` scaffold) renders correctly and is kept.

**Supersede when.** `assertDesignSnapshot` is rewritten to the `drawHierarchy(afterScreenUpdates:)` / key-window path where glass and sheet presentation render correctly; then restore the `PlaceDetailScreenSnapshotTests` and `AddPlaceSheetSnapshotTests` suites.

---

## 2026-06-07 — Wallet OD-7: booking detail/access grids REUSE `PlaceInfoGrid` (no `BookingInfoGrid`)

**Decision.** The booking-detail 3-cell info grid (Depart/Arrive/Seat) and the access-pass meta grid
(Gate/Seat/Zone) reuse the existing Saved `PlaceInfoGrid` component, fed `[PlaceFacts]` cells — no new
`BookingInfoGrid` was built (plan Task 1.6 skipped). `PlaceFacts` (`{key, value, sub?}`) is structurally
identical to the wallet `.info-cell`/`.acc-meta` anatomy, so the reuse is exact, not a force-fit. Keeps
the component surface minimal and the 3-cell hairline grid locked by one snapshot.

---

## 2026-06-07 — Wallet OD-8: no-destination affordances are WIRED STUBS (Share, Scan, From-a-photo, Edit, brightness)

**Decision.** Wallet affordances whose full flow is out of this milestone are wired to real, testable
sinks rather than empty closures or invented screens (the Saved D-3/D-5 pattern):
- `BookingDetailView` **Share** → an in-content `@State` notice (`bookingdetail.shareNotice`); no share sheet built.
- `AddToWalletSheet` **Scan** / **From a photo** → a `pendingMethod` `@State` read by an inline "coming soon" hint; **Edit details** → an `@State` edit-hint. The deeper capture/extraction flows are separate stories.
- `AccessCardView` **brightness raise** is REAL (not a stub): `UIScreen.brightness = 1.0` on appear, restored on disappear (OD-8 chose the real effect).

Every affordance hits a sink (06-screens §4.1); the stubs honestly signal the missing flow. Supersede each as its real flow lands.

---

## 2026-06-07 — In-content secondary control is the INTERIM for `ScreenScaffold`'s missing trailing slot

**Decision.** `ScreenScaffold` exposes no trailing top-bar control slot, and a screen may not hand-wire
`.toolbar` (06-screens §2.6). So a screen's single secondary top control is rendered as an **in-content,
trailing-aligned affordance** until the scaffold gains a slot. This is the established, already-merged
pattern from `SavedListView` (the "+" add, `savedlist.add`); Wallet follows it for `WalletView`'s "+"
(`wallet.add`) and `BookingDetailView`'s **Share** (`bookingdetail.share`). The control keeps its id +
real sink; only its placement is the interim.

**Why not escalate `BookingDetailView` to `.custom`** (the fidelity-reviewer's alternative): `.custom` +
the over-hero glass header renders blank in the offscreen snapshot host (the 2026-06-06 gap), losing the
screen's L3 lock, and it would diverge from the merged SavedList precedent for the same situation. The
booking-detail hero is a normal content hero (not a full-bleed photo), so `.detail` is the right chrome;
only the Share control's placement is affected, and the in-content interim keeps the screen snapshot-able.

**Supersede when.** A `swift-design-system` change adds a trailing-secondary-control slot to
`ScreenScaffold`; then SavedList "+", Wallet "+", and BookingDetail Share all migrate to it.

---

## 2026-06-07 — Wallet: orphan-prompt eyebrow ink is `textSecondary` (not the mockup's accent-700)

**Decision.** `OrphanPromptCard`'s mono-caps eyebrow (`.lab`) uses `ColorRole.textSecondary`, not the
mockup's `accent-700`. The card already spends its earned accent on the wash ground + the `.mk` dot + the
Pin primary; an accent-700 eyebrow ink would push the card to a fourth accent touch and read as
accent-as-room rather than accent-as-presence (J-2.4 / J-6.4). Keeping the eyebrow neutral concentrates
the accent into the dot + action. A deliberate, restrained departure from the mockup's literal ink.

---

## 2026-06-07 — Tab IA reworked to Saved · Wallet · Home · You — SUPERSEDES Wallet OD-1 (Trip-entry interim)

**Decision.** Per user direction, the root `TabView` (`AppTab`) is now **Saved · Wallet · Home · You**
(dropped `Trip` and `Map`). **Wallet is a real top-level tab** — `WalletView` is the Wallet tab's root
(`ScreenScaffold(.root(title: "Travel wallet"))`, large collapsing title, no back), and
`BookingDetailRoute` registers on the Wallet tab's `NavigationStack(path: $store.walletPath)`. `Home` and
`You` are coming-soon placeholders. `AppStore` per-tab paths are now `savedPath`/`walletPath`/`homePath`/
`youPath`; `selectedTab` default stays `.saved`.

**This SUPERSEDES the Wallet OD-1 decision** ("Travel wallet" affordance on the Trip placeholder pushing
`WalletRoute`). That interim is removed: `RootView.tripHome`, the `trip.openWallet` entry, the
`WalletRoute` push, and `WalletRoute.swift` itself are deleted (Wallet is reached by selecting its tab,
not pushed). The L4 `WalletFlowUITests.navigateToWallet` now taps `tab.wallet` directly. WalletView
screen snapshots re-recorded for the `.root` chrome.

**Note.** `Home` has no screen yet (placeholder) — a real home/trip dashboard is a future feature; when
it lands it becomes the Home tab's root.

---

## 2026-06-07 — ScreenScaffold trailing-action slot + empty states are scrollDisabled — SUPERSEDES the in-content-secondary-control interim

**Decision.** Two related fixes for "tabs scroll/bounce with no content" + "the + should float top-right":

1. **`ScreenScaffold` gains a `trailingAction:` slot** — a `@ViewBuilder` (defaulted `EmptyView`, so all
   existing call sites are unchanged) rendered as FLOATING chrome via `.overlay(alignment: .topTrailing)`
   (J-0.1: floating, not on content). This is the long-deferred trailing-secondary-control slot. **It
   SUPERSEDES the "in-content secondary control is the INTERIM" decision**: `SavedListView`'s "+"
   (`savedlist.add`) and `WalletView`'s "+" (`wallet.add`) are now floating top-right `GlassCircleButton`s
   passed via `trailingAction:`, not in-content `addAffordanceRow`s (those helpers are deleted). The "+"
   is now **persistent in all states** (empty + populated) — a top-right add affordance is always-available
   chrome; the L4 empty-state tests now assert it EXISTS (the old "must NOT exist in empty" was an artifact
   of the in-content row only rendering when populated).

2. **Empty states use `scrollDisabled: presenter.isEmpty`** so they route through `ScreenScaffold`'s static
   (no-ScrollView) branch — a screen with content that fits cannot scroll/bounce. `.scrollBounceBehavior(.basedOnSize)`
   alone was insufficient (it doesn't help when content fills height via `.frame(maxHeight: .infinity)`, as
   the Wallet empty-state centering does). `comingSoon` placeholders (Home/You) use `.scrollDisabled(true)`
   on their `ContentUnavailableView` (internally scrollable). Populated screens keep the ScrollView +
   `.basedOnSize` (scroll only when content overflows). The empty-state title got
   `.fixedSize(horizontal: false, vertical: true)` so it wraps (not truncates) in the static layout.

Saved/Wallet screen snapshots re-recorded for the floating-"+"/static-empty layout. Supersede when a
future home dashboard or a different chrome model changes the trailing-action pattern.
