// PlaceRowSnapshotTests.swift — Layer 3 render-snapshot lock for PlaceRow.
//
// These tests are the lock on PlaceRow at authoring time. They do not verify the design
// (that is the fidelity-reviewer's job); they freeze the accepted render so any later
// change that silently moves a pixel — thumb well size, badge position, body typography,
// source-line glyph, trailing slot, placeholder treatment — fails the build.
// (07-testing §6 governing doc.)
//
// States covered (one snapshot each, per 07-testing §6.2):
//   reel-chevron           — source=reel, trailing=chevron. The standard list row: reel provenance
//                            stamp (play.rectangle badge) + name/meta/source body + disclosure
//                            chevron. Confirms the badge, source line, and chevron co-occur correctly.
//   screenshot-category    — source=screenshot, trailing=category. The search-results variant:
//                            camera.viewfinder badge + CategoryChip in the trailing slot instead of
//                            a chevron. Confirms the chip replaces the chevron and the badge is correct.
//   search-no-photo        — source=search, trailing=chevron, hasThumbnail=false. The placeholder
//                            state: magnifyingglass badge + the monochrome "photo" glyph placeholder
//                            in the thumb well — never a broken-image box (J-12.4).
//   reel-chevron-ax5       — AX5 compensating snapshot (§7.4). Same fixture as reel-chevron at
//                            .accessibilityExtraExtraExtraLarge. Locks Dynamic Type scaling of the
//                            @ScaledMetric thumb/badge wells, the display-face name, and the mono-caps
//                            source line at the largest accessibility category. Glass-free — renders fully.
//
// Determinism (07-testing §6.4):
//   · No Date() — PlaceRow is a pure display component with no clock dependency.
//   · No withAnimation — snapshot at rest.
//   · designSystemEnvironment() registers fonts + injects .disablesOneShotMotion = true.
//   · Fixtures mirror the #Preview values in PlaceRow.swift exactly (stable ids, fixed strings).
//   · No SampleData required — PlaceRowModel is a value type.
//
// Baselines land in __Snapshots__/PlaceRowSnapshotTests/ alongside this file
// and are committed as the visual contract. First run records and fails with "recorded";
// commit the PNGs. Do NOT leave record: .all in committed code (§6.3).

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("PlaceRow snapshots")
struct PlaceRowSnapshotTests {

    // MARK: - reel-chevron

    /// PlaceRow: reel source, chevron trailing — the standard wishlist list row.
    /// Renders: reel provenance badge (play.rectangle) on the thumb corner + "A Cevicheria" display name +
    /// "Príncipe Real · Lisbon" meta + "FROM @TASTEMAKER" mono-caps source line + disclosure chevron.
    /// Confirms the badge, body, and chevron all co-occur in one frame (no unit test can confirm that).
    @Test("reel-chevron — reel source badge + name/meta/source body + disclosure chevron")
    @MainActor func reelChevron() {
        assertDesignSnapshot(
            rowCanvas {
                PlaceRow(
                    model: PlaceRowModel(
                        id: "cevicheria",
                        name: "A Cevicheria",
                        meta: "Príncipe Real · Lisbon",
                        sourceLabel: "FROM @TASTEMAKER",
                        sourceSystemImage: "play.rectangle",
                        category: .eat,
                        hasThumbnail: true,
                        trailing: .chevron
                    ),
                    accessibilityID: "placerow.cevicheria"
                )
            },
            named: "reel-chevron"
        )
    }

    // MARK: - screenshot-category

    /// PlaceRow: screenshot source, category chip trailing — the search-results variant.
    /// Renders: camera.viewfinder badge on the thumb corner + "Bar Alto" name +
    /// "Bairro Alto · Lisbon" meta + "FROM A SCREENSHOT" source line + trailing CategoryChip(.drink).
    /// Confirms the CategoryChip replaces the chevron in the trailing slot, and the badge glyph
    /// matches the screenshot source kind.
    @Test("screenshot-category — screenshot source badge + name/meta/source + trailing CategoryChip")
    @MainActor func screenshotCategory() {
        assertDesignSnapshot(
            rowCanvas {
                PlaceRow(
                    model: PlaceRowModel(
                        id: "bar-alto",
                        name: "Bar Alto",
                        meta: "Bairro Alto · Lisbon",
                        sourceLabel: "FROM A SCREENSHOT",
                        sourceSystemImage: "camera.viewfinder",
                        category: .drink,
                        hasThumbnail: true,
                        trailing: .category
                    ),
                    accessibilityID: "placerow.bar-alto"
                )
            },
            named: "screenshot-category"
        )
    }

    // MARK: - search-no-photo

    /// PlaceRow: search source, chevron trailing, no thumbnail — the placeholder state.
    /// Renders: magnifyingglass badge + the monochrome "photo" glyph placeholder in the thumb well
    /// (fillTertiary ground + textTertiary photo icon — never a broken-image box, J-12.4).
    /// Confirms the placeholder treatment is present when hasThumbnail is false.
    @Test("search-no-photo — search source + monochrome placeholder thumb (no broken-image box)")
    @MainActor func searchNoPhoto() {
        assertDesignSnapshot(
            rowCanvas {
                PlaceRow(
                    model: PlaceRowModel(
                        id: "kissaten",
                        name: "Yanaka Kissaten",
                        meta: "Yanaka · Tokyo",
                        sourceLabel: "FOUND IN SEARCH",
                        sourceSystemImage: "magnifyingglass",
                        category: .stay,
                        hasThumbnail: false,
                        trailing: .chevron
                    ),
                    accessibilityID: "placerow.kissaten"
                )
            },
            named: "search-no-photo"
        )
    }

    // MARK: - reel-chevron-ax5

    /// AX5 compensating snapshot (§7.4). Same fixture as reel-chevron at
    /// accessibilityExtraExtraExtraLarge. Locks Dynamic Type scaling of the @ScaledMetric thumb
    /// well (Sizing.Component.placeRowThumb) and badge (Sizing.Component.placeRowBadge), the
    /// display-face name, the secondary meta, and the mono-caps source line at the largest
    /// accessibility category. Glass-free component — renders fully at AX5.
    @Test("reel-chevron-ax5 — AX5 Dynamic Type: @ScaledMetric wells + display name + source line at accessibilityXXXL")
    @MainActor func reelChevronAX5() {
        assertDesignSnapshot(
            rowCanvas {
                PlaceRow(
                    model: PlaceRowModel(
                        id: "cevicheria",
                        name: "A Cevicheria",
                        meta: "Príncipe Real · Lisbon",
                        sourceLabel: "FROM @TASTEMAKER",
                        sourceSystemImage: "play.rectangle",
                        category: .eat,
                        hasThumbnail: true,
                        trailing: .chevron
                    ),
                    accessibilityID: "placerow.cevicheria"
                )
            }
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge),
            named: "reel-chevron-ax5"
        )
    }
}

// MARK: - Canvas helper

/// Wraps a row in a surfacePage canvas matching the PlaceRow #Preview padding.
@MainActor
private func rowCanvas<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorRole.surfacePage)
}
