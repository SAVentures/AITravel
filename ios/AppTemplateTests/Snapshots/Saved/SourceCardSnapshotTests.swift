// SourceCardSnapshotTests.swift — Layer 3 render-snapshot lock for SourceCard + SourcePlaceRow.
//
// These tests are the lock on SourceCard and SourcePlaceRow at authoring time. They do not
// verify the design (that is the fidelity-reviewer's job); they freeze the accepted render so
// any later change that silently moves a pixel — icon tile tint, caret rotation, count pill,
// child row layout, stamp pill, foot hint — fails the build.
// (07-testing §6 governing doc.)
//
// States covered (one snapshot each, per 07-testing §6.2):
//   collapsed                 — SourceCard collapsed (head only). Confirms the icon tile, title/meta,
//                               count pill, and chevron-down caret all render in the head row with
//                               the card in its resting (non-expanded) shape.
//   expanded-reel-many        — SourceCard expanded, reel source, three child SourcePlaceRows (with
//                               stamp pills) + a foot hint. The reel icon tile is violet-tinted.
//                               Confirms the expanded body: divider + child rows + optional foot hint
//                               all co-occur, and caret is rotated 180°.
//   expanded-search-single    — SourceCard expanded, search source, one child SourcePlaceRow (no stamp).
//                               The search icon tile is neutral-tinted. Confirms a single-child expanded
//                               state and that the foot hint is absent when nil.
//   expanded-screenshot       — SourceCard expanded, screenshot source, two child rows with "saved" stamp
//                               pills. The screenshot icon tile is slate-tinted.
//   sourceplace-with-stamp    — Isolated SourcePlaceRow with a "0:12" timestamp stamp pill. Confirms
//                               the accent-50 stamp fill + accent-700 stamp ink + text co-occur on the
//                               meta line (02-color §6 — never color alone; stamp text carries the signal).
//   sourceplace-no-stamp      — Isolated SourcePlaceRow with no stamp. Confirms the meta line renders
//                               without the stamp pill (no invisible horizontal gap).
//   expanded-reel-many-ax5    — AX5 compensating snapshot (§7.4). Same fixture as expanded-reel-many
//                               at .accessibilityExtraExtraExtraLarge. Locks Dynamic Type scaling of
//                               the @ScaledMetric icon tile and thumb, display-face titles, and the
//                               mono-caps meta line at the largest accessibility category.
//
// Determinism (07-testing §6.4):
//   · No Date() — SourceCard/SourcePlaceRow are pure display components.
//   · No withAnimation — snapshot at rest; the caret rotation value reflects isExpanded directly.
//     (The animation is .standard(Motion.standard) but the VALUE settles before capture.)
//   · designSystemEnvironment() registers fonts + injects .disablesOneShotMotion = true.
//   · Fixtures mirror the #Preview values in SourceCard.swift exactly (stable ids, fixed strings).
//   · No SampleData required — SourceCardModel/SourcePlaceRowModel are value types.
//
// Baselines land in __Snapshots__/SourceCardSnapshotTests/ alongside this file
// and are committed as the visual contract. Do NOT leave record: .all in committed code (§6.3).

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("SourceCard + SourcePlaceRow snapshots")
struct SourceCardSnapshotTests {

    // MARK: - Shared fixtures (mirror the #Preview fixtures in SourceCard.swift)

    // @MainActor static vars: SourceCardModel/SourcePlaceRowModel inits are MainActor-isolated
    // (Swift 6.2 MainActor-by-default module), so stored/computed fixtures must be actor-isolated.
    // All consumer test methods are @MainActor so access is safe. (§6.6)
    @MainActor static var reelManyModel: SourceCardModel {
        SourceCardModel(
            id: "reel-lisbonfoodie",
            title: "@lisbonfoodie",
            meta: "REEL · 2 WEEKS AGO",
            kind: .reel,
            places: [
                SourcePlaceRowModel(id: "p1", name: "A Cevicheria", meta: "Príncipe Real · Lisbon", stamp: "0:12"),
                SourcePlaceRowModel(id: "p2", name: "Time Out Market", meta: "Cais do Sodré · Lisbon", stamp: "0:34"),
                SourcePlaceRowModel(id: "p3", name: "Pastéis de Belém", meta: "Belém · Lisbon", stamp: "1:05"),
            ],
            footHint: "One reel · three places, in the order they appeared."
        )
    }

