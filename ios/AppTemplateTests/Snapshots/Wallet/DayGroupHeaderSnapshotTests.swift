// DayGroupHeaderSnapshotTests.swift — Layer 3 render-snapshot lock for DayGroupHeader.
//
// These tests are the lock on DayGroupHeader at authoring time. They do not verify the design
// (that is the fidelity-reviewer's job); they freeze the accepted render so any later change
// that silently moves a pixel — display number size, mono-caps date eyebrow, filling hairline
// rule weight or color, today vs not-today label treatment — fails the build.
// (07-testing §6 governing doc.)
//
// States covered (one snapshot each, per 07-testing §6.2):
//   today       — dayLabel "Day 2", dateLabel with "· today" suffix, isToday: true.
//                 Confirms: display number + mono-caps date (including the today suffix) +
//                 filling hairline all co-occur at the firstTextBaseline alignment.
//   not-today   — dayLabel "Day 3", dateLabel without suffix, isToday: false.
//                 Confirms: the not-today label renders without the "today" suffix, and
//                 the hairline still fills to the trailing edge.
//
// Determinism (07-testing §6.4):
//   · No Date() — DayGroupHeader is a pure display component; the caller composes the label.
//   · No withAnimation — snapshot at rest.
//   · designSystemEnvironment() registers fonts + injects .disablesOneShotMotion = true.
//   · Fixtures mirror the #Preview values in DayGroupHeader.swift exactly.
//   · No SampleData required — DayGroupHeader takes plain String/Bool args.
//
// Baselines land in __Snapshots__/DayGroupHeaderSnapshotTests/ alongside this file
// and are committed as the visual contract. First run records and fails with "recorded";
// commit the PNGs. Do NOT leave record: .all in committed code (§6.3).

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("DayGroupHeader snapshots")
struct DayGroupHeaderSnapshotTests {

    // MARK: - today

    /// DayGroupHeader: today — Day 2 with the "today" suffix in the date eyebrow.
    /// Renders: display "Day 2" number (Typography.name, textPrimary) + "THU · AUG 27 · TODAY"
    /// mono-caps date eyebrow (Typography.caption, textTertiary) + filling 1pt separator rule.
    /// All three elements align on firstTextBaseline; the rule fills to the trailing edge.
    @Test("today — display day-number + today-suffix date eyebrow + filling rule co-occur")
    @MainActor func today() {
        assertDesignSnapshot(
            headerCanvas {
                DayGroupHeader(
                    dayLabel: "Day 2",
                    dateLabel: "Thu · Aug 27 · today",
                    isToday: true
                )
            },
            named: "today"
        )
    }

    // MARK: - not-today

    /// DayGroupHeader: not-today — Day 3 with no "today" suffix.
    /// Renders: display "Day 3" + "FRI · AUG 28" mono-caps date (no suffix) + filling rule.
    /// Confirms the not-today state renders correctly without the today suffix.
    @Test("not-today — display day-number + date eyebrow (no today suffix) + filling rule")
    @MainActor func notToday() {
        assertDesignSnapshot(
            headerCanvas {
                DayGroupHeader(
                    dayLabel: "Day 3",
                    dateLabel: "Fri · Aug 28",
                    isToday: false
                )
            },
            named: "not-today"
        )
    }
}

// MARK: - Canvas helper

/// Wraps a DayGroupHeader in a surfacePage canvas at full width, matching the #Preview padding.
@MainActor
private func headerCanvas<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorRole.surfacePage)
}
