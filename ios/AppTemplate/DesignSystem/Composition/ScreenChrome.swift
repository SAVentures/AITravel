// ScreenChrome.swift
// DesignSystem/Composition
//
// Chrome intent — the value type `ScreenScaffold` consumes to map a screen's
// outer chrome onto platform chrome. This is intent only: a screen declares
// *what kind of screen it is*, and `ScreenScaffold` (built next) owns the
// translation to `.navigationTitle` / `.navigationBarTitleDisplayMode` /
// `.toolbar(.hidden, for: .tabBar)` / `.presentationDragIndicator`, so no
// screen ever hand-wires nav-bar or tab-bar modifiers.
//
// No View logic, no tokens — a small `Sendable` value type by design. The
// scaffold (B-COMP2) reads it; screens (Phase 2) declare it.
//
// Source / authority:
//   - mockups/CLAUDE.md — "The iOS shell" chrome-intent table (reproduced below;
//     it is the contract the fidelity-reviewer checks: large-vs-inline title,
//     tab bar present/hidden, back chevron).
//   - 06-screens §2 (ios/docs/engineering/06-screens.md) — the UI shell: chrome
//     intent → platform chrome mapping, owned by `ScreenScaffold`.
//
// ┌──────────────────┬────────────────────────┬──────────────┬───────────────────────────────┐
// │ Chrome intent    │ Top bar                │ Tab bar      │ Used for                      │
// ├──────────────────┼────────────────────────┼──────────────┼───────────────────────────────┤
// │ .root            │ large title, no back   │ visible      │ the landing screen of a tab   │
// │ .detail          │ inline title + back    │ visible      │ a drilled-in detail (persists │
// │                  │                        │  (persists)  │   on push)                    │
// │ .immersive       │ inline / minimal       │ HIDDEN       │ reader, capture, onboarding   │
// │ .custom          │ none — screen draws    │ per case     │ rare; must supply its own     │
// │                  │   its own header       │              │   back                        │
// │ .sheet           │ grabber, no nav bar    │ covered by   │ a side task presented over    │
// │                  │                        │   the sheet  │   content                     │
// └──────────────────┴────────────────────────┴──────────────┴───────────────────────────────┘
//
// Notes:
//   - A sheet is *solid at rest* — only the grabber is glass (05-components §6.1);
//     `ScreenChrome` carries only the intent, the scaffold renders the grabber.
//   - The Action bar (bottom thumb-zone CTA) is independent of chrome intent and
//     is supplied separately to `ScreenScaffold`, not encoded here.

/// Declares a screen's chrome intent — *what kind of screen it is* — which
/// `ScreenScaffold` maps to platform chrome (title style, back affordance,
/// tab-bar visibility, sheet grabber). See the chrome-intent table above.
///
/// Pure value type: no View logic, no tokens. `Sendable` so it crosses any
/// isolation boundary a screen declaration might need.
enum ScreenChrome: Sendable {

    /// A tab's home: large navigation title, no back affordance, tab bar visible.
    case root(title: String)

    /// A pushed detail: inline navigation title + automatic back; the tab bar
    /// persists across the push.
    case detail(title: String)

    /// A takeover (reader, capture, onboarding): inline / minimal title and the
    /// **tab bar hidden** — a deliberate, explicit opt-out, never a per-detail default.
    case immersive

    /// The screen draws its own header and supplies its own back affordance; the
    /// system nav bar is hidden. Rare.
    case custom

    /// A presented sheet: grabber visible, no nav bar (the sheet is solid at rest;
    /// only the grabber is glass). An optional inline title.
    case sheet(title: String?)
}
