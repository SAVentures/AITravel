# Judgment — the calls the tokens don't make

The other design docs answer *what exists* (the type scale, the color roles, the components). This one
answers *what to do with them* — the rules that separate a screen that merely "uses the tokens" from a
screen that is actually **beautiful**. Token discipline buys consistency; this doc buys craft.

Every rule has a number — cite it in review (`violates J-3.4`). These are prescriptions, not
suggestions; break one only with a written entry in `docs/decisions.md`. This is the bar the
**design-reviewer** (at foundation-freeze) and the **fidelity-reviewer** (per screen) enforce; the
engineering-side summary is `ios/docs/engineering/05-design-system.md §11`.

Examples use the library/book reference slice. Replace the domain specifics for your app — the **rules**
are what carry over.

---

## J-0. The visual non-negotiables (restated, load-bearing)

These govern everything below; if a later rule appears to contradict J-0, J-0 wins. They pair with the
non-negotiables in `CLAUDE.md`.

- **J-0.1 — Glass only on chrome that floats.** Tab bar, top bar, the action bar, a sheet handle, a map
  overlay chip. Never on cards, list rows, sheets-at-rest, or anything holding primary input. Use the
  system Liquid Glass material (`glassEffect`/`.buttonStyle(.glass)`), not a hand-rolled translucency.
- **J-0.2 — Design values come from *semantic* tokens only.** No literal colors/sizes/spacing in a
  screen or component; never a primitive directly. A literal or a raw primitive is a review failure.
- **J-0.3 — Dynamic Type, always.** Every text style scales; no fixed-pt fonts, no fixed frames. A
  hardcoded `.frame(height: 48)` on a text container is a bug.
- **J-0.4 — One accent, used for emphasis/state — not chrome.** The app's accent marks the one thing
  that matters on a surface (the primary action, a selected/now state). It is never a decorative fill on
  a card, and never spread across a screen.
- **J-0.5 — Every screen has a point of view.** A deliberate type pairing, a signature color, a
  signature motion — not generic system-font + system-blue + defaults. (J-13.)

---

## J-1. Vertical rhythm — the gap ladder

There is a fixed ladder of vertical gaps. Memorize the rungs; **do not invent one in between.** Each
maps to a *semantic* spacing token (`05-design-system.md §1`), never a raw number.

| Rung | Token | Px (4pt grid) | Where it appears |
|---|---|---|---|
| Hairline | `Spacing.hairline` | 4 | eyebrow ↔ title; tag ↔ name |
| Paired | `Spacing.paired` | 8 | icon ↔ label in a chip/button; thumb ↔ name baseline |
| Sibling | `Spacing.itemGap` | 12 | title ↔ subtitle in a card; meta ↔ title |
| Card / row | `Spacing.cardInset` | 16 | card padding; list-row vertical padding |
| Section | `Spacing.sectionGap` | 24 | section header ↔ first row; hero ↔ first section |
| Breath | `Spacing.hero` | 32 | screen hero ↔ first control; sheet inner top |

Anything off this ladder (10, 14, 18, 20…) is a bug. **The 4pt grid is a hard contract** — every value
is a multiple of 4 (the sole exception is sub-pixel glass edge hairlines). Two independently-built
screens that both pull `Spacing.sectionGap` for "the gap after the header" will *match* — that is the
whole point of the ladder.

---

## J-2. Color roles — pick by role, never by value

The neutral ramp is not interchangeable; pick the **semantic role**, not "a darker grey."

| Role | Used on | Never on |
|---|---|---|
| `textPrimary` | titles, names, primary numerals | meta, captions, dividers |
| `textSecondary` | meta lines, sub copy, captions | titles |
| `textTertiary` | disabled/placeholder, past-state | active text (fails AA at body size) |
| `separator` | 1px dividers, card borders | backgrounds |
| `surface` / `surfaceElevated` | page / card | text |
| `actionPrimary` | the CTA, links, focus | body text |

**Hard rules:**
- **J-2.1 — Headings are always `textPrimary`.** A softened heading reads as "the *previous* heading was
  the real one." One ink for primary type.
- **J-2.2 — Body is binary: `textPrimary` for the name, `textSecondary` for the rest.** There is no
  middle ink for body; a "subtitle in a third grey" is a bug.
- **J-2.3 — At most three inks in one row** (name, meta, one state mark). More than three is a chart, not
  a row.
- **J-2.4 — The accent has a budget.** It appears **at most twice** per screen (e.g. the primary CTA +
  one selected-state mark). A third accent appearance is over-claim — the accent becomes the room
  instead of a presence in it.
