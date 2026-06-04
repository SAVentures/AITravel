// View+AccessibilityID.swift — the ONE conditional accessibility-identifier helper (01-architecture §3/§11).
//
// A11y ids follow the dot-namespaced `component.slot[.id]` convention and are the CALLER's job to supply
// (the component/composition primitive owns the *mechanism*, the screen owns the *value* — 01-architecture
// §8.7). Several components/composition primitives take an optional `accessibilityID` and must attach it
// only when present: a `nil` id must leave the view untouched, never stamp an empty `""` id (a decorative
// blank-id node the `.elementDetection` accessibility audit would then flag — Track B Task 1.3).
//
// This is the shared home for that pattern, so the components/composition primitives that need it
// (`GlassCircleButton`, `ActionBar`, `HScrollSection`, `OnboardingActionFloor`, `SearchWell`) reference one
// definition instead of each re-declaring an identical private copy.
import SwiftUI

extension View {

    /// Applies `.accessibilityIdentifier` only when `id` is non-nil — no `?? ""` foot-gun.
    ///
    /// A `nil` id leaves the view untouched so it exposes no empty-id node in the accessibility tree
    /// (which the `.elementDetection` audit would otherwise flag as a decorative blank-id element). The
    /// component owns the mechanism; the caller owns the id value (01-architecture §8.7).
    @ViewBuilder
    func accessibilityIdentifier(ifPresent id: String?) -> some View {
        if let id {
            accessibilityIdentifier(id)
        } else {
            self
        }
    }
}
