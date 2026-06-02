---
name: foundation-freeze
description: Use at the Phase 0 → Phase 2 boundary of an AppTemplate build, before dispatching ANY swift-screen-builder. The hard gate that locks the design system (tokens → modifiers → components → composition primitives) — design-reviewed and snapshot-green — so every screen is built on a solid, consistent base. This is gate #1 of the four quality gates.
---

# Foundation Freeze

The prior app's deepest failure was building screens on a half-formed design system — so every screen
inherited a shaky base and they diverged from each other and from the mockups. This gate prevents that:
**no `swift-screen-builder` runs until the design system is complete, reviewed, and locked.** It is the
one hard barrier in the phased pipeline (`ios/docs/engineering/00-overview.md`, `05-design-system.md §10`).

The coordinator (`ios-subagent-development`) invokes this at the end of Phase 0.

## The freeze checklist — all must pass to unlock screens

1. **Tokens — primitives codegen'd, semantics authored.**
   - `mockups/foundations/foundations.css` defines every primitive value (the source of truth).
   - `Primitive.generated.swift` is regenerated from it (`.claude/scripts/generate-tokens.swift`) and
     committed — **never hand-edited**.
   - The **semantic** tier (`ColorRole`, `Spacing`, `Typography`, `Radius`, `Motion`, …) is authored and
     aliases primitives by role. Nothing references a primitive or a literal outside this tier.
2. **Modifiers** the screens will need exist (`.cardSurface()`, `.glassChrome()`, …), consuming semantic
   tokens only.
3. **Components** the screens will compose exist (`BookRow`, `CoverThumbnail`, `PillButton`, …) — screen-
   agnostic, Dynamic-Type-safe, each covering its key states.
4. **Composition primitives** exist and are the only layout path: `ScreenScaffold` (chrome intent
   `.root`/`.detail`/`.immersive`/`.custom`), `ScreenSection`, `RhythmSpacer`, `ActionBar`.
5. **Design-reviewed (`design-reviewer`, opus).** It validates the system against `docs/design-docs/`:
   semantic-token discipline, Dynamic Type, glass-on-chrome-only, the J-rules (cited), and a full
   **slop-catalog pass** (`08-slop.md`). Verdict must be **FREEZE-READY**, not BLOCKED.
6. **Snapshot-green.** Every component's render snapshots exist and pass (the lock); the build is clean.

## On pass → FREEZE

- Commit the design system as a unit (`feat(ds): foundation — tokens, components, composition primitives`).
- Record the freeze (a note in `docs/decisions.md` is good practice). Only now may the coordinator
  dispatch Phase 2 `swift-screen-builder` tasks.
- After the freeze, the design system is **stable**; a later token/component change re-runs this gate for
  the affected surface and re-records its snapshots in the same commit.

## On fail → BLOCK

Dispatch the matching scaffolder to close the gap (`swift-design-system` for a missing token/modifier/
component/primitive; the codegen script for a missing primitive after its value is added to
`foundations.css` by `mockups-screen-builder`), then re-run the checklist. **Do not** start screens to
"unblock progress" — that is exactly the failure this gate exists to prevent.
