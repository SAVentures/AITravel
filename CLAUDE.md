# AppTemplate — a quality-first native iOS template

A reusable starting point for building a **beautiful, non-generic native iOS app** with a doc-driven,
agent-dispatched workflow. Single-target SwiftUI (`AppTemplate` scheme, Xcode 26, **minimum iOS 26**,
**Swift 6.2 — MainActor-by-default**, light-mode only). It ships one reference vertical slice — a
**library / book-management** master-detail with one write flow — that exercises every layer end-to-end
and is the living "this is what good looks like" exemplar. Swap `Library`/`Book` for your domain when
you instantiate the template (see `README.md`).

> **Why this template exists.** It's distilled from a prior app whose architecture was sound but whose
> *foundation lacked quality from the start* — the UI drifted from the mockups, screens were
> inconsistent, and the gates measured the wrong things. Every structural choice here exists to make
> those four failure modes hard to reproduce. See "The four quality gates" below.

## Repository structure

```
CLAUDE.md            — this file (the rules)
README.md            — how to instantiate the template for a new app
.claude/             — the workflow harness: agents/ · skills/ · commands/ · scripts/
docs/
  design-docs/       — the prescriptive VISUAL language (00–08): what a screen should LOOK like
  decisions.md       — append-only log of non-obvious calls (new entries supersede, never edit)
mockups/
  foundations/       — foundations.css: the TOKEN source of truth (Swift primitives are codegen'd from it)
  components/         — component anatomy reference
  screens/           — the named mockups each screen ports from (+ committed screenshots)
ios/
  AppTemplate.xcodeproj
  AppTemplate/        — app source (App · Store · Networking · DesignSystem · Models · Screens)
  AppTemplate{Tests,UITests}/
  docs/engineering/   — how the app is BUILT (00–07)
```

## Scope rule — decide this first

- **`mockups/`, `docs/`, `README.md`** — design + prose artifacts. **Edit directly.**
- **`ios/` Swift code** — **never hand-edit and never code on `main`.** Every change goes through the
  agent pipeline below, in a git worktree.

## The native-app workflow (hard rule) — the phased pipeline

```
worktree
  → ios-plan-writer            architect a contract-level plan from the docs (interfaces, signatures,
                               tokens/components by name, accessibility ids, exemplars, acceptance criteria)
  → Phase 0: Foundation        design system: codegen primitives → semantic tokens → modifiers →
              ──[FREEZE]──      components → composition primitives → design-reviewed → snapshot-locked
  → Phase 1: Models + Networking
  → Phase 2: Screens           each: scaffold → consistency-review → fidelity-review (vs named mockup)
  → Phase 3: Tests
  → four-layer gate            build clean + all four test layers green
  → finish-branch
```

Orchestration stays in the **main loop** (the `ios-subagent-development` skill): dispatch the `swift-*`
scaffolders in parallel on disjoint files, serialize edits to shared files (`AppStore.swift`,
`ScreenCatalogView.swift`), run the gate, commit. **The foundation-freeze is the one hard barrier** —
no screen is scaffolded until the design system is locked.

**Before dispatching, read:**
- `ios/docs/engineering/00-overview.md` — the build conventions, the non-negotiables, the four-layer pyramid.
- `docs/design-docs/00-overview.md` — the visual language; then `06-judgment.md` (the crux).
- `.claude/agents/README.md` — the dispatch guide: which agent owns which layer, model tiers, parallelization rules.

## The four quality gates (why v2 exists)

| Prior failure | Gate | Where |
|---|---|---|
| Foundation built too fast | **Foundation-freeze** — design system locked + design-reviewed before any screen | `engineering/05 §10` |
| Screens inconsistent with each other | **Composition primitives** — every screen composes `ScreenScaffold`/`ScreenSection`/… | `engineering/06 §2` |
| Mockup → Swift drift | **Fidelity-reviewer** — each screen names its mockup, is reviewed against it, then snapshot-locked | `engineering/06 §9` |
| Scaffolder slop | **Coverage gate + design-reviewer + craft criteria + slop scan** — "green build ≠ done" | `engineering/07 §9`, `05 §11`, `design-docs/08-slop.md` |

## The non-negotiables

Violations require a written entry in `docs/decisions.md`.