- **J-2.5 — Never pure white or pure black.** Use the warm-tinted `surface`/`textPrimary` roles; pure
  `#fff` is clinical against a warm system.

---

## J-3. Typography — family per role, few sizes

Typography carries most of the beauty. Discipline here is the single biggest lever.

- **J-3.1 — Each family owns a role.** A *display* family for names/titles/hero numerals; a *UI* family
  for body, chrome, button/chip labels (the default — if you didn't pick, you're in it); a *mono* family
  for measurement (timestamps, counts, IDs, dates). Mixing roles is the most common type bug.
- **J-3.2 — A screen uses at most four type sizes:** title, name, body, footnote/mono. Reaching for a
  fifth means you're over-designing — collapse two roles.
- **J-3.3 — The scale is small on purpose.** Nothing larger than the display size on a phone; titles cap
  modestly. Oversized type reads as a marketing landing page, not an app.
- **J-3.4 — Body floor holds.** No running prose below the body-callout size; the footnote size is for
  mono caps and metadata only.
- **J-3.5 — Tracking is paired with size**, set by the token, never ad-hoc: tight on large display,
  normal on body/UI, loose on mono-caps eyebrows only.
- **J-3.6 — Italic (or the display family's expressive cut) is one editorial moment per hero.** Used for
  the product's *voice*; not sprinkled. Two expressive moments in one hero is a bug.
- **J-3.7 — Every role is a Dynamic Type style** (J-0.3) — a custom font is registered to a text style
  so it scales; never `.font(.system(size: 17))`.

---

## J-4. Dividers vs. space — when to draw the line

Every line is a claim about structure. If the claim isn't true, the line is noise.

- **J-4.1 — Use a 1px `separator` only when** a region genuinely needs a "footer/partition" reading, or
  identical rows repeat and the eye should *scan* not read.
- **J-4.2 — Never use a divider when space will do:** between rows already separated by `itemGap`+;
  inside a card between header and body; between a name and its meta; around a sheet's body (a sheet is
  one surface — inner lines cut it into mini-cards).
- **J-4.3 — One divider color (`separator`), always 1px.** Emphasis comes from space and color, not a
  thicker line.

---

## J-5. Density — chrome vs. content, never mixed

Two densities, scoped to surface type; pick one per surface.
- **J-5.1 — Chrome is thin** (tab/top/action bars): tight vertical padding, small glyphs; it hosts an
  action and disappears.
- **J-5.2 — Content is generous but not airy** (cards, rows, sheets): comfortable padding, room to
  breathe — but density honest to the content. Over-padding makes the content disappear into white.
- **J-5.3 — Never mix densities on one surface.** A chrome-thin button inside a content card reads
  oversized; a content-padded chip in the top bar reads as a banner. Demote to the surface's density;
  never invent a third.

---

## J-6. Scarcity — the "one of" rules

The product's calm comes from scarcity. You get exactly one of each per screen/region:
- **J-6.1 — One primary action per visible region** (a region = a card, a sheet footer, the action bar).
  Two primaries is two competing asks; demote one to a ghost/secondary.
- **J-6.2 — One editorial/italic moment per hero** (J-3.6).
- **J-6.3 — One "selected/now" marker per screen** — the user is in one place at one time.
- **J-6.4 — One accent emphasis per surface** (J-2.4) — the accent is the door, not the door handle.
- **J-6.5 — One continuous motion at most** (J-9).

---

## J-7. Alignment — the invisible grid

- **J-7.1 — Left-align by default** — body, names, meta, lists, sheet content. Centering is reserved for
  the status bar and (rarely) a standalone hero block. Never center body prose or a list row.
- **J-7.2 — Numeric/mono columns right-align** inside their column (timestamps, counts) — the eye runs
  the right edge and reads the list in seconds.
- **J-7.3 — Text aligns on baseline; symbols align on optical center.** A two-up header row sits on the
  title's *baseline*, not box-center; an icon/dot in a meta line sits on the lowercase x-height, not the
  geometric middle.
- **J-7.4 — Concentricity & optical correction (the pro/amateur tell).** Nested shapes share a center;
  an inner control's corner radius relates to its container's (J-10.4). Center *mathematically*, then
  **nudge optically** where the eye demands it (a leading glyph, a triangular play mark sits ~1px right
  of true-center to look centered). This is the WWDC25 "concentric geometry" rule and it is what makes a
  layout feel resolved.

---

## J-8. Surface stacking & depth — paper, paper, glass

Three solid tones, one glass; stack additively.
- **J-8.1 — Cards live on the page, never on another card of the same tone** (an elevated card on an
  equal surface is invisible). Group with space + the section, not with a third surface.
