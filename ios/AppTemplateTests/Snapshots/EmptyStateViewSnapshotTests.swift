// EmptyStateViewSnapshotTests.swift — Layer 3 render-snapshot lock for EmptyStateView (07-testing §6).
//
// Locks the key state of `EmptyStateView` against the canonical iPhone 17 Pro viewport.
// Any later change that silently shifts the glyph size, message typography, card surface,
// button placement, spacing, or ink will fail the build here.
//
// States covered:
//   default  — monochrome SF Symbol glyph + one editorial message + one secondary PillButton action,
//              all co-occurring in one frame (no unit test can confirm this co-occurrence — §6, L3).
//
// Governing rules (07-testing §6.1–6.4):
//   • One snapshot per state — thin lock.
//   • Rendered at rest — no `withAnimation`, no live clock.
//   • `designSystemEnvironment()` registers fonts and injects `.disablesOneShotMotion`.
//   • No `record: .all` left in committed code.
//   • Baselines land in __Snapshots__/EmptyStateViewSnapshotTests/ alongside this file and are committed.

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("EmptyStateView snapshots")
@MainActor
struct EmptyStateViewSnapshotTests {

    // MARK: - default

    /// The full component: a monochrome bookmark glyph, one editorial message line, and one
    /// secondary-tier PillButton action. Locks all three co-occurring signals — glyph ink,
    /// message typography, card surface, and button placement — in a single frame.
    @Test("default — glyph + message + secondary action at rest")
    func default_() {
        assertDesignSnapshot(
            EmptyStateView(
                systemImage: "bookmark",
                message: "No saved places in Lisbon yet.",
                actionTitle: "Add a place"
            ) {},
            named: "default"
        )
    }
}
