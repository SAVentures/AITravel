// PlacedChipSnapshotTests.swift — Layer 3 render-snapshot lock for PlacedChip.
//
// These tests are the lock on PlacedChip at authoring time. They do not verify the design
// (that is the fidelity-reviewer's job); they freeze the accepted render so any later change
// that silently moves a pixel — fillTertiary capsule ground, check glyph tint, subhead label
// weight and ink, chip padding — fails the build.
// (07-testing §6 governing doc.)
//
// States covered (one snapshot each, per 07-testing §6.2):
//   placed   — the one meaningful state: "Placed on Day 2 · Thu Aug 27".
//              Renders: fillTertiary capsule + textSecondary check glyph + textPrimary
//              subhead label. Confirms the glyph and label co-occur on the recessive chip
//              (the meaning is never carried by icon alone, 02-color §6).
//
// Determinism (07-testing §6.4):
//   · No Date() — PlacedChip is a pure display component; the caller composes the text.
//   · No withAnimation — snapshot at rest.
//   · designSystemEnvironment() registers fonts + injects .disablesOneShotMotion = true.
//   · Fixture mirrors the #Preview text in PlacedChip.swift exactly.
//   · No SampleData required — PlacedChip takes a plain String.
//
// Baselines land in __Snapshots__/PlacedChipSnapshotTests/ alongside this file
// and are committed as the visual contract. First run records and fails with "recorded";
// commit the PNGs. Do NOT leave record: .all in committed code (§6.3).

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("PlacedChip snapshots")
struct PlacedChipSnapshotTests {

    // MARK: - placed

    /// PlacedChip: the one meaningful display state.
    /// Renders: fillTertiary capsule + textSecondary check glyph (accessibilityHidden) +
    /// textPrimary subhead "Placed on Day 2 · Thu Aug 27".
    /// Confirms the glyph and label co-occur on the recessive chip ground.
    @Test("placed — fillTertiary capsule + check glyph + textPrimary label co-occur")
    @MainActor func placed() {
        assertDesignSnapshot(
            chipCanvas {
                PlacedChip("Placed on Day 2 · Thu Aug 27")
            },
            named: "placed"
        )
    }
}

// MARK: - Canvas helper

/// Wraps the chip in a surfacePage canvas matching the PlacedChip #Preview padding.
@MainActor
private func chipCanvas<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(Spacing.screenInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorRole.surfacePage)
}
