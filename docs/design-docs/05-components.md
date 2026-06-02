# 05 — Components

The component inventory: what each one **looks like**, the **states** it must render, how it's **sized**,
and — when two could work — **which to pick**. This doc owns component *appearance, anatomy, and
selection*. It does **not** own shell wiring (when the tab bar shows, how a screen declares its chrome,
the sheet-vs-push routing) — that is `ios/docs/engineering/06-screens.md §2`. The split is sharp:
**06-screens decides when a component appears in the shell; this doc decides how it looks once it's
there.** Token *values* live in `01-typography` / `02-color` / `03-layout-spacing`; the J-rules that
govern all of this live in `06-judgment`. Examples use the library / book reference slice — swap the
domain nouns, keep the rules.

Two load-bearing constraints carry through every component below:

- **Glass is a system material, on floating chrome only.** Bars, the bottom `ActionBar`, sheet handles,
  map-overlay chips — never cards, rows, sheets-at-rest, or anything holding primary input (`J-0.1`,
  `J-8`). Reach for the system `glassEffect` / `.buttonStyle(.glass)`, never a hand-rolled translucency
  ("Liquid Glass goes only on the floating navigation layer … never on lists, tables, cards, media",
  createwithswift/letsdev).
- **Every interactive control gets a 44×44pt hit target** — pad the touch area even when the glyph is
  smaller; inline text links are the only common exception (Apple HIG / LogRocket).

Every component renders the **six canonical states** where they apply — *default · pressed · disabled ·
selected · loading · empty* — and ships a render snapshot per meaningful state
(`05-design-system.md §8`, `07-testing.md §6`). Read `configuration.isPressed` from a `ButtonStyle` (not
a gesture) so the press commits in ≤100ms (`J-9.1`); read `.disabled()` from the environment, never a
hand-dimmed color (avanderlee).

---

## 1. Buttons

Pick the button by **hierarchy tier, not by look** — the style follows from "is this *the* action, a
secondary one, or inline?" (avanderlee). One prominent button per context (`J-6.1`).

| Tier | SwiftUI style | Shape | Use | Book example |
|---|---|---|---|---|
| **Primary** | `.borderedProminent` / `.glassProminent` (in a glass bar) | capsule | the one action that matters in a region | **Borrow** in the `ActionBar` |
| **Secondary** | `.bordered` / `.glass` (in a glass bar) | capsule | a real but lesser action beside the primary | **Preview** next to Borrow |
| **Ghost / tertiary** | `.plain` / `.borderless` | text, no fill | low-stakes / inline | **See all** on a section header |
| **Destructive** | `Button(role: .destructive)` | inherits tier | irreversible / removing | **Remove from shelf** |

**Rules**

- **1.1 — Tier maps to style, never the reverse.** `.glass`/`.glassProminent` require iOS 26 + Xcode 26
  and only appear *inside floating chrome* (the bars, the `ActionBar`); a button on a card or in a sheet
  body uses `.borderedProminent`/`.bordered`, **not** glass (`J-0.1`; avanderlee/conorluddy).
- **1.2 — Destructive is `role: .destructive`, not a hand-colored red button.** The system renders it red
  and announces the intent to assistive tech; pair with `role: .cancel` in a confirmation dialog. Never
  fake destructive semantics by tinting (avanderlee). Red is the *only* place red appears — it is a state
  signal, not chrome (`J-2`).
- **1.3 — One accent, one prominent button per region** (`J-2.4`, `J-6.1`). The primary CTA is the
  accent's budgeted appearance; a second prominent button in the same region is two competing asks —
  demote one to `.bordered`/ghost.
- **1.4 — Shape & size are tokens, not frames.** Set shape with `buttonBorderShape` (`.capsule` for
  content buttons, `.circle` for bar glyph buttons, `.roundedRectangle(radius:)` rarely) and size with
  `controlSize` (`.mini`…`.extraLarge`) — never a hardcoded `.frame(width:…,height:48)`, which breaks at
  large Dynamic Type (avanderlee; `J-0.3`, `05-design-system.md §5`). Pill = floats/CTA; chrome glyphs =
  circle (`J-10.2`).
