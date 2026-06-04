/*
 In-content onboarding step progress: 6 neutral segments + a mono `NN / 06` counter. Ports the mockup
 `.ob-progress`/`.ob-seg`/`.ob-counter` (mockups/screens/onboarding/screen-shell.css).

 Resting content, NOT chrome — no glass, no × (the dismiss × is a separate floating GlassCircleButton).
 The segment ramp is strictly ink: the accent budget is reserved for the CTA + the one AI/now mark (J-2.4).
*/
import SwiftUI

struct OnboardingProgressBar: View {

    let stepIndex: Int  // 0-based; segments at or before this index read as done/cur

    var totalSteps: Int = 6

    @ScaledMetric(relativeTo: .caption) private var segmentHeight: CGFloat = Sizing.Component.progressSegment

    private var displayStep: Int { min(stepIndex, totalSteps - 1) + 1 }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            progressSegments
            counter
        }
        // The whole bar is ONE VoiceOver element: `children: .ignore` collapses the segments and
        // the rendered `NN / 06` counter into this node, so the step is announced exactly once.
        // Carrying a non-empty LABEL (not only a value) here gives the bar's footprint — which is
        // what `.elementDetection` inspects — a backing accessible element, so the rendered counter
        // text is no longer an orphan empty-id/empty-label node (OD-3 / plan Task 2.7). Hence the
        // counter drops its `.accessibilityHidden(true)` — it has nothing to hide from anymore.
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("onboarding.progress")
        .accessibilityLabel("Step \(displayStep) of \(totalSteps)")
    }

    // MARK: - Progress

    private var progressSegments: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(segmentColor(at: index))
                    .frame(height: segmentHeight)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func segmentColor(at index: Int) -> Color {
        if index == stepIndex {
            ColorRole.textPrimary          // cur
        } else if index < stepIndex {
            ColorRole.textTertiary         // done
        } else {
            ColorRole.separatorOpaque      // todo
        }
    }

    // MARK: - Counter

    private var counter: some View {
        (
            Text(stepLabel(displayStep))
                .foregroundStyle(ColorRole.textPrimary)
            + Text(" / ")
                .foregroundStyle(ColorRole.textTertiary)
            + Text(stepLabel(totalSteps))
                .foregroundStyle(ColorRole.textTertiary)
        )
        .font(Typography.caption)
        .tracking(Typography.trackEyebrowCaption)
        .monospacedDigit()
        // No `.accessibilityHidden(true)`: the parent `children: .ignore` already folds this text
        // into the single labeled bar element, so this is not an orphan node — and hiding it is what
        // produced the empty-id/empty-label `.elementDetection` flag this component now resolves.
    }

    private func stepLabel(_ n: Int) -> String {
        String(format: "%02d", n)
    }
}

// MARK: - Previews

#Preview("Step 1 of 5") {
    OnboardingProgressBar(stepIndex: 0)
        .padding(Spacing.screenInset)
        .background(ColorRole.surfacePage)
}

#Preview("Step 3 of 5") {
    OnboardingProgressBar(stepIndex: 2)
        .padding(Spacing.screenInset)
        .background(ColorRole.surfacePage)
}

#Preview("Step 5 of 5") {
    OnboardingProgressBar(stepIndex: 4)
        .padding(Spacing.screenInset)
        .background(ColorRole.surfacePage)
}
