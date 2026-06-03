// CardSurface.swift — the content-card surface modifier (05-design-system.md §7; 05-components §3; J-8).
//
// A content card is SOLID, one elevation, no glass, no side-border (05-components §3.1–3.4, J-8). This
// modifier ports the mockup `.pcard`: a `surface-grouped` fill, `r-card` corners, and the `rest`
// elevation shadow — and, per J-8.4 / 08-slop A-4, NO border (a surface is *either* a 1px edge *or* a
// soft shadow, never both). It reads at the call site as `.cardSurface()`; the struct is private, the
// `func` is the API (05 §7).
//
// `.containerShape(.rect(cornerRadius: Radius.card))` is set so concentric children (a card photo, a
// nested control) can use `.rect(corners: .concentric)` / `ConcentricRectangle()` and inherit the
// parent's corner without hand-picking an inner radius (03-layout-spacing §5).
//
// ── Why there is NO `fuzzy:` parameter ──────────────────────────────────────────────────────────────
// The product's "definitive vs fuzzy" register is a *component* decision, not a surface flag. PlaceCard
// (Wave C) chooses `.cardSurface()` (definitive: `surfaceGrouped` + `rest` shadow) vs a flat
// `surfacePage` + no shadow (fuzzy) — see the mockup `.pcard` vs `.pcard.fuzzy`. This modifier owns only
// the one definitive surface; the register lives one tier up, as a value-type state arg on the component.
//
// Semantic tokens only — no literal, no `Primitive.*`, no glass (J-0.2, J-0.1).
import SwiftUI

private struct CardSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Spacing.cardInset)
            .background(ColorRole.surfaceGrouped, in: .rect(cornerRadius: Radius.card))
            .shadowRest()
            .containerShape(.rect(cornerRadius: Radius.card))
    }
}

extension View {
    /// The resting content-card surface: `surfaceGrouped` fill, `Radius.card` corners, the `rest`
    /// elevation shadow, and a concentric container shape for children. No glass, no border (J-8).
    /// The definitive/fuzzy register is the *component*'s choice — this is the definitive surface only.
    func cardSurface() -> some View { modifier(CardSurface()) }
}