- **1.5 — Label leads with a present-tense verb the user owns** — "Borrow", "Return by Jun 1", never
  "Submit"/"Confirm" (`J-11.3`).

### 1.1 iOS 26 Liquid Glass circle buttons (in bars)

The glyph buttons that float in nav bars, toolbars, and overlay chips. In iOS 26 these are **circular
Liquid Glass capsules** — a single SF Symbol on the system glass material.

- **Anatomy:** one SF Symbol, optically centered, on `.glass`; `buttonBorderShape(.circle)`; 44×44pt hit
  target even when the glyph is ~17–20pt.
- **Selection:** `.tint(_:)` *only to convey meaning* — a selected/active glyph carries the accent;
  tinting every glyph destroys the signal (conorluddy; `J-2.4`).
- **Grouping:** multiple bar buttons share one `GlassEffectContainer` so they blend correctly; split
  logical groups with `ToolbarSpacer(.fixed/.flexible)` so the capsules don't merge into one blob (Swift
  with Majid). **Never stack glass on glass** — a glass button migrating into a glass bar drops its own
  glass and becomes a plain glyph (`J-8.3`; conorluddy).
- **`.interactive()`** (`.glassEffect(.regular.interactive())`) only on touch-responsive glass — it adds
  the touch-point illumination / subtle scale; never on static decorative glass (conorluddy).

### Button states

| State | Treatment |
|---|---|
| **default** | tier fill/stroke at rest |
| **pressed** | `configuration.isPressed` → ~0.985 press scale, commits ≤100ms, *before* any animation (`J-9.1`) |
| **disabled** | `.disabled()` env → reduced-emphasis fill + `textTertiary` label; no tap; still announced |
| **selected** | (toggle/segment use) accent `.tint`; pair the color with a glyph/state mark, never color alone (`07-accessibility`) |
| **loading** | swap the label for an inline `ProgressView`, keep the button's footprint stable (no reflow), disable input |
| **empty** | n/a (a button is never empty; if there's no action, don't render the button) |

---

## 2. The bottom `ActionBar` (thumb-zone CTA)

The screen's primary action, pinned in the bottom thumb zone — the reachable place for a CTA on a large
phone (iOS 26 moved search and primary actions to the bottom across Messages/Mail/Notes/Safari;
AllThings.How/SavvyWithTech). This doc owns its *look*; **when** a screen supplies one is
`06-screens.md §2.4`.

- **When to use:** the screen has a primary action — `Borrow`, `Return`, `Save`. One primary, optionally
  one secondary beside it; more than that means the screen is doing too much (`06-screens.md §2.4`,
  `J-6.1`).
- **Anatomy:** a glass bar floating above the tab bar (or alone on a `.detail`/`.immersive` screen),
  holding a `.glassProminent` primary (+ optional `.glass` secondary), grouped in a
  `GlassEffectContainer`. The bar is **glass** (floating chrome, `J-0.1`); content scrolls *under* it
  with the iOS 26 scroll-edge effect (`06-screens.md §2.1`).
- **Density is chrome-thin** — tight vertical padding, the bar hosts an action and recedes; never
  content-padded (`J-5.1`, `J-5.3`).
- **`ActionBar` vs `tabViewBottomAccessory`:** the `ActionBar` is **per-screen** (this screen's CTA, gone
  when you leave); `tabViewBottomAccessory` is **app-global** (a now-playing strip, a global search —
  persists across tabs). Same thumb zone, different lifetime (`06-screens.md §2.4`; Donny Wals).