- **J-8.2 — Sheets are solid, not glass** — only the *handle* is glass (chrome). The moment you're
  reading content, you're on a solid surface (J-0.1).
- **J-8.3 — Never stack glass on glass** — two translucent layers make both read as dishwater. A glass
  control that migrates into a glass bar drops its own glass and becomes a glyph button.
- **J-8.4 — Depth is restraint:** one elevation system (a rest shadow, a hero shadow, the glass shadow),
  used consistently. Reaching for a heavier shadow means the card wants to be a sheet. Shadow/blur express
  *hierarchy*, never decoration.

---

## J-9. Motion — considered, never bouncy

- **J-9.1 — Tap response ≤ 100ms.** The element commits (a ~0.985 press scale) *before* any animation
  plays. Delayed press states read as lag no matter how good the curve.
- **J-9.2 — One easing personality** — a shared critically-damped ease-out token; no per-component
  curves. Spring/overshoot is forbidden except as a single, scoped *reward* moment (a confirm tick).
- **J-9.3 — At most one continuous motion on screen** (e.g. a loading shimmer). Everything else has a
  clear start and end; looping motion elsewhere is noise.
- **J-9.4 — Transitions explain space** — a push/zoom carries a shared element so the user sees where
  they went. Motion that merely decorates is cut.
- **J-9.5 — Respect Reduce Motion** — durations halve, springs flatten to fades, continuous motion goes
  static. Non-negotiable.

---

## J-10. Borders & radii — the hierarchy

- **J-10.1 — The radius set is a ladder of meaning**, smallest (tags) → small (thumbnails) → medium
  (rows/wells) → large (cards/sheets-at-rest) → pill (chrome). Each reads as a tier.
- **J-10.2 — Chrome is pill; content is rounded-rect.** Pill = floats; rounded-rect = anchored. A
  pill-shaped card reads as a giant chip; a rounded-rect tab bar reads as a panel — wrong on both.
- **J-10.3 — When radii meet, the outer is larger** — inner corners look tighter on purpose so the eye
  reads the container.
- **J-10.4 — Borders are 1px `separator` by default.** Emphasis comes from shadow or color, never a
  thicker border.

---

## J-11. Voice & content — editorial, never alarmist

- **J-11.1 — Titles are sentences with a point, not labels** — *"Your shelf, sorted"* over *"Library."*
- **J-11.2 — Sub copy is specific numbers** — "12 books · 3 due this week," not "Several books."
- **J-11.3 — Actions lead with a present-tense verb the user owns** — "Borrow," "Return by Jun 1," not
  "Submit"/"Confirm."
- **J-11.4 — Numbers are digits** in pills/meta ("3 due"); spell out only in an editorial hero.
- **J-11.5 — No exclamation marks, no emoji, no alarm copy.** Not "Overdue!" — "Due 3 days ago" + the
  offer to renew. A question + an offer-of-help is the trust contract.
- **J-11.6 — Empty/▢ and error states get the same editorial care as the happy path** — a considered
  empty state is a craft signal (J-13), not an afterthought.

---

## J-12. Imagery & iconography

- **J-12.1 — A coherent icon set, one weight** — hairline geometric glyphs, optically corrected, rounded
  caps; no mixing filled and outline arbitrarily. (Default SF Symbols everywhere is a "generic iOS app"
  tell — J-13; a deliberate, consistent symbol choice is the craft.)
- **J-12.2 — Photos are contained content, not full-bleed banners** (except a deliberate hero). Contained
  imagery reads as content; full-bleed reads as marketing.
- **J-12.3 — Photo radii match their container** (J-10.3).
- **J-12.4 — A monochrome glyph placeholder, never a broken-image box,** when an image is absent.

---

## J-13. Craft & soul — the anti-slop rules

This is what separates "fine" from "beautiful," and a human-made app from generic AI output.
- **J-13.1 — Hierarchy in order of power: size → weight → color → whitespace.** Reach for the type scale
  before color or decoration. If two things look equally important, the design hasn't decided.
- **J-13.2 — Whitespace is the primary tool, not leftover.** Generosity confers importance and calm.
  **Density is the default failure mode** — a cramped screen is the first sign of missing craft.
- **J-13.3 — Have a point of view (J-0.5).** Generic system-font + system-blue + default everything is
  the failure. The reference slice ships an opinionated identity so screens inherit one. Beauty in 2026
  is "decisions only a human would make" — make some.
- **J-13.4 — Clarity over decoration.** Ask "does this reduce effort?", not "how do we make it
  exciting?" Don't decorate data; honest structure beats ornament.
- **J-13.5 — Finish is the bar, not the bonus.** The last 10% — icon weight, corner concentricity, a
  considered empty state, one delightful interaction — is what earns "beautiful." Budget for it.
