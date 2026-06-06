// PlaceInfoGridSnapshotTests.swift — Layer 3 render-snapshot lock for PlaceInfoGrid.
//
// These tests are the lock on PlaceInfoGrid at authoring time. They do not verify the
// design (that is the fidelity-reviewer's job); they freeze the accepted render so any
// later change that silently moves a pixel — mono-caps key, display-face value,
// monospacedDigit numeric alignment, optional sub line, hairline dividers between cells,
// surfaceGrouped background, Radius.card clip — fails the build.
// (07-testing §6 governing doc.)
//
// States covered (one snapshot each, per 07-testing §6.2):
//   three-cells     — The canonical three-cell grid (Hours · Price · Cuisine) from the #Preview
//                     in PlaceInfoGrid.swift. Confirms all three cells co-occur with their
//                     hairline dividers, the monospacedDigit numeric alignment, and the
//                     optional sub lines — no unit test can confirm that co-occurrence.
//   three-cells-ax5 — AX5 compensating snapshot (§7.4). Same fixture at
//                     .accessibilityExtraExtraExtraLarge. Locks Dynamic Type safety of the grid:
//                     each cell grows vertically (fixedSize(horizontal:false, vertical:true)) and
//                     text wraps rather than clipping (J-0.3, 08-slop D-7).
//
// Determinism (07-testing §6.4):
//   · No Date() — PlaceInfoGrid is a pure display component with no clock dependency.
//   · No withAnimation — snapshot at rest.
//   · designSystemEnvironment() registers fonts + injects .disablesOneShotMotion = true.
//   · Fixture mirrors the .cevicheria extension in PlaceInfoGrid.swift exactly.
//   · No SampleData required — PlaceFacts is a value type.
//
// Baselines land in __Snapshots__/PlaceInfoGridSnapshotTests/ alongside this file
// and are committed as the visual contract. Do NOT leave record: .all in committed code (§6.3).

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("PlaceInfoGrid snapshots")
struct PlaceInfoGridSnapshotTests {

    // MARK: - three-cells

    /// PlaceInfoGrid — the canonical three-cell grid.
    /// Renders: "HOURS" mono-caps key + "Opens 12:30" monospacedDigit value + "Tue – Sun" sub |
    /// "PRICE" key + "€€€" value + "Mains ~€22" sub |
    /// "CUISINE" key + "Seafood" value + "Peruvian" sub.
    /// Hairline dividers (ColorRole.separator) sit between each cell; the whole is clipped to
    /// Radius.card on a surfaceGrouped ground. Confirms all three cells and dividers co-occur.
    @Test("three-cells — three facts cells with hairline dividers and optional sub lines co-occur")
    @MainActor func threeCells() {
        assertDesignSnapshot(
            gridCanvas {
                PlaceInfoGrid(cells: [
                    PlaceFacts(key: "Hours", value: "Opens 12:30", sub: "Tue \u{2013} Sun"),
                    PlaceFacts(key: "Price", value: "\u{20AC}\u{20AC}\u{20AC}", sub: "Mains ~\u{20AC}22"),
                    PlaceFacts(key: "Cuisine", value: "Seafood", sub: "Peruvian"),
                ])
            },
            named: "three-cells"
        )
    }

    // MARK: - three-cells-ax5

    /// AX5 compensating snapshot (§7.4). Same fixture as three-cells at
    /// accessibilityExtraExtraExtraLarge. Locks that each cell wraps rather than clips at
    /// the largest accessibility category (fixedSize(horizontal:false, vertical:true) in
    /// each cell's VStack and the grid's outer .fixedSize). Confirms J-0.3 / 08-slop D-7
    /// compliance: text wraps, no fixed-frame clip at AX5. Glass-free component — renders fully.
    @Test("three-cells-ax5 — AX5: cells grow vertically (no clip) at accessibilityXXXL")
    @MainActor func threeCellsAX5() {
        assertDesignSnapshot(
            gridCanvas {
                PlaceInfoGrid(cells: [
                    PlaceFacts(key: "Hours", value: "Opens 12:30", sub: "Tue \u{2013} Sun"),
                    PlaceFacts(key: "Price", value: "\u{20AC}\u{20AC}\u{20AC}", sub: "Mains ~\u{20AC}22"),
                    PlaceFacts(key: "Cuisine", value: "Seafood", sub: "Peruvian"),
                ])
            }
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge),
            named: "three-cells-ax5"
        )
    }
}

// MARK: - Canvas helper

/// Wraps a PlaceInfoGrid in a surfacePage canvas matching the #Preview padding (Spacing.screenInset).
@MainActor
private func gridCanvas<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(Spacing.screenInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorRole.surfacePage)
}
