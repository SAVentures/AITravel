# Accessibility — the craft floor, not the compliance ceiling

Accessibility is **a craft signal**, not a checklist you survive. The 2026 Apple Design Awards graded
winners on it as such — Guitar Wiz won partly for "robust VoiceOver plus Dynamic Type, Increase
Contrast, and Differentiate Without Color" (Apple — 2026 ADA Winners). A screen that holds at AX5,
reads cleanly under VoiceOver, and never leans on color alone is doing the same last-10% work that
`06-judgment.md` J-13.5 calls *finish* — the thing that separates "fine" from "beautiful." Treat every
rule here as part of the design, authored at the same time as the happy path (J-11.6), not bolted on
before review.

This doc owns the accessibility **design rules** — what to build. The **audit/test** that verifies them
(`performAccessibilityAudit()`, the suppression discipline, the snapshot lock) is owned by
`ios/docs/engineering/07-testing.md §7.4`; the Swift port of the styling that makes contrast and
Dynamic Type pass is `ios/docs/engineering/05-design-system.md`. When in doubt about a value, this doc
is the contract; the Swift specifics live there.

Examples use the library/book reference slice (AppTemplate). It's a reusable template — the **rules**
are generic; swap the book specifics for your app.

---

## A-0. The non-negotiables

These five are the floor. Each restates a J-rule or a slop tell as an accessibility hard requirement;
break one only with a written entry in `docs/decisions.md`.

- **A-0.1 — Dynamic Type, always; test at AX5.** Every text style scales; no fixed-pt fonts, no fixed
  frames on text (J-0.3, T-0.1, `08-slop.md` H-4). Support the full range to AX5; cap specific surfaces,
  never disable (A-4).
- **A-0.2 — WCAG AA contrast, with margin.** 4.5:1 body / 3:1 large; aim ~5:1 so hex/rounding drift
  can't fail you (A-2, `08-slop.md` H-1).
- **A-0.3 — Never color alone.** Every color-coded state pairs with a glyph, label, or shape — it must
  survive color-blindness, Increase Contrast, and Reduce Transparency (J-2, A-5).
- **A-0.4 — Every interactive element is reachable, labeled, and ≥ 44×44pt.** VoiceOver can land on it,
  it announces what it *is/does*, and the hit region meets the target even when the glyph is smaller
  (A-1, A-6).
- **A-0.5 — Honor the reduce-* settings.** Reduce Motion, Reduce Transparency, Increase Contrast each
  degrade gracefully — substitute, never strip (A-7).

---

## A-1. Tap targets — pad the region, never shrink the glyph

- **A-1.1 — 44×44pt minimum** for every interactive control: buttons, list accessories, toolbar items,
  tab items, the borrow/favorite affordance on a book row (Apple HIG; LogRocket). Sub-44pt targets push
  tap-error rates past 25% (freeCodeCamp).
- **A-1.2 — Pad the hit region; keep the glyph small.** A 24pt heart icon stays visually 24pt — extend
  the *touch* area to 44pt (`.frame(minWidth: 44, minHeight: 44)` or padding, `05-design-system.md`).
  Shrinking the visible mark to fit and shrinking the hit region with it are both wrong.
- **A-1.3 — Inline text links are the one common exception** — a word-level link inside running prose
  doesn't get a 44pt box (Apple HIG).
- **A-1.4 — Spacing serves targets too.** Adjacent controls need enough gap that a fingertip can't
  straddle two; the gap ladder (`03-layout-spacing.md`) already buys this — don't crowd accessories
  (J-13.2; `08-slop.md` D-8).

---

## A-2. Contrast — AA is the floor, ~5:1 is the aim

- **A-2.1 — Hit WCAG AA: 4.5:1 for body, 3:1 for large** (≥ 18pt regular or ≥ 14pt bold) (WCAG; Apple
  HIG; Ethan Gardner). Target **~5:1** so hex rounding / OKLCH conversion drift leaves margin (LogRocket
  OKLCH); AAA is 7:1.
- **A-2.2 — Contrast is a property of the color *role*, not the screen.** `textPrimary`-on-`surface`
  and `textSecondary`-on-`surface` clear AA by construction (`05-design-system.md §3`); a screen that
  uses roles correctly passes by default. `textTertiary` is for disabled / placeholder / past-state
  **only** — it does *not* clear AA at body size, so it is never active text (J-2.3).
