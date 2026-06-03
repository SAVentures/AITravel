// TimeHintSnapshotTests.swift — Layer 3 render-snapshot lock for TimeHint.
//
// One snapshot per state (07-testing §6.2). The `default` state captures the
// representative case: glyph + label + the optional mono measurement range all
// co-occurring in one frame — the co-occurrence no unit test can confirm.
//
// Governing doc: ios/docs/engineering/07-testing.md §6
// Component API:  ios/AppTemplate/DesignSystem/Components/TimeHint.swift

import Testing
import SwiftUI
@testable import AppTemplate

@Suite("TimeHint snapshots")
struct TimeHintSnapshotTests {

    // MARK: - default
    // The representative state: leading glyph, recessive label, and the mono
    // measurement range rendered together. Locks spacing, typography roles,
    // fillQuaternary ground, and pill shape in a single frame.
    @Test("default")
    @MainActor
    func default_() {
        assertDesignSnapshot(
            TimeHint(
                TimeHint.Model(
                    text: "Best light",
                    systemImage: "clock",
                    measurement: "7:30–8:30"
                )
            )
            .padding(Spacing.screenInset),
            named: "default"
        )
    }
}
