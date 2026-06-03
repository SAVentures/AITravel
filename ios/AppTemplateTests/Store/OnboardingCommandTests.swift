/*
 Layer 2 integration tests: loadOnboarding() hydrates the store from MockProvider across the three
 A/B/C scenarios, and savedHere/savedAnywhere/onboardingState derive correctly after hydration.
 Each test is @MainActor (AppStore isolation), fresh store per test, mock API only — no Date()/Calendar.
*/

import Testing
@testable import AppTemplate

@Suite("Onboarding store command + branch derivation")
struct OnboardingCommandTests {

    // MARK: - Scenario A

    @Test @MainActor
    func loadHydratesForScenarioA() async {
        let store = AppStore(api: .mock(scenario: .onboardingA))
        await store.loadOnboarding()

        #expect(
            store.onboardingLoadState == .loaded,
            "loadState=\(store.onboardingLoadState)"
        )
        #expect(
            store.onboarding != nil,
            "loadState=\(store.onboardingLoadState)"
        )
        #expect(store.savedHere == 23)
        #expect(store.onboardingState == .returningWithLocalSaves)
    }

    // MARK: - Scenario B

    @Test @MainActor
    func branchB() async {
        let store = AppStore(api: .mock(scenario: .onboardingB))
        await store.loadOnboarding()

        #expect(
            store.onboardingLoadState == .loaded,
            "loadState=\(store.onboardingLoadState)"
        )
        #expect(
            store.onboarding != nil,
            "loadState=\(store.onboardingLoadState)"
        )
        #expect(store.savedHere == 0)
        #expect(store.savedAnywhere > 0)
        #expect(store.onboardingState == .savesElsewhere)
    }

    // MARK: - Scenario C

    @Test @MainActor
    func branchC() async {
        let store = AppStore(api: .mock(scenario: .onboardingC))
        await store.loadOnboarding()

        #expect(
            store.onboardingLoadState == .loaded,
            "loadState=\(store.onboardingLoadState)"
        )
        #expect(
            store.onboarding != nil,
            "loadState=\(store.onboardingLoadState)"
        )
        #expect(store.savedAnywhere == 0)
        #expect(store.onboardingState == .firstTrip)
    }
}
