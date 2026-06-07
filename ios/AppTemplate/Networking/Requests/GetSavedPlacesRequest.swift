/*
 GET /saved-places — fetches the full saved-places list for the current session.
 mockLatency is .zero because the list is a snapshot load, not a generative/slow operation.
 A missing seed (e.g. .empty scenario) is a 404, keeping the mock honest about the contract
 (mirrors GetOnboardingContextRequest pattern).
*/
import Foundation

nonisolated struct GetSavedPlacesRequest: APIRequest {
    typealias Response = SavedPlacesDTO

    var path = "/saved-places"
    var method: HTTPMethod = .get
    var mockLatency: Duration = .zero

    func mockResponse(from seed: MockSeed) throws -> SavedPlacesDTO {
        guard let savedPlaces = seed.savedPlaces else {
            throw APIError.status(404)
        }
        return savedPlaces
    }
}
