# Motion — one personality, used with restraint

Motion is the easiest place to look generic and the easiest place to look broken. The bar is the same as
everything else in this set: a screen that *animates* is not a screen with good motion. Good motion has
**one easing personality**, fires only where it carries meaning, and gets out of the way. This doc owns
the *look* of motion — the easing, the duration ladder, when a spring is allowed, what never animates,
and how Reduce Motion degrades. The Swift *port* (the `Motion.*` tokens, the `@Animatable` macro,
`.oneShotPulse`) is `ios/docs/engineering/05-design-system.md §5`; this doc decides what those tokens
*feel* like.

This is the prescriptive expansion of **J-9** (`06-judgment.md`). Where J-9 states the rule, this doc
gives the numbers, the API shape, and the book-domain examples. Cite either in review (`violates J-9.2`
or `04-motion §3`).

Examples use the library/book reference slice — the borrow/return/shelf vocabulary. Replace the domain
specifics; the **rules** carry over.

---

## 1. The one easing personality

There is exactly **one** easing curve for the whole app: a **critically-damped ease-out**. It
decelerates into rest and never overshoots. Calm, resolved, premium — the opposite of bouncy. Every
chrome transition, sheet, push, fade, and reorder uses it. No per-component curves (J-9.2).

```
critically-damped ease-out  ≈  cubic-bezier(0.32, 0.72, 0, 1)
SwiftUI:  .timingCurve(0.32, 0.72, 0, 1, duration:)   — or a bounce-0 spring
```

This curve is the codified house style — non-bouncy, settles without wobble; lowering the damping to add
overshoot is exactly the "dated and tacky" tell to avoid (`comprehensive-references.md` Motion / Craft
Teardowns; `08-slop.md` E-1). When you express it as a spring, use `.smooth` (bounce 0) — the
`withAnimation` default since iOS 17 is already this spring (WWDC23 10158 / 10156).

- **§1.1 — One curve, app-wide.** A reader should never be able to tell two screens apart by their
  easing. Inventing a second curve "for this one transition" is the first crack.
- **§1.2 — The only sanctioned exception is the single reward moment** (§5) — and even there the bounce is
  small, scoped, and fires once.

---

## 2. The duration ladder

A fixed ladder of durations, each a semantic token (`Motion.fast` / `.base` / `.long`; map/think are
app-scoped extras). Pick a rung by *what is moving*; do not invent a value in between. Standard
transitions stay short (~200–500ms); anything past ~1–2s without a functional reason reads as gratuitous
(Apple HIG Motion; `comprehensive-references.md` Motion).

| Token | ms | Use | Book example |
|---|---|---|---|
| `Motion.fast` | **120** | taps, toggles, chip selects, press-state release | tapping a shelf filter chip; the borrow button's press settling back |
| `Motion.base` | **240** | the default — most state changes, fades, badge swaps | a row's `Borrowed` badge appearing; available → reading state change |
| `Motion.long` | **320** | sheets and full-screen transitions | the book-detail sheet rising to `.medium`; a push into a book |
| `Motion.map`† | **480** | camera moves, large list reorder, drop-in | re-sorting the shelf after "sort by due date" |
| `Motion.think`† | **1600** | the **one** continuous loop (§4) | the cover-fetch / "finding your next read" shimmer |

† App-scoped — present only if the app has a map/reorder surface or a single thinking affordance. Most
screens use only fast / base / long.

- **§2.1 — Tap feedback is exempt from "wait for the curve."** The press commits in **≤100ms** (§6); the
  120ms release is what plays *after*.
- **§2.2 — Reduce Motion halves every rung** (§7), so keep the base values clean multiples.

---

## 3. Springs vs. curves — when each is allowed

The split is about *who started the motion*, and it is not a stylistic choice — it is a rule
(`comprehensive-references.md` Motion, WWDC23 10158).

| The motion is… | Use | Why |
|---|---|---|
| **User-driven direct manipulation** — taps, drags, swipes, sheet pulls, pull-to-refresh, sliders | `spring(response:dampingFraction:)` (bounce 0 / `.smooth`) | a spring preserves the gesture's velocity and "picks up right where the finger ended"; it merges and retargets if interrupted, so it stays continuous (WWDC23 10158 / 10156) |
| **Automatic / time-based** — loading, progress, an appearing badge, a system-started fade or push | `.easeInOut` / `.linear` via `.timingCurve(0.32,0.72,0,1, …)` | the system started it; there is no gesture velocity to honor, so a fixed-duration curve reads as deliberate, not physical |

- **§3.1 — A spring is *only* for direct manipulation.** A spring on an automatic transition (a badge that
  springs in on its own) is the bouncy-where-it-shouldn't-be tell (J-9.2). The book-detail sheet that the
  *user drags* settles on a spring; the `Borrowed` badge that appears *because a sync completed* uses the
  ease-out curve.
