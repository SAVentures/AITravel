import Foundation

/// The immutable DTO snapshot the ``MockProvider`` serves — a `Sendable` value with no
/// persisted mutable state. Requests compute their `mockResponse(from:)` purely from this
/// seed (`04-networking.md §7`).
///
/// It starts **empty**. Each feature adds its top-level entity as a stored field via an
/// extension (e.g. `var library: LibraryDTO`), and `SampleData.seed(for:)` populates those
/// fields per scenario. Keeping the core type empty here lets parallel feature scaffolders
/// add fields without colliding on this file.
struct MockSeed: Sendable {

    /// The onboarding seed catalog served for the active scenario, or `nil` for `.empty`.
    /// `GetOnboardingContextRequest.mockResponse(from:)` reads this; an absent context yields a 404
    /// (`04-networking.md §7`, plan W2-10).
    var onboardingContext: OnboardingContextDTO?

    /// A no-argument-able init (all fields default) so the existing `MockSeed()` for `.empty`
    /// keeps working as features add fields by extension.
    init(onboardingContext: OnboardingContextDTO? = nil) {
        self.onboardingContext = onboardingContext
    }
}
