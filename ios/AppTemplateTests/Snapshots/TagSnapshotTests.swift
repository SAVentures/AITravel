// TagSnapshotTests.swift — Layer 3 render-snapshot lock for Tag (07-testing §6).
//
// Locks the two key states of `Tag` against the canonical iPhone 17 Pro viewport.
// Any later change that silently shifts the capsule fill, dot size, tracking, font,
// spacing, or radius will fail the build here.
//
// States covered:
//   default      — Tag(.neutral): fill-only capsule, no leading dot.
//   state-mark   — Tag(.now):     stateNow accent dot + label, co-occurring in one frame.
//
// Governing rules (07-testing §6.1–6.4):
//   • One snapshot per state — thin lock.
//   • Rendered at rest — no `withAnimation`, no live clock.
//   • `designSystemEnvironment()` registers fonts and injects `.disablesOneShotMotion`.
//   • No `record: .all` left in committed code.
//   • Baselines land in __Snapshots__/TagSnapshotTests/ alongside this file and are committed.

import Testing
import SwiftUI
@testable import AppTemplate

@Suite("Tag snapshots")
struct TagSnapshotTests {

    // MARK: - default

    /// Neutral fill-only capsule — no leading dot.
    @Test("default — neutral fill-only capsule, no leading dot")
    @MainActor func default_() {
        assertDesignSnapshot(
            Tag("Ramen"),
            named: "default"
        )
    }

    // MARK: - state-mark

    /// Live/now variant — a single leading `stateNow` dot co-occurring with the label in one frame.
    /// Locks both the dot render and the horizontal spacing between dot and text simultaneously
    /// (no unit test can confirm this co-occurrence — §6, L3 rationale).
    @Test("state-mark — stateNow accent dot co-occurring with label")
    @MainActor func stateMark() {
        assertDesignSnapshot(
            Tag("Open now", mark: .now),
            named: "state-mark"
        )
    }
}
