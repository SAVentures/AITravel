// OnboardingCommandTests.swift — Layer 2 integration tests for the onboarding store command
// and store-level branch derivation (plan W3/W5-01 L2).
//
// Coverage:
//   - `loadOnboarding()` hydrates the store from `MockProvider` for all three A/B/C scenarios.
//   - `savedHere` / `savedAnywhere` / `onboardingState` are correctly derived after hydration.
//
// Governing doc: ios/docs/engineering/07-testing.md §5 (store command tests).
// Every test runs @MainActor (matching AppStore's isolation), constructs a fresh store per test,
// and uses APIClient.mock(scenario:) — no live network, no Date(), no Calendar.current.

import Testing
@testable import AppTemplate

@Suite("Onboarding store command + branch derivation")
struct OnboardingCommandTests {

    // MARK: - Scenario A — returning user, local saves (Lisbon, 23 saved)

    /// Happy path for scenario A: `loadOnboarding()` hydrates the store, `onboardingLoadState`
    /// reaches `.loaded`, and the three branch-derivation properties reflect the 23 local saves
    /// that put this user on the A branch (`returningWithLocalSaves`).
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

    // MARK: - Scenario B — saves elsewhere, none in chosen city (Kyoto)

    /// Branch-B derivation: after loading scenario B, `savedHere` is 0 (no saves in Kyoto),
    /// `savedAnywhere` is positive (Tokyo + Lisbon saves), and `onboardingState` is `.savesElsewhere`.
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

    // MARK: - Scenario C — first trip, nothing saved anywhere

    /// Branch-C derivation: after loading scenario C, both `savedAnywhere` is 0 (first trip)
    /// and `onboardingState` is `.firstTrip`.
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
