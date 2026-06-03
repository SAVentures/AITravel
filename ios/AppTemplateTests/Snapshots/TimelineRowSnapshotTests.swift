// TimelineRowSnapshotTests.swift — Layer 3 render-snapshot lock for TimelineRow + TransitConnector.
//
// Governing doc: ios/docs/engineering/07-testing.md §6 (the lock).
//
// CONTRACT: one assertion per state, rendered over the local RailStage ground so the rail surface and
// dots read exactly as they do in the authoring previews (the same ground the mockup uses). The
// private `RailStage` from TimelineRow.swift is not accessible here — `LocalRailStage` below
// reproduces its exact layout and tokens.
//
// States covered (10):
//   TimelineRow  — stop-definitive, stop-now, stop-fuzzy
//                — accessory-chevron, accessory-switch, accessory-inline, accessory-check
//   TransitConnector — connector-single, connector-multileg, connector-ways
//
// Determinism (§6.4):
//   • No `Date()` / live clock — components take value-type fixtures only.
//   • No `withAnimation` — snapshots are at rest.
//   • `designSystemEnvironment()` (called inside `assertDesignSnapshot`) injects
//     `\.disablesOneShotMotion = true`, so no one-shot entrance flake.
//   • No `record: .all` — first run records, subsequent runs diff.

import Testing
import SwiftUI
@testable import AppTemplate

// MARK: - Local rail stage (mirrors the private RailStage in TimelineRow.swift)

/// Reproduces the private `RailStage` preview scaffold from `TimelineRow.swift` verbatim using the
/// same semantic tokens, so component dots read against the correct card surface ground.
/// This is a test-file-only fixture — never ship to the app target.
private struct LocalRailStage<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .padding(.horizontal, Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ColorRole.surfaceGrouped, in: .rect(cornerRadius: Radius.card))
            .padding(Spacing.screenInset)
            .background(ColorRole.surfacePage)
    }
}

// MARK: - Snapshot tests

/// Layer 3 lock for `TimelineRow` (all registers + all accessories) and `TransitConnector`
/// (all registers). One assertion per state — see §6.2.
@Suite("TimelineRow snapshots")
@MainActor
struct TimelineRowSnapshotTests {

    // MARK: TimelineRow — register states

    /// Lock: definitive register — solid ink dot, roman name, exact mono fact, chevron accessory.
    @Test("stop-definitive — solid ink dot, roman name, exact mono fact")
    func stopDefinitive() {
        assertDesignSnapshot(
            LocalRailStage {
                TimelineRow(.init(
                    name: "Tsuta ramen",
                    meta: "OPENS 08:00 · RAMEN",
                    fact: "08:00",
                    register: .definitive,
                    accessory: .chevron
                ))
            },
            named: "stop-definitive"
        )
    }

    /// Lock: now register — static ring mark, stateNow ink, roman name.
    @Test("stop-now — static ring mark, stateNow ink, roman name")
    func stopNow() {
        assertDesignSnapshot(
            LocalRailStage {
                TimelineRow(.init(
                    name: "Yanaka cemetery walk",
                    meta: "NOW · QUIET MORNING",
                    fact: "now",
                    register: .now
                ))
            },
            named: "stop-now"
        )
    }

    /// Lock: fuzzy register — recessive fillSecondary dot, italic name in textSecondary ink, "~" fact.
    @Test("stop-fuzzy — fillSecondary dot, italic textSecondary name, tilde fact")
    func stopFuzzy() {
        assertDesignSnapshot(
            LocalRailStage {
                TimelineRow(.init(
                    name: "somewhere for lunch",
                    meta: "~ 13:00 · FLEXIBLE",
                    fact: "~1:00",
                    register: .fuzzy
                ))
            },
            named: "stop-fuzzy"
        )
    }

    // MARK: TimelineRow — accessory states

    /// Lock: chevron accessory — disclosure glyph in textSecondary, drills in (push contract).
    @Test("accessory-chevron — disclosure glyph, textSecondary ink")
    func accessoryChevron() {
        assertDesignSnapshot(
            LocalRailStage {
                TimelineRow(.init(
                    name: "Chevron",
                    meta: "DRILLS INTO A CHILD",
                    register: .definitive,
                    accessory: .chevron
                ))
            },
            named: "accessory-chevron"
        )
    }

    /// Lock: toggle accessory — UISwitch tinted actionPrimary, showing the on state, toggles in place.
    @Test("accessory-switch — actionPrimary UISwitch, on state")
    func accessorySwitch() {
        assertDesignSnapshot(
            LocalRailStage {
                TimelineRow(.init(
                    name: "Switch",
                    meta: "TOGGLES IN PLACE",
                    register: .definitive,
                    accessory: .toggle(true)
                ))
            },
            named: "accessory-switch"
        )
    }

    /// Lock: inline accessory — verb-led label "Remove" in actionPrimary, one discrete action.
    @Test("accessory-inline — verb-led actionPrimary label")
    func accessoryInline() {
        assertDesignSnapshot(
            LocalRailStage {
                TimelineRow(.init(
                    name: "Inline action",
                    meta: "ONE DISCRETE ACTION",
                    register: .definitive,
                    accessory: .inline("Remove")
                ))
            },
            named: "accessory-inline"
        )
    }

    /// Lock: check accessory — checkmark glyph in actionPrimary, selected-in-choice contract.
    @Test("accessory-check — checkmark glyph, actionPrimary ink")
    func accessoryCheck() {
        assertDesignSnapshot(
            LocalRailStage {
                TimelineRow(.init(
                    name: "Check",
                    meta: "SELECTED, IN A CHOICE",
                    register: .definitive,
                    accessory: .check
                ))
            },
            named: "accessory-check"
        )
    }

    // MARK: TransitConnector — register states

    /// Lock: singleMode — one mode glyph + mono fact, recessive textSecondary ink.
    @Test("connector-single — one mode glyph, textSecondary mono fact")
    func connectorSingle() {
        assertDesignSnapshot(
            LocalRailStage {
                TransitConnector(.singleMode(
                    .init(systemImage: "figure.walk", fact: "8 min · walk")
                ))
            },
            named: "connector-single"
        )
    }

    /// Lock: multiLeg — leg → recessive arrow → leg chain in textSecondary, joined by textTertiary "→".
    @Test("connector-multileg — leg chain, textSecondary/textTertiary arrows")
    func connectorMultileg() {
        assertDesignSnapshot(
            LocalRailStage {
                TransitConnector(.multiLeg([
                    .init(systemImage: "tram.fill", fact: "Rossio → Sintra · 40 min"),
                    .init(systemImage: "figure.walk", fact: "15 min · uphill"),
                ]))
            },
            named: "connector-multileg"
        )
    }

    /// Lock: ways — "WAYS" eyebrow + glyph-count pills; selected pill is solid-ink capsule (not accent).
    @Test("connector-ways — WAYS eyebrow, glyph-count pills, solid-ink selected capsule")
    func connectorWays() {
        assertDesignSnapshot(
            LocalRailStage {
                TransitConnector(.ways([
                    .init(systemImage: "figure.walk", count: "12"),
                    .init(systemImage: "tram.fill",   count: "6", isSelected: true),
                    .init(systemImage: "bus.fill",    count: "4"),
                ]))
            },
            named: "connector-ways"
        )
    }
}
