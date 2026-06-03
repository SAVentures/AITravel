/*
 Onboarding step 05 — the generate moment. Ports state-{a,b,c}-screen-05-generate.html.

 A PASSIVE screen: no OnboardingActionFloor, the only affordance is the floating Cancel ×. On appear it
 kicks the store's generation clock; the STORE owns the clock (OPEN DECISION 3) — it walks GenerationPlan
 and, on completion, sets onboarding = nil to dismiss the immersive cover to root.

 The sweep is the one continuous motion (J-9.3), owned by GenerationProgressView; it parks static under
 Reduce Motion and the \.disablesOneShotMotion snapshot seam (07-testing §6.4).
*/
import SwiftUI

struct GeneratingStepView: View {

    @Environment(AppStore.self) private var store

    // Clearance band below the floating Cancel × so content doesn't collide at rest; scaled (J-0.3).
    @ScaledMetric(relativeTo: .body) private var topChrome: CGFloat = Spacing.chromeClearance

    var body: some View {
        let presenter = GeneratingStepPresenter(store: store)

        ScreenScaffold(.immersive, background: ColorRole.surfaceGrouped) {
            VStack(alignment: .leading, spacing: Spacing.hero) {
                OnboardingProgressBar(stepIndex: OnboardingStep.generating.index)

                VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                    AIVoice(eyebrow: presenter.eyebrow, line: presenter.headline)
                    Text(presenter.sub)
                        .font(Typography.body)
                        .foregroundStyle(ColorRole.textSecondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // The design-system component owns the one continuous motion (the heartbeat sweep).
                GenerationProgressView(steps: presenter.steps, handoff: presenter.handoff)

                Text(presenter.eta)
                    .font(Typography.caption)
                    .tracking(Typography.trackEyebrowCaption)
                    .foregroundStyle(ColorRole.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityIdentifier("generation.eta")
            }
            .padding(.top, topChrome)
        }
        // Floating Cancel × (glass chrome, not in scroll content) — the only affordance; aborts to root.
        .overlay(alignment: .topLeading) {
            GlassCircleButton(
                systemImage: "xmark",
                accessibilityLabel: "Close",
                action: { store.cancelOnboarding() }
            )
            .padding(.leading, Spacing.screenInset)
            .padding(.top, Spacing.paired)
            .accessibilityIdentifier("onboarding.cancel")
        }
        // The store owns the clock (OPEN DECISION 3); the view only observes the walk it kicks here.
        // TODO: navigate to Trip Overview when built — the real push lives store-side in
        // `AppStore.completeGeneration()` (W3-02), where `onboarding = nil` currently dismisses to root.
        .task { store.startGeneration() }
    }
}

// MARK: - Previews

#Preview("Generating · A (returning, 23 saves)") {
    GeneratingStepView()
        .environment(AppStore.preview(SampleData.onboardingAContext(), step: .generating))
        .environment(\.disablesOneShotMotion, true)
}

#Preview("Generating · B (saves elsewhere, Kyoto)") {
    GeneratingStepView()
        .environment(AppStore.preview(SampleData.onboardingBContext(), step: .generating))
        .environment(\.disablesOneShotMotion, true)
}

#Preview("Generating · C (first trip, Lisbon)") {
    GeneratingStepView()
        .environment(AppStore.preview(SampleData.onboardingCContext(), step: .generating))
        .environment(\.disablesOneShotMotion, true)
}