    @MainActor static var searchSingleModel: SourceCardModel {
        SourceCardModel(
            id: "search-1",
            title: "Search",
            meta: "SEARCH · YESTERDAY",
            kind: .search,
            places: [
                SourcePlaceRowModel(id: "p4", name: "Sushi Saito", meta: "Akasaka · Tokyo"),
            ]
        )
    }

    @MainActor static var screenshotModel: SourceCardModel {
        SourceCardModel(
            id: "shot-1",
            title: "Screenshots",
            meta: "SCREENSHOT · LAST MONTH",
            kind: .screenshot,
            places: [
                SourcePlaceRowModel(id: "p5", name: "Fabrica Coffee", meta: "Baixa · Lisbon", stamp: "saved"),
                SourcePlaceRowModel(id: "p6", name: "LX Factory", meta: "Alcântara · Lisbon", stamp: "saved"),
            ]
        )
    }

    // MARK: - collapsed

    /// SourceCard collapsed (head only) — the resting state of the card.
    /// Renders: reel icon tile (violet tint + play.rectangle glyph) + "@lisbonfoodie" title +
    /// "REEL · 2 WEEKS AGO" meta + "3" count pill + chevron-down caret (unrotated).
    /// Confirms that the head layout co-occurs as a single row with no expanded body.
    @Test("collapsed — head only: reel tile + title/meta + count pill + unrotated caret")
    @MainActor func collapsed() {
        assertDesignSnapshot(
            cardCanvas {
                SourceCard(
                    model: Self.reelManyModel,
                    isExpanded: false,
                    onToggle: {},
                    onSelectPlace: { _ in }
                )
            },
            named: "collapsed"
        )
    }

    // MARK: - expanded-reel-many

    /// SourceCard expanded, reel source, three child rows + foot hint.
    /// Renders: reel tile (violet) + head + divider + three SourcePlaceRows (each with a stamp pill)
    /// + foot hint row + rotated caret (180°).
    /// Confirms the expanded body: divider, all child rows, stamp pills, foot hint, and caret rotation
    /// all co-occur in one frame.
    @Test("expanded-reel-many — expanded reel: 3 child rows with stamps + foot hint + rotated caret")
    @MainActor func expandedReelMany() {
        assertDesignSnapshot(
            cardCanvas {
                SourceCard(
                    model: Self.reelManyModel,
                    isExpanded: true,
                    onToggle: {},
                    onSelectPlace: { _ in }
                )
            },
            named: "expanded-reel-many"
        )
    }

    // MARK: - expanded-search-single

    /// SourceCard expanded, search source, one child row, no foot hint.
    /// Renders: search tile (neutral + magnifyingglass glyph) + head + divider + one SourcePlaceRow
    /// (no stamp) + rotated caret. Confirms a single-child expanded state and absence of foot hint.
    @Test("expanded-search-single — expanded search: 1 child row, no stamp, no foot hint")
    @MainActor func expandedSearchSingle() {
        assertDesignSnapshot(
            cardCanvas {
                SourceCard(
                    model: Self.searchSingleModel,
                    isExpanded: true,
                    onToggle: {},
                    onSelectPlace: { _ in }
                )
            },
            named: "expanded-search-single"
        )
    }

    // MARK: - expanded-screenshot

