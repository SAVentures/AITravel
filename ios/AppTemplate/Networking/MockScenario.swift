import Foundation

/*
 Picks which MockSeed the MockProvider is built from — set at AppStore init, driven by launch args
 in UI tests. SampleData.seed(for:) maps each case to its seed.
*/
enum MockScenario: Sendable, CaseIterable {
    case empty
    case onboardingA  // returning user, local saves (Lisbon, 23 saved)
    case onboardingB  // saves elsewhere, none in chosen city (Kyoto)
    case onboardingC  // first trip, nothing saved anywhere (Lisbon)
}
