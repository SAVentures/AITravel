/*
 In-content onboarding step progress: 5 neutral segments + a mono `NN / 05` counter. Ports the mockup
 `.ob-progress` / `.ob-seg` / `.ob-counter` (mockups/screens/onboarding/screen-shell.css).

 NO glass, NO × button — this is resting content, not chrome; the dismiss × is a separate floating
 `GlassCircleButton` the screen overlays. The segment ramp is strictly ink (never accent): the blue
 budget is reserved for the CTA + the one AI/now mark.
*/
import SwiftUI

struct OnboardingProgressBar: View {

    let stepIndex: Int  // 0-based; segments at or before this index read as done/cur

    var totalSteps: Int = 5

    @ScaledMetric(relativeTo: .caption) private var segmentHeight: CGFloat = 4

    private var displayStep: Int { min(stepIndex, totalSteps - 1) + 1 }

    var body: some View {
        HStack(spacing: Spacing.paired) {
            progressSegments
            counter
        }
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("onboarding.progress")
        .accessibilityValue("Step \(stepIndex + 1) of \(totalSteps)")
    }

    // MARK: - Progress

    private var progressSegments: some View {
        HStack(spacing: Spacing.paired) {
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
        .accessibilityHidden(true)
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
