// Stroke.swift — the SEMANTIC stroke-width tier (05-design-system.md §1).
//
// Stroke/border widths by ROLE, never a raw number in a view (J-0.2). Each member aliases a
// codegen'd primitive (`Primitive.stroke*`, derived from `foundations.css`); views and components
// reference these roles, never `Primitive.*` directly.
//
//   • `selected` — the ink selection ring on a chosen card (J-2.4). The certainty cue is `textPrimary`
//     INK at this weight, never the accent — a selected card is *certain*, not *active*.
import SwiftUI

enum Stroke {

    /// The ink selection ring on a chosen card — `textPrimary` at this weight, the certainty cue (J-2.4).
    static let selected: CGFloat = Primitive.strokeSelected
}
