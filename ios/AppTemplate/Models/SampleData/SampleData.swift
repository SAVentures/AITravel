import Foundation

/// The single source of all mock data.
///
/// Everything that needs fake data — Xcode previews, unit/integration tests, and the
/// stateless `MockProvider` the running app talks to — gets it from here. There is no
/// inline-constructed data anywhere else; that's how fixtures drift (`02-models.md §5`).
///
/// `SampleData` resolves a ``MockScenario`` to the immutable ``MockSeed`` snapshot a
/// `MockProvider` serves for it. The seed is the **DTO value side** — a wire-shaped
/// snapshot. Where a factory builds a live domain reference graph (a `@MainActor`
/// object tree) it does so in a `@MainActor` context and snapshots it through `.toDTO()`
/// into the seed, keeping the two representations in lock-step.
///
/// **This file is CORE** and stays small: the ``seed(for:)`` switch plus the shared
/// substrate. Per-feature content is added by extension — each feature ships a
/// `SampleData+<Feature>.swift` file that fills in its slice of the seed for the
/// scenarios it owns, so a new feature's mock data is a *new file*, never an edit to
/// this composer.
enum SampleData {

    /// The immutable seed a `MockProvider` serves for a given scenario.
    ///
    /// `.empty` is the only scenario that exists today and returns a bare ``MockSeed``;
    /// `MockSeed` starts empty and gains per-feature fields by extension, so each
    /// feature extends this switch (via `SampleData+<Feature>`) to populate the
    /// scenarios it introduces.
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
        }
    }
}