- **A-2.3 — Measure custom ink-on-paper pairs before shipping.** The warm-tinted neutrals are
  deliberate (`02-color.md`; `08-slop.md` C-5) — verify, don't eyeball. Contrast is gated by the
  accessibility audit (`07-testing.md §7.4`), not a color-math unit test.
- **A-2.4 — Never gray text on a colored fill, never low-contrast "tasteful" gray.** Both are slop tells
  *and* AA failures (`08-slop.md` C-4, H-1). On the persimmon/accent-state surfaces use a verified
  high-contrast role (J-2).
- **A-2.5 — Honor Increase Contrast.** Read `@Environment(\.colorSchemeContrast)`; when `.increased`,
  swap to higher-contrast tones (target ~7:1) and let the body re-render (Mobile A11y). The Liquid Glass
  layer fattens its frosting and adds borders under this setting automatically — verify, don't override
  (`05-design-system.md §6`).

---

## A-3. Dynamic Type — the layout must hold to AX5

Cross-references the type system (`01-typography.md` T-8); the accessibility-specific rules:

- **A-3.1 — Drive type from semantic roles backed by text styles** (`Typography.body`/`.title`/`.mono`),
  never `.font(.system(size:))` — a fixed size defeats scaling and is a review failure (T-0.1, A-0.1).
- **A-3.2 — Scale non-text metrics with `@ScaledMetric`.** Padding, icon sizes, cover-thumbnail
  dimensions, and custom frames grow with text: `@ScaledMetric(relativeTo: .body) var coverWidth = 44`
  — pin `relativeTo:` to the adjacent text style so the layout stays proportional (WWDC20 10175;
  avanderlee). A fixed `CGFloat` next to scaling text tears the layout apart at AX5.
- **A-3.3 — Test at AX5.** Bump to the largest accessibility size in the 60-second review (J-15.9) and
  verify no truncation, overlap, or clipped container — the book row's title, byline, and borrowed badge
  must all still fit or wrap, never collide.
- **A-3.4 — Cap specific surfaces; never disable globally.** Where layout genuinely breaks (a dense
  metadata strip, a fixed-height chrome bar), clamp the *range* with
  `.dynamicTypeSize(...DynamicTypeSize.accessibility1)` — clamp the ceiling on that one surface, never
  turn scaling off app-wide (Apple HIG; Hacking with Swift). Clamping is a scoped exception, not a
  default.
- **A-3.5 — Let text wrap, not truncate.** Allow multi-line and tightening (`.allowsTightening(true)`)
  before a string drops off-scale; no fixed-height text container (J-0.3; `08-slop.md` D-7).

---

## A-4. VoiceOver — reachable, labeled, in order

Every interactive element is reachable by swipe and announces what it **is or does**. This is where most
of the craft lives.

### A-4.1 — Labels: name the function, not the content, and never the role

- **A-4.1.1** — `.accessibilityLabel` says what the element *is/does*, short, **without the role word** —
  VoiceOver appends "button" / "heading" itself (`.accessibilityLabel("Borrow")`, not "Borrow button")
  (Mobile A11y; CVS Health; tanaschita).
- **A-4.1.2** — An image-only / glyph-only control **must** carry a label, or VoiceOver speaks the asset
  filename (CVS Health Images). The heart affordance announces "Favorite," not "heart.fill."
- **A-4.1.3** — Decorative imagery is hidden: `Image(decorative:)` or `.accessibilityHidden(true)` — a
  monochrome glyph placeholder (J-12.4) that conveys nothing gets hidden; an informative cover gets a
  real label (CVS Health; WCAG 1.1.1).

### A-4.2 — Hints, values, traits

- **A-4.2.1 — Hints describe the outcome, verb-first, only when not obvious.**
  `.accessibilityHint("Opens the book detail")` — read last, after a pause; never repeat the label
  (Mobile A11y; freeCodeCamp).
- **A-4.2.2 — `.accessibilityValue` carries dynamic state** that isn't in the label — a progress
  "Page 142 of 412," a rating "4 of 5 stars."
- **A-4.2.3 — Traits mark real roles, not native controls.** A custom tappable view (`onTapGesture`) has
  **no** trait — add `.accessibilityAddTraits(.isButton)`; use `.isHeader`, `.isSelected`, `.isLink`,
  `.isToggle` for genuine roles; strip a wrong inherited trait with `.accessibilityRemoveTraits(...)`.
  Don't add traits to native `Button`/`Toggle` — they bring their own (CVS Health; Mobile A11y;
  tanaschita).
