// Radius.swift — the SEMANTIC radius tier: a meaning ladder (tag→thumb→row/well→card→pill) referenced by
// ROLE, never a raw number or `Primitive.r*` (03-layout-spacing §6; J-0.2/J-10). Rules: chrome = PILL,
// content = ROUNDED-RECT capped at `card` (extreme radii read AI — J-10.2, 08-slop A-6); concentric inner
// corners are the system's job via `.containerShape` + `ConcentricRectangle()` (03 §5).
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
