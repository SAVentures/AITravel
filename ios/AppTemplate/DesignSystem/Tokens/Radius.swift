// Radius.swift — the SEMANTIC radius tier (03-layout-spacing §6; 05-design-system.md §1, §5).
//
// Radius is a ladder of MEANING, not a free dial (J-10.1). Each member is referenced by ROLE here —
// never a raw number, never a `Primitive.r*` directly from a view (J-0.2). The ladder runs:
//
//     tag → thumb → row/well → card/sheet → pill (chrome)
//
// Two rules govern the picks (J-10):
//   • Chrome is a PILL; content is a ROUNDED-RECT (J-10.2). A pill *floats* (a bar, a chip, a button);
//     a rounded-rect is *anchored* (a card, a row). A pill-shaped card reads as a giant chip; a
//     rounded-rect bar reads as a panel — both wrong.
//   • CAP content at the `card` rung (16). Extreme radii — 24px+ on a small card — read as
//     AI-generated (08-slop A-6); full-pill is for tags/buttons/chips only, never a content surface.
//
// Concentric children — the craft move (03-layout-spacing §5). Do NOT hand-pick an inner radius
// (that produces "pinched" or "flared" corners). Instead the PARENT carries
// `.containerShape(.rect(cornerRadius: Radius.card))` and the CHILD uses `ConcentricRectangle()`
// (or `.rect(corners: .concentric)`); the system computes inner = outer − padding. This is a usage
// note for component authors, not a member of this enum.
import SwiftUI

enum Radius {

    /// Tags, the smallest chips.
    static let tag: CGFloat = Primitive.rTag

    /// Thumbnails, small media.
    static let thumb: CGFloat = Primitive.rThumb

    /// Rows, wells — the medium content rung.
    static let row: CGFloat = Primitive.rRow

    /// Cards, sheets — the cap for content (never go past this on a content surface; J-10.1, 08-slop A-6).
    static let card: CGFloat = Primitive.rCard

    /// Chrome — bars, buttons, chips. A pill (radius = half height) so it reads as floating chrome (J-10.2).
    static let pill: CGFloat = Primitive.rPill
}
