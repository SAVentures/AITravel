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
    case savedStandard  // Saved tab: 24 places across Eat/Drink/Stay/Do/Shop (Lisbon, Tokyo, Porto)
    case savedEmpty     // Saved tab: 0 places → rich empty state (WayToSaveRow × 3)
    // Note: savedError is not a separate seed — inject via APIClient.mock(failureRate: 1.0).
    // A named scenario keeps the UITest launch-arg table clean and self-documenting.
    case savedError     // Saved tab: same seed as savedStandard; failureRate drives the error banner
    case walletStandard // Wallet tab: populated trip wallet with items across categories
    case walletEmpty    // Wallet tab: 0 items → rich empty state
    case walletError    // Wallet tab: same seed as walletStandard; failureRate drives the error banner
}
