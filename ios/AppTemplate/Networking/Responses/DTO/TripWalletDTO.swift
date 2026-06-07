/*
 Value-type wire mirror of `TripWalletModel` (the container reference model). Holds the
 trip identity fields and a flat array of `BookingDTO` — no extra nesting because the
 leaf value types are already wire-safe and `BookingDTO` handles the per-row mapping
 (02-models §4). This struct is `nonisolated` so it decodes off the main actor without
 isolation-mismatch errors (02-models §1.2).

 Mapping contract (02-models §4):
   - `TripWalletDTO.toDomain()` — builds the `TripWalletModel` reference graph on the
     main actor (calls `BookingDTO.toDomain()` for each child booking).
   - `TripWalletModel.toDTO()` — snapshots the container and all child rows back to a
     value DTO.
   - Round-trip invariant: `dto.toDomain().toDTO() == dto` (tested in Wave 4, Task 4.1).
   - Mapping is TOTAL: every mutable field in `TripWalletModel` has a corresponding field
     here; a field added to the model but omitted from this DTO is a compile error.
*/
import Foundation

// MARK: - TripWalletDTO

nonisolated struct TripWalletDTO: Codable, Equatable, Sendable {

    var id: String
    var tripCityName: String
    var dayCount: Int
    var bookings: [BookingDTO]

    init(
        id: String,
        tripCityName: String,
        dayCount: Int,
        bookings: [BookingDTO]
    ) {
        self.id = id
        self.tripCityName = tripCityName
        self.dayCount = dayCount
        self.bookings = bookings
    }
}

// MARK: - TripWalletDTO → TripWalletModel

extension TripWalletDTO {

    /// Builds the `TripWalletModel` reference graph (container + all child booking rows)
    /// on the main actor.
    @MainActor
    func toDomain() -> TripWalletModel {
        TripWalletModel(
            id: id,
            tripCityName: tripCityName,
            dayCount: dayCount,
            bookings: bookings.map { $0.toDomain() }
        )
    }
}

// MARK: - TripWalletModel → TripWalletDTO

extension TripWalletModel {

    /// Snapshots the container and every child `BookingModel` back to a value DTO.
    func toDTO() -> TripWalletDTO {
        TripWalletDTO(
            id: id,
            tripCityName: tripCityName,
            dayCount: dayCount,
            bookings: bookings.map { $0.toDTO() }
        )
    }
}