| State | Treatment |
|---|---|
| **default** | prominent glass CTA at rest |
| **pressed** | press scale on the button, ≤100ms (`J-9.1`) |
| **disabled** | CTA disabled when the action isn't available (e.g. already borrowed) — dimmed, still present |
| **loading** | inline `ProgressView` in the CTA during the async write; the optimistic store update usually makes this brief (`03-store.md`) |
| **selected / empty** | n/a — the bar is present only when there's an action to take |

---

## 3. Cards

A **content surface** — a self-contained unit of real data (a featured book, a shelf summary). Cards
carry the most weight to get wrong; the anti-slop catalog flags more card tells than anything else
(`08-slop.md §A/§D`).

- **When to use:** a discrete, tappable-or-not unit that benefits from its own surface — *not* a list of
  homogeneous rows (use rows, §4), and *not* a wrapper around a single value (use a section + type).
- **Anatomy:** `surfaceElevated` fill on the page, `Radius.card` corners (medium-large, **12–16pt** —
  24pt+ on a small card reads as AI; `08-slop.md A-6`), `Spacing.cardInset` (16pt) internal padding,
  optional thumbnail, a title in the display family, meta in the UI/mono family. Content left-aligned
  (`J-7.1`).
- **Sizing:** content + Dynamic Type drive height; no fixed frame (`J-0.3`). Internal padding ≤ the gap
  to the next card (`Spacing.sectionGap`) so cards read as separate, not merged (`J-1`; Cieden
  internal ≤ external).

**Hard rules (these are the common card tells):**

- **3.1 — Never nested.** A card lives on the page, never on another card of the same tone (an elevated
  card on an equal surface is invisible, *and* cards-in-cards is a flagged AI tell). Group with space +
  the section, not a third surface (`J-8.1`, `08-slop.md D-4`).
- **3.2 — Never a side-tab accent border.** A thick colored stripe on one edge is "the most recognizable
  tell of AI-generated UIs." Emphasis comes from space, type weight, and one accent *mark* — never a
  colored stroke fighting the radius (`08-slop.md A-1/A-2`, `J-2.4`, `J-10.4`).
- **3.3 — Never glass.** Glass is floating chrome; a card is resting content (`J-0.1`, `08-slop.md A-3`).
- **3.4 — One elevation, not a glow.** A card is *either* a 1px `separator` border *or* one rest shadow —
  never a hairline + wide diffuse shadow together (`J-8.4`, `08-slop.md A-4`). Borders are 1px `separator`
  (`J-10.4`).
- **3.5 — Don't make identical card grids.** Repeating same-sized icon+heading+text cards, or the
  hero-metric (big number + three stats + gradient) template, reads as slop — vary by content importance
  (`08-slop.md D-1/D-2`, `J-13.1`).
- **3.6 — No icon-tile-over-heading.** The small rounded-square icon container stamped above every card
  title is a universal AI tell; if an icon belongs, integrate it inline (`08-slop.md B-2`).

| State | Treatment |
|---|---|
| **default** | resting surface |
| **pressed** | if tappable, whole-card ~0.985 press scale, ≤100ms; otherwise no press state |
| **disabled** | rare for a card; if a card's action is unavailable, disable the action, not the card |
| **selected** | a single accent mark (a leading dot / a checkmark), never an accent fill or border (`J-2.4`) |
| **loading** | a redacted/placeholder card (`.redacted(reason:.placeholder)`) at the same footprint — one shimmer at most (`J-9.3`) |
| **empty** | a card with no data is not rendered; an empty *region* gets the considered empty state (§9) |

---

## 4. List rows

The workhorse for homogeneous, scannable collections (a shelf of books, settings). Use rows — not cards —
when items repeat and the eye should *scan* (`J-4.1`).

- **Anatomy:** leading thumbnail/glyph (optional) → a primary line + a secondary line → a trailing
  accessory. **Primary text 17pt** (body), **secondary 15pt** (subheadline), captions 13pt often at
  reduced opacity — **never below 11pt** even at the smallest Dynamic Type (learnui.design, Apple HIG;
  `J-3.4`).
