// ConfirmationRowSnapshotTests.swift — Layer 3 render-snapshot lock for ConfirmationRow.
//
// These tests are the lock on ConfirmationRow at authoring time. They do not verify the design
// (that is the fidelity-reviewer's job); they freeze the accepted render so any later change
// that silently moves a pixel — surfaceGrouped ground, mono-caps key eyebrow, large mono
// confirmation code, copy button glyph and neutral tint — fails the build.
// (07-testing §6 governing doc.)
//
// States covered (one snapshot each, per 07-testing §6.2):
//   confirmation-row — the one meaningful state: code "7XQK2M", copy button present.
//                      Renders: surfaceGrouped row + mono-caps "CONFIRMATION" key eyebrow +
//                      large selectable mono code "7XQK2M" + trailing neutral copy button
//                      (doc.on.clipboard glyph). Confirms all four zones co-occur.
//
// Determinism (07-testing §6.4):
//   · No Date() — ConfirmationRow is a pure display component.
//   · No withAnimation — snapshot at rest.
//   · designSystemEnvironment() registers fonts + injects .disablesOneShotMotion = true.
//   · Fixture mirrors the #Preview code "7XQK2M" in ConfirmationRow.swift.
//   · No SampleData required — ConfirmationRow takes a plain String.
//
// Baselines land in __Snapshots__/ConfirmationRowSnapshotTests/ alongside this file
// and are committed as the visual contract. First run records and fails with "recorded";
// commit the PNGs. Do NOT leave record: .all in committed code (§6.3).

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("ConfirmationRow snapshots")
struct ConfirmationRowSnapshotTests {

    // MARK: - confirmation-row

    /// ConfirmationRow: the one meaningful display state.
    /// Renders: surfaceGrouped row + mono-caps key eyebrow + large selectable mono "7XQK2M"
    /// code + trailing neutral copy button (doc.on.clipboard glyph, never the accent).
    /// Confirms the key, code, and copy affordance all co-occur in a single frame.
    @Test("confirmation-row — surfaceGrouped row: mono-caps key + large mono code + neutral copy button")
    @MainActor func confirmationRow() {
        assertDesignSnapshot(
            rowCanvas {
                ConfirmationRow(
                    code: "7XQK2M",
                    onCopy: {},
                    accessibilityID: "booking.confirmation"
                )
            },
            named: "confirmation-row"
        )
    }
}

// MARK: - Canvas helper

/// Wraps the row in a surfacePage canvas matching the ConfirmationRow #Preview padding.
@MainActor
private func rowCanvas<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(Spacing.screenInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorRole.surfacePage)
}
