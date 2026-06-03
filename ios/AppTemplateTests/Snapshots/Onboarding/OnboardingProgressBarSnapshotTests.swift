// OnboardingProgressBarSnapshotTests.swift — Layer 3 render-snapshot lock for OnboardingProgressBar.
//
// These tests are the lock on OnboardingProgressBar at authoring time. They do not
// verify the design (that is the fidelity-reviewer's job); they freeze the accepted
// render so any later change that silently moves a pixel — segment color ramp, counter
// typography, spacing — fails the build. (07-testing §6 governing doc.)
//
// States covered (one snapshot each, per 07-testing §6.2):
//   step-0  — stepIndex 0: one "cur" ink segment, four "todo" separator segments, counter "01 / 05"
//   step-2  — stepIndex 2: two "done" tertiary segments, one "cur" ink segment, two "todo"
//   step-4  — stepIndex 4 (last): four "done" tertiary segments, one "cur" ink segment, counter "05 / 05"
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
    /// the remaining four are the "todo" separatorOpaque color. Counter reads "01 / 05".
    @Test("step-0 — first step: one ink segment, four todo segments, counter 01 / 05")
    @MainActor func step0() {
        assertDesignSnapshot(
            canvas { OnboardingProgressBar(stepIndex: 0) },
            named: "step-0"
        )
    }

    // MARK: - step-2

    /// stepIndex 2: a mid-journey step. Segments 0 and 1 are textTertiary (done);
    /// segment 2 is textPrimary (cur); segments 3 and 4 are separatorOpaque (todo).
    /// Counter reads "03 / 05".
    @Test("step-2 — mid step: two done segments, one ink segment, two todo segments, counter 03 / 05")
    @MainActor func step2() {
        assertDesignSnapshot(
            canvas { OnboardingProgressBar(stepIndex: 2) },
            named: "step-2"
        )
    }

    // MARK: - step-4

    /// stepIndex 4: the final step. Segments 0–3 are textTertiary (done); segment 4 is
    /// textPrimary (cur). Counter reads "05 / 05".
    @Test("step-4 — last step: four done segments, one ink segment, counter 05 / 05")
    @MainActor func step4() {
        assertDesignSnapshot(
            canvas { OnboardingProgressBar(stepIndex: 4) },
            named: "step-4"
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
