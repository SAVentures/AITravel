// Stroke.swift — the SEMANTIC stroke-width tier: border widths by role, aliasing codegen'd
// `Primitive.stroke*` (05-design-system.md §1). Flat = shared role; `Component` = single-component width.
// Views reference these roles, never `Primitive.*` (J-0.2). Stroke widths are the `03 §1/§6` off-grid
// carve-out — a line thickness is not a layout dimension, so it is NOT snapped to the 8pt spine.
import SwiftUI

enum Stroke {

    /// The ink selection ring on a chosen card — `textPrimary` ink at this weight (J-2.4).
    static let selected: CGFloat = Primitive.strokeSelected

    /// 1pt rule — separator / divider / border line, pairing with `ColorRole.separator`.
    static let separator: CGFloat = Primitive.strokeSeparator

    enum Component {
        /// 1.5 — GenerationProgressView ring border.
        static let progressRing = Primitive.strokeProgressRing
        /// 6 — MapPin now-halo ring width.
        static let mapPinRing = Primitive.strokeMapPinRing
    }
}
