/*
 Semantic stroke-width tier — border widths by role, aliasing codegen'd `Primitive.stroke*`.
 Views reference these roles, never `Primitive.*` directly.
*/
import SwiftUI

enum Stroke {

    // The ink selection ring on a chosen card — `textPrimary` ink at this weight, certain not active (J-2.4).
    static let selected: CGFloat = Primitive.strokeSelected

    // A 1pt rule — the thickness of a separator / divider / border line, pairing with `ColorRole.separator`.
    // The `03 §1/§6` off-the-8pt-grid carve-out: a stroke width is not a layout dimension, so it is NOT
    // snapped to the grid.
    static let separator: CGFloat = Primitive.strokeSeparator
}
