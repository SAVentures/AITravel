/*
 GET /onboarding/context — fetches the seed catalog for the active onboarding scenario.
 mockLatency is .zero because the generate-step latency is the store's clock, not this request.
 A missing context (e.g. .empty scenario) is a 404, keeping the mock honest about the contract.
*/
import Foundation

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
