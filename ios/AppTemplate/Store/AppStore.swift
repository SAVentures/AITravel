import Foundation
import Observation

/// `AppStore` — the single source of truth the whole UI reads (`01-architecture.md §5`,
/// `03-store.md §1`).
///
/// `@MainActor` puts every mutation and observable read on the main thread (no manual
/// `DispatchQueue.main`); `@Observable` makes each stored property individually observable, so
/// SwiftUI re-renders only the views that read a changed property; `final` prevents subclassing.
///
/// **Ownership.** The App root owns the one instance — `AppTemplateApp` holds
/// `@State private var store = AppStore()` and injects it via `.environment(store)`. Previews and
/// tests construct their *own* local instance and seed it. There is **no `.shared` singleton and no
/// parallel stores**; `init` is non-private precisely so every context (app, preview, test, UI-test)
/// owns its instance (`03-store.md §1`).
///
/// **Extending this core.** This file stays CORE/minimal: the injected `api`, the init, and shared
/// conveniences. Feature state and the async command wrappers are added by feature agents — a new
/// stored property is the one serialized edit to this file (`01-architecture.md §11`), while commands
/// land in their own `AppStore+<Feature>.swift` extension (whose methods inherit this type's
/// `@MainActor` isolation for free, `03-store.md §7`).
@MainActor
@Observable
final class AppStore {
    /// The injected client every read/write goes through. Screens depend on `APIClient`, never a
    /// concrete provider; the mock/live swap happens here at the store boundary
    /// (`01-architecture.md §7`, `04-networking.md`).
    let api: APIClient

    // MARK: Onboarding feature state (commands + derivation live in `AppStore+Onboarding.swift`)

    /// The active onboarding draft, or `nil` when onboarding is dismissed / at root.
    ///
    /// `private(set)` so only `AppStore` replaces the graph (at hydration, and on the
    /// dismiss-to-root commands); views mutate *through* the draft's model methods or the store's
    /// commands, never by reassigning it (`03-store.md §2`). It is the one `@Observable` reference
    /// graph the immersive flow accumulates across its five steps.
    private(set) var onboarding: TripDraftModel?

    /// The transient load state for `loadOnboarding()` (the read path, `03-store.md §2/§4`).
    var onboardingLoadState: LoadState = .idle

    /// The cancellable clock that walks the generation plan on the live path. Kept so
    /// `completeGeneration()` / `cancelOnboarding()` can cancel an in-flight sweep; tests drive the
    /// synchronous `advanceGeneration()` seam directly instead and never start this task
    /// (`03-store.md §3`, plan W3-02 / OPEN DECISION 3).
    private var generationTask: Task<Void, Never>?

    /// The App root owns one instance (defaulting to `.live`); previews and tests pass their own
    /// `.mock(...)` client. No singleton — see the type doc.
    init(api: APIClient = .live) {
        self.api = api
    }

    // MARK: Onboarding mutation seams (same-file, so the `AppStore+Onboarding.swift` extension can
    // drive the `private(set)` graph and the `private` task — keeping both read-only / invisible to
    // views while the commands live in their own feature file, `03-store.md §7`).

    /// Replace the active draft (hydration) or clear it to `nil` (the dismiss-to-root command).
    func setOnboarding(_ draft: TripDraftModel?) {
        onboarding = draft
    }

    /// Store the cancellable generation clock so a later command can cancel it.
    func setGenerationTask(_ task: Task<Void, Never>?) {
        generationTask = task
    }

    /// Cancel any in-flight generation clock and forget it.
    func cancelGenerationTask() {
        generationTask?.cancel()
        generationTask = nil
    }

    // MARK: - Preview / snapshot seam (synchronous — no `await`)

    /// A fresh, locally-constructed store seeded directly with an onboarding draft — for `#Preview`s
    /// and render snapshots, which must NOT `await loadOnboarding()` (`06-screens.md §8`,
    /// `03-store.md §4`). It builds a `.mock()`-backed store, maps the context to its seed `TripDraftModel`
    /// via `toDomain()` through the same-file `setOnboarding(_:)` seam (so it can drive the
    /// `private(set)` graph), parks the draft on `step`, and marks the load `.loaded`.
    ///
    /// Mock data comes only from `SampleData` factories (e.g. `SampleData.onboardingAContext()`); pick
    /// the rendered branch (A/B/C) by choosing the context, the rendered step by `step`. No `.shared`.
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
