// MapSnippetSnapshotTests.swift — Layer 3 render-snapshot lock for MapSnippet.
//
// These tests are the lock on MapSnippet at authoring time. They do not verify the
// design (that is the fidelity-reviewer's job); they freeze the accepted render so any
// later change that silently moves a pixel — graph-paper grid pitch/line weight, centered
// mappin accent pin, address bar typography, "Directions" caps link color — fails the build.
// (07-testing §6 governing doc.)
//
// States covered (one snapshot each, per 07-testing §6.2):
//   default-snippet — The static graph-paper placeholder canvas with the centered mappin pin
//                     (actionPrimary accent) + the address bar ("R. dom Pedro V 129, Príncipe Real")
//                     + "DIRECTIONS" caps link (location.fill glyph + actionPrimary ink).
//                     Confirms the canvas, pin, address, and "Directions" affordance all co-occur
//                     in one deterministic frame (no live MapKit — mirrors BaseMapCard's placeholder).
//
// No AX5 variant: MapSnippet is not a type-dense component — the only text elements are the address
// line (subhead) and the "Directions" link (caption). These are not glass-bearing. The plan specifies
// AX5 for "type-dense glass-free components"; the MapSnippet canvas is primarily graphical (the
// @ScaledMetric canvasHeight governs the visual growth). A single state satisfies the coverage
// requirement per §0.A5 Done-when ("one snapshot each"). An AX5 variant is added here if the
// coordinator's coverage-check flags it.
//
// Determinism (07-testing §6.4):
//   · No Date() — MapSnippet is a pure display component with no clock dependency.
//   · No live MapKit — the canvas is a deterministic graph-paper placeholder (J-12.4 /
//     BaseMapCard mirror). designSystemEnvironment() injects .mapSnapshotMode = true so
//     any future live-Map path is suppressed.
//   · No withAnimation — snapshot at rest.
//   · designSystemEnvironment() registers fonts + injects .disablesOneShotMotion = true.
//   · Fixture mirrors the #Preview value in MapSnippet.swift exactly (same address string).
//   · No SampleData required — MapSnippet takes a String address.
//
// Baselines land in __Snapshots__/MapSnippetSnapshotTests/ alongside this file
// and are committed as the visual contract. Do NOT leave record: .all in committed code (§6.3).

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("MapSnippet snapshots")
struct MapSnippetSnapshotTests {

    // MARK: - default-snippet

    /// MapSnippet — the static graph-paper placeholder.
    /// Renders: surfacePage canvas + repeating graph-paper grid (separator lines at gridPitch) +
    /// centered mappin glyph (actionPrimary accent) + address bar (surfacePage) carrying
    /// "R. dom Pedro V 129, Príncipe Real" subhead text + "DIRECTIONS" caps link
    /// (location.fill + actionPrimary foreground).
    /// Confirms the canvas, pin, address, and "Directions" affordance all co-occur in one
    /// deterministic frame. No live MapKit — the placeholder is fully deterministic (J-12.4).
    @Test("default-snippet — graph-paper canvas + accent pin + address bar + Directions link co-occur")
    @MainActor func defaultSnippet() {
        assertDesignSnapshot(
            snippetCanvas {
                MapSnippet(address: "R. dom Pedro V 129, Príncipe Real")
            },
            named: "default-snippet"
        )
    }
}

// MARK: - Canvas helper

/// Wraps a MapSnippet in a surfacePage canvas matching the #Preview padding (Spacing.screenInset).
@MainActor
private func snippetCanvas<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(Spacing.screenInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorRole.surfacePage)
}
