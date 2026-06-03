// GeneratingStepView.swift — Step 05 of the immersive onboarding flow: the generate moment (plan W4-05).
//
// PORTS FROM: `mockups/screens/onboarding/state-a-screen-05-generate.html`
//   (+ `state-b-screen-05-generate.html`, `state-c-screen-05-generate.html`) — the fidelity targets.
//
// This is a PASSIVE screen (06-screens §2.5): there is NO `OnboardingActionFloor`. The only affordance is
// Cancel — the × in the sticky `OnboardingProgressHeader` (mockup `.ob-topbar` close glyph). The screen
// observes; it does not advance anything itself. On appear it kicks the store's generation clock; the
// STORE owns the clock (OPEN DECISION 3) — it walks the `GenerationPlan` and, on completion, sets
// `onboarding = nil`, which dismisses the immersive cover to root (`RootView` reacts to that).
//
// Layout + wiring ONLY (06-screens §1): reads `AppStore` via `@Environment`, builds the stateless
// `GeneratingStepPresenter`, composes `ScreenScaffold(.immersive)` + the sticky header + the design-system
// `GenerationProgressView` (which owns the ONE continuous motion — the heartbeat sweep — and the firming-up
// checklist + the faint handoff peek). The gen-hero (`AIVoice` + a sub paragraph) and the mono `eta` line
// are placed around it. NO domain state in `@State`; the model→VM mapping lives on the presenter.
//
// Motion: the sweep is the one continuous motion (J-9.3 / J-6.5), owned by `GenerationProgressView`; it
// goes static under both Reduce Motion and the `\.disablesOneShotMotion` snapshot seam (07-testing §6.4).
// One accent on this screen: the current step's `stateNow` ring inside the checklist (J-2.4) — the header
// is strictly neutral and there is no CTA.
import SwiftUI

/// Step 05 — the generate moment. Passive: it starts the store's generation clock on appear and renders
/// the firming-up checklist; the store dismisses to root on completion. Cancel is the header ×.
struct GeneratingStepView: View {

    /// The single source of truth, injected at the App root (`06-screens.md §4`).
    @Environment(AppStore.self) private var store

    var body: some View {
        let presenter = GeneratingStepPresenter(store: store)

        ScreenScaffold(.immersive) {
            VStack(alignment: .leading, spacing: Spacing.hero) {
                // Sticky frosted header — step 5 of 5; the leading glyph is the Cancel × (the only
                // affordance on this passive screen). Tapping it aborts the clock + dismisses to root.
                OnboardingProgressHeader(
                    stepIndex: OnboardingStep.generating.index,   // 4
                    leadingGlyph: .close,
                    leadingAction: { store.cancelOnboarding() }
                )
                .accessibilityIdentifier("onboarding.cancel")

                // Gen-hero (mockup `.gen-hero`): the AI voice line + a sub paragraph. The eyebrow is the
                // constant "Drawing up your trip"; the italic line + sub come from the plan.
                VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                    AIVoice(eyebrow: presenter.eyebrow, line: presenter.headline)
                    Text(presenter.sub)
                        .font(Typography.body)
                        .foregroundStyle(ColorRole.textSecondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // The sweep + firming-up checklist + faint handoff peek — the design-system component owns
                // the ONE continuous motion and emits `generation.progress` / `generation.step.<i>` /
                // `generation.handoff`. The model→VM mapping is the presenter's.
                GenerationProgressView(steps: presenter.steps, handoff: presenter.handoff)

                // The mono caps eta line (mockup `.eta`, "Usually ready in about 8 seconds").
                Text(presenter.eta)
                    .font(Typography.caption)
                    .tracking(Typography.trackEyebrowCaption)
                    .foregroundStyle(ColorRole.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityIdentifier("generation.eta")
            }
        }
        // The store owns the clock (OPEN DECISION 3): kick the cancellable generation walk on appear. The
        // view only observes — when the plan completes, the store sets `onboarding = nil` and the parent
        // cover dismisses to root.
        // TODO: navigate to Trip Overview when built — the real push lives store-side in
        // `AppStore.completeGeneration()` (W3-02), where `onboarding = nil` currently dismisses to root.
        .task { store.startGeneration() }
    }
}

// MARK: - Previews
//
// One per A/B/C seed, at the `.generating` step, via `AppStore.preview(_:step:)`. Each injects
// `\.disablesOneShotMotion = true` so the heartbeat sweep parks at rest — the preview/snapshot settle at
// a stable frame (07-testing.md §6.4), exactly how the L3 lock captures this screen.

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
