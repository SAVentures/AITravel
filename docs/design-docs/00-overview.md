# 00 — Visual Design Overview

The prescriptive **visual language** for the v2 native app — the judgment that makes a SwiftUI screen
*beautiful*, not merely correct. **Read this first**, then `06-judgment.md` (the crux), then the topic
doc your task needs, then `08-slop.md` before you ship.

This set answers **what a screen should *look* like**. It is distinct from — and pairs with —
`ios/docs/engineering/`, which owns how the app is **built**. A screen that "uses the tokens" passes
engineering; a screen that earns *beautiful* passes this set. Both gates are required.

Examples use the **library / book-management** reference slice (`AppTemplate`). The slice is illustrative;
the **rules** are the reusable template — swap the domain specifics for your app.

---

## The authority split — who owns what

Three trees, one contract. When two disagree, the artifact and its prose move together; neither is
canonical alone.

| Tree | Owns | Authority |
|---|---|---|
| **`docs/design-docs/`** (this set) | the **LOOK** — visual judgment: type, color, layout, motion, component anatomy, the craft bar, the anti-slop catalog | the prescriptive visual language |
| **`ios/docs/engineering/`** | the **BUILD** — architecture, store, networking, the Swift design-system port, the four-layer test pyramid | how it's implemented |
| **`mockups/foundations.css`** | the **TOKEN VALUES** — colors, type scale, spacing, radii, motion | source of truth; Swift primitives are **codegen'd** from it (never re-typed) — `engineering/05-design-system §2` |

This set hands its judgment to two engineering gates: the **foundation-freeze** (design system locked +
design-reviewed before any screen is built — `engineering/05 §10`) and the **fidelity-reviewer** (each
screen reviewed against its named mockup, then snapshot-locked — `engineering/06 §9`).

---

## The visual non-negotiables

Domain-agnostic. These restate `06-judgment.md` **J-0** and the corpus's cross-cutting findings; they
govern everything in the topic docs. Break one only with a written entry in `docs/decisions.md`.

1. **Glass on floating chrome only.** The system Liquid Glass material (`glassEffect` / `.buttonStyle(.glass)`),
   on the navigation layer only — tab/top/action bars, sheet handle, floating controls. Never on cards,
   rows, sheets-at-rest, or content; never stacked glass-on-glass. (J-0.1, `04-motion`/`05-components`)
2. **Design values from *semantic* tokens only.** No literal color/size/spacing in a view; never a raw
   primitive. A literal is a review failure. (J-0.2, `02-color`, `03-layout-spacing`)
3. **Dynamic Type, always.** Every text style scales; no fixed-pt fonts, no fixed frames on text. Holds
   to AX5. (J-0.3, `01-typography`, `07-accessibility`)
4. **One accent, used sparingly.** It marks the one thing that matters on a surface (primary action,
   selected/now state) — at most twice per screen. Never a decorative card fill, never chrome. (J-0.4, `02-color`)
5. **Restrained motion.** Critically-damped ease-out, one easing personality, **at most one continuous
   motion** on screen, tap response ≤100ms, Reduce Motion degrades. No springs outside one scoped reward.
   (J-9, `04-motion`)
6. **Have a point of view — then run the slop scan.** Lean on the system, add **one deliberate signature**
   (a type pairing, a signature color, a signature motion); generic system-font + system-blue + defaults
   is the failure. Every flagged choice (warm neutrals, an expressive face, any gradient) must be *earned*,
   never reflexive. (J-0.5, J-13.3, `08-slop`)

---

## Doc index

| Doc | Owns (one line) |
|---|---|
| **`00-overview`** (this) | the authority split, the visual non-negotiables, the 5 principles, reading order, how to add a screen |
| **`01-typography`** | family-per-role (display / UI / mono), the size + tracking + line-height scale, Dynamic Type mapping, the one editorial moment |
| **`02-color`** | the semantic color roles + neutral ramp, the single accent and its budget, warm-tinted neutrals, contrast |
| **`03-layout-spacing`** | the 4/8pt grid, the gap ladder, radii ladder + concentricity, safe areas, surface stacking & depth |
| **`04-motion`** | the easing personality + duration ladder, the one-continuous-motion rule, tap ≤100ms, springs-for-direct-manipulation, Reduce Motion |
| **`05-components`** | component anatomy — rows, cards, buttons/chips, bars, sheets — and the glass-on-chrome rules in practice |
| **`06-judgment`** | **the crux** — the J-rules, J-0 non-negotiables, anti-patterns, the 60-second review; cite it in review |
| **`07-accessibility`** | WCAG AA, VoiceOver labels/traits/headings, tap targets, Dynamic Type range, Reduce Motion/Transparency |
| **`08-slop`** | the anti-slop catalog — the AI-generated tells to avoid; a required reviewer pass alongside J-15 |

---

## Reading order

`00` (this) → **`06-judgment`** (always — it's the central doc) → the **topic docs** your screen needs
(`01`–`05`, `07`) → **`08-slop`** before shipping. The **plan-writer** and **design-reviewer** read the
whole set.

---

## How to add a screen

1. Read `00` (this) → `06-judgment` → the topic docs for the components you're placing (`01`–`05`,
   `07` for any new affordance).
2. Port from the screen's **named mockup** — copy the markup intent, don't reinvent.
3. The screen is gated twice on the engineering side: **foundation-freeze** (design system locked +
   design-reviewed, `engineering/05 §10`) must be passed *before* the screen is scaffolded, and the
   **fidelity-reviewer** (`engineering/06 §9`) reviews the rendered screen against its mockup, then
   snapshot-locks it.
4. Before review, run the **60-second review** (`06-judgment` J-15) **and** the **slop scan** (`08-slop`).
   All sixteen pass + no tells → ship. Any fail → fix first.
5. Log any non-obvious call in `docs/decisions.md` (append-only — new entries supersede, never edit).

---

## The five principles

Apple's three, plus two we add and weight equally:

- **Clarity.** Type, color, and space do the work; one thing dominates each surface (J-13.1). Clarity over
  decoration — ask "does this reduce effort?", not "is this exciting?" (J-13.4)
- **Deference.** Content leads; chrome recedes. Lean on the system material, system controls, and the
  built-in text styles rather than re-rolling them.
- **Depth.** One restrained elevation system — paper, paper, glass — expresses hierarchy, never
  decoration. Motion explains space.
- **Craft / point of view** *(ours)*. A deliberate identity — the signature the system inherits — and the
  last-10% finish (icon weight, corner concentricity, a considered empty state) that earns *beautiful*.
  This is the antidote to slop. (J-13.3, J-13.5, `08-slop`)
- **Restraint** *(ours)*. Scarcity is the product's calm: one primary per region, one accent per surface,
  one editorial moment per hero, one continuous motion. Whitespace is the primary tool, not leftover.
  (J-6, J-13.2)