- **J-13.6 — Run the slop catalog.** `08-slop.md` lists the specific patterns that mark a UI as
  AI-generated (side-tab borders, gradient text, the cream + italic-serif-hero reflex, overused fonts,
  hero-metric templates, em-dash/buzzword copy, …). It's a required reviewer pass. The test for any
  flagged element: *would a thoughtful human pick this for this app, or is it the move because it's the
  current default?* Three of our own choices (warm neutrals, an expressive display face, any gradient)
  sit near tells — so they must be **earned**, never reflexive (`08-slop.md`, final section).

---

## J-14. Anti-patterns — copy these into a reviewer's eye

- **AP-1** Glass on a card/row/sheet-at-rest (J-0.1).  · **AP-2** Glass stacked on glass (J-8.3).
- **AP-3** A literal value or raw primitive in a view (J-0.2).  · **AP-4** A fixed-pt font / fixed frame
  on text (J-0.3).
- **AP-5** The accent as a decorative card fill, or 3+ accent appearances (J-0.4, J-2.4).
- **AP-6** A heading in a softer ink (J-2.1).  · **AP-7** A third body ink (J-2.2).  · **AP-8** 4+ inks
  in a row (J-2.3).
- **AP-9** Mono used for body prose; display family on a button label (J-3.1).  · **AP-10** A 5th type
  size (J-3.2).
- **AP-11** A divider where space would do (J-4.2).  · **AP-12** Two primary actions in one region
  (J-6.1).
- **AP-13** Centered body prose (J-7.1).  · **AP-14** Two glass bars in a vertical stack (J-8.3).
- **AP-15** A bouncy/spring curve outside the one reward moment (J-9.2).  · **AP-16** Looping motion
  beyond the one continuous allowance (J-9.3).
- **AP-17** Pure white/black surfaces (J-2.5).  · **AP-18** Exclamation marks / alarm copy / emoji
  (J-11.5).
- **AP-19** A cramped, dense screen with no breathing room (J-13.2).  · **AP-20** Default SF Symbols +
  system-blue + system-font with no point of view (J-13.3).
- **AP-21** A throwaway empty/error state (J-11.6, J-13.5).  · **AP-22** Any tell from the slop catalog
  used as an unexamined default — side-tab border, gradient text/fill, glassmorphism-as-decoration,
  icon-tile-over-heading, hero-metric template, overused reflex fonts, em-dash/buzzword copy (J-13.6,
  `08-slop.md`).

---

## J-15. The 60-second review

Run before shipping any screen — ~5 seconds each:
1. **Squint** — does one thing dominate? If two compete, one is wrong (J-13.1).
2. **Whitespace** — does it breathe, or is it cramped? (J-13.2)
3. **Type sizes** — ≤ 4? (J-3.2)
4. **Accent** — ≤ 2 appearances, emphasis/state only? (J-2.4)
5. **Inks** — heading primary, body binary, ≤ 3 per row? (J-2.1–2.3)
6. **Primaries** — ≤ 1 per region? (J-6.1)
7. **Glass** — floating chrome only, no glass-on-glass? (J-0.1, J-8.3)
8. **Tokens** — no literals/primitives; on the gap ladder; 4pt grid? (J-0.2, J-1)
9. **Dynamic Type** — bump to the largest size; does it hold? (J-0.3)
10. **Alignment** — left-aligned text, right-aligned numerics, concentric shapes? (J-7)
11. **Motion** — tap ≤ 100ms, no springs outside the reward, Reduce-Motion degrades? (J-9)
12. **Voice** — read it aloud: no "Submit," no "!", specific numbers? (J-11)
13. **Empty/error** — as considered as the happy path? (J-11.6)
14. **Tap targets** — every control ≥ 44pt? (HIG)
15. **Point of view** — does this look like *our* app, or any app? (J-13.3)
16. **Slop scan** — run `08-slop.md`: no side-tab borders, no gradient text/fills, no glassmorphism-
    decoration, no reflex fonts, no hero-metric/icon-tile templates, no em-dash/buzzword copy. (J-13.6)

All sixteen pass → ship. Any fails → fix before review.

---

## What this doc does not cover

Token *values* (`01-typography`, `02-color`, `03-layout-spacing`), component *anatomy* (`05-components`),
motion *tokens* (`04-motion`), accessibility *specifics* (`07-accessibility`), the **slop catalog**
(`08-slop`), and the Swift *port* (`ios/docs/engineering/05-design-system.md`). Anything here is a
contract; anything not yet here is not yet decided — flag it in `docs/decisions.md` if it gets decided
implicitly.
