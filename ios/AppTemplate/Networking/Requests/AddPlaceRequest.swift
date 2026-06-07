/*
 POST /saved-places — resolves a URL (reel/clipboard) into a saved place and returns the
 resolved PlaceDTO. This is the one networked write for the add-place flow (D-4).

 mockLatency is .milliseconds(800) so the loading state is exercisable in UI tests and previews
 (04-networking.md §7: "generative/slow endpoints set mockLatency so loading states are exercised").

 mockResponse computes a canned resolved place purely from the immutable seed — it is not
 persisted (the mock is stateless; the client applies the write optimistically against AppStore).
*/
import Foundation

// MARK: - AddPlaceBody

/// The request body the reel/clipboard add flow sends to the server.
/// Carries the URL the user pasted and the source kind so the server can route the resolution.
nonisolated struct AddPlaceBody: Encodable, Sendable {
    /// The reel or page URL pasted from the clipboard.
    var url: String
    /// The source kind the client detected (always `.reel` for the D-4 milestone path).
    var sourceKind: SourceKind
}

// MARK: - AddPlaceRequest

nonisolated struct AddPlaceRequest: APIRequest {
    typealias Response = PlaceDTO

    let body_: AddPlaceBody

    var path = "/saved-places"
    var method: HTTPMethod = .post
    var mockLatency: Duration = .milliseconds(800)

    var body: (any Encodable & Sendable)? { body_ }

    func mockResponse(from seed: MockSeed) throws -> PlaceDTO {
        // Returns a canned resolved place regardless of the body URL.
        // Pure and synchronous — computed from the immutable seed; not persisted.
        PlaceDTO(
            id: "place-resolved-reel",
            name: "Cervejaria Ramiro",
            category: .eat,
            location: PlaceLocation(neighborhood: "Intendente", cityName: "Lisbon"),
            source: .reel(handle: "foodie.travels", clipTitle: "Best seafood in Lisbon"),
            provenance: PlaceProvenance(
                sourceHandle: "@foodie.travels",
                clipTitle: "Best seafood in Lisbon",
                timestamp: "2 days ago",
                quote: "The best percebes I've ever had — go at lunch."
            ),
            facts: [
                PlaceFacts(key: "Hours", value: "12–24:30", sub: "Closed Mon"),
                PlaceFacts(key: "Price", value: "€€€", sub: nil),
                PlaceFacts(key: "Cuisine", value: "Seafood", sub: "Portuguese")
            ],
            addressLine: "Av. Almirante Reis 1, Lisbon",
            latitude: 38.7223,
            longitude: -9.1360,
            savedAtNote: "Resolved from reel"
        )
    }
}
