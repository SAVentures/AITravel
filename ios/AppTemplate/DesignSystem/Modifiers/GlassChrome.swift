// GlassChrome.swift — the ONE glass modifier (05-design-system.md §6; 05-components §1.1/§7; J-0.1/J-8.3).
//
// Glass is the iOS 26 system Liquid Glass material — we build *on* it, never reinvent it. This file is
// the design system's single seam for that material: `glassChrome()` wraps the system `glassEffect()`
// with our defaults, shaped as a floating-chrome container (a pill — `Radius.pill`, J-10.2). There is
// NO hand-rolled translucency/blur anywhere in this file; the system material is the contract
// (J-0.1 — "the system Liquid Glass material, not a hand-rolled translucency").
//
// ── Glass on floating chrome ONLY (J-0.1, the non-negotiable) ───────────────────────────────────────
// Apply `glassChrome()` to *bar/overlay containers that float over content*: a tab/top bar, the
// `ActionBar`, a sheet grabber, a map-overlay chip. NEVER on a card, list row, sheet-at-rest, or
// anything holding primary input — that is resting content on a solid surface (J-8.2, 05-components §3.3
// "a card is never glass"). The design system *enforces* glass-on-chrome-only by EXPOSING this modifier
// only here and APPLYING it only inside the composition primitives (`ActionBar`, the bars) — content
// components in `Components/` must NOT call it.
//
// ── Never glass-on-glass (J-8.3) ────────────────────────────────────────────────────────────────────
// Two translucent layers make both read as dishwater. A glass control migrating into a glass bar drops
// its own glass and becomes a plain glyph button (05-components §1.1). So: never stack `glassChrome()`
// inside another glass surface, and never put a glass bar over a glass bar in one vertical run.
//
// ── Grouping: GlassEffectContainer (05-design-system.md §6, 05-components §1.1/§2) ───────────────────
// Glass can't sample glass, so RELATED glass surfaces that should blend/morph as one (the CTA + the
// secondary action in the `ActionBar`; the glyph buttons in a bar) must share ONE `GlassEffectContainer`
// — not N independent `glassChrome()` calls. The `ActionBar` composition primitive (B-COMP5) does this:
// it groups its `.glassProminent` primary + `.glass` secondary in a single container so they blend.
// `glassChrome()` is for a single floating container; use `GlassEffectContainer` (in the composition
// primitive) when several glass elements must read as one piece of chrome.
import SwiftUI

/// Wraps the iOS 26 system Liquid Glass material for a single floating-chrome container.
///
/// `interactive` adds the system touch-point illumination / subtle scale (`.glassEffect(.regular
/// .interactive())`) — use it ONLY on touch-responsive glass (a tappable overlay chip), never on a
/// static decorative bar background (05-components §1.1).
private struct GlassChrome: ViewModifier {

    /// `true` for touch-responsive glass (adds the system interactive illumination); `false` for a
    /// static floating bar/overlay container.
    let interactive: Bool

    func body(content: Content) -> some View {
        // The system material, shaped as a pill — chrome is a pill, content is a rounded-rect (J-10.2).
        // `Capsule` is the `Radius.pill` chrome shape; the system computes the translucency/blur/edge —
        // we never author it (J-0.1).
        content.glassEffect(
            interactive ? .regular.interactive() : .regular,
            in: .capsule
        )
    }
}

extension View {

    /// Applies the iOS 26 system Liquid Glass material as floating chrome (a pill-shaped container).
    ///
    /// **Floating chrome only** (J-0.1): a tab/top bar, the `ActionBar`, a sheet grabber, a map-overlay
    /// chip. Never on a card/row/sheet-at-rest or content holding primary input. Never stacked on
    /// another glass surface (J-8.3 — no glass-on-glass). When several glass elements must blend as one
    /// piece of chrome, group them in a `GlassEffectContainer` (in the composition primitive) instead of
    /// calling this per element.
    ///
    /// - Parameter interactive: pass `true` only for touch-responsive glass (adds the system interactive
    ///   illumination); defaults to `false` for a static floating container.
    func glassChrome(interactive: Bool = false) -> some View {
        modifier(GlassChrome(interactive: interactive))
    }
}
