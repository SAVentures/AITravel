/*
 The one adaptive onboarding container — five steps, three data-driven branches (A/B/C). Layout +
 wiring only: routes presenter.currentStep to the matching per-step view, owns no domain state and no
 @State (the draft lives on AppStore).

 Each per-step view takes no args — it reads the store, builds its own presenter, and owns its own
 immersive chrome + step nav. This container only routes between them and animates the swap.
*/
import SwiftUI

struct OnboardingFlowView: View {

    @Environment(AppStore.self) private var store

    var body: some View {
        Group {
            if store.onboarding == nil {
                // No active draft: RootView drives presentation off store.onboarding != nil.
                EmptyView()
            } else {
                let presenter = OnboardingFlowPresenter(store: store)
                step(for: presenter.currentStep)
                    // Step identity keys the transition so SwiftUI animates between step views.
                    .id(presenter.currentStep)
                    .transition(.opacity)
                    .animation(Motion.standard(), value: presenter.currentStep)
            }
        }
    }

    @ViewBuilder
    private func step(for step: OnboardingStep) -> some View {
        switch step {
        case .destination:   DestinationStepView()
        case .tripShape:     TripShapeStepView()
        case .when:          WhenStepView()
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
