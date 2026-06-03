// OnboardingProgressBarSnapshotTests.swift — Layer 3 render-snapshot lock for OnboardingProgressBar.
//
// These tests are the lock on OnboardingProgressBar at authoring time. They do not
// verify the design (that is the fidelity-reviewer's job); they freeze the accepted
// render so any later change that silently moves a pixel — segment color ramp, counter
// typography, spacing — fails the build. (07-testing §6 governing doc.)
//
// States covered (one snapshot each, per 07-testing §6.2):
//   step-0  — stepIndex 0: one "cur" ink segment, five "todo" separator segments, counter "01 / 06"
//   step-2  — stepIndex 2: two "done" tertiary segments, one "cur" ink segment, three "todo"
//   step-4  — stepIndex 4: four "done" tertiary segments, one "cur" ink segment, one "todo", counter "05 / 06"
//   step-5  — stepIndex 5 (final, totalSteps default 6): five "done" tertiary segments, one "cur"
//             ink segment, counter "06 / 06". Locks the six-segment default and the final-step state.
//
// The bar is embedded in a surfacePage canvas matching the #Preview padding so the
// PNG shows it in the context a real onboarding screen provides.
//
// Determinism (07-testing §6.4):
//   · No Date() — OnboardingProgressBar is a pure display component with no clock dependency.
//   · No withAnimation — all states are at rest.
//   · designSystemEnvironment() (inside assertDesignSnapshot) injects .disablesOneShotMotion = true
//     and registers embedded fonts — no per-file setup needed.
//   · SampleData is not required; OnboardingProgressBar takes value-type arguments only.
//
// Baselines land in __Snapshots__/OnboardingProgressBarSnapshotTests/ alongside this file
// and are committed as the visual contract. First run records and fails with "recorded";
// commit the PNGs; subsequent runs diff. Never leave record: .all in committed code.

import Testing
import SnapshotTesting
import SwiftUI
@testable import AppTemplate

@Suite("OnboardingProgressBar snapshots")
struct OnboardingProgressBarSnapshotTests {

    // MARK: - step-0

    /// stepIndex 0: the first step. The current segment (index 0) renders in textPrimary ink;
    /// the remaining five are the "todo" separatorOpaque color. Counter reads "01 / 06".
    @Test("step-0 — first step: one ink segment, five todo segments, counter 01 / 06")
    @MainActor func step0() {
        assertDesignSnapshot(
            canvas { OnboardingProgressBar(stepIndex: 0) },
            named: "step-0"
        )
    }

    // MARK: - step-2

    /// stepIndex 2: a mid-journey step. Segments 0 and 1 are textTertiary (done);
    /// segment 2 is textPrimary (cur); segments 3, 4, and 5 are separatorOpaque (todo).
    /// Counter reads "03 / 06".
    @Test("step-2 — mid step: two done segments, one ink segment, three todo segments, counter 03 / 06")
    @MainActor func step2() {
        assertDesignSnapshot(
            canvas { OnboardingProgressBar(stepIndex: 2) },
            named: "step-2"
        )
    }

    // MARK: - step-4

    /// stepIndex 4: a late step (not the final step — totalSteps is 6). Segments 0–3 are
    /// textTertiary (done); segment 4 is textPrimary (cur); segment 5 is separatorOpaque (todo).
    /// Counter reads "05 / 06".
    @Test("step-4 — late step: four done segments, one ink segment, one todo segment, counter 05 / 06")
    @MainActor func step4() {
        assertDesignSnapshot(
            canvas { OnboardingProgressBar(stepIndex: 4) },
            named: "step-4"
        )
    }

    // MARK: - step-5

    /// stepIndex 5 — the sixth and final step of the new 6-step default (totalSteps: 6).
    /// Segments 0–4 are textTertiary (done); segment 5 is textPrimary (cur). Counter reads
    /// "06 / 06". Locks the totalSteps default of 6 and the terminal-step color ramp together
    /// in a single frame — no unit test can confirm that co-occurrence.
    @Test("step-5 — final step of 6: five done segments, one ink segment, counter 06 / 06")
    @MainActor func step5() {
        assertDesignSnapshot(
            canvas { OnboardingProgressBar(stepIndex: 5) },
            named: "step-5"
        )
    }
}

// MARK: - Canvas helper

/// Wraps the progress bar in a surfacePage canvas with the same padding as the #Preview
/// in OnboardingProgressBar.swift. Not a full-bleed screen; the bar is a component (§6.2).
@MainActor
private func canvas<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(Spacing.screenInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorRole.surfacePage)
}
