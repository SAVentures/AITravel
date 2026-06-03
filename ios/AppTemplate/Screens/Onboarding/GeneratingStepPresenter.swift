/*
 Stateless derivation for the generate step. Maps the `GenerationPlan` leaf value type
 (on `TripDraftModel.generationPlan`) to the design system's value-type view-models
 (`GenerationStepVM` + `HandoffVM`), so the view stays layout + wiring only. The store owns
 the clock that mutates the plan; this presenter projects the current plan on every `body` pass.

 Ports state-{a,b,c}-screen-05-generate.html. Every derived value stays total when there is no plan.
*/
import Foundation

struct GeneratingStepPresenter {

    let store: AppStore

    private var plan: GenerationPlan? { store.onboarding?.generationPlan }

    // MARK: - Gen-hero copy

    var eyebrow: String { "Drawing up your trip" }

    var headline: String { plan?.headline ?? "" }

    var sub: String { plan?.sub ?? "" }

    // MARK: - The checklist (model → component VM)

    var steps: [GenerationStepVM] {
        (plan?.steps ?? []).map { step in
            GenerationStepVM(
                id: step.id,
                text: step.label,
                detail: step.detail,
                status: status(for: step.state)
            )
        }
    }

    // Kept on the presenter so the component never imports the domain `StepState` enum.
    private func status(for state: StepState) -> GenerationStepVM.Status {
        switch state {
        case .done:    .done
        case .current: .current
        case .pending: .pending
        }
    }

    // MARK: - The faint handoff peek

    var handoff: HandoffVM? {
        guard let plan else { return nil }
        return HandoffVM(title: plan.handoffEyebrow, subtitle: plan.handoffLine)
    }

    // MARK: - The eta line

    var eta: String {
        let seconds = plan?.etaSeconds ?? 8
        return "Usually ready in about \(seconds) seconds"
    }
}