**Engineering** (full list + rationale in `ios/docs/engineering/00-overview.md`):
1. **Work goes through the phased pipeline.** Worktree → plan → foundation-freeze → features → gate.
2. **`AppStore` is the single source of truth** — one `@Observable` store, owned at the App root (no
   `.shared` singleton, no parallel stores).
3. **Reference models for mutable list rows; value types elsewhere; DTOs at the wire.** The network
   never carries a `@MainActor` domain model.
4. **Screens depend on `APIClient`, never a concrete provider.** Mock/live swaps at the store boundary;
   the mock is a **stateless, failable** `MockProvider` (so loading/error/rollback/offline are testable).
5. **Logic out of views** — mutations are model methods; networked writes are store commands
   (optimistic + rollback); derivation is a stateless presenter; only ephemeral UI state is `@State`.
6. **Swift 6.2, MainActor-by-default** — app code is main-actor by default; only the `Sendable` boundary
   and `@concurrent` off-main work are marked. Zero concurrency diagnostics.
7. **The four-layer pyramid stays green — and green build ≠ done.**

**Visual** (full list in `docs/design-docs/00-overview.md`; the calls are `06-judgment.md`):
1. **Glass on floating chrome only** — the system Liquid Glass material; never on content or stacked.
2. **Design values from *semantic* tokens only** — no literals, no raw primitives, in any view.
3. **Dynamic Type, always** — every text style scales (to AX5); no fixed-pt fonts, no fixed frames.
4. **One accent, used sparingly** — emphasis/state only, ≤ twice per screen; never chrome or a card fill.
5. **Restrained motion** — critically-damped, one easing personality, one continuous motion max, tap ≤100ms.
6. **Have a point of view** — lean on the system, add one deliberate signature; generic system-font +
   system-blue + defaults is the failure. Run the slop catalog (`08-slop.md`).

## Navigating Swift — SwiftLSP first

Resolve Swift symbols semantically with the **`LSP` tool** (`documentSymbol` to enter a file, then
`goToDefinition` / `findReferences` / `hover`), not `Grep`/`Read`. Reach for `Grep` only for non-Swift
files (`foundations.css`, `.pbxproj`), string literals, accessibility identifiers, or to check whether a
name is already taken. The `ios-worktree` command warms a per-worktree sourcekit-lsp index.

## Per-layer docs + owning agent

`engineering/01-architecture` · `02-models` (`swift-model-scaffold`) · `03-store` · `04-networking`
(`swift-networking-endpoint`) · `05-design-system` (`swift-design-system`) · `06-screens`
(`swift-screen-builder`) · `07-testing` (`swift-test-writer` + snapshot/UI writers). `swift-code-reviewer`,
`design-reviewer`, and `fidelity-reviewer` validate against the docs.

## Testing — the four-layer pyramid (one doc)

`engineering/07-testing.md` covers all four layers: Swift Testing (unit + integration), render snapshots
(swift-snapshot-testing — the **lock** on a screen you got right), XCUITest vs the stateless
`MockProvider` scenarios, and the coverage gate. Tokens are **not** parity-tested — they're codegen'd
from `foundations.css` and locked by snapshots. Visual *fidelity* is an authoring-time gate, not a test.

**Build:**
```
xcodebuild -project ios/AppTemplate.xcodeproj -scheme AppTemplate \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4.1' \
  CODE_SIGNING_ALLOWED=NO build
```

## Authority split / source-of-truth pairings

Three trees, one contract — neither prose nor artifact is canonical alone; they move together.

| Concern | Source of truth |
|---|---|
| How it **looks** (judgment) | `docs/design-docs/` (`06-judgment.md` is the crux) |
| How it's **built** | `ios/docs/engineering/` |
| Token **values** | `mockups/foundations/foundations.css` → Swift primitives **codegen'd** from it |
| Each screen's **appearance** | its named `mockups/screens/*.html` + committed screenshot (the fidelity target) |

## What this template is not

- Not a product — no auth, billing, or real backend. It ships scaffolding + one reference slice.
- Not dark-mode-ready — light-only by decision; the semantic-token layer makes it a future token swap.
- Not a generic UI kit — every rule is scoped to *beautiful, native, iOS-26, light-mode*. Don't
  repurpose components for unrelated domains.
- Not to be coded on `main` or by hand — the `ios/` app goes through the pipeline (scope rule above).
