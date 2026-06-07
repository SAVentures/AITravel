/*
 GET /wallet — fetches the full trip wallet (container + all bookings) for the current session.
 mockLatency is .zero because this is a snapshot load, not a generative/slow operation
 (mirrors GetSavedPlacesRequest pattern — 04-networking.md §7).
 A nil seed (e.g. scenarios that don't populate the wallet) yields a 404, keeping the mock
 honest about the contract.
*/
import Foundation

nonisolated struct GetWalletRequest: APIRequest {
    typealias Response = TripWalletDTO

    var path = "/wallet"
    var method: HTTPMethod = .get
    var mockLatency: Duration = .zero

    func mockResponse(from seed: MockSeed) throws -> TripWalletDTO {
        guard let wallet = seed.wallet else {
            throw APIError.status(404)
        }
        return wallet
    }
}
