// PlaceCardSnapshotTests.swift — Layer 3 render-snapshot lock for PlaceCard.
//
// These tests are the **lock** on PlaceCard at authoring time. They do not verify the
// design (that is the fidelity-reviewer's job); they freeze the accepted render so any
// later change that silently moves a pixel — spacing, color, font, elevation, icon —
// fails the build. (07-testing §6 governing doc.)
//
// States covered (one snapshot each, per 07-testing §6.2):
//   definitive  — lifted card, roman name, photo placeholder, mono facts, tag capsules
//   fuzzy       — flat ground, italic name in secondary ink, ring glyph, no shadow
//   selected    — definitive card + checkmark mark overlay (never an accent fill)
//   loading     — redacted placeholder at same footprint (no reflow)
//
// The card is embedded in a fixed-width 361 pt container (393 pt viewport − 16 pt × 2
// horizontal padding) with a surfacePage background, matching the context a real list
// screen would provide. This ensures the card lays out as it will in production.
//
// Determinism (07-testing §6.4):
//   · No Date() — PlaceCard is value-type; no clock dependency.
//   · No withAnimation — all states are at rest.
//   · disablesOneShotMotion = true — injected by designSystemEnvironment() inside
//     assertDesignSnapshot, so any entrance motion settles before capture.
//   · Fixtures are inline value literals identical to the private preview fixtures in
//     PlaceCard.swift (private extension PlaceCardModel). The test constructs its own
//     equivalents via the internal PlaceCardModel init.
//
// Baselines land in __Snapshots__/PlaceCardSnapshotTests/ alongside this file and are
// committed as the visual contract. First run records and fails with "recorded"; commit
// the PNGs; subsequent runs diff. Never leave record: .all in committed code.

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("PlaceCard snapshots")
struct PlaceCardSnapshotTests {

    // MARK: - Fixtures
    //
    // Values mirror the private `PlaceCardModel.definitive` / `.fuzzy` fixtures in
    // PlaceCard.swift so the snapshots lock the same representative content used in previews.

    private let definitiveModel = PlaceCardModel(
        id: "tsuta",
        name: "Tsuta",
        facts: "08:00 · 8 MIN WALK · ¥1,200",
        tags: ["Ramen", "Michelin"],
        certainty: .definitive
    )

    private let fuzzyModel = PlaceCardModel(
        id: "lunch",
        name: "somewhere for lunch",
        facts: "~ 13:00 · NEAR YANAKA",
        certainty: .fuzzy
    )

    // MARK: - Helpers

    /// Wraps `card` in a fixed-width container matching how PlaceCard sits inside a real
    /// list screen: 361 pt wide (viewport 393 pt − 16 pt padding × 2), surfacePage
    /// background, vertically top-aligned. The fixed width lets the card measure its
    /// photo-well height via @ScaledMetric and wrap long text correctly.
    private func container<C: View>(_ card: C) -> some View {
        card
            .frame(width: 361)
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
            .background(ColorRole.surfacePage)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Snapshot tests

    @Test("definitive — lifted card, roman name, photo placeholder, mono facts, tag capsules")
    @MainActor
    func definitive() {
        assertDesignSnapshot(
            container(PlaceCard(model: definitiveModel)),
            named: "definitive"
        )
    }

    @Test("fuzzy — flat ground, italic name in secondary ink, ring glyph, no shadow")
    @MainActor
    func fuzzy() {
        assertDesignSnapshot(
            container(PlaceCard(model: fuzzyModel)),
            named: "fuzzy"
        )
    }

    @Test("selected — definitive card + checkmark mark overlay, never an accent fill")
    @MainActor
    func selected() {
        assertDesignSnapshot(
            container(PlaceCard(model: definitiveModel, isSelected: true)),
            named: "selected"
        )
    }

    @Test("loading — redacted placeholder at same footprint, no reflow")
    @MainActor
    func loading() {
        assertDesignSnapshot(
            container(PlaceCard(model: definitiveModel, isLoading: true)),
            named: "loading"
        )
    }
}