- **§3.2 — Bounce/damping stays at the calm end.** In the duration/bounce model use `bounce: 0` (the
  `.smooth` preset); in the legacy model `dampingFraction ≥ 0.825` (response ~0.3 for a button press, ~0.9
  for a dramatic sheet) — never below 0.825, which adds overshoot (Apple `Animation.spring` docs;
  `comprehensive-references.md` Craft Teardowns).
- **§3.3 — Scope the animation to a value, not the transaction.** Prefer `.animation(.smooth, value:)`
  over a bare `withAnimation { }` so one property animates with one curve and nothing animates by accident
  (WWDC23 10156). This is also how each property can carry its correct rung.
- **§3.4 — Live gesture tracking uses `interactiveSpring`.** For a sheet detent drag or a swipe that
  updates continuously, `interactiveSpring(…)` (lower latency, higher `blendDuration`) tracks the finger;
  the settling `spring` takes over on release (Apple `interactiveSpring` docs / WWDC23 10158).

---

## 4. At most one continuous motion

A screen may have **at most one** looping/continuous animation, and only when it carries meaning — a
fetch in flight, "finding your next read." Everything else has a clear start and end (J-9.3).

- **§4.1 — One loop, period.** A second looping element (a pulsing dot *and* a shimmer) is noise. If two
  things want to move forever, the screen is doing two jobs.
- **§4.2 — The loop runs at `Motion.think` (1600ms)** via `.repeatForever(autoreverses:)`, used sparingly
  (`comprehensive-references.md` Motion). Keep its amplitude small and contained — Apple flags large
  ~0.2 Hz oscillation specifically (Apple HIG Motion).
- **§4.3 — Never the only signal.** Pair the loop with a static/textual cue (a "Finding…" label), because
  a person may not see motion (Apple HIG Motion). The shimmer over a loading cover row needs the row's
  skeleton shape too.
- **§4.4 — Continuous motion goes *static* under Reduce Motion** (§7) — the shimmer becomes a plain
  resting skeleton.

---

## 5. The one reward moment — the only sanctioned overshoot

Bounce is forbidden everywhere except **one** small, scoped reward per flow — a confirmation tick after a
completed action (J-9.2). In the book slice this is the **borrow-confirm tick**: tap *Borrow* → the press
commits flat (§6) → on success a checkmark draws/scales in with a single, gentle spring.

- **§5.1 — One reward per flow, on completion only.** Reserve celebratory/overshoot motion (and any
  `.success` haptic) for the *completed* flow — never an in-flight micro-interaction
  (`comprehensive-references.md` Motion). Borrow confirmed → tick + `.sensoryFeedback(.success, trigger:)`;
  the tap itself gets only a light impact.
- **§5.2 — Keep the bounce small.** `.snappy` (small bounce) or `.spring(duration: 0.3, bounce: 0.2)` —
  noticeable, not a cartoon. `bounce > 0.4` is too extreme (WWDC23 10158).
- **§5.3 — It animates a transform, not layout** (§8) — the tick scales/opacities in; it does not push
  siblings around.
- **§5.4 — Under Reduce Motion the tick *appears* (a fade), it does not spring** (§7). The reward is
  preserved; the overshoot is dropped.

---

## 6. Tap feedback — commit before you animate

Tap response must commit in **≤100ms**, before any animation plays (J-9.1). The press state is not part
of the transition — it is immediate feedback that the touch registered.

- **§6.1 — Commit a ~0.985 press scale instantly.** Render the pressed look the moment the finger lands;
  do not gate it behind the release animation. Measured tap-to-haptic latency already runs ~114ms, so any
  added delay reads as lag (`comprehensive-references.md` Motion / AITravel `CLAUDE.md`).
- **§6.2 — Drive the press from style state, not a gesture.** Read `configuration.isPressed` in a
  `ButtonStyle` so the press is structural and consistent (`comprehensive-references.md` Components). The
  *Borrow* button dips to 0.985 on press; the 120ms ease-out plays on release.
- **§6.3 — Press is a transform** (`scaleEffect`), never a frame/padding change (§8).
- **§6.4 — Pair discrete state changes with the right haptic class** — `.impact`/`.selection` for
  taps/toggles, `.success` reserved for completion (§5); call `prepare()` before the user acts
  (`comprehensive-references.md` Motion).

---

## 7. Reduce Motion is mandatory

