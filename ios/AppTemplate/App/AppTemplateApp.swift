import SwiftUI

/// `@main` entry. Two launch jobs: register the embedded fonts and construct + inject the single
/// `AppStore`. The App root owns the one store (`01-architecture.md §4` — no `.shared`, no parallel
/// stores); every screen reads it via `@Environment(AppStore.self)`.
///
/// The store is built from the launch-env scenario so UI tests can pin which onboarding branch (A/B/C)
/// the `MockProvider` serves (`07-testing.md §7.1`): `UITEST_SCENARIO` → `.onboardingA/B/C`, defaulting
/// to `.onboardingA` when unset.
@main
struct AppTemplateApp: App {
    /// The single store, owned here for the app's lifetime. Seeded from the launch scenario.
    @State private var store = AppStore(api: .mock(scenario: AppTemplateApp.launchScenario))

    init() { FontRegistry.registerEmbeddedFonts() }   // embed + register the custom faces (01-arch §4)

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)             // inject the one store at the root (01-arch §4)
                .preferredColorScheme(.light)   // light-mode only (design decision)
        }
    }

    /// Resolve the launch scenario from the UI-test launch environment (`07-testing.md §7.1`).
    /// `UITEST_SCENARIO` ∈ {`onboardingA`, `onboardingB`, `onboardingC`}; anything else (incl. unset,
    /// the normal-run default) maps to `.onboardingA`.
    private static var launchScenario: MockScenario {
        switch ProcessInfo.processInfo.environment["UITEST_SCENARIO"] {
        case "onboardingB": .onboardingB
        case "onboardingC": .onboardingC
        default:            .onboardingA
        }
    }
}
