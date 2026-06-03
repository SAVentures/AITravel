// ContextNoteSnapshotTests.swift — Layer 3 render-snapshot lock for ContextNote.
//
// These tests are the lock on ContextNote at authoring time. They do not verify the
// design (that is the fidelity-reviewer's job); they freeze the accepted render so any
// later change that silently moves a pixel — eyebrow caps typography, body text weight
// emphasis, leading glyph color, surfacePage card fill — fails the build.
// (07-testing §6 governing doc.)
//
// States covered (one snapshot each, per 07-testing §6.2):
//   with-emphasis — note with a systemImage glyph, eyebrow, body text, and an emphasized
//                   span rendered in semibold textPrimary weight (never an alarm color).
//                   Confirms that the emphasized span co-occurs with the correct glyph +
//                   eyebrow + body ink — no unit test can confirm that co-occurrence.
//   text-only     — note with no systemImage: the glyph column is absent, eyebrow and body
//                   render flush to the leading edge. Confirms the optional systemImage slot
//                   is truly absent (no empty horizontal gap).
//
// The note is embedded in a surfacePage canvas with the same padding as the #Preview
// in ContextNote.swift so the PNG shows it in the context a real onboarding screen provides.
//
// Determinism (07-testing §6.4):
//   · No Date() — ContextNote is a pure display component with no clock dependency.
//   · No withAnimation — snapshot at rest.
//   · designSystemEnvironment() (inside assertDesignSnapshot) injects .disablesOneShotMotion = true
//     and registers embedded fonts — no per-file setup needed.
//   · Fixtures mirror the #Preview values in ContextNote.swift exactly.
//   · SampleData is not required; ContextNote takes value-type arguments only.
//
// Baselines land in __Snapshots__/ContextNoteSnapshotTests/ alongside this file
// and are committed as the visual contract. First run records and fails with "recorded";
// commit the PNGs; subsequent runs diff. Never leave record: .all in committed code.

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("ContextNote snapshots")
struct ContextNoteSnapshotTests {

    // MARK: - with-emphasis

    /// ContextNote with a leading glyph and an emphasized span.
    /// Renders: cloud.rain glyph (textTertiary) + "FOR YOUR DATES" caps eyebrow +
    /// body with "Rain 2 of 4 days" in semibold textPrimary; rest of body is textSecondary.
    /// Confirms all three emphasis signals (weight, color, glyph) co-occur in one frame.
    @Test("with-emphasis — systemImage glyph + caps eyebrow + semibold-emphasis span co-occur")
    @MainActor func withEmphasis() {
        assertDesignSnapshot(
            canvas {
                ContextNote(
                    eyebrow: "For your dates",
                    text: "Rain 2 of 4 days — transit keeps the plan dry without changing the shape.",
                    emphasis: ["Rain 2 of 4 days"],
                    systemImage: "cloud.rain"
                )
            },
            named: "with-emphasis"
        )
    }

    // MARK: - text-only

    /// ContextNote with no systemImage and no emphasis spans.
    /// The glyph column is absent; the eyebrow and body render flush to the leading edge.
    /// Confirms the systemImage slot is truly omitted (no invisible gap).
    @Test("text-only — no systemImage, no emphasis: eyebrow + body flush leading, no glyph gap")
    @MainActor func textOnly() {
        assertDesignSnapshot(
            canvas {
                ContextNote(
                    eyebrow: "Lots of saves here",
                    text: "We can lean on the 23 places you've already saved."
                )
            },
            named: "text-only"
        )
    }
}

// MARK: - Canvas helper

/// Wraps the note in a surfacePage canvas with the same padding as the #Preview
/// in ContextNote.swift. Not a full-bleed screen; the note is a component (§6.2).
@MainActor
private func canvas<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(Spacing.screenInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorRole.surfacePage)
}
