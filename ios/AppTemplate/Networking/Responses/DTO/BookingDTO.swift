/*
 Value-type wire mirror of `BookingModel`. Reuses all leaf value types directly —
 `BookingType`, `BookingStatus`, `BookingDetailInfo`, `AccessPass`, `PlaceFacts`,
 `DetailRow` are already `nonisolated`, `Codable`, and wire-safe (no per-leaf DTO,
 per 02-models §1.2 and §4). This struct is `nonisolated` so it decodes off the main
 actor without isolation-mismatch errors (02-models §1.2).

 Mapping contract (02-models §4):
   - `BookingDTO.toDomain()`     — builds a `BookingModel` reference on the main actor.
   - `BookingModel.toDTO()`      — snapshots the live reference back to a value DTO.
   - Round-trip invariant: `dto.toDomain().toDTO() == dto` (tested in Wave 4, Task 4.1).
   - Mapping is TOTAL: every mutable field in `BookingModel` has a corresponding field
     here; a field added to the model but omitted from this DTO is a compile error.

 `BookingModel.restore(from: BookingDTO)` (defined in BookingModel.swift, Task 2.1)
 is the rollback seam that calls into this type. This file satisfies that forward
 reference.
*/
import Foundation

// MARK: - BookingDTO

nonisolated struct BookingDTO: Codable, Equatable, Sendable {

    var id: String
    var title: String
    var type: BookingType
    var status: BookingStatus
    var dayIndex: Int?
    var startTime: String?
    var subtitleParts: [String]
    var confirmation: String?
    var detail: BookingDetailInfo?
    var accessPass: AccessPass?

    init(
        id: String,
        title: String,
        type: BookingType,
        status: BookingStatus,
        dayIndex: Int? = nil,
        startTime: String? = nil,
        subtitleParts: [String] = [],
        confirmation: String? = nil,
        detail: BookingDetailInfo? = nil,
        accessPass: AccessPass? = nil
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.status = status
        self.dayIndex = dayIndex
        self.startTime = startTime
        self.subtitleParts = subtitleParts
        self.confirmation = confirmation
        self.detail = detail
        self.accessPass = accessPass
    }
}

// MARK: - BookingDTO → BookingModel

extension BookingDTO {

    /// Builds a `BookingModel` reference on the main actor.
    /// Called by `TripWalletDTO.toDomain()` for each child booking.
    @MainActor
    func toDomain() -> BookingModel {
        BookingModel(
            id: id,
            title: title,
            type: type,
            status: status,
            dayIndex: dayIndex,
            startTime: startTime,
            subtitleParts: subtitleParts,
            confirmation: confirmation,
            detail: detail,
            accessPass: accessPass
        )
    }
}

// MARK: - BookingModel → BookingDTO

extension BookingModel {

    /// Snapshots the live reference back to a value DTO.
    /// Used for rollback snapshots and any request body that sends a booking.
    func toDTO() -> BookingDTO {
        BookingDTO(
            id: id,
            title: title,
            type: type,
            status: status,
            dayIndex: dayIndex,
            startTime: startTime,
            subtitleParts: subtitleParts,
            confirmation: confirmation,
            detail: detail,
            accessPass: accessPass
        )
    }
}
