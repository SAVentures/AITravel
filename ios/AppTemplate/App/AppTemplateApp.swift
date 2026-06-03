import SwiftUI

/*
 `@main` entry: register embedded fonts, then construct + inject the one app-root `AppStore`.
 The store is seeded from the launch-env scenario so UI tests can pin which onboarding branch the
 MockProvider serves — `UITEST_SCENARIO` → `.onboardingA/B/C`, defaulting to `.onboardingA` when unset.
*/
@main
struct AppTemplateApp: App {
    @State private var store = AppStore(api: .mock(scenario: AppTemplateApp.launchScenario))

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

    private static var launchScenario: MockScenario {
        switch ProcessInfo.processInfo.environment["UITEST_SCENARIO"] {
        case "onboardingB": .onboardingB
        case "onboardingC": .onboardingC
        default:            .onboardingA
        }
    }
}
