# Typography — the type system

Typography carries most of the beauty (`06-judgment.md` J-3; `ios/docs/engineering/05-design-system.md`
§11.3). This doc owns the **system**: the families, the semantic roles, the Dynamic Type scale and its
values, and the discipline (few sizes, few families) that keeps a screen calm. It does *not* make the
per-element calls — that is judgment (`06-judgment.md` J-3); and it does not restate the Swift port —
that is `ios/docs/engineering/05-design-system.md` §4. When in doubt about a value, this doc is the
contract; when in doubt about a choice, J-3 is.

Examples use the library/book reference slice (AppTemplate). It's a reusable template — the **rules** are
generic; swap the book specifics for your app.

---

## T-0. The non-negotiables

- **T-0.1 — Every text style is a Dynamic Type style.** No `Font.system(size: 17)` literals; no fixed
  frames on text containers. A hardcoded size is a review failure (J-0.3, `08-slop.md` H-4) — it defeats
  scaling, and scaling is free on system styles (Apple HIG Typography).
- **T-0.2 — Roles, not sizes.** Screens reference a *semantic role* (`Typography.title`, `.body`,
  `.mono`), never a point size or a raw text style. One mapping changes everywhere
  (`05-design-system.md` §4).
- **T-0.3 — ≤ 2 families, ≤ 3–4 sizes per screen** (T-3, T-4). The fifth size and the third family are
  the most common type bugs (`06-judgment.md` J-3.2; IxDF).
- **T-0.4 — One deliberate distinctive display face — not the reflex.** Generic system-font everywhere is
  no point of view; Inter / Instrument-Serif / Space Grotesk are the *AI* point of view. Pick neither
  (`08-slop.md` B-8, B-3; J-13.3). See T-7.
- **T-0.5 — Test at AX5; cap, never disable.** Support the full range; clamp only specific surfaces
  (T-8).

---

## T-1. Families — one role each

Four system designs cover every role for free (Dynamic Type, optical sizing, per-size tracking); custom
fonts get none of that unless wired up (Apple HIG Typography; WWDC20 10175). Pick by role, never mix
roles (J-3.1).

| Role | Family (system default) | SwiftUI | Used for | Never |
|---|---|---|---|---|
| **Display** | New York (serif) *or* a chosen distinctive face | `.system(design: .serif)` / `Font.custom(…)` | names, screen titles, hero numerals | button/chip labels, body prose |
| **UI** | SF Pro | `.system` (default) | body, chrome, button/chip labels, meta | hero numerals |
| **Mono** | SF Mono | `.system(design: .monospaced)` | timestamps, counts, IDs, dates, prices | running prose (`08-slop.md` B-10) |
| **Rounded** | SF Pro Rounded | `.system(design: .rounded)` | soft/playful marks (use sparingly) | as the body face |

- **T-1.1 — UI is the default.** If a role wasn't deliberately chosen, it's UI. The display face is a
  *decision* (T-7); rounded is rarely the right call for a reference/reading app.
- **T-1.2 — Mono is for measurement, aligned.** Fixed advance widths keep numbers vertically aligned in
  lists/tables. For a single inline numeral inside proportional text, use `.monospacedDigit()` rather
  than switching the whole run to mono (Apple HIG Typography).
- **T-1.3 — Two families on a screen, max.** A deliberate display+UI+mono *system* is the scoped
  exception — each role stays in its lane, never freely mixed (IxDF; `08-slop.md` B-9).

---

## T-2. Semantic type roles

Every screen references one of these names; each is backed by a Dynamic Type text style + weight, never a
raw size (Apple HIG Typography; WWDC20 10175). This is the full role set — collapse two before adding a
fifth (T-4).

| Role | Family | Text style · weight | Pt @ Large | Used for |
|---|---|---|---|---|
| `titleLarge` | Display | `.largeTitle` · Regular/Bold | 34 | screen hero title (one per screen) |
| `title` | Display | `.title2` · Semibold | 22 | section / card titles |
| `name` | Display *or* UI | `.headline` · Semibold | 17 | the item name in a row (book title) |
| `body` | UI | `.body` · Regular | 17 | running copy, primary row text |
| `callout` | UI | `.callout` · Regular | 16 | dense secondary copy |
| `subhead` | UI | `.subheadline` · Regular | 15 | meta lines, sub copy |
| `footnote` | Mono | `.footnote` · Regular | 13 | metadata, mono caps |
| `caption` | Mono | `.caption1`/`.caption2` · Regular | 12 / 11 | smallest meta, eyebrow caps |

