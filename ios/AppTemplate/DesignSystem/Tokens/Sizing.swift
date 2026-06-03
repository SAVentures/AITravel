// Sizing.swift — the SEMANTIC component-dimension tier: fixed element sizes by role, aliasing codegen'd
// `Primitive.size*` (05-design-system.md §1, §5).
//
// This tier exists because component dimensions have no home in the existing tiers: `Spacing` is the gap
// ladder (between-group rhythm, 03 §2), and `Radius`/`Stroke` hold corner radii / border widths — a dot
// diameter or a card min-width is none of those. So a third semantic dimension tier names them by ROLE.
//
// Each value is on the 8pt spine, and is a MIN/IDEAL size — applied via a `@ScaledMetric` seed or a
// `minWidth:` so `05 §5`'s "no fixed frames" rule holds: the role sets the floor, content still drives the
// rest. Views reference these roles, never `Primitive.*` directly (J-0.2). Caseless enum per `05 §1`.
import SwiftUI

enum Sizing {

    /// 8 — status/indicator dot diameter.
    static let dot: CGFloat = Primitive.sizeDot

    /// 136 (8×17) — horizontal-scroll card min width.
    static let cardMin: CGFloat = Primitive.sizeCardMin

    /// 104 (8×13) — adaptive-grid chip min column.
    static let chipMin: CGFloat = Primitive.sizeChipMin
}
