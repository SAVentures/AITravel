/*
 Semantic stroke-width tier — border widths by role, aliasing codegen'd `Primitive.stroke*`.
 Views reference these roles, never `Primitive.*` directly.
*/
import SwiftUI

enum Stroke {

    // The ink selection ring on a chosen card — `textPrimary` ink at this weight, certain not active (J-2.4).
    static let selected: CGFloat = Primitive.strokeSelected
}
