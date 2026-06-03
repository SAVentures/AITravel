import Foundation
import Observation

/*
 The single source of truth the whole UI reads. No `.shared` singleton — `init` is non-private so
 every context (app root, preview, test, UI-test) owns its own instance; only the App root injects it.

 Stays CORE/minimal: injected `api`, the init, shared seams. Feature state is the one serialized edit
 here; commands + derivation land in `AppStore+<Feature>.swift` extensions.
*/
@MainActor
@Observable
final class AppStore {
    let api: APIClient

    // MARK: - Onboarding feature state

    /// `private(set)` so only the store replaces the graph (hydration / dismiss-to-root); views
    /// mutate *through* the draft's model methods, never by reassigning it.
    private(set) var onboarding: TripDraftModel?

    var onboardingLoadState: LoadState = .idle

    /// Kept so `completeGeneration()` / `cancelOnboarding()` can cancel an in-flight live sweep; tests
    /// drive the synchronous `advanceGeneration()` seam directly and never start this task.
    private var generationTask: Task<Void, Never>?

    init(api: APIClient = .live) {
        self.api = api
    }

    // Same-file seams so the `AppStore+Onboarding.swift` extension can drive the `private(set)` graph
    // and the `private` task while keeping both invisible to views.

    func setOnboarding(_ draft: TripDraftModel?) {
        onboarding = draft
    }

    func setGenerationTask(_ task: Task<Void, Never>?) {
        generationTask = task
    }

    func cancelGenerationTask() {
        generationTask?.cancel()
        generationTask = nil
    }

    // MARK: - Preview / snapshot seam

    /// A locally-constructed `.mock()`-backed store seeded directly so `#Preview`s and render
    /// snapshots never `await loadOnboarding()`. Choose the rendered branch (A/B/C) via `context`,
    /// the rendered step via `step`.
    static func preview(
        _ context: OnboardingContextDTO,
        step: OnboardingStep = .destination
    ) -> AppStore {
        let store = AppStore(api: .mock())
        let draft = context.toDomain()
        draft.currentStep = step
        store.setOnboarding(draft)
        store.onboardingLoadState = .loaded
        return store
    }
}