- **A-4.2.4 — Headings carry `.isHeader`, levels sequential.** Mark a section header with the
  `.isHeader` trait (enables Rotor navigation) — not by appending "Heading" to the label;
  `.accessibilityHeading(.h1)…(.h6)` sets level only alongside `.isHeader`, and **levels must not skip**
  (no h1→h3) (CVS Health Headings; WCAG 1.3.1; `08-slop.md` H-2).

### A-4.3 — Grouping & focus order

- **A-4.3.1 — Collapse a multi-element row into one stop.** A book row (cover + title + byline + badge)
  is one swipe target: `.accessibilityElement(children: .combine)` for an automatic merged read, or
  `children: .ignore` + a hand-written `.accessibilityLabel` for the most natural phrasing; use
  `children: .contain` when children must stay individually focusable (Hacking with Swift; Deque). A row
  the eye reads as one unit should be one VoiceOver stop, not four.
- **A-4.3.2 — Logical focus order follows reading order** (top→bottom, leading→trailing). Override only
  when it genuinely improves comprehension: `.accessibilitySortPriority` (higher reads first, inside a
  `children: .contain` container) and `@AccessibilityFocusState` to move focus to newly revealed content
  (e.g. onto a detail that just expanded) (Mobile A11y; Swift with Majid; Deque).
- **A-4.3.3 — Expose secondary affordances as custom actions, not swipe-only gestures.**
  `.accessibilityAction(named: "Renew")` surfaces a swipe action to VoiceOver users who can't perform the
  gesture; chunk dense metadata with Accessibility Custom Content (Deque; CVS Health).
- **A-4.3.4 — Announce non-focus-moving updates.** When state changes without moving focus (an item
  added to a shelf), post `AccessibilityNotification.Announcement("Added to your shelf")` — wrap in a
  brief `DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)` so VoiceOver reliably speaks it (CVS
  Health AccessibilityNotifications; WCAG 4.1.3).

### A-4.4 — Worked example: the overdue book row

A borrowed, overdue row carries five visual signals — borrowed badge, due-date line, dimmed cover, the
state ink, the renew action. As **one** VoiceOver stop it should read like a sentence, with state in
words (never color or badge alone, A-5):

```
"Dune, by Frank Herbert. Borrowed, due 3 days ago." 
  trait: .isButton
  hint:  "Opens the book detail"
  custom action: "Renew"
```

Note: "due 3 days ago," not "Overdue!" — editorial, no alarm, an offer to renew (J-11.5). The badge and
the dimmed cover are decorative *given the label already says "borrowed"* (`.accessibilityHidden(true)`)
so VoiceOver doesn't repeat the state three times.

---

## A-5. Never color alone — pair every state with a second cue

- **A-5.1 — Color-coded state always carries a glyph, label, or shape** (J-2; J-12; Apple HIG; NN/g). A
  "borrowed" state is a *badge + word*, not just a persimmon tint; "selected/now" (J-6.3) is a mark +
  position, not a color swap. This survives color-blindness, Increase Contrast, *and* Reduce Transparency
  — three different users, one rule.
- **A-5.2 — The redundancy is the same one J-2 already requires** for hierarchy — accessibility just
  makes it non-optional. If a state reads only as a color, it's both an a11y failure and a craft failure.
- **A-5.3 — Differentiate Without Color is a setting, not just a guideline.** The visual second cue means
  the screen already passes it; don't ship a state whose only differentiator is hue.
- **A-5.4 — Consider Button Shapes.** `accessibilityShowButtonShapes` surfaces tap affordances for users
  who need them — don't rely on a bare colored word reading as tappable (Apple HIG).

---

## A-6. Empty & error states — meaningful semantics, equal care

Empty/error states get the same accessibility work as the happy path (J-11.6, J-13.5):

- **A-6.1 — An empty state is announced, not just drawn.** The "No books yet" view has a real
  `.accessibilityLabel`; if it appears after an action, post an announcement (A-4.3.4).
- **A-6.2 — Errors carry actionable semantics.** A write-error banner is reachable, labeled with the
  problem *and the recovery* ("Couldn't borrow — try again"), and posts as an announcement so VoiceOver
  hears it without hunting (WCAG 4.1.3). No `!`, no alarm (J-11.5).
- **A-6.3 — Loading conveys progress, not silence.** A continuous shimmer (the one allowed continuous
  motion, J-9.3) needs a status the screen reader can read — it shouldn't read as an empty, frozen view.

