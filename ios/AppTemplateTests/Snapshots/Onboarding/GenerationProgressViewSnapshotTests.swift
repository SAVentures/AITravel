// GenerationProgressViewSnapshotTests.swift — Layer 3 render-snapshot lock for GenerationProgressView.
//
// Governing doc: ios/docs/engineering/07-testing.md §6 (render snapshots — the lock).
//
// States covered (§6.2 — one snapshot per key state):
//   mid-progress  — 3 done · 1 current (italic + stateNow accent) · 2 pending;
//                   heartbeat sweep parked at static rest (motionDisabled = true via
//                   designSystemEnvironment); handoff peek card visible but faint.
//   near-complete — 5 done · 1 current (last step); same heartbeat park; handoff visible.
//
// Both states mirror the named #Preview fixtures in GenerationProgressView.swift. Each locks
// a distinct configuration of the GenerationStepRow glyph vocabulary (done=filled-disc +
// checkmark; current=stateNow-ring; pending=hollow-ring) and the body-line typography
// (italic name for current, receded body for done/pending). One snapshot captures all
// simultaneously — no unit test can confirm that co-occurrence.
//
// The heartbeat sweep (HeartbeatSweep) reads \.disablesOneShotMotion and parks to its static
// rest frame (a 40%-opacity neutral bar). designSystemEnvironment() injects that key so the
// capture is always the settled frame — never a mid-animation position.
//
// Ground: surfacePage background + screenInset padding (matching the preview context).
//
// Determinism (§6.4):
//   - No Date() — GenerationProgressView carries no time state.
//   - No withAnimation — rendered at rest; HeartbeatSweep parks via disablesOneShotMotion.
//   - designSystemEnvironment() injects \.disablesOneShotMotion = true.
//   - Fixtures mirror the named previews exactly (same ids, text, detail, status).
//   - No record: .all left in committed code.

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("GenerationProgressView snapshots")
@MainActor
struct GenerationProgressViewSnapshotTests {

    // MARK: - Fixtures
    //
    // Mirror the private preview fixtures in GenerationProgressView.swift — same step ids,
    // text, optional detail strings, and status values. Kept as local constants so the test
    // is self-contained.

    private let midProgressSteps: [GenerationStepVM] = [
        GenerationStepVM(id: "cluster",
                         text: "Grouping your 23 places by neighborhood",
                         detail: "5 clusters found",
                         status: .done),
        GenerationStepVM(id: "days",
                         text: "Clustering into 4 days",
                         detail: "Alfama · Belém · Bairro Alto · Parque",
                         status: .done),
        GenerationStepVM(id: "route",
                         text: "Routing each day to minimize backtracking",
                         detail: "2 loops · 1 line · 1 hub",
                         status: .done),
        GenerationStepVM(id: "sequence",
                         text: "Sequencing the days so they flow geographically",
                         status: .current),
        GenerationStepVM(id: "meals",
                         text: "Spacing meals and rest",
                         status: .pending),
        GenerationStepVM(id: "tips",
                         text: "Adding context-aware tips",
                         status: .pending),
    ]

    private let nearCompleteSteps: [GenerationStepVM] = [
        GenerationStepVM(id: "cluster",
                         text: "Grouping your 23 places by neighborhood",
                         detail: "5 clusters found",
                         status: .done),
        GenerationStepVM(id: "days",
                         text: "Clustering into 4 days",
                         status: .done),
        GenerationStepVM(id: "route",
                         text: "Routing each day to minimize backtracking",
                         status: .done),
        GenerationStepVM(id: "sequence",
                         text: "Sequencing the days so they flow geographically",
                         status: .done),
        GenerationStepVM(id: "meals",
                         text: "Spacing meals and rest",
                         status: .done),
        GenerationStepVM(id: "tips",
                         text: "Adding context-aware tips",
                         status: .current),
    ]

    private let handoff = HandoffVM(
        title: "Up next · Trip overview",
        subtitle: "Lisbon · 4 days, your shape."
    )

    // MARK: - Helpers

    private func container<C: View>(_ content: C) -> some View {
        content
            .padding(Spacing.screenInset)
            .background(ColorRole.surfacePage)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Snapshots

    @Test("mid-progress — 3 done, 1 current (stateNow ring + italic), 2 pending; sweep at rest; handoff visible")
    func midProgress() {
        assertDesignSnapshot(
            container(
                GenerationProgressView(
                    steps: midProgressSteps,
                    handoff: handoff
                )
            ),
            named: "mid-progress"
        )
    }

    @Test("near-complete — 5 done, 1 current (last); sweep at rest; handoff visible")
    func nearComplete() {
        assertDesignSnapshot(
            container(
                GenerationProgressView(
                    steps: nearCompleteSteps,
                    handoff: handoff
                )
            ),
            named: "near-complete"
        )
    }

    // MARK: - mid-progress-ax5

    /// AX5 compensating snapshot (§7.4). Same fixture as `midProgress` (3 done, 1 current,
    /// 2 pending) but rendered at accessibilityExtraExtraExtraLarge (AX5) to lock Dynamic Type
    /// scaling of all GenerationStepRow glyph+typography states simultaneously: done body
    /// (receded), current body (italic stateNow accent), pending body (receded), and the
    /// optional detail lines. This is the most type-dense state — it exercises every step
    /// status variant in a single frame at maximum text size. Freezes any regression where a
    /// fixed row height or font-size token change clips or overflows step rows at AX5.
    /// Glass-free component — renders fully at AX5.
    /// (Task 3.4 — restores the AX5 compensating control lost per decisions.md 2026-06-03.)
    @Test("mid-progress-ax5 — AX5 Dynamic Type: 3 done + 1 current + 2 pending at accessibilityXXXL")
    func midProgressAX5() {
        assertDesignSnapshot(
            container(
                GenerationProgressView(
                    steps: midProgressSteps,
                    handoff: handoff
                )
            )
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge),
            named: "mid-progress-ax5"
        )
    }
}
