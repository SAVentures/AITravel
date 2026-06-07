/*
 POST /wallet/bookings/{id}/place — assigns an orphan booking to a specific day and returns
 the resolved `BookingDTO` with `dayIndex` set. This is the one networked write for the
 orphan-placement flow (OD-4).

 mockLatency is .milliseconds(600) so the loading state is exercisable in UI tests and
 previews (04-networking.md §7: "generative/slow endpoints set mockLatency so loading states
 are exercised").

 mockResponse computes a resolved BookingDTO purely from the immutable seed — it is not
 persisted (the mock is stateless; AppStore applies the write optimistically and rolls back
 on failure). If the booking is found in the seed, it returns a copy with dayIndex set to
 the requested day. If not found, it returns a canned placed BookingDTO with the given id
 and dayIndex (so the mock can always drive the happy-path UI path regardless of seed state).
*/
import Foundation

// MARK: - PlaceOrphanBody

/// The request body sent when placing an orphan booking onto a specific day.
nonisolated struct PlaceOrphanBody: Encodable, Sendable {
    /// The zero-based day index the user chose to assign the booking to.
    var dayIndex: Int
}

// MARK: - PlaceOrphanRequest

nonisolated struct PlaceOrphanRequest: APIRequest {
    typealias Response = BookingDTO

    let id: BookingModel.ID
    let dayIndex: Int

    var path: String { "/wallet/bookings/\(id)/place" }
    var method: HTTPMethod = .post
    var mockLatency: Duration = .milliseconds(600)

    var body: (any Encodable & Sendable)? { PlaceOrphanBody(dayIndex: dayIndex) }

    func mockResponse(from seed: MockSeed) throws -> BookingDTO {
        // Pure and synchronous — computed from the immutable seed; not persisted.
        // Find the booking in the seed and return a copy with dayIndex set to the requested day.
        if let existing = seed.wallet?.bookings.first(where: { $0.id == id }) {
            var placed = existing
            placed.dayIndex = dayIndex
            return placed
        }
        // Booking not in seed — return a canned resolved BookingDTO so the mock always
        // drives the happy-path UI regardless of scenario (mirrors AddPlaceRequest's canned approach).
        return BookingDTO(
            id: id,
            title: "Placed Booking",
            type: .activity,
            status: .upcoming,
            dayIndex: dayIndex
        )
    }
}
