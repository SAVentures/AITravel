import SwiftUI

/// The dimension grid — component sizes are integer multiples of the 4pt sub-unit (`Primitive.s1`),
/// so every size stays on-grid and in ratio. There are NO bespoke size primitives; the unit is the
/// only dimension atom. CSS mirrors this as `calc(var(--s-1) * n)`. (05-design-system.md §1.x)
enum Grid {
    /// 4pt — the atomic grid step (03 §1 sub-unit).
    static let unit: CGFloat = Primitive.s1

    /// A dimension of `steps` grid units. Bounded: integer steps, clamped 0…96 (0…384pt) — a dimension
    /// can never land off-grid or run away.
    static func x(_ steps: Int) -> CGFloat { unit * CGFloat(min(max(steps, 0), 96)) }
}
