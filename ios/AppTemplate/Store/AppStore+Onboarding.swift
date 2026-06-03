// AppStore+Onboarding.swift — the onboarding feature's commands + store-level derivation (plan W3-02).
//
// Per `03-store.md §3/§7`: networked / flow-control orchestration lives on `AppStore` as thin
// command wrappers in a per-feature extension file (its methods inherit the type's `@MainActor`
// isolation for free); the pure in-place state transitions live on the `TripDraftModel` model
// (`02-models.md §2`) and are called through thin nav wrappers here. The *store-shared* derivations
// (`savedHere` / `savedAnywhere` / `onboardingState`) live here, on the store — NOT in the views —
// so they feed every presenter from one place (`06-screens.md §3`, the task's branch-driver rule).
import Foundation

extension AppStore {

    // MARK: - Read path (hydration)

    /// Hydrate the onboarding draft from the network (the read path, `03-store.md §4`).
    ///
    /// `api.send(...)` is the one suspension point; the `OnboardingContextDTO` is `Sendable` and is
    /// decoded off the main actor, then mapped to the seed `TripDraftModel` here on `@MainActor` via
    /// `toDomain()` (which also carries the catalog as `context` and sets the derived
    /// `onboardingState`). On any throw the load state captures the error message so a view can
    /// `switch` on it.
    func loadOnboarding() async {
        onboardingLoadState = .loading
        do {
            let dto = try await api.send(GetOnboardingContextRequest())
            setOnboarding(dto.toDomain())
            onboardingLoadState = .loaded
        } catch {
            onboardingLoadState = .failed(String(describing: error))
        }
    }

    // MARK: - Derivation (on the store, NOT the view)

    /// Saved places in the chosen destination — drives the A branch. Derived from the draft's
    /// immutable catalog; `0` when there is no active draft. No view reads this count directly.
    var savedHere: Int { onboarding?.savedHere ?? 0 }

    /// Saved places anywhere — distinguishes B (`> 0`) from C (`== 0`). Derived from the draft's
    /// immutable catalog; `0` when there is no active draft.
    var savedAnywhere: Int { onboarding?.savedAnywhere ?? 0 }

    /// The A/B/C branch the immersive flow takes — the branch driver. `nil` when there is no active
    /// draft. Read straight off the seed draft (set by `toDomain()` from the saved-place counts:
    /// `savedHere > 0` → A; `savedHere == 0 && savedAnywhere > 0` → B; else → C).
    var onboardingState: OnboardingState? { onboarding?.onboardingState }

    // MARK: - Step navigation

    /// Advance the immersive flow's step cursor by one (clamped). A thin wrapper over the
    /// `TripDraftModel.advanceStep()` model method — step nav is store-level flow control
    /// (`03-store.md §3`), the clamp lives on the model.
    func advanceOnboardingStep() {
        onboarding?.advanceStep()
    }

    /// Retreat the step cursor by one (clamped). Thin wrapper over `TripDraftModel.retreatStep()`.
    func retreatOnboardingStep() {
        onboarding?.retreatStep()
    }

    // MARK: - Generation (OPEN DECISION 3 — the test-drivable seam)

    /// Kick the cancellable generation clock: walk the plan by calling the synchronous
    /// `advanceGeneration()` seam on a `Task.sleep` cadence, then `completeGeneration()` to dismiss
    /// to root. The task is stored on the core so a later command can cancel it. **Tests never call
    /// this** — they drive `advanceGeneration()` / `completeGeneration()` synchronously (no
    /// wall-clock in tests, `07-testing.md §3`); only the live path schedules the sleeps.
    func startGeneration() {
        guard let plan = onboarding?.generationPlan else { return }
        // Cancel any prior sweep before starting a fresh one.
        cancelGenerationTask()

        // One sleep tick per remaining step so the whole sweep lands near `plan.etaSeconds`.
        let remainingSteps = max(plan.steps.count - plan.currentStepIndex - 1, 0)
        let perStep: Duration = remainingSteps > 0
            ? .seconds(Double(plan.etaSeconds) / Double(remainingSteps))
            : .seconds(Double(plan.etaSeconds))

        let task = Task { [weak self] in
            for _ in 0..<remainingSteps {
                try? await Task.sleep(for: perStep)
                if Task.isCancelled { return }
                self?.advanceGeneration()
            }
            try? await Task.sleep(for: perStep)
            if Task.isCancelled { return }
            self?.completeGeneration()
        }
        setGenerationTask(task)
    }

    /// The SYNCHRONOUS, test-callable seam: firm up the plan by one step — mark the current
    /// `GenerationStep` `.done` and the next one `.current`, and advance `currentStepIndex`. A no-op
    /// once the cursor is on the last step (there is nothing left to advance to). Mutates
    /// `onboarding?.generationPlan` in place.
    func advanceGeneration() {
        guard var plan = onboarding?.generationPlan else { return }
        let current = plan.currentStepIndex
        let next = current + 1
        guard plan.steps.indices.contains(current), plan.steps.indices.contains(next) else { return }

        plan.steps[current] = restated(plan.steps[current], as: .done)
        plan.steps[next] = restated(plan.steps[next], as: .current)
        plan.currentStepIndex = next
        onboarding?.generationPlan = plan
    }

    /// Completion command: cancel the live clock and dismiss to root (`onboarding = nil`).
    func completeGeneration() {
        cancelGenerationTask()
        // TODO: navigate to Trip Overview when that screen is built
        setOnboarding(nil)
    }

    /// Cancel / Close command (the header ×): cancel the live clock and dismiss to root.
    func cancelOnboarding() {
        cancelGenerationTask()
        setOnboarding(nil)
    }

    // MARK: - Helpers

    /// Rebuild a `GenerationStep` with a new `state` (its other fields are `let`, so this is the
    /// in-place "change one field" of a leaf value type).
    private func restated(_ step: GenerationStep, as state: StepState) -> GenerationStep {
        GenerationStep(id: step.id, label: step.label, detail: step.detail, state: state)
    }
}
