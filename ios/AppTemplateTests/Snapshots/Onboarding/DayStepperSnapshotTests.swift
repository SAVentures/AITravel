// DayStepperSnapshotTests.swift — Layer 3 render-snapshot lock for DayStepper.
//
// These tests are the lock on DayStepper at authoring time. They do not verify the
// design (that is the fidelity-reviewer's job); they freeze the accepted render so any
// later change that silently moves a pixel — glyph button color, value face typography,
// enabled/disabled button ink, capsule shape — fails the build. (07-testing §6 governing doc.)
//
// States covered (one snapshot each, per 07-testing §6.2):
//   min           — value at lower bound (1): decrement button is textTertiary (disabled);
//                   increment button is textPrimary (enabled).
//   typical       — value in mid-range (4): both buttons enabled, tabular numeral face, "days" unit.
//   max           — value at upper bound (14): increment button is textTertiary (disabled);
//                   decrement button is textPrimary (enabled). Locks the upper-bound disabled state.
//   double-digit  — value 10: confirms the fixed-width number slot holds its width for a two-digit
//                   value — the hidden sizer (range.upperBound = 14) reserves the widest width so
//                   the ± buttons do not shift between 9 and 10 (DayStepper.swift line 80–84).
//
// The stepper is embedded in a surfacePage canvas matching the #Preview padding so the
// PNG shows it in the context a real onboarding screen provides.
//
// Determinism (07-testing §6.4):
//   · No Date() — DayStepper is a pure display component with no clock dependency.
//   · No withAnimation — snapshots at rest; press animations are never triggered.
//   · designSystemEnvironment() (inside assertDesignSnapshot) injects .disablesOneShotMotion = true
//     and registers embedded fonts — no per-file setup needed.
//   · The value is passed as a constant Int; onChange is a no-op so no state mutation occurs.
//   · SampleData is not required; DayStepper takes value-type arguments only.
//
// Baselines land in __Snapshots__/DayStepperSnapshotTests/ alongside this file
// and are committed as the visual contract. First run records and fails with "recorded";
// commit the PNGs; subsequent runs diff. Never leave record: .all in committed code.

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("DayStepper snapshots")
struct DayStepperSnapshotTests {

    // MARK: - min

    /// Value at lower bound (1 of 1…14). The decrement button is disabled and renders in
    /// textTertiary ink; the increment button is enabled and renders in textPrimary.
    /// Confirms the disabled/enabled button ink co-occurs with the correct boundary value.
    @Test("min — value 1, lower bound: decrement disabled (textTertiary), increment enabled (textPrimary)")
    @MainActor func min_() {
        assertDesignSnapshot(
            canvas {
                DayStepper(value: 1, range: 1...14, onChange: { _ in })
            },
            named: "min"
        )
    }

    // MARK: - typical

    /// Value in mid-range (4 of 1…14). Both buttons are enabled; the value face shows "4" in
    /// tabular numerals with "days" in footnote mono. Confirms the co-occurrence of the numeral
    /// + unit face + enabled ± buttons.
    @Test("typical — value 4, mid-range: both buttons enabled, numeral + days unit face")
    @MainActor func typical() {
        assertDesignSnapshot(
            canvas {
                DayStepper(value: 4, range: 1...14, onChange: { _ in })
            },
            named: "typical"
        )
    }

    // MARK: - max

    /// Value at upper bound (14 of 1…14). The increment button is disabled and renders in
    /// textTertiary ink; the decrement button is enabled and renders in textPrimary.
    /// Confirms the upper-bound disabled state co-occurs with the correct (14) value display.
    @Test("max — value 14, upper bound: increment disabled (textTertiary), decrement enabled (textPrimary)")
    @MainActor func max_() {
        assertDesignSnapshot(
            canvas {
                DayStepper(value: 14, range: 1...14, onChange: { _ in })
            },
            named: "max"
        )
    }

    // MARK: - double-digit

    /// Value 10 of 1…14 — the first double-digit value in the range. Locks the fixed-width
    /// number slot: the hidden sizer reserves `range.upperBound` ("14") width so the capsule
    /// does not expand when the value crosses from "9" to "10" (DayStepper.swift line 80–84).
    /// Both ± buttons are enabled; the value face shows "10 days".
    @Test("double-digit — value 10: fixed-width slot stable, both buttons enabled, 10 days")
    @MainActor func doubleDigit() {
        assertDesignSnapshot(
            canvas {
                DayStepper(value: 10, range: 1...14, onChange: { _ in })
            },
            named: "double-digit"
        )
    }
}

// MARK: - Canvas helper

/// Wraps the stepper in a surfacePage canvas with the same padding as the #Preview
/// in DayStepper.swift. Not a full-bleed screen; the stepper is a component (§6.2).
@MainActor
private func canvas<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorRole.surfacePage)
}
