// DetailListSnapshotTests.swift — Layer 3 render-snapshot lock for DetailList.
//
// These tests are the lock on DetailList at authoring time. They do not verify the design
// (that is the fidelity-reviewer's job); they freeze the accepted render so any later change
// that silently moves a pixel — mono-caps section head, surfaceGrouped card ground, per-row
// hairline separators, secondary key / emphasized value typography, last-row no-separator
// rule — fails the build.
// (07-testing §6 governing doc.)
//
// States covered (one snapshot each, per 07-testing §6.2):
//   flight-detail      — 5-row flight list: head "Flight details" + Airline/Flight/
//                        Departs/Arrives/Aircraft rows. The complete flight detail fixture
//                        from the DetailList #Preview. Confirms: head, all five rows with
//                        hairline separators (last row has none), and the surfaceGrouped card
//                        all co-occur.
//   flight-detail-ax5  — AX5 compensating snapshot (§7.4). Same fixture as flight-detail at
//                        .accessibilityExtraExtraExtraLarge. Locks Dynamic Type scaling of the
//                        mono-caps section head and the secondary key / emphasized value text
//                        pairs at the largest accessibility size category. Glass-free — renders
//                        fully at AX5.
//
// Determinism (07-testing §6.4):
//   · No Date() — DetailList is a pure display component.
//   · No withAnimation — snapshot at rest.
//   · designSystemEnvironment() registers fonts + injects .disablesOneShotMotion = true.
//   · Fixtures mirror the [DetailRow].flight preview array in DetailList.swift exactly.
//   · No SampleData required — DetailList takes value-type [DetailRow].
//
// Baselines land in __Snapshots__/DetailListSnapshotTests/ alongside this file
// and are committed as the visual contract. First run records and fails with "recorded";
// commit the PNGs. Do NOT leave record: .all in committed code (§6.3).

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("DetailList snapshots")
struct DetailListSnapshotTests {

    // MARK: - Shared fixture (mirrors [DetailRow].flight in DetailList.swift)
    //
    // nonisolated let: DetailRow is a nonisolated Sendable value type — safe to create
    // outside @MainActor. Captured by the @MainActor test methods below. (§6.6)

    nonisolated static let flightRows: [DetailRow] = [
        DetailRow(key: "Airline", value: "TAP Air Portugal"),
        DetailRow(key: "Flight", value: "TP 201"),
        DetailRow(key: "Departs", value: "Sat 13:40 · LIS"),
        DetailRow(key: "Arrives", value: "Sat 18:05 · JFK"),
        DetailRow(key: "Aircraft", value: "A330neo"),
    ]

    // MARK: - flight-detail

    /// DetailList: 5-row flight detail — the canonical flight fixture from #Preview.
    /// Renders: "FLIGHT DETAILS" mono-caps head + surfaceGrouped card (Radius.card) containing
    /// five key→value rows — Airline/TAP Air Portugal, Flight/TP 201, Departs/Sat 13:40 · LIS,
    /// Arrives/Sat 18:05 · JFK, Aircraft/A330neo — each separated by a 1pt hairline except
    /// the last row. Confirms the head, all rows, separators, and last-row no-separator
    /// rule all co-occur in one frame.
    @Test("flight-detail — 5-row flight: head + surfaceGrouped card + rows + hairlines + last-row no-sep")
    @MainActor func flightDetail() {
        assertDesignSnapshot(
            listCanvas {
                DetailList(head: "Flight details", rows: Self.flightRows)
            },
            named: "flight-detail"
        )
    }

    // MARK: - flight-detail-ax5

    /// AX5 compensating snapshot (§7.4). Same fixture as flight-detail at
    /// accessibilityExtraExtraExtraLarge. Locks Dynamic Type scaling of the mono-caps
    /// "FLIGHT DETAILS" section head, the secondary key labels, and the emphasized value
    /// labels at the largest accessibility size category. The card grows vertically —
    /// no fixed frame clips. Glass-free — renders fully at AX5.
    @Test("flight-detail-ax5 — AX5: mono-caps head + key/value text pairs scale at accessibilityXXXL")
    @MainActor func flightDetailAX5() {
        assertDesignSnapshot(
            listCanvas {
                DetailList(head: "Flight details", rows: Self.flightRows)
            }
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge),
            named: "flight-detail-ax5"
        )
    }
}

// MARK: - Canvas helper

/// Wraps the list in a surfacePage canvas matching the DetailList #Preview padding.
@MainActor
private func listCanvas<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(Spacing.screenInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorRole.surfacePage)
}