- **T-2.1 — Hierarchy by ladder + weight, not arbitrary points.** Body and Headline are *both 17pt* and
  differ only by weight — Body Regular vs Headline Semibold (Apple HIG Typography table). Reach for the
  weight jump before a size jump (J-13.1).
- **T-2.2 — Derive emphasis from the role so it still scales:** `.bold()` / `.italic()` keep Dynamic Type
  (`Font.footnote.bold()` = 13pt Semibold; emphasized title = Bold) (WWDC20 10175). Never hand-pick a
  bigger size for "emphasis."

---

## T-3. The Dynamic Type scale (the 11 built-in styles)

Drive every size from these — never a hardcoded size (Apple HIG Typography). Default (Large) point sizes
and the baked-in leading (line height); each style also auto-adjusts tracking per size.

| Text style | Size (pt) | Leading (pt) | Weight (default) |
|---|---|---|---|
| `largeTitle` | 34 | 41 | Regular |
| `title1` | 28 | 34 | Regular |
| `title2` | 22 | 28 | Regular |
| `title3` | 20 | 24 | Regular |
| `headline` | 17 | 22 | Semibold |
| `body` | 17 | 22 | Regular |
| `callout` | 16 | 21 | Regular |
| `subheadline` | 15 | 20 | Regular |
| `footnote` | 13 | 18 | Regular |
| `caption1` | 12 | 16 | Regular |
| `caption2` | 11 | 13 | Regular |

(All values: Apple HIG Typography table; leading per WWDC20 10175.)

- **T-3.1 — Body floor is 17pt; smallest standard is 11pt.** Never render text below `caption2` 11pt.
  Footnote 13 and caption1 12 are for *secondary/meta* text only — not running prose (Apple HIG;
  `08-slop.md` H-4; J-3.4).
- **T-3.2 — Leading is baked in.** Adjust only ±2pt via `.leading(.tight)` / `.loose`; don't hand-tune
  `lineSpacing` otherwise (WWDC20 10175). Tight line height (< ~1.3×) is a slop tell (`08-slop.md` H-3).
- **T-3.3 — Optical size switches automatically at 20pt** — SF Text below, SF Display at 20pt+; with the
  variable SF Pro the transition is continuous 17–28pt and stays synced to point size. Never manually
  pick Text vs Display (WWDC20 10175; Apple HIG).
- **T-3.4 — Aim ~3:1 between hero and body** (`.largeTitle` 34 over `.body` 17) and pair the size jump
  with a weight jump so size isn't doing all the work (IxDF; Toptal).

---

## T-4. Few sizes, few families — the discipline

- **T-4.1 — At most four type sizes per screen:** title · name · body · footnote/mono (J-3.2). A fifth
  means you're over-designing — collapse two roles.
- **T-4.2 — At most two families per screen** (T-1.3).
- **T-4.3 — Nothing larger than the display size on a phone.** Oversized type reads as a marketing
  landing page, not an app (J-3.3; `08-slop.md` B-6). The scale is small on purpose.
- **T-4.4 — Flat hierarchy is a tell.** Sizes too close together with no clear dominant fail the squint
  test (`08-slop.md` B-1; J-13.1) — fix with size→weight→color→space, in that order.

---

## T-5. Tracking — size-specific, system-supplied

Tracking is inverse to size and the system sets it per size; never apply one global letter-spacing value
across sizes (WWDC20 10175; Apple HIG tracking tables; learnui.design).

| Size | System tracking | (% of size) |
|---|---|---|
| 17pt body | ≈ −0.43pt | −2.5% |
| 15pt secondary | ≈ −0.24pt | −1.6% |
| 13pt tertiary | ≈ −0.08pt | −0.61% |

(learnui.design iOS Font Guidelines; HIG tables run ~+41 at 6pt down to 0 at 80pt+.)

- **T-5.1 — Let the system supply it; if you must customize, use `.tracking(_:)`** (semantic, size-aware)
  — **not `.kerning()`** (WWDC20 10175).
- **T-5.2 — Loose tracking only on short mono-caps eyebrows;** body and UI stay at system tracking
  (J-3.5). Wide tracking on body is a slop tell (`08-slop.md` H-5, > ~0.05em).
- **T-5.3 — Never crush tracking** until glyphs lose their shapes (`08-slop.md` B-7). For long strings
  that would overflow, use `.allowsTightening(true)` (UIKit `allowsDefaultTighteningForTruncation`) so
  the run tightens before truncating, rather than dropping to an off-scale size (WWDC20 10175).

---

## T-6. Scalable custom fonts & non-text metrics

If you adopt a distinctive display face (T-7), wire it to scale — a custom font does **not** get Dynamic
Type for free (Apple HIG Typography).

