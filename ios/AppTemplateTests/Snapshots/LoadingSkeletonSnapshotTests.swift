// LoadingSkeletonSnapshotTests.swift — Layer 3 render-snapshot lock for LoadingSkeleton
// (07-testing §6).
//
// Locks the settled (shimmer-at-rest) state of `LoadingSkeleton` against the canonical
// iPhone 17 Pro viewport. Any later change that silently shifts the bar height, square
// size, spacing, fill color, corner radius, shadow, or card surface will fail the build.
//
// States covered:
//   default  — LoadingSkeleton(rowCount: 3), shimmer parked off-screen at rest.
//              Motion is disabled via the `\.disablesOneShotMotion` seam already injected
//              by `designSystemEnvironment()` — no mid-sweep frame is captured.
//
// Governing rules (07-testing §6.1–6.4):
//   • One snapshot per state — thin lock.
//   • Rendered at rest — no `withAnimation`, no live clock, no `Date()`.
//   • `designSystemEnvironment()` registers fonts and injects `.disablesOneShotMotion = true`
//     so the shimmer settles (shimmer opacity → 0, sweep state stays false) before capture.
//   • No `record: .all` left in committed code.
//   • Baseline lands in __Snapshots__/LoadingSkeletonSnapshotTests/ alongside this file
//     and is committed — it is the contract (07-testing §6.3).

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("LoadingSkeleton snapshots")
@MainActor
struct LoadingSkeletonSnapshotTests {

    // MARK: - default

    /// Three redacted rows on a grouped surface, shimmer parked off-screen at rest.
    ///
    /// `designSystemEnvironment()` already injects `\.disablesOneShotMotion = true`, so
    /// `LoadingSkeleton.motionDisabled` is `true`, `sweeping` stays `false`, and the shimmer
    /// overlay opacity is 0 — the frame is fully settled before capture (07-testing §6.4).
    @Test("default — three rows, shimmer at rest")
    func default_() {
        assertDesignSnapshot(
            LoadingSkeleton(rowCount: 3),
            named: "default"
        )
    }
}
