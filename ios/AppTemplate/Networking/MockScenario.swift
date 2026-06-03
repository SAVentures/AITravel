import Foundation

/// Selects which ``MockSeed`` variant the ``MockProvider`` is built from, set at the
/// `AppStore` init boundary and driven by launch args in UI tests (`04-networking.md §7`).
///
/// Starts with just `.empty`. Features add cases (e.g. `.standard`, `.emptyLibrary`),
/// and `SampleData.seed(for:)` maps each case to a seeded ``MockSeed``. For `.empty` it
/// returns an empty `MockSeed()`.
enum MockScenario: Sendable, CaseIterable {
    case empty
    /// Onboarding state A — returning user with local saves (Lisbon, 23 saved).
    case onboardingA
    /// Onboarding state B — saves elsewhere, none in the chosen city (Kyoto).
    case onboardingB
    /// Onboarding state C — first trip, nothing saved anywhere (Lisbon).
    case onboardingC
}
