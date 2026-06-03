// OnboardingFlowView.swift — the ONE adaptive onboarding container (plan W4-00).
//
// One flow, five steps, three data-driven branches (A/B/C). This view is layout + wiring ONLY
// (`06-screens.md §1`): it reads `store.onboarding`, builds the stateless `OnboardingFlowPresenter`,
// and switches on `presenter.currentStep` to host the matching per-step view. It owns NO domain state
// — the draft lives on `AppStore`; it holds no `@State` at all. The branch (A/B/C) is selected by the
// store-derived `presenter.onboardingState`, which the per-step views read themselves.
//
// The per-step views (`DestinationStepView` … `GeneratingStepView`) are built by parallel agents and
// referenced by name with no args — each reads the store + builds its own presenter, composes
// `ScreenScaffold(.immersive)` + the in-content `OnboardingProgressBar` + a floating leading
// `GlassCircleButton` (close/back) + the `OnboardingActionFloor`, and wires its own step nav
// (`06-screens.md §2` immersive chrome). This container only routes between them and animates the step
// transition with the house curve (`Motion.standard`, restrained motion).
import SwiftUI

/// The immersive onboarding container. Renders nothing until a draft is hydrated; once present, it
/// routes `currentStep` → the matching step view, animating the transition.
struct OnboardingFlowView: View {

    /// The single source of truth, injected at the App root (`06-screens.md §4`).
    @Environment(AppStore.self) private var store

    var body: some View {
        Group {
            if store.onboarding == nil {
                // No active draft (pre-hydration, or dismissed-to-root): render nothing. `RootView`
                // drives presentation off `store.onboarding != nil`, so the cover is already gone here.
                EmptyView()
            } else {
                let presenter = OnboardingFlowPresenter(store: store)
                step(for: presenter.currentStep)
                    // Restrained motion: cross-fade/slide the step swap on the house curve (J-9). The
                    // step identity keys the transition so SwiftUI animates between the two step views.
                    .id(presenter.currentStep)
                    .transition(.opacity)
                    .animation(Motion.standard(), value: presenter.currentStep)
            }
        }
    }

    /// Route the cursor → the per-step view. Each step view reads the store + its own presenter and
    /// owns its chrome, so it takes no args here (`06-screens.md §1`).
    @ViewBuilder
    private func step(for step: OnboardingStep) -> some View {
        switch step {
        case .destination:   DestinationStepView()
        case .tripShape:     TripShapeStepView()
        case .baseLocation:  BaseLocationStepView()
        case .gettingAround: GettingAroundStepView()
        case .generating:    GeneratingStepView()
        }
    }
}

// MARK: - Previews

#Preview("Onboarding · A (returning) — destination") {
    OnboardingFlowView()
        .environment(AppStore.preview(SampleData.onboardingAContext(), step: .destination))
}

#Preview("Onboarding · B (saves elsewhere) — trip shape") {
    OnboardingFlowView()
        .environment(AppStore.preview(SampleData.onboardingBContext(), step: .tripShape))
}

#Preview("Onboarding · C (first trip) — generating") {
    OnboardingFlowView()
        .environment(AppStore.preview(SampleData.onboardingCContext(), step: .generating))
}