- **Inks are binary:** primary line `textPrimary`, everything else `textSecondary`; at most three inks in
  a row including one state mark (`J-2.2`, `J-2.3`). Left-align text; right-align any numeric/mono column
  (counts, due dates) so the eye runs the right edge (`J-7.1`, `J-7.2`).
- **Sizing:** `Spacing.cardInset` (16pt) vertical padding; the whole row ≥ **44pt** tall as a tap target
  (Apple HIG). Height follows content + Dynamic Type — no fixed row height (`J-0.3`).

**Trailing accessory = the row's behavior contract** (don't mismatch; learnui.design iOS 26 list cells):

| Accessory | Means | Book example |
|---|---|---|
| **chevron** (`chevron.right`) | drills into a child (push) | book row → book detail |
| **checkmark** | selected, in a choosing context | picking a shelf to move into |
| **switch** (`Toggle`) | toggles state in place | "Available for loan" |
| **inline text button** | a discrete action on the row | "Return" |

- **4.1 — A chevron means navigation.** Never show a chevron on a row that doesn't drill in
  (learnui.design); never a switch on a row that navigates.
- **4.2 — Combine the row for VoiceOver** (`.accessibilityElement(children: .combine)`) so it's one stop,
  not five (`07-accessibility`; Hacking with Swift).
- **4.3 — Dividers only when rows truly need a scan partition** — prefer space; one 1px `separator`,
  never a thicker line (`J-4.1`, `J-4.3`).

| State | Treatment |
|---|---|
| **default** | row at rest |
| **pressed** | full-row highlight (system list selection or ~0.985 scale), ≤100ms (`J-9.1`) |
| **disabled** | `textTertiary` content, accessory hidden/inert, no tap |
| **selected** | trailing **checkmark** (choosing context) — color + glyph, never color alone (`07-accessibility`) |
| **past / done** | opacity + a glyph shift, **never strikethrough** (the consolidated past-state rule) |
| **loading** | redacted rows at the real footprint; one shimmer (`J-9.3`) |
| **empty** | the *list* shows the empty state (§9); a single empty row is not a thing |

---

## 5. Chips & tags

Small, capsule-shaped labels for status, category, or filter. Two registers — **tags** (read-only:
"Borrowed", "Due Jun 1") and **filter chips** (interactive, selectable).

- **Anatomy:** capsule (`buttonBorderShape(.capsule)`), a short label in the UI family (mono only for a
  measurement like a date/count), optional leading glyph at `Spacing.paired` (8pt) from the label. Caps
  reserved for short mono eyebrows, never sentence text (`J-3.5`, `08-slop.md B-10`).
- **Sizing:** content-hugging; interactive chips still meet 44pt in the tap dimension via padding even if
  the visual capsule is shorter (Apple HIG).
- **5.1 — A tag carries state via one accent mark or a neutral fill** — never a side-border, never a
  gradient fill (`J-2.4`, `08-slop.md A-1/C-1`). Pair any color-coded status with the label text so it
  survives color-blindness (`07-accessibility`).
- **5.2 — Pill radius is for chips and buttons only** — a card or row is rounded-rect, not pill
  (`J-10.2`).

| State | Treatment |
|---|---|
| **default** | neutral capsule (tag) / unselected outline (filter chip) |
| **pressed** | filter chip: ≤100ms press scale |
| **disabled** | `textTertiary` label, muted fill |
| **selected** | filter chip: accent fill or accent stroke + a check glyph; one selected marker per group |
| **loading / empty** | n/a — a chip with no value isn't rendered |

---

## 6. Sheets

A subordinate, dismissible task surface (borrow-confirm, edit, filter, picker, peek). **When** to choose
a sheet vs. push vs. cover is the decision rule in `06-screens.md §2.5`; this is how it *looks*.

- **Anatomy:** detents drive height — `.presentationDetents([.medium, .large])` (`.medium` ≈ half,
  `.large` = full; custom via `.fraction(_:)`/`.height(_:)`); the system shows the **grabber** automatically
  at 2+ detents, override with `.presentationDragIndicator` (nilcoalescing, Apple). A task sheet carries a
  header with **Cancel / Done**; a peek can be grabber-only.
