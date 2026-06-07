import SwiftUI

/*
 `@main` entry: register embedded fonts, then construct + inject the one app-root `AppStore`.
 The store is seeded from the launch-env scenario so UI tests can pin which scenario branch the
 MockProvider serves:

   UITEST_SCENARIO     → MockScenario (onboardingA/B/C; savedStandard/savedEmpty/savedError)
   UITEST_FAILURE_RATE → when "1.0", injects APIError.status(503) on WRITE requests only
                         (for saved scenarios the store is pre-seeded from the DTO so the GET
                          never fires; only AddPlaceRequest reaches the failing provider)
   UITEST_NOW          → ISO-8601 string; consumed by presenters to pin time-conditional state

 Saved-scenario launches: the savedStandard/savedEmpty/savedError seeds carry no onboarding
 context, so store.onboarding is nil and the full-screen onboarding cover never appears — the
 app boots directly into the Saved tab (selectedTab defaults to .saved).

 Pre-seeding for saved scenarios: for savedStandard/savedEmpty/savedError, the store is seeded
 from the DTO at launch time (store.loadSeed(savedPlaces:)) so SavedListView's `.task` guard
 (`if store.savedPlaces == nil`) is false and loadSavedPlaces() never fires. This means
 UITEST_FAILURE_RATE=1.0 only affects subsequent WRITE requests (AddPlaceRequest), enabling the
 write-error/rollback path to be tested without the GET also failing.
*/
@main
struct AppTemplateApp: App {
    @State private var store: AppStore = AppTemplateApp.makeStore()

    init() { FontRegistry.registerEmbeddedFonts() }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                // UI tests force the deterministic static map (no live MapKit tiles / attribution / labels).
                .environment(\.mapSnapshotMode, ProcessInfo.processInfo.environment["UITEST_STATIC_MAP"] == "1")
                .preferredColorScheme(.light)   // light-mode only
        }
    }

    // MARK: - Launch seam

    /// Builds and pre-seeds the `AppStore` for the current launch.
    ///
    /// For a live run (no `UITEST_SCENARIO`), returns a standard `.live`-backed store.
    ///
    /// For a saved scenario (`savedStandard`/`savedEmpty`/`savedError`):
    ///   - Builds the store with `APIClient.mock(scenario:failure:)`.
    ///   - Pre-seeds `store.savedPlaces` via `loadSeed(savedPlaces:)` so the view's `.task`
    ///     guard (`if store.savedPlaces == nil`) is false at render time — the GET never fires.
    ///   - This isolates `UITEST_FAILURE_RATE=1.0` to WRITE requests (AddPlaceRequest), so the
    ///     write-error/rollback flow is exercisable without the read path also failing.
    ///
    /// For an onboarding scenario, behavior is unchanged from the prior pattern (no pre-seed).
    ///
    /// Not marked `@MainActor` explicitly — `AppTemplateApp` is `@MainActor` by default under
    /// Swift 6.2's MainActor-by-default rule, so the `@State` initializer expression already
    /// runs on the main actor and calling this static method is actor-safe.
    private static func makeStore() -> AppStore {
        let env = ProcessInfo.processInfo.environment
        guard let scenarioRaw = env["UITEST_SCENARIO"] else {
            return AppStore(api: .live)
        }
        let scenarioCase = scenario(for: scenarioRaw)
        let failure: APIError? = env["UITEST_FAILURE_RATE"] == "1.0" ? .status(503) : nil
        let store = AppStore(api: .mock(scenario: scenarioCase, failure: failure))

        // Pre-seed the saved graph for saved-tab scenarios so the GET never fires at runtime.
        // This keeps UITEST_FAILURE_RATE's effect confined to the write path only.
        switch scenarioCase {
        case .savedStandard, .savedError:
            store.loadSeed(savedPlaces: SampleData.savedPlacesDTO())
        case .savedEmpty:
            store.loadSeed(savedPlaces: SampleData.emptySavedPlacesDTO())
        default:
            break
        }

        return store
    }

    private static func scenario(for raw: String) -> MockScenario {
        switch raw {
        case "onboardingB":    return .onboardingB
        case "onboardingC":    return .onboardingC
        case "savedStandard":  return .savedStandard
        case "savedEmpty":     return .savedEmpty
        case "savedError":     return .savedError
        default:               return .onboardingA
        }
    }
}