- **T-6.1 — Register to a text style** with `Font.custom(_:size:relativeTo:)`, e.g.
  `Font.custom("Fraunces", size: 34, relativeTo: .largeTitle)`. Without `relativeTo` it scales only off
  `.body`; `.custom(_:fixedSize:)` opts *out* of scaling entirely — never use it for text (WWDC20 10175;
  useyourloaf).
- **T-6.2 — In UIKit/bridging**, scale via `UIFontMetrics(forTextStyle:).scaledFont(for:)` and set
  `adjustsFontForContentSizeCategory = true` (WWDC20 10175; useyourloaf).
- **T-6.3 — Register fonts at launch** (`FontRegistry.registerEmbeddedFonts()`,
  `01-architecture.md` §4); a missing font falls back to the system equivalent of the same role
  (`05-design-system.md` §4).
- **T-6.4 — Scale non-text metrics with `@ScaledMetric`**, never a fixed `CGFloat`:
  `@ScaledMetric(relativeTo: .body) var coverSize: CGFloat = 56` (must be `var`). Pin to the adjacent
  text style so icon sizes, paddings, and thumbnail frames grow with text and layouts don't break at
  large sizes (WWDC20 10175; avanderlee). For arbitrary CGFloats in UIKit:
  `UIFontMetrics.default.scaledValue(for:)`.

---

## T-7. The distinctive display face — point of view, earned

A screen must have a point of view (J-0.5, J-13.3). Generic system-font + system-blue + defaults is the
failure mode — but so is the reflex distinctive face. The expressive display face is the lever; spend it
deliberately.

- **T-7.1 — Pick *one* distinctive display face**, paired with the SF Pro body/UI and SF Mono numerals
  (the reference slice uses Fraunces for display — an optical-size variable serif with real range, not a
  reflex pick). One distinctive face, a refined body face, mono for measurement (`08-slop.md` B-8, B-9;
  J-13.3).
- **T-7.2 — Steer away from the AI tells:** Inter / Geist / Space Grotesk / Instrument Serif everywhere,
  and the giant centered italic-serif hero, are the *current* AI default — they signal "no decision"
  (`08-slop.md` B-3, B-8). The test (J-13.3): *would a thoughtful human pick this exact face for this
  exact app, or is it the move because it's the tasteful reflex?*
- **T-7.3 — Italic / the expressive cut is one editorial moment per hero** (J-3.6, `06-judgment.md`).
  Used for the product's *voice* — a single hero title, an empty-state line — never sprinkled on single
  words. Two expressive moments in one hero is a bug, and the unearned italic-serif hero is the tell
  (`08-slop.md` B-3).
- **T-7.4 — Display owns names and hero numerals, never button labels** (T-1; J-3.1). A display family on
  a chip/button reads as decoration.

---

## T-8. Dynamic Type range & testing

- **T-8.1 — Support the full range.** iOS 18+ ships 12 sizes — 7 standard (xSmall–xxxLarge) + 5
  accessibility (AX1–AX5); body reaches ~310% at AX5 (Apple HIG Typography).
- **T-8.2 — Test at AX5.** Bump to the largest size in the 60-second review (J-15.9); verify no
  truncation, overlap, or clipped containers. `@ScaledMetric` (T-6.4) is what keeps layouts intact there.
- **T-8.3 — Cap, never disable.** Clamp only specific surfaces where layout truly breaks
  (`.dynamicTypeSize(...DynamicTypeSize.accessibility1)`) — clamp the *minimum* of the range, never turn
  scaling off globally (Apple HIG Typography; Hacking with Swift).
- **T-8.4 — Keep a readable measure** — roughly 50–75 characters per line. A 390pt iPhone column
  satisfies this for body; widen safe-area / `contentMargins` on `.regular` width (iPad, landscape) so
  text doesn't run edge-to-edge (Apple HIG Typography; `08-slop.md` D-6). Left-align body (J-7.1); never
  justify without hyphenation (`08-slop.md` H-6).

---

## See also

- `06-judgment.md` — J-3 (typography calls), J-13.1 (hierarchy order), J-15 (the 60-second review)
- `08-slop.md` — §B (typography tells), B-3/B-8 (the reflex-font cautions)
- `02-color.md` — text-color roles (`textPrimary`/`textSecondary`) that pair with these type roles
- `03-layout-spacing.md` — the gap ladder + `@ScaledMetric` spacing that scales alongside type
- `07-accessibility.md` — Dynamic Type a11y specifics, contrast for text roles
- `ios/docs/engineering/05-design-system.md` §4 — the Swift port (semantic type roles, `Font.custom`
  `relativeTo`, `@ScaledMetric`, `FontRegistry`)