- **6.1 — A sheet at rest is solid, not glass.** Only the *grabber* (chrome) reads as glass; the moment
  you're reading sheet content you're on a solid `surface` (`J-0.1`, `J-8.2`; `08-overlays`). This is a
  non-negotiable — glass-on-content is the prior app's mistake.
- **6.2 — A sheet is one surface** — no inner dividers cutting it into mini-cards, no cards nested inside
  it; group with space (`J-4.2`, `J-8.1`). Left-aligned content (`J-7.1`).
- **6.3 — Always an obvious, safe exit** (explicit **Done** + **Cancel**); if Cancel would discard edits,
  confirm via a dialog before dismissing — don't trap swipe-to-dismiss on unsaved changes (Apple HIG
  Modality). Keep the task short — "don't build an app within your app."
- **6.4 — Errors in a sheet are the store's `writeError` banner, never a toast or a nested alert**
  (`06-screens.md §6`).

| State | Treatment |
|---|---|
| **default** | solid surface at the chosen detent, grabber visible |
| **pressed** | applies to the controls inside, per their component |
| **disabled** | **Done** disabled until the form is valid; the sheet stays open |
| **loading** | inline `ProgressView` on the confirming control; the sheet footprint stays stable |
| **empty** | a picker/filter sheet with no options shows the considered empty state (§9), not a blank sheet |

---

## 7. The bars (nav · tab · toolbar)

The floating chrome. This doc covers their **appearance**; their show/hide behavior, large-vs-inline
timing, and tab-bar ownership are `06-screens.md §2.2–2.4` — **not duplicated here**.

- **Nav bar.** Large title (34pt bold) at a tab root, collapsing to an inline 17pt semibold centered
  title on scroll; glass/blur background; back chevron labeled with the *parent's* title, never generic
  "Back" (learnui.design, Frank Rausch). Carries **title + back only** — never a primary action (those go
  in the `ActionBar`); at most one secondary `•••` control top-right (`06-screens.md §2.3`).
- **Tab bar.** 3–5 stable **destinations** ("places", nouns) — Library · You — never actions (no +, Scan,
  Create) (Medium design-bootcamp). iOS 26: an inset (~21pt from edges) floating Liquid Glass capsule,
  ~11pt labels, that can compact to the active tab on scroll-down and re-expand on scroll-up
  (learnui.design). A `.search`-role `Tab` floats bottom-right, separated by glass (Donny Wals).
- **Toolbar.** `ToolbarItem` placement auto-applies glass — `.confirmationAction` → `.glassProminent`,
  cancellation/primary get matching glass; split groups with `ToolbarSpacer(.flexible/.fixed)` so capsules
  don't merge (Swift with Majid).

**Rules**

- **7.1 — All three are glass, all are floating chrome** (`J-0.1`). Let the system supply it — don't add
  custom backgrounds; remove them (`.scrollContentBackground(.hidden)`, `.containerBackground(.clear,
  for: .navigation)`) and let content scroll under the glass (conorluddy).
- **7.2 — Never two glass bars stacked in a vertical run** that would put glass over glass (e.g. a custom
  bottom toolbar *and* the tab bar). One floating layer per zone (`J-8.3`, `AP-14`; Medium
  design-bootcamp).
- **7.3 — Chrome density is thin** (`J-5.1`): small glyphs, tight padding; the bar hosts a target and
  disappears.
- **7.4 — Tinting on a bar conveys meaning only** — a selected tab, an active control. Tint everything and
  the signal is gone (conorluddy, `J-2.4`).
- **7.5 — Glass accessibility is the system's job** — Reduce Transparency adds frosting, Increase Contrast
  adds borders; read the environment to verify, don't override, and still hold legible text contrast on
  the solid layer behind glass (`07-accessibility`; conorluddy/letsdev).