---

## A-7. Reduce Motion / Reduce Transparency / Increase Contrast

- **A-7.1 — Reduce Motion: substitute, don't strip** (→ `04-motion.md`; J-9.5). Read
  `@Environment(\.accessibilityReduceMotion)`; apply the animated value only when `false`, and swap large
  transform/oscillation for a cross-fade or static state — but **keep meaning** that motion carried
  (createwithswift; Hacking with Swift; Apple HIG Motion). Continuous motion (A-6.3) goes static. Never
  rely on animation alone to communicate something important (Apple HIG Motion).
- **A-7.2 — Reduce Transparency: fall back to opaque.** Glass chrome (`05-design-system.md §6`) frosts
  more heavily / goes opaque under this setting — text on it must still clear 4.5:1, so keep glass text
  on a solid layer, never floating over arbitrary content (letsdev; conorluddy). The system handles the
  glass fallback; your job is the contrast that survives it.
- **A-7.3 — Increase Contrast: see A-2.5.** Higher-contrast tones, target ~7:1; glass gains stark borders
  automatically — verify, don't override.
- **A-7.4 — Read the environment to verify, never to fight the system.** These are user choices; the
  design degrades to honor them.

---

## A-8. Identifiers are for testing, not for VoiceOver

The dot-namespaced **accessibility *identifiers*** (`bookrow.<id>`, `book.borrowButton`,
`writeError.banner`) are **stable test contracts**, not user-facing strings — XCUITest queries them; a
screen reader never speaks them.

- **A-8.1** — `.accessibilityIdentifier(...)` (the test hook) is distinct from `.accessibilityLabel(...)`
  (what VoiceOver speaks). Set both; never overload an identifier to do a label's job (a slot id like
  `bookrow.borrowed.badge.<id>` is not a sentence).
- **A-8.2** — The convention (`component.slot[.id]`, lowercase, the view owns it) and the per-screen
  audit live in engineering: `ios/docs/engineering/06-screens.md §10` (identifier convention) and
  `07-testing.md §7.3–§7.4` (queries + `performAccessibilityAudit()` with narrow, documented
  suppression). This doc sets the *design* rules the audit enforces; it does not restate the Swift.

---

## A-9. The accessibility pass (fold into J-15)

Run alongside the 60-second review (`06-judgment.md` J-15) — these are its accessibility teeth:

1. **AX5** — bump to the largest size; no truncation/overlap/clipping? (A-3.3)
2. **Contrast** — text roles clear AA, aim ~5:1; no gray-on-color? (A-2)
3. **Color-alone** — every state has a glyph/label/shape second cue? (A-5)
4. **Targets** — every control ≥ 44×44pt, region padded not glyph shrunk? (A-1)
5. **VoiceOver** — every control reachable + labeled (function, no role word); rows combined to one
   stop; logical order; decorative hidden? (A-4)
6. **Headings** — `.isHeader`, levels sequential (no skip)? (A-4.2.4)
7. **Reduce-\*** — Motion substitutes, Transparency stays legible, Increase Contrast lifts tone? (A-7)
8. **Empty/error** — announced, recovery-labeled, no alarm? (A-6)

All eight pass → the screen is accessible. Any fails → fix before the fidelity-reviewer, which is where
`performAccessibilityAudit()` (`07-testing.md §7.4`) locks it.

---

## See also

- `06-judgment.md` — J-0.3 (Dynamic Type), J-2 (color roles / contrast), J-11.6 + J-13.5 (empty/error as
  craft), J-15 (the 60-second review this folds into)
- `08-slop.md` — §H general-quality tells (H-1 low contrast, H-2 skipped headings, H-3 tight leading,
  H-4 tiny text, H-6 justified) — the accessibility floor restated
- `01-typography.md` — T-8 (Dynamic Type range, AX5, cap-never-disable), the text-style roles
- `02-color.md` — the text-color roles and the warm-neutral pairs that must be measured
- `04-motion.md` — Reduce Motion behavior (A-7.1 cross-refs)
- `ios/docs/engineering/07-testing.md §7.4` — the accessibility audit that **verifies** these rules
- `ios/docs/engineering/06-screens.md §10` — the dot-namespaced identifier convention (testing, not
  VoiceOver)
- `ios/docs/engineering/05-design-system.md` §3 (contrast as a role property), §6 (glass + reduce-\*)
