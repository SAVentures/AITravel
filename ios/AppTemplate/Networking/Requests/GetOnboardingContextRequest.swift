// GetOnboardingContextRequest.swift — the one-file onboarding endpoint (plan W2-10).
//
// One `struct` conforming to `APIRequest` carrying both the wire description and the pure mock
// behavior, so adding this endpoint is a single new file and `MockProvider` stays ignorant of it
// (`04-networking.md §2`). The generate-step latency is the store's clock, not this request, so
// `mockLatency` is `.zero`.
import Foundation

/// `GET /onboarding/context` — fetches the seed catalog for the active onboarding scenario.
///
/// The `MockProvider` resolves this from `MockSeed.onboardingContext`, which `SampleData`
/// populates per `MockScenario` (`.onboardingA/B/C`). A missing context (e.g. `.empty`) is a 404,
/// keeping the mock honest about the contract (`04-networking.md §6/§7`).
nonisolated struct GetOnboardingContextRequest: APIRequest {
    typealias Response = OnboardingContextDTO

    var path = "/onboarding/context"
    var method: HTTPMethod = .get
    var mockLatency: Duration = .zero

    func mockResponse(from seed: MockSeed) throws -> OnboardingContextDTO {
        guard let ctx = seed.onboardingContext else {
            throw APIError.status(404)
        }
        return ctx
    }
}