| State | Treatment |
|---|---|
| **default** | glass at rest, content scrolling beneath |
| **selected** (tab) | active tab glyph filled + accent `.tint`; one selected tab |
| **pressed** | bar button press, ≤100ms |
| **disabled** | a bar control unavailable → dimmed glyph, inert |
| **loading / empty** | n/a — bars are persistent chrome |

---

## 8. Component selection — the decision guide

When two components could carry the same content, pick by intent:

| Question | Answer | Pick |
|---|---|---|
| Is this a *child of what I'm viewing* (list → detail)? | yes | **push** (chevron row → detail) |
| Is it a *side task I finish and dismiss* (confirm, edit, filter, peek)? | yes | **sheet** |
| Does it *need to own the screen* (onboarding, capture, blocking)? | yes | **full-screen cover** |
| Are the items *homogeneous and meant to be scanned*? | yes | **list rows** (§4) |
| Is it *one self-contained unit of rich data* worth its own surface? | yes | **card** (§3) |
| Is this *the* action in the region? | yes | **primary button** (`.glassProminent` in the `ActionBar`) |
| Is it a *real but lesser* action? | secondary | **`.bordered`/`.glass` button** |
| Is it *low-stakes / inline* (a "See all", a row's link)? | yes | **ghost button / link** (`.plain`) |
| Is it *irreversible / removing*? | yes | **`role: .destructive`** (system red) |
| Does it *float over content* (a bar, the `ActionBar`, an overlay chip)? | yes | **glass**; everything else is **solid** |

**Tie-breakers**

- **Card vs row:** one rich unit → card; many homogeneous units → rows. A "card list" of identical cards
  is a slop tell (`08-slop.md D-2`) — those want to be rows.
- **Button vs link:** a committed action → button; navigating to more of the same content, or an inline
  "learn more" → a `.plain` link. Don't style a navigation link as a prominent button.
- **Sheet vs push:** "child of this?" → push; "detour I'll finish and leave?" → sheet; "needs to own the
  screen?" → cover (`06-screens.md §2.5`).

---

## 9. Empty & error states (every component earns one)

An empty or error state gets **the same editorial care as the happy path** — a considered empty state is
a craft signal, not an afterthought (`J-11.6`, `J-13.5`).

- **Empty:** a monochrome glyph placeholder (never a broken-image box, never a stock illustration), one
  editorial line of specific copy, and the one offered action. "No books on this shelf yet" + **Add a
  book**, not a blank region (`J-12.4`, `08-slop.md G-1`).
- **Error:** surfaced as the store's `writeError` **banner** the screen reads — never a toast, never an
  OK-only alert (`06-screens.md §6`; Apple HIG Modality). Copy is a question + an offer of help, no
  exclamation marks, no alarm (`J-11.5`).
- **Loading:** redacted placeholders at the real footprint with **at most one** shimmer on screen
  (`J-9.3`); never a layout that reflows when data arrives.

---

## See also

- `01-typography` · `02-color` · `03-layout-spacing` · `04-motion` — the token *values* every component
  consumes (this doc references roles, not numbers).
- `06-judgment` — the J-rules that govern selection, density, scarcity, surfaces, radii, motion (cite
  both: e.g. "card never nested, `J-8.1` / §3.1").
- `07-accessibility` — 44pt targets, Dynamic Type, contrast, VoiceOver labels/traits, never-color-alone.
- `08-slop` — the component tells this doc steers away from (side-tab border, nested cards, identical
  card grids, icon-tile-over-heading, hero-metric template, glassmorphism-as-decoration).
- `ios/docs/engineering/05-design-system.md` — the Swift port: modifiers, the `glassChrome()` wrapper,
  the component contract, foundation-freeze.
- `ios/docs/engineering/06-screens.md` §2 — the **shell wiring** (when the tab/top/action bars show,
  large-vs-inline title, sheet-vs-push routing) this doc defers to.
