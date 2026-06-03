/*
 The onboarding feature's store commands + store-level derivation. Flow-control orchestration lives
 here as thin wrappers over `TripDraftModel`'s in-place transitions. The store-shared derivations
 (savedHere / savedAnywhere / onboardingState) live here, not in views, so every presenter reads
 the branch driver from one place.
*/
import Foundation

extension AppStore {

    // MARK: - Read path (hydration)

    func loadOnboarding() async {
        onboardingLoadState = .loading
        do {
            let dto = try await api.send(GetOnboardingContextRequest())
            let draft = dto.toDomain()
            // Test seam: UITEST_START_STEP lets a UI test launch directly into any step (no effect unset).
            if let step = Self.uiTestStartStep { draft.currentStep = step }
            setOnboarding(draft)
            onboardingLoadState = .loaded
        } catch {
            onboardingLoadState = .failed(String(describing: error))
        }
    }

    private static var uiTestStartStep: OnboardingStep? {
        switch ProcessInfo.processInfo.environment["UITEST_START_STEP"] {
        case "tripShape":     .tripShape
        case "when":          .when
        case "baseLocation":  .baseLocation
        case "gettingAround": .gettingAround
        case "generating":    .generating
        case "destination":   .destination
        default:              nil
        }
    }

    // MARK: - Derivation (on the store, NOT the view)

    var savedHere: Int { onboarding?.savedHere ?? 0 }

    var savedAnywhere: Int { onboarding?.savedAnywhere ?? 0 }

    // The A/B/C branch driver: savedHere > 0 → A; savedHere == 0 && savedAnywhere > 0 → B; else → C.
    var onboardingState: OnboardingState? { onboarding?.onboardingState }

    // MARK: - Step navigation

    func advanceOnboardingStep() {
        onboarding?.advanceStep()
    }

    func retreatOnboardingStep() {
        onboarding?.retreatStep()
    }

    // MARK: - Generation

    /* Kick the cancellable generation clock: walk the plan by calling the synchronous
       advanceGeneration() seam on a Task.sleep cadence, then completeGeneration() to dismiss to
       root. Tests never call this — they drive advanceGeneration() / completeGeneration()
       synchronously; only the live path schedules the sleeps. */
    func startGeneration() {
        guard let plan = onboarding?.generationPlan else { return }
        cancelGenerationTask()

        // One sleep tick per remaining step so the whole sweep lands near plan.etaSeconds.
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

    // The synchronous, test-callable seam: mark the current step .done and the next .current, and
    // advance currentStepIndex. No-op once the cursor is on the last step.
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

    func completeGeneration() {
        cancelGenerationTask()
        // TODO: navigate to Trip Overview when that screen is built
        setOnboarding(nil)
    }

    func cancelOnboarding() {
        cancelGenerationTask()
        setOnboarding(nil)
    }

    // MARK: - Helpers

    // Rebuild a GenerationStep with a new state — its other fields are `let`.
    private func restated(_ step: GenerationStep, as state: StepState) -> GenerationStep {
        GenerationStep(id: step.id, label: step.label, detail: step.detail, state: state)
    }
}
