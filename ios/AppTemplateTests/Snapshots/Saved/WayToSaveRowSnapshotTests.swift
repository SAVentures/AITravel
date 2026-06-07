// WayToSaveRowSnapshotTests.swift — Layer 3 render-snapshot lock for WayToSaveRow.
//
// These tests are the lock on WayToSaveRow at authoring time. They do not verify the
// design (that is the fidelity-reviewer's job); they freeze the accepted render so any
// later change that silently moves a pixel — glyph tile tier (prominent vs standard),
// accent wash fill + ring on the prominent row, surfaceGrouped card on standard rows,
// title/subtitle typography, chevron — fails the build.
// (07-testing §6 governing doc.)
//
// States covered (one snapshot each, per 07-testing §6.2):
//   prominent       — The single recommended method row (add-place.html `.method.primary`):
//                     accent-washed card (accentWashFill + accentWashRing) + actionPrimary glyph
//                     tile on a Radius.row rounded rect + "Paste a reel or video" title +
//                     subtitle + chevron. Confirms the accent signals (fill, ring, tile color)
//                     co-occur on the prominent tier.
//   standard        — A standard method row (`.way` / `.method`): surfaceGrouped card +
//                     a grouped well tile (textPrimary glyph, shadow rest) + title + subtitle +
//                     chevron. Confirms the quiet register has no accent fill or ring.
//   all-three       — All three methods (prominent + two standard) stacked, matching the
//                     saved-empty.html and add-place.html layout — confirms the visual
//                     differentiation between the single prominent row and the standard pair.
//   prominent-ax5   — AX5 compensating snapshot (§7.4). Same fixture as `prominent` at
//                     .accessibilityExtraExtraExtraLarge. Locks Dynamic Type scaling of the
//                     @ScaledMetric glyph tiles (Sizing.Component.wayToSaveGlyph /
//                     wayToSaveGlyphProminent), the display-face title, and the subtitle at
//                     the largest accessibility category. Glass-free component — renders fully.
//
// Determinism (07-testing §6.4):
//   · No Date() — WayToSaveRow is a pure display component with no clock dependency.
//   · No withAnimation — snapshot at rest.
//   · designSystemEnvironment() registers fonts + injects .disablesOneShotMotion = true.
//   · Fixtures mirror the #Preview values in WayToSaveRow.swift exactly.
//   · No SampleData required — WayToSaveRowModel is a value type.
//
// Baselines land in __Snapshots__/WayToSaveRowSnapshotTests/ alongside this file
// and are committed as the visual contract. Do NOT leave record: .all in committed code (§6.3).

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("WayToSaveRow snapshots")
struct WayToSaveRowSnapshotTests {

    // MARK: - prominent

    /// WayToSaveRow — prominent tier (the add-sheet's "Paste a reel" method).
    /// Renders: accentWashFill card + accentWashRing border + actionPrimary glyph tile
    /// (play.rectangle on an accent-filled Radius.row rounded rect) + "Paste a reel or video"
    /// display-face title + subtitle + trailing chevron.
    /// Confirms that the three accent signals (wash fill, ring, tile color) all co-occur.
    @Test("prominent — accent wash card + accent glyph tile + title/subtitle + chevron co-occur")
    @MainActor func prominent() {
        assertDesignSnapshot(
            rowCanvas {
                WayToSaveRow(
                    model: WayToSaveRowModel(
                        id: "reel",
                        title: "Paste a reel or video",
                        subtitle: "TikTok, Reel, or YouTube — even if it lists several spots",
                        systemImage: "play.rectangle",
                        prominent: true
                    ),
                    accessibilityID: "waytosave.reel"
                ) {}
            },
            named: "prominent"
        )
    }

    // MARK: - standard

    /// WayToSaveRow — standard tier (`.way` / `.method` in the mockup).
    /// Renders: surfaceGrouped card (shadow rest, no border) + grouped-well glyph tile (textPrimary
    /// ink on surfaceGrouped) + "From a screenshot" title + subtitle + chevron.
    /// Confirms the quiet register has NO accent wash fill or accent ring.
    @Test("standard — surfaceGrouped card (no accent fill/ring) + grouped-well tile + title/subtitle")
    @MainActor func standard() {
        assertDesignSnapshot(
            rowCanvas {
                WayToSaveRow(
                    model: WayToSaveRowModel(
                        id: "screenshot",
                        title: "From a screenshot",
                        subtitle: "A map pin, a story, or a menu photo",
                        systemImage: "photo"
                    ),
                    accessibilityID: "waytosave.screenshot"
                ) {}
            },
            named: "standard"
        )
    }

    // MARK: - all-three

    /// All three method rows stacked — one prominent + two standard.
    /// Matches the saved-empty.html and add-place.html layout.
    /// Confirms the visual differentiation: the prominent row is visually distinct (accent
    /// wash + ring + accent tile) from the two quiet standard rows below it.
    @Test("all-three — prominent + two standard: visual tier differentiation in a real stack")
    @MainActor func allThree() {
        assertDesignSnapshot(
            allThreeCanvas(),
            named: "all-three"
        )
    }

    // MARK: - prominent-ax5

    /// AX5 compensating snapshot (§7.4). Same fixture as `prominent` at
    /// accessibilityExtraExtraExtraLarge. Locks Dynamic Type scaling of the @ScaledMetric
    /// glyph tiles (Sizing.Component.wayToSaveGlyphProminent), the display-face title, and
    /// the subtitle's vertical growth (fixedSize vertical: true) at the largest accessibility
    /// category. Glass-free component — renders fully at AX5.
    @Test("prominent-ax5 — AX5: @ScaledMetric prominent tile + title + subtitle at accessibilityXXXL")
    @MainActor func prominentAX5() {
        assertDesignSnapshot(
            rowCanvas {
                WayToSaveRow(
                    model: WayToSaveRowModel(
                        id: "reel",
                        title: "Paste a reel or video",
                        subtitle: "TikTok, Reel, or YouTube — even if it lists several spots",
                        systemImage: "play.rectangle",
                        prominent: true
                    ),
                    accessibilityID: "waytosave.reel"
                ) {}
            }
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge),
            named: "prominent-ax5"
        )
    }
}

// MARK: - Canvas helpers

/// Wraps a single WayToSaveRow in a surfacePage canvas matching the WayToSaveRow #Preview padding.
@MainActor
private func rowCanvas<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorRole.surfacePage)
}

/// Builds the three-row stack matching the waysStack() helper in WayToSaveRow.swift.
@MainActor
private func allThreeCanvas() -> some View {
    VStack(spacing: Spacing.md) {
        WayToSaveRow(
            model: WayToSaveRowModel(
                id: "reel",
                title: "Paste a reel or video",
                subtitle: "TikTok, Reel, or YouTube — even if it lists several spots",
                systemImage: "play.rectangle",
                prominent: true
            ),
            accessibilityID: "waytosave.reel"
        ) {}
        WayToSaveRow(
            model: WayToSaveRowModel(
                id: "screenshot",
                title: "From a screenshot",
                subtitle: "A map pin, a story, or a menu photo",
                systemImage: "photo"
            ),
            accessibilityID: "waytosave.screenshot"
        ) {}
        WayToSaveRow(
            model: WayToSaveRowModel(
                id: "search",
                title: "Search for a place",
                subtitle: "Find it by name and pin it",
                systemImage: "magnifyingglass"
            ),
            accessibilityID: "waytosave.search"
        ) {}
    }
    .padding(Spacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(ColorRole.surfacePage)
}
