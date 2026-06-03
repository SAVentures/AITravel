// AIVoiceSnapshotTests.swift — Layer 3 render-snapshot lock for AIVoice (07-testing §6).
//
// Locks the single key state of `AIVoice` against the canonical iPhone 17 Pro viewport.
// Any later change that silently shifts the eyebrow tracking, accent dot size, italic
// display font, line spacing, or ink will fail the build here.
//
// State covered:
//   default — AIVoice(eyebrow:line:): accent dot + mono caps eyebrow + italic voice line,
//             all co-occurring in one frame. The line is long enough to wrap naturally at
//             a representative content column width, locking the multi-line italic render.
//
// Governing rules (07-testing §6.1–6.4):
//   • One snapshot per state — thin lock.
//   • Rendered at rest — no `withAnimation`, no live clock.
//   • `designSystemEnvironment()` registers fonts and injects `.disablesOneShotMotion`.
//   • No `record: .all` left in committed code.
//   • Baselines land in __Snapshots__/AIVoiceSnapshotTests/ alongside this file and are committed.

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("AIVoice snapshots")
struct AIVoiceSnapshotTests {

    // MARK: - default

    /// The full AIVoice anatomy: stateNow accent dot + mono caps eyebrow + italic display
    /// voice line — all co-occurring in one frame. The voice line is long enough to wrap
    /// at a representative content width, locking the natural multi-line italic render.
    /// No unit test can confirm the co-occurrence of dot, eyebrow tracking, and italic
    /// display face simultaneously (07-testing §6 L3 rationale).
    @Test("default")
    @MainActor func default_() {
        assertDesignSnapshot(
            AIVoice(
                eyebrow: "ITINERARY",
                line: "A slow morning in the old town, then the coast before the light goes."
            )
            // Constrain to a representative content column so the italic display line
            // wraps naturally — matching authoring context (the #Preview uses cardInset
            // padding on a full-width container). Leading-aligned, top of column.
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading),
            named: "default"
        )
    }
}
