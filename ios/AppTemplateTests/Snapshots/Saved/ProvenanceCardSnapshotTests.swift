// ProvenanceCardSnapshotTests.swift — Layer 3 render-snapshot lock for ProvenanceCard.
//
// These tests are the lock on ProvenanceCard at authoring time. They do not verify the
// design (that is the fidelity-reviewer's job); they freeze the accepted render so any
// later change that silently moves a pixel — eyebrow glyph + caps ink, source thumb
// placeholder, handle display face, "View" lifted pill, italic display-face quote — fails
// the build.
// (07-testing §6 governing doc.)
//
// States covered (one snapshot each, per 07-testing §6.2):
//   with-quote     — ProvenanceCard with a full model: sourceHandle + meta + a pull-quote.
//                    Confirms the eyebrow row, the source-thumb placeholder, the "View"
//                    affordance, and the italic quote line all co-occur in one frame.
//   no-quote       — ProvenanceCard with a quoteless model (no quote field).
//                    Confirms the quote line is truly absent (no invisible vertical gap).
//
// Determinism (07-testing §6.4):
//   · No Date() — ProvenanceCard is a pure display component with no clock dependency.
//   · No withAnimation — snapshot at rest.
//   · designSystemEnvironment() registers fonts + injects .disablesOneShotMotion = true.
//   · Fixtures mirror the #Preview values in ProvenanceCard.swift exactly.
//   · No SampleData required — ProvenanceCard.Model is a value type.
//
// Baselines land in __Snapshots__/ProvenanceCardSnapshotTests/ alongside this file
// and are committed as the visual contract. Do NOT leave record: .all in committed code (§6.3).

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("ProvenanceCard snapshots")
struct ProvenanceCardSnapshotTests {

    // MARK: - with-quote

    /// ProvenanceCard — full model with a pull-quote.
    /// Renders: "SAVED FROM" eyebrow (play.fill glyph + caps) + source thumb placeholder +
    /// "@saltinmycoffee" display-face handle + "Reel · 'Lisbon in 48 hours' · 0:42" meta +
    /// "View" lifted pill (surfaceGrouped + rest shadow) + italic display-face pull-quote.
    /// Confirms that the eyebrow, row, and quote line all co-occur — no unit test can verify that.
    @Test("with-quote — eyebrow + thumb + handle/meta + View pill + italic quote co-occur")
    @MainActor func withQuote() {
        assertDesignSnapshot(
            cardCanvas {
                ProvenanceCard(
                    model: ProvenanceCard.Model(
                        sourceHandle: "@saltinmycoffee",
                        meta: "Reel · \u{201C}Lisbon in 48 hours\u{201D} · 0:42",
                        quote: "\u{201C}The ceviche under that giant octopus is the best meal I had all trip \u{2014} go at opening, no reservations.\u{201D}"
                    )
                )
            },
            named: "with-quote"
        )
    }

    // MARK: - no-quote

    /// ProvenanceCard — quoteless model (no pull-quote).
    /// Renders: "SAVED FROM" eyebrow + source thumb + "@saltinmycoffee" handle +
    /// "Screenshot · saved Apr 12" meta + "View" pill.
    /// Confirms the quote line is truly absent (no invisible vertical padding below the row).
    @Test("no-quote — eyebrow + thumb + handle/meta + View pill; quote line absent (no vertical gap)")
    @MainActor func noQuote() {
        assertDesignSnapshot(
            cardCanvas {
                ProvenanceCard(
                    model: ProvenanceCard.Model(
                        sourceHandle: "@saltinmycoffee",
                        meta: "Screenshot \u{00B7} saved Apr 12"
                    )
                )
            },
            named: "no-quote"
        )
    }
}

// MARK: - Canvas helper

/// Wraps a ProvenanceCard in a surfacePage canvas matching the #Preview padding (Spacing.screenInset).
@MainActor
private func cardCanvas<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(Spacing.screenInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorRole.surfacePage)
}
