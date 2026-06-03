/*
 Stateless derivation for the onboarding container: which step to render, the A/B/C branch, the
 progress index, the header's leading glyph. The branch derivation itself (`onboardingState`) lives
 on the store; this just surfaces it. Imports SwiftUI only to return a `LeadingGlyph` (no View built).
*/
import SwiftUI

struct OnboardingFlowPresenter {

    let store: AppStore

    // Defaults to `.destination` when there's no active draft, keeping the presenter total.
    var currentStep: OnboardingStep {
        store.onboarding?.currentStep ?? .destination
    }

    var onboardingState: OnboardingState? {
        store.onboardingState
    }

    var progressIndex: Int {
        currentStep.index
    }

    // Close (×) to dismiss on the first step, back chevron to retreat after.
    var leadingGlyph: LeadingGlyph {
        currentStep.index == 0 ? .close : .back
    }
}
