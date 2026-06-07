import Foundation

/*
 The single source of all mock data — previews, tests, and the stateless MockProvider all
 read from here; no fixture is constructed inline anywhere else (02-models.md §5).

 Resolves a MockScenario to its immutable MockSeed (the wire-shaped DTO value side). A
 factory that builds a live @MainActor reference graph snapshots it via .toDTO() into the
 seed, keeping both representations in lock-step.

 Stays CORE and small: the seed(for:) switch plus shared substrate. Each feature extends
 the switch from its own SampleData+<Feature>.swift, so new mock data is a new file.
*/
enum SampleData {

    static func seed(for scenario: MockScenario) -> MockSeed {
        switch scenario {
        case .empty:
            MockSeed()
        case .onboardingA:
            MockSeed(onboardingContext: onboardingAContext())
        case .onboardingB:
            MockSeed(onboardingContext: onboardingBContext())
        case .onboardingC:
            MockSeed(onboardingContext: onboardingCContext())
        case .savedStandard:
            MockSeed(savedPlaces: savedPlacesDTO())
        case .savedEmpty:
            MockSeed(savedPlaces: emptySavedPlacesDTO())
        case .savedError:
            // Same populated seed as savedStandard; the error path is exercised via
            // APIClient.mock(scenario: .savedError, failureRate: 1.0) — not a distinct seed.
            MockSeed(savedPlaces: savedPlacesDTO())
        case .walletStandard:
            MockSeed(wallet: walletDTO())
        case .walletEmpty:
            MockSeed(wallet: emptyWalletDTO())
        case .walletError:
            // Same populated seed as walletStandard; the error path is exercised via
            // APIClient.mock(scenario: .walletError, failureRate: 1.0) — not a distinct seed.
            MockSeed(wallet: walletDTO())
        }
    }
}