    /// SourceCard expanded, screenshot source, two child rows with "saved" stamp pills.
    /// Renders: screenshot tile (slate + photo.on.rectangle glyph) + head + divider + two
    /// SourcePlaceRows (each with "saved" stamp) + rotated caret. No foot hint for this source.
    /// Confirms the screenshot tile tint is visually distinct from reel and search.
    @Test("expanded-screenshot — expanded screenshot: 2 child rows with saved stamps, distinct tile tint")
    @MainActor func expandedScreenshot() {
        assertDesignSnapshot(
            cardCanvas {
                SourceCard(
                    model: Self.screenshotModel,
                    isExpanded: true,
                    onToggle: {},
                    onSelectPlace: { _ in }
                )
            },
            named: "expanded-screenshot"
        )
    }

    // MARK: - sourceplace-with-stamp

    /// Isolated SourcePlaceRow — with a "0:12" timestamp stamp pill.
    /// Renders: placeholder thumb + "A Cevicheria" name + "Príncipe Real · Lisbon" meta +
    /// "0:12" stamp pill (stampFill background + stampInk text) + chevron.
    /// Confirms the stamp pill's accent fill + ink co-occur with the meta text (02-color §6).
    @Test("sourceplace-with-stamp — thumb + name + meta + accent stamp pill + chevron co-occur")
    @MainActor func sourcePlaceWithStamp() {
        assertDesignSnapshot(
            sourcePlaceCanvas {
                SourcePlaceRow(
                    model: SourcePlaceRowModel(
                        id: "p1",
                        name: "A Cevicheria",
                        meta: "Príncipe Real · Lisbon",
                        stamp: "0:12"
                    ),
                    onTap: {},
                    accessibilityID: "sourceplacerow.p1"
                )
            },
            named: "sourceplace-with-stamp"
        )
    }

    // MARK: - sourceplace-no-stamp

    /// Isolated SourcePlaceRow — no stamp pill.
    /// Renders: placeholder thumb + "Sushi Saito" name + "Akasaka · Tokyo" meta + chevron.
    /// Confirms the meta line renders without any stamp pill (no invisible horizontal gap).
    @Test("sourceplace-no-stamp — thumb + name + meta only, no stamp pill")
    @MainActor func sourcePlaceNoStamp() {
        assertDesignSnapshot(
            sourcePlaceCanvas {
                SourcePlaceRow(
                    model: SourcePlaceRowModel(
                        id: "p4",
                        name: "Sushi Saito",
                        meta: "Akasaka · Tokyo"
                    ),
                    onTap: {},
                    accessibilityID: "sourceplacerow.p4"
                )
            },
            named: "sourceplace-no-stamp"
        )
    }

    // MARK: - expanded-reel-many-ax5

    /// AX5 compensating snapshot (§7.4). Same fixture as expanded-reel-many at
    /// accessibilityExtraExtraExtraLarge. Locks Dynamic Type scaling of the @ScaledMetric icon
    /// tile (Sizing.Component.sourceIconTile) and child thumb (Sizing.Component.sourcePlaceThumb),
    /// the display-face titles, the mono-caps meta, and the stamp pill labels at the largest
    /// accessibility category. Glass-free component — renders fully at AX5.
    @Test("expanded-reel-many-ax5 — AX5: @ScaledMetric tile + thumb + titles + meta + stamps at accessibilityXXXL")
    @MainActor func expandedReelManyAX5() {
        assertDesignSnapshot(
            cardCanvas {
                SourceCard(
                    model: Self.reelManyModel,
                    isExpanded: true,
                    onToggle: {},
                    onSelectPlace: { _ in }
                )
            }
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge),
            named: "expanded-reel-many-ax5"
        )
    }
}

// MARK: - Canvas helpers

/// Wraps a SourceCard in a surfacePage canvas matching the SourceCard #Preview padding.
@MainActor
private func cardCanvas<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorRole.surfacePage)
}

/// Wraps an isolated SourcePlaceRow in a surfaceGrouped card canvas matching the SourcePlaceRow #Preview.
@MainActor
private func sourcePlaceCanvas<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(.horizontal, Spacing.lg)
        .background(ColorRole.surfaceGrouped, in: .rect(cornerRadius: Radius.card))
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorRole.surfacePage)
}