Honoring `@Environment(\.accessibilityReduceMotion)` is non-negotiable (J-9.5). Read it and gate the
animation; substitute a calmer alternative — never just strip the feedback (Apple HIG Motion;
`comprehensive-references.md` Motion/Accessibility).

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
// …
.animation(reduceMotion ? nil : .smooth, value: isBorrowed)
```

| Normal | Reduce Motion |
|---|---|
| durations on the ladder (§2) | **halved** |
| springs (direct manipulation, §3) | **flatten to a cross-fade** |
| continuous loop / shimmer (§4) | **goes static** (resting skeleton, color shift) |
| reward tick spring (§5) | **fades in**, no overshoot |
| push/zoom that carries an element (§8) | **dissolve** between states |

- **§7.1 — Degrade, don't delete.** Motion that conveys meaning (a transition that shows hierarchy)
  becomes a dissolve or color shift, not nothing (Apple HIG Motion).
- **§7.2 — Test both settings.** Every animated surface ships verified at Reduce Motion on and off.

---

## 8. Animate transforms — never layout

What you animate matters as much as the curve. Animate cheap, interpolatable properties; never the ones
that force a layout pass (J-9.2; `08-slop.md` E-2).

| Animate (cheap, via `Animatable`/`VectorArithmetic`) | Never animate (layout thrash) |
|---|---|
| `opacity`, `scaleEffect`, `offset`, `rotationEffect` | `width` / `height` / `frame` |
| color, shadow radius | `padding` / `margin` / spacing |
| `matchedGeometryEffect` for shared-element moves | inserting/removing layout-affecting views per frame |

- **§8.1 — Transforms and opacity only.** They interpolate cheaply and don't recompute the layout
  (`comprehensive-references.md` Motion / SwiftUI Lab). Animating a row's height to "expand" a book entry
  janks; cross-fade or use `matchedGeometryEffect` instead.
- **§8.2 — Use `matchedGeometryEffect` for shared elements** — a book cover that flies from a shelf row
  into the detail header is one element moving, not two views resized.
- **§8.3 — Isolate transforms from ancestor layout** with `geometryGroup()` (iOS 17+) when a transform
  would otherwise perturb siblings (`comprehensive-references.md` Motion).
- **§8.4 — Toggle expensive effects without layout cost** — e.g. switch glass via `.identity` rather than
  inserting/removing the modifier (the glass analog of "don't animate layout").

---

## 9. Transitions explain space

A transition is a sentence about *where the user went*; if it explains nothing, cut it (J-9.4). Don't
transition full-screen for an in-place state change (empty/loading/loaded, list↔grid) — swap content in
place and reserve push/cover for genuine hierarchy or task change
(`comprehensive-references.md` Navigation Shell).

- **§9.1 — Push carries the parent's title and a shared element.** Tapping a shelf row pushes into the
  book and carries the cover (§8.2) so the move reads as "into this one."
- **§9.2 — Sheets rise from the thumb zone** at `Motion.long` and settle with the ease-out (or, on a
  drag, the spring) — the upward motion *is* the "subordinate task" signal.
- **§9.3 — No decorative transition.** A thumbnail that scales/rotates on tap for flavor is gratuitous
  (`08-slop.md` E-3). Motion gives feedback or explains space — nothing else.
- **§9.4 — In-place is in-place.** available → reading on a row, or list ↔ grid on the shelf, cross-fades
  in the same view; it does not push.

---

## 10. The motion review

Run alongside `J-15` for any animated surface:

1. **One curve?** Every non-reward transition uses the one ease-out (§1, J-9.2).
2. **On the ladder?** Durations are fast/base/long (+map/think); nothing in between, nothing >~2s (§2).
3. **Spring only for direct manipulation?** No bouncy automatic transitions (§3, J-9.2).
4. **≤ one continuous motion**, paired with a static cue? (§4, J-9.3)
5. **≤ one reward moment**, on completion, small bounce? (§5)
6. **Tap commits ≤100ms** before any animation? (§6, J-9.1)
7. **Transforms/opacity only** — no animated frame/padding? (§8, J-9.2)
8. **Transition explains space**, not decoration; in-place stays in-place? (§9, J-9.4)
9. **Reduce Motion** degrades (halve / fade / static), verified both ways? (§7, J-9.5)

All nine pass → ship.

---

## See also

- `06-judgment.md` §J-9 — the motion J-rules this doc expands; J-6.5 (one continuous motion)
- `08-slop.md` §E — the motion tells (E-1 bounce, E-2 layout-prop animation, E-3 gratuitous transforms)
- `ios/docs/engineering/05-design-system.md` §5 — the Swift port: `Motion.*` tokens, `@Animatable`,
  Reduce-Motion handling
- `03-layout-spacing.md` — the spacing/radius the transforms move *within* (motion never animates these)
- `07-accessibility.md` — Reduce Motion alongside Dynamic Type / contrast
- `_research/comprehensive-references.md` — the Motion section (WWDC23 10158/10156, HIG, spring docs)
