import Foundation
import Observation
import SwiftUI

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

    // MARK: - Navigation (one path per tab)

    /// The active tab. Saved is the only tab built this milestone (the others are placeholders), so the
    /// app boots into it. The tab bar binds to this; `push`/`pop` (AppStore+Navigation) operate on the
    /// matching path below.
    var selectedTab: AppTab = .saved

    /// One `NavigationPath` per tab — each tab's `NavigationStack` drives presentation from its own
    /// path; pushes route through the *active* tab's path, never a view-local one (03-store.md §2).
    var savedPath  = NavigationPath()
    var walletPath = NavigationPath()
    var homePath   = NavigationPath()
    var youPath    = NavigationPath()

    // MARK: - Onboarding feature state

    /// `private(set)` so only the store replaces the graph (hydration / dismiss-to-root); views
    /// mutate *through* the draft's model methods, never by reassigning it.
    private(set) var onboarding: TripDraftModel?

    var onboardingLoadState: LoadState = .idle

    /// Kept so `completeGeneration()` / `cancelOnboarding()` can cancel an in-flight live sweep; tests
    /// drive the synchronous `advanceGeneration()` seam directly and never start this task.
    private var generationTask: Task<Void, Never>?

    // MARK: - Saved feature state

    /// `private(set)` so only the store replaces the graph (hydration / seed); views mutate *through*
    /// the `addPlace` command and the row model methods, never by reassigning the container.
    private(set) var savedPlaces: SavedPlacesModel?

    var savedLoadState: LoadState = .idle

    // MARK: - Wallet feature state

    /// `private(set)` so only the store replaces the graph (hydration / seed); views mutate *through*
    /// the `placeOrphan` command and the row model methods, never by reassigning the container.
    private(set) var wallet: TripWalletModel?

    var walletLoadState: LoadState = .idle

    /// Set by an optimistic write command on rollback, cleared on success/retry. Surfaced as a banner
    /// (06-screens.md §6), never a toast/alert.
    var writeError: WriteError?

    init(api: APIClient = .live) {
        self.api = api
    }

    // Same-file seams so the `AppStore+Onboarding.swift` extension can drive the `private(set)` graph
    // and the `private` task while keeping both invisible to views.

    func setOnboarding(_ draft: TripDraftModel?) {
        onboarding = draft
    }

    /// Same-file seam so the `AppStore+Saved.swift` extension can replace the `private(set)` saved
    /// graph at hydration / seed time while keeping the setter invisible to views.
    func setSavedPlaces(_ places: SavedPlacesModel?) {
        savedPlaces = places
    }

    /// Same-file seam so the `AppStore+Wallet.swift` extension can replace the `private(set)` wallet
    /// graph at hydration / seed time while keeping the setter invisible to views.
    func setWallet(_ wallet: TripWalletModel?) {
        self.wallet = wallet
    }

    func setGenerationTask(_ task: Task<Void, Never>?) {
        generationTask = task
    }

    func cancelGenerationTask() {
        generationTask?.cancel()
        generationTask = nil
    }

    // MARK: - Seed seams (synchronous, no network)

    /// Seed the saved graph directly from a DTO (a `SampleData` snapshot) so `#Preview`s, render
    /// snapshots, and tests render deterministically without `await loadSavedPlaces()` (03-store §4).
    /// Maps the DTO to the domain graph on the main actor and marks the load `.loaded`.
    func loadSeed(savedPlaces dto: SavedPlacesDTO) {
        setSavedPlaces(dto.toDomain())
        savedLoadState = .loaded
    }

    /// Seed the wallet graph directly from a DTO (a `SampleData` snapshot) so `#Preview`s, render
    /// snapshots, and tests render deterministically without `await loadWallet()` (03-store §4).
    /// Maps the DTO to the domain graph on the main actor and marks the load `.loaded`.
    func loadSeed(wallet dto: TripWalletDTO) {
        setWallet(dto.toDomain())
        walletLoadState = .loaded
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

    /// A fresh `.mock()`-backed store seeded with a saved-places snapshot so Saved-tab `#Preview`s and
    /// render snapshots never `await loadSavedPlaces()`. Choose the rendered state by choosing the
    /// `SampleData` factory that built the DTO (populated / empty).
    static func preview(savedPlaces dto: SavedPlacesDTO) -> AppStore {
        let store = AppStore(api: .mock())
        store.loadSeed(savedPlaces: dto)
        return store
    }

    /// A fresh `.mock()`-backed store seeded with a wallet snapshot so wallet-tab `#Preview`s and
    /// render snapshots never `await loadWallet()`. Choose the rendered state by choosing the
    /// `SampleData` factory that built the DTO (populated / empty).
    static func preview(wallet dto: TripWalletDTO) -> AppStore {
        let store = AppStore(api: .mock())
        store.loadSeed(wallet: dto)
        return store
    }
}
