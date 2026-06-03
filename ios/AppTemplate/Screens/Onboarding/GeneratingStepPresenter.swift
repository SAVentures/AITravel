// GeneratingStepPresenter.swift — the stateless derivation for the generate step (plan W4-05).
//
// Per `06-screens.md §3`: a stateless `<Screen>Presenter` value type over the store, constructed in
// `body`, returning data / view-models (never `View`s). It owns the generate step's screen-specific
// mapping — the `GenerationPlan` model (a leaf value type on `TripDraft.generationPlan`) is mapped here
// to the design-system component's value-type view-models (`GenerationStepVM` + `HandoffVM`), so the
// view stays layout + wiring only. The store owns the clock that mutates the plan; this presenter just
// projects the current plan into the component's vocabulary on every `body` pass (kept cheap).
//
// PORTS FROM: `mockups/screens/onboarding/state-a-screen-05-generate.html` (+ b / c). The gen-hero
// reads its eyebrow ("Drawing up your trip") + an italic voice line (`plan.headline`, e.g. "A draft,
// not a finish line.") + a `sub` paragraph (`plan.sub`); the checklist + handoff + eta come straight
// off the plan.
import Foundation

/// Stateless derivation for `GeneratingStepView`. Constructed in `body` from the store so the store's
/// per-field dependency tracking is preserved (`06-screens.md §3`). All screen-specific model→VM
/// mapping lives here; the view never touches a `GenerationStep` / `GenerationPlan` directly.
struct GeneratingStepPresenter {

    /// The single source of truth the step reads. Held, never mutated here.
    let store: AppStore

    /// The active generation plan, or `nil` when there is no draft / no plan yet (the view renders a
    /// quiet placeholder in that case, but every derived value below stays total).
    private var plan: GenerationPlan? { store.onboarding?.generationPlan }

    // MARK: - Gen-hero copy

    /// The mono caps eyebrow for the AI voice line — constant across states (mockup `.ai .lab`,
    /// "Drawing up your trip").
    var eyebrow: String { "Drawing up your trip" }

    /// The italic editorial voice line (mockup `.ai .line`): "A draft, not a finish line." (A/B) /
    /// "A first draft to react to." (C). Carried by the plan's `headline`.
    var headline: String { plan?.headline ?? "" }

    /// The sub paragraph below the voice line (mockup `.gen-hero .sub`): the "reading your … places, your
    /// … base, your … preference" line. Carried by the plan's `sub`.
    var sub: String { plan?.sub ?? "" }

    // MARK: - The checklist (model → component VM)

    /// The planning checklist mapped from `[GenerationStep]` to the component's value-type
    /// `[GenerationStepVM]` — the one place `GenerationStep`/`StepState` is translated to the design
    /// system's vocabulary. Order is preserved; each row's `status` drives its register in the component.
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

    /// Map the model's `StepState` to the component's `GenerationStepVM.Status` — a total 1:1 mapping
    /// kept on the presenter so the component never imports the domain enum (05-design-system §8).
    private func status(for state: StepState) -> GenerationStepVM.Status {
        switch state {
        case .done:    .done
        case .current: .current
        case .pending: .pending
        }
    }

    // MARK: - The faint handoff peek

    /// The faint "up next" peek (mockup `.handoff`): a mono caps eyebrow + an italic display line,
    /// mapped from the plan's handoff copy. `nil` when there is no plan (the peek is omitted).
    var handoff: HandoffVM? {
        guard let plan else { return nil }
        return HandoffVM(title: plan.handoffEyebrow, subtitle: plan.handoffLine)
    }

    // MARK: - The eta line

    /// The mono caps eta line (mockup `.eta`, "Usually ready in about 8 seconds"), composed from the
    /// plan's `etaSeconds` so the copy and the store's clock read from one number.
    var eta: String {
        let seconds = plan?.etaSeconds ?? 8
        return "Usually ready in about \(seconds) seconds"
    }
}
