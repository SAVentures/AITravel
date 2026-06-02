# mockups/ — the visual source of truth

This directory is where the design language becomes **concrete artifacts**. It is hand-coded HTML/CSS
with **no build step** — it reads like the product but isn't the product. It has three jobs, and every
file serves one of them:

1. **Token source of truth** — `foundations/foundations.css` holds every raw design value. The Swift
   primitive tokens are **code-generated** from it (`.claude/scripts/generate-tokens.swift` →
   `ios/AppTemplate/DesignSystem/Tokens/Primitive.generated.swift`). **If a value isn't in
   `foundations.css`, it doesn't exist** — never type a raw value straight into Swift.
2. **Component anatomy** — `components/` shows each component's structure and states, the reference the
   `swift-design-system` agent ports from.
3. **Screen fidelity targets** — `screens/*.html` (+ a committed PNG in `screens/screenshots/`) are what
   each SwiftUI screen is built against and checked against by the `fidelity-reviewer`.

> **Authority.** `docs/design-docs/` owns the *judgment* (what beautiful looks like — the J-rules, the
> craft bar, the anti-slop catalog). This directory is where that judgment is *applied* to make real
> screens. When they disagree, fix the mockup to match the design-docs.

---

## Design with purpose — read before authoring

Don't open a blank canvas. Before making any artifact, read, in order:

1. `docs/design-docs/00-overview.md` — the visual non-negotiables + the authority split.
2. `docs/design-docs/06-judgment.md` — **the crux** (the J-rules; cite them).
3. The topic docs for what you're making — `01-typography`, `02-color`, `03-layout-spacing`,
   `04-motion`, `05-components`.
4. `docs/design-docs/08-slop.md` — the AI-slop tells to avoid.

Then **have a point of view** (J-13.3): one deliberate type pairing, one signature accent, one signature
motion — never generic system-font + system-blue + defaults. Warm neutrals, an expressive display face,
and any gradient sit *near* slop tells, so they must be **earned**, never reflexive.

**Before you call a screen done**, run the **60-second review** (`06-judgment.md §J-15`) and the **slop
scan** (`08-slop.md`). Both must pass.

---

## Directory organization

```
mockups/
  CLAUDE.md                  ← this file
  index.html                 ← links the artifacts (optional gallery)
  foundations/
    foundations.css          ← THE token contract (codegen input — see below)
    foundations.html         ← human-readable token sheet (visual reference)
  components/
    components.css
    components.html           ← the component inventory + states
  screens/
    screen-shell.css          ← the iPhone frame + shell chrome stand-ins (safe areas, tab/top/action bars)
    <screen-name>.html        ← one screen per file (e.g. book-list.html)
    screenshots/
      <screen-name>.png       ← the committed fidelity target for that screen
```

**File rules:**
- **One screen per file**, named for the screen (`book-list.html`, `book-detail.html`). The SwiftUI
  screen names this file as its fidelity target — keep names stable.
- **Compose shared components; don't reinvent them.** A new screen pulls from `components/`. A genuinely
  new component is added to `components/` first, then used.
- **Every value references a token.** No literal colors/sizes/spacing in a component or screen — pull
  `var(--token)` from `foundations.css`. A literal is a token-discipline failure (the `mockups-screen-
  builder` AUDIT mode catches these).
- **Commit a screenshot** to `screens/screenshots/` whenever a screen is authored or changes — it's the
  pixel fidelity target the reviewer and the SwiftUI port compare against.

---

## The iOS shell — render the chrome (a glass *approximation*)

Every screen lives inside the iOS shell, so the mockups must render it — otherwise the SwiftUI
`ScreenScaffold`, tab bar, and `ActionBar` have nothing to lay out against. Treat the chrome as
first-class **components**, and have `screen-shell.css` place them on the iPhone frame so every
`screens/*.html` shows the bars in position.

**The shell is not one fixed frame — it's set by the screen's chrome intent** (the SwiftUI
`ScreenScaffold(.root / .detail / .immersive / .custom)`, `06-screens.md §2`). `screen-shell.css`
provides the variants (e.g. a body class `chrome-root` / `chrome-detail` / `chrome-immersive` /
`chrome-custom` / `chrome-sheet`); **each `screens/<name>.html` declares the one matching the screen it
will become**:

| Chrome intent | Top bar | Tab bar | Used for |
|---|---|---|---|
| `.root` (a tab's home) | large title, no back | visible | the landing screen of a tab |
| `.detail` (pushed) | inline title + back | visible (persists on push) | a drilled-in detail |
| `.immersive` (takeover) | inline / minimal | **hidden** | reader, capture, onboarding |
| `.custom` | none — screen draws its own header | per case | rare; must supply its own back |
| sheet (presented) | grabber, no nav bar | covered by the sheet | a side task over content |

- The **Action bar** (bottom thumb-zone CTA) is *independent of the chrome intent* — render it on any
  screen that has a primary action; omit it on screens that don't.
- A mockup's chrome must match the intent its SwiftUI screen will declare — large-vs-inline title, tab
  bar present/hidden, back chevron — because that's exactly what the fidelity-reviewer checks.

**Glass is an approximation here, not Liquid Glass fidelity.** HTML/CSS cannot reproduce Liquid Glass's
real-time lensing, specular response, or refraction — and it shouldn't try. Render the chrome as a
**static frosted-glass** stand-in: a translucent fill + `backdrop-filter: blur()` + a hairline edge —
enough to read as "floating glass chrome" and to get placement, translucency, and layering right. The
*real* Liquid Glass is the system's job, rendered natively in SwiftUI (the system material —
`05-design-system.md §6`); the mockup only approximates it.

So the **fidelity-reviewer compares chrome *structure, placement, and composition*** — is the tab bar
present, is the title large-vs-inline correct, is the CTA in the thumb zone — and treats the glass
*material* difference (the mockup's CSS frost vs SwiftUI's Liquid Glass) as a **substrate difference,
not drift** (`fidelity-reviewer`, `06-screens.md §9`). Get the *layout* faithful; don't chase the glass
pixels.

---

## The token contract (`foundations/foundations.css`)

`generate-tokens.swift` parses this file, so its shape is a **contract**, not a preference. Define every
primitive as a flat custom property under `:root`:

```css
:root {
  /* color — oklch(L C H) or oklch(L C H / A) → Primitive Color (converted to sRGB at codegen) */
  --ink-900:   oklch(0.23 0.02 265);   /* → Primitive.ink900  */
  --paper-0:   oklch(0.99 0.005 80);   /* → Primitive.paper0  */
  --accent-500: oklch(0.62 0.15 45);   /* → Primitive.accent500 */

  /* length — Npx → Primitive CGFloat (px stripped) */
  --space-4:   16px;                   /* → Primitive.space4  (CGFloat 16) */
  --radius-lg: 18px;                   /* → Primitive.radiusLg */

  /* duration — Nms → Primitive Double in SECONDS (ms ÷ 1000) */
  --dur-base:  240ms;                  /* → Primitive.durBase (0.24) */

  /* bare number → Primitive Double */
  --opacity-muted: 0.6;                /* → Primitive.opacityMuted */
}
```

Rules so codegen stays clean:
- **Name → identifier:** kebab-case → camelCase (`--dur-base` → `durBase`, `--ink-900` → `ink900`).
  Keep the category prefix in the name (`space`/`radius`/`dur`/`ink`/`paper`/`accent`) so the generated
  identifiers read by role.
- **One value per property.** **Compound values** (shadows, gradients, multi-part transitions) are
  *skipped* by the codegen — author those in the Swift **semantic** tier by hand; define them here only
  as a visual reference, and don't expect a primitive.
- **`foundations.css` is the only place a raw value lives.** Change a value here and re-run the codegen
  in the same commit (the Swift token + its snapshot move together). `Primitive.generated.swift` is
  **never hand-edited.**
- The Swift **semantic** tier (`ColorRole`, `Spacing`, `Typography`, …) aliases these primitives by
  *role* — that mapping is design intent, authored in Swift, not here.

---

## Workflow & ownership

The `mockups-screen-builder` agent (AUTHOR / AUDIT) does this work; it edits this directory **directly**
(not through the Swift pipeline). The order mirrors the foundation-freeze:

1. **Foundations first** — define/extend tokens in `foundations.css` (and the `foundations.html` sheet).
   Nothing downstream can reference a token that isn't here.
2. **Components** — author/extend `components/` with anatomy + states, token-referenced.
3. **Screens** — compose components into `screens/<name>.html` on the iPhone frame, commit a screenshot.

---

## What these mockups are not

- **Not a build pipeline** — no bundler, no JS framework, no server. Pure HTML/CSS.
- **Not a product** — no auth, no real data, no error/empty flows beyond what a screen needs to show.
- **Not dark-mode** — light-only by decision; the warm-tinted neutrals are intentional (and must be
  *earned*, not the reflexive "tasteful AI" default — `08-slop.md`).
- **Not a generic UI kit** — every token and component is scoped to *this* beautiful, native,
  iOS-26-light-mode app. Don't repurpose them for unrelated domains.
