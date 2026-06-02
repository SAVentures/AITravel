# ios-app-template

A **quality-first, doc-driven, agent-dispatched template** for building beautiful, non-generic native
iOS apps — SwiftUI, Xcode 26, **minimum iOS 26**, **Swift 6.2 (MainActor-by-default)**, light-mode.

It ships a small **library / book-management** reference slice that exercises every layer end-to-end and
is the living "this is what good looks like" exemplar. Swap the `Library`/`Book` domain for your own.

> Distilled from a prior app whose architecture was sound but whose *foundation lacked quality from the
> start* — the UI drifted from the mockups, screens were inconsistent, and the gates measured the wrong
> things. Every choice here exists to make those four failure modes hard to reproduce.

## What's in here

| Path | What |
|---|---|
| `CLAUDE.md` | the governing workflow — scope rule, the phased pipeline, the four quality gates, the non-negotiables |
| `docs/design-docs/` | the prescriptive **visual language** (00–08): typography, color, layout, motion, components, **judgment** (the crux), accessibility, the **anti-slop catalog** |
| `ios/docs/engineering/` | how the app is **built** (00–07): architecture, models, store, networking, design-system, screens, the four-layer testing pyramid |
| `mockups/` | the **visual source of truth** — `foundations.css` (the token contract, codegen'd to Swift), component anatomy, per-screen fidelity targets |
| `ios/AppTemplate/` | the SwiftUI app (App · Store · Networking · DesignSystem · Models · Screens) |
| `.claude/` | the workflow harness — `agents/` (the `swift-*` scaffolders + the gate reviewers), `skills/`, `commands/`, `scripts/` |

## The four quality gates

| Prior failure | Gate |
|---|---|
| Foundation built too fast | **Foundation-freeze** — the design system is locked + design-reviewed before any screen is built |
| Screens inconsistent | **Composition primitives** — every screen composes `ScreenScaffold`/`ScreenSection`/… |
| Mockup → Swift drift | **Fidelity-reviewer** — each screen names its mockup, is reviewed against it, then snapshot-locked |
| Scaffolder slop | **Coverage gate + design-reviewer + the slop catalog** — "green build ≠ done" |

## The workflow (hard rule)

```
worktree → ios-plan-writer → Phase 0: Foundation ──[FREEZE]── → Models+Networking
        → Screens (scaffold → consistency → fidelity) → Tests → four-layer gate → finish-branch
```

`ios/` Swift is **never hand-edited and never built on `main`** — it goes through the agent pipeline in a
worktree. `mockups/` and `docs/` are edited directly. See `CLAUDE.md` for the full rules.

## Instantiating for a new app

1. Rename the `AppTemplate` scheme / bundle id / `ios/AppTemplate` dir for your app.
2. Define your domain models and your app's non-negotiables in `CLAUDE.md`.
3. Author your mockups in `mockups/` (`foundations.css` first — it codegens the Swift tokens), and commit
   a screenshot per screen.
4. Run **Phase 0** and **freeze** the design system before building any screen.
5. Only then build features, screen by screen, each ported from its named mockup.

## Build

```
xcodebuild -project ios/AppTemplate.xcodeproj -scheme AppTemplate \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4.1' \
  CODE_SIGNING_ALLOWED=NO build
```

---

**Status:** the documentation + workflow harness + mockups scaffold are complete; the Xcode project +
reference-slice implementation is the next build-out.
