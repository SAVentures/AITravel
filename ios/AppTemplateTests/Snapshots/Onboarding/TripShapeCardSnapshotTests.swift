// TripShapeCardSnapshotTests.swift — Layer 3 render-snapshot lock for TripShapeCard.
//
// These tests are the lock on TripShapeCard at authoring time. They do not verify the
// design (that is the fidelity-reviewer's job); they freeze the accepted render so any
// later change that silently moves a pixel — ink ring on selected, opacity on locked,
// lockline vs metric strip, diagram dot layout — fails the build. (07-testing §6 governing doc.)
//
// States covered (one snapshot each, per 07-testing §6.2):
//   selectable-unselected   — card A in the selectable register, isSelected false.
//                             Flat surfacePage fill, no shadow, no ink ring. The metric
//                             strip and fixedDays diagram render at full opacity.
//   selectable-selected     — card A in the selectable register, isSelected true.
//                             cardSurface() elevation + 2pt textPrimary ink ring + checkmark mark.
//                             Confirms all three selected signals co-occur in one frame.
//   selectable-with-stepper — card A selected, with an embeddedControl (a DayStepper) under the
//                             title. Confirms the optional inline control slot renders without
//                             reflowing the diagram column.
//   locked                  — card B in the locked register.
//                             opacity 0.55, lockline replaces metric strip, lock glyph,
//                             tapping is inert (no button trait), diagram recedes to neutral.
//
// The card is embedded in a fixed-width 361 pt container (393 pt viewport − 16 pt × 2)
// with a surfacePage background, matching the context a real onboarding screen provides.
// This is the same container pattern used by PlaceCardSnapshotTests.
//
// Determinism (07-testing §6.4):
//   · No Date() — TripShapeCard is a pure display component with no clock dependency.
//   · No withAnimation — snapshots at rest; tap animations are never triggered.
//   · designSystemEnvironment() (inside assertDesignSnapshot) injects .disablesOneShotMotion = true
//     and registers embedded fonts — no per-file setup needed.
//   · Fixtures mirror the #Preview values in TripShapeCard.swift.
//   · SampleData is not required; TripShapeCard takes value-type arguments only.
//
// Baselines land in __Snapshots__/TripShapeCardSnapshotTests/ alongside this file
// and are committed as the visual contract. First run records and fails with "recorded";
// commit the PNGs; subsequent runs diff. Never leave record: .all in committed code.

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("TripShapeCard snapshots")
struct TripShapeCardSnapshotTests {

    // MARK: - Fixtures (mirror the #Preview values in TripShapeCard.swift)

    // Card A — fixed-days diagram, metric strip, selectable register.
    private let cardAMetricStrip: [MetricToken] = [
        MetricToken("hits 14 of 23", emphasis: true),
        MetricToken("skips 9", struck: true),
    ]
    private let cardADiagram = TripShapeDiagram.fixedDays(
        filled: [4, 3, 4, 2],
        dim:    [0, 0, 0, 1]
    )

    // Card B — cover-bucket diagram, locked register.
    private let cardBDiagram = TripShapeDiagram.coverBucket(dayCounts: [3, 4, 4, 5, 7])

    // MARK: - selectable-unselected

    /// Card A, selectable, isSelected false.
    /// Flat surfacePage fill, no elevation, no ink ring. Metric strip and fixed-days diagram
    /// render at full opacity. Title ink is textSecondary (the unselected register color).
    @Test("selectable-unselected — flat fill, no ring, metric strip, fixedDays diagram at full opacity")
    @MainActor func selectableUnselected() {
        assertDesignSnapshot(
            container {
                TripShapeCard(
                    id: "a",
                    eyebrow: "A · Fixed days",
                    title: "Pack four great days.",
                    metricStrip: cardAMetricStrip,
                    diagram: cardADiagram,
                    register: .selectable,
                    isSelected: false,
                    onSelect: {}
                )
            },
            named: "selectable-unselected"
        )
    }

    // MARK: - selectable-selected

    /// Card A, selectable, isSelected true.
    /// cardSurface() elevation + 2pt textPrimary ink ring + checkmark mark overlay co-occur.
    /// Title ink is textPrimary. No unit test can confirm the three signals appear together.
    @Test("selectable-selected — cardSurface elevation + ink ring + checkmark mark, title in textPrimary")
    @MainActor func selectableSelected() {
        assertDesignSnapshot(
            container {
                TripShapeCard(
                    id: "a",
                    eyebrow: "A · Fixed days",
                    title: "Pack four great days.",
                    metricStrip: cardAMetricStrip,
                    diagram: cardADiagram,
                    register: .selectable,
                    isSelected: true,
                    onSelect: {}
                )
            },
            named: "selectable-selected"
        )
    }

    // MARK: - selectable-with-stepper

    /// Card A selected, with a DayStepper in the embeddedControl slot.
    /// Confirms the inline control renders under the title without reflowing the diagram column.
    /// The stepper is passed as an AnyView-erased value, mirroring the #Preview pattern.
    @Test("selectable-with-stepper — selected card A with inline DayStepper, diagram column stable")
    @MainActor func selectableWithStepper() {
        assertDesignSnapshot(
            container {
                TripShapeCard(
                    id: "a",
                    eyebrow: "A · Fixed days",
                    title: "Pack four great days.",
                    metricStrip: cardAMetricStrip,
                    diagram: cardADiagram,
                    register: .selectable,
                    isSelected: true,
                    embeddedControl: AnyView(
                        DayStepper(value: 4, range: 1...14, onChange: { _ in })
                    ),
                    onSelect: {}
                )
            },
            named: "selectable-with-stepper"
        )
    }

    // MARK: - locked

    /// Card B, locked register ("Save places in Kyoto to unlock").
    /// opacity 0.55, lockline replaces metric strip, lock glyph visible, cover-bucket diagram
    /// recedes to neutral (separatorOpaque dots). The card is inert (no button trait).
    @Test("locked — opacity 0.55, lockline replaces metric strip, neutral diagram dots")
    @MainActor func locked() {
        assertDesignSnapshot(
            container {
                TripShapeCard(
                    id: "b",
                    eyebrow: "B · Cover the bucket",
                    title: "Hit everything you saved.",
                    diagram: cardBDiagram,
                    register: .locked(reason: "Save places in Kyoto to unlock")
                )
            },
            named: "locked"
        )
    }
}

// MARK: - Container helper

/// Wraps the card in a fixed-width 361 pt container (viewport 393 pt − 16 pt padding × 2)
/// with a surfacePage background, matching how TripShapeCard sits in a real onboarding
/// screen. Mirrors the container pattern in PlaceCardSnapshotTests and the #Preview setup
/// in TripShapeCard.swift.
@MainActor
private func container<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .frame(width: 361)
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .background(ColorRole.surfacePage)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
}
