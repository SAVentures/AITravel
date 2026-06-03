// OnboardingFlowPresenter.swift — the stateless derivation for the onboarding container (plan W4-00).
//
// Per `06-screens.md §3`: a stateless `<Screen>Presenter` value type over the store, constructed in
// `body`, returning data / view-models (never `View`s). It owns the container's screen-specific
// derivation — which step to render, which A/B/C branch, the progress index, and which leading glyph
// the header shows. The *store-shared* branch derivation (`onboardingState`) lives on the store
// (`AppStore+Onboarding`); the presenter just surfaces it for the container's switch.
//
// Imports SwiftUI only because it returns a `LeadingGlyph` (a view-side value); no `View` is built
// here. Kept cheap — it is rebuilt every `body` pass.
import SwiftUI

/// Stateless derivation for `OnboardingFlowView`. Constructed in `body` from the store so the store's
/// per-field dependency tracking is preserved (`06-screens.md §3`).
struct OnboardingFlowPresenter {

    /// The single source of truth the container reads. Held, never mutated here.
    let store: AppStore

    /// The step the flow currently renders. Defaults to `.destination` when there is no active draft
    /// (the container renders nothing in that case, but the presenter stays total).
    var currentStep: OnboardingStep {
        store.onboarding?.currentStep ?? .destination
    }

    /// The derived A/B/C branch (off the store, not the view). `nil` when there is no active draft.
    var onboardingState: OnboardingState? {
        store.onboardingState
    }

    /// The 0-based progress index the sticky header reads (`currentStep.index`).
    var progressIndex: Int {
        currentStep.index
    }

    /// The leading glyph the header shows: a close (×) to dismiss the flow on the first step, a back
    /// chevron to retreat on every step after (`06-screens.md §2.3` — back/close only).
    var leadingGlyph: LeadingGlyph {
        currentStep.index == 0 ? .close : .back
    }
}
