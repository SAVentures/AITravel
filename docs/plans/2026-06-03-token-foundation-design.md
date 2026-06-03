# Token Foundation — Replication Design (first-saas, adapted to iOS)

**Status:** proposal for review — do NOT rebuild until approved.
**Why we're here:** the spacing tier was built sparse + gap-only (no size coverage), so component
dimensions had no home → we minted bespoke "size primitives" (pollution). We want a foundation that
won't spring this leak again, grounded in first-saas's mature token system rather than free-handed.

---

## 1. What first-saas ACTUALLY does (verbatim study)

**One spacing scale — dense low, sparse high** (`_spacing.scss`):
`0, 1px, 4, 8, 12, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 144, 192, 224, 256, … 768`.
4pt base, 8pt rhythm, steps widen as they climb ("editorial air"). This scale doubles as the **size**
source — components set `height: var(--space-10)` (64), `min-width: var(--space-20)` (144), etc.

**Three tier bands per category, explicitly sectioned:**
1. **numeric scale** — `--space-1…96` (the atoms)
2. **t-shirt semantic** — `--space-xs/sm/md/lg/xl/2xl/3xl/4xl` → map to rungs (`md=16, lg=32, xl=48`)
3. **component aliases** — `--space-card`(24), `--space-button-x`(16), `--radius-button`(8),
   `--radius-card`(20), `--shadow-card`, … each *references* a scale rung
Same pattern in radius / shadows / motion. Themes (`[data-theme]`) override **only colors + shadows**
(+ optional radius sharpening); the spacing/type/motion scales are constant across all themes.

**The surprise — bespoke component dimensions are LITERALS, not tokens.** When a dimension doesn't land
on a rung, first-saas bakes a literal *in the component*: `min-height: 200px` (table), `400px` (editor),
`600px` (device frame), `260px` (integration card), `120px` (skeleton). It does **not** snap them, does
**not** mint a token, does **not** `calc(rung × n)`. The rule `SP-1.1 "the ladder is law"` governs
**spacing/rhythm** (gaps, padding) — **not** arbitrary component sizes. `calc()` is allowed only for
*arithmetic on tokens* (centering, a switch's travel), never to fabricate a size.

---

## 2. The key insight (this changes the recommendation)

**first-saas is LESS strict than our repo about component dimensions.** It allows literal sizes for
component-specific dimensions; only spacing must be on the ladder. Our repo's rule is *"no literals / no
raw primitives in any view, ever."*

So a *faithful* copy would **relax our no-literals rule**. And our `Grid.x(n)` (every dimension = a 4pt
multiple, named, no literal, no bespoke primitive) is in fact **stricter and cleaner than first-saas** —
where they'd write `184px`, we write `Grid.x(46)`, which can't drift off-grid.

**Conclusion: our foundation isn't "wrong" — the one real defect (no size story) is now fixed by
`Grid.x`, and on component-dimension discipline we're already *ahead* of first-saas.** What first-saas
genuinely does better is the **spacing tier itself**: a richer scale + t-shirt names + per-category
component-alias bands. That's the part worth adopting.

---

## 3. What we adopt / keep / skip

| from first-saas | decision | rationale |
|---|---|---|
| Denser spacing scale + **t-shirt aliases** (`sm/md/lg/xl/…`) | **Adopt** | our spine is too sparse (stops at 56) and role-only; t-shirt is the conventional, discoverable API |
| **Component-alias bands** per category (`Spacing.Component.*`, `Radius.Component.*`) | **Adopt** (already agreed) | a deterministic home for component-specific values |
| **Themes override colors/shadows only**; scale constant | **Adopt as the deferred seam** | matches our "dark = token swap" plan exactly |
| **Literals for bespoke component dims** | **Reject — keep `Grid.x(n)`** | ours is stricter/cleaner; no literals, on-grid by construction |
| 768px-tall scale, z-index, breakpoints, 43 themes | **Skip** | single mobile device; SwiftUI owns layering/responsive; light-only |

---

## 4. Proposed AITravel foundation

**Spacing — the real change.** Keep the codegen→Swift pipeline; enrich the tier:
- **Numeric scale (foundations primitives)** — extend/regularise: `s0=0, s1=4, s2=8, s3=12, s4=16,
  s5=20, s6=24, s7=32, s8=40, s9=48, s10=56, s11=64, s12=80` (covers rhythm + small sizes; mobile, so we
  stop ~80).
- **t-shirt semantic (Swift `Spacing`)** — `xs=4, sm=8, md=16, lg=24, xl=32, xxl=48`.
- **Role aliases (keep)** — `sectionGap, itemGap, hero, screenInset, chromeClearance` stay, now defined
  on the richer scale. *(See the open decision — keep role names vs migrate to t-shirt.)*
- **`Spacing.Component`** band — component-specific insets.

**Sizing — keep `Grid.x(n)`** (bounded 4pt multiples) for component dimensions; reference a spacing rung
where one fits. No bespoke size primitives. *(Already built and freeze-green.)*

**Radius / Stroke / Typography / Shadows / Motion** — add a `Component` alias band where a component
needs its own value; otherwise unchanged (these tiers are sound).

**Theme seam** — documented, not built: `[data-theme]` would override colors/shadows only; `ColorRole`
is the single resolve point.

---

## 5. The one decision for you

Our `Spacing` uses **role names** (`sectionGap`, `itemGap`, `hero`) — doc-justified ("the gap after a
section header is decided once"). first-saas uses **t-shirt** (`md/lg/xl`) + numeric.

- **(a) Keep role names, enrich underneath** *(recommended)* — add the dense numeric scale + t-shirt
  aliases beneath the existing role ladder; keep `Grid.x` for sizes. **Low churn** (existing
  `Spacing.sectionGap` call-sites untouched), gets first-saas's coverage + discoverability.
- **(b) Migrate to t-shirt as the primary API** — re-point every `Spacing.*` reference across all
  screens/components to `sm/md/lg/…`. **High churn**, but one conventional scale, fully first-saas-faithful.

Recommend **(a)**: the role ladder is a *strength* (semantic intent), not the defect. The defect was the
missing size story — already solved by `Grid.x`. So this becomes an *enrichment* (add t-shirt + denser
rungs + component bands), not a teardown.

---

## 6. Bottom line

Studying first-saas end-to-end is reassuring, not alarming: their system's strength is a well-tiered
spacing scale (adopt it), and their handling of bespoke dimensions is *literals* — which our `Grid.x`
already beats. **Net: keep the current in-flight work (`Grid.x` + `Component` bands), add the t-shirt
scale + denser rungs, and we have a foundation that's first-saas-grade on structure and stricter on
discipline.** The big "rebuild" the doubt implied isn't warranted — it's a contained enrichment.
